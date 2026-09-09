import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terra_nt/app/tab_shell.dart';
import 'package:terra_nt/core/theme/app_theme.dart';
import 'package:terra_nt/data/models/itinerary.dart';
import 'package:terra_nt/data/models/onboarding_answers.dart';
import 'package:terra_nt/data/models/plan_entry.dart';
import 'package:terra_nt/data/models/session.dart';
import 'package:terra_nt/data/models/stop.dart';
import 'package:terra_nt/data/repositories/notifiers.dart';
import 'package:terra_nt/features/itinerary/result_screen.dart';
import 'package:terra_nt/features/itinerary/stop_detail/stop_detail_screen.dart';
import 'package:terra_nt/shared/map/map_markers.dart';

const stops = [
  Stop(
    name: 'First',
    subtitle: '',
    lat: -12.4,
    lng: 130.8,
    hours: '',
    duration: 'First duration',
    driveNext: 'First to Second',
    aiNote: 'First highlight',
    tags: [],
    detailedPlan: [PlanEntry(time: '9:00am', activity: 'First activity')],
  ),
  Stop(
    name: 'Second',
    subtitle: '',
    lat: -12.5,
    lng: 131.0,
    hours: '',
    duration: 'Second duration',
    driveNext: 'Second to Third',
    aiNote: 'Second highlight',
    tags: [],
    detailedPlan: [PlanEntry(time: '10:00am', activity: 'Second activity')],
  ),
  Stop(
    name: 'Third',
    subtitle: '',
    lat: -12.6,
    lng: 131.2,
    hours: '',
    duration: 'Third duration',
    aiNote: 'Third highlight',
    tags: [],
    detailedPlan: [PlanEntry(time: '11:00am', activity: 'Third activity')],
  ),
];

class _CompletedSessionNotifier extends SessionNotifier {
  @override
  Session build() =>
      const Session(email: 'traveller@example.com', onboardingDone: true);
}

Future<void> pumpResult(
  WidgetTester tester, {
  OnboardingAnswers answers = const OnboardingAnswers(days: 5),
  Itinerary itinerary = const Itinerary(
    title: 'A different trip',
    stops: stops,
  ),
  MapsLauncher? launcher,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.dark,
        home: ResultScreen(launcher: launcher ?? (_) async => true),
      ),
    ),
  );
  final container = ProviderScope.containerOf(
    tester.element(find.byType(ResultScreen)),
  );
  container.read(onboardingNotifierProvider.notifier).setAnswers(answers);
  container.read(itineraryNotifierProvider.notifier).setItinerary(itinerary);
  await tester.pump();
}

Future<void> pumpAtHeight(
  WidgetTester tester,
  double height, {
  MapsLauncher? launcher,
}) async {
  tester.view.physicalSize = Size(390, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await pumpResult(tester, launcher: launcher);
}

Future<void> pumpIntegratedResultAtHeight(
  WidgetTester tester,
  double height,
) async {
  tester.view.physicalSize = Size(390, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionNotifierProvider.overrideWith(_CompletedSessionNotifier.new),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: const AppShell(initialTab: 1),
      ),
    ),
  );
  await tester.pump();
}

