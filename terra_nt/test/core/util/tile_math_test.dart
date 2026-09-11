import 'package:flutter_test/flutter_test.dart';

import 'package:terra_nt/core/util/tile_math.dart';

void main() {
  group('slippy-map tile coordinates', () {
    // Darwin, the seeded northern anchor (CLAUDE.md Part 2 data contracts).
    const darwinLat = -12.4634;
    const darwinLng = 130.8456;

    test('zoom 0 is the single world tile', () {
      expect(tileXForLongitude(darwinLng, 0), 0);
      expect(tileYForLatitude(darwinLat, 0), 0);
    });

    test('Darwin lands in the south-east quadrant at zoom 1', () {
      // Zoom 1 splits the world into four. Darwin is east of Greenwich and
      // south of the equator, so it must be column 1, row 1.
      expect(tileXForLongitude(darwinLng, 1), 1);
      expect(tileYForLatitude(darwinLat, 1), 1);
    });

    test('Darwin is tile 3/2 at zoom 2', () {
      // Longitude 130.8456 is 0.8635 of the way east across the world, which
      // falls in the fourth of four columns. Its Web Mercator y works out at
      // 0.5349, which falls in the third of four rows.
      expect(tileXForLongitude(darwinLng, 2), 3);
      expect(tileYForLatitude(darwinLat, 2), 2);
    });

    test('tile counts double with each zoom level', () {
      expect(tileCountForZoom(0), 1);
      expect(tileCountForZoom(4), 16);
      expect(tileCountForZoom(6), 64);
    });

    test('the antimeridian and poles clamp inside the grid', () {
      expect(tileXForLongitude(180, 4), 15);
      expect(tileXForLongitude(-180, 4), 0);
      expect(tileYForLatitude(-85.05, 4), 15);
    });
  });

  group('bounds coverage', () {
    test('a box inside one tile yields exactly that tile', () {
      final tiles = tilesForBounds(
        north: -12.4,
        south: -12.5,
        west: 130.8,
        east: 130.9,
        minZoom: 2,
        maxZoom: 2,
      );

      expect(tiles, [const TileCoordinate(z: 2, x: 3, y: 2)]);
    });

    test('rows run north to south', () {
      final tiles = tilesForBounds(
        north: ntBoundsNorth,
        south: ntBoundsSouth,
        west: ntBoundsWest,
        east: ntBoundsEast,
        minZoom: 4,
        maxZoom: 4,
      );

      final rows = tiles.map((tile) => tile.y).toSet().toList()..sort();
      expect(rows.first, tileYForLatitude(ntBoundsNorth, 4));
      expect(rows.last, tileYForLatitude(ntBoundsSouth, 4));
    });

    test('the NT prefetch covers zoom 4 to 6 and nothing else', () {
      final zooms = ntPrefetchTiles().map((tile) => tile.z).toSet();

      expect(zooms, {4, 5, 6});
    });

    test('the NT prefetch stays a small, duplicate-free set', () {
      final tiles = ntPrefetchTiles();

      expect(tiles.toSet(), hasLength(tiles.length));
      // Small enough to warm on a screen the user is still reading.
      expect(tiles, hasLength(lessThan(80)));
    });
  });

  group('tile URLs', () {
    const template =
        'https://basemaps.cartocdn.com/rastertiles/dark_all/'
        '{z}/{x}/{y}{r}.png?key={key}';

    test('fills every placeholder, dropping {r} when retina is off', () {
      expect(
        tileUrl(
          urlTemplate: template,
          tile: const TileCoordinate(z: 5, x: 27, y: 17),
          apiKey: 'abc123',
        ),
        'https://basemaps.cartocdn.com/rastertiles/dark_all/'
        '5/27/17.png?key=abc123',
      );
    });

    test('server retina asks for the @2x tile', () {
      expect(
        tileUrl(
          urlTemplate: template,
          tile: const TileCoordinate(z: 5, x: 27, y: 17),
          apiKey: 'abc123',
          retina: true,
        ),
        contains('/5/27/17@2x.png'),
      );
    });

    test('a missing key leaves an empty key parameter rather than a literal', () {
      final url = tileUrl(
        urlTemplate: template,
        tile: const TileCoordinate(z: 4, x: 13, y: 8),
      );

      expect(url, endsWith('key='));
      expect(url.contains('{'), isFalse);
    });

    test('one URL is listed per prefetched tile, all placeholders resolved', () {
      final urls = ntPrefetchTileUrls(urlTemplate: template, apiKey: 'k');

      expect(urls, hasLength(ntPrefetchTiles().length));
      expect(urls.every((url) => !url.contains('{')), isTrue);
    });
  });
}
