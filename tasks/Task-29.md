# Task-29 — Crashlytics, and the disclosure row in Profile

**Status: DONE** — verified 2026-09-23 00:48 (otopilot: worktree gate green incl. debug APK, integrated gate green on main, 433 tests)

> **Execution:** agent `codex` · effort `high` (a bee lane; tonight's bees are Claude by operator decision, 2026-09-22)
> *Why:* Four Gradle lines, six Dart lines and one row with fixed copy. The criterion is
> `flutter analyze` + tests + a debug APK build, because the Gradle plugin is the one
> thing the test run does not compile. Whether a crash reaches the console is a manual
> main-loop check, not a DoD item.

**Lane**
- OWNS: `terra_nt/lib/main.dart`, `terra_nt/android/settings.gradle.kts`, `terra_nt/android/app/build.gradle.kts`, `terra_nt/lib/features/profile/profile_screen.dart`, `terra_nt/test/features/profile/profile_screen_test.dart` (the new row assertion only; Task-27 owns the delete-order assertion in the same file — append-only, both add tests, neither edits the other's), `terra_nt/test/app/boot_test.dart`
- MUST NOT TOUCH: `terra_nt/pubspec.yaml`, `terra_nt/pubspec.lock`, `terra_nt/android/app/src/` (Task-32 owns the debug manifest), `terra_nt/lib/data/`, `terra_nt/lib/features/profile/account/` (Task-28), `terra_nt/lib/shared/`, `terra_nt/lib/core/theme/`
- GATE: `cd terra_nt && flutter analyze && flutter test test/features/profile/ test/app/ && flutter build apk --debug`
- DEPENDS ON: Task-26

## Objective

A crash on a phone in Kakadu becomes a stack trace in the Firebase console
(`docs/PRD.md` D13). The package is already pinned (`firebase_crashlytics` 5.4.0,
Blueprint Stack); this task wires the Gradle plugin, routes Flutter's error handlers to
it, and adds the one-line disclosure `docs/PRD.md` §3.9 specifies.

## The contracts — fixed, not guidance

### 1. Gradle

- `settings.gradle.kts` plugins block: `id("com.google.firebase.crashlytics") version
  "3.0.6" apply false` next to the google-services line (3.0.x is the current major on
  2026-09-22; if Gradle refuses the exact patch, use the newest 3.0.x it resolves and say
  so in the report).
- `app/build.gradle.kts` plugins block: `id("com.google.firebase.crashlytics")` after
  `com.google.gms.google-services`.

### 2. `main.dart`

After `Firebase.initializeApp`:

```dart
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
PlatformDispatcher.instance.onError = (error, stack) {
  FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  return true;
};
```

Collection stays at the plugin default (on). No opt-out toggle: the app has no settings
surface and §8 keeps it that way; the disclosure row is the privacy line.

### 3. Profile — the `Crash reports` row

After the Language row, before Log Out, same row widget: label `Crash reports`, value
line `Sent anonymously to fix bugs.`, no chevron, not tappable, `key:
ValueKey('profile-crash-reports')`.

## Execution Guide

Gradle first and build once, so a plugin-version problem surfaces before any Dart is
touched. `boot_test.dart` pumps the app with no Firebase; the two handler assignments
happen in `main()` which tests never call, so the test is unaffected — assert that it
still passes rather than assuming.

## Acceptance Criteria (DoD)

- [x] `grep -n "firebase.crashlytics" android/settings.gradle.kts android/app/build.gradle.kts`
      shows both lines.
- [x] `grep -n "recordFlutterFatalError\|PlatformDispatcher.instance.onError" lib/main.dart`
      shows both handlers.
- [x] `profile_screen_test.dart`: the row with key `profile-crash-reports` renders
      `Crash reports` and `Sent anonymously to fix bugs.`, and tapping it changes
      nothing (no navigation, same widget tree).
- [x] `cd terra_nt && flutter build apk --debug` succeeds.
- [x] `cd terra_nt && flutter analyze` is clean.
- [x] `cd terra_nt && flutter test` passes.
