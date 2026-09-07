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
