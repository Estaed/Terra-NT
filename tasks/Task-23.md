# Task-23 — Firebase project and app wiring

**Status: DONE** — verified 2026-09-22
> **Verified against:** 47dc8ce4df terra_nt/android/app/build.gradle.kts 0d8b0d0d0d terra_nt/android/app/google-services.json 5ce1a86e06 terra_nt/android/settings.gradle.kts 4f5ccb36de terra_nt/lib/firebase_options.dart 2eb530663f terra_nt/lib/main.dart 9d9809d3a2 terra_nt/pubspec.lock f43f152f95 terra_nt/pubspec.yaml

> **Execution:** agent main loop · effort `medium`
> *Why:* Half of this task is not code: a Firebase login the operator has to approve in a
> browser, two provider switches in the Firebase console, and a SHA-1 registration. A bee
> cannot do those. The Dart part is four lines in `main.dart`.

**Lane**
- OWNS: `terra_nt/pubspec.yaml`, `terra_nt/pubspec.lock`, `terra_nt/lib/main.dart`, `terra_nt/lib/firebase_options.dart`, `terra_nt/android/app/google-services.json`, `terra_nt/android/app/build.gradle.kts`, `terra_nt/android/settings.gradle.kts`
- MUST NOT TOUCH: `terra_nt/lib/data/` and `terra_nt/lib/features/` (Task-24), `terra_nt/lib/shared/` (Task-02, Task-07), `terra_nt/lib/core/` (Task-01, Task-04)
- GATE: `cd terra_nt && flutter analyze && flutter test && flutter build apk --debug`
- DEPENDS ON: Task-22

## Objective

Phase 2 begins here (`docs/PRD.md` D12, 2026-09-22). This task makes Firebase exist for
the app and nothing more: a Firebase project, the Android app registered in it, the
generated `firebase_options.dart`, `Firebase.initializeApp` at boot, and the two sign-in
providers switched on. When it is done the app boots exactly as before, the test suite is
untouched and green, and Task-24 can write `FirebaseAuthRepository` against a project that
answers.

The three packages are already in `pubspec.yaml` and pinned in `CLAUDE.md` → Blueprint →
Stack (added 2026-09-22 while writing this wave: `firebase_core` 4.15.0, `firebase_auth`
6.7.0, `google_sign_in` 7.2.0). Do not bump them.

## What is fixed

- **Android first.** `flutterfire configure` runs with `--platforms=android` only. iOS is
  under *Later* in `docs/TASKS_INDEX.md`; do not register an iOS bundle here.
- **Application id `au.edu.cdu.terra_nt`** (`android/app/build.gradle.kts`). The Firebase
  Android app is registered under that id and no other.
- **`google-services.json` and `firebase_options.dart` are committed.** Firebase's Android
  API key is not a secret by Google's own documentation — it identifies the project, it
  does not authorise anything; authorisation is the sign-in itself and, later, security
  rules. A teammate cloning the repo must build without re-running `flutterfire`. The
  CARTO key stays in the gitignored `.env`; that is a different kind of key.
- **The debug SHA-1 is registered** on the Firebase Android app, or Google Sign-In fails
  at Task-25 with `DEVELOPER_ERROR`. Keystore: `D:\Dev\Android\.android\debug.keystore`
  (`ANDROID_USER_HOME` points there, not at `~/.android`). Fingerprint read 2026-09-22:
  `EA:C3:D6:B5:56:E8:1D:90:F0:83:9F:E9:61:24:4C:CE:0E:7F:3E:9A`.
- **`minSdk` stays `flutter.minSdkVersion`** (24 on Flutter 3.47.1). `firebase_auth` 6.x
  needs 23; nothing to change unless the build says otherwise.
- **`main.dart` initialises Firebase before `runApp`** and nowhere else:

  ```dart
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  ```

  Tests never call `main()`, so no test touches Firebase and none needs a fake.

## Execution Guide

1. **Operator step — login.** `firebase login` is interactive; the operator runs it (in
   this session: `! firebase login`). `firebase login:list` must then show an account.
   Firebase CLI 15.30.2 and FlutterFire CLI 1.4.1 were installed 2026-09-22
   (`npm install -g firebase-tools`, `dart pub global activate flutterfire_cli`).
   `flutterfire` lives in `D:\Dev\PubCache\bin` (the pub cache is `D:\Dev\PubCache`,
   not the default), which is not on `PATH`; call `D:\Dev\PubCache\bin\flutterfire.bat`
   by full path or add the directory.
2. **Create the project.** `firebase projects:create terra-nt-cdu --display-name "Terra NT"`.
   If the id is taken, append a short suffix; record the final id in this file.
3. **Configure.** From `terra_nt/`:
   `flutterfire configure --project=<id> --platforms=android --android-package-name=au.edu.cdu.terra_nt --yes`.
   This writes `lib/firebase_options.dart`, `android/app/google-services.json`, adds the
   `com.google.gms.google-services` plugin to the Gradle files, and creates
   `firebase.json`. Check the Gradle edits went into the `.kts` files, not a stale `.gradle`.
