"""The model behind one switch (Task-45 contract 6).

Each backend is one function `generate(prompt) -> dict` returning the model's
output in the shape of schema.json (docs/PHASE-3-CONTRACT.md §3.2). Moving the
model from the Codex subscription to an API changes `--backend`, nothing else.
"""

import json
import os
import shutil
import subprocess
import tempfile
import urllib.error
import urllib.request
from dataclasses import dataclass
from pathlib import Path

HERE = Path(__file__).resolve().parent
SCHEMA_PATH = HERE / "schema.json"
FIXTURE_PATH = HERE / "fixture_output.json"
CODEX_HOME = HERE / ".codex-home"
USER_CODEX_AUTH = Path.home() / ".codex" / "auth.json"
TIMEOUT_SECONDS = 50

CODEX_MODEL = "gpt-6-luna"
CODEX_EFFORT = "low"
OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"
OPENROUTER_MODEL = "openai/gpt-6-luna"


class BackendTimeout(Exception):
    """The model did not answer within TIMEOUT_SECONDS; the server answers 504."""


@dataclass(frozen=True)
class Prompt:
    system: str  # §4.1, filled
    context: str  # the RAG block, "" when no document matched
    user: str  # §4.2, filled

    @property
    def text(self):
        return "\n\n".join(part for part in (self.system, self.context, self.user) if part)


def load_schema():
    return json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))


# --- fixture --------------------------------------------------------------


def fixture_generate(prompt):
    """A fixed valid model output, instantly: for the gate and for rehearsal."""
    return json.loads(FIXTURE_PATH.read_text(encoding="utf-8"))


# --- codex ----------------------------------------------------------------


def prepare_codex_home():
    """Clean CODEX_HOME holding only the user's auth.json; codex must be on PATH.

    The user's hooks and MCP servers roughly double a generation's time
    (measured 2026-09-29), so nothing else from ~/.codex is used.
    """
    if shutil.which("codex") is None:
        raise SystemExit("codex is not on PATH; install the Codex CLI or pick another --backend")
    CODEX_HOME.mkdir(exist_ok=True)
    if not USER_CODEX_AUTH.exists():
        raise SystemExit(f"{USER_CODEX_AUTH} is missing; run `codex login` first")
    sync_codex_auth()


def sync_codex_auth(home_auth=None, user_auth=None):
    """Copy the newer of the two auth.json files over the older one.

    Codex rotates the refresh token on every refresh, so whichever copy did not
    refresh stops working ("refresh token was already used", 2026-10-07): the
    user's CLI refreshing strands .codex-home, and a refresh here strands the
    user's CLI. Runs at start and around every call.
    """
    home_auth = home_auth or CODEX_HOME / "auth.json"
    user_auth = user_auth or USER_CODEX_AUTH
    if not user_auth.exists():
        return
    if not home_auth.exists() or user_auth.stat().st_mtime > home_auth.stat().st_mtime:
        shutil.copy2(user_auth, home_auth)
    elif (home_auth.stat().st_mtime > user_auth.stat().st_mtime
          and home_auth.read_bytes() != user_auth.read_bytes()):
        shutil.copy2(home_auth, user_auth)


def codex_command(executable, out_path):
    return [
        executable,
        "exec",
        "--skip-git-repo-check",
        "--ephemeral",
        "-s",
        "read-only",
        "-m",
        os.environ.get("PLAN_MODEL") or CODEX_MODEL,
        "-c",
        f"model_reasoning_effort={os.environ.get('PLAN_EFFORT') or CODEX_EFFORT}",
        "-c",
        "mcp_servers={}",
        "-c",
        "features.hooks=false",
        "--output-schema",
        str(SCHEMA_PATH),
        "-o",
        str(out_path),
        "-",
    ]


