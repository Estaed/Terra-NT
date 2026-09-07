import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_route.dart';
import '../models/session.dart';
import '../seed/seed_data.dart';

/// Persistence schema for the three phase-1 preferences keys:
///
/// * `terra_nt.saved_routes` is a JSON-encoded list of route objects with
///   `id`, `title`, `meta`, and `dateLabel` string fields.
/// * `terra_nt.session` is a JSON object with an `email` string or null.
/// * `terra_nt.onboarding_done` is a boolean.
///
/// An absent saved-routes value means the seeded demo routes. An explicitly
/// stored empty JSON list remains empty, which preserves the delete-account
/// behaviour.
class PreferencesStore {
  static const savedRoutesKey = 'terra_nt.saved_routes';
  static const sessionKey = 'terra_nt.session';
  static const onboardingDoneKey = 'terra_nt.onboarding_done';

  final Future<SharedPreferences> Function() _preferences;

  PreferencesStore({Future<SharedPreferences> Function()? preferences})
      : _preferences = preferences ?? SharedPreferences.getInstance;

  Future<List<SavedRoute>> readSavedRoutes() async {
    final preferences = await _preferences();
    final encoded = preferences.getString(savedRoutesKey);
    if (encoded == null) {
      return List<SavedRoute>.from(seedSavedRoutes);
    }

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) {
        throw const FormatException('Saved routes must be a list.');
      }
      return decoded.map(_savedRouteFromJson).toList(growable: false);
    } on FormatException {
      return List<SavedRoute>.from(seedSavedRoutes);
    } on TypeError {
      return List<SavedRoute>.from(seedSavedRoutes);
    }
  }

  Future<void> saveSavedRoutes(List<SavedRoute> routes) async {
    final preferences = await _preferences();
    final encoded = jsonEncode(
      routes
          .map(
            (route) => {
              'id': route.id,
              'title': route.title,
              'meta': route.meta,
              'dateLabel': route.dateLabel,
            },
          )
          .toList(growable: false),
    );
    await preferences.setString(savedRoutesKey, encoded);
  }

  Future<Session> readSession() async {
    final preferences = await _preferences();
    final onboardingDone = preferences.getBool(onboardingDoneKey) ?? false;
    final encoded = preferences.getString(sessionKey);
    if (encoded == null) {
      return Session(email: null, onboardingDone: onboardingDone);
    }

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Session must be an object.');
      }
      final email = decoded['email'];
      if (email != null && email is! String) {
        throw const FormatException('Session email must be a string.');
      }
      return Session(email: email as String?, onboardingDone: onboardingDone);
    } on FormatException {
      return Session(email: null, onboardingDone: onboardingDone);
    } on TypeError {
      return Session(email: null, onboardingDone: onboardingDone);
    }
  }

  Future<void> saveSession(Session session) async {
    final preferences = await _preferences();
    await preferences.setString(sessionKey, jsonEncode({'email': session.email}));
    await preferences.setBool(onboardingDoneKey, session.onboardingDone);
  }

  SavedRoute _savedRouteFromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Saved route must be an object.');
    }
    return SavedRoute(
      id: _requiredString(value, 'id'),
      title: _requiredString(value, 'title'),
      meta: _requiredString(value, 'meta'),
      dateLabel: _requiredString(value, 'dateLabel'),
    );
  }

  String _requiredString(Map<String, dynamic> value, String key) {
    final field = value[key];
    if (field is! String) {
      throw FormatException('Saved route $key must be a string.');
    }
    return field;
  }
}
