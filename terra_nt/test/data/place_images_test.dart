import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:terra_nt/data/seed/place_images.dart';
import 'package:terra_nt/data/seed/seed_data.dart';

void main() {
  void expectMapsToExistingFile(String name) {
    final image = placeImageFor(name);
    expect(image, isNotNull, reason: '$name should map to an image');
    expect(File(image!).existsSync(), isTrue, reason: '$image should exist for $name');
  }

  group('placeImageFor maps every seeded stop and POI to an existing file', () {
    for (final stop in seedStops) {
      test(stop.name, () => expectMapsToExistingFile(stop.name));
    }

    for (final stop in redCentreStops) {
      test(stop.name, () => expectMapsToExistingFile(stop.name));
    }

    for (final poi in seedPois) {
      test(poi.name, () => expectMapsToExistingFile(poi.name));
    }
  });

  test('Alice Springs Desert Park maps to desert-park, not alice-springs', () {
    expect(placeImageFor('Alice Springs Desert Park'), 'assets/images/places/desert-park.jpg');
  });

  test('unknown name maps to null', () {
    expect(placeImageFor('Somewhere Else Entirely'), isNull);
  });

  test('Uluru-Kata Tjuta National Park still maps to uluru', () {
    expect(placeImageFor('Uluru-Kata Tjuta National Park'), 'assets/images/places/uluru.jpg');
  });

  test('Kata Tjuta maps to kata-tjuta', () {
    expect(placeImageFor('Kata Tjuta'), 'assets/images/places/kata-tjuta.jpg');
  });

  test('each Task-46 POI maps to its own illustration by name', () {
    const expected = {
      'kata-tjuta': 'kata-tjuta',
      'ormiston': 'ormiston-gorge',
      'karlu-karlu': 'karlu-karlu',
      'mataranka': 'mataranka',
      'edith-falls': 'edith-falls',
      'wildlife-park': 'wildlife-park',
      'standley-chasm': 'standley-chasm',
    };
    for (final entry in expected.entries) {
      final poi = seedPois.singleWhere((p) => p.id == entry.key);
      expect(placeImageFor(poi.name), 'assets/images/places/${entry.value}.jpg', reason: poi.id);
    }
  });

  test('an unknown name falls back to its first known tag', () {
    expect(
      placeImageFor('Somewhere Else Entirely', tags: ['Wildlife']),
      'assets/images/places/tag-wildlife.jpg',
    );
    expect(
      placeImageFor('Somewhere Else Entirely', tags: ['Unknown', 'Culture']),
      'assets/images/places/tag-culture.jpg',
    );
  });

  test('an unknown name with no known tag maps to null', () {
    expect(placeImageFor('Somewhere Else Entirely', tags: ['Unknown', 'nature']), isNull);
  });

  test('a name hit wins over the tags', () {
    expect(placeImageFor('Darwin', tags: ['Wildlife']), 'assets/images/places/darwin.jpg');
  });

  test('every tag fallback file exists', () {
    for (final tag in ['Nature', 'Culture', 'Adventure', 'Wildlife', 'Relaxation']) {
      final image = placeImageFor('Somewhere Else Entirely', tags: [tag]);
      expect(image, 'assets/images/places/tag-${tag.toLowerCase()}.jpg');
      expect(File(image!).existsSync(), isTrue, reason: image);
    }
  });

  test('seedPois has 15 entries, unique ids, all inside the NT box', () {
    expect(seedPois.length, 15);
    expect(seedPois.map((p) => p.id).toSet().length, seedPois.length);
    for (final poi in seedPois) {
      expect(poi.lat, inInclusiveRange(-26.5, -10.5), reason: poi.id);
      expect(poi.lng, inInclusiveRange(128.5, 138.5), reason: poi.id);
    }
  });
}
