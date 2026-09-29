# Planning server — `POST /v1/itinerary`

The endpoint `docs/PHASE-3-CONTRACT.md` §1–§4 describes, run on the operator's machine
(`docs/PRD.md` D17). It checks the Firebase ID token, validates the fifteen answers, fills
the §4 prompt with the place documents in `rag/`, asks the model for the §3.2 schema,
geocodes every stop, drops what does not resolve inside the Northern Territory and answers
with the §3.1 body. The app only needs `PLAN_API_URL` pointed here.

## Install

Python 3.13, from the repo root:

    pip install -r tools/plan_server/requirements.txt

`google-auth` (with `requests` as its transport) is only for the token check; with
`--no-auth` the server runs on the standard library alone. The default backend also needs
the Codex CLI on `PATH`, logged in once with `codex login`.

## Run

    python tools/plan_server/server.py --port 8787 [--backend codex|openrouter|fixture] [--no-auth]

| Option | Default | Meaning |
|---|---|---|
| `--port` | `8787` | Listens on every interface (`0.0.0.0`), so the emulator, the LAN and a tunnel all reach it. |
| `--backend` | `codex` | Which model answers; see below. |
| `--no-auth` | off | Accepts requests without a token and prints a warning. Emulator and rehearsal only. |

Each request prints one line: time, `requestId`, backend, HTTP status, seconds, stops kept
and dropped, and `(cached)` when a repeated `requestId` was answered without generating.
A stack trace goes to the console, never into a response body.

For a rehearsal with no model and no login:

    python tools/plan_server/server.py --backend fixture --no-auth

### Backends — the one switch

| `--backend` | What runs | Settings |
|---|---|---|
| `codex` | `codex exec` on the operator's Codex subscription, prompt on stdin, `--output-schema schema.json`. 18–30 s measured. After 50 s the call is killed and the app gets `504`. | `PLAN_MODEL` (default `gpt-6-luna`), `PLAN_EFFORT` (default `low`) |
| `openrouter` | `POST https://openrouter.ai/api/v1/chat/completions` with strict `json_schema` output. The route for later; unit-tested, not yet run live. | `OPENROUTER_API_KEY` (required), `PLAN_MODEL` (default `openai/gpt-6-luna`) |
| `fixture` | `fixture_output.json`, instantly: a four-stop Top End plan. The request's answers are ignored. | none |

The `codex` backend runs with `CODEX_HOME=tools/plan_server/.codex-home/`. On start the
server copies `~/.codex/auth.json` there if it is missing; nothing else from your Codex
config (hooks, MCP servers, AGENTS.md) is loaded, which is what keeps a generation under
30 s. If the backend starts failing with a login error, run `codex login`, delete
`.codex-home/auth.json` and restart the server.

### The prompt and the place documents

`prompts/system.txt` and `prompts/user.txt` are §4.1 and §4.2 verbatim; the test suite
fails if they drift from the contract. `schema.json` is the §3.2 schema, likewise checked.
Between the two prompts the server inserts the place documents in `rag/` whose region
matches the request (`full_nt` takes all), about 12 000 characters at most. The format
teammates write to is in `rag/README.md`; restart the server after adding a document.

### Geocoding

A stop whose name matches a place document's `name` or `aliases` (ignoring case) takes
that document's coordinates. Any other name goes to Nominatim (OpenStreetMap), one request
a second, and the answer is cached in `.cache/geocode.json`, so a place is looked up once.
A result outside the NT box of §3.3 is unresolved. Unresolved stops are dropped; fewer
than two left is `422 cannot_plan`. `photoUrl` is always `null` (`docs/PRD.md` P7).

## Point the app at it

`PLAN_API_URL` goes in `terra_nt/.env`, no trailing slash, and reaches the build through
`--dart-define-from-file=.env` (see the repo `README.md`). Pick one:

1. **Android emulator on this machine:** `PLAN_API_URL=http://10.0.2.2:8787`
   (the emulator's alias for the host).
2. **A physical Android phone on the same Wi-Fi:** `PLAN_API_URL=http://<LAN IP>:8787`,
   where the LAN IP is the IPv4 address of this machine's Wi-Fi adapter (`ipconfig`).
   Debug builds only: release builds refuse plain HTTP. Windows asks once whether Python
   may accept connections; allow it on private networks.
3. **Any phone, including an iPhone:** run
   `cloudflared tunnel --url http://localhost:8787` (install with
   `winget install --id Cloudflare.cloudflared`) and set `PLAN_API_URL` to the
   `https://….trycloudflare.com` URL it prints. The URL changes every time the tunnel
   starts. Keep auth on: the tunnel is public.

## Local state

`.codex-home/` (a copy of your Codex login) and `.cache/` (the geocode cache) live next to
the server and are gitignored. Deleting either is safe.

## Tests

    python -m unittest discover -s tools/plan_server -p "test_*.py" -v

No network and no Codex login: the server runs in-process with the fixture backend and a
stubbed geocoder, and the `codex` and `openrouter` backends run against fakes.
