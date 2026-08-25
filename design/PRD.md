# PRD: Terra NT Route Planner (target: Flutter)

## Overview
An NT (Northern Territory, Australia) road-trip planning app: user logs in, optionally
runs a 15-question onboarding, gets an AI-generated multi-stop itinerary on a map,
can edit/reorder/skip stops, export to Google Maps, browse POIs on an explore map,
manage saved routes, and manage their profile.

## About the design files
Everything in this bundle is an **HTML/React design reference**, built as a
clickable prototype — not code to port line-by-line. The task is to **recreate this
UI and its behavior natively in Flutter** (widgets, real navigation, real state
management), using Flutter/Dart idioms rather than translating HTML/CSS/JS.

The maps in the prototype are Leaflet running inside iframes (`terra-nt-bg-map.html`,
`terra-nt-explore-map.html`, `terra-nt-map.html`). Flutter has no iframe/DOM — reimplement
these with a native map layer (`flutter_map` with the same dark CARTO-style tiles, or
`google_maps_flutter` with a custom dark map style) and native marker widgets/animations
instead of postMessage + divIcon HTML.

## Fidelity
**High-fidelity.** Colors, type, spacing, radii and copy below are final — the design
system tokens are real values (not placeholders). Recreate pixel-accurate spacing/type;
do not restyle.

## Design tokens (Terra NT Design System)

Authoritative source: `design-system/tokens/*.css` (added 2026-08-25). The values below
are that bundle, restated for the app. Read `design-system/README.md` before using it —
upstream it documents a *marketing website* for a different product, so only `tokens/`
transfers; its component inventory and desktop breakpoints do not.

**Colors**
- Canvas (app background): `#010102`
- Surface ladder (cards → hover/featured → menus → deepest): `#0f1011`, `#141516`, `#18191a`, `#191a1b`
- Ink (headline/body → subtle → tertiary → faintest): `#f7f8f8`, `#d0d6e0`, `#8a8f98`, `#62666d`
- Primary (brand/CTA/focus/links only — never a fill/background): `#5e6ad2`; hover `#828fff`; press/focus `#5e69d1`
- Success: `#27a644`
- Hairlines: `#23252a` (default), `#34343a` (strong/featured/focused), `#3e3e44` (nested)
- Tag colors used functionally in this app (priority/category dots, destructive actions): blue `#5e6ad2`, purple `#8b5cf0`, green `#27a644`, yellow `#d4a72c`, orange `#d97b34`, red `#d1484a`. **Provisional** — derived from the accent hue family, not sampled from the real product (`design-system/tokens/colors.css`). Usable values, not confirmed ones; define them as named tokens so a later correction is a one-line change.
- No light mode.

**Typography** — 3 font roles: display (500–600 weight, headlines), text (400–500, body/UI), mono (400, codes/times). Aggressive negative letter-spacing on display sizes (down to −3px at 80px, easing to −0.05px at 16px and 0 at 14px and below). The eyebrow role inverts this with +0.4px — the one positive-tracked role. Sentence case everywhere, no ALL CAPS, no title case.
- **Families.** The real Terra NT cuts are proprietary and were never supplied. The system substitutes **Inter** (400/500/600/700) for display *and* text, and **JetBrains Mono** (400/500) for mono (`design-system/tokens/fonts.css`). In Flutter: either the `google_fonts` package or bundled font files in `pubspec.yaml` — **decide before T-00 lands**, since goldens are font-rendering-sensitive and switching later invalidates every checked-in golden.
- The desktop display sizes (80/56/40px) belong to the marketing site. This app's largest type is 44px (Login headline) — inherit the family/weight/tracking ramp, not the sizes.

**Spacing** — 4px base scale: 4·8·12·16·24·32·48, 96 for large section gaps. Card padding 24px (this app uses 14–16px for compact mobile list rows — intentional deviation for mobile density). Buttons 8×14px padding, inputs 8×12px, pill badges 6×14px.

