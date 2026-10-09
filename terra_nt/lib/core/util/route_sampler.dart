import 'dart:math' as math;

/// Returns cumulative Euclidean distances for a polyline of [lat, lng] pairs.
List<double> cumulativeDistances(List<List<double>> points) {
  if (points.isEmpty) {
    return <double>[];
  }

  final cumulative = <double>[0];
  for (var i = 1; i < points.length; i++) {
    final previous = points[i - 1];
    final current = points[i];
    final deltaLat = current[0] - previous[0];
    final deltaLng = current[1] - previous[1];
    cumulative.add(
      cumulative.last + math.sqrt(deltaLat * deltaLat + deltaLng * deltaLng),
    );
  }
  return cumulative;
}

/// Samples a point at fraction [fraction] along the full polyline.
List<double> pointAtFraction(List<List<double>> points, double fraction) {
  if (points.isEmpty) {
    throw ArgumentError.value(points, 'points', 'must not be empty');
  }
  if (points.length == 1) {
    return List<double>.from(points.first);
  }

  final clampedFraction = fraction.clamp(0.0, 1.0).toDouble();
  final cumulative = cumulativeDistances(points);
  final total = cumulative.last;
  final target = clampedFraction * total;

  for (var i = 1; i < cumulative.length; i++) {
    if (target <= cumulative[i]) {
      final previousDistance = cumulative[i - 1];
      final segmentDistance = cumulative[i] - previousDistance;
      final segmentFraction = segmentDistance == 0
          ? 0.0
          : (target - previousDistance) / segmentDistance;
      final start = points[i - 1];
      final end = points[i];
      return <double>[
        start[0] + (end[0] - start[0]) * segmentFraction,
        start[1] + (end[1] - start[1]) * segmentFraction,
      ];
    }
  }

  return List<double>.from(points.last);
}
