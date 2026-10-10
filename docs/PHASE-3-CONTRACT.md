# Phase 3 contract — what leaves the app, what comes back

Written 2026-09-22 by the app side. **Binding for the app from `docs/PRD.md` D14, and the
document the server owner builds against.** The division of labour is fixed in
`docs/PHASE-2-3-FOUNDATION.md` §1 and repeated here because it decides who reads which
section:

- **The app** (this repo) builds the request from the fifteen onboarding answers, sends it
  to one endpoint with a Firebase ID token, validates the response, and turns it into an
  `Itinerary` or a typed failure. §2, §3, §5, §6.
- **The server** (Tarık since 2026-09-29, `tools/plan_server/`; the RAG documents are the teammates') hosts the endpoint, verifies the token, fills the prompt in
  §4 from the request, calls the model with the schema in §3.2, geocodes every place name,
  drops what does not resolve, and returns the response. §3, §4, §7.

Nothing in the app knows what model runs, whether it is fine-tuned or RAG, or what the
prompt says. The app can be built, tested and toured against the stub in §8 before the
server exists. When the server exists, only `PLAN_API_URL` changes.

Research behind the shape (2026-09-22): every commercial planner surveyed calls the model
from a backend and returns a structured day-by-day plan; the ones that work resolve
model-named places against a places database and drop what does not resolve; OpenAI,
Gemini and Anthropic now guarantee schema-conformant JSON at the API, so the "return only
JSON" prompt and the JSON-repair loop are legacy patterns.

---

## 1. Transport

| | |
|---|---|
| Endpoint | `POST {PLAN_API_URL}/v1/itinerary` — `PLAN_API_URL` has no trailing slash |
| Headers | `Authorization: Bearer <Firebase ID token>` · `Content-Type: application/json; charset=utf-8` · `Accept: application/json` |
| Body | `PlanRequest` (§2), UTF-8 JSON |
| Client timeout | **60 000 ms** from send to last byte, one value, no per-phase split |
| Idempotency | `requestId` in the body; a retry after a timeout resends the **same** `requestId`, and the server may answer from cache instead of generating again |

Responses:

| HTTP | Body | App failure (`PlanFailure`) | User sees |
|---|---|---|---|
| `200` | `PlanResponse` (§3) | — | Result |
| `400`, `422` | `{ "error": { "code": "cannot_plan", "message": "…" } }` | `cannotPlan` | "We couldn't plan this trip." — no retry, back to the answers |
| `401` | `{ "error": { "code": "unauthorised" } }` | `unauthorised` | "Your session has expired. Sign in again." |
| `429` | `{ "error": { "code": "rate_limited", "retryAfterSeconds": 30 } }` | `rateLimited` | try-again copy |
| `5xx`, malformed body, connection refused | any | `serverError` / `invalidResponse` / `network` | try-again copy |
| no response within the timeout | — | `timeout` | try-again copy |

The `message` field is for logs, never for the screen; the app's copy is fixed in
`docs/PRD.md` §3.4. `code` is the only field the app reads from an error body; an
unknown code is `serverError`.

---

## 2. Outbound — `PlanRequest`

Built in tier 1 (`terra_nt/lib/core/util/plan_request.dart`) from `OnboardingAnswers`.
Every answer is a **stable machine key**, never the label the screen shows; the label may
be reworded without changing the wire. The key table is the contract and lives in
`terra_nt/lib/data/seed/onboarding_options.dart` next to the labels.

```json
{
  "schemaVersion": 1,
  "requestId": "3f1c9a2e7b4d4e0f9a6c1d2e3f4a5b6c",
  "answers": {
    "ageRange": "26_35",
    "days": 7,
    "companions": "couple",
    "focus": ["nature", "aboriginal_culture"],
    "vehicle": "four_wd",
    "budget": "mid_range",
    "accommodation": "camping",
    "activityLevel": "medium",
    "region": "top_end",
    "offRoadConfidence": "medium",
    "heat": 3,
    "campingPreference": "mixed",
    "wildlifeInterest": "interested",
    "offGridComfortable": true,
    "startLocation": "Darwin",
    "endLocation": "Uluru"
  }
}
```

| Field | Type | Values |
|---|---|---|
| `schemaVersion` | int | `1`. The server rejects a version it cannot serve with `400 cannot_plan` |
| `requestId` | string | 32 lowercase hex chars, generated per generation attempt, reused on retry |
| `ageRange` | string | `18_25` · `26_35` · `36_50` · `50_plus` |
| `days` | int | 1–14 |
| `companions` | string | `solo` · `couple` · `family` · `friends` |
| `focus` | string[] | ≥1 of `nature` · `aboriginal_culture` · `adventure` · `relaxation` |
| `vehicle` | string | `four_wd` · `campervan` · `standard_car` · `guided_tour` |
| `budget` | string | `budget` · `mid_range` · `luxury` |
| `accommodation` | string | `camping` · `motel_cabin` · `hotel` |
| `activityLevel` | string | `low` · `medium` · `high` |
| `region` | string | `top_end` · `red_centre` · `full_nt` |
| `offRoadConfidence` | string | `low` · `medium` · `high` |
| `heat` | int | 1–5, 1 = "Not well at all", 5 = "Thrives in the heat" |
| `campingPreference` | string | `camping` · `mixed` · `resort` |
| `wildlifeInterest` | string | `not_fussed` · `interested` · `big_draw` |
| `offGridComfortable` | bool | |
| `startLocation`, `endLocation` | string | location names, trimmed, 1–80 chars; the app selects presets from D19, while the server still accepts free text |

Every field is required; the app never sends `null`, because onboarding gates every step
(`docs/PRD.md` §3.3). A request missing a field is an app bug, and the server answers
`400 cannot_plan`.

---

## 3. Inbound — `PlanResponse`

### 3.1 Shape

```json
{
  "schemaVersion": 1,
  "title": "Top End in 7 days: Darwin to Kakadu",
  "stops": [
    {
      "name": "Litchfield National Park",
      "subtitle": "Waterfalls & swimming holes",
      "lat": -13.1830,
      "lng": 130.6805,
      "placeId": "ChIJ…",
      "photoUrl": null,
      "duration": "1 day",
      "driveNext": "230 km · 3h to Kakadu National Park",
      "hours": "Park open 24 hours; visitor centre 8:00am–4:30pm",
      "fee": "Free entry",
      "tags": ["Nature", "Adventure"],
      "aiNote": "Closer to Darwin than Kakadu, so it works as the easier first stop. Wangi and Florence Falls are both safe for swimming in the dry season.",
      "detailedPlan": [
        { "time": "9:00am", "activity": "Drive from Darwin, Batchelor stop for fuel" },
        { "time": "11:00am", "activity": "Florence Falls swim" }
      ],
      "sources": ["https://nt.gov.au/parks/find-a-park/litchfield-national-park"]
    }
  ]
}
```

The stop maps one-to-one onto the phase-1 `Stop` (`docs/PRD.md` §5.3). The **model
produces** `name`, `subtitle`, `duration`, `driveNext`, `hours`, `fee`, `tags`, `aiNote`,
`detailedPlan`, `sources`. The **server adds** `lat`, `lng`, `placeId`, `photoUrl` from
geocoding, and drops any stop whose name did not resolve. `title` comes from the model.

### 3.2 JSON Schema — what the server asks the model for

This is the schema handed to the model's structured-output mode (`response_schema` on
Gemini, `json_schema` on OpenAI, `output_config.format` on Anthropic). The server adds
`schemaVersion`, `lat`, `lng`, `placeId`, `photoUrl` after geocoding; the model never
sees or writes them.

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": ["title", "stops"],
  "properties": {
    "title": { "type": "string" },
    "stops": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": ["name", "subtitle", "duration", "driveNext", "hours", "fee", "tags", "aiNote", "detailedPlan", "sources"],
        "properties": {
          "name":         { "type": "string" },
          "subtitle":     { "type": "string" },
          "duration":     { "type": "string" },
          "driveNext":    { "type": ["string", "null"] },
          "hours":        { "type": "string" },
          "fee":          { "type": ["string", "null"] },
          "tags":         { "type": "array", "items": { "type": "string", "enum": ["Nature", "Culture", "Adventure", "Wildlife", "Relaxation"] } },
          "aiNote":       { "type": "string" },
          "detailedPlan": { "type": "array", "items": {
            "type": "object", "additionalProperties": false, "required": ["time", "activity"],
            "properties": { "time": { "type": "string" }, "activity": { "type": "string" } } } },
          "sources":      { "type": "array", "items": { "type": "string" } }
        }
      }
    }
  }
}
```

Length and format constraints are in the prompt (§4), not the schema — the three
providers' schema subsets do not all support `minLength`/`pattern`.

### 3.3 Validation on the app side — per field, once, at the boundary

`parsePlanResponse` (`terra_nt/lib/core/util/plan_response.dart`, tier 1) reads the body
and returns an `Itinerary` or throws `PlanFailure.invalidResponse`. No screen ever sees a
half-parsed response. This table answers `docs/PRD.md` P5.

| Field | Missing or wrong type | Kept as |
|---|---|---|
| `schemaVersion` | ≠ 1 | **`invalidResponse`** |
| `title` | missing, empty, not a string | `"${days}-day Northern Territory trip"` |
| `stops` | not a list | `invalidResponse` |
| stop `name` | missing or empty | **stop dropped** |
| stop `lat`/`lng` | missing, not numbers, or outside the NT box `lat −26.5…−10.5`, `lng 128.5…138.5` | **stop dropped** — a pin outside the Territory is a geocoding miss |
| stop `subtitle` | missing | `""` |
| stop `duration` | missing | `"1 day"` |
| stop `driveNext` | missing or null | `null` — the row shows `Drive time unavailable` (V9) |
| stop `hours` | missing | `"Hours not listed"` |
| stop `fee` | missing or null | `null` — the row hides |
| stop `tags` | missing, or an unknown value | missing → `[]`; unknown values kept — `tagColor()` falls back to `inkTertiary` by contract |
| stop `aiNote` | missing | `""` |
| stop `detailedPlan` | missing, or an entry without both strings | missing → `[]`; a bad entry is dropped, the rest kept |
| stop `photoUrl` | not an `http(s)` URL | `null` |
| stop `placeId`, `sources` | anything | **ignored in this wave** — parsed past, not stored |
| valid stops after dropping | fewer than **2** | **`invalidResponse`** — that is not an itinerary |
| valid stops | more than **14** | first 14 kept |

`days` is the answer that produced the request; the parser takes it as a parameter for
the title fallback. Nothing else in the response is compared to the request.

---

## 4. The prompt — server side, designed here

The server owns the template file and fills it from the request. It is written here so
that the model's output and the app's parser agree on the same words. **P4 answered.**
The server may add retrieved context (the RAG passages) between the system prompt and the
user turn; it must not change the rules or the output vocabulary.

### 4.1 System prompt

```
You are Terra NT's route planner: a Northern Territory (Australia) road-trip expert who
turns a traveller's answers into a stop-by-stop itinerary.