**Radius** — 4px chips/badges, 8px buttons/inputs, 12px cards, 16px screenshot/map panels, pill for status badges and toggles.

**Elevation** — surface steps + 1px hairlines only. No drop shadows except `shadow-overlay` = `0 8px 32px rgba(0,0,0,0.6)` on floating things (sheets, menus) and a 1px top edge highlight `inset 0 1px 0 rgba(255,255,255,0.06)` on lifted panels. Focus ring = 2px `#5e69d1` at 50% opacity. Modal scrim ≈ `rgba(1,1,2,0.72)`. No glows, no colored shadows, no `backdrop-filter`.

**Motion** — 80ms instant, 120ms hover crossfades, 160ms default, 240ms overlays; `cubic-bezier(0,0,0.2,1)` (ease-out) and `cubic-bezier(0.4,0,0.2,1)` (standard). No bounce/spring/scale-in/parallax. These are the design system's *house defaults* — the source brand doc documented no animation at all — so this app's own prototype timings (380ms onboarding auto-advance, 320ms step-card slide, 1.6s loading pulse, 1.4s message rotation) take precedence where they conflict.

## Screens

### 1. Login
Full-bleed dark map background (ambient, looping car animation — decorative), gradient overlay bottom-to-top. Headline "Terra NT" (display, 44px), subhead "Discover the Northern Territory." Email + password inputs, primary "Start Exploring" button, divider "or", secondary "Continue with Google" button.

**Acceptance criteria**
- Full-bleed map background renders behind the bottom-to-top gradient overlay; no bottom nav on this screen.
- Copy matches character-for-character: headline "Terra NT", subhead "Discover the Northern Territory.", buttons "Start Exploring" and "Continue with Google", divider "or".
- Both "Start Exploring" and "Continue with Google" navigate to Welcome. The prototype performs no credential check — no validation, no error state, no disabled state.
- The email typed into the field is the address later shown on Profile; when it is empty, Profile falls back to `explorer@example.com`.
- The ambient car animation loops continuously and visibly passes through every intermediate demo-route point (arc-length sampling, not raw lat/lng lerp). The sampling function has its own unit test: fraction 0 → first point, 1 → last point, 0.5 → a point on the correct segment.
- The animation controller is disposed when the route is popped — no ticker-leak assertion in tests.
- Golden test for this screen matches `screenshots/01-login.png`.
- `dart analyze` clean; no layout exceptions (no overflow stripes, no unbounded-constraint errors) at phone widths.
- TBD — needs decision: does the Flutter build validate email/password (format check, CTA disabled until valid, inline error copy), or keep the prototype's no-validation pass-through?
- TBD — needs decision: is "Continue with Google" a real Google Sign-In integration, or a mock that behaves identically to "Start Exploring"?

**Non-goals**
- No sign-up, forgot-password, or password-reset flow — none exists in the prototype.
- No real backend, token, or session persistence; auth is mocked in memory.
- The background map is decorative only: not pannable, zoomable, or tappable (the prototype disables `dragging`, `touchZoom`, `scrollWheelZoom`, `doubleClickZoom`, `boxZoom`, `keyboard`, `tap`).

### 2. Welcome
Same map background, dimmer overlay. Card with headline "Welcome to Terra NT" and body copy. Two full-width buttons: primary "Create My Route", secondary "Skip for Now".

**Acceptance criteria**
- Same map background as Login with a dimmer overlay; the card uses surface-1 and the 12px card radius.
- Copy matches character-for-character: headline "Welcome to Terra NT", buttons "Create My Route" and "Skip for Now"; both full-width.
- "Create My Route" navigates to Onboarding at step 1 of 15.
- "Skip for Now" marks onboarding as done and lands on Explore — it does not run the generator and does not create a saved route.
- After "Skip for Now", the Plan AI tab opens the Result screen (because onboarding is flagged done), not Login. Covered by a navigation test.
- Golden test for this screen matches `screenshots/02-welcome.png`.
- `dart analyze` clean; no layout exceptions.

