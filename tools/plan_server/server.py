"""Terra NT planning server: POST /v1/itinerary (docs/PHASE-3-CONTRACT.md §1-§4).

Python 3.13 standard library, plus google-auth for the Firebase ID token check.
Run from the repo root:

    python tools/plan_server/server.py --port 8787 [--backend codex|openrouter|fixture] [--no-auth]

README.md next to this file covers install, backends, place documents and how
the app reaches the server.
"""

import argparse
import json
import re
import sys
import threading
import time
import traceback
from dataclasses import dataclass
from datetime import datetime
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlsplit

import backends
import places

HERE = Path(__file__).resolve().parent
PROMPTS_DIR = HERE / "prompts"
RAG_DIR = HERE / "rag"
GEOCODE_CACHE = HERE / ".cache" / "geocode.json"

FIREBASE_PROJECT = "terra-nt-cdu"
CACHE_TTL_SECONDS = 30 * 60  # §4.3 asks for at least 10 minutes
MAX_BODY_BYTES = 64 * 1024
MIN_STOPS = 2

# docs/PHASE-3-CONTRACT.md §2, in table order.
ANSWER_KEYS = (
    "ageRange",
    "days",
    "companions",
    "focus",
    "vehicle",
    "budget",
    "accommodation",
    "activityLevel",
    "region",
    "offRoadConfidence",
    "heat",
    "campingPreference",
    "wildlifeInterest",
    "offGridComfortable",
    "startLocation",
    "endLocation",
)
ENUMS = {
    "ageRange": ("18_25", "26_35", "36_50", "50_plus"),
    "companions": ("solo", "couple", "family", "friends"),
    "vehicle": ("four_wd", "campervan", "standard_car", "guided_tour"),
    "budget": ("budget", "mid_range", "luxury"),
    "accommodation": ("camping", "motel_cabin", "hotel"),
    "activityLevel": ("low", "medium", "high"),
    "region": ("top_end", "red_centre", "full_nt"),
    "offRoadConfidence": ("low", "medium", "high"),
    "campingPreference": ("camping", "mixed", "resort"),
    "wildlifeInterest": ("not_fussed", "interested", "big_draw"),
}
FOCUS = ("nature", "aboriginal_culture", "adventure", "relaxation")
INT_RANGES = {"days": (1, 14), "heat": (1, 5)}
TEXT_MAX = 80

# §3.1 key order: model fields around the four the server adds.
LEADING_FIELDS = ("name", "subtitle")
TRAILING_FIELDS = ("duration", "driveNext", "hours", "fee", "tags", "aiNote", "detailedPlan", "sources")

SERVER_ERROR = {"error": {"code": "server_error"}}
UNAUTHORISED = {"error": {"code": "unauthorised"}}
NOT_FOUND = {"error": {"code": "not_found"}}

NO_AUTH_WARNING = "\n".join(
    ["!" * 76]
    + [
        f"!!  {line:<68}  !!"
        for line in (
            "--no-auth: requests are accepted WITHOUT a Firebase ID token.",
            "Anyone who can reach this port can spend your model quota.",
            "Use it for the emulator and rehearsal only, never through a tunnel.",
        )
    ]
    + ["!" * 76]
)


def cannot_plan(message):
    return {"error": {"code": "cannot_plan", "message": message}}


class CannotPlan(Exception):
    """The request is not one §2 describes: 400 cannot_plan."""


@dataclass(frozen=True)
class Result:
    status: int
    body: dict
    kept: int = 0
    dropped: int = 0


# --- request --------------------------------------------------------------


def _is_int(value):
    return isinstance(value, int) and not isinstance(value, bool)


def _valid_answer(key, value):
    if key in ENUMS:
        return isinstance(value, str) and value in ENUMS[key]
    if key in INT_RANGES:
        low, high = INT_RANGES[key]
        return _is_int(value) and low <= value <= high
    if key == "focus":
        return (
            isinstance(value, list)
            and len(value) >= 1
            and all(isinstance(f, str) and f in FOCUS for f in value)
        )
    if key == "offGridComfortable":
        return isinstance(value, bool)
    return isinstance(value, str) and 1 <= len(value.strip()) <= TEXT_MAX