Rules — every one is checked by software, not by a reader:
1. Only real, named places in the Northern Territory: national parks, towns,
   roadhouses, gorges, waterholes, cultural centres, lookouts. Use the official name a
   map search would find ("Nitmiluk National Park", not "Katherine Gorge area").
2. Never output coordinates, addresses or map links. Names only; software resolves them.
3. One stop is one place the traveller sleeps or spends most of a day at. Between 2 and
   {days} stops, and never more than 14. The first stop is where the trip starts and the
   last is where it ends when those are places in the Northern Territory; otherwise the
   nearest sensible NT gateway.
4. Respect the vehicle: a standard_car itinerary uses sealed roads only; campervan avoids
   4WD-only tracks; four_wd may use unsealed roads only when offRoadConfidence is medium
   or high; guided_tour stays where tours actually run.
5. Respect the region: top_end stays north of Katherine, red_centre stays around Alice
   Springs and Uluru, full_nt connects both along the Stuart Highway.
6. Respect the season for what is written today: note wet-season closures (November to
   April) in "hours" or "aiNote" when a place has them; do not send a low heat tolerance
   traveller on long midday walks.
7. Aboriginal land and sacred sites: name permits where they are required (for example
   Arnhem Land), never suggest climbing Uluru, and use the dual names where they exist
   ("Uluru-Kata Tjuta National Park").