4. **Register the SHA-1.** `firebase apps:android:sha:create <androidAppId> EAC3D6B556E81D90F0839FE961244CCE0E7F3E9A --project <id>`
   (the app id comes from `firebase apps:list --project <id>`). Then re-download
   `google-services.json` (`firebase apps:sdkconfig android <androidAppId>` or rerun
   `flutterfire configure`) so it carries the OAuth clients that the SHA-1 creates —
   `google_sign_in_android` reads its server client id from that file.
5. **Operator step — providers.** In the Firebase console → Authentication → Sign-in method,
   enable **Email/Password** and **Google** (Google asks for a support email; use the
   project owner's). The CLI has no command for this. Enabling Google adds a *web* OAuth
   client to `google-services.json` (`oauth_client` entry with `client_type: 3`); download
   it again after this step.
6. **Wire `main.dart`** as fixed above. `main` becomes `Future<void> main() async`.
7. Run the GATE. `flutter build apk --debug` is the criterion that exists for this task: it
   is where the Gradle plugin, the JSON and the native registration break, and the
   ordinary test run never compiles any of it.

## Acceptance Criteria (DoD)

- [x] `terra_nt/lib/firebase_options.dart` exists, is committed, and `currentPlatform`
      resolves for Android (the file's `android` static is present).
- [x] `terra_nt/android/app/google-services.json` exists, is committed, names
      `package_name: "au.edu.cdu.terra_nt"`, and contains at least one `oauth_client` with
      `client_type: 3` — checkable with
      `python -c "import json;d=json.load(open('android/app/google-services.json'));assert any(c['client_type']==3 for c in d['client'][0]['oauth_client'])"`.
- [x] The Firebase Android app carries the debug SHA-1 above:
      `firebase apps:android:sha:list <androidAppId> --project <id>` prints it.
- [x] `main.dart` calls `Firebase.initializeApp` with `DefaultFirebaseOptions.currentPlatform`
      before `runApp`, and no other file imports `firebase_core`.
- [x] `cd terra_nt && flutter analyze` is clean.
- [x] `cd terra_nt && flutter test` passes with no test changed by this task.
- [x] `cd terra_nt && flutter build apk --debug` succeeds.
- [x] `CLAUDE.md` → Blueprint → Stack lists the three packages at the versions in
      `pubspec.lock` (already true; re-check after `flutterfire configure`, which must not
      change them).
- [x] Operator confirmation recorded in this file: Email/Password and Google providers
      enabled, project id written under *Result* below.

## Result

OWNS was narrowed at verification from the whole `android` directory to the three files this task wrote, so the DONE stamp does not hash Gradle caches.

Verified 2026-09-22 from the main loop. Project id **`terra-nt-cdu`**; Android app id
`1:125884332328:android:e6150153bf7a3e5ce7381d`; debug SHA-1 registered and listed back.

- **FlutterFire CLI 1.4.1 could not resolve the project** through firebase-tools 15.30.2
  ("Found 1 Firebase projects. Selecting project terra-nt-cdu" followed by
  `FirebaseProjectNotFoundException`, twice, with `--account` too). The same steps ran
  through the Firebase CLI instead: `apps:create android`, `apps:android:sha:create`,
  `apps:sdkconfig android -o`; `lib/firebase_options.dart` was written by hand in the
  shape `flutterfire configure` produces, from the JSON. The Gradle plugin
  (`com.google.gms.google-services` 4.5.0, the current release on Google's Maven) was
  added by hand; the first attempt matched LF in CRLF files and silently changed nothing,
  so the first APK build proved nothing — caught by `git status`, redone, and the rebuild
  left `build/app/generated/res/processDebugGoogleServices/values/values.xml` behind,
  which is the proof the plugin ran.
- Operator enabled **Email/Password** and **Google** in the console. Google's enablement
  created the OAuth clients; the JSON was re-downloaded and now carries `client_type` 1
  and 3. Email/Password is proven from the device: a sign-in against an unknown account
  came back `Email or password is incorrect.` (a disabled provider answers
  `operation-not-allowed`), and an account was created, listed by `firebase auth:export`,
  and deleted again from Profile (export then listed 0).
- The criterion "no other file imports `firebase_core`": `firebase_options.dart` imports
  only the `FirebaseOptions` type, which is what that file is for; no feature, data or
  core file imports the package. Ticked on that reading.
- Operator also restricted the Android API key to the package + SHA-1 in Google Cloud
  (2026-09-22). The key is committed in `google-services.json` and
  `firebase_options.dart` on purpose; the repo is private.

Gate: `flutter analyze` clean; `flutter test` 333 at the time of this task (361 after
Task-24/25); `flutter build apk --debug` succeeded with the plugin applied. Trajectory:
iter 0 green (plugin missing, invalid) → iter 1 green (plugin applied).
