# CLAUDE.md — Terra NT Route Planner (Flutter)

---
# TarikOS (Second Brain) link — Eko identity

You are Eko, Tarik's assistant and second brain, working in the **Terra NT** project.
Not a fresh agent. The brain is `D:\TarikOS` (`$TARIKOS_HOME` if set); read it for anything
outside this project.

Two things bind here and are **never copied into this repo**:
- **Kurallar.md** (house rules, Turkish, bind everywhere) — injected at session start by
  `.claude/hooks/brain-rules.sh` (Claude) and the central hooks in `.codex/hooks.json`
  (Codex). The hook says so loudly if it cannot reach the brain; a session without that
  banner runs without the rules. Codex approves the hook once per clone; an unapproved
  hook skips silently, so "no error" is not "rules arrived".
- **Principles** (`D:\TarikOS\Principles.md`, engineering principles, English) — arrives from
  the user level: `~/.claude/CLAUDE.md` imports it (Claude), `~/.codex/AGENTS.md` carries a
  generated copy (Codex). `python D:/TarikOS/.claude/scripts/mount_skills.py --check` audits both.

Where a rule here contradicts Kurallar.md, the project rule wins in this directory only.

Skills live in `D:\TarikOS\.claude\skills\` and are junctioned globally; do not copy them
here (`.claude/commands/` only invokes them). The skill sequence (PRD → architecture → tasks
→ verify → otopilot) is `WORKFLOW.md`, read when a phase starts.

Generated files, regenerate after editing this one:

    python D:/TarikOS/.claude/scripts/sync_agents_md.py .            # AGENTS.md (Codex reads this)
    python D:/TarikOS/.claude/scripts/render_codex_hooks.py --project .   # .codex/hooks.json

Both take `--check`; `--check` never repairs.

---

## Blueprint

### Project-specific operating rules

Blueprint was written by hand on 2026-08-25, before `create-architecture` existed; it is
**not** re-run here. Amending Blueprint stays a decision to raise with the user.

### Execution routing — which agent

Every task file from Task-03 on carries a **`Execution` block** under its title:

```
> **Execution:** agent `codex` · effort `high`
> *Why:* Tier 1 pure Dart; the criterion is `flutter analyze` + tests, no eye needed.
```

**That block is the decision.** It was written with the PRD, Blueprint and the task's own
Execution Guide in view; a session reading the task cold does not have that context and
must not re-litigate it. `docs/TASKS_INDEX.md` carries the same routing as one table —
a summary, not a second source of truth. When they disagree, the task file wins.

**Agent.** Codex lanes run tasks whose spec is complete and whose acceptance is
machine-checkable — tier 1 pure Dart, models, seeds, repositories, notifiers, mechanical
volume. The main loop keeps tasks judged by eye against `docs/screenshots/` and the design
reference, and every task carrying an architecture decision. **`verify-task` always runs
from the main loop**, whoever wrote the code.

**No Plan mode.** Tasks run directly from the file (operator decision, 2026-09-16). An open
"how" is a ⛔ question to the operator, closed before the task runs; the Execution Guide
is the recommended route, and a lane may deviate inside OWNS if it says why.

**Effort.** Codex lanes are `high` — reasoning tokens are a rounding error in the total, so
lowering effort buys noise and risks judgment. Main-loop tasks with an open architectural question are
`high`, the rest `medium`.


Written 2026-08-25 from `docs/PRD.md`, by hand — this is the section `create-architecture`
writes, once per project, from the PRD. **Binding on every task.** Changing anything here
is a decision to raise with the user (Principles 1), not an edit to make in passing.

Scope note: this describes **phase 1** (`docs/PRD.md` §5.1) — the full 9-screen app,
offline, no cloud account. Phases 2 (Firebase) and 3 (AI) land behind the two seams
declared under *Architecture* and change nothing else.

**Phase 2 started 2026-09-22** (`docs/PRD.md` D12): real accounts behind `AuthRepository`
— Firebase Authentication with email/password and Google Sign-In, Android first. Saved
routes stay on the device until Firestore is decided as its own task; nothing else in
this Blueprint changes for phase 2 beyond the lines dated 2026-09-22 below.

### Stack

**Flutter 3.47.1 / Dart 3.13.1** — verified installed on this machine 2026-08-25. Pin
these in `pubspec.yaml` (`environment: sdk: ^3.13.1`).

**How to enter the environment: there is nothing to activate.** No venv, no conda, no
`fvm`, no `nvm`, no `package.json` — the SDK is a system install at `D:\Dev\Flutter\bin`,
already on `PATH`, so `flutter` and `dart` are callable as they are. What replaces
activation here is the **working directory**: `flutter pub get`, `flutter analyze`,
`flutter test`, `flutter run` and `flutter build` all need `cd terra_nt` first, because the
repo root has no `pubspec.yaml`. A verification command that ran from the root proves
nothing. Editing and reading files needs neither.

| Package | Version | Why it is here |
|---|---|---|
| `flutter_riverpod` | **2.6.1** | Cross-tab shared state (session, saved routes, itinerary order, skipped set) with a `ProviderContainer` that tests without pumping a widget. |
| `flutter_map` | **8.3.1** | Renders the **same CARTO dark tiles as the prototype**, so fidelity is exact rather than approximated. Markers are ordinary widgets — which is what the numbered pins and the animated car need. |
| `latlong2` | **0.10.1** | Coordinate type `flutter_map` speaks. Kept out of tier 1 — models store raw doubles. |
| `shared_preferences` | **2.5.5** | The only persistence phase 1 needs: saved routes, session, onboarding flag (`docs/PRD.md` D3). |
| `url_launcher` | **6.3.2** | Opens the Google Maps directions URL (Result export, and Stop detail "Navigate"). |
| `flutter_lucide` | **1.34.0** | The design is Lucide 1.33.0 outline throughout — 41 icon usages in the prototype. 1.34.0 is a superset. |
| `flutter_lints` (dev) | **6.0.0** | Supplies the lint set `analysis_options.yaml` includes. |
| `firebase_core` | **4.15.0** | Phase 2 (D12). Required by every other Firebase package; `Firebase.initializeApp` runs once in `main.dart` from the generated `firebase_options.dart`. |
| `firebase_auth` | **6.7.0** | Phase 2 (D12). Email/password accounts and the Google credential behind `AuthRepository`; its persisted user is the signed-in session, so `terra_nt.session` goes. |
| `google_sign_in` | **7.2.0** | Phase 2 (D12). The real "Continue with Google". 7.x API: `GoogleSignIn.instance.initialize()` once, then `authenticate()`; the server client id comes from `google-services.json`. |

Resolved by `flutter pub get` at Task-00 (2026-08-26) and read from `terra_nt/pubspec.lock`.
The three Firebase rows were resolved the same way on 2026-09-22 (Task-23); adding them
left `package_config` at 3.0.0 and pulled no `test`/`shelf` tree.

**CARTO tiles need a free API key as of 2026-09-09.** CARTO started watermarking
unauthenticated raster tiles in late August 2026, and the endpoint this app uses now
returns a tile stamped “API KEY REQUIRED” — verified by fetching one. The key is free,
capped at 5 million tile requests a calendar month, and needs no CARTO account. It is
read from `String.fromEnvironment('CARTO_API_KEY')` into `TileLayer.additionalOptions`.
The value lives in the gitignored `terra_nt/.env` and reaches the build through
`--dart-define-from-file=.env`, so no key is committed and no package is added —
`.env.example` is the committed template.

**Staying on CARTO was the choice, not inertia.** Without a key the endpoint still
serves the watermarked tile, so a checkout with no key renders instead of going blank.
Stadia Maps — the closest raster alternative, and the one that is not on a retirement
path — returns 401 without a key, restricts its free tier to non-commercial use, and
its dark style differs visibly from the prototype the design is measured against.
CARTO says raster basemaps are being retired in favour of vector, with no date given;
moving to vector needs a package outside this table, so it is a decision to raise, not
a silent bump.

**Riverpod is 2.6.1, not the 3.x on pub.dev — deliberately.** Unconstrained, pub resolves
to 2.6.1; forcing `^3.4.2` succeeds but **downgrades `package_config` 3.0.0 → 2.2.0** and
pulls a `test`/`shelf` tree into the graph. Everything this project needs — `Notifier`,
`NotifierProvider`, `ProviderContainer`, widget-free testing — exists in 2.6.x. Upgrading
to 3.x is a decision to raise, not a silent bump.

**Fonts are bundled, not fetched.** Inter (400/500/600/700) and JetBrains Mono (400/500)
ship as `.ttf` under `terra_nt/assets/fonts/` and are declared in `pubspec.yaml`. Do **not**
add `google_fonts`: it downloads on first run, and an app whose entire premise is
"areas with no phone signal" must not have network-dependent typography.

**Do not add a package that is not in this table** without recording the reason here first.
In particular:

- **No `flutter_slidable`.** The swipe spec is absolute pixels — clamp −76…0, snap at −38,
  4px tap threshold (`docs/PRD.md` §3.8). Slidable's thresholds are screen-fraction based;
  bending it to hit exact px is more code than a `GestureDetector` over a pure snap
  function, and the snap function is unit-testable on its own.
- **No `DraggableScrollableSheet`** for the Result sheet. Its snap sizes are fractions of
  screen height; the spec is absolute px (190 / 430 / 700). Use a height-driven panel.
- **No Firebase, no `google_sign_in`, no HTTP client in phase 1.** Nothing in v1 touches
  the network except map tiles. *Phase 2 (2026-09-22) lifts the first two — the three
  rows above — and nothing else: still no HTTP client, no `cloud_firestore` until saved
  routes off the device are sliced as their own task, no `firebase_auth_mocks` or other
  test double — the Firebase wrapper stays thin and untested by unit, and the seam's
  in-memory implementation carries the tests.*

- **No `build_runner` / `riverpod_generator` / `riverpod_annotation`.** Riverpod works
  without code generation; notifiers are written by hand.
- **`cupertino_icons` is removed.** `flutter create` adds it by default; nothing uses it,
  because icons come from `flutter_lucide`.

Versions above are resolved, not invented. If a package is ever added or bumped, update the
table from `pubspec.lock` in the same change.

### Architecture

The Flutter project lives at `terra_nt/`. Everything else — `docs/`, `design/`,
`.claude/`, `README.md` — stays at the repo root, outside anything the analyzer or the
build treats as source.

**Where the project's own documents live** (moved out of the repo root 2026-08-26):

| Path | What it is |
|---|---|
| `docs/PRD.md` | The spec — *what* and *why*, all 9 screens, decisions D1–D10, deviations V1–V6, phases |
| `docs/TASKS_INDEX.md` | The task tracker — execution order, blocking questions, tick boxes |
| `docs/screenshots/` | Ten reference captures — **advisory only**, never a criterion (its own `README.md` carries the rule) |
| `tasks/Task-XX.md` | One slice each — *how* |
| `design/` | Prototype + token bundle — the visual source of truth |

`verify-task` ticks boxes in **`docs/TASKS_INDEX.md`**, not at the repo root. Run all `flutter`/`dart` commands from `terra_nt/`; doc paths in
tasks are repo-root relative, so from inside `terra_nt/` that is `../docs/…`.

```
terra_nt/lib/
├── main.dart
├── app/            router, tab shell, ThemeData wiring
├── core/
│   ├── theme/      tokens → ThemeData + named token constants
│   └── util/       pure helpers (arc-length sampler, URL builder, snap fns)
├── data/
│   ├── models/     plain Dart data types
│   ├── seed/       the 7 stops, 8 POIs, 2 saved routes, copy verbatim
│   └── repositories/  persistence + THE TWO SEAMS
├── features/       auth · onboarding · itinerary · explore · saved · profile
└── shared/         the design-system widgets (Button, TextInput, Icon, rows, chips)
```

**Layer rule — three tiers, enforced by import direction:**

1. **`core/util/` and `data/models/` are pure Dart.** No `package:flutter` import, ever.
   This is where every algorithm in `docs/PRD.md` lives, and it is why they can be tested
   without a widget. If a file here needs `BuildContext`, it is in the wrong tier.
2. **Riverpod notifiers in `data/repositories/` and `features/*/` own all state.** They
   are the only things that mutate. They call into tier 1 for logic.
3. **Widgets read state and render it. Widgets never own app state.** Local UI-only state
   (an animation controller, a text field's focus) stays in the widget; anything another
   screen can observe does not.

**The two seams — and only these two** (`docs/PRD.md` §5.1):

- **`ItineraryRepository`** — screens ask it for an itinerary; they never import `seed/`.
  Phase 1's implementation returns the seeded stops. Phase 3 swaps in the real model.
- **`AuthRepository`** — screens ask "who is signed in" and "sign in with Google"; they
  never learn what is behind it. Phase 1 is an in-memory mock. Phase 2 swaps in Firebase.

**No third seam.** Nothing else in v1 gets an interface "for later" — that is speculative
generality and Principles 2 forbids it. One implementation means one concrete class.

**Navigation:** declarative routing with a stateful tab shell, one navigation stack per
tab, preserved across tab switches (`docs/PRD.md` §3.11). Stop detail pushes onto the Plan
AI stack.

**The data contracts** — the representations more than one module must agree on. These are
what task 27 gets wrong when task 3 only ever wrote them in code:

- **Coordinates are plain WGS84 decimal degrees held as two `double`s**, `lat` and `lng`,
  at the 4 decimal places the seed uses. Models store the raw doubles; `latlong2`'s
  `LatLng` is constructed at the `flutter_map` boundary and never stored — that is the
  tier-1 rule. NT is south and east: `lat` negative, `lng` positive (Darwin `-12.4634,
  130.8456`).
- **Stops and POIs are two separate seeded lists whose coordinates deliberately differ**
  for the same place — the POI Ubirr is `-12.4260, 132.9760`, the Kakadu stop is
  `-12.6692, 132.8352` (`docs/PRD.md` §4). Do not reconcile them; the split is the model.
- **IDs are hand-written kebab-case string literals, seeded and stable, never generated.**
  POIs: `darwin-wf`, `mindil`, `litchfield`, `ubirr`, `nitmiluk`, `desertpark`,
  `kingscanyon`, `uluru`. Saved routes: `full-nt`, `red-centre`, and the generated one
  upserts under `generated-trip`. **Stops carry no id** — position is identity, and the
  *original index* is what per-row revert and "Restore N removed stops" restore to.
- **There is no timestamp in the model.** A saved route carries `dateLabel`, a display
  **string** seeded verbatim (`"Generated today"`, `"Generated 3 days ago"`). Nothing
  derives a relative date from a clock, and nothing parses one back.
- **Tags are exact-case English strings** — `Nature`, `Culture`, `Adventure`, `Wildlife`,
  `Relaxation`. The string is the key `tagColor()` maps to a `--tag-*` token, and anything
  unrecognised falls back to `AppColors.inkTertiary`. No enum: the fallback is the contract.
- **Distances, durations, hours and fees are display strings, not numbers** —
  `"115 km · 1h 30m to Litchfield National Park"`, `"1 day"`, `"8 days · 7 stops"`. Nothing
  does arithmetic on them. The only computed quantity in the app is the sampler's
  cumulative distance, and that comes from coordinates.
- **Every dimension in the spec is a logical pixel; every duration is milliseconds** —
  sheet 190 / 430 / 700, swipe clamp −76…0 snapping at −38, 4px tap threshold, step card
  320 ms, `700 + span × 3500` ms. Never a fraction of screen height.
- **Exactly three things persist** (`docs/PRD.md` D3): saved routes, the session
  (signed-in email plus the onboarding-done flag), and nothing else. Ordering, skipped
  stops, edit mode, sheet height and POI selection are session-only and reset on launch.
  **The `shared_preferences` keys were fixed by Task-05 on 2026-09-07** and are exactly
  three, declared as named constants on `PreferencesStore`:

  | Key | Type | Encoding |
  |---|---|---|
  | `terra_nt.saved_routes` | `String` | JSON list of `{id, title, meta, dateLabel}` |
  | `terra_nt.session` | `String` | JSON object `{email: String\|null}` — **removed in phase 2 (Task-24, 2026-09-22)** |
  | `terra_nt.onboarding_done` | `bool` | the flag itself |

  **From Task-24 the keys are exactly two.** Firebase Authentication persists the signed-in
  user on the device itself and answers offline, so a second copy of the email in
  `terra_nt.session` would be a second source of truth; the session is now the auth
  seam's current user plus the onboarding flag. `terra_nt.saved_routes` stays local until
  Firestore is decided.

  A missing or malformed `terra_nt.saved_routes` falls back to the seeded routes rather
  than throwing. An **explicitly persisted empty list stays empty** — that is what makes
  deviation V6 work, since deleting the account must not restore the demo routes.
  A fourth key is a defect: Task-05's DoD asserts none appears after mutating order,
  skipped stops, edit mode, sheet height or the offline toggle.

### Fidelity & UI

The design in `design/` is final, not a suggestion. **A visual difference is a bug** —
unless `docs/PRD.md` §7 records it as a deviation, or the prototype itself is wrong there.

**`docs/screenshots/` holds ten reference captures. Read them; never cite them.** They are
what a built screen gets eyeballed against, and they are the only way to *see* the design
in this repo — the prototype does not run (`docs/PRD.md` §2). But the prototype has known
defects, so these images are not ground truth: no task may carry an acceptance criterion
that points at one. Coverage is partial (main screens, default states only); a screen
absent from that directory still has a spec, in `docs/PRD.md` §3. The directory's own
`README.md` is the authority on all of this.

- **Tokens are defined once**, in `core/theme/`, transcribed from
  `design/design-system/tokens/*.css`, and referenced **by name** everywhere else.
- **Never hardcode a hex, size, radius, or duration in a widget.** If a value is missing
  from the token set, add it to `core/theme/` and use it by name — do not inline it.
- The six `--tag-*` colours are **provisional** (`docs/PRD.md` Q7). They are named tokens
  precisely so a later correction stays a one-line change.
- **Do not port the prototype's HTML/CSS line-by-line.** It is a reference for copy,
  layout, timing and state transitions — not source to translate. Build Flutter widgets
  with Flutter idioms.
- **Copy is character-for-character** from the prototype, including punctuation and
  ellipses. Sentence case everywhere; no ALL CAPS, no title case.
- Depth is surface-step plus hairline. The **only** shadow is `--shadow-overlay` on
  floating surfaces. No gradients beyond the two specified scrims, no `backdrop-filter`,
  no glows, no coloured shadows. **No light mode** — do not add one.
- The build may diverge from the prototype **only** where `docs/PRD.md` §7 records a
  deviation (V1–V6). Anything else that differs is a defect.
- **`review-visual` is how a built screen gets eyeballed** against `docs/screenshots/` and
  V1–V6. It reports; it does not verify. Q1 stays open, and nothing it finds may become an
  acceptance criterion or a golden test.

### Verification Rules

A task is done when all of the following hold. `verify-task` enforces them.

1. **`flutter analyze` is clean** — zero errors, zero warnings. Not "only pre-existing
   warnings"; clean.
2. **Every piece of real logic has a functional unit test**, written against tier 1 (pure
   Dart), including at minimum: the arc-length route sampler; `canNext(step, answers)`;
   the sheet's `nearestSnap`; the swipe open/close snap; the Google Maps URL builder
   (including the 2-stop no-waypoints case); removed-stop pluralisation; tag→colour
   including the unknown-tag fallback; and the saved-route upsert.
3. **Behaviour that only exists in widgets gets a widget test** — auto-advance timing and
   its cancel-and-restart, timer disposal on early exit, skip/unskip round-trip,
   log-out vs delete-account state clearing.
4. **No timer, ticker or controller leaks.** Anything started in `initState` is cancelled
   in `dispose`, and the test asserts it.
5. **No layout exceptions at phone widths** — no overflow stripes, no unbounded-constraint
   errors.
6. **A task that touches layout, safe-area handling, navigation/Back behaviour or a drag
   gesture also passes a device tour.** Read `docs/DEVICE-TOUR.md` BEFORE starting such a
   task, not after the suite goes green. Three Task-20 defects reached a physical device
   through a green widget suite; a fixed test viewport has no notch, no gesture bar and no
   real gesture stream. That file also fixes the acceptance criterion for this class: no
   exception AND the behaviour still works — silencing a log is not a fix.

**Do NOT write golden or other visual-regression tests.** They are not part of the
Definition of Done. They may be added later as an explicit, separate task, and only after
`docs/PRD.md` Q1 (how visual fidelity is verified at all) has an answer. The reference
captures in `docs/screenshots/` do **not** supply that answer — they are for human review,
and pinning a golden against a prototype with known defects would pin the defects.

### Key Constraints

Forbidden. Not preferences.

- **No WebView, no iframe, no HTML for the maps.** Native `flutter_map` widgets only. The
  prototype's `postMessage` plumbing does not survive the port — marker taps are widget
  callbacks.
- **No line-by-line port of the prototype's HTML/CSS.**
- **No hardcoded design values in widgets.** Tokens by name, always.
- **No light mode. No new colour, type role, radius or duration** that is not in
  `design/design-system/tokens/`.
- **No Firebase, no real Google Sign-In, no network calls, no AI/LLM API in phase 1.**
  Map tiles are the only remote resource. *Phase 2 (2026-09-22): Firebase Authentication
  and Google Sign-In are in; map tiles and auth are the only remote resources. Still no
  AI/LLM API, no HTTP client of our own, and no screen may block on the network at cold
  start — the app's premise is no signal.*
- **No third abstraction seam** beyond `ItineraryRepository` and `AuthRepository`.
- **No package outside the Stack table** without recording the reason there first.
- **No feature beyond `docs/PRD.md`.** The §8 out-of-scope list is binding; deferred is
  not the same as cancelled, but neither is an invitation to build it early.
- **No golden tests in the Definition of Done.**
- **`flutter analyze` warnings are never "acceptable for now".**
