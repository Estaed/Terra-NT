import '../../data/models/saved_route.dart';
import '../../data/models/stop.dart';

/// Refreshes only road facts in the two demo routes, matching stops by name
/// within their own seed route. Returns the original list when nothing changes.
List<SavedRoute> refreshSeedFacts(
  List<SavedRoute> routes,
  List<SavedRoute> seeds,
) {
  List<SavedRoute>? result;
  for (var index = 0; index < routes.length; index++) {
    final route = routes[index];
    if (route.id != 'full-nt' && route.id != 'red-centre') continue;
    final seedIndex = seeds.indexWhere((seed) => seed.id == route.id);
    if (seedIndex == -1) continue;
    final seedStops = {
      for (final stop in seeds[seedIndex].stops) stop.name: stop,
    };
    List<Stop>? stops;
    for (var stopIndex = 0; stopIndex < route.stops.length; stopIndex++) {
      final stop = route.stops[stopIndex];
      final seed = seedStops[stop.name];
      if (seed == null) continue;
      final aiNote = stop.name == 'Nitmiluk Gorge, Katherine'
          ? seed.aiNote
          : stop.aiNote;
      if (stop.driveNext == seed.driveNext && stop.aiNote == aiNote) continue;
      stops ??= List<Stop>.from(route.stops);
      stops[stopIndex] = Stop(
        name: stop.name,
        subtitle: stop.subtitle,
        lat: stop.lat,
        lng: stop.lng,
        hours: stop.hours,
        fee: stop.fee,
        duration: stop.duration,
        driveNext: seed.driveNext,
        aiNote: aiNote,
        tags: stop.tags,
        detailedPlan: stop.detailedPlan,
        photoUrl: stop.photoUrl,
      );
    }
    if (stops == null) continue;
    result ??= List<SavedRoute>.from(routes);
    result[index] = SavedRoute(
      id: route.id,
      title: route.title,
      meta: route.meta,
      dateLabel: route.dateLabel,
      stops: stops,
      days: route.days,
    );
  }
  return result ?? routes;
}

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

/// Undo keeps the whole route and its original slot. A newer route with the
/// same stable id wins over the deleted snapshot.
List<SavedRoute> restore(List<SavedRoute> routes, SavedRoute route, int index) {
  if (routes.any((entry) => entry.id == route.id)) return routes;
  return List<SavedRoute>.from(routes)
    ..insert(index.clamp(0, routes.length), route);
}

List<SavedRoute> rename(List<SavedRoute> routes, String routeId, String title) {
  final trimmed = title.trim();
  final index = routes.indexWhere((route) => route.id == routeId);
  if (trimmed.isEmpty || index == -1 || routes[index].title == trimmed) {
    return routes;
  }
  final route = routes[index];
  return List<SavedRoute>.from(routes)
    ..[index] = SavedRoute(
      id: route.id,
      title: trimmed,
      meta: route.meta,
      dateLabel: route.dateLabel,
      stops: route.stops,
      days: route.days,
    );
}

/// Moves one slot without introducing another gesture on the Saved screen.
List<SavedRoute> move(List<SavedRoute> routes, String routeId, int direction) {
  final index = routes.indexWhere((route) => route.id == routeId);
  final target = index + direction;
  if (index == -1 ||
      (direction != -1 && direction != 1) ||
      target < 0 ||
      target >= routes.length) {
    return routes;
  }
  final result = List<SavedRoute>.from(routes);
  result.insert(target, result.removeAt(index));
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
