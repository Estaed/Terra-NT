import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terra_nt/core/theme/app_theme.dart';
import 'package:terra_nt/data/models/session.dart';
import 'package:terra_nt/data/repositories/notifiers.dart';
import 'package:terra_nt/features/profile/account/account_screen.dart';

class _FixedSessionNotifier extends SessionNotifier {
  _FixedSessionNotifier(this.session);

  final Session session;

  @override
  Session build() => session;
}

void main() {
  Future<void> pumpAccount(
    WidgetTester tester, {
    Session session = const Session(
      email: 'traveller@example.com',
      onboardingDone: true,
    ),
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionNotifierProvider.overrideWith(
            () => _FixedSessionNotifier(session),
          ),
        ],
        child: MaterialApp(theme: AppTheme.dark, home: const AccountScreen()),
      ),
    );
  }

  testWidgets('renders account identity and session email', (tester) async {
    await pumpAccount(tester);

    expect(find.text('NT Explorer'), findsOneWidget);
    expect(find.text('traveller@example.com'), findsOneWidget);
  });

  testWidgets('uses the fallback email when the session email is empty', (
    tester,
  ) async {
    await pumpAccount(
      tester,
      session: const Session(email: '', onboardingDone: true),
    );

    expect(find.text('explorer@example.com'), findsOneWidget);
  });

  testWidgets('is read-only and has no text field or save button', (
    tester,
  ) async {
    await pumpAccount(tester);

    expect(find.byType(TextField), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Save'), findsNothing);
  });

  testWidgets('back button returns to Profile', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionNotifierProvider.overrideWith(
            () => _FixedSessionNotifier(
              const Session(
                email: 'traveller@example.com',
                onboardingDone: true,
              ),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: Navigator(
            onGenerateRoute: (settings) => MaterialPageRoute<void>(
              builder: (_) => settings.name == '/account'
                  ? const AccountScreen()
                  : const Scaffold(body: Text('Profile')),
              settings: settings,
            ),
            initialRoute: '/',
          ),
        ),
      ),
    );
    Navigator.of(tester.element(find.text('Profile'))).push<void>(
      MaterialPageRoute<void>(builder: (_) => const AccountScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('account-back-button')));
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsOneWidget);
    expect(find.byKey(const ValueKey('account-screen')), findsNothing);
  });

  testWidgets('fits at 360px without a layout exception', (tester) async {
    final view = tester.view;
    view.physicalSize = const Size(360, 800);
    view.devicePixelRatio = 1;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);

    await pumpAccount(tester);
    expect(tester.takeException(), isNull);
  });
}
