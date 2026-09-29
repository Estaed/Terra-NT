# RAG data brief — for the teammates' AI

Terra NT's planning server (`tools/plan_server/`, run by Tarık) asks a language model for a
Northern Territory itinerary. Before it asks, it pastes place documents into the prompt so
the model states real hours, fees, permits and closures instead of guessing, and so the
server can put each stop on the map. **These documents are the teammates' part.**

Copy everything below the line into your AI assistant as the prompt. What comes back is a
folder of Markdown files; put them in `tools/plan_server/rag/` (a pull request, or send the
zip to Tarık). The two files already there (`litchfield.md`, `uluru.md`) are examples of
the format.

---

You are writing reference documents for a road-trip planner for the Northern Territory,
Australia. A server reads these files and pastes them into a language model's prompt, so
every fact must be correct and every file must follow the format exactly.

**Output:** one Markdown file per place, file name in kebab-case (`nitmiluk-gorge.md`).

**Format of each file** — a front-matter block, then the body:

```
---
name: Nitmiluk National Park
aliases: [Katherine Gorge, Nitmiluk Gorge]
lat: -14.3103
lng: 132.4204
region: top_end
tags: [Nature, Adventure]
sources:
  - https://nt.gov.au/parks/find-a-park/nitmiluk-national-park
  - https://www.nitmiluktours.com.au/
---
Hours: …
Fees: …
Permits: …
Seasonal access: …
Getting there: …
What to do: …
Good to know: …
```

Rules for the front matter:

- `name`: the official name a map search finds. Use the dual name where one exists
  ("Uluru-Kata Tjuta National Park", "Leliyn (Edith Falls)").
- `aliases`: other names people use, including the Aboriginal or the English name that is
  not in `name`. The server matches the model's stop names against `name` and `aliases`.
- `lat`, `lng`: decimal degrees, 4 decimal places, of the place's visitor area or main
  car park — taken from OpenStreetMap or the official park page, never estimated. The
  Territory is south and east: `lat` is negative, `lng` positive.
- `region`: `top_end` (north of and including Katherine), `red_centre` (Alice Springs,
  the MacDonnell Ranges, Kings Canyon, Uluru) or `both` (the Stuart Highway towns between,
  such as Tennant Creek and Daly Waters).
- `tags`: one to three of exactly `Nature`, `Culture`, `Adventure`, `Wildlife`,
  `Relaxation` (these exact spellings).
- `sources`: the pages every fact in the body comes from. Prefer nt.gov.au,
  parksaustralia.gov.au, northernterritory.com and the operator's own site.

Rules for the body (plain text lines, at most ~250 words per file):

- **Hours, fees, permits and seasonal closures as of 2026**, with the wet season
  (November–April) closures stated explicitly. If a fact cannot be confirmed from a
  source, write "Not confirmed — check before you go" instead of a number.
- Name permits where they are required (Arnhem Land, the NT Parks Pass for interstate and
  overseas visitors) and cultural rules (no climbing Uluru, no photography at marked
  sacred sites).
- Road access: sealed or unsealed, 4WD only or not, typical drive time from the nearest
  town.
- No marketing language, no emoji, no invented facts, no coordinates in the body.

**Places to cover** (about 40; add others you think a traveller would stop at):

Top End — Darwin (Waterfront, Mindil Beach, Museum and Art Gallery of the NT), Berry Springs
and the Territory Wildlife Park, Litchfield National Park (Florence Falls, Wangi Falls,
Buley Rockhole), Adelaide River, Kakadu National Park (Ubirr, Burrungkuy/Nourlangie,
Ngurrungurrudjba/Yellow Water cruise, Maguk, Gunlom, Jabiru), Arnhem Land (Gunbalanya/Injalak
Hill, with the permit), Pine Creek, Tjuwaliyn (Douglas) Hot Springs, Katherine, Nitmiluk
National Park, Leliyn (Edith Falls), Mataranka (Bitter Springs, Mataranka Thermal Pool),
Daly Waters.

Between — Tennant Creek, Karlu Karlu (Devils Marbles), Barrow Creek.

Red Centre — Alice Springs, Alice Springs Desert Park, the West MacDonnell Ranges
(Simpsons Gap, Standley Chasm/Angkerle Atwatye, Ellery Creek Big Hole, Ormiston Gorge,
Glen Helen), the East MacDonnell Ranges (Trephina Gorge), Kings Canyon (Watarrka National
Park), Uluru-Kata Tjuta National Park (Uluru, Kata Tjuta, the Cultural Centre), Yulara.

Before you finish, check every file: the front matter parses as YAML, `lat` is between
−26.5 and −10.5 and `lng` between 128.5 and 138.5, every tag is one of the five, and every
fact in the body appears on one of the `sources` pages.
