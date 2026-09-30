import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/util/stop_json.dart';
import '../models/saved_route.dart';
import '../seed/seed_data.dart';

/// Persistence schema for the two preferences keys, and there are only two:
///
/// * `terra_nt.saved_routes` is a JSON-encoded list of route objects with
///   `id`, `title`, `meta`, and `dateLabel` string fields and a `stops` list in
///   the shape `stopToJson` writes, plus optional integer `days`. Old entries
///   without days retain their stored meta. An entry without `stops` is malformed.
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
///
/// The account's copy of the saved routes (D13) arrives through two injected
/// functions rather than an interface; null means no remote at all. The local
/// key stays the source of truth.
typedef PullRemote = Future<List<SavedRoute>?> Function(String uid);
typedef PushRemote = Future<void> Function(String uid, List<SavedRoute> routes);

class PreferencesStore {
  static const savedRoutesKey = 'terra_nt.saved_routes';
  static const onboardingDoneKey = 'terra_nt.onboarding_done';

  final Future<SharedPreferences> Function() _preferences;
  final PullRemote? _pullRemote;
  final PushRemote? _pushRemote;

  PreferencesStore({
    Future<SharedPreferences> Function()? preferences,
    this._pullRemote,
    this._pushRemote,
  }) : _preferences = preferences ?? SharedPreferences.getInstance;

  /// Local first. When the local key is ABSENT and [uid] is non-null and a
  /// remote list comes back non-null, adopts it: writes it locally and returns
  /// it. A present local key -- including an explicit empty list -- is never
  /// overwritten by the remote. A remote failure of any kind returns the local
  /// result.
  Future<List<SavedRoute>> readSavedRoutes({String? uid}) async {
    final preferences = await _preferences();
    final encoded = preferences.getString(savedRoutesKey);
    if (encoded == null) {
      final pullRemote = _pullRemote;
      if (uid != null && pullRemote != null) {
        try {
          final remote = await pullRemote(uid);
          if (remote != null) {
            await saveSavedRoutes(remote);
            return List<SavedRoute>.from(remote);
          }
        } catch (_) {
          // Offline or refused: the seed below is the local result.
        }
      }
      return List<SavedRoute>.from(seedSavedRoutes);
    }

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) {
        throw const FormatException('Saved routes must be a list.');
      }
      return decoded
          .map((route) {
            if (route is! Map<String, Object?>) {
              throw const FormatException('Saved route must be an object.');
            }
            return savedRouteFromJson(route);
          })
          .toList(growable: false);
    } on FormatException {
      return List<SavedRoute>.from(seedSavedRoutes);
    } on TypeError {
      return List<SavedRoute>.from(seedSavedRoutes);
    }
  }

  /// Writes locally, then pushes the same list when [uid] is non-null. A push
  /// failure is swallowed: the local write already succeeded and Firestore's
  /// offline queue retries on its own.
  Future<void> saveSavedRoutes(List<SavedRoute> routes, {String? uid}) async {
    final preferences = await _preferences();
    final encoded = jsonEncode(
      routes.map(savedRouteToJson).toList(growable: false),
    );
    await preferences.setString(savedRoutesKey, encoded);

    final pushRemote = _pushRemote;
    if (uid == null || pushRemote == null) return;
    try {
      await pushRemote(uid, routes);
    } catch (_) {
      // The local copy is the source of truth; the remote catches up later.
    }
  }

  /// Pushes an empty list (deletes every remote doc) and THROWS on failure --
  /// delete-account must not proceed when the remote copy could not be cleared.
  Future<void> clearRemote(String uid) async {
    await _pushRemote?.call(uid, const []);
  }

  Future<bool> readOnboardingDone() async {
    final preferences = await _preferences();
    return preferences.getBool(onboardingDoneKey) ?? false;
  }

  Future<void> saveOnboardingDone(bool onboardingDone) async {
    final preferences = await _preferences();
    await preferences.setBool(onboardingDoneKey, onboardingDone);
  }
}
