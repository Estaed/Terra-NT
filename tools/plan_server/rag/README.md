# Place documents — the planning server's RAG data

Every `*.md` file in this directory except this README is one **place document**: a place
a traveller might stop at, with the facts the model should use for it. The server reads
them all at start (restart it after adding one), puts the ones for the request's region
into the prompt, and uses their coordinates before asking a geocoder. No embeddings, no
vector store: the text goes into the prompt as written.

## Format

A front-matter block between two `---` lines, then free text:

```markdown
---
name: Litchfield National Park
aliases:
  - Litchfield
  - Litchfield NP
lat: -13.1830
lng: 130.6805
region: top_end
tags: [Nature, Adventure]
sources:
  - https://northernterritory.com/darwin-and-surrounds/destinations/litchfield-national-park
---
Hours: ...
Fees: ...
```

| Field | Required | What it is |
|---|---|---|
| `name` | yes | The official name a map search finds. The model is told to use such names, and a stop whose name matches this (or an alias), ignoring case, takes this document's coordinates. |
| `aliases` | no | Other names the model might write for the same place (short name, dual name, old name). |
| `lat`, `lng` | yes | WGS84 decimal degrees, 4 decimals, inside the NT box (`lat` −26.5…−10.5, `lng` 128.5…138.5). |
| `region` | yes | `top_end`, `red_centre` or `both`. A `top_end` request gets `top_end` and `both` documents; `full_nt` gets all. |
| `tags` | no | Any of `Nature`, `Culture`, `Adventure`, `Wildlife`, `Relaxation`, exactly as written. |
| `sources` | no | Public `http(s)` URLs the facts come from. The model copies them into a stop's `sources`, so they must be real pages. |

Lists are written either inline (`tags: [Nature, Adventure]`) or as `- item` lines under
an empty `key:`. Values may be quoted. Lines starting with `#` inside the block are
comments.

The body is free text: opening hours, fees and passes, permits, seasonal (wet-season)
closures, road access (sealed, gravel, 4WD only), and what to do there. Short lines and
plain sentences work best. State only what a source says; the model is told to mark
anything else "check before you go".

## Rules the server enforces

- A document with a missing or malformed field stops the server at start with the file
  name and the reason, so a bad document is found before a demo, not during one.
- The context block is capped at about 30 000 characters. Whole documents are added in
  file-name order until the next one would not fit; the server logs which ones were left
  out. Keep a document under about 1 500 characters.
- The file name (`litchfield.md`) becomes the stop's `placeId` when the name matched here.
