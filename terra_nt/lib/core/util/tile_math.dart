// Web Mercator tile arithmetic and the tile-URL listing the map prefetch warms.
//
// Pure Dart on purpose (CLAUDE.md Part 2, tier 1): the slippy-map projection is
// the only real logic here, so it is tested without pumping a widget. Bounds
// arrive as raw WGS84 doubles rather than a `LatLngBounds`, because `latlong2`
// is constructed at the `flutter_map` boundary and never stored.

import 'dart:math' as math;

/// The Northern Territory's administrative extent, the area worth warming
/// before Explore mounts.
const ntBoundsNorth = -10.96;
const ntBoundsSouth = -26.0;
const ntBoundsWest = 129.0;
const ntBoundsEast = 138.0;

/// The zoom levels Explore and the backdrop open at.
const ntPrefetchMinZoom = 4;
const ntPrefetchMaxZoom = 6;

/// One raster tile in the slippy-map scheme.
class TileCoordinate {
  final int z;
  final int x;
  final int y;

  const TileCoordinate({required this.z, required this.x, required this.y});

  @override
  bool operator ==(Object other) =>
      other is TileCoordinate && other.z == z && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(z, x, y);

  @override
  String toString() => 'TileCoordinate($z/$x/$y)';
}

/// The number of tiles along one axis at [zoom].
int tileCountForZoom(int zoom) => 1 << zoom;

/// The tile column holding [longitude] at [zoom].
int tileXForLongitude(double longitude, int zoom) {
  final count = tileCountForZoom(zoom);
  final fraction = (longitude + 180.0) / 360.0;
  return (fraction * count).floor().clamp(0, count - 1);
}

/// The tile row holding [latitude] at [zoom], under the Web Mercator
/// projection the CARTO raster tiles are published in.
int tileYForLatitude(double latitude, int zoom) {
  final count = tileCountForZoom(zoom);
  final radians = latitude * math.pi / 180.0;
  final mercator =
      (1.0 - math.log(math.tan(radians) + 1.0 / math.cos(radians)) / math.pi) /
      2.0;
  return (mercator * count).floor().clamp(0, count - 1);
}

/// Every tile covering the box for the inclusive zoom range.
///
/// Latitude runs north to south as the tile row grows, so the northern edge
/// gives the first row and the southern edge the last.
List<TileCoordinate> tilesForBounds({
  required double north,
  required double south,
  required double west,
  required double east,
  required int minZoom,
  required int maxZoom,
}) {
  final tiles = <TileCoordinate>[];
  for (var zoom = minZoom; zoom <= maxZoom; zoom++) {
    final firstX = tileXForLongitude(west, zoom);
    final lastX = tileXForLongitude(east, zoom);
    final firstY = tileYForLatitude(north, zoom);
    final lastY = tileYForLatitude(south, zoom);
    for (var x = firstX; x <= lastX; x++) {
      for (var y = firstY; y <= lastY; y++) {
        tiles.add(TileCoordinate(z: zoom, x: x, y: y));
      }
    }
  }
  return tiles;
}

/// The tiles covering the Northern Territory at the zoom levels Explore uses.
List<TileCoordinate> ntPrefetchTiles() => tilesForBounds(
  north: ntBoundsNorth,
  south: ntBoundsSouth,
  west: ntBoundsWest,
  east: ntBoundsEast,
  minZoom: ntPrefetchMinZoom,
  maxZoom: ntPrefetchMaxZoom,
);

/// Fills a slippy-map URL template for one tile.
///
/// Mirrors how `flutter_map` resolves its placeholders, so a prefetched URL is
/// byte-identical to the one `TileLayer` later asks for — otherwise the warm
/// cache would never be hit. `{r}` is `@2x` only in server retina mode, which
/// is why [retina] defaults to off here just as it does on the tile layer.
String tileUrl({
  required String urlTemplate,
  required TileCoordinate tile,
  String apiKey = '',
  bool retina = false,
}) => urlTemplate
    .replaceAll('{z}', '${tile.z}')
    .replaceAll('{x}', '${tile.x}')
    .replaceAll('{y}', '${tile.y}')
    .replaceAll('{r}', retina ? '@2x' : '')
    .replaceAll('{key}', apiKey);

/// Every tile URL the prefetch should warm before Explore mounts.
List<String> ntPrefetchTileUrls({
  required String urlTemplate,
  String apiKey = '',
  bool retina = false,
}) => ntPrefetchTiles()
    .map(
      (tile) => tileUrl(
        urlTemplate: urlTemplate,
        tile: tile,
        apiKey: apiKey,
        retina: retina,
      ),
    )
    .toList(growable: false);
