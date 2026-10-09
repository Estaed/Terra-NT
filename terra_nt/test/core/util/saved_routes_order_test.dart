import 'package:flutter_test/flutter_test.dart';
import 'package:terra_nt/core/util/saved_routes_ops.dart' as saved_routes_ops;
import 'package:terra_nt/data/models/saved_route.dart';
import 'package:terra_nt/data/seed/seed_data.dart';

SavedRoute _route(String id) =>
    SavedRoute(id: id, title: id, meta: '', dateLabel: '', stops: const []);

List<String> _ids(List<SavedRoute> routes) =>
    routes.map((route) => route.id).toList();

void main() {
  group('saved-route changes', () {
    test('restore puts the complete deleted route back at its index', () {
      final routes = [_route('first'), seedSavedRoutes.first, _route('last')];
      final remaining = [routes.first, routes.last];
      final restored = saved_routes_ops.restore(remaining, routes[1], 1);
      expect(restored, routes);
      expect(identical(restored[1], routes[1]), isTrue);
      expect(remaining, [routes.first, routes.last]);
    });

    test(
      'restore handles an empty or shortened list and does not duplicate ids',
      () {
        final route = _route('deleted');
        expect(saved_routes_ops.restore([], route, 2), [route]);
        expect(_ids(saved_routes_ops.restore([_route('first')], route, 4)), [
          'first',
          'deleted',
        ]);
        final newer = _route('deleted');
        final routes = [newer];
        expect(
          identical(saved_routes_ops.restore(routes, route, 0), routes),
          isTrue,
        );
        expect(saved_routes_ops.restore(routes, route, 0).single, same(newer));
      },
    );

    test('rename trims the title and keeps identity, stops, days and copy', () {
      const route = SavedRoute(
        id: 'generated-trip',
        title: 'Original',
        meta: '9 days · 7 stops',
        dateLabel: 'Your latest plan',
        stops: seedStops,
        days: 9,
      );
      final routes = [_route('first'), route];
      final renamed = saved_routes_ops.rename(
        routes,
        route.id,
        '  My holiday  ',
      );
      expect(renamed[1].title, 'My holiday');
      expect(renamed[1].id, route.id);
      expect(renamed[1].stops, same(route.stops));
      expect(renamed[1].days, 9);
      expect(renamed[1].meta, route.meta);
      expect(renamed[1].dateLabel, route.dateLabel);
      expect(routes[1].title, 'Original');
      expect(saved_routes_ops.upsert(renamed, route), [routes.first, route]);
    });

    test('blank, missing and unchanged renames are ignored', () {
      final routes = [_route('first')];
      for (final (id, title) in [
        ('first', '   '),
        ('missing', 'New'),
        ('first', 'first'),
      ]) {
        expect(
          identical(saved_routes_ops.rename(routes, id, title), routes),
          isTrue,
        );
      }
    });

    test('move up and down one slot without mutating the original', () {
      final routes = [_route('first'), _route('middle'), _route('last')];
      expect(_ids(saved_routes_ops.move(routes, 'middle', -1)), [
        'middle',
        'first',
        'last',
      ]);
      expect(_ids(saved_routes_ops.move(routes, 'middle', 1)), [
        'first',
        'last',
        'middle',
      ]);
      expect(_ids(saved_routes_ops.move(routes, 'last', -1)), [
        'first',
        'last',
        'middle',
      ]);
      expect(_ids(saved_routes_ops.move(routes, 'first', 1)), [
        'middle',
        'first',
        'last',
      ]);
      expect(_ids(routes), ['first', 'middle', 'last']);
    });

    test('moves at either end, missing ids and empty lists are no-ops', () {
      final routes = [_route('first'), _route('last')];
      for (final (id, direction) in [
        ('first', -1),
        ('last', 1),
        ('missing', 1),
        ('first', 2),
      ]) {
        expect(
          identical(saved_routes_ops.move(routes, id, direction), routes),
          isTrue,
        );
      }
      expect(saved_routes_ops.move([], 'missing', -1), isEmpty);
      final single = [_route('only')];
      expect(saved_routes_ops.move(single, 'only', -1), same(single));
      expect(saved_routes_ops.move(single, 'only', 1), same(single));
    });
  });

  group('orderByPosition', () {
    test('restores the pushed order, not the document-id order', () {
      // Firestore returns documents by id; the local list had the generated
      // trip on top.
      final pulled = [
        (1, _route('full-nt')),
        (0, _route('generated-trip')),
        (2, _route('red-centre')),
      ];

      expect(_ids(saved_routes_ops.orderByPosition(pulled)), [
        'generated-trip',
        'full-nt',
        'red-centre',
      ]);
    });

    test('documents without a position follow, in the order they arrived', () {
      final pulled = [
        (null, _route('b-legacy')),
        (1, _route('second')),
        (null, _route('a-legacy')),
        (0, _route('first')),
      ];

      expect(_ids(saved_routes_ops.orderByPosition(pulled)), [
        'first',
        'second',
        'b-legacy',
        'a-legacy',
      ]);
    });

    test('an empty pull stays empty', () {
      expect(saved_routes_ops.orderByPosition(const []), isEmpty);
    });
  });
}
