import '../../data/models/saved_route.dart';

List<SavedRoute> upsert(List<SavedRoute> routes, SavedRoute route) {
  final result = List<SavedRoute>.from(routes);
  final existingIndex = result.indexWhere((entry) => entry.id == route.id);
  if (existingIndex == -1) {
    result.insert(0, route);
  } else {
    result[existingIndex] = route;
  }
  return result;
}

/// Restores the pushed order of a Firestore pull, which arrives by document
/// id. Entries without a position keep their arrival order, last.
List<SavedRoute> orderByPosition(List<(int?, SavedRoute)> entries) {
  final positioned = <(int, SavedRoute)>[];
  final unpositioned = <SavedRoute>[];
  for (final entry in entries) {
    final position = entry.$1;
    if (position == null) {
      unpositioned.add(entry.$2);
    } else {
      positioned.add((position, entry.$2));
    }
  }
  positioned.sort((a, b) => a.$1.compareTo(b.$1));
  return [for (final entry in positioned) entry.$2, ...unpositioned];
}
