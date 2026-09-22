import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_route.dart';
import '../seed/seed_data.dart';

/// Persistence schema for the two preferences keys, and there are only two:
///
/// * `terra_nt.saved_routes` is a JSON-encoded list of route objects with
///   `id`, `title`, `meta`, and `dateLabel` string fields.
/// * `terra_nt.onboarding_done` is a boolean.
///
/// The third key, the one that held the session, went with Task-24: Firebase
/// Authentication persists the signed-in user on the device and answers
/// offline, so a second copy of the email here would be a second source of
/// truth. The session is now the auth seam's current user plus this flag.
///
/// An absent saved-routes value means the seeded demo routes. An explicitly
/// stored empty JSON list remains empty, which preserves the delete-account
/// behaviour.
class PreferencesStore {
  static const savedRoutesKey = 'terra_nt.saved_routes';
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

  Future<bool> readOnboardingDone() async {
    final preferences = await _preferences();
    return preferences.getBool(onboardingDoneKey) ?? false;
  }

  Future<void> saveOnboardingDone(bool onboardingDone) async {
    final preferences = await _preferences();
    await preferences.setBool(onboardingDoneKey, onboardingDone);
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
