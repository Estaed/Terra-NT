# Running Terra NT on an iPhone

For a teammate with a Mac. Written 2026-09-29 on Windows, where iOS cannot be built, so
**nobody has built the iOS app yet**: if a step below fails, send Tarık the exact error.

What is already done in the repo: the iOS app is registered in Firebase (`terra-nt-cdu`,
bundle id `au.edu.cdu.terraNt`), `lib/firebase_options.dart` has the iOS entry, Google
Sign-In's iOS client id and URL scheme are in `ios/Runner/Info.plist`, and the app icon and
dark launch screen are in place. Nothing below needs a Firebase console.

## You need

- A Mac with the current Xcode (App Store), opened once so it installs its components.
- Flutter 3.47.1 (`flutter --version`) and CocoaPods (`brew install cocoapods`).
- An iPhone and its cable, and a free Apple ID. No paid developer account.
- The `terra_nt/.env` file from Tarık (sent privately, never committed). Without it the
  map says "API KEY REQUIRED" and the app plans the built-in demo route.

## Steps

1. Clone the repo, put `.env` in `terra_nt/`, then:

       cd terra_nt
       flutter pub get
       cd ios && pod install && cd ..

2. `open ios/Runner.xcworkspace` (the workspace, not the project). Select **Runner** →
   **Signing & Capabilities** → **Team**: add your Apple ID and pick its *Personal Team*.
   Keep the bundle id `au.edu.cdu.terraNt`: Firebase and Google Sign-In are tied to it. If
   Xcode says the id is unavailable, stop and tell Tarık rather than changing it.
3. On the iPhone: plug it in, tap *Trust*, then **Settings → Privacy & Security →
   Developer Mode → On** (the phone restarts).
4. Build a release build, so the app opens from the home screen without the Mac:

       flutter run --release --dart-define-from-file=.env

5. The first launch is blocked until you trust yourself: **Settings → General → VPN &
   Device Management →** your Apple ID → *Trust*.

The app stops opening after 7 days (free Apple ID limit); run step 4 again to renew. Every
other iPhone that should get the app is plugged into the Mac once and step 4 is repeated.

## The AI planner on an iPhone

iOS refuses plain `http`, so `PLAN_API_URL` in `.env` must be the `https://…` address Tarık
gets from `cloudflared` while `tools/plan_server` runs on his machine
(`tools/plan_server/README.md`). Rebuild (step 4) after changing `.env`.
