import 'dart:math' as math;

import '../../data/models/itinerary.dart';
import '../../data/models/stop.dart';

List<int> reorder(List<int> order, int from, int to) {
  if (from < 0 || from >= order.length || order.isEmpty) {
    return List<int>.from(order);
  }

  final result = List<int>.from(order);
  final item = result.removeAt(from);
  final insertionIndex = to.clamp(0, result.length).toInt();
  result.insert(insertionIndex, item);
  return result;
}

List<int> remove(List<int> order, int originalIndex) =>
    order.where((index) => index != originalIndex).toList();

List<int> revertOne(List<int> order, int originalIndex) {
  final currentPosition = order.indexOf(originalIndex);
  if (currentPosition == -1) {
    return List<int>.from(order);
  }

  final result = List<int>.from(order);
  final item = result.removeAt(currentPosition);
  final insertionIndex = originalIndex.clamp(0, result.length).toInt();
  result.insert(insertionIndex, item);
  return result;
}

List<int> restoreRemoved(List<int> order, int totalStops) {
  final result = List<int>.from(order);
  for (var originalIndex = 0; originalIndex < totalStops; originalIndex++) {
    if (result.contains(originalIndex)) {
      continue;
    }
    final insertionIndex = originalIndex.clamp(0, result.length).toInt();
    result.insert(insertionIndex, originalIndex);
  }
  return result;
}

int removedCount(List<int> order, int totalStops) =>
    (totalStops - order.toSet().length).clamp(0, totalStops).toInt();

/// Whether the traveller has changed the generated route: a stop is skipped, a
/// stop was removed, or the order differs from the AI's.
bool hasEdits(List<int> order, Set<int> skipped, int totalStops) {
  if (skipped.isNotEmpty) return true;
  if (removedCount(order, totalStops) > 0) return true;
  for (var position = 0; position < order.length; position++) {
    if (order[position] != position) return true;
  }
  return false;
}

String removedLabel(int count) =>
    'Restore $count removed stop${count == 1 ? '' : 's'}';

String derivedMeta(int stopCount, int days) => '$days days · $stopCount stops';

String itineraryMeta(Itinerary itinerary, int stopCount) {
  final days = itinerary.days;
  return days == null
      ? itinerary.storedMeta ?? '$stopCount stops'
      : derivedMeta(stopCount, days);
}

/// Separates overlapping pin hit boxes in screen space, keeping each centre
/// inside the fitted strip. The route's geographical points are unchanged.
/// Points outside the strip stay put so panning never drags them back on screen.
List<(double, double)> fanOutPins(
  List<(double, double)> points, {
  required double left,
  required double top,
  required double right,
  required double bottom,
  required double spacing,
}) {
  if (right < left || bottom < top) return List.of(points);
  final placed = <(double, double)>[];
  for (final point in points) {
    // Projection round-off at a fitted boundary is not a user pan.
    const tolerance = 1e-7;
    if (point.$1 < left - tolerance ||
        point.$1 > right + tolerance ||
        point.$2 < top - tolerance ||
        point.$2 > bottom + tolerance) {
      placed.add(point);
      continue;
    }
    bool clear((double, double) candidate) => placed.every(
      (other) =>
          (candidate.$1 - other.$1).abs() >= spacing ||
          (candidate.$2 - other.$2).abs() >= spacing,
    );
    var best = point;
    var distance = double.infinity;
    if (!clear(point)) {
      // Search around the original anchor, choosing the closest free slot.
      // Clamping also supplies slots along the strip's edges.
      for (var dx = -points.length; dx <= points.length; dx++) {
        for (var dy = -points.length; dy <= points.length; dy++) {
          final candidate = (
            (point.$1 + dx * spacing).clamp(left, right).toDouble(),
            (point.$2 + dy * spacing).clamp(top, bottom).toDouble(),
          );
          final squared =
              math.pow(candidate.$1 - point.$1, 2) +
              math.pow(candidate.$2 - point.$2, 2);
          if (squared < distance && clear(candidate)) {
            best = candidate;
            distance = squared.toDouble();
          }
        }
      }
    }
    placed.add(best);
  }
  return placed;
}

String? driveNextForPosition(
  List<int> order,
  int position,
  List<Stop> baselineStops,
) {
  if (position < 0 || position >= order.length) {
    return null;
  }
  if (position == order.length - 1) {
    return null;
  }

  final currentIndex = order[position];
  final nextIndex = order[position + 1];
  if (currentIndex < 0 || currentIndex >= baselineStops.length ||
      nextIndex != currentIndex + 1) {
    return _straightLineFallback(order, position, baselineStops);
  }
  final driveNext = baselineStops[currentIndex].driveNext;
  if (driveNext != null) return driveNext;
  return _straightLineFallback(order, position, baselineStops);
}

String _straightLineFallback(
  List<int> order,
  int position,
  List<Stop> baselineStops,
) {
  final currentIndex = order[position];
  final nextIndex = order[position + 1];
  if (currentIndex < 0 ||
      currentIndex >= baselineStops.length ||
      nextIndex < 0 ||
      nextIndex >= baselineStops.length) {
    return 'Drive time unavailable';
  }

  final current = baselineStops[currentIndex];
  final next = baselineStops[nextIndex];
  final km = _haversineKm(current.lat, current.lng, next.lat, next.lng);
  final roundedKm = math.max(5, (km / 5).round() * 5);
  return '$roundedKm km straight line to ${next.name}';
}

double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const earthRadiusKm = 6371.0;
  final dLat = _degToRad(lat2 - lat1);
  final dLng = _degToRad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_degToRad(lat1)) *
          math.cos(_degToRad(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusKm * c;
}

double _degToRad(double deg) => deg * math.pi / 180;
