# Task-45 — The planning server: the contract's endpoint on the operator's machine, model behind one switch

> **Execution:** agent `ultracode` · effort `xhigh`
> *Why:* A new component (Python, outside `terra_nt/`) that the app already talks to through
> `docs/PHASE-3-CONTRACT.md`; the contract is complete and the acceptance is a smoke run, so one
> builder owns it end to end. No screen.

**Lane**
- OWNS: `tools/plan_server/` (new), `docs/PHASE-3-CONTRACT.md` (§3.2 schema `required` list and §7 only), `.gitignore` (append-only: the server's local state)
- MUST NOT TOUCH: `terra_nt/`, `tools/plan_stub/`, `tools/goal_gate.py`, `CLAUDE.md`, `AGENTS.md`, `docs/PRD.md`, `docs/TASKS_INDEX.md`
- GATE: `python -m unittest discover -s tools/plan_server -p "test_*.py" -v`
- DEPENDS ON: none

## Goal

`POST /v1/itinerary` exactly as `docs/PHASE-3-CONTRACT.md` §1–§3 describe, running on the
operator's Windows machine for the Thursday 2026-10-01 demo, so the app's `PLAN_API_URL` can
point at it and generate a real itinerary from the fifteen answers.

## Why

Decided with the operator on 2026-09-29: the operator owns the server; teammates only supply
RAG data. The model runs on the operator's Codex subscription for the demo and moves to an API
later, so the model call sits behind one switch and nothing else changes when it moves.

## The contracts — fixed

1. **Stack:** Python 3.13 standard library (`http.server.ThreadingHTTPServer`, `subprocess`,
   `json`, `urllib`), plus `google-auth` for the token check only, pinned in
   `tools/plan_server/requirements.txt`. No web framework.
2. **Run:** `python tools/plan_server/server.py --port 8787 [--backend codex|openrouter|fixture] [--no-auth]`.
   Defaults: port 8787, backend `codex`, auth on. `--no-auth` prints a loud warning.
3. **Auth:** `Authorization: Bearer <Firebase ID token>` verified with
   `google.oauth2.id_token.verify_firebase_token(token, Request(), audience="terra-nt-cdu")`.
   Missing or invalid → `401 {"error":{"code":"unauthorised"}}`.
4. **Request:** validate §2 (every field present, types and value sets as in the table,
   `schemaVersion == 1`). Anything wrong → `400 {"error":{"code":"cannot_plan","message":…}}`.
   Same `requestId` seen before → return the cached response, no second generation.
5. **Prompt:** §4.1 system prompt verbatim, then the RAG context block (item 7), then the §4.2
   user turn filled from `answers`. Kept as text files next to the server, not rebuilt in code.
6. **Model backends**, one function `generate(prompt) -> dict` per backend, chosen by `--backend`:
   - `codex` (default): `codex exec --skip-git-repo-check --ephemeral -s read-only -m gpt-6-luna
     -c model_reasoning_effort=low -c 'mcp_servers={}' -c features.hooks=false
     --output-schema <schema file> -o <out file> -` with the prompt on stdin, and
     `CODEX_HOME` set to `tools/plan_server/.codex-home/`. On start the server copies
     `~/.codex/auth.json` there if it is missing; nothing else from the user's Codex config is
     used. Measured 2026-09-29: 18–30 s with a clean `CODEX_HOME`, 59 s with the user's hooks
     loaded — the clean home is required, not an optimisation. Timeout 50 s → `504`-class
     failure (`5xx`, `server_error`). Model and effort overridable by env `PLAN_MODEL`,
     `PLAN_EFFORT`.
   - `openrouter`: `POST https://openrouter.ai/api/v1/chat/completions` with
     `response_format: {type: "json_schema", json_schema: {name, strict: true, schema}}`,
     model from env `PLAN_MODEL` (default `openai/gpt-6-luna`), key from env
     `OPENROUTER_API_KEY`. Written and unit-tested against a fake transport; not run live.
   - `fixture`: returns a fixed valid model output instantly (for the gate and for rehearsal).
7. **RAG context:** every `*.md` file in `tools/plan_server/rag/` is a place document with a
   front-matter block — `name`, `aliases` (list), `lat`, `lng`, `region` (`top_end` |
   `red_centre` | `both`), `tags` (the five tag strings), `sources` (URLs) — and a free-text
   body (hours, fees, permits, seasonal closures, access, what to do). The server selects the
   documents whose `region` matches the request (`full_nt` takes all), caps the block at
   ~12 000 characters, and inserts it between §4.1 and §4.2 as
   `Context (use it for facts; cite its URLs in "sources"):`. Ship two example documents
   (`rag/litchfield.md`, `rag/uluru.md`) written from the existing seed data with real
   public source URLs, and `rag/README.md` stating the format — the teammates' documents
   will follow it. No embeddings, no vector store.
8. **Geocoding:** for each stop, first a case-insensitive match of the stop name against the
   RAG documents' `name`/`aliases` (their `lat`/`lng`), else Nominatim
   (`https://nominatim.openstreetmap.org/search?format=json&limit=1&countrycodes=au&q=<name>, Northern Territory`)
   with an identifying `User-Agent` naming the project (no personal email), at most one
   request per second, results cached in `tools/plan_server/.cache/geocode.json`.
   A result outside the NT box of §3.3 counts as unresolved. Unresolved stops are dropped;
   the stop before a dropped one gets `driveNext: null`. Fewer than 2 stops left →
   `422 cannot_plan`. `placeId` = the Nominatim `osm_type`+`osm_id` or the RAG file name;
   `photoUrl` = `null` (`docs/PRD.md` P7 stays open).
9. **Response:** §3.1 shape with `schemaVersion: 1`, UTF-8 JSON, one log line per request
   (requestId, backend, seconds, stops kept/dropped). Any unexpected exception → `500
   {"error":{"code":"server_error"}}`, never a stack trace in the body.
10. **Contract fix (§3.2):** the schema's stop `required` list must name every property —
    add `driveNext` and `fee` (they stay nullable by type). OpenAI's strict structured output
    rejected the current schema on 2026-09-29 (`invalid_json_schema`: "Missing 'driveNext'").
    The server's schema file is this corrected schema. §7: record that the operator owns
    the server (2026-09-29) and which choices it made (hosting on the operator's machine,
    backend switch, RAG format, Nominatim).
11. **Reaching it:** `tools/plan_server/README.md` — install, run, and three ways to point
    the app at it: emulator `PLAN_API_URL=http://10.0.2.2:8787`; a physical Android phone
    on the same Wi-Fi `http://<LAN IP>:8787` (debug builds only); any phone including an
    iPhone through `cloudflared tunnel --url http://localhost:8787` (the https URL it prints).
    Local state (`.codex-home/`, `.cache/`) is gitignored.

## Acceptance Criteria (DoD)

- [ ] The GATE passes: a smoke test starts the server in-process on a free port with
      `--backend fixture --no-auth`, a stubbed geocoder, and posts the §2 example body; it
      asserts `200`, `schemaVersion == 1`, ≥ 2 stops each with numeric `lat`/`lng` inside the
      NT box, and that a second post with the same `requestId` does not call the backend again.
- [ ] The same test file asserts: a missing answer field → `400 cannot_plan`; no
      `Authorization` with auth on → `401 unauthorised`; a geocoder that resolves only one
      stop → `422 cannot_plan`; a backend that raises → `500 server_error`; the openrouter
      backend sends `strict: true` with the schema (fake transport).
- [ ] `docs/PHASE-3-CONTRACT.md` §3.2 lists `driveNext` and `fee` in `required`, and the
      server's schema file is identical to it.
- [ ] `python tools/plan_server/server.py --help` prints the options.
- [ ] Manual, by the orchestrator after integration (not the builder): one real generation
      with `--backend codex --no-auth` returns a valid body in under 50 s.
