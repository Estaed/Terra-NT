import 'stop.dart';

class SavedRoute {
  final String id;
  final String title;
  final String meta;
  final String dateLabel;
  final List<Stop> stops;
  /// Absent on routes saved before day counts were part of the schema.
  final int? days;

  const SavedRoute({
    required this.id,
    required this.title,
    required this.meta,
    required this.dateLabel,
    required this.stops,
    this.days,
  });
}
