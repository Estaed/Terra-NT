import '../../data/models/plan_entry.dart';
import '../../data/models/saved_route.dart';
import '../../data/models/stop.dart';

/// The JSON shape of a [Stop], shared by the saved-routes key (Task-26) and the
/// planning response parser (Task-31). Keys are the field names exactly.
Map<String, Object?> stopToJson(Stop stop) => {
  'name': stop.name,
  'subtitle': stop.subtitle,
  'lat': stop.lat,
  'lng': stop.lng,
  'hours': stop.hours,
  'fee': stop.fee,
  'duration': stop.duration,
  'driveNext': stop.driveNext,
  'aiNote': stop.aiNote,
  'tags': stop.tags,
  'detailedPlan': [
    for (final entry in stop.detailedPlan)
      {'time': entry.time, 'activity': entry.activity},
  ],
  'photoUrl': stop.photoUrl,
};

/// Throws [FormatException] when `name`, `lat` or `lng` is missing or of the
/// wrong type, or when a present field has the wrong type. A missing optional
/// field takes the fallback `docs/PHASE-3-CONTRACT.md` §3.3 names, and a
/// `detailedPlan` entry without both strings is dropped.
Stop stopFromJson(Map<String, Object?> json) {
  final name = json['name'];
  if (name is! String) {
    throw const FormatException('Stop name must be a string.');
  }
  return Stop(
    name: name,
    subtitle: _string(json, 'subtitle', ''),
    lat: _coordinate(json, 'lat'),
    lng: _coordinate(json, 'lng'),
    hours: _string(json, 'hours', 'Hours not listed'),
    fee: _nullableString(json, 'fee'),
    duration: _string(json, 'duration', '1 day'),
    driveNext: _nullableString(json, 'driveNext'),
    aiNote: _string(json, 'aiNote', ''),
    tags: _tags(json['tags']),
    detailedPlan: _detailedPlan(json['detailedPlan']),
    photoUrl: _nullableString(json, 'photoUrl'),
  );
}

Map<String, Object?> savedRouteToJson(SavedRoute route) => {
  'id': route.id,
  'title': route.title,
  'meta': route.meta,
  'dateLabel': route.dateLabel,
  if (route.days != null) 'days': route.days,
  'stops': [for (final stop in route.stops) stopToJson(stop)],
};

/// Throws [FormatException] when any field is missing or of the wrong type,
/// including a missing `stops` list. `days` is optional for legacy entries;
/// when present it must be a positive integer.
SavedRoute savedRouteFromJson(Map<String, Object?> json) {
  final days = json['days'];
  if (days != null && (days is! int || days <= 0)) {
    throw const FormatException('Saved route days must be a positive integer.');
  }
  final stops = json['stops'];
  if (stops is! List) {
    throw const FormatException('Saved route stops must be a list.');
  }
  final id = _requiredString(json, 'id');
  final dateLabel = _requiredString(json, 'dateLabel');
  return SavedRoute(
    id: id,
    title: _requiredString(json, 'title'),
    meta: _requiredString(json, 'meta'),
    // Earlier generated routes permanently claimed to have been made just now.
    dateLabel: id == 'generated-trip' && dateLabel == 'Generated just now'
        ? 'Your latest plan'
        : dateLabel,
    days: days as int?,
    stops: [
      for (final stop in stops)
        if (stop is Map<String, Object?>)
          stopFromJson(stop)
        else
          throw const FormatException('Saved route stop must be an object.'),
    ],
  );
}

double _coordinate(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! num) {
    throw FormatException('Stop $key must be a number.');
  }
  return value.toDouble();
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('$key must be a string.');
  }
  return value;
}

String _string(Map<String, Object?> json, String key, String fallback) {
  return _nullableString(json, key) ?? fallback;
}

String? _nullableString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null || value is String) return value as String?;
  throw FormatException('Stop $key must be a string.');
}

List<String> _tags(Object? value) {
  if (value == null) return const [];
  if (value is! List) {
    throw const FormatException('Stop tags must be a list.');
  }
  return [
    for (final tag in value)
      if (tag is String) tag,
  ];
}

List<PlanEntry> _detailedPlan(Object? value) {
  if (value == null) return const [];
  if (value is! List) {
    throw const FormatException('Stop detailedPlan must be a list.');
  }
  return [
    for (final entry in value)
      if (entry is Map &&
          entry['time'] is String &&
          entry['activity'] is String)
        PlanEntry(
          time: entry['time'] as String,
          activity: entry['activity'] as String,
        ),
  ];
}
