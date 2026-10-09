import 'package:flutter_test/flutter_test.dart';
import 'package:terra_nt/core/util/tile_cache_key.dart';

void main() {
  const tile = 'https://basemaps.cartocdn.com/rastertiles/dark_all/5/27/17.png';

  test('changing or omitting the CARTO key keeps the same tile identity', () {
    expect(tileCacheKey('$tile?key=old'), tileCacheKey('$tile?key=new'));
    expect(tileCacheKey('$tile?key='), tileCacheKey(tile));
    expect(tileCacheKey('$tile?key=old'), tile);
  });

  test('a URL with no query is unchanged', () {
    expect(tileCacheKey(tile), tile);
  });

  test('zoom, x, y and retina variants retain different identities', () {
    final keys = [
      '$tile?key=old',
      '${tile.replaceFirst('/5/', '/6/')}?key=old',
      '${tile.replaceFirst('/27/', '/28/')}?key=old',
      '${tile.replaceFirst('/17.png', '/18.png')}?key=old',
      '${tile.replaceFirst('.png', '@2x.png')}?key=old',
    ].map(tileCacheKey).toSet();
    expect(keys, hasLength(5));
  });

  test('removes only key parameters, preserving other query bytes', () {
    expect(
      tileCacheKey('$tile?lang=en&key=old&style=a%20b&lang=fr#tile'),
      '$tile?lang=en&style=a%20b&lang=fr#tile',
    );
    expect(tileCacheKey('$tile?key=old&key=new'), tile);
    expect(tileCacheKey('$tile?monkey=old'), '$tile?monkey=old');
  });
}
