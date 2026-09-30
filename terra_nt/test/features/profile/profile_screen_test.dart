import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terra_nt/core/theme/app_theme.dart';
import 'package:terra_nt/core/theme/colors.dart';
import 'package:terra_nt/data/models/auth_failure.dart';
import 'package:terra_nt/data/models/session.dart';
import 'package:terra_nt/data/repositories/auth_repository.dart';
import 'package:terra_nt/data/repositories/notifiers.dart';
import 'package:terra_nt/data/repositories/preferences_store.dart';
import 'package:terra_nt/data/seed/seed_data.dart';
import 'package:terra_nt/features/auth/login_screen.dart';
import 'package:terra_nt/features/profile/profile_screen.dart';
import 'package:terra_nt/shared/widgets/app_button.dart';
import 'package:terra_nt/shared/widgets/app_icon.dart';
import 'package:terra_nt/shared/widgets/settings_row.dart';

class _FixedSessionNotifier extends SessionNotifier {
  _FixedSessionNotifier(this.session);

  final Session session;

  @override
  Session build() => session;
}

Future<PreferencesStore> _storeWithMockValues(
  Map<String, Object> values,
) async {
  SharedPreferences.setMockInitialValues(values);
  final preferences = await SharedPreferences.getInstance();
  return PreferencesStore(preferences: () async => preferences);
}

