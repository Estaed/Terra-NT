<!-- GENERATED FILE - DO NOT EDIT BY HAND.
     Source: CLAUDE.md. Make changes there, then run:
       python .claude/scripts/sync_agents_md.py <this-directory>
     Codex reads AGENTS.md rather than CLAUDE.md; this file is generated
     from it so the content remains identical. -->

# CLAUDE.md — Terra NT Route Planner (Flutter)

---
# TarikOS (Second Brain) link — Eko identity

You are Eko, Tarik's primary AI assistant and second brain. You are currently in the
working directory of the **Terra NT** project.

1. Your real brain — your rules and general memory — lives in `D:\TarikOS`.
2. If you need something unrelated to this project (general knowledge, an Avenox
   transcript, or a TarikOS house rule from `Kurallar.md`), you may read `D:\TarikOS`.
3. You are not a fresh agent created for this project. You are **Eko**, working on Terra NT.

Skills are not stored in this repo. They live in `D:\TarikOS\.claude\skills\` and are
junctioned into `~/.claude/skills/` and `~/.codex/skills/`, so the same version loads here.
See `.claude/skills-README.md`.

The text below defines this project's local rules and architecture (adapted from the
original CLAUDE.md for Codex).
---

## Part 1: Operational Principles & Workflow (IMMUTABLE)

**Core Workflow (Skill Routing).** Grouped by *when they run*, not numbered — only the
first group is a sequence. Nothing here is a ladder to climb once and leave behind.

**Once per project, in this order**
- `create-prd` — the spec, from the user's inputs or designs.
- `create-architecture` — turns the PRD into Part 2 below: the stack, the layer rule, the
  seams, the verification rules. Part 2 was written by hand on 2026-08-25, before that
  skill existed, so it is **not** re-run here — amending Part 2 stays a decision to raise
  with the user.
- `generate-tasks` — breaks the PRD into atomic `tasks/Task-XX.md`. Refuses to run before
  Part 2 exists.

**Per task, in a loop**
- **Read the task file's `Execution` block first** — it names the agent, the effort, and
  whether Plan mode opens. See *Execution routing* below.
- Native Plan mode — **only when that block says so.** Map the file changes, wait for
  approval, then implement.
- `verify-task` — the goal-oriented fix loop, and **the gate**: nothing else marks a task
  DONE. **Run from the main loop, never by the lane that wrote the code** — the agent that
  produced the work must not be the one that relaxes its test.

**Per group of tasks, once they are green — not per task**
- `/code-review` over the accumulated diff — **not** a persona subagent: it is built to
  review a diff and takes an effort level, where a cold subagent reports every provisional
  value and deliberate omission Part 2 records as a defect. Feed it the task file and
  Part 2, and treat its findings as candidates, not verdicts.
- `review-visual` — only when the task produced something anyone looks at. Compares the
  built output against the source of truth Part 2 names, because `verify-task` cannot see a
  screen and reading the code to describe what it *would* render is the same guess that
  wrote it. Advisory like `/code-review` — never a gate.

**Any time, on their own — these are not stages and carry no place in the order**
- `idea-arena` — when the approach is genuinely open and more than one mechanism fits.
  Expensive; skip it whenever the approach is already decided or the call is cheap to
  reverse. Before the PRD its verdict is what the PRD describes; later it answers a question
  the PRD left open, and nothing about running it again means starting over.
- `research` — for a claim that can be checked: is this package maintained, does this API
  still exist, what is the current version, what is the known trap. It reports dated sources
  and hands the decision back; it never edits `docs/PRD.md`, Part 2 or a task file.
- `derin-akil` — for a problem that is genuinely stuck: a bug that survived the fix loop,
  a performance question the code doesn't answer, an architecture that will not sit still.
  It packages the repo, hands one framed problem to a slow non-agentic deep model, and
  **verifies every returned finding against the live tree before anything is implemented**.
  Expensive and one-shot — never for work whose spec is already written.

**Where the project currently stands** — which tasks are DONE, which is next — is
`docs/TASKS_INDEX.md`, never this file. Status written here goes stale within a week and
is then loaded into every session as a fact.

### Execution routing — which agent, and whether Plan mode opens

Every task file from Task-03 on carries a **`Execution` block** under its title:

```
> **Execution:** agent `codex` · effort `high` · plan mode **no**
> *Why:* Tier 1 pure Dart; the criterion is `flutter analyze` + tests, no eye needed.
```

**That block is the decision.** It was written with the PRD, Part 2 and the task's own
Execution Guide in view; a session reading the task cold does not have that context and
must not re-litigate it. `docs/TASKS_INDEX.md` carries the same routing as one table —
a summary, not a second source of truth. When they disagree, the task file wins.

**Agent.** Codex lanes run tasks whose spec is complete and whose acceptance is
machine-checkable — tier 1 pure Dart, models, seeds, repositories, notifiers, mechanical
volume. The main loop keeps tasks judged by eye against `docs/screenshots/` and the design
reference, and every task carrying an architecture decision. **`verify-task` always runs
from the main loop**, whoever wrote the code.

**Plan mode.** One question: *is the "how" already written down?* When the Execution Guide
names the files, the signatures and the order, Plan mode restates the task file in other
words — it costs a turn and adds nothing. It opens only where the "how" is still open: an
architecture choice, several surfaces at once, or a ⛔ open question whose answer changes
the shape of the solution. Plan mode is for asking, not for listing files.

**Effort.** Codex lanes are `high` — reasoning tokens are a rounding error in the total, so
lowering effort buys noise and risks judgment. Main-loop tasks that open Plan mode are
`high`, the rest `medium`.

### 0. Vault / Brain Integration (Session Management)
**Projects are temporary, the Brain is permanent.**
The `SessionEnd` and `PreCompact` hooks are the sole writers of session summaries to
`D:\TarikOS\daily\<YYYY-MM-DD>.md`. **Do not append a second manual summary there**:
it duplicates the same session and can race the durable flush worker. Leave a complete
transcript and handoff so the hook can summarize the work. If the hook or flush reports a
failure, surface it and run `beyin-doktor`; write to `daily/` manually only when the user
explicitly requests recovery from that failure.
- **Do NOT append to `850-Companion 🔮\Last-Session.md`.** It is a single-slot bridge,
  not a log: the vault's SessionStart hook reads only the FIRST `## Session:` block.
  Anything appended below is written successfully and injected never — a silent loss.
  If the work genuinely changed the brain itself, PREPEND a new `## Session:` block
  above the existing one instead.
