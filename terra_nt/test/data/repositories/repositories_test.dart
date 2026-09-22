import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terra_nt/core/util/sheet_snap.dart';
import 'package:terra_nt/data/models/auth_failure.dart';
import 'package:terra_nt/data/models/onboarding_answers.dart';
import 'package:terra_nt/data/models/saved_route.dart';
import 'package:terra_nt/data/repositories/auth_repository.dart';
import 'package:terra_nt/data/repositories/itinerary_repository.dart';
import 'package:terra_nt/data/repositories/notifiers.dart';
import 'package:terra_nt/data/repositories/preferences_store.dart';
import 'package:terra_nt/data/seed/seed_data.dart';

Future<PreferencesStore> _storeWithMockValues(
  Map<String, Object> values,
) async {
  SharedPreferences.setMockInitialValues(values);
  final preferences = await SharedPreferences.getInstance();
  return PreferencesStore(preferences: () async => preferences);
}

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
  var deleteCalls = 0;
  var signOutCalls = 0;

  @override
  Future<void> deleteAccount() {
    deleteCalls += 1;
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
  }
}

void main() {
  group('PreferencesStore', () {
    test('round-trips saved routes as JSON', () async {
      final store = await _storeWithMockValues({});
      final routes = [
        const SavedRoute(
          id: 'custom',
          title: 'Custom trip',
          meta: '3 days · 2 stops',
          dateLabel: 'Generated today',
        ),
      ];

      await store.saveSavedRoutes(routes);

      _expectRoutesEqual(await store.readSavedRoutes(), routes);
    });

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

    test('declares exactly two keys', () {
      expect(PreferencesStore.savedRoutesKey, 'terra_nt.saved_routes');
      expect(PreferencesStore.onboardingDoneKey, 'terra_nt.onboarding_done');
    });
  });

  group('repositories', () {
    test('seed itinerary repository dispatches the Red Centre route', () async {
      final repository = SeedItineraryRepository();

      final standard = await repository.itineraryFor(const OnboardingAnswers());
      final redCentre = await repository.itineraryForSavedRoute('red-centre');

      expect(standard.stops.length, 7);
      expect(redCentre.stops.length, 4);
      expect(redCentre.title, '7 Days in the Red Centre');
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
        ),
      );
      expect(container.read(savedRoutesNotifierProvider).first.id, 'generated-trip');

      await notifier.upsert(
        const SavedRoute(
          id: 'full-nt',
          title: 'Updated full trip',
          meta: '9 days · 7 stops',
          dateLabel: 'Generated today',
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
      container.read(profileNotifierProvider.notifier).setOfflineMaps(true);
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
      container.read(profileNotifierProvider.notifier).setOfflineMaps(true);
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
  });

  test('saved-route JSON is stored as a list, not an opaque preference type', () async {
    final store = await _storeWithMockValues({});
    await store.saveSavedRoutes(seedSavedRoutes);
    final preferences = await SharedPreferences.getInstance();
    final decoded = jsonDecode(preferences.getString(PreferencesStore.savedRoutesKey)!);

    expect(decoded, isA<List<dynamic>>());
  });
}
