import 'package:flutter_test/flutter_test.dart';
import 'package:terra_nt/core/util/saved_routes_ops.dart';
import 'package:terra_nt/core/util/stop_json.dart';
import 'package:terra_nt/data/models/saved_route.dart';
import 'package:terra_nt/data/models/stop.dart';
import 'package:terra_nt/data/seed/seed_data.dart';

Stop _oldStop(Stop stop) => stopFromJson(
  stopToJson(stop)
    ..['driveNext'] = switch (stop.name) {
      'Nitmiluk Gorge, Katherine' => '670 km · 7h to Alice Springs',
      'Kings Canyon' => '300 km · 3h to Uluru',
      _ => 'Old road fact',
    }
    ..['aiNote'] = 'My saved note',
);

SavedRoute _oldRoute(SavedRoute seed) => SavedRoute(
  id: seed.id,
  title: seed.title,
  meta: seed.meta,
  dateLabel: seed.dateLabel,
  stops: seed.stops.map(_oldStop).toList(),
  days: seed.days,
);

void main() {
  test('old Full NT copy gets every current drive and the Nitmiluk note', () {
    final old = _oldRoute(seedSavedRoutes.first);
    final routes = [old];
    final refreshed = refreshSeedFacts(routes, seedSavedRoutes).single;

    expect(
      refreshed.stops[3].driveNext,
      '1,191 km · about 12h to Alice Springs',
    );
    expect(refreshed.stops[5].driveNext, '302 km · 3h 10m to Uluru');
    for (var index = 0; index < old.stops.length; index++) {
      final expected = stopToJson(old.stops[index])
        ..['driveNext'] = seedStops[index].driveNext;
      if (index == 3) expected['aiNote'] = seedStops[index].aiNote;
      expect(stopToJson(refreshed.stops[index]), expected);
    }
    expect(old.stops[3].driveNext, '670 km · 7h to Alice Springs');
    expect(old.stops[5].driveNext, '300 km · 3h to Uluru');
    expect(routes.single, same(old));
  });

  test(
    'Red Centre facts come from its own route, including the in-town leg',
    () {
      final old = _oldRoute(seedSavedRoutes.last);
      final refreshed = refreshSeedFacts([old], seedSavedRoutes).single;

      expect(
        refreshed.stops.first.driveNext,
        '7 km · 15m to Alice Springs Desert Park',
      );
      expect(refreshed.stops[1].driveNext, '473 km · 4h 50m to Kings Canyon');
      expect(refreshed.stops[2].driveNext, '302 km · 3h 10m to Uluru');
      expect(refreshed.stops.last.driveNext, isNull);
      for (var index = 0; index < old.stops.length; index++) {
        expect(
          stopToJson(refreshed.stops[index]),
          stopToJson(old.stops[index])
            ..['driveNext'] = redCentreStops[index].driveNext,
        );
      }
    },
  );

  test(
    'renamed and reordered copies keep all fields except the road facts',
    () {
      final stop = stopFromJson(
        stopToJson(_oldStop(seedStops[3]))
          ..['subtitle'] = 'My subtitle'
          ..['lat'] = -14.4
          ..['lng'] = 132.5
          ..['hours'] = 'My hours'
          ..['fee'] = 'My fee'
          ..['duration'] = '3 days'
          ..['tags'] = ['My tag']
          ..['detailedPlan'] = [
            {'time': 'Later', 'activity': 'My activity'},
          ]
          ..['photoUrl'] = 'https://example.com/my-photo.jpg',
      );
      final unknown = stopFromJson(
        stopToJson(_oldStop(seedStops[0]))..['name'] = 'My extra stop',
      );
      final otherRoute = SavedRoute(
        id: 'generated-trip',
        title: 'Offline suggestion: Darwin to Katherine',
        meta: 'My meta',
        dateLabel: 'Your latest plan',
        stops: [stop],
        days: 5,
      );
      for (final days in [null, 11]) {
        final old = SavedRoute(
          id: 'full-nt',
          title: 'My renamed holiday',
          meta: 'Custom saved meta',
          dateLabel: 'Custom saved date',
          stops: [_oldStop(seedStops[5]), unknown, stop, seedStops[0]],
          days: days,
        );
        final refreshed = refreshSeedFacts([otherRoute, old], seedSavedRoutes);
        expect(refreshed.first, same(otherRoute));
        final expected = savedRouteToJson(old);
        final stops = expected['stops'] as List<Map<String, Object?>>;
        stops[0]['driveNext'] = seedStops[5].driveNext;
        stops[2]['driveNext'] = seedStops[3].driveNext;
        stops[2]['aiNote'] = seedStops[3].aiNote;
        expect(savedRouteToJson(refreshed.last), expected);
        expect(refreshed.last.stops[1], same(unknown));
        expect(refreshed.last.stops.last, same(seedStops[0]));
        expect(refreshed.last.stops[2].tags, same(stop.tags));
        expect(refreshed.last.stops[2].detailedPlan, same(stop.detailedPlan));
      }
    },
  );

  test('a stop from another seed route is left alone', () {
    final stop = _oldStop(seedStops[3]);
    final route = SavedRoute(
      id: 'red-centre',
      title: 'Custom',
      meta: '',
      dateLabel: '',
      stops: [stop],
    );
    final routes = [route];
    expect(refreshSeedFacts(routes, seedSavedRoutes), same(routes));
    expect(route.stops.single, same(stop));
  });

  test('a stale Nitmiluk note alone triggers the refresh', () {
    final stop = stopFromJson(
      stopToJson(seedStops[3])..['aiNote'] = 'Old note',
    );
    final route = SavedRoute(
      id: 'full-nt',
      title: '',
      meta: '',
      dateLabel: '',
      stops: [stop],
    );
    expect(
      refreshSeedFacts([route], seedSavedRoutes).single.stops.single.aiNote,
      seedStops[3].aiNote,
    );
  });

  test('second run and current seeds return the same list', () {
    final refreshed = refreshSeedFacts(
      seedSavedRoutes.map(_oldRoute).toList(),
      seedSavedRoutes,
    );
    expect(refreshSeedFacts(refreshed, seedSavedRoutes), same(refreshed));
    expect(
      refreshSeedFacts(seedSavedRoutes, seedSavedRoutes),
      same(seedSavedRoutes),
    );
  });

  test('empty lists and missing seed routes are unchanged', () {
    const empty = <SavedRoute>[];
    expect(refreshSeedFacts(empty, seedSavedRoutes), same(empty));
    final routes = [_oldRoute(seedSavedRoutes.first)];
    expect(refreshSeedFacts(routes, const []), same(routes));
  });
}
