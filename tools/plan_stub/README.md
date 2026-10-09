# plan_stub

Run: `python tools/plan_stub/server.py --port 8787 --mode ok`

Modes: `ok` · `slow` · `cannot_plan` · `rate_limited` · `error` · `invalid` · `refuse`.

Emulator `.env`: `PLAN_API_URL=http://10.0.2.2:8787`

Logs one line per request with `requestId` and whether `Authorization` was present.