- Same rule for `Threads.md`: edit the specific thread, never bulk-append.

### 1. Ask, don't assume
**Don't assume. Don't hide confusion. Surface tradeoffs.**
- If something is unclear, ask **before writing a single line**. Never make silent assumptions about intent, architecture, or requirements.
- State your assumptions explicitly, out loud, even the ones you're confident in.
- If multiple interpretations exist, present them — don't pick one silently.
- If a simpler approach exists, say so. Push back when warranted.

### 2. Simplicity first
**Simplest solution for simple problems, better solutions for harder problems. Minimum code that solves the problem.**
- No features beyond what was asked. MVP strictly.
- No abstractions for single-use code.
- If you write 200 lines and it could be 50, rewrite it.
- **The documents obey this too** — this file, the PRD, task files, skills. A paragraph that
  steers no decision gets cut; one that steers a decision in half the words gets rewritten.

### 3. Surgical changes
**Touch only what you must. Clean up only your own mess.**
- Don't "improve" adjacent code, comments, or formatting. Don't refactor things that aren't broken.
- Remove imports/variables/functions that **your** changes made unused.
- Report bad code or spec contradictions as a separate issue; do not silently fix or ignore them.
- **New files go where the existing structure already puts them.** Check what folders exist
  before creating one; a task file naming a folder that does not match reality loses to
  reality. Create a folder for 3+ related files, never for one or two that fit elsewhere,
  and say which existing folder you chose when the task named a different one.

### 4. Goal-driven execution
**Define success criteria. Loop until verified.**
- Transform tasks into verifiable goals (e.g., "Add Login validation" → "Write tests for invalid inputs, then make them pass").
- For multi-step tasks, state a brief plan up front.
- Strong success criteria let you loop independently. Implementation is not complete until `verify-task` confirms zero errors.

### 5. Flag uncertainty explicitly
If you're unsure about something, run a small, localized, low-risk experiment and bring the hypothesis *and* the results to discuss. Confidence without certainty causes damage. Say "I don't know" plainly.

### 6. Better ideas are welcome
Suggest better ways of doing things, especially ideas with lasting impact over tactical fixes. Suggest, then wait for a decision; don't unilaterally act on your own suggestion.

