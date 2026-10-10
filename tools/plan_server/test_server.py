"""Gate for Task-45: python -m unittest discover -s tools/plan_server -p "test_*.py" -v

No network and no Codex login: the server runs in-process with the fixture
backend and a stubbed geocoder; the openrouter and codex backends run against
fakes.
"""

import contextlib
import io
import json
import os
import re
import subprocess
import sys
import tempfile
import threading
import unittest
import urllib.error
import urllib.request
from pathlib import Path
from unittest import mock

import backends
import places
import server

HERE = Path(__file__).resolve().parent
REPO_ROOT = HERE.parents[1]
CONTRACT = (REPO_ROOT / "docs" / "PHASE-3-CONTRACT.md").read_text(encoding="utf-8")
NO_PROXY = urllib.request.build_opener(urllib.request.ProxyHandler({}))


def contract_block(heading, lang=""):
    """The first fenced block after `heading` in docs/PHASE-3-CONTRACT.md."""
    start = CONTRACT.index(heading)
    return re.compile(r"```" + lang + r"\n(.*?)```", re.S).search(CONTRACT, start).group(1)


EXAMPLE_REQUEST = json.loads(contract_block("## 2. Outbound", "json"))
FIXTURE_OUTPUT = json.loads((HERE / "fixture_output.json").read_text(encoding="utf-8"))


def in_nt_box(stop):
    lat, lng = stop["lat"], stop["lng"]
    numeric = all(isinstance(v, (int, float)) and not isinstance(v, bool) for v in (lat, lng))
    return numeric and -26.5 <= lat <= -10.5 and 128.5 <= lng <= 138.5


class StubGeocoder:
    """Resolves every name (or only `resolvable`) to a point in Darwin."""

    def __init__(self, resolvable=None):
        self.resolvable = resolvable

    def resolve(self, name):
        if self.resolvable is not None and name not in self.resolvable:
            return None
        return places.Place(-12.4634, 130.8456, f"stub/{name}")


class Counting:
    def __init__(self, generate):
        self.generate = generate
        self.calls = 0

    def __call__(self, prompt):
        self.calls += 1
        return self.generate(prompt)


class ServerTestCase(unittest.TestCase):
    def start(self, argv, **overrides):
        overrides.setdefault("geocoder", StubGeocoder())
        self.log = io.StringIO()
        redirect = contextlib.redirect_stdout(self.log)
        redirect.__enter__()
        self.addCleanup(redirect.__exit__, None, None, None)
        httpd = server.create_server(server.parse_args(argv), host="127.0.0.1", **overrides)
        threading.Thread(target=httpd.serve_forever, daemon=True).start()
        self.addCleanup(httpd.server_close)
        self.addCleanup(httpd.shutdown)
        self.port = httpd.server_address[1]
        return httpd

    def post(self, body, headers=None):
        request = urllib.request.Request(
            f"http://127.0.0.1:{self.port}/v1/itinerary",
            data=json.dumps(body).encode("utf-8"),
            method="POST",
            headers={"Content-Type": "application/json; charset=utf-8", **(headers or {})},
        )
        try:
            with NO_PROXY.open(request, timeout=15) as response:
                return response.status, json.loads(response.read().decode("utf-8"))
        except urllib.error.HTTPError as error:
            return error.code, json.loads(error.read().decode("utf-8"))


class SmokeTest(ServerTestCase):
    def test_example_request_plans_and_a_repeat_is_answered_from_cache(self):
        httpd = self.start(["--port", "0", "--backend", "fixture", "--no-auth"])
        counting = Counting(httpd.planner.generate)
        httpd.planner.generate = counting

        status, body = self.post(EXAMPLE_REQUEST)

        self.assertEqual(status, 200)
        self.assertEqual(body["schemaVersion"], 1)
        self.assertGreaterEqual(len(body["stops"]), 2)
        for stop in body["stops"]:
            self.assertTrue(in_nt_box(stop), stop)
        self.assertEqual(counting.calls, 1)

        again_status, again = self.post(EXAMPLE_REQUEST)

        self.assertEqual(again_status, 200)
        self.assertEqual(again, body)
        self.assertEqual(counting.calls, 1, "a repeated requestId must not generate again")
        request_id = EXAMPLE_REQUEST["requestId"]
        self.assertIn(
            f"requestId={request_id} backend=fixture status=200", self.log.getvalue()
        )
        self.assertIn("stops kept=4 dropped=0 (cached)", self.log.getvalue())


