import 'dart:convert';

import '../../data/models/itinerary.dart';
import '../../data/models/plan_failure.dart';
import '../../data/models/stop.dart';
import 'stop_json.dart';

const double _minLat = -26.5;
const double _maxLat = -10.5;
const double _minLng = 128.5;
const double _maxLng = 138.5;

/// Parses a `PlanResponse` body (`docs/PHASE-3-CONTRACT.md` §3.3) into an
/// [Itinerary], or throws [PlanException] with [PlanFailure.invalidResponse].
///
/// [days] is the answer that produced the request; only the title fallback uses it.
Itinerary parsePlanResponse(String body, {required int days}) {
  final Object? decoded;
  try {
    decoded = jsonDecode(body);
  } on FormatException {
    throw const PlanException(
      PlanFailure.invalidResponse,
      'Body is not valid JSON.',
    );
  }
  if (decoded is! Map<String, Object?>) {
    throw const PlanException(
      PlanFailure.invalidResponse,
      'Body is not a JSON object.',
    );
  }

  if (decoded['schemaVersion'] != 1) {
    throw const PlanException(
      PlanFailure.invalidResponse,
      'Unsupported schemaVersion.',
    );
  }

  final rawStops = decoded['stops'];
  if (rawStops is! List) {
    throw const PlanException(
      PlanFailure.invalidResponse,
      'stops is not a list.',
    );
  }

  final stops = <Stop>[];
  for (final rawStop in rawStops) {
    if (stops.length == 14) break;
    if (rawStop is! Map<String, Object?>) continue;
    final stop = _parseStop(rawStop);
    if (stop != null) stops.add(stop);
  }

  if (stops.length < 2) {
    throw const PlanException(
      PlanFailure.invalidResponse,
      'Fewer than 2 valid stops.',
    );
  }

  final rawTitle = decoded['title'];
  final title = rawTitle is String && rawTitle.isNotEmpty
      ? rawTitle
      : '$days-day Northern Territory trip';

  return Itinerary(title: title, stops: stops);
}

/// Applies the two checks `stopFromJson` does not make; drops a stop whose
/// coordinates fall outside the NT box, and clears a `photoUrl` that is not
/// an `http(s)` URL. Returns `null` when the stop should be dropped.
Stop? _parseStop(Map<String, Object?> json) {
  Stop stop;
  try {
    stop = stopFromJson(json);
  } on FormatException {
    return null;
  }

  if (stop.name.trim().isEmpty) return null;

  if (stop.lat < _minLat ||
      stop.lat > _maxLat ||
      stop.lng < _minLng ||
      stop.lng > _maxLng) {
    return null;
  }

  final photoUrl = stop.photoUrl;
  if (photoUrl != null &&
      !photoUrl.startsWith('http://') &&
      !photoUrl.startsWith('https://')) {
    stop = Stop(
      name: stop.name,
      subtitle: stop.subtitle,
      lat: stop.lat,
      lng: stop.lng,
      hours: stop.hours,
      fee: stop.fee,
      duration: stop.duration,
      driveNext: stop.driveNext,
      aiNote: stop.aiNote,
      tags: stop.tags,
      detailedPlan: stop.detailedPlan,
      photoUrl: null,
    );
  }

  return stop;
}

/// HTTP status + body → the failure `docs/PHASE-3-CONTRACT.md` §1 names.
PlanFailure failureForStatus(int statusCode, String body) {
  String? code;
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, Object?>) {
      final error = decoded['error'];
      if (error is Map<String, Object?> && error['code'] is String) {
        code = error['code'] as String;
      }
    }
  } on FormatException {
    code = null;
  }

  switch (code) {
    case 'cannot_plan':
      return PlanFailure.cannotPlan;
    case 'unauthorised':
      return PlanFailure.unauthorised;
    case 'rate_limited':
      return PlanFailure.rateLimited;
  }

  if (statusCode == 400 || statusCode == 422) return PlanFailure.cannotPlan;
  if (statusCode == 401) return PlanFailure.unauthorised;
  if (statusCode == 429) return PlanFailure.rateLimited;
  return PlanFailure.serverError;
}
