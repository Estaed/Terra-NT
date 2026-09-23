import 'package:flutter_test/flutter_test.dart';
import 'package:terra_nt/core/util/saved_routes_ops.dart' as saved_routes_ops;
import 'package:terra_nt/data/models/saved_route.dart';

SavedRoute _route(String id) =>
    SavedRoute(id: id, title: id, meta: '', dateLabel: '', stops: const []);

List<String> _ids(List<SavedRoute> routes) =>
    routes.map((route) => route.id).toList();

void main() {
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