class FailureTest(ServerTestCase):
    def test_missing_answer_is_400_cannot_plan(self):
        self.start(["--port", "0", "--backend", "fixture", "--no-auth"])
        body = json.loads(json.dumps(EXAMPLE_REQUEST))
        del body["answers"]["heat"]

        status, error = self.post(body)

        self.assertEqual(status, 400)
        self.assertEqual(error["error"]["code"], "cannot_plan")
        self.assertIn("heat", error["error"]["message"])

    def test_no_or_bad_token_with_auth_on_is_401(self):
        seen = []

        def verify(token):
            seen.append(token)
            return False

        self.start(["--port", "0", "--backend", "fixture"], verify_token=verify)

        status, error = self.post(EXAMPLE_REQUEST)
        self.assertEqual((status, error), (401, {"error": {"code": "unauthorised"}}))
        self.assertEqual(seen, [], "no header must not reach the verifier")

        status, error = self.post(EXAMPLE_REQUEST, {"Authorization": "Bearer not-a-token"})
        self.assertEqual((status, error), (401, {"error": {"code": "unauthorised"}}))
        self.assertEqual(seen, ["not-a-token"])

    def test_valid_token_with_auth_on_plans(self):
        self.start(["--port", "0", "--backend", "fixture"], verify_token=lambda t: t == "good")

        status, body = self.post(EXAMPLE_REQUEST, {"Authorization": "Bearer good"})

        self.assertEqual(status, 200)
        self.assertEqual(body["schemaVersion"], 1)

    def test_one_resolved_stop_is_422_cannot_plan(self):
        self.start(
            ["--port", "0", "--backend", "fixture", "--no-auth"],
            geocoder=StubGeocoder(resolvable={"Darwin"}),
        )

        status, error = self.post(EXAMPLE_REQUEST)

        self.assertEqual(status, 422)
        self.assertEqual(error["error"]["code"], "cannot_plan")

    def test_backend_that_raises_is_500_server_error_without_a_trace(self):
        def broken(prompt):
            raise RuntimeError("model exploded at C:/secret/path.py line 7")

        self.start(["--port", "0", "--backend", "fixture", "--no-auth"], generate=broken)

        with contextlib.redirect_stderr(io.StringIO()) as stderr:
            status, error = self.post(EXAMPLE_REQUEST)

        self.assertEqual((status, error), (500, {"error": {"code": "server_error"}}))
        self.assertIn("model exploded", stderr.getvalue(), "the trace belongs in the console")

    def test_backend_timeout_is_504_and_a_retry_generates_again(self):
        def slow(prompt):
            raise backends.BackendTimeout("codex exec did not finish in 50 s")

        counting = Counting(slow)
        self.start(["--port", "0", "--backend", "fixture", "--no-auth"], generate=counting)

        first = self.post(EXAMPLE_REQUEST)
        second = self.post(EXAMPLE_REQUEST)

        self.assertEqual(first, (504, {"error": {"code": "server_error"}}))
        self.assertEqual(second, first)
        self.assertEqual(counting.calls, 2, "a 5xx answer is not cached")


