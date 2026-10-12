# Place documents — the planning server's RAG data

Every `*.md` file in this directory except this README is one **place document**: a place
a traveller might stop at, with the facts the model should use for it. The server reads
them all at start (restart it after adding one), puts the ones for the request's region
into the prompt, and uses their coordinates before asking a geocoder. No embeddings, no
vector store: the text goes into the prompt as written.

## Format

A front-matter block between two `---` lines, then seven fixed sections. `_TEMPLATE.md`
is the blank to copy:

```markdown
---
id: litchfield
name: Litchfield National Park
aliases: [Litchfield, Litchfield NP]
lat: -13.1830
lng: 130.6805
region: top_end
tags: [Nature, Adventure]
Road_accessibility: Sealed loop road; 4WD only to Lost City and Tjaynera
station: Batchelor
price: live on MyFuel NT
fuel_type: Unleaded, Diesel
distance: ~20 km
Permit: NT Parks Visitor Pass
authority: Northern Territory Government
checked: 2026-10-12
sources:
  - https://nt.gov.au/parks/find-a-park/litchfield-national-park
---
## Access
## Hours, fees, permits
## Seasons and heat
## Activities and swimming
## Stay
## Wildlife and culture
## Fuel Station
```

| Field | Required | What it is |
|---|---|---|
| `name` | yes | The official name a map search finds. The model is told to use such names, and a stop whose name matches this (or an alias), ignoring case, takes this document's coordinates. |
| `aliases` | no | Other names the model might write for the same place (short name, dual name, old name). |
| `lat`, `lng` | yes | WGS84 decimal degrees, 4 decimals, inside the NT box (`lat` −26.5…−10.5, `lng` 128.5…138.5). |
| `region` | yes | `top_end`, `red_centre`, `barkly` or `both`. A `top_end` request gets `top_end` and `both` documents; `barkly` (Tennant Creek down to Aileron) only reaches `full_nt`, which gets all. |
| `tags` | no | Any of `Nature`, `Culture`, `Adventure`, `Wildlife`, `Relaxation`, exactly as written. |
| `sources` | no | Public `http(s)` URLs the facts come from. The model copies them into a stop's `sources`, so they must be real pages. |
| others | no | `id`, `Road_accessibility`, `station`, `price`, `fuel_type`, `distance`, `Permit`, `authority`, `checked`: the team's summary fields. The server reads them but does not send them to the model, so every fact in them must also be in the body. |

Lists are written either inline (`tags: [Nature, Adventure]`) or as `- item` lines under
an empty `key:`. Values may be quoted. Lines starting with `#` inside the block are
comments.

The body is the seven sections above, short plain sentences. State only what a source
says; the model is told to mark anything else "check before you go". No fuel prices (they
change daily; point to MyFuel NT), no drive times (the server takes them from OSRM), no
dated facts in the body (`checked` carries the date).

## How the data is collected

These rules follow Australian law and research ethics; a document that breaks one is
removed, not fixed later.

- **Official sources only:** nt.gov.au, Parks Australia (kakadu.gov.au, parksaustralia.gov.au),
  Tourism NT, the operator's own page, MyFuel NT. No Reddit, TripAdvisor, Facebook,
  forums or blogs. Each source is the specific page, not a homepage.
- **Indigenous knowledge** (AIATSIS Code of Ethics, ICIP): Traditional Owners, place names
  and cultural rules only as the official page publishes them for visitors. No sacred or
  restricted detail, stories or meanings beyond that page.
- **Copyright** (Copyright Act 1968): paraphrase; do not copy sentences.
- **Privacy** (Privacy Act 1988): public facts about places only, never about people.
- **Freshness:** `checked` is the day the sources were read; the planner tells the
  traveller to confirm road status (NT Road Report) and park alerts before leaving.

`check.py` checks every document against these format rules:
`python check.py` from this directory.

## Rules the server enforces

- A document with a missing or malformed field stops the server at start with the file
  name and the reason, so a bad document is found before a demo, not during one.
- The context block is capped at about 50 000 characters. Whole documents are added in
  file-name order until the next one would not fit; the server logs which ones were left
  out. Keep a document under about 1 500 characters.
- The file name (`litchfield.md`) becomes the stop's `placeId` when the name matched here.
