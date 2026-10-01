# Offline map errors reported as fatal

The Firebase stability email for 30 September linked issue
`aa89cc42ceb68fb5f5e3b60e013cffc5`: 11 fatal events affecting one user, on an
Android 16 `Sdk_gphone64_x86_64` emulator. The console's stack identifies
`IOClient.send` / `NetworkTileImageProvider._loadImage` and a failed DNS lookup
for `basemaps.cartocdn.com`. These records do not establish that the process exited:
`main.dart` sent every Flutter error to `recordFlutterFatalError`.

The installed error handler now excludes only image-resource errors that are
both `SocketException` and HTTP `ClientException`, with an HTTPS CARTO raster
tile URI. It retains Flutter's local diagnostics. HTTP authorization errors,
decoding errors, other hosts, other paths, widget errors, and unhandled platform
errors continue through the existing fatal reporters. No tile cache or offline
notice behavior changed.

Validation:

- `flutter analyze --no-pub`: no issues.
- Entire Flutter suite: 957 tests passed.
- Regression test invokes the installed Flutter and platform handlers, checking
  excluded and retained errors. Inverting the filter made the test fail; restoring
  it passed.
- Android release APK built and installed with `adb install -r`, preserving data.
- Emulator `emulator-5554`, Wi-Fi and mobile data disabled, active default network
  absent: offline cold start kept the process alive and rendered the cached Explore
  map. Screenshot: `2026-10-01-firebase-map/offline-cached.png`.
- A temporary release probe on that offline emulator resolved an uncached Sydney
  tile through the actual `NetworkTileProvider`, without an image listener. The
  real image-stream failure reached the production handler with **0** recorded
  errors. A subsequent application-error control reached the reporter with **1**
  recorded error. The probe used local counting callbacks, sending no test
  crashes to Firebase. The normal application entry point was restored afterward.

Sources:

- [Firebase issue](https://console.firebase.google.com/project/terra-nt-cdu/crashlytics/app/android:au.edu.cdu.terra_nt/issues/aa89cc42ceb68fb5f5e3b60e013cffc5)
- [Flutter silent error semantics](https://api.flutter.dev/flutter/foundation/FlutterErrorDetails/silent.html)
- [Firebase error reporting](https://firebase.google.com/docs/crashlytics/flutter/customize-crash-reports)

Existing Firebase history is unchanged. The new APK prevents future matching
offline tile errors from being recorded as fatal; installed older builds retain
their previous behavior.
