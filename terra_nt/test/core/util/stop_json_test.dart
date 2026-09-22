import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:terra_nt/core/util/stop_json.dart';
import 'package:terra_nt/data/models/saved_route.dart';
import 'package:terra_nt/data/models/stop.dart';
import 'package:terra_nt/data/seed/seed_data.dart';

void _expectStopEqual(Stop actual, Stop expected) {
  expect(actual.name, expected.name);
  expect(actual.subtitle, expected.subtitle);
  expect(actual.lat, expected.lat);
  expect(actual.lng, expected.lng);
  expect(actual.hours, expected.hours);
  expect(actual.fee, expected.fee);
  expect(actual.duration, expected.duration);
  expect(actual.driveNext, expected.driveNext);
  expect(actual.aiNote, expected.aiNote);
  expect(actual.tags, expected.tags);
  expect(actual.detailedPlan.length, expected.detailedPlan.length);
  for (var index = 0; index < expected.detailedPlan.length; index++) {
    expect(actual.detailedPlan[index].time, expected.detailedPlan[index].time);
    expect(
      actual.detailedPlan[index].activity,
      expected.detailedPlan[index].activity,
    );
  }
  expect(actual.photoUrl, expected.photoUrl);
}

/// Goes through a real encode/decode so the test sees what the store reads.
Map<String, Object?> _throughJson(Map<String, Object?> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, Object?>;

Map<String, Object?> _minimal() => {'name': 'Somewhere', 'lat': -12.5, 'lng': 131};

void main() {
  test('every seeded stop round-trips field by field', () {
    for (final stop in [...seedStops, ...redCentreStops]) {
      _expectStopEqual(stopFromJson(_throughJson(stopToJson(stop))), stop);
    }
  });

  test('nullable fields serialise as JSON null', () {
    final json = stopToJson(seedStops.last);
    expect(json.containsKey('driveNext'), isTrue);
    expect(json['driveNext'], isNull);
    expect(json.containsKey('photoUrl'), isTrue);
    expect(json.containsKey('fee'), isTrue);
  });

  test('missing optional fields take the contract fallbacks', () {
    final stop = stopFromJson(_minimal());
    expect(stop.subtitle, '');
    expect(stop.hours, 'Hours not listed');
    expect(stop.duration, '1 day');
    expect(stop.aiNote, '');
    expect(stop.tags, isEmpty);
    expect(stop.detailedPlan, isEmpty);
    expect(stop.fee, isNull);
    expect(stop.driveNext, isNull);
    expect(stop.photoUrl, isNull);
    expect(stop.lng, 131.0);
  });

  test('a bad shape throws FormatException', () {
    expect(
      () => stopFromJson({'lat': -12.5, 'lng': 131.0}),
      throwsFormatException,
    );
    expect(
      () => stopFromJson({..._minimal(), 'lat': '-12.5'}),
      throwsFormatException,
    );
    expect(
      () => stopFromJson({..._minimal(), 'detailedPlan': 'morning'}),
      throwsFormatException,
    );
  });

  test('a saved route round-trips with its stops', () {
    final route = seedSavedRoutes[1];
    final read = savedRouteFromJson(_throughJson(savedRouteToJson(route)));
    expect(read.id, route.id);
    expect(read.title, route.title);
    expect(read.meta, route.meta);
    expect(read.dateLabel, route.dateLabel);
    expect(read.stops.length, route.stops.length);
    for (var index = 0; index < route.stops.length; index++) {
      _expectStopEqual(read.stops[index], route.stops[index]);
    }
  });

  test('a saved route without stops throws FormatException', () {
    final json = savedRouteToJson(
      const SavedRoute(
        id: 'old',
        title: 'Old',
        meta: '1 day · 1 stop',
        dateLabel: 'Generated today',
        stops: [],
      ),
    )..remove('stops');
    expect(() => savedRouteFromJson(json), throwsFormatException);
  });
}
