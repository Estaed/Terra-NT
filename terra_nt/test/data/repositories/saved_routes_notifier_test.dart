import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terra_nt/core/util/saved_routes_ops.dart';
import 'package:terra_nt/core/util/stop_json.dart';
import 'package:terra_nt/data/models/saved_route.dart';
import 'package:terra_nt/data/repositories/auth_repository.dart';
import 'package:terra_nt/data/repositories/notifiers.dart';
import 'package:terra_nt/data/repositories/preferences_store.dart';
import 'package:terra_nt/data/seed/seed_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PreferencesStore store;
  late ProviderContainer container;
  late SavedRoutesNotifier notifier;
  late List<(int?, SavedRoute)> remote;
  late List<(String, List<SavedRoute>)> pushes;
  late int pulls;

  ProviderContainer createContainer() => ProviderContainer(
    overrides: [
      preferencesStoreProvider.overrideWithValue(store),
      authRepositoryProvider.overrideWithValue(InMemoryAuthRepository()),
    ],
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    remote = [
      for (var i = 0; i < seedSavedRoutes.length; i++) (i, seedSavedRoutes[i]),
    ];
    pushes = [];
    pulls = 0;
    store = PreferencesStore(
      pullRemote: (_) async {
        pulls++;
        return orderByPosition(remote);
      },
      pushRemote: (uid, routes) async {
        pushes.add((uid, List.of(routes)));
        remote = [for (var i = 0; i < routes.length; i++) (i, routes[i])];
      },
    );
    container = createContainer();
    await container
        .read(sessionNotifierProvider.notifier)
        .signInWithEmail('traveller@example.com', 'secret');
    notifier = container.read(savedRoutesNotifierProvider.notifier);
    await notifier.load();
  });

  tearDown(() => container.dispose());

  List<SavedRoute> routes() => container.read(savedRoutesNotifierProvider);
  List<String> ids() => routes().map((route) => route.id).toList();

  test(
    'delete and Undo restore the complete route at its original position',
    () async {
      final original = routes();
      await notifier.delete('red-centre');
      expect(ids(), ['full-nt']);
      await notifier.undoDelete('red-centre');
      expect(routes(), original);
      expect(
        (await store.readSavedRoutes()).map(savedRouteToJson),
        original.map(savedRouteToJson),
      );
      expect(pushes.last.$2, original);
      await notifier.undoDelete('red-centre');
      expect(pushes, hasLength(2));
    },
  );

  test(
    'only the most recent deletion can be undone, including the last card',
    () async {
      await notifier.delete('full-nt');
      await notifier.delete('red-centre');
      expect(routes(), isEmpty);
      expect(await store.readSavedRoutes(uid: 'another-device'), isEmpty);
      await notifier.undoDelete('full-nt');
      expect(routes(), isEmpty);
      await notifier.undoDelete('red-centre');
      expect(ids(), ['red-centre']);
    },
  );

  test(
    'account deletion and a changed account cannot restore stale routes',
    () async {
      await notifier.delete('full-nt');
      await container.read(sessionNotifierProvider.notifier).signOut();
      await notifier.undoDelete('full-nt');
      expect(ids(), ['red-centre']);
      await notifier.delete('red-centre');
      await notifier.clearForDeleteAccount();
      await notifier.undoDelete('red-centre');
      expect(routes(), isEmpty);
      expect(await store.readSavedRoutes(), isEmpty);
    },
  );

  test(
    'rename and order survive local reload and a positioned remote pull',
    () async {
      const generated = SavedRoute(
        id: 'generated-trip',
        title: 'Generated',
        meta: '9 days · 7 stops',
        dateLabel: 'Your latest plan',
        stops: seedStops,
        days: 9,
      );
      await notifier.upsert(generated);
      await notifier.rename('generated-trip', '  My holiday  ');
      await notifier.moveDown('generated-trip');
      await notifier.moveUp('red-centre');
      expect(ids(), ['full-nt', 'red-centre', 'generated-trip']);
      final expected = routes().map(savedRouteToJson).toList();
      expect(
        pushes.every((push) => push.$1 == 'uid-traveller@example.com'),
        isTrue,
      );
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getKeys(), {PreferencesStore.savedRoutesKey});

      container.dispose();
      container = createContainer();
      notifier = container.read(savedRoutesNotifierProvider.notifier);
      await notifier.load();
      expect(routes().map(savedRouteToJson), expected);
      expect(pulls, 1, reason: 'the local copy wins');
      final renamed = routes().last;
      expect(renamed.title, 'My holiday');
      expect(renamed.id, 'generated-trip');
      expect(renamed.days, 9);
      expect(renamed.stops.map(stopToJson), seedStops.map(stopToJson));

      // Simulate Firestore document-id order on a fresh device.
      remote.sort((a, b) => a.$2.id.compareTo(b.$2.id));
      await preferences.remove(PreferencesStore.savedRoutesKey);
      expect(
        (await store.readSavedRoutes(uid: 'uid-traveller@example.com'))
            .map(savedRouteToJson),
        expected,
      );
      expect(pulls, 2);
    },
  );

  test('boundary moves and blank renames do not write', () async {
    await notifier.moveUp('full-nt');
    await notifier.moveDown('red-centre');
    await notifier.rename('full-nt', '  ');
    await notifier.rename('missing', 'New');
    await notifier.delete('missing');
    expect(pushes, isEmpty);
    expect(routes(), seedSavedRoutes);
  });

  test(
    'a renamed generated route still upserts in place and supersedes Undo',
    () async {
      const old = SavedRoute(
        id: 'generated-trip',
        title: 'Old',
        meta: '',
        dateLabel: '',
        stops: [],
        days: 3,
      );
      const next = SavedRoute(
        id: 'generated-trip',
        title: 'Next',
        meta: '',
        dateLabel: '',
        stops: seedStops,
        days: 7,
      );
      await notifier.upsert(old);
      await notifier.rename(old.id, 'My route');
      await notifier.moveDown(old.id);
      await notifier.upsert(next);
      expect(ids(), ['full-nt', 'generated-trip', 'red-centre']);
      expect(routes()[1], same(next));
      await notifier.delete(next.id);
      await notifier.upsert(old);
      await notifier.undoDelete(next.id);
      expect(routes().first, same(old));
      expect(routes().where((route) => route.id == old.id), hasLength(1));
    },
  );
}
