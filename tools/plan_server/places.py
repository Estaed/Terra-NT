"""Place documents (the RAG context) and geocoding for the planning server.

Task-45 contracts 7 and 8. A place document is a Markdown file in rag/ with a
front-matter block; rag/README.md states the format. Geocoding tries the
documents' names and aliases first, then Nominatim.
"""

import json
import os
import re
import threading
import time
import urllib.parse
import urllib.request
from dataclasses import dataclass
from pathlib import Path

REGIONS = ("top_end", "red_centre", "both")
TAGS = ("Nature", "Culture", "Adventure", "Wildlife", "Relaxation")
CONTEXT_HEADER = 'Context (use it for facts; cite its URLs in "sources"):'
CONTEXT_CAP = 30_000

# docs/PHASE-3-CONTRACT.md §3.3: a pin outside this box is a geocoding miss.
NT_LAT = (-26.5, -10.5)
NT_LNG = (128.5, 138.5)

NOMINATIM_URL = "https://nominatim.openstreetmap.org/search"
USER_AGENT = (
    "TerraNT-PlanServer/1.0 "
    "(Terra NT route planner, Charles Darwin University PRT691 student project)"
)
NOMINATIM_TIMEOUT_SECONDS = 10


def in_nt(lat, lng):
    return NT_LAT[0] <= lat <= NT_LAT[1] and NT_LNG[0] <= lng <= NT_LNG[1]


def _norm(name):
    return " ".join(name.split()).casefold()


@dataclass(frozen=True)
class PlaceDoc:
    file_name: str
    name: str
    aliases: tuple
    lat: float
    lng: float
    region: str
    tags: tuple
    sources: tuple
    body: str

    def render(self):
        lines = [f"## {self.name}"]
        if self.aliases:
            lines.append("Also known as: " + ", ".join(self.aliases))
        if self.tags:
            lines.append("Tags: " + ", ".join(self.tags))
        if self.sources:
            lines.append("Sources: " + " ".join(self.sources))
        if self.body:
            lines += ["", self.body]
        return "\n".join(lines)


@dataclass(frozen=True)
class Place:
    lat: float
    lng: float
    place_id: str


# --- place documents ------------------------------------------------------

_KEY = re.compile(r"^([A-Za-z_]+):\s*(.*)$")
_ITEM = re.compile(r"^\s*-\s+(.*)$")


def _scalar(text):
    text = text.strip()
    if len(text) >= 2 and text[0] == text[-1] and text[0] in "\"'":
        return text[1:-1]
    return text


def parse_front_matter(text):
    """Returns (fields, body). Lists are `key: [a, b]` or `key:` then `- item` lines."""
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        raise ValueError("the file does not start with a --- front-matter block")
    end = next((i for i in range(1, len(lines)) if lines[i].strip() == "---"), None)
    if end is None:
        raise ValueError("the front-matter block is not closed with ---")
    fields = {}
    key = None
    for line in lines[1:end]:
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        item = _ITEM.match(line)
        if item and key is not None and isinstance(fields[key], list):
            fields[key].append(_scalar(item.group(1)))
            continue
        pair = _KEY.match(line)
        if pair is None:
            raise ValueError(f"cannot read front-matter line {line!r}")
        key, value = pair.group(1), pair.group(2).strip()
        if value == "":
            fields[key] = []
        elif value.startswith("[") and value.endswith("]"):
            fields[key] = [_scalar(v) for v in value[1:-1].split(",") if v.strip()]
        else:
            fields[key] = _scalar(value)
    return fields, "\n".join(lines[end + 1 :]).strip()


def load_place_doc(path):
    path = Path(path)
    try:
        fields, body = parse_front_matter(path.read_text(encoding="utf-8"))

        def text(key):
            value = fields.get(key)
            if not isinstance(value, str) or not value:
                raise ValueError(f"'{key}' is missing")
            return value

        def items(key):
            value = fields.get(key, [])
            return tuple([value] if isinstance(value, str) else value)

        lat, lng = float(text("lat")), float(text("lng"))
        if not in_nt(lat, lng):
            raise ValueError(f"lat/lng {lat}, {lng} is outside the NT box")
        region = text("region")
        if region not in REGIONS:
            raise ValueError(f"region must be one of {', '.join(REGIONS)}")
        tags = items("tags")
        unknown = [t for t in tags if t not in TAGS]
        if unknown:
            raise ValueError(f"unknown tags {unknown}; use {', '.join(TAGS)}")
        sources = items("sources")
        if any(not s.startswith(("https://", "http://")) for s in sources):
            raise ValueError("every source must be an http(s) URL")
        return PlaceDoc(
            file_name=path.name,
            name=text("name"),
            aliases=items("aliases"),
            lat=lat,
            lng=lng,
            region=region,
            tags=tags,
            sources=sources,
            body=body,
        )
    except ValueError as error:
        raise ValueError(f"rag/{path.name}: {error}") from None


