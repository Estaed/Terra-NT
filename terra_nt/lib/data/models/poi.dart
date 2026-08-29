class Poi {
  final String id;
  final String name;
  final String tag;
  final String rating;
  final String description;
  final double lat;
  final double lng;
  final String? photoUrl;

  const Poi({
    required this.id,
    required this.name,
    required this.tag,
    required this.rating,
    required this.description,
    required this.lat,
    required this.lng,
    this.photoUrl,
  });
}
