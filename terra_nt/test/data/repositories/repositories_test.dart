import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terra_nt/core/util/sheet_snap.dart';
import 'package:terra_nt/core/util/stop_json.dart';
import 'package:terra_nt/data/models/auth_failure.dart';
import 'package:terra_nt/data/models/onboarding_answers.dart';
import 'package:terra_nt/data/models/saved_route.dart';
import 'package:terra_nt/data/repositories/auth_repository.dart';
import 'package:terra_nt/data/repositories/firestore_saved_routes.dart';
import 'package:terra_nt/data/repositories/itinerary_repository.dart';
import 'package:terra_nt/data/repositories/notifiers.dart';
import 'package:terra_nt/data/repositories/preferences_store.dart';
import 'package:terra_nt/data/seed/seed_data.dart';
import 'package:terra_nt/data/seed/onboarding_options.dart';

Future<PreferencesStore> _storeWithMockValues(
  Map<String, Object> values,
) async {
  SharedPreferences.setMockInitialValues(values);
  final preferences = await SharedPreferences.getInstance();
  return PreferencesStore(preferences: () async => preferences);
}

class _CountingPreferencesStore extends PreferencesStore {
  _CountingPreferencesStore({
    required super.preferences,
    super.pullRemote,
    super.pushRemote,
  });

  var saves = 0;

  @override
  Future<void> saveSavedRoutes(List<SavedRoute> routes, {String? uid}) {
    saves++;
    return super.saveSavedRoutes(routes, uid: uid);
  }
}

List<SavedRoute> _outdatedDemoRoutes() => [
  for (final route in seedSavedRoutes)
    savedRouteFromJson({
      ...savedRouteToJson(route),
      'stops': [
        for (final stop in route.stops)
          stopToJson(stop)
            ..['driveNext'] = switch (stop.name) {
              'Nitmiluk Gorge, Katherine' => '670 km · 7h to Alice Springs',
              'Kings Canyon' => '300 km · 3h to Uluru',
              _ => stop.driveNext,
            }
            ..['aiNote'] = stop.name == 'Nitmiluk Gorge, Katherine'
                ? 'An easy seven-hour drive.'
                : stop.aiNote,
      ],
    }),
];

/// Stands in for Firestore: records every pull and push, and throws when told.
class _RecordingRemote {
  _RecordingRemote({this.pulled, this.fail = false, List<String>? log})
    : log = log ?? [];

  final List<SavedRoute>? pulled;
  bool fail;
  final pulls = <String>[];
  final pushes = <(String, List<SavedRoute>)>[];

  /// Shared with the auth double so a test can assert call order.
  final List<String> log;

  Future<List<SavedRoute>?> pull(String uid) async {
    pulls.add(uid);
    if (fail) throw Exception('offline');
    return pulled;
  }

  Future<void> push(String uid, List<SavedRoute> routes) async {
    if (fail) throw Exception('offline');
    pushes.add((uid, routes));
    log.add('push');
  }
}

Future<PreferencesStore> _storeWithRemote(
  Map<String, Object> values,
  _RecordingRemote remote,
) async {
  SharedPreferences.setMockInitialValues(values);
  final preferences = await SharedPreferences.getInstance();
  return PreferencesStore(
    preferences: () async => preferences,
    pullRemote: remote.pull,
    pushRemote: remote.push,
  );
}

final _remoteRoute = SavedRoute(
  id: 'remote-trip',
  title: 'Remote trip',
  meta: '3 days · 2 stops',
  dateLabel: 'Generated today',
  stops: redCentreStops,
);

