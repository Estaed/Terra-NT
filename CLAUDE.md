# CLAUDE.md — Terra NT Route Planner (Flutter)

---

# Project Guidelines

## Part 1: Operational Principles & Workflow (IMMUTABLE)

**Core Workflow (Skill Routing):**
- **Phase 1 (Requirements):** Run `create-prd` to establish the core specification from user inputs or designs.
- **Phase 2 (Planning):** Run `generate-tasks` to derive architectural solutions and break the PRD down into atomic `tasks/Task-XX.md` files.
- **Phase 3 (Execution):** Use native Plan mode to map out file changes for a specific task. Wait for user approval, then implement.
- **Phase 4 (Validation):** Run `verify-task` to enter a goal-oriented fix loop until the task meets 100% of its Acceptance Criteria.

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

### 3. Surgical changes
**Touch only what you must. Clean up only your own mess.**
- Don't "improve" adjacent code, comments, or formatting. Don't refactor things that aren't broken.
- Remove imports/variables/functions that **your** changes made unused.
- Report bad code or spec contradictions as a separate issue; do not silently fix or ignore them.

### 4. Goal-driven execution
**Define success criteria. Loop until verified.**
- Transform tasks into verifiable goals (e.g., "Add Login validation" → "Write tests for invalid inputs, then make them pass").
- For multi-step tasks, state a brief plan up front.
- Strong success criteria let you loop independently. Implementation is not complete until `verify-task` confirms zero errors.

### 5. Flag uncertainty explicitly
If you're unsure about something, run a small, localized, low-risk experiment and bring the hypothesis *and* the results to discuss. Confidence without certainty causes damage. Say "I don't know" plainly.

### 6. Better ideas are welcome
Suggest better ways of doing things, especially ideas with lasting impact over tactical fixes. Suggest, then wait for a decision; don't unilaterally act on your own suggestion.

### 7. Code is English-only, no matter what language we're speaking
**Every artifact of code is English. Always. Regardless of the conversation's language.**
- Identifiers (classes, methods, variables, files, folders), comments, commit messages, and test/group descriptions are English — no exceptions, whatever language this conversation happens to be in at the time (Turkish, English, or anything else).
- This is not a style preference: a codebase mixing languages in its identifiers is genuinely harder for anyone to read later, and English is what every Flutter package, error message, and reference this project will ever consult is already written in.
- The conversation itself is unaffected — talk in whichever language is natural. So are `docs/` and `design/`: PRD prose, task files, and chat can be Turkish, English, or mixed, as they already are. This rule governs the code artifact only.

---

## Part 2: Technical Architecture

Written 2026-08-25 from `docs/PRD.md`. **Binding on every task.** Changing anything here
is a decision to raise with the user (Part 1 → rule 1), not an edit to make in passing.

Scope note: this describes **phase 1** (`docs/PRD.md` §5.1) — the full 9-screen app,
offline, no cloud account. Phases 2 (Firebase) and 3 (AI) land behind the two seams
declared under *Architecture* and change nothing else.

### Stack

**Flutter 3.47.1 / Dart 3.13.1** — verified installed on this machine 2026-08-25. Pin
these in `pubspec.yaml` (`environment: sdk: ^3.13.1`).

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

### Fidelity & UI

The design in `design/` is final, not a suggestion. **A visual difference is a bug.**

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
`docs/PRD.md` Q1 (how visual fidelity is verified at all) has an answer.

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

### Why this section exists

`docs/PRD.md` says *what* to build and *why*. `tasks/Task-XX.md` says *how* to build one
slice. Neither survives as ambient context — they are read on demand. `CLAUDE.md` is
loaded into **every** session automatically, so Part 2 is the only place where the
project's technical invariants are always present.

Without it, each session re-derives the stack, and 30 tasks drift into 30 slightly
different architectures. Part 2 is what makes task 27 look like task 3 wrote it.
