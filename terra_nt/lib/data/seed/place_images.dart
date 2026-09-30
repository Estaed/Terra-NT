import '../models/saved_route.dart';

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
  MapEntry("kata tjuta", "kata-tjuta"),
  MapEntry("olgas", "kata-tjuta"),
  MapEntry("ormiston", "ormiston-gorge"),
  MapEntry("karlu karlu", "karlu-karlu"),
  MapEntry("devils marbles", "karlu-karlu"),
  MapEntry("mataranka", "mataranka"),
  MapEntry("bitter springs", "mataranka"),
  MapEntry("edith falls", "edith-falls"),
  MapEntry("leliyn", "edith-falls"),
  MapEntry("wildlife park", "wildlife-park"),
  MapEntry("standley chasm", "standley-chasm"),
  MapEntry("angkerle", "standley-chasm"),
];

const Set<String> _tagsWithImages = {"Nature", "Culture", "Adventure", "Wildlife", "Relaxation"};

/// Case-insensitive substring match against a fixed slug order — first hit wins.
/// With no name hit, the first exact-case known tag picks a fallback picture.
String? placeImageFor(String name, {Iterable<String> tags = const []}) {
  final lower = name.toLowerCase();
  for (final matcher in _placeImageMatchers) {
    if (lower.contains(matcher.key)) {
      return "assets/images/places/${matcher.value}.jpg";
    }
  }
  for (final tag in tags) {
    if (_tagsWithImages.contains(tag)) {
      return "assets/images/places/tag-${tag.toLowerCase()}.jpg";
    }
  }
  return null;
}

/// Regional names take precedence over the first stop's destination picture.
/// Older and custom routes need no extra persisted cover field.
String? savedRouteCoverFor(SavedRoute route) {
  final name = '${route.id} ${route.title}';
  for (final region in const ['full_nt', 'top_end', 'red_centre']) {
    final words = region.split('_').join(r'[\s-]+');
    if (RegExp('\\b$words\\b', caseSensitive: false).hasMatch(name)) {
      return 'assets/images/scenes/$region.jpg';
    }
  }
  if (route.stops.isEmpty) return null;
  final stop = route.stops.first;
  return placeImageFor(stop.name, tags: stop.tags);
}
