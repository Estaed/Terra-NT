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

/// Separates painted circles, not their larger touch targets. Only anchors that
/// originally overlap may move, and never by more than one pin diameter.
/// Points outside the strip stay put so panning never drags them back on screen.
List<(double, double)> fanOutPins(
  List<(double, double)> points, {
  required double left,
  required double top,
  required double right,
  required double bottom,
  required double diameter,
}) {
  if (right < left || bottom < top || diameter <= 0) return List.of(points);
  const tolerance = 1e-7;
  bool inside((double, double) point) =>
      point.$1 >= left - tolerance &&
      point.$1 <= right + tolerance &&
      point.$2 >= top - tolerance &&
      point.$2 <= bottom + tolerance;
  double distance((double, double) a, (double, double) b) =>
      math.sqrt(math.pow(a.$1 - b.$1, 2) + math.pow(a.$2 - b.$2, 2));
  final movable = [
    for (var i = 0; i < points.length; i++)
      inside(points[i]) &&
          points.indexed.any(
            (other) =>
                other.$1 != i &&
                inside(other.$2) &&
                distance(points[i], other.$2) < diameter - tolerance,
          ),
  ];
  final placed = List.of(points);
  for (var i = 0; i < points.length; i++) {
    if (!movable[i]) continue;
    final point = points[i];
    // Reserve future anchors too: a greedy placement must not consume the
    // only nearby space for a pin at the strip's edge. Isolated pins never move.
    final blockers = [
      for (var j = 0; j < points.length; j++)
        if (j != i) placed[j],
    ];
    bool clear((double, double) candidate) => blockers.every(
      (other) => distance(candidate, other) >= diameter - tolerance,
    );
    final candidates = [point];
    if (!clear(point)) {
      for (var j = 0; j < blockers.length; j++) {
        final other = blockers[j];
        final span = distance(point, other);
        if (span > tolerance) {
          candidates.add((
            other.$1 + (point.$1 - other.$1) * diameter / span,
            other.$2 + (point.$2 - other.$2) * diameter / span,
          ));
        } else {
          candidates.addAll([
            (point.$1 - diameter, point.$2),
            (point.$1 + diameter, point.$2),
            (point.$1, point.$2 - diameter),
            (point.$1, point.$2 + diameter),
          ]);
        }
        // The closest free position is on an obstacle's circle: either nearest
        // the anchor, or where that circle meets another constraint.
        for (final centre in [...blockers.skip(j + 1), point]) {
          candidates.addAll(_circleIntersections(other, centre, diameter));
        }
        for (final x in [left, right]) {
          final square = diameter * diameter - math.pow(x - other.$1, 2);
          if (square >= 0) {
            final dy = math.sqrt(square);
            candidates.addAll([(x, other.$2 - dy), (x, other.$2 + dy)]);
          }
        }
        for (final y in [top, bottom]) {
          final square = diameter * diameter - math.pow(y - other.$2, 2);
          if (square >= 0) {
            final dx = math.sqrt(square);
            candidates.addAll([(other.$1 - dx, y), (other.$1 + dx, y)]);
          }
        }
      }
    }
    var nearest = double.infinity;
    for (final candidate in candidates) {
      final span = distance(candidate, point);
      if (inside(candidate) &&
          span <= diameter + tolerance &&
          span < nearest &&
          clear(candidate)) {
        placed[i] = candidate;
        nearest = span;
      }
    }
    // At extreme zoom there may be no space for all circles. Preserve location
    // rather than inventing a distant position to force a packing solution.
  }
  return placed;
}

List<(double, double)> _circleIntersections(
  (double, double) a,
  (double, double) b,
  double radius,
) {
  final dx = b.$1 - a.$1;
  final dy = b.$2 - a.$2;
  final span = math.sqrt(dx * dx + dy * dy);
  if (span == 0 || span > radius * 2) return const [];
  final height = math.sqrt(math.max(0, radius * radius - span * span / 4));
  final x = (a.$1 + b.$1) / 2;
  final y = (a.$2 + b.$2) / 2;
  return [
    (x - dy * height / span, y + dx * height / span),
    (x + dy * height / span, y - dx * height / span),
  ];
}

/// The same ordered, unskipped stops used for leg labels and map export.
List<int> activeStopOrder(List<int> order, Set<int> skipped) =>
    order.where((index) => !skipped.contains(index)).toList();

String? driveNextForPosition(
  List<int> order,
  int position,
  List<Stop> baselineStops, {
  Set<int> skipped = const {},
}) {
  if (position < 0 || position >= order.length) {
    return null;
  }
  final currentIndex = order[position];
  final activeOrder = activeStopOrder(order, skipped);
  final activePosition = activeOrder.indexOf(currentIndex);
  // A skipped stop has no outgoing leg in the exported route.
  if (activePosition < 0 || activePosition == activeOrder.length - 1) {
    return null;
  }
  final nextIndex = activeOrder[activePosition + 1];
  if (currentIndex < 0 ||
      currentIndex >= baselineStops.length ||
      nextIndex != currentIndex + 1) {
    return _straightLineFallback(activeOrder, activePosition, baselineStops);
  }
  final driveNext = baselineStops[currentIndex].driveNext;
  if (driveNext != null) return driveNext;
  return _straightLineFallback(activeOrder, activePosition, baselineStops);
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
