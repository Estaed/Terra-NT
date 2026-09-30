import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/util/saved_routes_ops.dart';
import '../../core/util/stop_json.dart';
import '../models/saved_route.dart';

/// The account's copy of the saved routes, `users/{uid}/savedRoutes/{routeId}`
/// (`docs/PRD.md` D13). Supplies the two functions `PreferencesStore` takes;
/// it is not a seam. Untested by unit -- its shape is exercised on the emulator.
class FirestoreSavedRoutes {
  final FirebaseFirestore _firestore;
  // notifiers.dart constructs a wrapper per call. Share only push identities
  // for each SDK instance so an older cleanup cannot erase a newer save.
  static final _pushVersions = Expando<Map<String, Object>>();

  FirestoreSavedRoutes(this._firestore);

  CollectionReference<Map<String, dynamic>> _routes(String uid) =>
      _firestore.collection('users').doc(uid).collection('savedRoutes');

  /// Null for an empty collection, so a fresh account never wipes the seed on
  /// a fresh device. A document that fails to parse is skipped; one without a
  /// `position` sorts last.
  Future<List<SavedRoute>?> pull(String uid) async {
    final snapshot = await _routes(uid).get();
    if (snapshot.docs.isEmpty) return null;
    final entries = <(int?, SavedRoute)>[];
    for (final doc in snapshot.docs) {
      try {
        final data = doc.data();
        final position = data['position'];
        entries.add((
          position is int ? position : null,
          savedRouteFromJson(data),
        ));
      } on FormatException {
        continue;
      } on TypeError {
        continue;
      }
    }
    return orderByPosition(entries);
  }

  /// Queue a batch from the device cache without waiting for a server read.
  /// Once acknowledged, remove any stale docs not known to this device.
  /// Only the latest push reconciles the server. PreferencesStore waits for
  /// outstanding pushes before the delete-account clear.
  /// `updatedAt` is console metadata and is never read back into the model;
  /// `position` is the route's index in [routes] and is read back by [pull].
  Future<void> push(String uid, List<SavedRoute> routes) async {
    final collection = _routes(uid);
    final versions = _pushVersions[_firestore] ??= {};
    final identity = Object();
    versions[uid] = identity;
    try {
      await synchronizeSavedRoutes(
        routes,
        isCurrent: () => identical(versions[uid], identity),
        readIds: ({required bool fromCache}) async {
          final snapshot = await collection.get(
            GetOptions(source: fromCache ? Source.cache : Source.server),
          );
          return snapshot.docs.map((doc) => doc.id).toSet();
        },
        write: (toSave, toDelete) async {
          if (toSave.isEmpty && toDelete.isEmpty) return;
          final batch = _firestore.batch();
          for (var index = 0; index < toSave.length; index++) {
            final route = toSave[index];
            batch.set(collection.doc(route.id), {
              ...savedRouteToJson(route),
              'updatedAt': FieldValue.serverTimestamp(),
              'position': index,
            });
          }
          for (final id in toDelete) {
            batch.delete(collection.doc(id));
          }
          await batch.commit();
        },
      );
    } finally {
      if (identical(versions[uid], identity)) versions.remove(uid);
    }
  }
}

/// The concrete push sequence, with I/O closures for tests rather than a
/// Firebase double. Only cache reads precede the first write. The server pass
/// also makes an empty-list clear await deletion of uncached remote documents.
Future<void> synchronizeSavedRoutes(
  List<SavedRoute> routes, {
  required Future<Set<String>> Function({required bool fromCache}) readIds,
  required Future<void> Function(
    List<SavedRoute> routes,
    Set<String> deletedIds,
  )
  write,
  bool Function()? isCurrent,
}) async {
  final keep = routes.map((route) => route.id).toSet();
  final cached = await readIds(fromCache: true);
  if (isCurrent != null && !isCurrent()) return;
  await write(routes, cached.difference(keep));
  if (isCurrent != null && !isCurrent()) return;
  final remote = await readIds(fromCache: false);
  if (isCurrent != null && !isCurrent()) return;
  final obsolete = remote.difference(keep);
  if (obsolete.isNotEmpty) await write(const [], obsolete);
}