void main() {
  Future<ProviderContainer> pumpProfile(
    WidgetTester tester, {
    Session session = const Session(
      email: 'traveller@example.com',
      onboardingDone: true,
    ),
    PreferencesStore? store,
    AuthRepository? authRepository,
  }) async {
    final container = ProviderContainer(
      overrides: [
        sessionNotifierProvider.overrideWith(
          () => _FixedSessionNotifier(session),
        ),
        if (store != null) preferencesStoreProvider.overrideWithValue(store),
        // The real provider is Firebase, which needs an initialised app.
        authRepositoryProvider.overrideWithValue(
          authRepository ?? InMemoryAuthRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.dark, home: const ProfileScreen()),
      ),
    );
    return container;
  }

  testWidgets('shows the account identity and session email', (tester) async {
    await pumpProfile(tester);

    expect(find.text('NT Explorer'), findsOneWidget);
    expect(find.text('traveller@example.com'), findsOneWidget);
  });

  testWidgets(
    'uses the fallback account email when the session email is empty',
    (tester) async {
      await pumpProfile(
        tester,
        session: const Session(email: '', onboardingDone: true),
      );

      expect(find.text('explorer@example.com'), findsOneWidget);
    },
  );

  testWidgets('shows English as the language value', (tester) async {
    await pumpProfile(tester);

    final language = tester.widget<SettingsRow>(
      find.byWidgetPredicate(
        (widget) => widget is SettingsRow && widget.label == 'Language',
      ),
    );
    expect(language.value, 'English');
  });

  testWidgets('does not promise offline map downloads', (tester) async {
    await pumpProfile(tester);

    expect(find.text('Offline Maps'), findsNothing);
    expect(find.text('Download maps for areas with no signal'), findsNothing);
    expect(find.byKey(const ValueKey('offline-maps-toggle')), findsNothing);
  });

  testWidgets('offline maps explains the viewed-area cache without an action', (
    tester,
  ) async {
    await pumpProfile(tester);

    final finder = find.byKey(const ValueKey('profile-offline-maps'));
    final row = tester.widget<SettingsRow>(finder);
    expect(find.text('Offline maps'), findsOneWidget);
    expect(
      find.text(
        'Map areas you have opened stay available offline for up to 30 days.',
      ),
      findsOneWidget,
    );
    expect(row.onTap, isNull);
    expect(row.showChevron, isFalse);
    expect(row.trailing, isNull);
    expect(
      find.descendant(of: finder, matching: find.byType(Switch)),
      findsNothing,
    );
    expect(
      find.descendant(of: finder, matching: find.byType(GestureDetector)),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('delete account is a centred caption link without card chrome', (
    tester,
  ) async {
    await pumpProfile(tester);

    final link = tester.widget<Text>(find.text('Delete account').first);
    expect(link.style!.color, AppColors.inkTertiary);
    expect(link.style!.fontSize, 12);
    expect(link.textAlign, TextAlign.center);
    expect(
      find.byKey(const ValueKey('delete-account-confirmation')),
      findsNothing,
    );
  });

  testWidgets(
    'delete confirmation swaps in place and Cancel restores the link',
    (tester) async {
      await pumpProfile(tester);

      await tester.tap(find.byKey(const ValueKey('delete-account-link')));
      await tester.pump();

      expect(find.byKey(const ValueKey('delete-account-link')), findsNothing);
      expect(
        find.byKey(const ValueKey('delete-account-confirmation')),
        findsOneWidget,
      );
      expect(
        find.text(
          "Delete your account and all saved routes? This can't be undone.",
        ),
        findsOneWidget,
      );
      expect(find.byType(Dialog), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byKey(const ValueKey('screen-login')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('cancel-delete-account')));
      await tester.pump();
      expect(find.byKey(const ValueKey('delete-account-link')), findsOneWidget);
    },
  );

  testWidgets('delete account clears routes permanently and returns to Login', (
    tester,
  ) async {
    final store = await _storeWithMockValues({});
    final container = await pumpProfile(tester, store: store);
    await container.read(savedRoutesNotifierProvider.notifier).load();

    await tester.tap(find.byKey(const ValueKey('delete-account-link')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('confirm-delete-account')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('screen-login')), findsOneWidget);
    expect(container.read(sessionNotifierProvider).email, isNull);
    expect(container.read(sessionNotifierProvider).onboardingDone, isFalse);
    expect(container.read(savedRoutesNotifierProvider), isEmpty);
    expect(await store.readSavedRoutes(), isEmpty);
  });

  testWidgets('log out keeps saved routes and onboarding state', (
    tester,
  ) async {
    final store = await _storeWithMockValues({});
    final container = await pumpProfile(tester, store: store);
    await container.read(savedRoutesNotifierProvider.notifier).load();

    await tester.tap(find.text('Log Out'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('screen-login')), findsOneWidget);
    expect(container.read(sessionNotifierProvider).email, isNull);
    expect(container.read(sessionNotifierProvider).onboardingDone, isTrue);
    expect(
      container.read(savedRoutesNotifierProvider).length,
      seedSavedRoutes.length,
    );
    expect((await store.readSavedRoutes()).length, seedSavedRoutes.length);
  });

  testWidgets('log out and delete account produce distinct persisted state', (
    tester,
  ) async {
    // Seeded as a real signed-in device would be: onboarding was finished, so
    // the flag is already on disk before either path runs.
    final logoutStore = await _storeWithMockValues({
      PreferencesStore.onboardingDoneKey: true,
    });
    final logoutContainer = await pumpProfile(tester, store: logoutStore);
    await logoutContainer.read(savedRoutesNotifierProvider.notifier).load();
    await tester.tap(find.text('Log Out'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final logoutRoutes = await logoutStore.readSavedRoutes();
    final logoutOnboardingDone = await logoutStore.readOnboardingDone();

    await tester.pumpWidget(const SizedBox.shrink());
    final deleteStore = await _storeWithMockValues({
      PreferencesStore.onboardingDoneKey: true,
    });
    final deleteContainer = await pumpProfile(tester, store: deleteStore);
    await deleteContainer.read(savedRoutesNotifierProvider.notifier).load();
    await tester.tap(find.byKey(const ValueKey('delete-account-link')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('confirm-delete-account')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final deleteRoutes = await deleteStore.readSavedRoutes();
    final deleteOnboardingDone = await deleteStore.readOnboardingDone();

    expect(logoutRoutes, isNotEmpty);
    expect(logoutOnboardingDone, isTrue);
    expect(
      logoutContainer.read(sessionNotifierProvider).onboardingDone,
      isTrue,
    );
    expect(deleteRoutes, isEmpty);
    expect(deleteOnboardingDone, isFalse);
    expect(
      deleteContainer.read(sessionNotifierProvider).onboardingDone,
      isFalse,
    );
  });

  testWidgets('Log Out icon and label use the tag-red token', (tester) async {
    await pumpProfile(tester);

    final logout = tester.widget<SettingsRow>(
      find.byWidgetPredicate(
        (widget) => widget is SettingsRow && widget.label == 'Log Out',
      ),
    );
    expect(logout.foregroundColor, AppColors.tagRed);
    final icon = tester.widget<AppIcon>(
      find.descendant(
        of: find.byWidget(logout),
        matching: find.byType(AppIcon),
      ),
    );
    expect(icon.color, AppColors.tagRed);
  });

  testWidgets('a refused delete keeps the confirmation open with its reason', (
    tester,
  ) async {
    final store = await _storeWithMockValues({});
    final authRepository = InMemoryAuthRepository()
      ..nextFailure = AuthFailure.requiresRecentLogin;
    final container = await pumpProfile(
      tester,
      store: store,
      authRepository: authRepository,
    );
    await container.read(savedRoutesNotifierProvider.notifier).load();

    await tester.tap(find.byKey(const ValueKey('delete-account-link')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('confirm-delete-account')));
    await tester.pump();
    await tester.pump();

    expect(
      find.byKey(const ValueKey('delete-account-confirmation')),
      findsOneWidget,
    );
    expect(
      find.text('Sign in again, then delete your account.'),
      findsOneWidget,
    );
    expect(find.byType(LoginScreen), findsNothing);
    expect(
      container.read(sessionNotifierProvider).email,
      'traveller@example.com',
    );
    expect(container.read(sessionNotifierProvider).onboardingDone, isTrue);
    expect(container.read(savedRoutesNotifierProvider), isNotEmpty);
    expect(await store.readSavedRoutes(), isNotEmpty);

    // The same button works again once the provider stops refusing.
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const ValueKey('confirm-delete-account')),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('the delete error clears when the confirmation is reopened', (
    tester,
  ) async {
    final container = await pumpProfile(
      tester,
      authRepository: InMemoryAuthRepository()
        ..nextFailure = AuthFailure.network,
    );

    await tester.tap(find.byKey(const ValueKey('delete-account-link')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('confirm-delete-account')));
    await tester.pump();
    await tester.pump();
    expect(
      find.text('No connection. Check your signal and try again.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('cancel-delete-account')));
    await tester.pump();
    expect(container.read(profileNotifierProvider).deleteAccountError, isNull);

    await tester.tap(find.byKey(const ValueKey('delete-account-link')));
    await tester.pump();
    expect(
      find.text('No connection. Check your signal and try again.'),
      findsNothing,
    );
  });

  testWidgets(
    'crash reports row is a non-tappable disclosure between Language and Log Out',
    (tester) async {
      await pumpProfile(tester);

      expect(find.text('Crash reports'), findsOneWidget);
      expect(find.text('Sent anonymously to fix bugs.'), findsOneWidget);

      final row = tester.widget<SettingsRow>(
        find.byKey(const ValueKey('profile-crash-reports')),
      );
      expect(row.onTap, isNull);
      expect(row.showChevron, isFalse);

      final treeBefore = tester.element(find.byType(ProfileScreen)).toString();
      await tester.tap(find.byKey(const ValueKey('profile-crash-reports')));
      await tester.pump();
      final treeAfter = tester.element(find.byType(ProfileScreen)).toString();

      expect(treeAfter, treeBefore);
      expect(find.byType(LoginScreen), findsNothing);
    },
  );

  testWidgets('idle and confirming states fit at 360px', (tester) async {
    final view = tester.view;
    view.physicalSize = const Size(360, 800);
    view.devicePixelRatio = 1;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);
    await pumpProfile(tester);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('delete-account-link')));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
