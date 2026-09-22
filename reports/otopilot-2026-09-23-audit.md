# Audit — 2026-09-23

Read-only pass over `terra_nt/lib`, `docs/PRD.md`, `docs/PHASE-3-CONTRACT.md`, and
`design/design-reference/Terra NT.dc.html`. `flutter analyze` (from `terra_nt/`) reports
"No issues found!"; `flutter test` reports "All tests passed!" (462 tests) — both run
2026-09-23 in this worktree, so a clean gate is a measured fact here, not an assumption.
Already-tracked items from `reports/otopilot-2026-09-23-findings.md` (Loading V1 flash,
Loading retry-untested, Account catch-all) are excluded per instructions.

**Second pass** read the map subsystem (`shared/map/*.dart`), the Firebase-backed
repositories (`firestore_saved_routes.dart`, `firebase_auth_repository.dart`), the auth
screens (`create_account_screen.dart`, `welcome_screen.dart`), `language_screen.dart`,
`onboarding_steps.dart`, `progress_drive.dart`, `route_sampler.dart`, `sheet_snap.dart`
and `swipe_snap.dart` against `docs/PRD.md`, `CLAUDE.md` and the prototype — the files the
first pass explicitly skipped. The car-glyph route coordinates, sampler, easing curve and
every timing constant (700 + span times 3500 ms travel, 900 ms ambient start delay,
1400 ms ambient pause, 140 ms flip, 1700 ms bob) were checked line-for-line against
`design/design-reference/terra-nt-bg-map.html` and matched exactly; the onboarding step
order/copy/options were checked against the same reference file's remote-comfort block and
against `docs/PRD.md` deviation V11 (the step-14 reorder) and matched. The
`TweenAnimationBuilder` pattern in `car_glyph.dart` (a fresh `Tween(end: facingScale)` built
every frame, no `begin`) was checked against the Flutter SDK source at
`D:\Dev\Flutter\packages\flutter\lib\src\widgets\tween_animation_builder.dart` lines 184-192
and confirmed to be the framework's own documented begin-defaults-to-end behaviour, not a
bug. `RouteCarBackdrop`'s timer/controller disposal was traced and is mounted-guarded
throughout, with no leak on early dispose during either the ambient-pause wait or a travel
animation in flight.

## Bugs

