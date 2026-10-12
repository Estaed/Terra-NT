"""Checks every place document in this directory against README.md's rules.

Run: python check.py [folder]
The server itself only refuses a malformed front matter; this also catches the quiet
failures: an empty or cut-off section, a placeholder, a fuel price, a dated fact.
"""
import re
import sys
from pathlib import Path

SECTIONS = ["## Access", "## Hours, fees, permits", "## Seasons and heat",
            "## Activities and swimming", "## Stay", "## Wildlife and culture",
            "## Fuel Station"]
FRONT = ["id", "name", "lat", "lng", "region", "Road_accessibility", "station", "price",
         "fuel_type", "distance", "Permit", "authority", "checked"]
REGIONS = ("top_end", "red_centre", "barkly", "both")
BODY_MAX = 1300
MONTHS = "Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec"
DATED = re.compile(rf"\b\d{{1,2}} ({MONTHS})[a-z]* \d{{4}}\b|\b20\d\d-\d\d-\d\d\b")
PRICE = re.compile(r"\d+(\.\d+)?\s*c/L", re.I)
PLACEHOLDER = re.compile(r"^(see operator sites|see official sources|tbd|todo|n/a)\b", re.I)
BANNED_SOURCES = ("reddit.com", "tripadvisor", "facebook.com", "forum", "blog")


def check(text):
    problems = []
    if text.count("---") < 2:
        return ["no front-matter block"]
    _, front, body = text.split("---", 2)
    fields = dict(re.findall(r"^([A-Za-z_]+):[ \t]*(.*)$", front, re.M))
    for key in FRONT:
        if not fields.get(key, "").strip():
            problems.append(f"missing front matter {key}")
    for key in ("lat", "lng"):
        if not re.fullmatch(r"-?\d+\.\d{4}", fields.get(key, "")):
            problems.append(f"{key} not 4 decimals")
    if fields.get("region") not in REGIONS:
        problems.append(f"region {fields.get('region')!r} not one of {', '.join(REGIONS)}")
    if PRICE.search(fields.get("price", "")):
        problems.append("price field holds a price; write 'live on MyFuel NT'")
    if len(body.strip()) > BODY_MAX:
        problems.append(f"body {len(body.strip())} chars > {BODY_MAX}")
    parts = re.split(r"^(## .+)$", body, flags=re.M)
    found = {parts[i].strip(): parts[i + 1].strip() for i in range(1, len(parts), 2)}
    if list(found) != SECTIONS:
        problems.append(f"sections are {list(found)}, expected the seven in order")
    for head, value in found.items():
        if len(value) < 15 or PLACEHOLDER.search(value):
            problems.append(f"{head} is empty or a placeholder")
        elif value.endswith(("(", ",", ":", "-")):
            problems.append(f"{head} is cut off: ...{value[-25:]!r}")
    if DATED.search(body):
        problems.append(f"dated fact in body: {DATED.search(body).group(0)}")
    if PRICE.search(body):
        problems.append("fuel price in body")
    if re.search(r"\b\d+(\.\d+)? ?(hours?|hrs?)'? drive|drive of \d", body):
        problems.append("drive time in body")
    sources = re.findall(r"^\s+- (\S+)", front, re.M)
    if not sources:
        problems.append("no sources")
    for s in sources:
        if any(b in s.lower() for b in BANNED_SOURCES):
            problems.append(f"unofficial source {s}")
        if re.fullmatch(r"https?://[^/]+/?", s):
            problems.append(f"homepage source {s}")
    return problems


folder = Path(sys.argv[1] if len(sys.argv) > 1 else Path(__file__).parent)
bad = 0
for f in sorted(folder.glob("*.md")):
    if f.name.startswith("_") or f.name.lower() == "readme.md":
        continue
    problems = check(f.read_text(encoding="utf-8"))
    if problems:
        bad += 1
        print(f"FAIL {f.name}: " + "; ".join(problems))
    else:
        print(f"ok   {f.name}")
print(f"\n{bad} file(s) with problems")
sys.exit(1 if bad else 0)
