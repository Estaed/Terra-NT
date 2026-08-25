# CLAUDE.md — Terra NT Route Planner (Flutter)

---

# Part 1 — How to work

Behavioral guidelines that reduce common LLM coding mistakes. They apply to
everything below, and they outrank convenience.

**Tradeoff:** these guidelines bias toward caution over speed. For genuinely
trivial tasks, use judgment.

## 1. Ask, don't assume

**Don't assume. Don't hide confusion. Surface tradeoffs.**

- If something is unclear, ask **before writing a single line**. Never make
  silent assumptions about intent, architecture, or requirements.
- State your assumptions explicitly, out loud, even the ones you're confident in.
- If multiple interpretations exist, present them — don't pick one silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

**Unattended exception:** when running without a human to answer (background job,
autonomous loop), pick the most reasonable interpretation, proceed, and **record
the assumption** in your report rather than blocking. Recorded assumptions are a
deliverable, not a footnote.

## 2. Simplicity first

**Simplest solution for simple problems, better solutions for harder problems.
Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

The test: *"Would a senior engineer say this is overcomplicated?"* If yes, simplify.

## 3. Surgical changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.

When your changes create orphans:
- Remove imports/variables/functions that **your** changes made unused.
- Don't remove pre-existing dead code unless asked.

**Do surface what you find.** Bad code, design smells, dead code, and spec
contradictions get reported to me as a **separate issue** — named, located, and
briefly explained — so we can decide on them deliberately. Report them; don't
silently fix them, and don't silently ignore them either.

The test: every changed line traces directly to the request.

## 4. Goal-driven execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"
- "Build the Saved Routes screen" → "Screen renders, swipe reveals exactly 76px,
  snaps at the -38px midpoint, `dart analyze` is clean, matches `08-saved-routes.png`"

For multi-step tasks, state a brief plan up front:

```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it
work") force constant clarification. See **Definition of done** below for this
project's concrete verification gates.

## 5. Flag uncertainty explicitly

If you're unsure about something, see rule 1. Where it helps, run a **small,
localised, low-risk experiment** and bring me the hypothesis *and* the results to
discuss. Confidence without certainty causes more damage than admitting a gap.

Say "I don't know" / "I haven't verified this" plainly. Never present an
untested claim in the same register as a verified one.

## 6. Better ideas are welcome

I'm always open to better ways of doing things. Don't hesitate to suggest one —
especially ideas with lasting impact over tactical fixes. Suggest, then wait for
a decision; don't unilaterally act on your own suggestion.

**These guidelines are working if:** diffs contain fewer unnecessary changes,
fewer rewrites happen due to overcomplication, and clarifying questions arrive
*before* implementation rather than after mistakes.

---

# Part 2 — The project

## What this is
Flutter rewrite of the Terra NT Route Planner design prototype. Native app, no
WebView/iframe, no porting HTML/CSS — recreate the UI and behavior with Flutter
widgets and idiomatic state management.

NT (Northern Territory, Australia) road-trip planner: login → optional 15-step
onboarding → AI-generated multi-stop itinerary on a map → edit/reorder/skip stops
→ export to Google Maps, plus an explore map, saved routes, and profile.
9 screens. No real backend — auth is mocked and all stop data is seeded.

## Source of truth
- `PRD.md` — full product spec: screens, design tokens, state, data model, interactions.
- `screenshots/` — one PNG per screen, pixel reference.
- `design-reference/` — the original HTML/React prototype + map logic, for exact
  copy, timing, and state-machine reference (read, don't port line-by-line).
- `design-reference/Terra NT.dc.html` — carry the 7 seeded stops (names, times,
  fees, AI notes, tags, hourly plans) over **verbatim**. Don't paraphrase copy.
- `design-system/` — the token bundle `PRD.md` derives from (added 2026-08-25;
  it was missing from the original handoff). `tokens/*.css` are the authoritative
  hexes and numbers. **Read `design-system/README.md` first:** upstream this
  system documents a *marketing website for a different product*, so only
  `tokens/` transfers — its component inventory (`PricingCard`, `TopNav`, …) and
  desktop breakpoints describe that site, not this app.

Read `PRD.md` in full before writing code for a screen. If something is
ambiguous, ask (rule 1) rather than guess.

## Stack / conventions
Verified on this machine 2026-08-25: **Flutter 3.47.1 · Dart 3.13.1** (stable).

- Flutter, null-safety, Dart 3. Prefer Dart 3 idioms: records, sealed classes,
  exhaustive `switch` expressions, pattern matching.
- **State management: Riverpod** (`flutter_riverpod` ^3.4.2) with code-gen
  (`riverpod_annotation` ^4.0.6, `riverpod_generator` ^4.0.8, `build_runner`).
  One `Notifier` per feature; UI reads via `ConsumerWidget`/`ConsumerStatefulWidget`.
  No `provider`, no `get_it`, no `ChangeNotifier` ViewModels.
  **Why, not just preference:** this app has real cross-feature derived state —
  onboarding answers → generated itinerary → auto-saved route; skip/restore
  toggles a "N removed stops" count; reorder recomputes duration/drive-time.
  Riverpod's computed providers express these without `BuildContext` and are
  unit-testable without `WidgetTester`. The official
  `flutter-apply-architecture-best-practices` skill defaults to
  ChangeNotifier+Provider/get_it — a reasonable default for simpler apps, but
  weaker here because that derived state ends up synced by hand via
  `notifyListeners()` chains. If implementation shows Riverpod is overkill for
  what this app actually needs, revisit — this is a technical call, not dogma.
  *(Reasoning recorded 2026-08-25.)*
- Routing: `go_router` (^18.0.0), declarative, `MaterialApp.router`. Bottom nav =
  `StatefulShellRoute` so each tab keeps its own stack.
- Maps: `flutter_map` (^8.3.1) + `latlong2` with dark CARTO-style tiles (matches
  the prototype's dark map). **No Google Maps SDK dependency** — "Export to Google
  Maps" is just a `https://www.google.com/maps/dir/...` URL launch, not an SDK.
- Icons: `flutter_lucide` (^1.34.0) or Material equivalents — outline-only,
  theme-driven color, no fill. Icon list is in `PRD.md` → Assets.
- Swipe-to-delete: `flutter_slidable` (^4.0.3), `endActionPane` + `DrawerMotion`.
- Reorderable itinerary list: `ReorderableListView`.
- Bottom sheet with 3 snap heights: `DraggableScrollableSheet` + `snapSizes`.
- Pin exact versions in `pubspec.yaml`; the numbers above were latest-stable on
  2026-08-25 and are a starting point, not a permanent constraint.

## Architecture
Layered, following the official Flutter architecture guidance **with one
deliberate substitution**: where that guidance says "ViewModel extends
ChangeNotifier + provider/get_it DI", we use a **Riverpod `Notifier`** instead.
Everything else about the layering holds.

```
lib/
├── data/           # seeded stop data, local persistence (saved routes)
├── domain/         # immutable models: Stop, Itinerary, SavedRoute, OnboardingAnswers
└── ui/
    ├── core/       # theme, design tokens, shared widgets
    └── features/<feature>/   # notifiers/ + views/
```

- Views stay lean: layout, animation, routing. No business logic.
- Notifiers expose immutable state snapshots; UI never mutates state in place.
- Keep pure logic (arc-length sampling, Google Maps URL building, reorder/skip
  transforms) in plain Dart functions — no widgets, no Flutter imports — so it's
  unit-testable without `WidgetTester`.

## Design tokens
Colors, type, spacing, radius, motion are exact values in `PRD.md` → Design
tokens. **Treat them as final, not placeholders. No light mode.** Define them
once in `ui/core/theme/` and reference them by name — never hardcode a hex or a
magic number in a widget.

## Fidelity
High-fidelity rebuild. Match spacing, type, radii, and copy in `PRD.md` and
`screenshots/` exactly. Do not restyle or "improve" the design. A visual
difference from the screenshot is a bug, not a preference.

## The one hard algorithm
**Car-follows-route animation** (login ambient loop + onboarding backdrop):
parameterize the route by cumulative arc length along the polyline, drive a
single `0..1` progress value with an `AnimationController`, and on each tick
sample lat/lng at that progress by walking the cumulative-distance table.
**Never lerp raw lat/lng between two arbitrary points** — the car must visibly
pass through every intermediate stop. Reference implementation:
`pointAtFraction` in `design-reference/terra-nt-bg-map.html`.

Write this as a pure function first and unit-test it (fraction 0 → first point,
1 → last point, 0.5 → a point on the correct segment) before wiring any widget.

## Definition of done (per screen)
Rule 4, made concrete. A screen isn't done until all of these hold:

1. `dart analyze` is clean — zero warnings, zero infos.
2. No layout exceptions in the debug console (no overflow stripes, no unbounded
   constraint errors).
3. The screen visually matches its PNG in `screenshots/` — spacing, type scale,
   radii, and colors traced back to the tokens. **Don't rely on eyeballing this:**
   add a golden test (`matchesGoldenFile`) for the screen, generated with
   `flutter test --update-goldens` the first time, then checked in and compared
   on every run — that's what actually catches a silent visual regression, not
   a glance at the simulator. Use `flutter-add-widget-test` skill's workflow as
   the base and add the golden assertion on top.
4. Every piece of real logic on that screen has a test: reorder, skip/restore,
   swipe-delete thresholds, sheet snapping, arc-length sampling, Maps URL building.
5. Copy matches `PRD.md` / `Terra NT.dc.html` character-for-character.

Confirm a screen is done before moving to the next one. Order of work is in
`README.md` → Suggested order of work.

Golden files are platform/font-rendering-sensitive — generate and compare them
in the same environment (CI or one pinned dev machine), not across OSes.

## Available skills (official Dart & Flutter plugin)
`dart-flutter@dart-flutter` is installed at project scope (23 skills + Dart MCP
server). These are *skills* — task procedures — not subagents; they complement
the subagents in `.claude/agents/`.

**Use these, proactively:**

| Skill | When |
|---|---|
| `flutter-fix-layout-issues` | Any overflow / unbounded-constraint error |
| `flutter-add-widget-test` | Gate 4 above, for anything with interaction |
| `flutter-add-integration-test` | End-to-end flows: onboarding → loading → result |
| `flutter-setup-declarative-routing` | Initial `go_router` + bottom-nav shell setup |
| `flutter-add-widget-preview` | New shared widgets in `ui/core/` |
| `dart-run-static-analysis` | Gate 1 above, after every meaningful change |
| `dart-fix-runtime-errors` | Stack traces during hot reload |
| `dart-add-unit-test` / `dart-generate-test-mocks` | Pure-logic tests |
| `dart-use-pattern-matching` | Modelling state as sealed classes |
| `dart-resolve-package-conflicts` | pubspec version conflicts |

**Use with the override noted above:**
- `flutter-apply-architecture-best-practices` — follow its layering, ignore its
  ChangeNotifier/provider prescription. Riverpod wins (see Architecture).

**Not applicable to this project — don't invoke:**
`flutter-use-http-package` (no backend), `flutter-setup-localization` (the
Language row is display-only; no i18n in scope), `dart-setup-ffi-assets`,
`dart-use-ffigen` (no native code), `dart-build-cli-app` (not a CLI),
`dart-migrate-to-checks-package` (no tests to migrate).
`flutter-implement-json-serialization` only becomes relevant if we persist saved
routes as JSON — ask first (rule 1).

**Dart MCP server** is registered by the plugin. After editing any `.dart` file,
connect to the running app and hot reload so changes are visible immediately. If
no app is running, say so and keep going — don't let it block the edit.

## Open decisions
Nothing here is a licence to guess — these are flagged for a decision, per rule 1.

- **Saved-routes persistence:** in-memory only, or `shared_preferences`/local
  storage across launches? PRD doesn't say. Ask before building the data layer.
- **Tag colors:** *no longer blocking.* `design-system/tokens/colors.css` supplies
  six concrete hexes (blue `#5e6ad2`, purple `#8b5cf0`, green `#27a644`, yellow
  `#d4a72c`, orange `#d97b34`, red `#d1484a`), but they are **provisional** —
  derived from the accent hue family, not sampled from the real product. Build on
  them as named tokens; a later correction should be a one-line change, not a
  sweep. Still worth confirming with the design owner.
- **Fonts:** the real Terra NT cuts are proprietary and were never supplied; the
  system substitutes Inter + JetBrains Mono. Decide **before T-00 lands** whether Flutter
  gets them via `google_fonts` or bundled font files — goldens are
  font-rendering-sensitive, so switching later invalidates every checked-in golden.
- **Tablet/landscape:** design is phone-only. No responsive spec exists — don't
  invent one.

## File placement
The repo root is `Terra NT/`. The Flutter project is **not** the repo root — it
lives in a `terra_nt/` subfolder and contains *only* the app:

```
Terra NT/                  ← repo root: git, docs, design, agent config
├── CLAUDE.md              ← this file, once T-00 moves it up from design/
├── README.md
├── .claude/
├── design/                ← PRD.md, screenshots/, design-reference/, design-system/
├── docs/tickets/
└── terra_nt/              ← Flutter project — lib/, test/, pubspec.yaml, android/, ios/
```

Nothing from `design/`, `docs/`, `.claude/` or `README.md` moves under `terra_nt/`.
The docs stay at the repo root, where they are outside anything the analyzer or
build treats as source, and where Claude Code still loads `CLAUDE.md` when the
working directory is `terra_nt/` (parent directories are read).

Run all Flutter and Dart commands from `terra_nt/`. Paths in `PRD.md` and in the
tickets are relative to the repo root — from inside `terra_nt/` that is `../design/…`.