- Firebase auth seam violates its own no-leak contract on a null current user —
  `terra_nt/lib/data/repositories/firebase_auth_repository.dart:130`
  (`deleteAccount`: `_auth.currentUser!.delete()`) and `:150` (`sendEmailVerification`:
  `_auth.currentUser!.sendEmailVerification()`) use the null-check operator on
  `_auth.currentUser`. `auth_repository.dart` lines 6-7 document that every method may
  throw `AuthException` and nothing else — a provider's own exception type must never
  escape an implementation. A null `currentUser` (session expired or revoked elsewhere
  while the Account screen is still open, then the user taps "Delete account" or "Resend
  verification") throws a raw `TypeError` from the `!` instead of an `AuthException`,
  escaping the seam's contract before any Firebase request is even made — the surrounding
  `try`/`on FirebaseAuthException` blocks in this file never get a chance to catch it,
  because the bang throws in plain Dart, ahead of the SDK call.
- Plan response parsing: an empty-string stop `name` is not dropped, contradicting the
  contract's own rule — `terra_nt/lib/core/util/stop_json.dart` lines 30-33 only throw
  when `name` is not a `String` (so an empty string passes through unchanged into
  `Stop.name`), and `terra_nt/lib/core/util/plan_response.dart` lines 75-111
  (`_parseStop`) never separately check for emptiness. Verify by feeding
  `parsePlanResponse` a stop JSON with an empty-string `name`; per
  `docs/PHASE-3-CONTRACT.md` section 3.3 ("stop name — missing or empty leads to the stop
  being dropped") it should be dropped and is not. The only existing test,
  `stop_without_name.json` (`terra_nt/test/fixtures/plan/stop_without_name.json`), covers
  the missing-key case, not the empty-string case, so this gap is untested.

## Spec gaps

(None found beyond the bugs above and the already-tracked items — every other screen and
control read matched `docs/PRD.md` or `docs/PHASE-3-CONTRACT.md` in this pass: onboarding
gating (`core/util/onboarding_rules.dart`) matches the section 3.3 table exactly; the
failure copy table in `core/util/plan_failure_copy.dart` is verbatim; itinerary edit ops
(`core/util/itinerary_ops.dart`), the Maps URL builder (`core/util/maps_url.dart`), and
saved-route upsert (`core/util/saved_routes_ops.dart`) match deviations V3/V4/V9's
descriptions; the Explore search empty-state and selection-clearing behaviour match
section 9 Q6 exactly. Second pass: `TileWarmup`'s body-height formula (screen height minus
`AppSpacing.padFooterY` minus bottom inset) was cross-checked against `BottomNav`'s actual
rendered height — a `SafeArea(top: false)` wrapped around a fixed `AppSpacing.padFooterY`
box — and the two agree, so the shared tile-cache key the comment relies on is not
undermined by a height mismatch; `onboarding_steps.dart`'s option keys and labels match
`terra-nt-bg-map.html`'s render block and the wire keys `docs/PHASE-3-CONTRACT.md`
section 2 fixes; `sheet_snap.dart`/`swipe_snap.dart` constants (190/430/700 anchors,
minus 76 to 0 clamp, minus 38 snap, 4px threshold) match `docs/PRD.md` section 3.8
exactly.)

## Fidelity

(None found in this pass beyond the recorded deviations V1–V18 in `docs/PRD.md` section 7,
which are deliberate and out of scope for a fidelity finding. Screens read against the
prototype — Login, Onboarding, Loading, Explore, Result, Stop detail, Saved Routes,
Profile, Account — all matched their PRD section or a recorded deviation; no unrecorded
divergence in copy, spacing, order or state transition was found in the files read.
Second pass: Welcome's card copy, Create account's fields and copy (section 3.1a, operator
decision D11, no prototype source), the onboarding step-13/14 remote-comfort card copy
(matched against `Terra NT.dc.html` lines 348-365), and the ambient car's every timing
constant all matched their source exactly.)

## Improvements

- Explore: a "near me" style distance sort is out of scope per section 8, but a simple
  "closest to the currently opened itinerary's stops" ordering of the POI list (still no
  location permission needed) would help a driver already mid-route decide which POI to
  detour to.
- Result: the per-stop drive-next text is dropped to "Drive time unavailable" as soon as
  an edit changes a leg (V9) — showing the great-circle distance between the two
  now-adjacent stops (already have lat/lng) as a rough fallback would beat an unlabelled
  blank for a road-trip app whose whole value is pacing.
- Saved Routes: the empty-state copy and the swipe-to-delete both assume routes only ever
  come from generation; a one-line "Duplicate" affordance is out of scope (section 8) but
  a lightweight "share a snapshot" export via the same Google Maps URL builder used on
  Result would reuse existing code and serve the no-signal/road-trip use case (sending the
  plan to a travel companion before losing signal).
- Loading: the five rotating status messages are generic ("Packing the essentials...",
  etc. per the seed); an NT-specific set that mentions the actual seeded stops in flavor
  text would reinforce the product's "ordering and pacing, not a list" pitch during the
  one screen every user watches.
- Stop detail: the AI-note callout is a static block; letting it visually distinguish
  "wet-season closure" or "permit required" notes generated by phase 3 (contract section
  4.1 rules 6 and 7) with a small icon variant would make safety-relevant notes easier to
  spot at a glance in a low-signal, high-stakes context.
- Account: the email-verification row silently shows nothing while
  `authRepository.isEmailVerified()` is pending or fails; a one-line "Checking..."
  placeholder (still no spinner, per PRD) would remove the ambiguity between "not loaded
  yet" and "provider returned nothing" for a user glancing at the screen once.
- Explore: POI markers currently render identically regardless of category; using the six
  tag colour tokens already defined for the marker pin fill (not just the info-card dot)
  would let a driver scanning the map distinguish "Wildlife" stops from "Culture" stops
  before tapping any of them.
- Loading: `TileWarmup` already pre-warms Explore's tile bounds while Welcome sits on
  screen; the mandatory 7 s (phase 1) or open-ended (phase 3) Loading wait is idle screen
  time that could do the same trick for the generated route's own bounds, so Result does
  not open on the same blank-tile risk `TileWarmup`'s own comment describes for Explore.
- Account/Profile: `FirebaseAuthRepository.deleteAccount` and `sendEmailVerification` (see
  Bugs) would be a one-line fix — null-check `_auth.currentUser` into an
  `AuthException(unknown)` instead of using the bang operator — worth doing alongside
  whatever Task-35 already touches in this file for the tracked catch-all issue, since
  both land in the same class.