class ValidationTest(unittest.TestCase):
    def test_example_is_valid(self):
        request_id, answers = server.validate_request(EXAMPLE_REQUEST)
        self.assertEqual(request_id, EXAMPLE_REQUEST["requestId"])
        self.assertEqual(answers, EXAMPLE_REQUEST["answers"])

    def test_each_wrong_value_is_cannot_plan(self):
        cases = {
            "schemaVersion 2": ("schemaVersion", 2),
            "schemaVersion true": ("schemaVersion", True),
            "short requestId": ("requestId", "abc"),
            "upper-case requestId": ("requestId", "3F1C9A2E7B4D4E0F9A6C1D2E3F4A5B6C"),
            "days 15": ("answers.days", 15),
            "days as bool": ("answers.days", True),
            "heat 0": ("answers.heat", 0),
            "empty focus": ("answers.focus", []),
            "unknown focus": ("answers.focus", ["nature", "shopping"]),
            "vehicle label": ("answers.vehicle", "4WD"),
            "offGrid as string": ("answers.offGridComfortable", "yes"),
            "blank start": ("answers.startLocation", "   "),
            "81-char end": ("answers.endLocation", "x" * 81),
        }
        for label, (path, value) in cases.items():
            with self.subTest(label):
                body = json.loads(json.dumps(EXAMPLE_REQUEST))
                target = body["answers"] if path.startswith("answers.") else body
                target[path.removeprefix("answers.")] = value
                with self.assertRaises(server.CannotPlan):
                    server.validate_request(body)


class AssemblyTest(unittest.TestCase):
    def test_dropped_stop_nulls_the_leg_before_it_and_keeps_contract_order(self):
        geocoder = StubGeocoder(
            resolvable={"Darwin", "Litchfield National Park", "Nitmiluk National Park"}
        )

        stops, dropped = server.assemble_stops(FIXTURE_OUTPUT["stops"], geocoder)

        self.assertEqual(
            [s["name"] for s in stops],
            ["Darwin", "Litchfield National Park", "Nitmiluk National Park"],
        )
        self.assertEqual(dropped, 1)
        self.assertEqual(stops[0]["driveNext"], FIXTURE_OUTPUT["stops"][0]["driveNext"])
        self.assertIsNone(stops[1]["driveNext"], "its next stop (Kakadu) was dropped")
        self.assertIsNone(stops[2]["driveNext"])
        self.assertEqual(
            list(stops[0]),
            ["name", "subtitle", "lat", "lng", "placeId", "photoUrl", "duration", "driveNext",
             "hours", "fee", "tags", "aiNote", "detailedPlan", "sources"],
        )
        self.assertIsNone(stops[0]["photoUrl"])
        self.assertEqual(stops[0]["placeId"], "stub/Darwin")


class PromptTest(unittest.TestCase):
    def planner(self):
        docs = places.load_place_docs(HERE / "rag")
        return server.Planner("fixture", backends.fixture_generate, StubGeocoder(), docs, None)

    def test_prompt_files_are_the_contract_verbatim(self):
        system = (HERE / "prompts" / "system.txt").read_text(encoding="utf-8")
        user = (HERE / "prompts" / "user.txt").read_text(encoding="utf-8")
        self.assertEqual(system, contract_block("### 4.1 System prompt"))
        self.assertEqual(user, contract_block("### 4.2 User turn"))

    def test_prompt_is_system_then_context_then_user_filled_from_answers(self):
        prompt = self.planner().build_prompt(EXAMPLE_REQUEST["answers"])

        for part in (prompt.system, prompt.user):
            self.assertNotRegex(part, r"[{}]")
        self.assertIn("Between 2 and\n   7 stops", prompt.system)
        self.assertIn("Focus: nature, aboriginal_culture. Region: top_end.", prompt.user)
        self.assertIn("Comfortable off-grid:\ntrue.", prompt.user)
        self.assertIn('starts at "Darwin" and ends at "Uluru".', prompt.user)
        self.assertTrue(prompt.context.startswith(places.CONTEXT_HEADER))
        self.assertIn("## Litchfield National Park", prompt.context)
        self.assertNotIn("Uluru-Kata Tjuta National Park", prompt.context, "red_centre only")
        text = prompt.text
        self.assertLess(text.index(prompt.system), text.index(places.CONTEXT_HEADER))
        self.assertLess(text.index(places.CONTEXT_HEADER), text.index(prompt.user))

    def test_full_nt_takes_every_document_under_the_cap(self):
        docs = places.load_place_docs(HERE / "rag")
        block, left_out = places.context_block(docs, "full_nt")
        self.assertIn("## Litchfield National Park", block)
        self.assertIn("## Uluru-Kata Tjuta National Park", block)
        self.assertEqual(left_out, [])
        self.assertLessEqual(len(block), places.CONTEXT_CAP)

        big = places.PlaceDoc("big.md", "Big", (), -20.0, 133.0, "both", (), (), "x" * 13_000)
        block, left_out = places.context_block([*docs, big], "full_nt")
        self.assertEqual(left_out, ["big.md"])
        self.assertLessEqual(len(block), places.CONTEXT_CAP)