8. Every fact you state about hours, fees, permits or closures must come from the
   provided context or be marked in "aiNote" as "check before you go". Put the URLs
   you relied on in "sources"; an empty list is allowed, an invented URL is not.

Output format — produce exactly the JSON the schema describes, and follow these
conventions inside the strings:
- "title": sentence case, at most 60 characters, names the region and the day count
  ("Top End in 7 days: Darwin to Kakadu").
- "subtitle": at most 40 characters, a descriptor not a sentence ("Waterfalls & swimming
  holes").
- "duration": "1 day", "2 days" or "half day".
- "driveNext": the leg to the NEXT stop as "<km> km · <h>h <m>m to <next stop name>"
  ("230 km · 3h to Kakadu National Park"); null on the last stop.
- "hours": opening hours as one line; "Open 24 hours" when a park has no gate.
- "fee": the entry fee as one line ("Free entry", "Park pass $30 per adult") or null.
- "tags": one to three of exactly Nature, Culture, Adventure, Wildlife, Relaxation.
- "aiNote": two sentences at most, at most 220 characters, why this stop is here for
  this traveller.
- "detailedPlan": three to seven entries per stop, "time" as "9:00am" / "1:30pm",
  "activity" one line at most 80 characters.
- Sentence case throughout. No emoji, no markdown, no ALL CAPS.
```

### 4.2 User turn — filled from `PlanRequest.answers`

```
Plan a {days}-day trip for a {companions} traveller aged {ageRange}, travelling by
{vehicle}, {budget} budget, staying in {accommodation}, preferring {campingPreference}.
Focus: {focus, comma-separated}. Region: {region}. Physical activity level:
{activityLevel}. Off-road driving confidence: {offRoadConfidence}. Heat tolerance
{heat} of 5. Wildlife interest: {wildlifeInterest}. Comfortable off-grid:
{offGridComfortable}. The trip starts at "{startLocation}" and ends at "{endLocation}".
```

The keys are substituted as they are (`four_wd`, `mid_range`); the model reads them fine
and the server never has to keep a second label table.

### 4.3 What the server does with the output

1. Parse against the schema (structured output makes this a formality).
2. For every stop, geocode `name` biased to the Northern Territory; keep the place id,
   `lat`, `lng`, and a photo URL if one is licensed for display. **Drop the stop** when
   nothing resolves or the result is outside the NT box in §3.3. Cache place ids by
   name — Google's terms allow storing a `place_id` indefinitely, not the photo.
3. Return `200` with the assembled `PlanResponse`, or `422 cannot_plan` when fewer than 2
   stops survive.
4. Cache the response under `requestId` for at least 10 minutes so a retry after a
   client timeout does not generate twice.

---

## 5. Failure state on Loading — `docs/PRD.md` §3.4 from D14

Specified in the PRD; summarised here because the server owner should know what the user
sees. Loading keeps its five rotating messages and the pulsing disc, gains a **Cancel**
text button under the progress pill while the request is in flight, and on failure
replaces the status text with a title, a body line and one or two buttons. No save
happens on failure (`docs/PRD.md` §3.4). The copy table is the PRD's, not this file's.

---

## 6. Configuration

| | |
|---|---|
| `PLAN_API_URL` | `String.fromEnvironment('PLAN_API_URL')`, from the gitignored `terra_nt/.env` through `--dart-define-from-file=.env`, like `CARTO_API_KEY` |
| Empty or absent | The app keeps `SeedItineraryRepository`: a checkout with no `.env` still generates the seeded route, tests run without a network, and no screen blocks on the network at cold start |
| Emulator or USB phone | `PLAN_API_URL=http://127.0.0.1:8787` with `adb reverse tcp:8787 tcp:8787` (run by `tools/plan_server/start.bat`), so the device's own loopback reaches the laptop over USB. Since 2026-09-29 release builds allow cleartext to the loopback only (`res/xml/network_security_config.xml`); everything else stays HTTPS. `http://10.0.2.2:8787` still works on the emulator in debug builds |

The ID token comes from the auth seam (`AuthRepository.idToken()`), refreshed by Firebase
when expired; the in-memory implementation returns a fixed string so tests never touch
Firebase.

---

## 7. What the server owner still decides

Not the app's call, listed so nobody assumes the app decided them:

- Hosting and stack (Cloud Functions, Cloud Run, anything that verifies a Firebase ID
  token — `docs/PRD.md` P3 remains theirs).
- Which model and whether RAG is in front of it (P2); the retrieved context goes into the
  prompt between §4.1 and §4.2.
- Geocoding provider (Google Geocoding/Places, or another) and the photo source
  (`docs/PRD.md` P7 — Places Photos or Wikimedia Commons; the app only needs an
  `http(s)` URL it may display, or `null`).
- Rate limits and the `429` policy; the app shows try-again copy and honours nothing
  else in the body.

**Decided 2026-09-29: the operator owns the server** (`docs/PRD.md` D17, Task-45);
teammates supply RAG documents only. The server is `tools/plan_server/`, and its
`README.md` says how to run and reach it. The choices it made for the list above:

- **Hosting and stack:** the operator's Windows machine for the 2026-10-01 demo; Python
  3.13 standard library (`ThreadingHTTPServer`) plus `google-auth`, which verifies the
  Firebase ID token for project `terra-nt-cdu`. The app reaches it through the emulator
  alias, the LAN (debug builds) or a `cloudflared` tunnel.
- **Model:** one switch, `--backend`. `codex` (default) is `codex exec` on the operator's
  Codex subscription, `gpt-6-luna` at low effort, with a clean `CODEX_HOME` and a 50 s
  timeout that answers `504`; `openrouter` is the API route for later, with strict
  `json_schema` structured output; `fixture` is a fixed answer for tests and rehearsal.
  Nothing else changes when the model moves.
- **RAG:** Markdown place documents in `tools/plan_server/rag/`, a front-matter block
  (`name`, `aliases`, `lat`, `lng`, `region`, `tags`, `sources`) and free text, format in
  that directory's `README.md`. The request's region selects them, capped at about
  30 000 characters (12 000 until 2026-10-10, when 20 place documents no longer fit),
  inserted between §4.1 and §4.2. No embeddings, no vector store.
- **Geocoding and photos:** a stop's name is matched against the place documents first,
  then Nominatim (OpenStreetMap), one request a second, cached on disk; a result outside
  the §3.3 box is unresolved. `placeId` is the OSM `type/id` or the place document's file
  name. `photoUrl` is always `null`: P7 stays open.
- **Rate limits:** none; the server never answers `429`. Answers are cached by
  `requestId` for 30 minutes (`5xx` answers are not), and a retry that arrives while the
  first attempt is still generating waits for that attempt.

---

## 8. The stub — how the app is verified before the server exists

`tools/plan_stub/server.py`, Python 3 standard library only, no dependencies:

```
python tools/plan_stub/server.py --port 8787 --mode ok
```

| `--mode` | Behaviour |
|---|---|
| `ok` | `200` with `terra_nt/test/fixtures/plan/ok.json` after 2 s |
| `slow` | `200` with the same body after 75 s — past the client timeout |
| `cannot_plan` | `422` with the `cannot_plan` error body |
| `rate_limited` | `429` with `retryAfterSeconds: 30` |
| `error` | `500` with `{"error":{"code":"server_error"}}` |
| `invalid` | `200` with `terra_nt/test/fixtures/plan/invalid_one_stop.json` |
| `refuse` | closes the connection without a response |

The stub logs each request's `requestId` and whether the `Authorization` header was
present; it does not verify the token. The fixture files are the same ones the parser's
unit tests read, so the tour and the tests exercise one body.
