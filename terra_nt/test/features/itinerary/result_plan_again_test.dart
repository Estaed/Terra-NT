import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terra_nt/core/theme/app_theme.dart';
import 'package:terra_nt/data/models/itinerary.dart';
import 'package:terra_nt/data/models/onboarding_answers.dart';
import 'package:terra_nt/data/repositories/notifiers.dart';
import 'package:terra_nt/data/seed/seed_data.dart';
import 'package:terra_nt/features/itinerary/result_screen.dart';
import 'package:terra_nt/features/onboarding/onboarding_screen.dart';

/// Fourteen stops: enough that the edit list cannot fit its viewport at a
/// 700px sheet, so reaching the last position needs the edge auto-scroller.
final longItinerary = Itinerary(
  title: 'Twice around',
  stops: [...seedStops, ...seedStops],
);

Future<ProviderContainer> pumpResult(
  WidgetTester tester, {
  required Itinerary itinerary,
}) async {
  tester.view.physicalSize = const Size(411, 914);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.dark,
        home: ResultScreen(launcher: (_) async => true),
      ),
    ),
  );
  final container = ProviderScope.containerOf(
    tester.element(find.byType(ResultScreen)),
  );
  container
      .read(onboardingNotifierProvider.notifier)
      .setAnswers(const OnboardingAnswers(days: 5, region: 'Top End'));
  container.read(itineraryNotifierProvider.notifier).setItinerary(itinerary);
  await tester.pump();
  return container;
}

/// Onboarding's progress car bobs on a perpetual ticker, so a route change
/// that lands there can never settle; a fixed pump covers the transition.
Future<void> pumpTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  final planAgain = find.byKey(const ValueKey('result-plan-again'));
  final confirmPanel = find.byKey(const ValueKey('result-plan-again-confirm'));

  testWidgets('a drag past the viewport edge scrolls and lands the row last', (
    tester,
  ) async {
    final haptics = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') haptics.add(call);
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });
    final container = await pumpResult(tester, itinerary: longItinerary);
    container.read(itineraryNotifierProvider.notifier).setEditMode(true);
    await tester.pumpAndSettle();

    final list = find.byKey(const ValueKey('result-stop-list-edit'));
    final scrollable = find
        .descendant(of: list, matching: find.byType(Scrollable))
        .first;
    final position = tester.state<ScrollableState>(scrollable).position;
    expect(position.maxScrollExtent, greaterThan(0));

    final handle = find.byKey(const ValueKey('result-stop-drag-0'));
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));

    // Carry the row to the bottom edge of the viewport and hold it there: the
    // framework's edge auto-scroller has to carry the list the rest of the way.
    final viewport = tester.getRect(list);
    final target = Offset(viewport.center.dx, viewport.bottom - 4);
    final start = tester.getCenter(handle);
    for (var step = 1; step <= 20; step++) {
      await gesture.moveTo(Offset.lerp(start, target, step / 20)!);
      await tester.pump(const Duration(milliseconds: 16));
    }
    for (var frame = 0; frame < 240; frame++) {
      await gesture.moveBy(Offset.zero);
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(position.pixels, greaterThan(0), reason: 'the list did not scroll');
    await gesture.up();
    await tester.pump();
    expect(
      container.read(itineraryNotifierProvider).order.first,
      0,
      reason: 'the drag proxy settles before the drop updates the order',
    );
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await tester.pumpAndSettle();

    final order = container.read(itineraryNotifierProvider).order;
    expect(order.last, 0);
    expect(order.toList()..sort(), List.generate(14, (index) => index));
    expect(haptics, hasLength(1));
    expect(haptics.single.arguments, 'HapticFeedbackType.lightImpact');
  });

  testWidgets('Plan again with no edits resets both notifiers and leaves', (
    tester,
  ) async {
    final container = await pumpResult(
      tester,
      itinerary: const Itinerary(title: 'Full NT', stops: seedStops),
    );
    await tester.tap(planAgain);
    await pumpTransition(tester);

    expect(confirmPanel, findsNothing);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(ResultScreen), findsNothing);
    expect(container.read(onboardingNotifierProvider).answers.region, isNull);
    expect(container.read(onboardingNotifierProvider).currentStep, 0);
  });

  testWidgets('Plan again with edits asks first; cancel keeps, confirm goes', (
    tester,
  ) async {
    final container = await pumpResult(
      tester,
      itinerary: const Itinerary(title: 'Full NT', stops: seedStops),
    );
    final notifier = container.read(itineraryNotifierProvider.notifier);
    notifier.remove(1);
    notifier.toggleSkipped(3);
    await tester.pump();

    await tester.tap(planAgain);
    await tester.pumpAndSettle();
    expect(confirmPanel, findsOneWidget);
    expect(find.text('Discard edits and plan again?'), findsOneWidget);
    expect(find.byType(ResultScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('result-plan-again-cancel')));
    await tester.pumpAndSettle();
    expect(confirmPanel, findsNothing);
    expect(find.byType(ResultScreen), findsOneWidget);
    expect(container.read(itineraryNotifierProvider).order.length, 6);

    await tester.tap(planAgain);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('result-plan-again-confirm-action')),
    );
    await pumpTransition(tester);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    final itinerary = container.read(itineraryNotifierProvider);
    expect(itinerary.order, [0, 1, 2, 3, 4, 5, 6]);
    expect(itinerary.skipped, isEmpty);
    expect(itinerary.editMode, isFalse);
  });
}