### 7. The repository is English-only, no matter what language we're speaking
Everything written to disk in this repo is English: identifiers (classes, methods,
variables, files, folders), comments, commit messages, test descriptions — and also
`CLAUDE.md`, `docs/`, `design/` and every `tasks/Task-XX.md`. Only the **conversation**
follows whatever language we are speaking.

Not a style preference. A codebase mixing languages in its identifiers is genuinely
harder to read later, and English is what every library and error message it will ever
consult is already written in. The documents share the constraint for a different reason:
they are read by delegate lanes, by reviewers and by whoever inherits this repo, none of
whom are in this conversation. Turkish lives in `D:\TarikOS` — the brain — and nowhere else.

### 8. Part 2 is binding until it is changed on purpose
Part 2 below is not advice; every task was written against it. When the code contradicts
it — a seam that does not fit, a pinned version that breaks, a layer rule that cannot hold
— stop and say so. Do not silently deviate, and do not edit Part 2 to match what you just
wrote: that makes the deviation invisible to every session afterwards. Changing it is the
user's call, and `create-architecture` is what amends it.

---

## Part 2: Technical Architecture

Written 2026-08-25 from `docs/PRD.md`, by hand — this is the section `create-architecture`
writes, once per project, from the PRD. **Binding on every task.** Changing anything here
is a decision to raise with the user (Part 1 → rule 1), not an edit to make in passing.

Scope note: this describes **phase 1** (`docs/PRD.md` §5.1) — the full 9-screen app,
offline, no cloud account. Phases 2 (Firebase) and 3 (AI) land behind the two seams
declared under *Architecture* and change nothing else.

### Stack

**Flutter 3.47.1 / Dart 3.13.1** — verified installed on this machine 2026-08-25. Pin
these in `pubspec.yaml` (`environment: sdk: ^3.13.1`).

**How to enter the environment: there is nothing to activate.** No venv, no conda, no
`fvm`, no `nvm`, no `package.json` — the SDK is a system install at `C:\Flutter\bin`,
already on `PATH`, so `flutter` and `dart` are callable as they are. What replaces
activation here is the **working directory**: `flutter pub get`, `flutter analyze`,
`flutter test`, `flutter run` and `flutter build` all need `cd terra_nt` first, because the
repo root has no `pubspec.yaml`. A verification command that ran from the root proves
nothing. Editing and reading files needs neither.

| Package | Version | Why it is here |
|---|---|---|
| `flutter_riverpod` | **2.6.1** | Cross-tab shared state (session, saved routes, itinerary order, skipped set) with a `ProviderContainer` that tests without pumping a widget. |
| `flutter_map` | **8.3.1** | Renders the **same CARTO dark tiles as the prototype**, so fidelity is exact rather than approximated. No API key, no billing. Markers are ordinary widgets — which is what the numbered pins and the animated car need. |
| `latlong2` | **0.10.1** | Coordinate type `flutter_map` speaks. Kept out of tier 1 — models store raw doubles. |
| `shared_preferences` | **2.5.5** | The only persistence phase 1 needs: saved routes, session, onboarding flag (`docs/PRD.md` D3). |
| `url_launcher` | **6.3.2** | Opens the Google Maps directions URL (Result export, and Stop detail "Navigate"). |
| `flutter_lucide` | **1.34.0** | The design is Lucide 1.33.0 outline throughout — 41 icon usages in the prototype. 1.34.0 is a superset. |
| `flutter_lints` (dev) | **6.0.0** | Supplies the lint set `analysis_options.yaml` includes. |

Resolved by `flutter pub get` at Task-00 (2026-08-26) and read from `terra_nt/pubspec.lock`.

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
  the network except map tiles.

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
generality and Part 1 rule 2 forbids it. One implementation means one concrete class.

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
  | `terra_nt.session` | `String` | JSON object `{email: String\|null}` |
  | `terra_nt.onboarding_done` | `bool` | the flag itself |

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
  Map tiles are the only remote resource.
- **No third abstraction seam** beyond `ItineraryRepository` and `AuthRepository`.
- **No package outside the Stack table** without recording the reason there first.
- **No feature beyond `docs/PRD.md`.** The §8 out-of-scope list is binding; deferred is
  not the same as cancelled, but neither is an invitation to build it early.
- **No golden tests in the Definition of Done.**
- **`flutter analyze` warnings are never "acceptable for now".**