class SchemaTest(unittest.TestCase):
    def test_schema_file_is_the_contract_schema_and_requires_every_property(self):
        block = contract_block("### 3.2 JSON Schema", "json")
        schema_text = (HERE / "schema.json").read_text(encoding="utf-8")
        self.assertEqual(schema_text, block)
        stop = json.loads(schema_text)["properties"]["stops"]["items"]
        self.assertEqual(sorted(stop["required"]), sorted(stop["properties"]))
        self.assertIn("driveNext", stop["required"])
        self.assertIn("fee", stop["required"])

    def test_fixture_output_uses_every_schema_field(self):
        stop_schema = backends.load_schema()["properties"]["stops"]["items"]
        for stop in FIXTURE_OUTPUT["stops"]:
            self.assertEqual(sorted(stop), sorted(stop_schema["required"]))


class OpenRouterTest(unittest.TestCase):
    def test_sends_strict_json_schema_and_returns_the_content(self):
        sent = []

        def transport(url, headers, body, timeout):
            sent.append((url, headers, json.loads(body.decode("utf-8"))))
            reply = {"choices": [{"message": {"content": json.dumps(FIXTURE_OUTPUT)}}]}
            return 200, json.dumps(reply).encode("utf-8")

        prompt = backends.Prompt("SYSTEM", "CONTEXT", "USER")
        with mock.patch.dict(os.environ, {"OPENROUTER_API_KEY": "test-key"}):
            os.environ.pop("PLAN_MODEL", None)
            output = backends.openrouter_generate(prompt, transport=transport)

        self.assertEqual(output, FIXTURE_OUTPUT)
        url, headers, payload = sent[0]
        self.assertEqual(url, "https://openrouter.ai/api/v1/chat/completions")
        self.assertEqual(headers["Authorization"], "Bearer test-key")
        self.assertEqual(payload["model"], "openai/gpt-6-luna")
        response_format = payload["response_format"]
        self.assertEqual(response_format["type"], "json_schema")
        self.assertIs(response_format["json_schema"]["strict"], True)
        self.assertEqual(response_format["json_schema"]["schema"], backends.load_schema())
        self.assertEqual(
            payload["messages"],
            [
                {"role": "system", "content": "SYSTEM\n\nCONTEXT"},
                {"role": "user", "content": "USER"},
            ],
        )

    def test_http_error_raises_and_timeout_is_backend_timeout(self):
        prompt = backends.Prompt("S", "", "U")

        def refused(url, headers, body, timeout):
            return 401, b'{"error":"bad key"}'

        def slow(url, headers, body, timeout):
            raise TimeoutError("timed out")

        with mock.patch.dict(os.environ, {"OPENROUTER_API_KEY": "test-key"}):
            with self.assertRaises(RuntimeError):
                backends.openrouter_generate(prompt, transport=refused)
            with self.assertRaises(backends.BackendTimeout):
                backends.openrouter_generate(prompt, transport=slow)