def validate_request(body):
    """(requestId, answers) from a §2 body, or CannotPlan naming what is wrong."""
    if not isinstance(body, dict):
        raise CannotPlan("the body is not a JSON object")
    version = body.get("schemaVersion")
    if not _is_int(version) or version != 1:
        raise CannotPlan(f"schemaVersion {version!r} cannot be served; this server speaks 1")
    request_id = body.get("requestId")
    if not isinstance(request_id, str) or not re.fullmatch(r"[0-9a-f]{32}", request_id):
        raise CannotPlan("requestId must be 32 lowercase hex characters")
    answers = body.get("answers")
    if not isinstance(answers, dict):
        raise CannotPlan("answers is missing or not an object")
    missing = [key for key in ANSWER_KEYS if key not in answers]
    if missing:
        raise CannotPlan("answers is missing " + ", ".join(missing))
    clean = {}
    for key in ANSWER_KEYS:
        value = answers[key]
        if not _valid_answer(key, value):
            raise CannotPlan(f"answers.{key} has a value outside §2: {value!r}")
        clean[key] = value.strip() if isinstance(value, str) else value
    return request_id, clean


# --- prompt ---------------------------------------------------------------

# `{days}` and the contract's `{focus, comma-separated}` both name an answer key.
_PLACEHOLDER = re.compile(r"\{(\w+)(?:,[^}]*)?\}")


def _wire_text(value):
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, list):
        return ", ".join(value)
    return str(value)


def fill(template, answers):
    return _PLACEHOLDER.sub(lambda m: _wire_text(answers[m.group(1)]), template)


# --- response -------------------------------------------------------------


def assemble_stops(model_stops, geocoder):
    """The §3.1 stops: geocoded, unresolved ones dropped, and the stop before a
    dropped one loses its driveNext. Returns (stops, dropped count)."""
    if not isinstance(model_stops, list):
        raise ValueError("the model output has no stops list")
    resolved = [
        geocoder.resolve(stop.get("name")) if isinstance(stop, dict) else None
        for stop in model_stops
    ]
    stops = []
    for index, (stop, place) in enumerate(zip(model_stops, resolved)):
        if place is None:
            continue
        out = {key: stop[key] for key in LEADING_FIELDS if key in stop}
        out.update(lat=place.lat, lng=place.lng, placeId=place.place_id, photoUrl=None)
        out.update({key: stop[key] for key in TRAILING_FIELDS if key in stop})
        if index + 1 < len(model_stops) and resolved[index + 1] is None:
            out["driveNext"] = None
        stops.append(out)
    return stops, len(model_stops) - len(stops)


def drive_text(metres, seconds, next_name):
    """The §4.1 driveNext form: "<km> km · <h>h <m>m to <next stop name>"."""
    minutes = round(seconds / 60)
    return f"{round(metres / 1000)} km · {minutes // 60}h {minutes % 60}m to {next_name}"


def apply_drive_legs(stops, router):
    """Every driveNext from the road network, not the model: in a measured run the
    model wrote Katherine to Tennant Creek as 300 km, OSRM says 671. When routing
    fails every leg is null (the app shows "Drive time unavailable") rather than
    the model's guess. The last stop has no next leg."""
    legs = router.legs([(s["lat"], s["lng"]) for s in stops])
    for index, stop in enumerate(stops):
        if legs is None or index >= len(legs):
            stop["driveNext"] = None
        else:
            stop["driveNext"] = drive_text(*legs[index], stops[index + 1]["name"])


class _Entry:
    def __init__(self):
        self.done = threading.Event()
        self.result = None
        self.expires = 0.0