def load_place_docs(directory):
    """Every *.md in directory except README.md, in file-name order."""
    paths = sorted(Path(directory).glob("*.md"))
    return [load_place_doc(p) for p in paths if p.name.lower() != "readme.md"]


def context_block(docs, region):
    """The RAG block for a request's region, and the documents that did not fit.

    `full_nt` takes every document; a region takes its own and `both`. Whole
    documents are added in file-name order while the block stays under
    CONTEXT_CAP characters. No documents means no block ("").
    """
    chosen = [d for d in docs if region == "full_nt" or d.region in (region, "both")]
    parts, size, left_out = [], len(CONTEXT_HEADER), []
    for doc in chosen:
        text = doc.render()
        if size + 2 + len(text) > CONTEXT_CAP:
            left_out.append(doc.file_name)
            continue
        parts.append(text)
        size += 2 + len(text)
    if not parts:
        return "", left_out
    return "\n\n".join([CONTEXT_HEADER, *parts]), left_out


# --- geocoding ------------------------------------------------------------


def nominatim_url(name):
    query = urllib.parse.urlencode(
        {
            "format": "json",
            "limit": 1,
            "countrycodes": "au",
            "q": f"{name.strip()}, Northern Territory",
        }
    )
    return f"{NOMINATIM_URL}?{query}"


def fetch_json(url):
    request = urllib.request.Request(
        url, headers={"User-Agent": USER_AGENT, "Accept": "application/json"}
    )
    with urllib.request.urlopen(request, timeout=NOMINATIM_TIMEOUT_SECONDS) as response:
        return json.load(response)


class Geocoder:
    """Stop name -> Place, or None when it does not resolve inside the NT.

    Place documents first (case-insensitive name/alias match, placeId = the
    file name), then Nominatim at most once per `min_interval` seconds, its
    answers (including "nothing found") cached in `cache_path`. A network
    failure counts as unresolved for this request and is not cached.
    """

    def __init__(self, docs, cache_path, fetch=fetch_json, min_interval=1.0):
        self._known = {}
        for doc in docs:
            for name in (doc.name, *doc.aliases):
                self._known.setdefault(_norm(name), Place(doc.lat, doc.lng, doc.file_name))
        self._cache_path = Path(cache_path)
        self._cache = self._read_cache()
        self._fetch = fetch
        self._min_interval = min_interval
        self._last_request = None
        self._lock = threading.Lock()

    def resolve(self, name):
        if not isinstance(name, str) or not name.strip():
            return None
        key = _norm(name)
        if key in self._known:
            return self._known[key]
        with self._lock:
            if key not in self._cache:
                try:
                    self._cache[key] = self._nominatim(name)
                except (OSError, ValueError, KeyError, TypeError) as error:
                    print(f"geocode: Nominatim failed for {name!r}: {error}", flush=True)
                    return None
                self._write_cache()
            hit = self._cache[key]
        if hit is None:
            return None
        return Place(hit["lat"], hit["lng"], hit["placeId"])

    def _nominatim(self, name):
        if self._last_request is not None:
            wait = self._min_interval - (time.monotonic() - self._last_request)
            if wait > 0:
                time.sleep(wait)
        try:
            results = self._fetch(nominatim_url(name))
        finally:
            self._last_request = time.monotonic()
        if not results:
            return None
        first = results[0]
        lat, lng = float(first["lat"]), float(first["lon"])
        if not in_nt(lat, lng):
            return None
        return {"lat": lat, "lng": lng, "placeId": f"{first['osm_type']}/{first['osm_id']}"}

    def _read_cache(self):
        try:
            cache = json.loads(self._cache_path.read_text(encoding="utf-8"))
        except FileNotFoundError:
            return {}
        except (OSError, ValueError) as error:
            print(f"geocode: ignoring unreadable cache {self._cache_path}: {error}", flush=True)
            return {}
        return cache if isinstance(cache, dict) else {}

    def _write_cache(self):
        self._cache_path.parent.mkdir(parents=True, exist_ok=True)
        temp = self._cache_path.with_suffix(".tmp")
        temp.write_text(
            json.dumps(self._cache, ensure_ascii=False, indent=1, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        os.replace(temp, self._cache_path)