Future<void> expandSheet(WidgetTester tester) async {
  await tester.drag(
    find.byKey(const ValueKey('result-sheet-handle')),
    const Offset(0, -600),
    touchSlopY: 0,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('uses live title, derived meta and pin order', (tester) async {
    await pumpResult(tester);

    expect(find.text('A different trip'), findsOneWidget);
    expect(find.text('5 days · 3 stops'), findsOneWidget);
    expect(find.byKey(const ValueKey('numbered-pin-1')), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(ResultScreen)),
    );
    container.read(itineraryNotifierProvider.notifier).reorder(0, 2);
    await tester.pump();
    expect(find.byType(NumberedPinMarker), findsNWidgets(3));

    container.read(itineraryNotifierProvider.notifier).remove(1);
    await tester.pump();
    expect(find.text('5 days · 2 stops'), findsOneWidget);
    expect(find.byType(NumberedPinMarker), findsNWidgets(2));
  });

  testWidgets('shares the detailed setting and toggles edit mode', (
    tester,
  ) async {
    await pumpResult(
      tester,
      answers: const OnboardingAnswers(days: 5, detailed: true),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ResultScreen)),
    );

    await expandSheet(tester);
    expect(find.text('First activity'), findsOneWidget);
    expect(find.text('First highlight'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('result-highlights')));
    await tester.pump();
    expect(
      container.read(onboardingNotifierProvider).answers.detailed,
      isFalse,
    );
    expect(find.text('First highlight'), findsOneWidget);
    expect(find.text('First activity'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('result-edit-toggle')));
    await tester.pump();
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('clamps and snaps the sheet at the nominal anchors', (
    tester,
  ) async {
    await pumpAtHeight(tester, 900);
    final handle = find.byKey(const ValueKey('result-sheet-handle'));
    final sheet = find.byKey(const ValueKey('result-sheet'));

    await tester.drag(handle, const Offset(0, -600), touchSlopY: 0);
    await tester.pumpAndSettle();
    expect(tester.getSize(sheet).height, 700);

    await tester.drag(handle, const Offset(0, 800), touchSlopY: 0);
    await tester.pumpAndSettle();
    expect(tester.getSize(sheet).height, 190);

    await tester.drag(handle, const Offset(0, -110), touchSlopY: 0);
    await tester.pumpAndSettle();
    expect(tester.getSize(sheet).height, 190);

    await tester.drag(handle, const Offset(0, -130), touchSlopY: 0);
    await tester.pumpAndSettle();
    expect(tester.getSize(sheet).height, 430);

    await tester.drag(handle, const Offset(0, 120), touchSlopY: 0);
    await tester.pumpAndSettle();
    expect(tester.getSize(sheet).height, 190);
  });

  testWidgets('clamps its ceiling to the integrated 600px shell body', (
    tester,
  ) async {
    await pumpIntegratedResultAtHeight(tester, 664);
    final handle = find.byKey(const ValueKey('result-sheet-handle'));
    final sheet = find.byKey(const ValueKey('result-sheet'));

    expect(
      tester.getSize(find.byKey(const ValueKey('result-map'))).height,
      340,
    );

    await tester.drag(handle, const Offset(0, -600), touchSlopY: 0);
    await tester.pumpAndSettle();
    expect(tester.getSize(sheet).height, 600);
    await tester.drag(
      find.byKey(const ValueKey('result-sheet-scroll')),
      const Offset(0, -100),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('exports only non-skipped live stops and no-ops below two', (
    tester,
  ) async {
    Uri? launched;
    await pumpAtHeight(
      tester,
      900,
      launcher: (url) async {
        launched = url;
        return true;
      },
    );
    await tester.drag(
      find.byKey(const ValueKey('result-sheet-handle')),
      const Offset(0, -300),
      touchSlopY: 0,
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ResultScreen)),
    );
    container.read(itineraryNotifierProvider.notifier).toggleSkipped(1);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('result-export')));
    expect(launched.toString(), contains('origin=-12.4%2C130.8'));
    expect(launched.toString(), contains('destination=-12.6%2C131.2'));

    container.read(itineraryNotifierProvider.notifier).remove(1);
    container.read(itineraryNotifierProvider.notifier).remove(2);
    await tester.pump();
    launched = null;
    await tester.tap(find.byKey(const ValueKey('result-export')));
    expect(launched, isNull);
  });

  testWidgets('restore link labels counts and restores only removed stops', (
    tester,
  ) async {
    await pumpAtHeight(tester, 900);
    await expandSheet(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ResultScreen)),
    );
    final notifier = container.read(itineraryNotifierProvider.notifier);

    expect(find.byKey(const ValueKey('result-restore-removed')), findsNothing);
    notifier.remove(1);
    await tester.pump();
    expect(find.text('Restore 1 removed stop'), findsOneWidget);

    notifier.reorder(0, 1);
    await tester.pump();
    expect(container.read(itineraryNotifierProvider).order, [2, 0]);
    await tester.tap(find.byKey(const ValueKey('result-restore-removed')));
    await tester.pump();
    expect(container.read(itineraryNotifierProvider).order, [2, 1, 0]);
    expect(find.byKey(const ValueKey('result-restore-removed')), findsNothing);

    notifier.remove(0);
    notifier.remove(1);
    await tester.pump();
    expect(find.text('Restore 2 removed stops'), findsOneWidget);
  });

  testWidgets('view-mode row opens Stop detail', (tester) async {
    await pumpAtHeight(tester, 900);
    await expandSheet(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('result-stop-row-0')));

    await tester.tap(find.byKey(const ValueKey('result-stop-row-0')));
    await tester.pumpAndSettle();

    expect(find.byType(StopDetailScreen), findsOneWidget);
    expect(find.text('First'), findsOneWidget);
  });
}
