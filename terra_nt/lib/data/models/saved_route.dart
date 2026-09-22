import 'stop.dart';

class SavedRoute {
  final String id;
  final String title;
  final String meta;
  final String dateLabel;
  final List<Stop> stops;

  const SavedRoute({
    required this.id,
    required this.title,
    required this.meta,
    required this.dateLabel,
    required this.stops,
  });
}
