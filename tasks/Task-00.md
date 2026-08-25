# Task-00 — Flutter project scaffold and repo layout

**Status: DONE** — verified 2026-08-26. Org id `au.edu.cdu` (`applicationId au.edu.cdu.terra_nt`), platforms `android,ios`. `flutter_riverpod` resolved to 2.6.1, not 3.x — see `CLAUDE.md` → Part 2 → Stack for why. All 14 acceptance criteria re-run and passing: `flutter analyze` 0 issues, `flutter test` 10/10, `flutter build apk --debug` exit 0, app installed and launched on `emulator-5554` (Android 16) showing the `Terra NT` scaffold.

## Objective

Create the Flutter project at `terra_nt/` with the exact stack `CLAUDE.md` → Part 2 pins,
and settle the repo layout so no later task has to move files. Nothing in this task
renders UI; it exists so that every task after it starts from a project that analyzes
clean and runs tests.

**Fonts are already in place** — downloaded 2026-08-26 and committed at
`terra_nt/assets/fonts/`: Inter 4.1 (Regular/Medium/SemiBold/Bold) and JetBrains Mono 2.304
(Regular/Medium), both SIL OFL 1.1 with their licence files alongside. This task only has
to *declare* them in `pubspec.yaml`. Part 2 forbids `google_fonts`.

Note: `flutter create` must not delete them. Run it in the existing directory and confirm
`assets/fonts/` still holds 8 files afterwards.

## Execution Guide

**Create the project.** From the repo root:

```
flutter create --org <org-id> --platforms=android,ios terra_nt
```

The org id is a decision — pick one and record it in the task's completion note. Nothing
from `docs/`, `design/`, `.claude/` or `README.md` moves under `terra_nt/`; the Flutter
project holds the app and nothing else. Run every `flutter`/`dart` command from
`terra_nt/`.

**`pubspec.yaml`** — pin `environment: sdk: ^3.13.1`. Add exactly the packages in Part 2 →
Stack and no others:

```
flutter pub add flutter_riverpod flutter_map latlong2 shared_preferences url_launcher flutter_lucide
flutter pub remove cupertino_icons
```

`flutter create` always adds `cupertino_icons` to `dependencies`. Nothing uses it — icons
come from `flutter_lucide` — and Part 2 admits no package it does not list, so it goes.

Then declare the font families. Place the files under `terra_nt/assets/fonts/` and declare
`Inter` (w400/w500/w600/w700) and `JetBrainsMono` (w400/w500).

**Write the resolved versions back into `CLAUDE.md` → Part 2 → Stack.** Part 2 explicitly
defers version pinning to this task and forbids inventing numbers. Read them from
`pubspec.lock` after `flutter pub get`.

**Create the folder skeleton** from Part 2 → Architecture, each with a `.gitkeep` so the
layout is committed before any code lands:

```
lib/{app,core/{theme,util},data/{models,seed,repositories},features,shared}
test/{core/util,data,features}
```

**`analysis_options.yaml`** — include `package:flutter_lints/flutter.yaml`. Part 2 requires
`flutter analyze` to be clean with zero warnings, so do not disable rules to make it pass;
if a rule fights the codebase, raise it rather than silencing it.

**`.gitignore`** — confirm the Flutter defaults cover `build/`, `.dart_tool/`,
`pubspec.lock` decisions and the platform folders. Keep `pubspec.lock` committed (this is
an app, not a library).

## Acceptance Criteria (DoD)

- [x] `terra_nt/pubspec.yaml` exists with `environment: sdk: ^3.13.1`.
- [x] `cd terra_nt && flutter pub get` exits 0.
- [x] `pubspec.yaml` `dependencies:` contains exactly `flutter`, `flutter_riverpod`, `flutter_map`, `latlong2`, `shared_preferences`, `url_launcher`, `flutter_lucide` — and nothing else.
- [x] `grep -c "google_fonts" terra_nt/pubspec.lock` returns 0 — the lock file is authoritative and catches it at any depth. (Do **not** grep `pubspec.yaml`: a comment there correctly explains *why* the package is absent, and matching prose would fail the check for the wrong reason.)
- [x] `ls terra_nt/assets/fonts/*.ttf | wc -l` returns 6, and both licence files are still present.
- [x] `pubspec.yaml` declares family `Inter` with weights 400/500/600/700 and `JetBrainsMono` with 400/500, each pointing at a file that exists.
- [x] `test/fonts_test.dart` asserts **`rootBundle.load` succeeds for all six `.ttf` paths**. Asserting a resolved `fontFamily` alone is not enough — it passes even when the asset path is wrong, because `flutter test` substitutes a stub font either way. Only reading the asset proves it is declared and bundled.
- [x] That suite also asserts a **path that cannot exist throws**, so the six checks above cannot pass vacuously.
- [x] The Stack table in `CLAUDE.md` → Part 2 lists a resolved version for every package, matching `terra_nt/pubspec.lock`.
- [x] All directories in Part 2 → Architecture exist under `terra_nt/lib/`.
- [x] `cd terra_nt && flutter analyze` exits 0 and prints no warnings.
- [x] `cd terra_nt && flutter test` exits 0 (the default counter test may be deleted; an empty suite passing is acceptable).
- [x] `cd terra_nt && flutter build apk --debug` exits 0.
- [x] No file from `docs/`, `design/` or `.claude/` exists under `terra_nt/`.