/// `authRepositoryProvider` defaults to Firebase, which needs an initialised
/// app; every test drives the seam's in-memory implementation instead.
ProviderContainer _container(
  PreferencesStore store,
  InMemoryAuthRepository authRepository,
) {
  final container = ProviderContainer(
    overrides: [
      preferencesStoreProvider.overrideWithValue(store),
      authRepositoryProvider.overrideWithValue(authRepository),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Records which seam member the notifier reached for, so a delete that merely
/// signs out cannot pass as a delete.
class _RecordingAuthRepository extends InMemoryAuthRepository {
  _RecordingAuthRepository({List<String>? log}) : log = log ?? [];

  final List<String> log;
  var deleteCalls = 0;
  var signOutCalls = 0;

  @override
  Future<void> deleteAccount() {
    deleteCalls += 1;
    log.add('deleteAccount');
    return super.deleteAccount();
  }

  @override
  Future<void> signOut() {
    signOutCalls += 1;
    return super.signOut();
  }
}

void _expectRoutesEqual(List<SavedRoute> actual, List<SavedRoute> expected) {
  expect(actual.length, expected.length);
  for (var index = 0; index < expected.length; index++) {
    expect(actual[index].id, expected[index].id);
    expect(actual[index].title, expected[index].title);
    expect(actual[index].meta, expected[index].meta);
    expect(actual[index].dateLabel, expected[index].dateLabel);
    expect(actual[index].days, expected[index].days);
    expect(
      actual[index].stops.map((stop) => stop.name),
      expected[index].stops.map((stop) => stop.name),
    );
  }
}

void main() {
  group('offline itinerary through the existing seam', () {
    final ItineraryRepository repository = SeedItineraryRepository();
    for (final region in regionOptions) {
      for (final start in tripLocationOptions) {
        for (final end in tripLocationOptions) {
          test(
            '${region.key}: $start to $end is a labelled offline suggestion',
            () {
              final itinerary = repository.offlineItineraryFor(
                OnboardingAnswers(
                  days: 5,
                  region: region.key,
                  startLocation: start,
                  endLocation: end,
                ),
              );
              expect(itinerary.title, 'Offline suggestion: $start to $end');
              expect(itinerary.stops, isNotEmpty);
              expect(itinerary.stops.first.name, start);
              expect(itinerary.stops.last.name, end);
              expect(itinerary.days, 5);
            },
          );
        }
      }
    }
  });

  group('PreferencesStore', () {
    for (final fromRemote in [false, true]) {
      test('refreshes old ${fromRemote ? 'remote' : 'local'} demo copies '
          'in one local-first save and does not save again', () async {
        final old = _outdatedDemoRoutes();
        SharedPreferences.setMockInitialValues({
          if (!fromRemote)
            PreferencesStore.savedRoutesKey: jsonEncode(
              old.map(savedRouteToJson).toList(),
            ),
          PreferencesStore.onboardingDoneKey: true,
        });
        final preferences = await SharedPreferences.getInstance();
        var pulls = 0;
        final pushed = <List<SavedRoute>>[];
        final store = _CountingPreferencesStore(
          preferences: () async => preferences,
          pullRemote: (uid) async {
            expect(uid, 'traveller');
            pulls++;
            return old;
          },
          pushRemote: (uid, routes) async {
            expect(uid, 'traveller');
            expect(
              jsonDecode(
                preferences.getString(PreferencesStore.savedRoutesKey)!,
              ),
              routes.map(savedRouteToJson).toList(),
            );
            pushed.add(routes);
          },
        );

        final loaded = await store.readSavedRoutes(uid: 'traveller');
        expect(
          loaded.map(savedRouteToJson).toList(),
          seedSavedRoutes.map(savedRouteToJson).toList(),
        );
        expect(pulls, fromRemote ? 1 : 0);
        expect(store.saves, 1);
        expect(pushed, hasLength(1));
        expect(
          pushed.single.map(savedRouteToJson).toList(),
          loaded.map(savedRouteToJson).toList(),
        );
        final encoded = preferences.getString(PreferencesStore.savedRoutesKey);
        await store.readSavedRoutes(uid: 'traveller');
        expect(store.saves, 1);
        expect(pushed, hasLength(1));
        expect(preferences.getString(PreferencesStore.savedRoutesKey), encoded);
        expect(
          preferences.getKeys(),
          unorderedEquals([
            PreferencesStore.savedRoutesKey,
            PreferencesStore.onboardingDoneKey,
          ]),
        );
      });
    }

    test(
      'unchanged, empty and malformed local values cause no write or push',
      () async {
        for (final encoded in [
          jsonEncode(seedSavedRoutes.map(savedRouteToJson).toList()),
          '[]',
          '{not json',
          '[{"id":"full-nt"}]',
        ]) {
          SharedPreferences.setMockInitialValues({
            PreferencesStore.savedRoutesKey: encoded,
          });
          final preferences = await SharedPreferences.getInstance();
          final remote = _RecordingRemote(pulled: _outdatedDemoRoutes());
          final store = _CountingPreferencesStore(
            preferences: () async => preferences,
            pullRemote: remote.pull,
            pushRemote: remote.push,
          );
          final loaded = await store.readSavedRoutes(uid: 'traveller');
          expect(
            loaded.map(savedRouteToJson).toList(),
            encoded == '[]'
                ? []
                : seedSavedRoutes.map(savedRouteToJson).toList(),
          );
          expect(store.saves, 0);
          expect(remote.pulls, isEmpty);
          expect(remote.pushes, isEmpty);
          expect(
            preferences.getString(PreferencesStore.savedRoutesKey),
            encoded,
          );
        }
      },
    );

    test('signed-out refresh writes locally without a remote push', () async {
      final old = _outdatedDemoRoutes();
      final remote = _RecordingRemote();
      final store = await _storeWithRemote({
        PreferencesStore.savedRoutesKey: jsonEncode(
          old.map(savedRouteToJson).toList(),
        ),
      }, remote);
      final loaded = await store.readSavedRoutes();
      expect(
        loaded.map(savedRouteToJson).toList(),
        seedSavedRoutes.map(savedRouteToJson).toList(),
      );
      expect(remote.pushes, isEmpty);
      final preferences = await SharedPreferences.getInstance();
      expect(
        jsonDecode(preferences.getString(PreferencesStore.savedRoutesKey)!),
        loaded.map(savedRouteToJson).toList(),
      );
    });

    test(
      'a refused migration push leaves corrected facts saved locally',
      () async {
        final old = _outdatedDemoRoutes();
        final remote = _RecordingRemote(fail: true);
        final store = await _storeWithRemote({
          PreferencesStore.savedRoutesKey: jsonEncode(
            old.map(savedRouteToJson).toList(),
          ),
        }, remote);
        final loaded = await store.readSavedRoutes(uid: 'traveller');
        expect(
          loaded.map(savedRouteToJson).toList(),
          seedSavedRoutes.map(savedRouteToJson).toList(),
        );
        expect(
          (await store.readSavedRoutes()).map(savedRouteToJson).toList(),
          loaded.map(savedRouteToJson).toList(),
        );
      },
    );

    test('round-trips saved routes with their stops as JSON', () async {
      final store = await _storeWithMockValues({});
      final routes = [
        SavedRoute(
          id: 'custom',
          title: 'Custom trip',
          meta: '3 days · 2 stops',
          dateLabel: 'Generated today',
          stops: redCentreStops,
          days: 3,
        ),
      ];

      await store.saveSavedRoutes(routes);

      final read = await store.readSavedRoutes();
      _expectRoutesEqual(read, routes);
      expect(read.single.stops[1].lat, redCentreStops[1].lat);
      expect(read.single.stops[1].fee, redCentreStops[1].fee);
      expect(read.single.stops.last.driveNext, isNull);
    });

    test('an entry without stops falls back to the seed', () async {
      final store = await _storeWithMockValues({
        PreferencesStore.savedRoutesKey: jsonEncode([
          {
            'id': 'old',
            'title': 'Old trip',
            'meta': '1 day · 1 stop',
            'dateLabel': 'Generated today',
          },
        ]),
      });

      _expectRoutesEqual(await store.readSavedRoutes(), seedSavedRoutes);
    });

    test(
      'a stored route without days survives loading, opening and saving',
      () async {
        final json = savedRouteToJson(seedSavedRoutes.last)
          ..remove('days')
          ..['id'] = 'old-custom-route'
          ..['title'] = 'My old trip'
          ..['meta'] = 'A week away · 4 places';
        final encoded = jsonEncode([json]);
        final remote = _RecordingRemote(pulled: seedSavedRoutes);
        final store = await _storeWithRemote({
          PreferencesStore.savedRoutesKey: encoded,
        }, remote);
        final container = _container(store, InMemoryAuthRepository());
        final notifier = container.read(savedRoutesNotifierProvider.notifier);
        await notifier.load();
        final route = container.read(savedRoutesNotifierProvider).single;
        expect(route.id, 'old-custom-route');
        expect(route.title, 'My old trip');
        expect(route.days, isNull);
        expect(route.meta, 'A week away · 4 places');
        expect(route.dateLabel, seedSavedRoutes.last.dateLabel);
        expect(remote.pulls, isEmpty);
        final itineraryNotifier = container.read(
          itineraryNotifierProvider.notifier,
        );
        itineraryNotifier.openSavedRoute(route);
        final itinerary = container.read(itineraryNotifierProvider).itinerary;
        expect(itinerary.days, isNull);
        expect(itinerary.storedMeta, route.meta);
        expect(itinerary.stops, same(route.stops));
        await store.saveSavedRoutes([route], uid: 'traveller');
        expect(
          jsonEncode(savedRouteToJson((await store.readSavedRoutes()).single)),
          jsonEncode(json),
        );
        expect(
          jsonEncode(savedRouteToJson(remote.pushes.single.$2.single)),
          jsonEncode(json),
        );
      },
    );

    test(
      'a literal empty legacy list stays empty through loading and saving',
      () async {
        final store = await _storeWithMockValues({
          PreferencesStore.savedRoutesKey: '[]',
        });
        final container = _container(store, InMemoryAuthRepository());
        await container.read(savedRoutesNotifierProvider.notifier).load();
        expect(container.read(savedRoutesNotifierProvider), isEmpty);
        await store.saveSavedRoutes(
          container.read(savedRoutesNotifierProvider),
        );
        expect(await store.readSavedRoutes(), isEmpty);
      },
    );

    test('uses seeded routes for absent or corrupt saved-routes JSON', () async {
      final absentStore = await _storeWithMockValues({});
      _expectRoutesEqual(await absentStore.readSavedRoutes(), seedSavedRoutes);

      final corruptStore = await _storeWithMockValues({
        PreferencesStore.savedRoutesKey: '{not json',
      });
      _expectRoutesEqual(await corruptStore.readSavedRoutes(), seedSavedRoutes);
    });

    test('keeps an explicitly persisted empty saved-routes list empty', () async {
      final store = await _storeWithMockValues({});

      await store.saveSavedRoutes(const []);

      expect(await store.readSavedRoutes(), isEmpty);
    });

    test('round-trips the onboarding flag', () async {
      final store = await _storeWithMockValues({});
      expect(await store.readOnboardingDone(), isFalse);

      await store.saveOnboardingDone(true);
      expect(await store.readOnboardingDone(), isTrue);

      await store.saveOnboardingDone(false);
      expect(await store.readOnboardingDone(), isFalse);
    });

    test('absent key + remote list: adopted and written locally', () async {
      final remote = _RecordingRemote(pulled: [_remoteRoute]);
      final store = await _storeWithRemote({}, remote);

      final read = await store.readSavedRoutes(uid: 'uid-a');

      _expectRoutesEqual(read, [_remoteRoute]);
      expect(remote.pulls, ['uid-a']);
      expect(remote.pushes, isEmpty);
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString(PreferencesStore.savedRoutesKey), isNotNull);
      _expectRoutesEqual(await store.readSavedRoutes(), [_remoteRoute]);
    });

    test('absent key + remote null: seed, nothing written', () async {
      final remote = _RecordingRemote();
      final store = await _storeWithRemote({}, remote);

      _expectRoutesEqual(
        await store.readSavedRoutes(uid: 'uid-a'),
        seedSavedRoutes,
      );
      expect(remote.pulls, ['uid-a']);
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getKeys(), isEmpty);
    });

    test('absent key without a uid never asks the remote', () async {
      final remote = _RecordingRemote(pulled: [_remoteRoute]);
      final store = await _storeWithRemote({}, remote);

      _expectRoutesEqual(await store.readSavedRoutes(), seedSavedRoutes);
      expect(remote.pulls, isEmpty);
    });

    test('present key + remote list: local wins', () async {
      final local = [seedSavedRoutes.last];
      final remote = _RecordingRemote(pulled: [_remoteRoute]);
      final store = await _storeWithRemote({
        PreferencesStore.savedRoutesKey: jsonEncode(
          local.map(savedRouteToJson).toList(),
        ),
      }, remote);

      _expectRoutesEqual(await store.readSavedRoutes(uid: 'uid-a'), local);
    });

    test('present empty list + remote list: stays empty', () async {
      final remote = _RecordingRemote(pulled: [_remoteRoute]);
      final store = await _storeWithRemote({
        PreferencesStore.savedRoutesKey: '[]',
      }, remote);

      expect(await store.readSavedRoutes(uid: 'uid-a'), isEmpty);
    });

    test('remote throws: local result, no throw', () async {
      final remote = _RecordingRemote(pulled: [_remoteRoute], fail: true);
      final store = await _storeWithRemote({}, remote);

      _expectRoutesEqual(
        await store.readSavedRoutes(uid: 'uid-a'),
        seedSavedRoutes,
      );
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getKeys(), isEmpty);
    });

    test('save pushes the list it wrote locally, only with a uid', () async {
      final remote = _RecordingRemote();
      final store = await _storeWithRemote({}, remote);
      final routes = [_remoteRoute, seedSavedRoutes.first];

      await store.saveSavedRoutes(routes);
      expect(remote.pushes, isEmpty);

      await store.saveSavedRoutes(routes, uid: 'uid-a');
      expect(remote.pushes, hasLength(1));
      expect(remote.pushes.single.$1, 'uid-a');
      _expectRoutesEqual(remote.pushes.single.$2, routes);
      _expectRoutesEqual(await store.readSavedRoutes(), routes);
    });

    test('a failed push is swallowed after the local write', () async {
      final remote = _RecordingRemote(fail: true);
      final store = await _storeWithRemote({}, remote);

      await store.saveSavedRoutes([_remoteRoute], uid: 'uid-a');

      _expectRoutesEqual(await store.readSavedRoutes(), [_remoteRoute]);
    });

    test(
      'save returns with its local key while the cloud never acknowledges',
      () async {
        SharedPreferences.setMockInitialValues({});
        final preferences = await SharedPreferences.getInstance();
        final started = Completer<void>();
        final never = Completer<void>();
        final store = PreferencesStore(
          preferences: () async => preferences,
          pushRemote: (uid, routes) {
            expect(uid, 'uid-a');
            _expectRoutesEqual(routes, [_remoteRoute]);
            started.complete();
            return never.future;
          },
        );

        await store
            .saveSavedRoutes([_remoteRoute], uid: 'uid-a')
            .timeout(const Duration(seconds: 1));
        await started.future;
        expect(never.isCompleted, isFalse);
        final encoded = preferences.getString(PreferencesStore.savedRoutesKey)!;
        expect(jsonDecode(encoded).single['id'], 'remote-trip');
        _expectRoutesEqual(await store.readSavedRoutes(), [_remoteRoute]);
      },
    );

    test(
      'synchronous remote throws also stay out of the save caller',
      () async {
        SharedPreferences.setMockInitialValues({});
        final store = PreferencesStore(
          pushRemote: (_, _) => throw StateError('refused'),
        );
        await store.saveSavedRoutes([_remoteRoute], uid: 'uid-a');
        _expectRoutesEqual(await store.readSavedRoutes(), [_remoteRoute]);
      },
    );

    test(
      'every save starts without an acknowledgement and a clear waits for them',
      () async {
        SharedPreferences.setMockInitialValues({});
        final firstAck = Completer<void>();
        final pushed = <List<SavedRoute>>[];
        final store = PreferencesStore(
          pushRemote: (_, routes) {
            pushed.add(routes);
            return pushed.length == 1 ? firstAck.future : Future<void>.value();
          },
        );
        final first = [_remoteRoute];
        await store.saveSavedRoutes(first, uid: 'uid-a');
        first.clear();
        await store.saveSavedRoutes(seedSavedRoutes, uid: 'uid-a');
        var cleared = false;
        final clear = store.clearRemote('uid-a').then((_) => cleared = true);
        await Future<void>.delayed(Duration.zero);
        expect(pushed, hasLength(2));
        expect(pushed.first.single.id, 'remote-trip');
        expect(cleared, isFalse);

        firstAck.complete();
        await clear;
        expect(pushed, hasLength(3));
        _expectRoutesEqual(pushed[1], seedSavedRoutes);
        expect(pushed.last, isEmpty);
        expect(cleared, isTrue);
      },
    );

    test('clearRemote pushes an empty list and propagates failure', () async {
      final remote = _RecordingRemote();
      final store = await _storeWithRemote({}, remote);

      await store.clearRemote('uid-a');
      expect(remote.pushes.single.$1, 'uid-a');
      expect(remote.pushes.single.$2, isEmpty);

      remote.fail = true;
      await expectLater(store.clearRemote('uid-a'), throwsException);
    });

    test('declares exactly two keys', () {
      expect(PreferencesStore.savedRoutesKey, 'terra_nt.saved_routes');
      expect(PreferencesStore.onboardingDoneKey, 'terra_nt.onboarding_done');
    });
  });

  group('Firestore push sequence through I/O closures', () {
    test('an older server cleanup cannot delete a newer route', () async {
      var current = true;
      final requestedServer = Completer<void>();
      final server = Completer<Set<String>>();
      final writes = <Set<String>>[];
      final push = synchronizeSavedRoutes(
        [_remoteRoute],
        isCurrent: () => current,
        readIds: ({required fromCache}) {
          if (fromCache) return Future.value(<String>{});
          requestedServer.complete();
          return server.future;
        },
        write: (routes, deleted) async => writes.add(deleted),
      );
      await requestedServer.future;
      current = false;
      server.complete({'remote-trip', 'newer-trip'});
      await push;
      expect(writes, [
        <String>{},
      ], reason: 'the superseded cleanup must not delete newer-trip');
    });

    test('an older cache read cannot overwrite a newer save', () async {
      final cache = Completer<Set<String>>();
      var current = true;
      final push = synchronizeSavedRoutes(
        [_remoteRoute],
        isCurrent: () => current,
        readIds: ({required fromCache}) {
          expect(fromCache, isTrue);
          return cache.future;
        },
        write: (_, _) async => fail('a newer push already owns this snapshot'),
      );
      current = false;
      cache.complete({'old'});
      await push;
    });

    test(
      'queues a write without a server read, then removes uncached stale docs',
      () async {
        final acknowledgement = Completer<void>();
        final queued = Completer<void>();
        final reads = <bool>[];
        final writes = <(List<SavedRoute>, Set<String>)>[];
        final push = synchronizeSavedRoutes(
          [_remoteRoute],
          readIds: ({required fromCache}) async {
            reads.add(fromCache);
            return fromCache ? {'cached-old'} : {'remote-trip', 'uncached-old'};
          },
          write: (routes, deleted) {
            writes.add((routes, deleted));
            if (writes.length == 1) {
              queued.complete();
              return acknowledgement.future;
            }
            return Future<void>.value();
          },
        );
        await queued.future;
        expect(reads, [
          true,
        ], reason: 'no server read can delay the first write');
        expect(writes.single.$1.single.id, 'remote-trip');
        expect(writes.single.$2, {'cached-old'});
        acknowledgement.complete();
        await push;
        expect(reads, [true, false]);
        expect(writes.last.$1, isEmpty);
        expect(writes.last.$2, {'uncached-old'});
      },
    );

    test(
      'empty clear waits for deletion of uncached docs and propagates refusal',
      () async {
        final deletion = Completer<void>();
        final started = Completer<void>();
        final push = synchronizeSavedRoutes(
          const [],
          readIds: ({required fromCache}) async => fromCache ? {} : {'old'},
          write: (routes, deleted) {
            expect(routes, isEmpty);
            if (deleted.isEmpty) return Future<void>.value();
            expect(deleted, {'old'});
            started.complete();
            return deletion.future;
          },
        );
        final failure = expectLater(push, throwsStateError);
        await started.future;
        deletion.completeError(StateError('server refused clear'));
        await failure;
      },
    );
  });

  group('repositories', () {
    test('seed itinerary repository returns the full NT route', () async {
      final repository = SeedItineraryRepository();

      final standard = await repository.itineraryFor(const OnboardingAnswers());

      expect(standard.stops.length, 7);
      expect(standard.title, 'Full NT: Darwin to Uluru');
    });

    test('in-memory currentUid and idToken follow the signed-in email', () async {
      final repository = InMemoryAuthRepository();
      expect(await repository.currentUid(), isNull);
      expect(await repository.idToken(), isNull);

      final session = await repository.signInWithEmail(
        'traveller@example.com',
        'secret',
      );
      expect(session.uid, 'uid-traveller@example.com');
      expect(await repository.currentUid(), 'uid-traveller@example.com');
      expect(await repository.idToken(), 'test-token');

      await repository.signOut();
      expect(await repository.currentUid(), isNull);
      expect(await repository.idToken(), isNull);
    });

    test('in-memory sendPasswordReset records the email and honours nextFailure', () async {
      final repository = InMemoryAuthRepository();

      await repository.sendPasswordReset('traveller@example.com');
      expect(repository.lastResetEmail, 'traveller@example.com');

      repository.nextFailure = AuthFailure.network;
      await expectLater(
        repository.sendPasswordReset('second@example.com'),
        throwsA(
          isA<AuthException>().having(
            (error) => error.failure,
            'failure',
            AuthFailure.network,
          ),
        ),
      );
      expect(repository.lastResetEmail, 'traveller@example.com');
      expect(repository.nextFailure, isNull);
    });

    test('in-memory sendEmailVerification counts sends and honours nextFailure', () async {
      final repository = InMemoryAuthRepository();
      await repository.signInWithEmail('traveller@example.com', 'secret');

      await repository.sendEmailVerification();
      expect(repository.verificationEmailsSent, 1);

      repository.nextFailure = AuthFailure.network;
      await expectLater(
        repository.sendEmailVerification(),
        throwsA(isA<AuthException>()),
      );
      expect(repository.verificationEmailsSent, 1);
    });

    test('in-memory isEmailVerified answers the public flag', () async {
      final repository = InMemoryAuthRepository();
      expect(await repository.isEmailVerified(), isFalse);

      repository.emailVerified = true;
      expect(await repository.isEmailVerified(), isTrue);
    });

    test('Google mock uses the email sign-in path without network work', () async {
      final repository = InMemoryAuthRepository();

      final googleSession = await repository.signInWithGoogle();
      final emailSession = await repository.signInWithEmail(
        'explorer@example.com',
        'any-password',
      );

      expect(googleSession.email, emailSession.email);
      expect(googleSession.onboardingDone, emailSession.onboardingDone);
    });

    test('in-memory currentEmail follows the last successful sign-in', () async {
      final repository = InMemoryAuthRepository();
      expect(await repository.currentEmail(), isNull);

      await repository.signInWithEmail('traveller@example.com', 'secret');
      expect(await repository.currentEmail(), 'traveller@example.com');

      await repository.signOut();
      expect(await repository.currentEmail(), isNull);

      await repository.createAccount('second@example.com', 'secret');
      expect(await repository.currentEmail(), 'second@example.com');

      await repository.deleteAccount();
      expect(await repository.currentEmail(), isNull);
    });

    test('nextFailure throws once and then clears itself', () async {
      final repository = InMemoryAuthRepository();
      repository.nextFailure = AuthFailure.invalidCredential;

      await expectLater(
        repository.signInWithEmail('traveller@example.com', 'wrong'),
        throwsA(
          isA<AuthException>().having(
            (error) => error.failure,
            'failure',
            AuthFailure.invalidCredential,
          ),
        ),
      );
      expect(repository.nextFailure, isNull);
      expect(await repository.currentEmail(), isNull);

      final session = await repository.signInWithEmail(
        'traveller@example.com',
        'secret',
      );
      expect(session.email, 'traveller@example.com');
    });

    test('nextFailure refuses a delete without clearing the account', () async {
      final repository = InMemoryAuthRepository();
      await repository.signInWithEmail('traveller@example.com', 'secret');
      repository.nextFailure = AuthFailure.requiresRecentLogin;

      await expectLater(
        repository.deleteAccount(),
        throwsA(
          isA<AuthException>().having(
            (error) => error.failure,
            'failure',
            AuthFailure.requiresRecentLogin,
          ),
        ),
      );
      expect(await repository.currentEmail(), 'traveller@example.com');
    });
  });

  group('notifiers', () {
    test('upsert inserts new routes first and replaces existing routes in place', () async {
      final store = await _storeWithMockValues({});
      final container = ProviderContainer(
        overrides: [preferencesStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(savedRoutesNotifierProvider.notifier);
      await notifier.load();

      await notifier.upsert(
        const SavedRoute(
          id: 'generated-trip',
          title: 'Generated trip',
          meta: '7 days · 7 stops',
          dateLabel: 'Generated just now',
          stops: seedStops,
        ),
      );
      expect(container.read(savedRoutesNotifierProvider).first.id, 'generated-trip');

      await notifier.upsert(
        const SavedRoute(
          id: 'full-nt',
          title: 'Updated full trip',
          meta: '9 days · 7 stops',
          dateLabel: 'Generated today',
          stops: seedStops,
        ),
      );
      final routes = container.read(savedRoutesNotifierProvider);
      expect(routes.length, 3);
      expect(routes[1].id, 'full-nt');
      expect(routes[1].title, 'Updated full trip');
    });

    test('session-only notifier mutations create no preferences keys', () async {
      final store = await _storeWithMockValues({});
      final container = ProviderContainer(
        overrides: [preferencesStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);

      final itinerary = container.read(itineraryNotifierProvider.notifier);
      itinerary.reorder(0, 1);
      itinerary.toggleSkipped(0);
      itinerary.setEditMode(true);
      final profile = container.read(profileNotifierProvider.notifier);
      profile.showDeleteAccountConfirmation();
      profile.startDeleteAccount();
      profile.failDeleteAccount('No connection.');
      profile.cancelDeleteAccount();
      container.read(onboardingNotifierProvider.notifier).setStep(3);

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getKeys(), isEmpty);
    });

    test('a full signed-in round trip persists no third key', () async {
      final store = await _storeWithMockValues({});
      final container = _container(store, InMemoryAuthRepository());
      final sessionNotifier = container.read(sessionNotifierProvider.notifier);

      await sessionNotifier.signInWithEmail('traveller@example.com', 'secret');
      await sessionNotifier.setOnboardingDone(true);
      final itinerary = container.read(itineraryNotifierProvider.notifier);
      itinerary.reorder(0, 1);
      itinerary.toggleSkipped(0);
      itinerary.setEditMode(true);
      final profile = container.read(profileNotifierProvider.notifier);
      profile.showDeleteAccountConfirmation();
      profile.startDeleteAccount();
      profile.failDeleteAccount('No connection.');
      profile.cancelDeleteAccount();
      // The Result sheet's height is widget-local state in `ResultScreen`, so
      // there is no notifier for it to persist through; `nearestSnap` is pure.
      expect(nearestSnap(420), 430);
      await sessionNotifier.signOut();
      await container.read(savedRoutesNotifierProvider.notifier).load();

      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getKeys(),
        unorderedEquals([PreferencesStore.onboardingDoneKey]),
      );
      await container.read(savedRoutesNotifierProvider.notifier).delete('full-nt');
      expect(
        preferences.getKeys(),
        unorderedEquals([
          PreferencesStore.savedRoutesKey,
          PreferencesStore.onboardingDoneKey,
        ]),
      );
    });

    test('delete account deletes on the seam, log out only signs out', () async {
      final store = await _storeWithMockValues({});
      final authRepository = _RecordingAuthRepository();
      final container = _container(store, authRepository);
      final sessionNotifier = container.read(sessionNotifierProvider.notifier);
      await sessionNotifier.signInWithEmail('traveller@example.com', 'secret');

      await sessionNotifier.signOut();
      expect(authRepository.signOutCalls, 1);
      expect(authRepository.deleteCalls, 0);

      await sessionNotifier.signInWithEmail('traveller@example.com', 'secret');
      await sessionNotifier.deleteAccount();
      expect(authRepository.deleteCalls, 1);
      expect(authRepository.signOutCalls, 1);
    });

    test('a refused delete leaves session, flag and routes untouched', () async {
      final store = await _storeWithMockValues({});
      final authRepository = InMemoryAuthRepository();
      final container = _container(store, authRepository);
      final sessionNotifier = container.read(sessionNotifierProvider.notifier);
      await sessionNotifier.signInWithEmail('traveller@example.com', 'secret');
      await sessionNotifier.setOnboardingDone(true);
      await container.read(savedRoutesNotifierProvider.notifier).load();
      authRepository.nextFailure = AuthFailure.requiresRecentLogin;

      await expectLater(
        sessionNotifier.deleteAccount(),
        throwsA(
          isA<AuthException>().having(
            (error) => error.failure,
            'failure',
            AuthFailure.requiresRecentLogin,
          ),
        ),
      );

      expect(
        container.read(sessionNotifierProvider).email,
        'traveller@example.com',
      );
      expect(container.read(sessionNotifierProvider).onboardingDone, isTrue);
      expect(await store.readOnboardingDone(), isTrue);
      _expectRoutesEqual(
        container.read(savedRoutesNotifierProvider),
        seedSavedRoutes,
      );
    });

    test('an uncleared remote blocks delete account as a network failure', () async {
      final remote = _RecordingRemote();
      final store = await _storeWithRemote({}, remote);
      final authRepository = _RecordingAuthRepository();
      final container = _container(store, authRepository);
      final sessionNotifier = container.read(sessionNotifierProvider.notifier);
      final routesNotifier = container.read(savedRoutesNotifierProvider.notifier);
      await sessionNotifier.signInWithEmail('traveller@example.com', 'secret');
      await sessionNotifier.setOnboardingDone(true);
      await routesNotifier.load();
      await routesNotifier.upsert(_remoteRoute);
      final routesBefore = container.read(savedRoutesNotifierProvider);
      remote.fail = true;

      await expectLater(
        sessionNotifier.deleteAccount(),
        throwsA(
          isA<AuthException>().having(
            (error) => error.failure,
            'failure',
            AuthFailure.network,
          ),
        ),
      );

      expect(authRepository.deleteCalls, 0);
      expect(
        container.read(sessionNotifierProvider).email,
        'traveller@example.com',
      );
      expect(container.read(sessionNotifierProvider).onboardingDone, isTrue);
      expect(await store.readOnboardingDone(), isTrue);
      _expectRoutesEqual(container.read(savedRoutesNotifierProvider), routesBefore);
      _expectRoutesEqual(await store.readSavedRoutes(), routesBefore);
    });

    test('delete account clears the remote, then the seam, then local state', () async {
      final log = <String>[];
      final remote = _RecordingRemote(log: log);
      final store = await _storeWithRemote({}, remote);
      final authRepository = _RecordingAuthRepository(log: log);
      final container = _container(store, authRepository);
      final sessionNotifier = container.read(sessionNotifierProvider.notifier);
      final routesNotifier = container.read(savedRoutesNotifierProvider.notifier);
      await sessionNotifier.signInWithEmail('traveller@example.com', 'secret');
      await sessionNotifier.setOnboardingDone(true);
      await routesNotifier.load();
      await routesNotifier.upsert(_remoteRoute);
      log.clear();
      remote.pushes.clear();

      await sessionNotifier.deleteAccount();

      expect(log, ['push', 'deleteAccount']);
      expect(authRepository.deleteCalls, 1);
      expect(remote.pushes.single.$1, 'uid-traveller@example.com');
      expect(remote.pushes.single.$2, isEmpty);
      expect(container.read(sessionNotifierProvider).email, isNull);
      expect(container.read(sessionNotifierProvider).uid, isNull);
      expect(container.read(sessionNotifierProvider).onboardingDone, isFalse);
      expect(await store.readOnboardingDone(), isFalse);
      expect(container.read(savedRoutesNotifierProvider), isEmpty);
      expect(await store.readSavedRoutes(), isEmpty);
      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getKeys(),
        unorderedEquals([
          PreferencesStore.savedRoutesKey,
          PreferencesStore.onboardingDoneKey,
        ]),
      );
    });

    test('saved-route mutations push under the signed-in uid', () async {
      final remote = _RecordingRemote(pulled: [_remoteRoute]);
      final store = await _storeWithRemote({}, remote);
      final container = _container(store, InMemoryAuthRepository());
      final sessionNotifier = container.read(sessionNotifierProvider.notifier);
      final routesNotifier = container.read(savedRoutesNotifierProvider.notifier);

      await routesNotifier.load();
      expect(remote.pulls, isEmpty);

      await sessionNotifier.signInWithEmail('traveller@example.com', 'secret');
      await routesNotifier.load();
      expect(remote.pulls, ['uid-traveller@example.com']);
      _expectRoutesEqual(container.read(savedRoutesNotifierProvider), [
        _remoteRoute,
      ]);

      await routesNotifier.upsert(seedSavedRoutes.first);
      await routesNotifier.delete('remote-trip');
      expect(remote.pushes.map((push) => push.$1), [
        'uid-traveller@example.com',
        'uid-traveller@example.com',
      ]);
      _expectRoutesEqual(remote.pushes.last.$2, [seedSavedRoutes.first]);
    });

    test('a refused sign-in leaves the state signed out and rethrows', () async {
      final store = await _storeWithMockValues({});
      final authRepository = InMemoryAuthRepository();
      final container = _container(store, authRepository);
      final sessionNotifier = container.read(sessionNotifierProvider.notifier);
      authRepository.nextFailure = AuthFailure.invalidCredential;

      await expectLater(
        sessionNotifier.signInWithEmail('traveller@example.com', 'wrong'),
        throwsA(
          isA<AuthException>().having(
            (error) => error.failure,
            'failure',
            AuthFailure.invalidCredential,
          ),
        ),
      );

      expect(container.read(sessionNotifierProvider).email, isNull);
      expect(await authRepository.currentEmail(), isNull);
    });

    test('load reads the signed-in email from the seam, not preferences', () async {
      final store = await _storeWithMockValues({
        PreferencesStore.onboardingDoneKey: true,
      });
      final authRepository = InMemoryAuthRepository();
      await authRepository.signInWithEmail('returning@example.com', 'secret');
      final container = _container(store, authRepository);

      await container.read(sessionNotifierProvider.notifier).load();

      final session = container.read(sessionNotifierProvider);
      expect(session.email, 'returning@example.com');
      expect(session.uid, 'uid-returning@example.com');
      expect(session.onboardingDone, isTrue);
    });

    test('delete account clears routes permanently and resets onboarding', () async {
      final store = await _storeWithMockValues({});
      final container = _container(store, InMemoryAuthRepository());
      final sessionNotifier = container.read(sessionNotifierProvider.notifier);
      final routesNotifier = container.read(savedRoutesNotifierProvider.notifier);
      await sessionNotifier.signInWithEmail('traveller@example.com', 'password');
      await sessionNotifier.setOnboardingDone(true);
      await routesNotifier.load();

      await sessionNotifier.deleteAccount();

      expect(container.read(sessionNotifierProvider).email, isNull);
      expect(container.read(sessionNotifierProvider).onboardingDone, isFalse);
      expect(container.read(savedRoutesNotifierProvider), isEmpty);
      expect(await store.readSavedRoutes(), isEmpty);
    });

    test('log out retains saved routes and onboarding state', () async {
      final store = await _storeWithMockValues({});
      final container = _container(store, InMemoryAuthRepository());
      final sessionNotifier = container.read(sessionNotifierProvider.notifier);
      final routesNotifier = container.read(savedRoutesNotifierProvider.notifier);
      await sessionNotifier.signInWithEmail('traveller@example.com', 'password');
      await sessionNotifier.setOnboardingDone(true);
      await routesNotifier.load();
      final routesBeforeLogout = container.read(savedRoutesNotifierProvider);

      await sessionNotifier.signOut();

      expect(container.read(sessionNotifierProvider).email, isNull);
      expect(container.read(sessionNotifierProvider).onboardingDone, isTrue);
      _expectRoutesEqual(
        container.read(savedRoutesNotifierProvider),
        routesBeforeLogout,
      );
    });

    test('all notifier state is usable from a bare ProviderContainer', () async {
      final store = await _storeWithMockValues({});
      final container = ProviderContainer(
        overrides: [preferencesStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);

      container.read(onboardingNotifierProvider.notifier).setAnswers(
            const OnboardingAnswers(days: 5),
          );
      await container.read(itineraryNotifierProvider.notifier).loadForAnswers(
            container.read(onboardingNotifierProvider).answers,
          );
      expect(container.read(itineraryNotifierProvider).itinerary.days, 5);
      container.read(exploreNotifierProvider.notifier).selectPoi('ubirr');
      container
          .read(profileNotifierProvider.notifier)
          .showDeleteAccountConfirmation();

      expect(container.read(onboardingNotifierProvider).answers.days, 5);
      expect(container.read(itineraryNotifierProvider).order.length, 7);
      expect(container.read(exploreNotifierProvider).selectedPoiId, 'ubirr');
      expect(
        container.read(profileNotifierProvider).deleteAccountConfirmation,
        isTrue,
      );
    });

    test('toggleSkipped round-trips: a second call on the same stop unskips it', () async {
      final store = await _storeWithMockValues({});
      final container = ProviderContainer(
        overrides: [preferencesStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);

      final itinerary = container.read(itineraryNotifierProvider.notifier);
      itinerary.toggleSkipped(2);
      expect(container.read(itineraryNotifierProvider).skipped, {2});

      itinerary.toggleSkipped(2);
      expect(container.read(itineraryNotifierProvider).skipped, isEmpty);
    });

    test('preferencesStoreProvider wires Firestore pull/push closures that '
        'swallow failure without an initialised app', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final store = container.read(preferencesStoreProvider);

      final routes = await store.readSavedRoutes(uid: 'traveller-1');
      await store.saveSavedRoutes(routes, uid: 'traveller-1');

      _expectRoutesEqual(routes, seedSavedRoutes);
    });

    test('authRepositoryProvider builds the Firebase-backed repository', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(() => container.read(authRepositoryProvider), throwsA(anything));
    });
  });

  group('ExploreState', () {
    test('copyWith overrides the selected POI and search query', () {
      const state = ExploreState(selectedPoiId: 'ubirr', searchQuery: 'water');

      final updated = state.copyWith(
        selectedPoiId: 'mindil',
        searchQuery: 'market',
      );

      expect(updated.selectedPoiId, 'mindil');
      expect(updated.searchQuery, 'market');
    });

    test('copyWith with no arguments keeps the current values', () {
      const state = ExploreState(selectedPoiId: 'ubirr', searchQuery: 'water');

      final updated = state.copyWith();

      expect(updated.selectedPoiId, 'ubirr');
      expect(updated.searchQuery, 'water');
    });
  });

  test('saved-route JSON is stored as a list, not an opaque preference type', () async {
    final store = await _storeWithMockValues({});
    await store.saveSavedRoutes(seedSavedRoutes);
    final preferences = await SharedPreferences.getInstance();
    final decoded = jsonDecode(preferences.getString(PreferencesStore.savedRoutesKey)!);

    expect(decoded, isA<List<dynamic>>());
  });
}
