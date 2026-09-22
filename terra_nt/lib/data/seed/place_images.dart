const List<MapEntry<String, String>> _placeImageMatchers = [
  MapEntry("desert park", "desert-park"),
  MapEntry("alice springs", "alice-springs"),
  MapEntry("mindil", "mindil"),
  MapEntry("darwin", "darwin"),
  MapEntry("litchfield", "litchfield"),
  MapEntry("kakadu", "kakadu"),
  MapEntry("ubirr", "kakadu"),
  MapEntry("nitmiluk", "nitmiluk"),
  MapEntry("katherine", "nitmiluk"),
  MapEntry("kings canyon", "kings-canyon"),
  MapEntry("watarrka", "kings-canyon"),
  MapEntry("uluru", "uluru"),
];

/// Case-insensitive substring match against a fixed slug order — first hit wins.
String? placeImageFor(String name) {
  final lower = name.toLowerCase();
  for (final matcher in _placeImageMatchers) {
    if (lower.contains(matcher.key)) {
      return "assets/images/places/${matcher.value}.jpg";
    }
  }
  return null;
}
