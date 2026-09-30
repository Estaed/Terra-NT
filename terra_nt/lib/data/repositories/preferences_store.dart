import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/util/saved_routes_ops.dart';
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
  final Map<String, Set<Future<void>>> _remoteWrites = {};

  PreferencesStore({
    Future<SharedPreferences> Function()? preferences,
    this._pullRemote,
    this._pushRemote,
  }) : _preferences = preferences ?? SharedPreferences.getInstance;

  /// Local first. When the local key is ABSENT and [uid] is non-null and a
  /// remote list comes back non-null, adopts it: writes it locally and returns
  /// it. A present local key -- including an explicit empty list -- is never
  /// overwritten by the remote. A remote failure of any kind returns the local
  /// result. Changed demo road facts are saved locally, then pushed normally.
  Future<List<SavedRoute>> readSavedRoutes({String? uid}) async {
    final preferences = await _preferences();
    final encoded = preferences.getString(savedRoutesKey);
    if (encoded == null) {
      final pullRemote = _pullRemote;
      if (uid != null && pullRemote != null) {
        try {
          final remote = await pullRemote(uid);
          if (remote != null) {
            final refreshed = refreshSeedFacts(remote, seedSavedRoutes);
            await saveSavedRoutes(
              refreshed,
              uid: identical(refreshed, remote) ? null : uid,
            );
            return List<SavedRoute>.from(refreshed);
          }
        } catch (_) {
          // Offline or refused: the seed below is the local result.
        }
      }
      return List<SavedRoute>.from(seedSavedRoutes);
    }

    final List<SavedRoute> routes;
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) {
        throw const FormatException('Saved routes must be a list.');
      }
      routes = decoded
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
    final refreshed = refreshSeedFacts(routes, seedSavedRoutes);
    if (!identical(refreshed, routes)) {
      await saveSavedRoutes(refreshed, uid: uid);
    }
    return refreshed;
  }

  /// Completes after the local write. Every cloud push starts in the background
  /// without waiting for another push's server acknowledgement.
  Future<void> saveSavedRoutes(List<SavedRoute> routes, {String? uid}) async {
    final snapshot = List<SavedRoute>.unmodifiable(routes);
    final preferences = await _preferences();
    final encoded = jsonEncode(
      snapshot.map(savedRouteToJson).toList(growable: false),
    );
    await preferences.setString(savedRoutesKey, encoded);

    if (uid == null || _pushRemote == null) return;
    final operation = Future<void>.sync(() => _pushRemote(uid, snapshot))
        .catchError((Object _) {
          // The local copy is the source of truth; refused writes cannot reach UI.
        });
    final pending = _remoteWrites.putIfAbsent(uid, () => {});
    pending.add(operation);
    unawaited(
      operation.whenComplete(() {
        pending.remove(operation);
        if (pending.isEmpty) _remoteWrites.remove(uid);
      }),
    );
  }

  /// Pushes an empty list (deletes every remote doc) and THROWS on failure --
  /// delete-account must not proceed when the remote copy could not be cleared.
  Future<void> clearRemote(String uid) async {
    // No earlier background save may recreate documents after the clear.
    final pending = _remoteWrites[uid];
    if (pending != null) await Future.wait(pending.toList());
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