class FakeProcess:
    def __init__(self, argv, *, stdin, stdout, stderr, cwd, env, wait=None):
        self.argv, self.cwd, self.env = argv, cwd, env
        self.stdin = stdin.read().decode("utf-8")
        self.pid = 4242
        self._wait = wait
        out_path = Path(argv[argv.index("-o") + 1])
        out_path.write_text(json.dumps(FIXTURE_OUTPUT), encoding="utf-8")

    def wait(self, timeout=None):
        if self._wait is not None:
            return self._wait(timeout)
        return 0


class CodexTest(unittest.TestCase):
    def setUp(self):
        # Never touch the real ~/.codex/auth.json from a test.
        patcher = mock.patch.object(backends, "sync_codex_auth")
        self.sync = patcher.start()
        self.addCleanup(patcher.stop)

    def test_runs_codex_exec_with_the_contract_flags_and_a_clean_home(self):
        started = []

        def popen(argv, **kwargs):
            started.append(FakeProcess(argv, **kwargs))
            return started[-1]

        prompt = backends.Prompt("SYSTEM", "CONTEXT", "USER")
        with mock.patch.dict(os.environ):
            os.environ.pop("PLAN_MODEL", None)
            os.environ.pop("PLAN_EFFORT", None)
            output = backends.codex_generate(prompt, popen=popen)

        self.assertEqual(output, FIXTURE_OUTPUT)
        process = started[0]
        argv = process.argv
        out_path = argv[argv.index("-o") + 1]
        self.assertEqual(
            argv[1:],
            ["exec", "--skip-git-repo-check", "--ephemeral", "-s", "read-only",
             "-m", "gpt-6-luna", "-c", "model_reasoning_effort=low",
             "-c", "mcp_servers={}", "-c", "features.hooks=false",
             "--output-schema", str(backends.SCHEMA_PATH), "-o", out_path, "-"],
        )
        self.assertEqual(process.env["CODEX_HOME"], str(HERE / ".codex-home"))
        self.assertEqual(process.stdin, "SYSTEM\n\nCONTEXT\n\nUSER")
        self.assertNotIn(str(REPO_ROOT), str(process.cwd), "no AGENTS.md may be picked up")
        self.assertEqual(self.sync.call_count, 2, "auth synced before and after the call")

    def test_model_and_effort_follow_the_environment(self):
        with mock.patch.dict(os.environ, {"PLAN_MODEL": "gpt-x", "PLAN_EFFORT": "medium"}):
            argv = backends.codex_command("codex", "out.json")
        self.assertIn("gpt-x", argv)
        self.assertIn("model_reasoning_effort=medium", argv)

    def test_timeout_kills_the_process_tree_and_raises_backend_timeout(self):
        def never(timeout):
            raise subprocess.TimeoutExpired("codex", timeout)

        def popen(argv, **kwargs):
            return FakeProcess(argv, wait=never, **kwargs)

        with mock.patch.object(backends, "_kill_tree") as kill:
            with self.assertRaises(backends.BackendTimeout):
                backends.codex_generate(backends.Prompt("S", "", "U"), popen=popen, timeout=50)
        kill.assert_called_once()
        self.assertEqual(self.sync.call_count, 2, "auth synced even when the call times out")


