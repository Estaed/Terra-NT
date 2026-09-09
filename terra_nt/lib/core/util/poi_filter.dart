import '../../data/models/poi.dart';

/// Applies the PRD Q6 name-or-tag search to the existing Explore collection.
List<Poi> filterPois(List<Poi> pois, String query) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return pois;
  return pois
      .where(
        (poi) =>
            poi.name.toLowerCase().contains(needle) ||
            poi.tag.toLowerCase().contains(needle),
      )
      .toList(growable: false);
}
