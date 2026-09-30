# Terra NT mobile design review

Date: 30 September 2026. Report only; no implementation or specification changes.

## Evidence and scope

Installed the existing release APK built at 12:34 on 30 September on the `terra_nt` Android emulator, serial `emulator-5554`. Display: 1080 × 2400 physical pixels at 420 dpi, approximately 411 × 914 logical pixels. The physical phone was not used.

Inspected Explore and a selected place card, the Plan AI empty state, Saved Routes, a seeded route in Highlights and Detailed modes, the expanded route panel, Darwin stop detail, Profile, Account, and all 15 planning questions including the endpoint dropdown. Navigation, selection and panel motion were observed interactively. No new itinerary was generated or saved. Login, Language, live AI loading/failure, large text, landscape and TalkBack were not toured. This is an expert review, not a user study or a frame-rate benchmark.

## Recommendation

Keep the existing dark palette, violet accent, native map and destination illustrations. Prioritize legibility and map clarity, simplify the planning form, then make motion connect related elements. The main visual weaknesses observed are weak secondary information, repetitive nested outlines, and inconsistent emphasis between numeric and textual answers. Correction after inspecting the image assets and PRD V22: the bundled destination images are generated illustrations, not photographs.

| Priority | Area and observed evidence | Suggested change |
| --- | --- | --- |
| 1 | Enabled, unselected bottom tabs use 11px `captionApp` and `inkTertiary` against `surface1`. The token contrast is approximately 3.30:1. Saved-route dates use the same combination. | Use the existing brighter `inkSubtle` for actionable or useful secondary text; it gives approximately 5.86:1 against that surface. Keep disabled styling for controls that really cannot be used. Review small metadata alongside the tab labels. |
| 1 | Explore initially shows a very dark map with unlabeled colored circles. Several circles overlap near Darwin and the Red Centre. Selecting a circle exposes its name in a bottom card. | Preserve the dark map, but make key place names easier to read. Group overlapping places at broad zoom and expose their names on selection or closer zoom. Add compact category labels if color remains a navigation cue. Tile-label changes require a map-style decision; do not silently replace CARTO. |
| 1 | Profile says “Offline Maps — Download maps for areas with no signal”. PRD §3.9 explicitly says the toggle downloads nothing; the notifier only changes session state. | Remove the download promise and disable or omit the control until it performs the promised action. This is a product-copy/specification decision, not an instruction to build offline downloads. |
| 2 | The full 15-question tour repeatedly presents an outer outlined card, outlined option rows and a Next button. Days, region and endpoints are separated, with endpoints last. | Start with the core trip facts: endpoints, days and region. Group the remaining questions into clearly named sections such as travel style and comfort. Reduce competing outlines so the question and selected answer have stronger emphasis. Keep all backend fields until any flow redesign is specified. |
| 2 | “Standard Car” was selected at question 5, but question 10 still asks about confidence driving a 4×4 off-road. Questions 7 and 12 both concern accommodation/camping preference. | Make off-road questions conditional on relevant vehicle/use choices. Investigate whether the two accommodation questions provide distinct useful signals before merging them. Do not remove fields on visual preference alone; validate the generated route quality. |
| 2 | At question 11, “It’s fine either way” uses the same large readout treatment as “7 days”, wrapping into two dominant lines. | Keep the large readout for short quantities. Use a smaller text role for a sentence answer, or present the heat levels as clearly labeled choices. The question should remain visually dominant. |
| 2 | “Top End”, “Red Centre”, “Budget”, and “High” are short labels without much explanation. The heat and connectivity questions have longer explanatory answers. | Add brief examples where interpretation changes a choice: “Top End — Darwin, Kakadu…” and “Red Centre — Alice Springs, Uluru…”. Define budget/activity labels consistently, using actual supported meaning rather than invented dollar thresholds. |
| 2 | The route panel’s initial state shows a toolbar, export action, destination image and only part of the first stop. A large drag exposes much more of the list and leaves a narrow map strip. | Make the visible summary more useful at the middle height: route title, readable duration/stops and a compact first stop. Reserve full imagery and schedules for the expanded state. Keep the three established panel anchors unless a new interaction is deliberately specified. |
| 3 | Darwin detail has a strong destination illustration, but schedule times, descriptions, tags and an hours card form a dense text stack. | Give times a consistent readable column and group events into clear rows. Format hours as a short label/value block. Preserve the illustration and existing Skip/Navigate actions. |
| 3 | Saved Routes occupies the upper part of the screen; long generated titles wrap, while dates and route metadata are much smaller. | Use a consistent title/summary hierarchy and slightly larger, consistent thumbnails. Let empty space remain when there are only a few routes; adding filler is unnecessary. A New route entry could improve navigation, but would be a separate product-flow decision. |
| 3 | Selection, tab and question transitions are present. The repeated form layout has a stronger visual effect than the amount of animation. | Extend motion at meaningful connections: selected map pin to place card, destination image to stop detail, panel movement and skip/restore feedback. Keep the primary action available promptly and avoid making frequent navigation replay a long entrance sequence. Verify reduced motion and timing on a real device separately. |

