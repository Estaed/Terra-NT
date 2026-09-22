import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/util/stop_json.dart';
import '../models/saved_route.dart';

/// The account's copy of the saved routes, `users/{uid}/savedRoutes/{routeId}`
/// (`docs/PRD.md` D13). Supplies the two functions `PreferencesStore` takes;
/// it is not a seam. Untested by unit -- its shape is exercised on the emulator.
class FirestoreSavedRoutes {
  final FirebaseFirestore _firestore;

  FirestoreSavedRoutes(this._firestore);

  CollectionReference<Map<String, dynamic>> _routes(String uid) =>
      _firestore.collection('users').doc(uid).collection('savedRoutes');

  /// Null for an empty collection, so a fresh account never wipes the seed on
  /// a fresh device. A document that fails to parse is skipped.
  Future<List<SavedRoute>?> pull(String uid) async {
    final snapshot = await _routes(uid).get();
    if (snapshot.docs.isEmpty) return null;
    final routes = <SavedRoute>[];
    for (final doc in snapshot.docs) {
      try {
        routes.add(savedRouteFromJson(doc.data()));
      } on FormatException {
        continue;
      } on TypeError {
        continue;
      }
    }
    return routes;
  }

  /// One batch: set every route, delete every remote doc no longer in [routes].
  /// `updatedAt` is console metadata and is never read back into the model.
  Future<void> push(String uid, List<SavedRoute> routes) async {
    final collection = _routes(uid);
    final existing = await collection.get();
    final keep = routes.map((route) => route.id).toSet();
    final batch = _firestore.batch();
    for (final route in routes) {
      batch.set(collection.doc(route.id), {
        ...savedRouteToJson(route),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    for (final doc in existing.docs) {
      if (!keep.contains(doc.id)) batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