**Non-goals**
- No bottom nav on this screen.
- No "don't show this again" preference — Welcome is a step in the linear post-login flow, not a dismissible dialog.

### 3. Onboarding (15 steps)
Map background showing a car animating progressively along a fixed demo route as steps advance (fraction = step/14). Top bar: back button, pill progress bar, "n/15" counter. Step card slides in (translateX 18px→0, 320ms). Step types used:
- Single-select list (radio-style rows with checkmark), auto-advances 380ms after pick: age range, who you're traveling with, transport, budget, accommodation, activity level, region, 4x4 confidence, camping-vs-resort, wildlife interest.
- Multi-select list (toggle rows), manual "Next" button, disabled until ≥1 picked: trip focus.
- Slider with big number readout: trip length (1–14 days), heat tolerance (1–5, with a text label per notch).
- Two-card choice (detail level: highlights vs. hourly plan) — auto-advances.
- Final yes/no question (remote/off-grid comfort) — manual "Generate My Route" button (disabled until answered).
Last two steps carry an "NT-specific" pill badge above the question.
On completion → auto-saves the generated route into Saved Routes, then Loading.

**Acceptance criteria**
- Exactly 15 steps, indices 0–14, in this order: age range, trip length slider, who you're traveling with, trip focus (multi-select), transport, budget, accommodation, activity level, region, detail level (two-card), 4x4 confidence, heat tolerance slider, camping-vs-resort, wildlife interest, remote/off-grid comfort.
- Counter reads "n/15" with n = step index + 1; the pill progress bar fills to `round(((step + 1) / 15) * 100)`%.
- The backdrop car sits at fraction `step / 14` of the demo route and travels along the polyline through intermediate points as steps advance — never a straight-line cut between endpoints.
- Single-select steps auto-advance exactly 380 ms after a pick; a second pick inside that window cancels and restarts the pending advance instead of double-advancing. Unit-tested with a fake timer.
- The multi-select step (trip focus) never auto-advances; "Next" is disabled until ≥1 option is selected and re-disables when all are deselected.
- Both slider steps (trip length 1–14, heat tolerance 1–5) leave "Next" enabled at all times; defaults are days = 7 and heat = 3, and the heat notch label matches the 5 seeded strings verbatim.
- The two-card detail-level step auto-advances on either card, and the picked card carries the selected chip styling.
- The final step (remote comfort) labels its button "Generate My Route" instead of "Next", disabled until yes or no is answered.
- The "NT-specific" pill badge appears above the question on the last two steps only (wildlife interest, remote comfort).
- Back from step 0 navigates to Login (matching the prototype's `onBack`); back on any other step decrements the step and cancels any pending auto-advance.
- Completing the final step navigates to Loading; the route is auto-saved during Loading (see screen 4), not when the button is pressed.
- The step guard is a pure function with a unit test: `canNext(step, answers)` returns false for each of the 12 gated steps until its answer is set, and true for the ungated slider steps.
- Golden test for this screen matches `screenshots/03-onboarding.png`.
- `dart analyze` clean; no layout exceptions on the tallest step card.
- TBD — needs decision: back from step 0 lands on Login, skipping Welcome. Intended, or should it return to Welcome?
- TBD — needs decision: the prototype preserves answers when the user goes back and forward again. Confirm that is wanted (vs. clearing the answer on back).

**Non-goals**
- No answer persistence across app launches; answers live in memory for the session.
- No step skipping or jumping — navigation is strictly linear, one step at a time.
- No validation beyond "an answer exists"; no cross-question consistency checks.

### 4. Loading
Centered pulsing circle (scale 1→1.4, opacity 0.9→0.3, 1.6s loop), rotating status text every 1.4s ("Analyzing NT preferences...", "Consulting outback AI...", etc.), ~7.0s total (all 5 messages get one full 1.4s turn) before landing on Result. **Deviates from the HTML prototype**, which cuts the loop short at 5.6s and never shows the 5th message ("Routing...") — corrected here.

**Acceptance criteria**
- Centered circle pulses scale 1 → 1.4 and opacity 0.9 → 0.3 on a 1.6 s loop.
- Status text rotates every 1400 ms through the 5 seeded messages in order, starting at index 0: "Analyzing NT preferences...", "Consulting outback AI...", "Mapping stops across the Territory...", "Calculating drive times...", "Routing...".
- After 7000 ms (5 messages × 1400 ms) the screen auto-navigates to Result and flags onboarding as done — no user action required, no way to cancel.
- On that same transition the generated route is upserted into Saved Routes under the stable id `generated-trip`: title "Full NT: Darwin to Uluru", meta "`<days>` days · 7 stops", date label "Generated just now". Re-running onboarding updates that one entry rather than adding a second. Unit-tested on the upsert function.
- A new entry is inserted at the top of the list; an existing entry is updated in place at its current position.
- All timers are cancelled on dispose — leaving early (e.g. a back gesture) must not fire the navigation or the upsert afterwards. Covered by a widget test.
- Golden test for this screen matches `screenshots/04-loading.png`.
- `dart analyze` clean; no layout exceptions.
- **Resolved:** the prototype's 5.6 s loop is a bug — it clears the message interval one tick before "Routing..." would show. Fixed here to 7.0 s so all 5 messages get an equal turn. The delay stays hard-coded (no real generator future) — no backend to await.

**Non-goals**
- No bottom nav, no back button, no cancel — this is a non-interruptible transition.
- No real AI or API call; the itinerary is always the 7 seeded stops regardless of the answers.
- No progress percentage or ETA — only the rotating status line.

### 5. Explore
Full-bleed interactive map. Floating search bar pill at top ("Search the Territory"). Tapping a POI marker opens a bottom card: thumbnail placeholder, name, rating, category tag with colored dot, description, close (X) button.

**Acceptance criteria**
- Full-bleed interactive map (pan + zoom enabled, unlike the Login backdrop) showing the 8 seeded POI markers at their seeded lat/lngs, with OpenStreetMap/CARTO attribution visible.
- Floating search pill sits 20px from top/left/right: pill radius, surface-1, hairline border, overlay shadow, 16px `Search` icon, tertiary-ink placeholder "Search the Territory".
- Tapping a POI marker opens the bottom info card for that POI; tapping another marker swaps its content; tapping the X closes it and clears the selection.
- The card renders the seeded name, rating, description, and a category tag whose dot color comes from the tag map (Nature → green, Culture → purple, Adventure → orange, Wildlife → blue, Relaxation → yellow).
- The thumbnail is the placeholder icon-in-box tile: 76px square, surface-2, hairline border, `Image` icon.
- Bottom nav visible with Explore active (full ink) and the other three tabs tertiary ink.
- The tag→color mapping is a pure function with a unit test, including the fallback to tertiary ink for an unknown tag.
- Golden test matches `screenshots/05-explore.png` in both the no-selection and card-open states.
- `dart analyze` clean; no layout exceptions with the info card open.
- TBD — needs decision: the search pill is a non-interactive label in the prototype. Does Flutter make it functional (tap → search across the 8 seeded POIs), or keep it a static affordance?
- TBD — needs decision: the prototype marks POI photos "loads from Google Places API in production". Placeholder tiles only for this build, or a real image source?

**Non-goals**
- No POI detail screen — the bottom card is the full extent of POI detail, and it does not link to Stop detail.
- No "add this POI to my route" action; Explore is read-only browsing.
- No user location, geolocation permission, or "near me" behavior.
- No POI filtering by category.

### 6. Plan AI result (itinerary)
Top 340px: route map with numbered pins and dashed connecting line. Below: draggable bottom sheet (peek 190 / default 430 / expanded 700px, snaps to nearest on release) containing:
- Trip title + meta (days · stops)
- Segmented control: Highlights / Detailed
- "Edit Route" toggle button (icon+label flips to "Done"/Check when active)
- Primary "Export to Google Maps" button (builds a real Google Maps directions URL from ordered stop lat/lngs)
- "Restore N removed stops" link, shown only when stops have been removed
- Scrollable stop list: each row has numbered badge, name, subtitle, category tag chips (colored dot + label), and either a chevron (view mode, tap opens Stop Detail) or drag-handle + revert/remove icon buttons (edit mode, drag-and-drop reorder). Highlights mode shows one AI-note line per stop; Detailed mode shows an hour-by-hour mini-schedule. Footer row per card: duration, drive time to next stop.

**Acceptance criteria**
- Top 340px is the route map: numbered pins in the current stop order, connected by a dashed polyline; pan and zoom enabled.
- The sheet clamps to 190–700px while dragging and on release snaps to the nearest of exactly 190 / 430 / 700px (ties resolve to the lower value, matching the prototype's first-wins scan). Unit-tested on a pure `nearestSnap(height)` function.
- Trip title "Full NT: Darwin to Uluru" is a fixed string (there is only one generated itinerary). Meta is **derived, not hard-coded**: "`<current stop count>` stops · `<answers.days>` days" — it reflects the live order (drops after a remove, matching what the saved-route entry's meta shows) and the onboarding `days` answer. **Resolved** — the prototype hard-codes "7 stops · 8 days" even after a stop is removed; this fixes that divergence from the Saved Routes entry, which already derives its meta correctly.
- The segmented control switches Highlights (one AI-note line per stop) and Detailed (that stop's hour-by-hour mini-schedule); it shares one state value with the onboarding detail-level answer rather than duplicating it.
- "Edit Route" toggles to "Done", the icon flips `Pencil` → `Check`, and the selected chip styling applies while active.
- View mode: each stop row shows a chevron and opens Stop detail on tap. Edit mode: rows show a drag handle plus revert and remove icon buttons, and tapping a row does not navigate.
- Drag-and-drop reorder is available only in edit mode; reordering renumbers the badges 1..N by position while each row keeps its own duration and drive-time copy.
- **Resolved** (the two icons/link below were both wired to a single "reset everything" action in the prototype, which didn't match either one's label — split into scoped actions):
  - The per-row **revert icon** undoes reordering for that one stop only — moves it back to its own original index — and never touches removed stops. It is a no-op (or hidden) when that stop is already at its original position.
  - The **"Restore N removed stop(s)"** link re-inserts every removed stop back at its original index, while preserving any manual reordering of the stops that were never removed. It does not touch per-stop reorder-revert state.
- Removing a stop drops it from the order and reveals "Restore N removed stop"/"stops" (singular at N = 1); the link is hidden when nothing is removed. Pluralisation is unit-tested.
- Skipped stops (toggled from Stop detail) render at 0.5 opacity and stay in the list — skipping is not removing, and the two states are independent.
- "Export to Google Maps" builds `https://www.google.com/maps/dir/?api=1&origin=<lat,lng>&destination=<lat,lng>&travelmode=driving`, appending `&waypoints=` joined by `|` for intermediate stops, all URL-encoded, in the current order; it no-ops with fewer than 2 stops. Unit-tested on the pure URL builder, including the 2-stop (no waypoints) case.
- Bottom nav visible with Plan AI active.
- Golden test matches `screenshots/06-plan-ai-result.png` at the 430px default sheet height, in both Highlights and Detailed modes.
- `dart analyze` clean; no layout exceptions at all three sheet heights.
- TBD — needs decision: are skipped stops excluded from the exported Google Maps URL? The prototype includes them.
- TBD — needs decision: is map fly-to-pin on stop-row selection in scope? `PRD.md` describes it as optional.

**Non-goals**
- No regenerate / re-run-AI action on this screen.
- No adding a new stop — only reorder, remove, restore, and skip.
- No per-stop editing of times, durations, or drive labels; those are seeded copy.
- No route export beyond the Google Maps URL launch (no PDF, no calendar, no share sheet).

### 7. Stop detail
Full-bleed image placeholder header (260px) with back button overlay. Name, subtitle, tag chips, info card (hours, park fee if any), AI-note callout. Footer: "Skip"/"Unskip" secondary button + "Navigate" primary button.

**Acceptance criteria**
- 260px full-bleed placeholder image header (icon-in-box treatment) with the back button overlaid; back returns to Result.
- Name, subtitle, tag chips, hours, and AI note render verbatim from the seeded stop; the park-fee row appears only when the stop has a fee and is omitted entirely when it is null.
- The footer secondary button reads "Skip" when the stop is not skipped and "Unskip" when it is.
- Tapping Skip/Unskip toggles the skipped flag and immediately returns to Result, where that stop now renders at 0.5 opacity (or full opacity again after Unskip). Covered by a widget test.
- Skipped state survives leaving and re-entering the screen.
- No bottom nav on this screen (it sits on top of the Plan AI tab's stack).
- Golden test matches `screenshots/07-stop-detail.png` in both the fee-present and fee-absent variants.
- `dart analyze` clean; no layout exceptions with the longest seeded hours/AI-note strings (Darwin's Mindil Beach line is the longest).
- TBD — needs decision: the "Navigate" primary button has no handler in the prototype. Does it launch a single-destination Google Maps URL for this stop, or stay inert?

**Non-goals**
- No photo gallery or carousel — a single placeholder hero.
- No editing of stop content (hours, fees, notes) from this screen.
- No "remove stop" here; removal lives only in the Result screen's edit mode.

### 8. Saved Routes
List of saved route cards (thumbnail, title, meta, relative date, chevron). **Swipe left reveals a red delete button** pinned behind the row (fixed 76px reveal, snaps open past ~half, tap elsewhere on an open row closes it, tap the red button deletes). Empty state: icon, "No saved routes yet", body copy, "Plan Your First Route" button.

**Acceptance criteria**
- Populated state lists route cards with placeholder thumbnail, title, meta, relative date label, and chevron; the two seeded routes are "Full NT: Darwin to Uluru" / "8 days · 7 stops" / "Generated today" and "7 Days in the Red Centre" / "7 days · 4 stops" / "Generated 3 days ago".
- Swipe left reveals exactly 76px of red delete button behind the row; the drag is clamped to −76..0px and does not track right-swipes past 0.
- On release the row snaps open past the −38px midpoint and snaps closed at or before it. Both thresholds are unit-tested on the pure snap function.
- Only one row is open at a time — opening a second row closes the first.
- Tapping an open row closes it instead of navigating; a tap that followed a drag of more than 4px does not navigate either.
- Tapping a closed row opens the Result screen.
- Tapping the red button deletes that route and resets the swipe state; deletion is immediate, with no confirmation step.
- Deleting every route reveals the empty state: icon, "No saved routes yet", body copy, and a "Plan Your First Route" button that switches to the Plan AI tab.
- Auto-saved routes from onboarding appear at the top under the id `generated-trip`, and re-running onboarding updates that entry instead of adding another.
- Bottom nav visible with Saved Routes active.
- Golden tests match `screenshots/08-saved-routes.png` in both the populated and empty states.
- `dart analyze` clean; no layout exceptions with a row swiped open.
- TBD — needs decision: persistence — in-memory only, or `shared_preferences`/local storage across launches? (Already flagged in `CLAUDE.md` → Open decisions; blocks the data layer.)
- TBD — needs decision: every saved route opens the same seeded itinerary in the prototype. What should "7 Days in the Red Centre" open — the same 7 stops, its own seeded 4-stop itinerary, or nothing?

**Non-goals**
- No rename, duplicate, or share action on a saved route.
- No undo or snackbar after delete.
- No sorting, filtering, or search over saved routes.
- No cross-device sync.

### 9. Profile
Account row (avatar circle, name, email, chevron). Offline Maps toggle row. Language row (chevron, shows "English"). "Log Out" row (red icon+label). Below a spacer, a **small, muted, de-emphasized "Delete account" text link** (no card, no icon, tertiary-ink caption text — deliberately low-prominence). Tapping it swaps in an inline confirm card ("Delete your account and all saved routes? This can't be undone." + Cancel / Delete account buttons) instead of navigating away.

**Acceptance criteria**
- Account row shows the avatar circle, "NT Explorer", the session email (falling back to `explorer@example.com`), and a chevron; it is inert on tap in the prototype.
- Offline Maps row toggles a pill switch: off = surface-2 track, hairline border, tertiary-ink thumb, thumb left; on = surface-3 track, strong hairline, ink thumb, thumb right. The value is session state only and triggers no download.
- Language row shows the `Globe` icon, label "Language", value "English", and a chevron; display-only, no tap target.
- "Log Out" renders icon and label in tag-red, returns to Login, and clears email and password. Saved routes and the onboarding-done flag are NOT cleared. Covered by a widget test.
- "Delete account" is a centered, tertiary-ink 12px caption text link — no card, no icon — separated from the rows by a flexible spacer.
- Tapping it swaps that link in place for an inline confirm card reading "Delete your account and all saved routes? This can't be undone." with Cancel and Delete account buttons; it must not navigate away or open a dialog/sheet.
- Cancel returns to the idle link. Confirm returns to Login and clears email, password, and the onboarding-done flag. **Resolved:** confirm also clears saved routes to an **empty list**, not the two seeded entries — the prototype sets `savedRoutes: null`, which falls back to the seed data and effectively un-deletes the two demo routes on "account deletion". Unit-tested on the state transition, including that a subsequent fresh login sees zero saved routes rather than the seeded pair.
- Bottom nav visible with Profile active.
- Golden tests match `screenshots/09-profile.png` in the idle and confirming states.
- `dart analyze` clean; no layout exceptions.
- TBD — needs decision: the account row and language row are inert in the prototype. Inert in Flutter too, or do they need destinations?

**Non-goals**
- No profile editing (name, email, avatar upload).
- No language switching or i18n — the Language row is display-only (`CLAUDE.md` explicitly excludes `flutter-setup-localization`).
- No real offline map download, cache management, or storage-size display.
- No notification, privacy, or theme settings — there is no light mode.

### Bottom nav (all main screens)
4 tabs: Explore (Compass), Plan AI (Sparkles), Saved Routes (Bookmark), Profile (User). Active tab = full ink color, inactive = tertiary ink.

**Acceptance criteria**
- Present on Explore, Plan AI result, Saved Routes, and Profile only. Absent on Login, Welcome, Onboarding, Loading, and Stop detail.
- 64px tall, surface-1, 1px hairline top border, four equal-width tabs; each tab is a 20px icon over an 11px caption label with a 4px gap.
- Labels and icons match exactly: Explore/`Compass`, Plan AI/`Sparkles`, Saved Routes/`Bookmark`, Profile/`User`.
- Active tab renders icon and label in full ink; the other three in tertiary ink.
- Stop detail keeps Plan AI as the conceptually active tab but hides the bar, since it is pushed on top of that tab's stack.
- The Plan AI tab opens Result when onboarding is done and Login when it is not. Covered by a navigation test for both cases.
- Each tab keeps its own navigation stack across switches (`StatefulShellRoute`) — e.g. Stop detail is still on top of the Plan AI stack after visiting Profile and coming back.
- Golden test for the bar in each of the four active states.
- `dart analyze` clean; no layout exceptions at the narrowest supported width with the longest label ("Saved Routes").

**Non-goals**
- No badges, counts, or dot indicators on tabs.
- No tab reordering or hiding.
- No swipe-between-tabs gesture — tabs change by tap only.

## Interactions & behavior detail
- **Swipe-to-delete**: horizontal drag tracked from pointer-down, clamped -76..0px, snaps open/closed at the -38px midpoint on release; only one row open at a time. In Flutter: `Slidable` (flutter_slidable) `endActionPane` with a `DrawerMotion` and a single red `SlidableAction`.
- **Auto-save on generate**: completing onboarding upserts a route entry (by stable id, so regenerating updates rather than duplicates) into the top of Saved Routes.
- **Bottom sheet drag**: pointer-drag on a grabber handle resizes sheet height, snaps to 3 heights on release. In Flutter: `DraggableScrollableSheet` with `snapSizes`.
- **Reorder itinerary**: only draggable in Edit mode; drag-and-drop reorder + per-stop remove/revert-to-original-position (scoped to that one stop — see screen 6 → Acceptance criteria for how this differs from the list-wide "Restore N removed stops" link). In Flutter: `ReorderableListView`.
- **Car-follows-route animation** (onboarding backdrop + login ambient loop): the car must travel **along the polyline through every intermediate stop**, not cut a straight line from A to B. Implementation: parameterize the route by cumulative arc length, drive a single `0..1` progress value with an `AnimationController`, and on each tick sample the lat/lng at that progress by walking the cumulative-distance table — never lerp raw lat/lng between two arbitrary points.
- **POI selection** (Explore): tapping a marker opens/closes a bottom info card; native marker `onTap`, no postMessage needed in Flutter.
- **Map "focus" flyTo** (Result screen numbered pins): selecting a stop row could optionally fly the map camera to that pin (`AnimatedMapController.animateTo` in flutter_map, or `GoogleMapController.animateCamera`).

## State needed
- Auth/session (email — mocked, no real backend in the prototype)
- Onboarding answers: age range, days (1–14), travel-with, focus (multi), transport, budget, accommodation, activity level, region, detail-level (bool), 4x4 confidence, heat tolerance (1–5), camping-vs-resort, wildlife interest, remote comfort
- Generated itinerary: ordered stop list, skipped-stop set, edit mode flag
- Saved routes list (id, title, meta, date)
- Explore: selected POI id
- Profile: offline-maps toggle, language, delete-account confirm step

## Data model (stops)
Each stop: `name, subtitle, lat, lng, hours, fee (nullable), driveNextLabel (nullable for the last stop), durationLabel, aiNote, tags: string[], detailedPlan: {time, activity}[]`. 7 stops seeded (Darwin → Litchfield → Kakadu → Nitmiluk/Katherine → Alice Springs → Kings Canyon → Uluru-Kata Tjuta) — see `Terra NT.dc.html` for full seed copy/times/fees to carry over verbatim.

## Assets
No real photography/icons supplied — the prototype uses placeholder icon-in-box tiles wherever a photo would go (POI cards, stop detail hero, saved-route thumbnails) and Lucide icons throughout (`ArrowLeft`, `ArrowRight`, `Search`, `X`, `Image`, `Star`, `Zap`, `ChevronRight`, `GripVertical`, `RotateCcw`, `Trash2`, `Bookmark`, `Map`, `User`, `Download`, `Globe`, `LogOut`, `Compass`, `Sparkles`, `CircleCheck`, `Check`, `Pencil`, `ExternalLink`). Use `lucide_icons`/`flutter_lucide` or Material equivalents at the same outline-only, currentColor, no-fill treatment.

## Files in this bundle
- `CLAUDE.md` — project instructions for Claude Code (stack conventions, working style).
- `design-reference/Terra NT.dc.html` — the full app prototype (all 9 screens + nav + logic), source of truth for copy, structure and state transitions.
- `design-reference/terra-nt-bg-map.html` — ambient/onboarding-progress map with the car-following-route animation logic (reference the `pointAtFraction`/cumulative-distance approach directly).
- `design-reference/terra-nt-explore-map.html` — POI marker map.
- `design-reference/terra-nt-map.html` — result-screen numbered-pin map with `flyTo`.
- `screenshots/` — one PNG per screen (login, welcome, onboarding, loading, explore, plan-ai-result, stop-detail, saved-routes, profile).