class Planner:
    """Everything between a validated request and its Result."""

    def __init__(self, backend, generate, geocoder, router, docs, verify_token):
        self.backend = backend
        self.generate = generate
        self.geocoder = geocoder
        self.router = router
        self.docs = docs
        self.verify_token = verify_token  # None means --no-auth
        self.system_template = (PROMPTS_DIR / "system.txt").read_text(encoding="utf-8").strip()
        self.user_template = (PROMPTS_DIR / "user.txt").read_text(encoding="utf-8").strip()
        self._responses = {}
        self._lock = threading.Lock()

    def build_prompt(self, answers):
        context, left_out = places.context_block(self.docs, answers["region"])
        if left_out:
            print(f"rag: over the context cap, left out {', '.join(left_out)}", flush=True)
        return backends.Prompt(
            system=fill(self.system_template, answers),
            context=context,
            user=fill(self.user_template, answers),
        )

    def plan(self, request_id, answers):
        """(Result, cached). A requestId already answered, or still being
        answered, gets that answer instead of a second generation. 5xx answers
        are not kept, so a retry after a failure generates again."""
        now = time.monotonic()
        with self._lock:
            for key in [k for k, e in self._responses.items() if e.done.is_set() and e.expires < now]:
                del self._responses[key]
            entry = self._responses.get(request_id)
            owner = entry is None
            if owner:
                entry = self._responses[request_id] = _Entry()
        if not owner:
            entry.done.wait()
            return entry.result, True
        result = Result(500, SERVER_ERROR)
        try:
            result = self._generate(answers)
        except backends.BackendTimeout as error:
            print(f"backend timeout: {error}", flush=True)
            result = Result(504, SERVER_ERROR)
        except Exception:
            traceback.print_exc()
        finally:
            entry.result = result
            entry.expires = time.monotonic() + CACHE_TTL_SECONDS
            if result.status >= 500:
                with self._lock:
                    if self._responses.get(request_id) is entry:
                        del self._responses[request_id]
            entry.done.set()
        return result, False

    def _generate(self, answers):
        output = self.generate(self.build_prompt(answers))
        if not isinstance(output, dict):
            raise ValueError("the model output is not a JSON object")
        stops, dropped = assemble_stops(output.get("stops"), self.geocoder)
        if len(stops) < MIN_STOPS:
            message = f"{len(stops)} of {len(stops) + dropped} stops resolved to a place in the NT"
            return Result(422, cannot_plan(message), len(stops), dropped)
        apply_drive_legs(stops, self.router)
        body = {"schemaVersion": 1, "title": output.get("title"), "stops": stops}
        return Result(200, body, len(stops), dropped)


# --- auth -----------------------------------------------------------------


def firebase_verifier(project=FIREBASE_PROJECT):
    """token -> bool, with google-auth. Imported here so --no-auth runs without it."""
    from google.auth.exceptions import GoogleAuthError, TransportError
    from google.auth.transport.requests import Request
    from google.oauth2 import id_token

    issuer = f"https://securetoken.google.com/{project}"
    request = Request()

    def verify(token):
        try:
            claims = id_token.verify_firebase_token(token, request, audience=project)
        except TransportError:
            raise  # Google's keys unreachable: a server error, not the user's token
        except (ValueError, GoogleAuthError):
            return False
        return bool(claims) and claims.get("iss") == issuer

    return verify


def bearer_token(header):
    parts = (header or "").split(None, 1)
    if len(parts) == 2 and parts[0].lower() == "bearer" and parts[1].strip():
        return parts[1].strip()
    return None


# --- HTTP -----------------------------------------------------------------


