# Task-47 — iOS configured from Windows; a dark launch screen on both platforms
**Status: DONE** — 2026-09-29, main loop (Android launch checked at the wave's closing emulator tour; iOS not built: no Mac here)

> **Execution:** agent `main-loop` · effort `medium`
> *Why:* Firebase CLI registration under the operator's login and platform files; no Dart.

## What was done

- `flutterfire configure --platforms=android,ios` registered the iOS app
  (`1:125884332328:ios:a32039f5a3fc95ffe7381d`, bundle `au.edu.cdu.terraNt`) in
  `terra-nt-cdu`; `lib/firebase_options.dart` returns it instead of throwing. The Android
  entry is unchanged. `terra_nt/firebase.json` is the CLI's record of the mapping.
- `ios/Runner/Info.plist`: Google Sign-In's `GIDClientID`, `GIDServerClientID` (the web
  client from `google-services.json`) and the reversed-client-id URL scheme.
- iOS app icon: all 15 sizes from a 1024 px `gpt-image-2` redraw of the Android icon on
  `AppColors.canvas`, opaque, no rounded corners.
- Launch screen: Android `launch_background` on `@color/ic_launcher_background`
  (`#010102`, the canvas token), `Theme.Black` parents, `windowSplashScreenBackground` for
  API 31+ in both `values-v31` and `values-night-v31`; iOS `LaunchScreen.storyboard`
  background the same colour. The white flash before the first frame is gone.
- `docs/IOS-SETUP.md`: the Mac teammate's steps (free Apple ID, release build, 7-day renew).

## Open

- [ ] (device) First iOS build on a Mac, sign-in with email and Google, map, Plan AI.
