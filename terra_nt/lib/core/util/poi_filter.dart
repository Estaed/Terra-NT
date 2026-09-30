import '../../data/models/poi.dart';

/// Matches Explore place names and tags without changing the collection order.
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

/// Only a non-empty query with exactly one match should open a place card.
Poi? singleSearchMatch(List<Poi> pois, String query) {
  if (query.trim().isEmpty) return null;
  final matches = filterPois(pois, query);
  return matches.length == 1 ? matches.single : null;
}