class Handler(BaseHTTPRequestHandler):
    server_version = "TerraNTPlanServer/1.0"

    def log_message(self, format, *args):  # noqa: A002 - stdlib signature
        pass  # one line per request is written by do_POST

    def do_POST(self):
        started = time.monotonic()
        planner = self.server.planner
        request_id, cached = "-", False
        try:
            result, request_id, cached = self._handle(planner)
        except Exception:
            traceback.print_exc()
            result = Result(500, SERVER_ERROR)
        self._send(result.status, result.body)
        print(
            f"{datetime.now():%H:%M:%S} requestId={request_id} backend={planner.backend} "
            f"status={result.status} seconds={time.monotonic() - started:.1f} "
            f"stops kept={result.kept} dropped={result.dropped}"
            + (" (cached)" if cached else ""),
            flush=True,
        )

    def _handle(self, planner):
        try:
            raw = self._read_body()
        except CannotPlan as error:
            return Result(400, cannot_plan(str(error))), "-", False
        if urlsplit(self.path).path != "/v1/itinerary":
            return Result(404, NOT_FOUND), "-", False
        if planner.verify_token is not None:
            token = bearer_token(self.headers.get("Authorization"))
            if token is None or not planner.verify_token(token):
                return Result(401, UNAUTHORISED), "-", False
        try:
            try:
                body = json.loads(raw.decode("utf-8"))
            except ValueError:
                raise CannotPlan("the body is not UTF-8 JSON") from None
            request_id, answers = validate_request(body)
        except CannotPlan as error:
            return Result(400, cannot_plan(str(error))), "-", False
        result, cached = planner.plan(request_id, answers)
        return result, request_id, cached

    def _read_body(self):
        try:
            length = int(self.headers.get("Content-Length") or 0)
        except ValueError:
            raise CannotPlan("Content-Length is not a number") from None
        if length > MAX_BODY_BYTES:
            raise CannotPlan(f"the body is over {MAX_BODY_BYTES} bytes")
        return self.rfile.read(length) if length > 0 else b""

    def _send(self, status, body):
        data = json.dumps(body, ensure_ascii=False).encode("utf-8")
        try:
            self.send_response(status)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)
        except OSError as error:
            print(f"client gone before the response was written: {error}", flush=True)


# --- CLI ------------------------------------------------------------------


def parse_args(argv=None):
    parser = argparse.ArgumentParser(
        prog="server.py",
        description="Terra NT planning server: POST /v1/itinerary as docs/PHASE-3-CONTRACT.md describes.",
    )
    parser.add_argument("--port", type=int, default=8787, help="port to listen on (default 8787)")
    parser.add_argument(
        "--backend",
        choices=sorted(backends.GENERATORS),
        default="codex",
        help="the model: codex (default, the operator's Codex subscription), "
        "openrouter (OPENROUTER_API_KEY), fixture (a fixed answer, no model)",
    )
    parser.add_argument(
        "--no-auth",
        action="store_true",
        help="accept requests without a Firebase ID token (prints a warning; emulator and rehearsal only)",
    )
    return parser.parse_args(argv)


def create_server(
    args, *, host="0.0.0.0", generate=None, geocoder=None, router=None, verify_token=None, docs=None
):
    """The server, not yet serving. Tests pass fakes; main() passes nothing."""
    docs = places.load_place_docs(RAG_DIR) if docs is None else docs
    if generate is None:
        generate = backends.GENERATORS[args.backend]
    if geocoder is None:
        geocoder = places.Geocoder(docs, GEOCODE_CACHE)
    if router is None:
        router = places.Router()
    if args.no_auth:
        verify_token = None
    elif verify_token is None:
        verify_token = firebase_verifier()
    server = ThreadingHTTPServer((host, args.port), Handler)
    server.planner = Planner(args.backend, generate, geocoder, router, docs, verify_token)
    return server


def main(argv=None):
    args = parse_args(argv)
    for stream in (sys.stdout, sys.stderr):
        # A place name like "Uluṟu" must not crash a log line when the
        # console output is redirected to a cp1252 file.
        stream.reconfigure(errors="backslashreplace")
    if args.no_auth:
        print(NO_AUTH_WARNING, file=sys.stderr, flush=True)
    backends.prepare(args.backend)
    server = create_server(args)
    port = server.server_address[1]
    print(
        f"plan_server listening on http://0.0.0.0:{port}/v1/itinerary "
        f"backend={args.backend} auth={'off' if args.no_auth else 'on'} "
        f"place documents={len(server.planner.docs)}",
        flush=True,
    )
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