class AuthSyncTest(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.home = Path(tmp.name) / "home-auth.json"
        self.user = Path(tmp.name) / "user-auth.json"

    def write(self, path, text, mtime):
        path.write_text(text, encoding="utf-8")
        os.utime(path, (mtime, mtime))

    def test_missing_home_copy_is_created_from_the_user_file(self):
        self.write(self.user, "user", 1000)
        backends.sync_codex_auth(self.home, self.user)
        self.assertEqual(self.home.read_text(encoding="utf-8"), "user")

    def test_user_refresh_replaces_a_stale_home_copy(self):
        self.write(self.home, "old", 1000)
        self.write(self.user, "refreshed by the CLI", 2000)
        backends.sync_codex_auth(self.home, self.user)
        self.assertEqual(self.home.read_text(encoding="utf-8"), "refreshed by the CLI")

    def test_server_refresh_is_written_back_to_the_user_file(self):
        self.write(self.user, "old", 1000)
        self.write(self.home, "refreshed by the server", 2000)
        backends.sync_codex_auth(self.home, self.user)
        self.assertEqual(self.user.read_text(encoding="utf-8"), "refreshed by the server")

    def test_a_second_sync_changes_nothing(self):
        self.write(self.home, "old", 1000)
        self.write(self.user, "new", 2000)
        backends.sync_codex_auth(self.home, self.user)
        backends.sync_codex_auth(self.home, self.user)
        self.assertEqual(self.user.read_text(encoding="utf-8"), "new")
        self.assertEqual(self.home.read_text(encoding="utf-8"), "new")


class GeocoderTest(unittest.TestCase):
    def test_place_documents_first_then_nominatim_cached(self):
        docs = places.load_place_docs(HERE / "rag")
        fetched = []

        def fetch(url):
            fetched.append(url)
            if "Daly" in url:
                return [{"lat": "-12.67", "lon": "132.83", "osm_type": "relation", "osm_id": 123}]
            if "Perth" in url:
                return [{"lat": "-31.95", "lon": "115.86", "osm_type": "node", "osm_id": 9}]
            if "Offline" in url:
                raise urllib.error.URLError("no network")
            return []

        with tempfile.TemporaryDirectory() as tmp:
            cache = Path(tmp) / "geocode.json"
            geocoder = places.Geocoder(docs, cache, fetch=fetch, min_interval=0)

            self.assertEqual(
                geocoder.resolve("  LITCHFIELD  "), places.Place(-13.183, 130.6805, "litchfield.md")
            )
            self.assertEqual(geocoder.resolve("Ayers Rock").place_id, "uluru.md")
            self.assertEqual(fetched, [], "a place document answers without Nominatim")

            self.assertEqual(
                geocoder.resolve("Daly Waters"),
                places.Place(-12.67, 132.83, "relation/123"),
            )
            self.assertIsNone(geocoder.resolve("Perth"), "outside the NT box is unresolved")
            self.assertIsNone(geocoder.resolve("Nowhere Creek"))
            with contextlib.redirect_stdout(io.StringIO()):
                self.assertIsNone(geocoder.resolve("Offline Gorge"))
            self.assertEqual(
                fetched[0],
                "https://nominatim.openstreetmap.org/search?format=json&limit=1"
                "&countrycodes=au&q=Daly+Waters%2C+Northern+Territory",
            )

            again = places.Geocoder(docs, cache, fetch=fetch, min_interval=0)
            count = len(fetched)
            self.assertEqual(again.resolve("daly waters").place_id, "relation/123")
            self.assertIsNone(again.resolve("Perth"))
            self.assertIsNone(again.resolve("Nowhere Creek"))
            self.assertEqual(len(fetched), count, "answers came from geocode.json")
            with contextlib.redirect_stdout(io.StringIO()):
                again.resolve("Offline Gorge")
            self.assertEqual(len(fetched), count + 1, "a network failure is not cached")

    def test_a_malformed_place_document_stops_the_load(self):
        with tempfile.TemporaryDirectory() as tmp:
            bad = Path(tmp) / "bad.md"
            bad.write_text("---\nname: Somewhere\nlat: -12.0\nregion: top_end\n---\n", encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "bad.md.*lng"):
                places.load_place_docs(tmp)


class CliTest(unittest.TestCase):
    def test_help_prints_the_options(self):
        result = subprocess.run(
            [sys.executable, str(HERE / "server.py"), "--help"],
            capture_output=True,
            text=True,
            timeout=30,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        for option in ("--port", "--backend", "--no-auth", "codex", "openrouter", "fixture"):
            self.assertIn(option, result.stdout)


if __name__ == "__main__":
    unittest.main()
