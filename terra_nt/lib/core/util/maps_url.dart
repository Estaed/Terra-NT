import '../../data/models/stop.dart';

const _mapsDirectionsBase = 'https://www.google.com/maps/dir/?api=1';

/// Builds a driving directions URL for the live route.
///
/// Entries in [skipped] are original stop indices and are removed before the
/// origin, destination and waypoints are selected.
String? buildMapsUrl(
  List<Stop> stops, {
  Set<int> skipped = const <int>{},
  Set<int>? skippedIndices,
  Set<int>? skippedIndexes,
}) {
  final excluded = <int>{
    ...skipped,
    ...?skippedIndices,
    ...?skippedIndexes,
  };
  final liveStops = <Stop>[];
  for (var i = 0; i < stops.length; i++) {
    if (!excluded.contains(i)) {
      liveStops.add(stops[i]);
    }
  }

  if (liveStops.length < 2) {
    return null;
  }

  final origin = '${liveStops.first.lat},${liveStops.first.lng}';
  final destination = '${liveStops.last.lat},${liveStops.last.lng}';
  var url = '$_mapsDirectionsBase'
      '&origin=${Uri.encodeComponent(origin)}'
      '&destination=${Uri.encodeComponent(destination)}'
      '&travelmode=driving';

  final waypoints = liveStops
      .sublist(1, liveStops.length - 1)
      .map((stop) => '${stop.lat},${stop.lng}')
      .join('|');
  if (waypoints.isNotEmpty) {
    url += '&waypoints=${Uri.encodeComponent(waypoints)}';
  }
  return url;
}

String? mapsUrl(
  List<Stop> stops, {
  Set<int> skipped = const <int>{},
  Set<int>? skippedIndices,
  Set<int>? skippedIndexes,
}) => buildMapsUrl(
      stops,
      skipped: skipped,
      skippedIndices: skippedIndices,
      skippedIndexes: skippedIndexes,
    );

String? singleDestinationUrl(Stop stop) {
  final destination = destinationCoordinates(stop);
  return '$_mapsDirectionsBase'
      '&destination=${Uri.encodeComponent(destination)}'
      '&travelmode=driving';
}

/// The same destination used by Navigate and the offline clipboard fallback.
String destinationCoordinates(Stop stop) => '${stop.lat},${stop.lng}';
