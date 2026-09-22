"""Stub for POST /v1/itinerary (docs/PHASE-3-CONTRACT.md §8).

Python 3 standard library only. Serves one fixed --mode for the life of the
process; run a second instance on another --port to switch modes mid-tour.
"""

import argparse
import json
import time
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
FIXTURES = REPO_ROOT / "terra_nt" / "test" / "fixtures" / "plan"

RATE_LIMITED_BODY = {
    "error": {"code": "rate_limited", "retryAfterSeconds": 30},
}
ERROR_BODY = {"error": {"code": "server_error"}}


def _fixture(name):
    return (FIXTURES / name).read_bytes()


class PlanStubHandler(BaseHTTPRequestHandler):
    mode = "ok"

    def log_message(self, format, *args):  # noqa: A002 - stdlib signature
        pass

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        raw = self.rfile.read(length) if length else b""
        request_id = None
        try:
            request_id = json.loads(raw).get("requestId") if raw else None
        except json.JSONDecodeError:
            request_id = None
        has_auth = "Authorization" in self.headers
        print(
            f"POST {self.path} requestId={request_id} authorization={has_auth}",
            flush=True,
        )

        if self.mode == "refuse":
            self.connection.close()
            return

        if self.mode == "ok":
            time.sleep(2)
            self._respond(200, _fixture("ok.json"))
        elif self.mode == "slow":
            time.sleep(75)
            self._respond(200, _fixture("ok.json"))
        elif self.mode == "cannot_plan":
            self._respond(422, _fixture("error_cannot_plan.json"))
        elif self.mode == "rate_limited":
            self._respond(429, json.dumps(RATE_LIMITED_BODY).encode("utf-8"))
        elif self.mode == "error":
            self._respond(500, json.dumps(ERROR_BODY).encode("utf-8"))
        elif self.mode == "invalid":
            self._respond(200, _fixture("invalid_one_stop.json"))
        else:
            raise ValueError(f"Unknown mode: {self.mode}")

    def _respond(self, status, body):
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=8787)
    parser.add_argument(
        "--mode",
        default="ok",
        choices=[
            "ok",
            "slow",
            "cannot_plan",
            "rate_limited",
            "error",
            "invalid",
            "refuse",
        ],
    )
    args = parser.parse_args()

    PlanStubHandler.mode = args.mode
    server = HTTPServer(("0.0.0.0", args.port), PlanStubHandler)
    print(f"plan_stub listening on :{args.port} mode={args.mode}", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