## Research grounding

- **Legibility:** Android recommends at least 4.5:1 for smaller normal text and touch targets of at least 48dp. W3C independently specifies the 4.5:1 normal-text threshold. The measurements above use the source tokens, not antialiased screenshot pixels. The unselected tabs remain enabled; the disabled-control exemption therefore does not apply to them. Sources: [Android accessibility](https://developer.android.com/guide/topics/ui/accessibility/apps), updated 22 September 2026, read 30 September 2026; [W3C contrast minimum](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html), read 30 September 2026. The existing map wrapper already enlarges marker hit areas to 48 logical pixels; small painted circles alone do not demonstrate small touch targets.
- **Travel-app structure:** Wanderlog describes presenting itinerary and map together. Roadtrippers documents switching between the map and trip planner and starting a trip from a chosen destination. These are useful patterns for keeping location context connected to planning; they are not proof that either competitor converts better. Sources: [Wanderlog](https://wanderlog.com/), read 30 September 2026; [Roadtrippers mobile planning](https://support.roadtrippers.com/hc/en-us/articles/202594209-Planning-a-Trip-in-Our-Mobile-App), dated 23 September 2026, read 30 September 2026.
- **Forms:** NN/G distinguishes optional secondary controls from a mandatory sequence and warns that excessive steps can create navigation overhead. This supports investigating grouped/conditional questions; it does not establish a magic optimal question count. Source: [Progressive disclosure](https://www.nngroup.com/articles/progressive-disclosure/), published 3 December 2006, read 30 September 2026.
- **Motion:** NN/G recommends brief, subtle motion for feedback, state changes and navigation relationships. Apple's indexed motion guidance similarly favors feedback that follows gestures and expectations. Source: [NN/G motion](https://www.nngroup.com/articles/animation-purpose-ux/), published 12 January 2020, read 30 September 2026; [Apple motion](https://developer.apple.com/design/human-interface-guidelines/motion?changes=l_9_3), indexed excerpt checked 30 September 2026; the full Apple page was not readable through the text browser.

## What would validate the recommendations

First compare two readable variants of Explore and the route panel. Ask a new user to identify a destination, understand the route and open a stop. Record hesitation and mistaken taps. For the form, compare completion time, backtracking and route relevance with the present 15-step version. No conversion loss, completion-rate improvement or satisfaction increase has been measured in this review.

These findings belong in a review report now. Any accepted flow, copy or map-style change should subsequently be recorded in the PRD/deviations and a scoped task before implementation.

## Emulator captures

- [Explore](01-explore.png)
- [Initial route panel](02-result.png)
- [Darwin stop detail](03-stop-detail.png)
- [Heat question](04-heat-question.png)
