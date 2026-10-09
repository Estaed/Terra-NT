const _nominalAnchors = <double>[190, 430, 700];

double nearestSnap(double height, {double usableHeight = 700}) {
  final available = usableHeight.clamp(0.0, double.infinity).toDouble();
  final clampedHeight = height.clamp(0.0, available).toDouble();
  final anchors = <double>[];

  for (final nominal in _nominalAnchors) {
    final anchor = nominal.clamp(0.0, available).toDouble();
    if (!anchors.contains(anchor)) {
      anchors.add(anchor);
    }
  }

  var nearest = anchors.first;
  var bestDistance = (nearest - clampedHeight).abs();
  for (final anchor in anchors.skip(1)) {
    final distance = (anchor - clampedHeight).abs();
    if (distance < bestDistance) {
      nearest = anchor;
      bestDistance = distance;
    }
  }
  return nearest;
}
