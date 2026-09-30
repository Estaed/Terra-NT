import 'package:flutter_test/flutter_test.dart';
import 'package:terra_nt/core/util/poi_filter.dart';
import 'package:terra_nt/data/seed/seed_data.dart';

void main() {
  test('matches trimmed case-insensitive name or tag substrings only', () {
    expect(filterPois(seedPois, ' UBI ').single.id, 'ubirr');
    expect(filterPois(seedPois, 'culture').map((poi) => poi.id), [
      'mindil',
      'ubirr',
      'uluru',
      'kata-tjuta',
      'karlu-karlu',
    ]);
    expect(filterPois(seedPois, 'floodplain'), isEmpty);
  });

  test('empty and whitespace-only queries retain the original collection', () {
    expect(filterPois(seedPois, ''), same(seedPois));
    expect(filterPois(seedPois, '   '), same(seedPois));
  });

  test('selects only a single match for a non-empty search', () {
    expect(singleSearchMatch(seedPois, ' ULURU ')?.id, 'uluru');
    expect(singleSearchMatch(seedPois, 'culture'), isNull);
    expect(singleSearchMatch(seedPois, 'missing'), isNull);
    expect(singleSearchMatch(seedPois, ''), isNull);
    expect(singleSearchMatch([seedPois.first], '   '), isNull);
    expect(singleSearchMatch([], 'uluru'), isNull);
  });
}
