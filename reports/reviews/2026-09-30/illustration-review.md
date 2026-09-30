# Terra NT illustration and visual appeal review

30 September 2026 — recommendations only. No app code, design tokens, PRD or task changes. No new artwork was generated.

## Direction

Use a small, coherent family of NT road-trip illustrations to give the planning experience a recognizable identity. Keep the current dark surfaces, violet interface accent and Lucide controls. Build the illustration vocabulary around a winding road, a white 4×4, recognizable landforms, tropical plants and travel objects.

My recommended treatment is simplified, layered landscape illustration with strong silhouettes, restrained texture and a consistent viewpoint. Let the existing destination artwork inform the atmosphere; simplify its detail for small UI scenes. Natural colors inside artwork can remain, while the interface continues to use its existing tokens. This is a design proposal, not a specification change.

## What I inspected

Revisited Explore, the Plan AI empty state, Saved Routes, the first planning question and Welcome interactively on Android emulator `emulator-5554`. Welcome was reached using Back from the first question, without signing out. Used the earlier tour of all 15 questions, route panel and stop detail from the same release. Inspected the actual image files for the car, brand mark, Darwin, Uluru and onboarding backdrop, plus the asset inventory and PRD V22–V29. Login and live loading were not toured this time.

The bundled destination images are generated illustrations. The previous report called them photographs; its terminology has now been corrected.

Three visual issues stand out:

1. **Visibility:** the Plan AI empty state has a small sparkle symbol and text surrounded by a large black area. The onboarding map illustration is dark enough to become background texture. Saved-route artwork is confined to small square thumbnails.
2. **Roles:** destination artwork gives a sense of place. There is little scene-based illustration explaining starting a trip, selecting a region or preparing a route. A logo or a small action icon does not fill the same role.
3. **Unity:** the car is a detailed vehicle cutout, the brand mark is a glowing route-and-pin image, and destinations are textured landscape paintings. These assets have different roles, so they need not be identical, but shared shape, contrast and framing would make them feel more deliberately related. This is an aesthetic judgment, not a measured user outcome.

## Where illustration would help

| Area | Suggested scene and placement | Priority and evidence |
| --- | --- | --- |
| Plan AI before the first route | A folded map opening into a winding road, with the white 4×4 and a small NT landscape. Place it above the existing heading; keep the primary button close to the message. | First. The empty screen was revisited and captured. A distinct scene could establish the app's purpose and personality. |
| Top End / Red Centre selection | Two clearly different landscape scenes: tropical waterfall and greenery; red rock, dry country and sparse vegetation. Pair each with readable region names and short examples. | First. The region question was toured earlier; the two region assets can also become route covers. |
| Onboarding sections | Reuse small compositions for core trip facts, travel style and remote-area comfort. Keep one scene per section or concept rather than adding a new drawing to every answer row. | Second. The repeated question layout and faint backdrop were observed. Relevance matters more than decorating the age-range question. |
| Route preparation | The same map/road composition with restrained continuous movement. It can express that a trip is being prepared without pretending to expose real backend stages or percentage progress. | Second. The current badge/map treatment was inspected in code and PRD; live loading was not toured in this review. |
| Saved Routes | Give route artwork a wider, clearer crop or cover treatment. Use regional identity so Top End and Full NT routes do not both rely on the same tiny Darwin image. An empty Saved state can reuse the folded-map scene. | Second. The populated list was revisited. Cover height must be tested against list scanning and long titles. |
| Welcome / first impression | A single prominent road-trip scene with a clear horizon and title. Use the logo as a brand mark alongside that scene. | First. Welcome was reached and captured: a compact text/action card sits over a very dark map, with little destination imagery visible. Authentication screens remain source-reviewed candidates. |
| Explore and stop detail | Preserve the native map and the existing destination artwork as the main visuals. Improve visibility, crop and map/card connection rather than placing a large illustration over navigation content. | The existing map and destination hero already have useful visual roles. |
| Profile | A restrained identity/avatar treatment can be enough; retain an efficient settings list. | Low priority for illustration. The profile was toured in the earlier review. |

## Minimal first set

Four base drawings are sufficient for an initial visual comparison:

1. **Start a trip:** folded map, road, white vehicle and destination.
2. **Top End:** tropical landscape with a recognizable waterfall/country silhouette.
3. **Red Centre:** red-rock landscape and dry-country vegetation.
4. **Prepare the route:** a composition of map, stops and travel objects using the same shapes.

Reuse these at different crops and scales. Make the intended focal object survive at phone size. Check them against both the near-black canvas and card surfaces, with the main text and action still leading the interaction. Keep functional icons separate from editorial artwork.

## Research and examples

- **A recognizable illustration family:** Google recommends treating imagery, graphics and icons as related elements and using them deliberately throughout a product. This supports a common illustration vocabulary rather than collecting unrelated assets. [Expressing Brand in Material](https://design.google/library/staying-true-to-your-identity-material-branding), read 30 September 2026; publication date not shown.
- **Warmth and approachable content:** Apple's Headspace case study describes illustration style and color as part of a warm, friendly experience. This is a useful example of imagery appearing within the product. The recommended Terra direction uses landscape and travel subjects; Headspace's character style is not the selected art direction. [Behind the Design: Headspace](https://developer.apple.com/news/?id=fkfnhq8u), published 5 June 2023, read 30 September 2026.
- **Contextual scenes:** Atlassian recommends small illustrations for empty states, errors and meaningful milestones, and warns that excessive illustration creates noise. This supports starting with the Plan AI empty state and a few planning concepts. [Illustrations](https://atlassian.design/foundations/illustrations/), read 30 September 2026; publication date not shown.
- **Travel-specific example:** Hopper's own historical design case used its bunny to reinforce buy/wait recommendations. The useful pattern is attaching a recognizable visual to a meaningful state. The 2015 article is historical evidence, not a claim about Hopper's current UI. [Designing Hopper 1.0 for Android](https://medium.com/@hopper_travel/designing-hopper-1-0-for-android-b483b8f94f9b), published 25 September 2015, read 30 September 2026.
- **AI visual continuity:** Google's Gemini illustration case links shapes, motion and brand heritage into a coherent system. Terra can take that continuity principle while keeping its own palette and current restrictions on glows/gradients. [Illustrating the Gemini App](https://design.google/library/gemini-ai-visual-design), read 30 September 2026; publication date not shown.

## Validation before implementation

Compare the current Plan AI empty state with one scene-based composition at the same emulator size. Then compare the two region choices and a populated route list. Evaluate recognizability, visible detail, style consistency, text legibility and how quickly the next action can be found. A better-looking composition remains a design judgment until users compare it; this review makes no claim of measured retention or conversion improvement.

Any accepted visible change subsequently belongs in PRD deviations and a scoped task. This report does not modify those contracts.

## Emulator evidence

- [Plan AI empty state](05-plan-empty.png)
- [Saved-route artwork](06-saved-illustrations.png)
- [Onboarding backdrop and small car](07-onboarding-illustration.png)
- [Welcome over the dark map](08-welcome-illustration.png)
- [Earlier stop-detail capture](03-stop-detail.png)