def _kill_tree(process):
    # codex on Windows is an npm .cmd shim: cmd.exe -> node -> codex.exe.
    # Killing only cmd.exe would leave the model call running.
    if os.name == "nt":
        subprocess.run(
            ["taskkill", "/F", "/T", "/PID", str(process.pid)],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
    else:
        process.kill()
    try:
        process.wait(timeout=5)
    except subprocess.TimeoutExpired:
        pass


def codex_generate(prompt, *, popen=subprocess.Popen, timeout=TIMEOUT_SECONDS):
    """`codex exec` with the prompt on stdin, in a scratch directory (so no
    AGENTS.md is picked up), CODEX_HOME = .codex-home/."""
    executable = shutil.which("codex") or "codex"
    env = dict(os.environ, CODEX_HOME=str(CODEX_HOME))
    with tempfile.TemporaryDirectory(prefix="plan-", ignore_cleanup_errors=True) as scratch:
        scratch = Path(scratch)
        prompt_path = scratch / "prompt.txt"
        prompt_path.write_bytes(prompt.text.encode("utf-8"))
        out_path = scratch / "out.json"
        log_path = scratch / "codex.log"
        sync_codex_auth()
        # Files, not pipes: a pipe held open by an orphaned grandchild would
        # block the timeout below.
        with open(prompt_path, "rb") as stdin, open(log_path, "wb") as log:
            process = popen(
                codex_command(executable, out_path),
                stdin=stdin,
                stdout=log,
                stderr=subprocess.STDOUT,
                cwd=scratch,
                env=env,
            )
            try:
                code = process.wait(timeout=timeout)
            except subprocess.TimeoutExpired:
                _kill_tree(process)
                raise BackendTimeout(f"codex exec did not finish in {timeout} s") from None
            finally:
                sync_codex_auth()
        if code != 0:
            tail = log_path.read_text(encoding="utf-8", errors="replace")[-1500:]
            raise RuntimeError(f"codex exec exited {code}:\n{tail}")
        return json.loads(out_path.read_text(encoding="utf-8"))


# --- openrouter -----------------------------------------------------------


def urllib_post(url, headers, body, timeout):
    """(status, body bytes). The real transport; tests pass a fake."""
    request = urllib.request.Request(url, data=body, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            return response.status, response.read()
    except urllib.error.HTTPError as error:
        return error.code, error.read()
    except urllib.error.URLError as error:
        if isinstance(error.reason, TimeoutError):
            raise TimeoutError(str(error.reason)) from None
        raise


def openrouter_request(prompt):
    return {
        "model": os.environ.get("PLAN_MODEL") or OPENROUTER_MODEL,
        "messages": [
            {"role": "system", "content": "\n\n".join(p for p in (prompt.system, prompt.context) if p)},
            {"role": "user", "content": prompt.user},
        ],
        "response_format": {
            "type": "json_schema",
            "json_schema": {"name": "plan_response", "strict": True, "schema": load_schema()},
        },
    }


def openrouter_generate(prompt, *, transport=urllib_post, timeout=TIMEOUT_SECONDS):
    key = os.environ.get("OPENROUTER_API_KEY")
    if not key:
        raise RuntimeError("OPENROUTER_API_KEY is not set")
    headers = {"Authorization": f"Bearer {key}", "Content-Type": "application/json"}
    body = json.dumps(openrouter_request(prompt)).encode("utf-8")
    try:
        status, raw = transport(OPENROUTER_URL, headers, body, timeout)
    except TimeoutError:
        raise BackendTimeout(f"OpenRouter did not answer in {timeout} s") from None
    if status != 200:
        raise RuntimeError(f"OpenRouter answered HTTP {status}: {raw[:500]!r}")
    content = json.loads(raw)["choices"][0]["message"]["content"]
    return json.loads(content)


GENERATORS = {
    "codex": codex_generate,
    "openrouter": openrouter_generate,
    "fixture": fixture_generate,
}


def prepare(backend):
    """Start-up checks, so a missing login or key fails before the first request."""
    if backend == "codex":
        prepare_codex_home()
    elif backend == "openrouter" and not os.environ.get("OPENROUTER_API_KEY"):
        raise SystemExit("OPENROUTER_API_KEY is not set")
