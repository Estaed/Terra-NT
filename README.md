# Terra NT

🚧 **Work in progress.** 🚧

## Run

The Flutter app is in `terra_nt/`. Copy `terra_nt/.env.example` to `terra_nt/.env` and fill
in `CARTO_API_KEY`, then pass the file to every run and build — without it the map tiles
say "API KEY REQUIRED":

    cd terra_nt
    flutter run --dart-define-from-file=.env
    flutter build apk --dart-define-from-file=.env

## Demo on a phone (Android, USB cable)

1. Phone: *Settings → About phone*, tap *Build number* seven times, then *Developer options →
   USB debugging* on. Plug it in and accept the prompt.
2. Laptop: double-click `tools/plan_server/start.bat`. It links every plugged-in phone and
   emulator to the laptop, then runs the AI planner; keep that window open.
3. Install the app: `adb install -r terra_nt/build/app/outputs/flutter-apk/app-release.apk`
   (build it first with `flutter build apk --release --dart-define-from-file=.env`, with
   `PLAN_API_URL=http://127.0.0.1:8787` in `.env`).

A phone plugged in after step 2 needs `tools/plan_server/link-devices.bat`. iPhone:
`docs/IOS-SETUP.md`.

**Without a cable:** build with `PLAN_API_URL=https://passable-random-rebuttal.ngrok-free.dev`
in `.env` and run `tools/plan_server/start-demo.bat` instead of `start.bat`. It opens the
server to the internet through the operator's ngrok domain (`ngrok config add-authtoken`
once), so the phone reaches it over any network. The Firebase token check stays on.
