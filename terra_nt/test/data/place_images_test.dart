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
}
