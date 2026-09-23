# Findings ledger — 2026-09-23 goal run

One line per finding: `- [ ] <area>: <defect or gap> (source: audit|tour|eye|gate) → Task-NN`. Ticked when its task is DONE on main.

- [x] Loading: seeded path flashes, V1 7000 ms lost in Task-33 integration (source: orchestrator) → Task-34
- [x] Loading: retry wiring untested (source: gate) → Task-34
- [x] Account: catch-all hides a misconfigured build (source: gate) → Task-35
- [x] Launch: a fresh install with nobody signed in lands on onboarding, not Login — phase 1's Q2 rule predates real accounts; plans are made with no uid, nothing syncs, Profile shows the placeholder email (source: tour, `tour-01-launch.png`) → Task-36
- [x] Explore: the map fit ignores the status bar and the search field; the Darwin-area POI pins sit under the clock and under the search box (source: tour, `tour-04-explore.png`; the prototype has the same fit, ours adds the status bar) → Task-37
- [x] Result: stops 1–3 sit under the status bar, same fit defect (source: tour, `tour-05-06-pair.png`) → Task-37
- [x] Plan AI: a user who skipped onboarding sees the seeded Full NT route as if generated ("7 days · 7 stops"); no empty state (source: tour) → Task-40
- [x] Profile: signed-out user sees the placeholder email and a Log Out row (source: tour) → closed by Task-36's routing
- [x] Auth wrapper: `currentUser!` throws a TypeError past the seam when the user is gone (source: audit) → Task-38
- [x] Plan parser: an empty-string stop name is kept, contract says drop (source: audit) → Task-38
- [x] Goal gate: lib/data coverage below 97% (source: gate) → Task-38
- [x] Result: an edited leg says "Drive time unavailable" where the distance is known (source: audit, improvement) → Task-39
- [x] Explore: POI markers identical regardless of category; tag colours exist (source: audit, improvement) → Task-41
- [x] Stop detail / Explore / Saved: no images anywhere (source: operator) → assets generated 02:03–02:06 (`2f0e013`), wired by Task-42
- [x] Launcher: the app had the default Flutter icon (source: operator, 2026-09-22) → adaptive + legacy icon committed in `2f0e013`
- [x] Tile warmup: still uses the flat Explore fit after Task-37, so it can warm the wrong zoom (source: orchestrator, regression from Task-37) → Task-43
- [x] Result: opens on cold tiles after the 7 s Loading wait (source: audit, improvement) → Task-43
- [x] Account: verification row blank while loading, indistinguishable from no answer (source: audit, improvement) → Task-44
- [x] Emulator eye check 02:45–02:50 (`reports/shots/final-*.png`): fresh install lands on Login with the reset link; account creation works against real Firebase; Explore pins carry tag colours and clear the search field; Plan AI shows the empty state; Saved Routes and Stop detail show the new illustrations; Result pins clear the status bar.
- [x] Minor, for the morning: both saved-route thumbnails are the same Uluru image, because Task-42 keys the thumbnail on the route's last stop and both seeded routes end at Uluru. Keying on the first stop, or the route id, would give two different cards. Fixed 2026-09-23: keyed on the first stop (Darwin, Alice Springs), widget test added.
- [x] Sign-up: a new account tapping Create My Route on Welcome landed on the black "Onboarding" placeholder, because Login opened Create Account without its onAuthenticated callback (source: tour 2026-09-23 17:08) → fixed the same day, widget test in `test/app/app_launch_test.dart`.
- [x] Sign-up: system Back on Welcome after sign-up returned a signed-in user to Login; the sign-in path leaves the app (source: tour 2026-09-23 17:30) → fixed the same day, Welcome is the stack root on both paths.

## Device tour — 2026-09-23 17:00–18:45 (emulator, real Firebase, stub on :8787)

Passed: sign-up → Welcome → real onboarding (after the fix above); onboarding Back from step 1 → Welcome; all 15 steps advance on Next only (V12); stub modes `ok`, `error`, `cannot_plan`, `rate_limited`, `invalid`, `refuse`, `slow` show the §3.4 copy and buttons, one request each; `Back` / `Change answers` return to step 15 with answers intact; `Try again` after switching the stub to `ok` lands on Result; `Cancel` in flight returns to step 15; the client timeout fires at ~60 s; Result pins clear the status bar; Firestore pull restores the generated route on a fresh install; Profile shows the Crash reports row; Account shows `Not verified` + `Resend email`; delete account first asks for a recent sign-in, then deletes and lands on Login, and the deleted account can no longer sign in.

- [x] Loading: system Back during generation leaves the app, the request still completes, and the route is saved — Cancel's contract says a cancelled generation saves nothing; after relaunch Plan AI says `No route yet` while Saved Routes holds the new route (source: tour). Operator chose Back = Cancel; fixed 2026-09-23, PRD §3.4 amended, device-toured.
- [x] Create account: with the keyboard open, the map attribution rides up over `Already have an account? Sign in` (source: tour, cosmetic). Login had the same overlap on `Sign up`. Fixed in `AuthBackdrop` 2026-09-23; the first fix passed a test that opened the keyboard before the build and failed on the device, the test now opens it after.
- [x] Saved Routes: after a Firestore pull on a fresh install, the generated route is second instead of on top (source: tour, minor). Fixed 2026-09-23: documents carry `position`, the pull restores it; device-toured.
- [ ] Not toured: Crashlytics test crash in the console, Firestore collection emptied after delete (both need the Firebase console), Google Sign-In.
