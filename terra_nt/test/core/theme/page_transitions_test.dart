import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terra_nt/core/theme/app_theme.dart';
import 'package:terra_nt/core/theme/motion.dart';

/// The pushed-screen transition of the polish pass (`docs/PRD.md` D18).
void main() {
  test('Android and iOS both use the fade-through transition', () {
    final builders = AppTheme.dark.pageTransitionsTheme.builders;

    expect(
      builders[TargetPlatform.android],
      isA<FadeThroughPageTransitionsBuilder>(),
    );
    expect(
      builders[TargetPlatform.iOS],
      isA<FadeThroughPageTransitionsBuilder>(),
    );
  });

  test('it lasts a cover and an entrance, both motion tokens', () {
    expect(
      const FadeThroughPageTransitionsBuilder().transitionDuration,
      AppMotion.base + AppMotion.entrance,
    );
  });

  testWidgets('a pushed screen covers the last, then fades and rises in', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        navigatorKey: navigator,
        home: const Scaffold(body: Text('First')),
      ),
    );

    final second = find.text('Second');
    double opacityOfSecond() => tester
        .widget<FadeTransition>(
          find
              .ancestor(of: second, matching: find.byType(FadeTransition))
              .first,
        )
        .opacity
        .value;

    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Second')),
      ),
    );
    await tester.pump();

    await tester.pump(AppMotion.base ~/ 2);
    expect(opacityOfSecond(), 0, reason: 'the cover runs first');
    expect(find.text('First'), findsOneWidget);

    await tester.pump(AppMotion.base ~/ 2 + AppMotion.entrance ~/ 2);
    expect(opacityOfSecond(), inExclusiveRange(0, 1));
    final risingTop = tester.getTopLeft(second).dy;

    await tester.pump(AppMotion.entrance ~/ 2);
    expect(opacityOfSecond(), 1);
    expect(
      tester.getTopLeft(second).dy,
      lessThan(risingTop),
      reason: 'the screen rises into place',
    );
    await tester.pumpAndSettle();
    expect(find.text('First'), findsNothing, reason: 'covered once it rests');

    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(second, findsNothing);
    expect(find.text('First'), findsOneWidget);
  });
}
