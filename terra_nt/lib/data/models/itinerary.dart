import 'stop.dart';

class Itinerary {
  final String title;
  final List<Stop> stops;
  final int? days;
  /// Preserves a legacy saved route's display copy when its days are unknown.
  final String? storedMeta;

  const Itinerary({
    required this.title,
    required this.stops,
    this.days,
    this.storedMeta,
  });
}
