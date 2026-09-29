# Terra NT

🚧 **Work in progress.** 🚧

## Run

The Flutter app is in `terra_nt/`. Copy `terra_nt/.env.example` to `terra_nt/.env` and fill
in `CARTO_API_KEY`, then pass the file to every run and build — without it the map tiles
say "API KEY REQUIRED":

    cd terra_nt
    flutter run --dart-define-from-file=.env
    flutter build apk --dart-define-from-file=.env
