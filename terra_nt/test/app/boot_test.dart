import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terra_nt/data/repositories/auth_repository.dart';
import 'package:terra_nt/data/repositories/notifiers.dart';
import 'package:terra_nt/features/onboarding/onboarding_screen.dart';
import 'package:terra_nt/main.dart';

/// Tests never call `main()`, so Firebase is never initialised here; the auth
/// seam is overridden with the in-memory implementation, as every other test
/// does (Task-24).
Widget _app() => ProviderScope(
  overrides: [
    authRepositoryProvider.overrideWithValue(InMemoryAuthRepository()),
  ],
  child: const TerraNtApp(),
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('app boots inside a ProviderScope without throwing', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('Riverpod is wired at the root', (tester) async {
    await tester.pumpWidget(_app());

    // A container resolved from the tree proves ProviderScope is above the app,
    // which is what every later task's notifiers depend on.
    final element = tester.element(find.byType(TerraNtApp));
    expect(ProviderScope.containerOf(element, listen: false), isNotNull);
  });
}
