# Offline map tiles for Terra NT: research, 2026-09-30

Question: how can the map work with no signal for a route the user saved, on flutter_map
8.3.1 with the CARTO `dark_all` raster basemap? All pages were read on 2026-09-30 unless another
date is given. Outcome: Blueprint D22 (viewed-tile cache, 30 days, no bulk download).

## CARTO's terms decide it

CARTO's [Basemap Terms](https://carto.com/legal/basemap-terms/) (last updated 2026-09-29)
forbid "downloading or extracting map content in bulk" and "caching map content on an end
user's device… for longer than thirty (30) days". The same terms class "educational,
academic" use as non-commercial. So a bulk "download this route" feature on CARTO tiles is
not allowed, whichever library does the downloading. "Bulk" is not defined. The free key
allows 5M requests a month for non-commercial use and 1M for commercial use
([API key page](https://carto.com/basemaps/apikey/),
[FAQ](https://docs.carto.com/faqs/carto-basemaps)).

Other providers:

- OSM forbids offline use outright ([tile policy](https://operations.osmfoundation.org/policies/tiles/)).
- MapTiler forbids bulk download without a written agreement ([terms](https://www.maptiler.com/terms/cloud/)).
- Stadia allows up to 100 MB of offline cache per device
  ([ToS](https://stadiamaps.com/terms-of-service/), 2026-03-18), but its
  [FAQ](https://stadiamaps.com/faqs/) ties this to "an active subscription". The two conflict;
  the question is unresolved.
- Protomaps ([downloads](https://docs.protomaps.com/basemaps/downloads)) and
  [OpenFreeMap](https://openfreemap.org/) allow downloads, but serve vector tiles only.

## flutter_map 8.3.1 already caches

- Built-in caching (`BuiltInMapCachingProvider`) arrived in 8.2.0
  ([changelog](https://pub.dev/packages/flutter_map/changelog), 2025-07-10). It is on by
  default and has a 1 GB soft limit.
- The [caching docs](https://docs.fleaflet.dev/layers/tile-layer/caching.md) warn that the
  default location is an OS cache directory that may be cleared at any time, and that the
  cache "should not be relied upon… for example, offline mapping".
- There is no prefetch API: [flutter_map#1979](https://github.com/fleaflet/flutter_map/issues/1979)
  was closed on 2026-07-01.

Two traps:

- **Stale tiles go blank offline.** A cached tile past its freshness date is re-requested, and
  if that request fails the stale copy is not shown
  ([image_provider.dart at v8.3.1](https://github.com/fleaflet/flutter_map/blob/v8.3.1/lib/src/layer/tile_layer/tile_provider/network/image_provider/image_provider.dart)).
  CARTO sends `Cache-Control: public, max-age=86400`, measured with a live `curl -I` on
  2026-09-30. So without `overrideFreshAge`, a viewed tile stops working offline after about
  24 hours.
- **The cache key includes the API key.** The default key is the full URL including
  `?key={key}`, so a new API key misses the whole cache. A custom `tileKeyGenerator` fixes it
  ([caching docs](https://docs.fleaflet.dev/layers/tile-layer/caching.md)).

The provider factory also takes `cacheDirectory`, `overrideFreshAge` and `readOnly`
([built_in_caching_provider.dart at v8.3.1](https://github.com/fleaflet/flutter_map/blob/v8.3.1/lib/src/layer/tile_layer/tile_provider/network/caching/built_in/built_in_caching_provider.dart)).

## Rejected

- **FMTC 10.1.1** (published 2025-03-09; [pub.dev](https://pub.dev/packages/flutter_map_tile_caching)):
  - GPL-3.0, with proprietary licences for sale.
  - Depends on a closed ObjectBox binary ([FMTC#197](https://github.com/JaffaKetchup/flutter_map_tile_caching/issues/197)).
  - Open Android build failure ([FMTC#194](https://github.com/JaffaKetchup/flutter_map_tile_caching/issues/194),
    updated 2026-06-14) and an isolate bug ([FMTC#193](https://github.com/JaffaKetchup/flutter_map_tile_caching/issues/193)).
  - Whether it runs on flutter_map 8.3.1 is unconfirmed.
  - It would not make CARTO prefetch legal anyway.
- **Vector tiles** ([vector_map_tiles](https://github.com/greensopinion/flutter-vector-map-tiles)):
  - Support for flutter_map 8 is only in the 9.0.0 betas (9.0.0-beta.13, 2026-09-01); 10.x needs
    the Flutter main channel.
  - `vector_map_tiles_pmtiles` 1.5.0 still needs `vector_map_tiles ^8`.
  - There is an open raster-mode scale bug ([#284](https://github.com/greensopinion/flutter-vector-map-tiles/issues/284)).
  - The dark style would have to be rebuilt.
- **MBTiles/PMTiles raster** ([flutter_map_mbtiles](https://pub.dev/packages/flutter_map_mbtiles)
  and [flutter_map_pmtiles](https://pub.dev/packages/flutter_map_pmtiles), MIT, 2025-02-05):
  these need a dark raster tileset we are allowed to hold, which CARTO's is not.

## Size (own arithmetic, not sourced)

A z14 tile is about 2.3 km across at NT latitudes. A 10 km corridor along 2,000 km of road
needs about 3,700 z14 tiles, or about 5,000 with the lower zooms.
