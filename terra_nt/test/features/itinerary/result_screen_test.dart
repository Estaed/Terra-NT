import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:terra_nt/app/tab_shell.dart';
import 'package:terra_nt/core/theme/app_theme.dart';
import 'package:terra_nt/core/theme/colors.dart';
import 'package:terra_nt/core/theme/metrics.dart';
import 'package:terra_nt/core/theme/motion.dart';
import 'package:terra_nt/data/models/itinerary.dart';
import 'package:terra_nt/data/models/onboarding_answers.dart';
import 'package:terra_nt/data/models/plan_entry.dart';
import 'package:terra_nt/data/models/saved_route.dart';
import 'package:terra_nt/data/models/session.dart';
import 'package:terra_nt/data/models/stop.dart';
import 'package:terra_nt/data/repositories/notifiers.dart';
import 'package:terra_nt/data/seed/seed_data.dart';
import 'package:terra_nt/features/itinerary/result_screen.dart';
import 'package:terra_nt/features/itinerary/stop_detail/stop_detail_screen.dart';
import 'package:terra_nt/shared/map/map_markers.dart';
import 'package:terra_nt/shared/map/terra_map.dart';
import 'package:terra_nt/shared/widgets/app_button.dart';

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
    days: 5,
  ),
  MapsLauncher? launcher,
  double textScale = 1,
  bool disableAnimations = false,
  ValueChanged<int>? onOpenStop,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: disableAnimations,
          ),
          child: child!,
        ),
        home: ResultScreen(
          launcher: launcher ?? (_) async => true,
          onOpenStop: onOpenStop,
        ),
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
  double width = 390,
  Itinerary? itinerary,
  MapsLauncher? launcher,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await pumpResult(
    tester,
    itinerary:
        itinerary ?? const Itinerary(title: 'A different trip', stops: stops),
    launcher: launcher,
    textScale: textScale,
  );
}

/// Scrolls the edit list until the first row's drag handle is inside the sheet
/// viewport. `scrollUntilVisible` is not enough: the list builds rows into its
/// cache extent, so the handle is findable well before it can be touched.
Future<void> revealFirstDragHandle(WidgetTester tester, Finder list) async {
  final handle = find.byKey(const ValueKey('result-stop-drag-0'));
  for (var attempt = 0; attempt < 40; attempt++) {
    if (handle.evaluate().isNotEmpty) {
      final viewport = tester.getRect(list);
      final rect = tester.getRect(handle);
      if (rect.top >= viewport.top && rect.bottom <= viewport.bottom) return;
    }
    await tester.drag(list, const Offset(0, -30));
    await tester.pumpAndSettle();
  }
  fail('the first drag handle never scrolled into the sheet viewport');
}

Future<void> pumpIntegratedResultAtHeight(
  WidgetTester tester,
  double height, {
  double width = 390,
  FakeViewPadding padding = const FakeViewPadding(),
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = padding;
  tester.view.viewPadding = padding;
  addTearDown(tester.view.reset);
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
  final container = ProviderScope.containerOf(
    tester.element(find.byType(AppShell)),
  );
  container
      .read(itineraryNotifierProvider.notifier)
      .setItinerary(const Itinerary(title: 'A different trip', stops: stops));
  await tester.pump();
}

/// The `LayoutBuilder` the Result `Scaffold` hands its body constraints to.
/// The map is `Positioned.fill` inside it, so the two boxes must match.
Finder resultScaffoldBody() => find
    .ancestor(
      of: find.byKey(const ValueKey('result-map')),
      matching: find.byType(LayoutBuilder),
    )
    .first;

Future<void> expandSheet(WidgetTester tester) async {
  await tester.drag(
    find.byKey(const ValueKey('result-sheet-handle')),
    const Offset(0, -600),
    touchSlopY: 0,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    '48px sheet handle expands and collapses through named semantic actions',
    (tester) async {
      await pumpAtHeight(tester, 900, width: 360);
      await tester.pumpAndSettle();
      final sheet = find.byKey(const ValueKey('result-sheet'));
      final handle = find.byKey(const ValueKey('result-sheet-handle'));
      expect(tester.getSize(handle).height, AppMetrics.minTouchTarget);
      expect(
        tester.getSize(handle).width,
        greaterThanOrEqualTo(AppMetrics.minTouchTarget),
      );
      void perform(String label) {
        final node = tester.getSemantics(find.bySemanticsLabel('Trip stops'));
        final id = node
            .getSemanticsData()
            .customSemanticsActionIds!
            .singleWhere(
              (id) => CustomSemanticsAction.getAction(id)!.label == label,
            );
        tester.binding.renderViews.single.owner!.semanticsOwner!.performAction(
          node.id,
          SemanticsAction.customAction,
          id,
        );
      }

      perform('Expand');
      await tester.pumpAndSettle();
      expect(tester.getSize(sheet).height, AppMetrics.resultSheetMaxHeight);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Trip stops')).value,
        'Expanded',
      );
      perform('Collapse');
      await tester.pumpAndSettle();
      expect(tester.getSize(sheet).height, AppMetrics.resultSheetMinHeight);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Trip stops')).value,
        'Collapsed',
      );
      perform('Expand');
      await tester.pumpAndSettle();
      expect(tester.getSize(sheet).height, AppMetrics.resultSheetMaxHeight);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Result place pins are named and open the right stop through semantics',
    (tester) async {
      int? opened;
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpResult(
        tester,
        onOpenStop: (index) => opened = index,
        disableAnimations: true,
      );
      await tester.pumpAndSettle();
      for (var index = 0; index < stops.length; index++) {
        final node = tester.getSemantics(
          find.bySemanticsLabel('Stop ${index + 1}: ${stops[index].name}'),
        );
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
        tester.binding.renderViews.single.owner!.semanticsOwner!.performAction(
          node.id,
          SemanticsAction.tap,
        );
        await tester.pump();
        expect(opened, index);
      }
    },
  );

  testWidgets('overlapping Red Centre pins each open their own original stop', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 44);
    addTearDown(tester.view.reset);
    final opened = <int>[];
    await pumpResult(tester, onOpenStop: opened.add);
    final notifier = ProviderScope.containerOf(
      tester.element(find.byType(ResultScreen)),
    ).read(itineraryNotifierProvider.notifier);
    notifier.openSavedRoute(seedSavedRoutes.last);
    await tester.pumpAndSettle();
    final first = tester.getRect(find.byKey(const ValueKey('result-pin-0')));
    final second = tester.getRect(find.byKey(const ValueKey('result-pin-1')));
    expect(
      (first.center - second.center).distance,
      greaterThanOrEqualTo(AppMetrics.mapNumberedPinSize - 1e-7),
    );
    await tester.tapAt(first.center);
    await tester.tapAt(second.center);
    expect(opened, [0, 1]);
    notifier.reorder(0, 2);
    await tester.pumpAndSettle();
    await tester.tapAt(
      tester.getCenter(find.byKey(const ValueKey('result-pin-0'))),
    );
    expect(opened.last, 1);
  });

  testWidgets(
    'opening Full NT ignores a last onboarding answer of three days',
    (tester) async {
      await pumpResult(tester, answers: const OnboardingAnswers(days: 3));
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ResultScreen)),
      );
      container
          .read(itineraryNotifierProvider.notifier)
          .openSavedRoute(seedSavedRoutes.first);
      await tester.pumpAndSettle();
      expect(find.text('8 days · 7 stops'), findsOneWidget);
      expect(find.text('3 days · 7 stops'), findsNothing);
      container
          .read(onboardingNotifierProvider.notifier)
          .setAnswers(const OnboardingAnswers(days: 12));
      await tester.pump();
      expect(find.text('8 days · 7 stops'), findsOneWidget);
    },
  );

  testWidgets(
    'an old route shows its stored meta verbatim after opening and editing',
    (tester) async {
      await pumpResult(tester, answers: const OnboardingAnswers(days: 3));
      final notifier = ProviderScope.containerOf(
        tester.element(find.byType(ResultScreen)),
      ).read(itineraryNotifierProvider.notifier);
      notifier.openSavedRoute(
        const SavedRoute(
          id: 'legacy',
          title: 'Legacy trip',
          meta: 'A week away · three places',
          dateLabel: 'My plan',
          stops: stops,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('A week away · three places'), findsOneWidget);
      expect(find.text('3 days · 3 stops'), findsNothing);
      notifier.remove(1);
      await tester.pumpAndSettle();
      expect(find.text('A week away · three places'), findsOneWidget);
    },
  );

  List<LatLng> drawnPoints(WidgetTester tester) => tester
      .widget<PolylineLayer>(find.byType(PolylineLayer))
      .polylines
      .expand((polyline) => polyline.points)
      .toList();

  testWidgets('Full NT pins stay on the true dashed route at 411 by 914', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(411, 914);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 44);
    addTearDown(tester.view.reset);
    final opened = <int>[];
    await pumpResult(tester, onOpenStop: opened.add);
    ProviderScope.containerOf(tester.element(find.byType(ResultScreen)))
        .read(itineraryNotifierProvider.notifier)
        .openSavedRoute(seedSavedRoutes.first);
    await tester.pumpAndSettle();
    final points = [for (final stop in seedStops) LatLng(stop.lat, stop.lng)];
    expect(drawnPoints(tester), points);
    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    final origin = tester.getTopLeft(find.byType(FlutterMap));
    final leaders = find.byKey(const ValueKey('route-pin-leaders'));
    var leaderCount = 0;
    for (var i = 0; i < points.length; i++) {
      final anchor = map.mapController!.camera.latLngToScreenOffset(points[i]);
      final centre =
          tester.getCenter(find.byKey(ValueKey('result-pin-$i'))) - origin;
      final displacement = (centre - anchor).distance;
      expect(
        displacement,
        lessThanOrEqualTo(AppMetrics.mapNumberedPinSize + 1e-7),
      );
      if (displacement > AppMetrics.mapNumberedPinSize / 2) {
        leaderCount++;
        expect(
          leaders,
          paints..something(
            (method, arguments) =>
                method == #drawLine &&
                ((arguments[0] as Offset) - anchor).distance < 1e-7 &&
                ((arguments[1] as Offset) - centre).distance < 1e-7 &&
                (arguments[2] as Paint).color == AppColors.primary &&
                (arguments[2] as Paint).strokeWidth ==
                    AppMetrics.mapPinBorderWidth,
          ),
        );
      }
      await tester.tapAt(centre + origin);
      expect(opened.last, i);
    }
    expect(leaders, paintsExactlyCountTimes(#drawLine, leaderCount));
  });

  double pinOpacity(WidgetTester tester, int number) => tester
      .widget<Opacity>(
        find
            .ancestor(
              of: find.byKey(ValueKey('numbered-pin-$number')),
              matching: find.byType(Opacity),
            )
            .first,
      )
      .opacity;

  testWidgets('draws continuously and reveals numbered pins in stop order', (
    tester,
  ) async {
    await pumpAtHeight(tester, 900);
    expect(drawnPoints(tester), isEmpty);
    expect([for (var i = 1; i <= 3; i++) pinOpacity(tester, i)], [1, 0, 0]);
    final tiles = tester.widget<TileLayer>(find.byType(TileLayer));
    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    final camera = map.mapController!.camera;

    await tester.pump(AppMotion.resultRouteReveal ~/ 2);
    final partial = drawnPoints(tester);
    expect(partial.length, greaterThan(1));
    expect(partial.first, LatLng(stops.first.lat, stops.first.lng));
    expect(partial.last, isNot(LatLng(stops.last.lat, stops.last.lng)));
    expect(pinOpacity(tester, 2), closeTo(1, 0.001));
    expect(pinOpacity(tester, 3), 0);
    // A reveal tick updates the route layers, not tiles or camera.
    expect(tester.widget<TileLayer>(find.byType(TileLayer)), same(tiles));
    expect(map.mapController!.camera.center, camera.center);
    expect(map.mapController!.camera.zoom, camera.zoom);

    await tester.pump(AppMotion.resultRouteReveal ~/ 2);
    expect(drawnPoints(tester), [
      for (final stop in stops) LatLng(stop.lat, stop.lng),
    ]);
    expect([for (var i = 1; i <= 3; i++) pinOpacity(tester, i)], [1, 1, 1]);
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets(
    'reduced motion completes the route and pins on the first frame',
    (tester) async {
      await pumpResult(tester, disableAnimations: true);
      expect(drawnPoints(tester), [
        for (final stop in stops) LatLng(stop.lat, stop.lng),
      ]);
      expect([for (var i = 1; i <= 3; i++) pinOpacity(tester, i)], [1, 1, 1]);
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);
    },
  );

  testWidgets('another saved route replays; reorder, remove and skip do not', (
    tester,
  ) async {
    await pumpAtHeight(tester, 900);
    await tester.pumpAndSettle();
    final notifier = ProviderScope.containerOf(
      tester.element(find.byType(ResultScreen)),
    ).read(itineraryNotifierProvider.notifier);
    notifier.reorder(0, 2);
    await tester.pump();
    expect(drawnPoints(tester).length, 3);
    expect(pinOpacity(tester, 3), 1);
    notifier.toggleSkipped(0);
    await tester.pump();
    expect(drawnPoints(tester).length, 3);
    expect(pinOpacity(tester, 3), 1);
    notifier.remove(1);
    await tester.pump();
    expect(drawnPoints(tester).length, 2);
    expect(pinOpacity(tester, 2), 1);

    notifier.openSavedRoute(
      const SavedRoute(
        id: 'second-saved-trip',
        title: 'Another saved trip',
        meta: '3 stops',
        dateLabel: 'Generated today',
        stops: stops,
      ),
    );
    await tester.pump();
    expect(drawnPoints(tester), isEmpty);
    expect(pinOpacity(tester, 3), 0);
    expect(find.text('Another saved trip'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(drawnPoints(tester).length, 3);
    expect(pinOpacity(tester, 3), 1);
  });

  testWidgets('Result leaves mid-reveal without an exception or ticker leak', (
    tester,
  ) async {
    await pumpAtHeight(tester, 900);
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      drawnPoints(tester).last,
      isNot(LatLng(stops.last.lat, stops.last.lng)),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pump(AppMotion.resultRouteReveal);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'sheet snaps ease the camera and keep all Full NT pins above it',
    (tester) async {
      tester.view.physicalSize = const Size(411, 914);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 48);
      addTearDown(tester.view.reset);
      await pumpResult(
        tester,
        itinerary: const Itinerary(
          title: 'Full NT: Darwin to Uluru',
          stops: seedStops,
        ),
      );
      await tester.pumpAndSettle();
      final controller = tester
          .widget<FlutterMap>(find.byType(FlutterMap))
          .mapController!;
      final handle = find.byKey(const ValueKey('result-sheet-handle'));
      void expectPinsVisible() {
        final sheetTop = tester
            .getTopLeft(find.byKey(const ValueKey('result-sheet')))
            .dy;
        const radius = AppMetrics.mapNumberedPinSize / 2;
        for (final stop in seedStops) {
          final offset = controller.camera.latLngToScreenOffset(
            LatLng(stop.lat, stop.lng),
          );
          expect(offset.dx, inInclusiveRange(radius, 411 - radius));
          expect(offset.dy, inInclusiveRange(48 + radius, sheetTop - radius));
        }
      }

      expectPinsVisible();
      final before = controller.camera;
      await tester.drag(handle, const Offset(0, -600), touchSlopY: 0);
      await tester.pump();
      // Start the camera ticker queued after the snap layout.
      await tester.pump();
      await tester.pump(AppMotion.resultCameraFit ~/ 2);
      final midway = controller.camera;
      expect(midway.zoom, lessThan(before.zoom));
      await tester.pumpAndSettle();
      expect(controller.camera.zoom, lessThan(midway.zoom));
      expect(controller.camera.zoom, lessThan(AppMetrics.mapMinZoom));
      expectPinsVisible();
      await tester.drag(handle, const Offset(0, 800), touchSlopY: 0);
      await tester.pumpAndSettle();
      expectPinsVisible();
      await tester.drag(handle, const Offset(0, -230), touchSlopY: 0);
      await tester.pumpAndSettle();
      expectPinsVisible();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('the result map fills the Scaffold body behind the sheet', (
    tester,
  ) async {
    await pumpResult(tester);

    final map = find.byKey(const ValueKey('result-map'));
    expect(tester.getSize(map), tester.getSize(resultScaffoldBody()));
    // Full-bleed means it starts at the body's origin, not below a header.
    expect(tester.getTopLeft(map), tester.getTopLeft(resultScaffoldBody()));
  });

  testWidgets('after setItinerary the map and sheet render, not the empty state', (
    tester,
  ) async {
    await pumpResult(tester);

    expect(find.byKey(const ValueKey('result-map')), findsOneWidget);
    expect(find.byKey(const ValueKey('result-sheet')), findsOneWidget);
    expect(find.text('No route yet'), findsNothing);
  });

  test('hasRoute goes from false to true after openSavedRoute', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(itineraryNotifierProvider).hasRoute, isFalse);

    container
        .read(itineraryNotifierProvider.notifier)
        .openSavedRoute(
          const SavedRoute(
            id: 'route-1',
            title: 'A saved trip',
            meta: '1 day',
            dateLabel: 'Generated today',
            stops: stops,
          ),
        );

    expect(container.read(itineraryNotifierProvider).hasRoute, isTrue);
  });

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

  testWidgets('keeps the detailed setting local and toggles edit mode', (
    tester,
  ) async {
    await pumpResult(tester, answers: const OnboardingAnswers(days: 5));

    // Highlights is the default now that onboarding no longer asks (V11).
    await expandSheet(tester);
    expect(find.text('First highlight'), findsOneWidget);
    expect(find.text('First activity'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('result-detailed')));
    await tester.pump();
    expect(find.text('First activity'), findsOneWidget);
    expect(find.text('First highlight'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('result-highlights')));
    await tester.pump();
    expect(find.text('First highlight'), findsOneWidget);
    expect(find.text('First activity'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('result-edit-toggle')));
    await tester.pump();
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('edit mode opens at the max anchor and reorders cleanly', (
    tester,
  ) async {
    await pumpAtHeight(
      tester,
      914,
      width: 411,
      itinerary: const Itinerary(
        title: 'Full NT: Darwin to Uluru',
        stops: seedStops,
      ),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ResultScreen)),
    );

    // Entering edit mode snaps the sheet open. That is half the reorder fix:
    // the edge auto-scroller only works while the dragged row is shorter than
    // the viewport, so the peek anchor is not a geometry edit mode can hold.
    await tester.tap(find.byKey(const ValueKey('result-edit-toggle')));
    await tester.pumpAndSettle();
    expect(container.read(itineraryNotifierProvider).editMode, isTrue);
    expect(
      tester.getSize(find.byKey(const ValueKey('result-sheet'))).height,
      AppMetrics.resultSheetMaxHeight,
    );

    // The other half: an edit row is compact, not a full stop card.
    final list = find.byKey(const ValueKey('result-stop-list-edit'));
    await revealFirstDragHandle(tester, list);
    expect(
      tester.getSize(find.byKey(const ValueKey('result-stop-row-0'))).height,
      AppMetrics.resultStopEditRowHeight,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('result-stop-item-0'))).height,
      lessThan(tester.getSize(list).height),
    );

    final errors = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previousOnError);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('result-stop-drag-0'))),
    );
    await tester.pump(const Duration(milliseconds: 100));
    for (var step = 0; step < 12; step++) {
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();
    FlutterError.onError = previousOnError;

    // Both halves of the acceptance criterion `docs/DEVICE-TOUR.md` fixes: no
    // framework error, and the reorder actually happened.
    expect(
      errors.map((details) => details.exception.toString()).toList(),
      isEmpty,
    );
    final order = container.read(itineraryNotifierProvider).order;
    expect(order, isNot([0, 1, 2, 3, 4, 5, 6]));
    expect(order.first, isNot(0));
    expect(order.toList()..sort(), [0, 1, 2, 3, 4, 5, 6]);
  });

  testWidgets('clamps and snaps the sheet at the nominal anchors', (
    tester,
  ) async {
    await pumpAtHeight(tester, 900);
    final handle = find.byKey(const ValueKey('result-sheet-handle'));
    final sheet = find.byKey(const ValueKey('result-sheet'));

    // It opens at the middle anchor, as the prototype does.
    expect(tester.getSize(sheet).height, 430);

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

  testWidgets('clamps its ceiling to the integrated shell body', (
    tester,
  ) async {
    await pumpIntegratedResultAtHeight(tester, 664);
    final handle = find.byKey(const ValueKey('result-sheet-handle'));
    final sheet = find.byKey(const ValueKey('result-sheet'));

    expect(
      tester.getSize(find.byKey(const ValueKey('result-map'))),
      tester.getSize(resultScaffoldBody()),
    );

    await tester.drag(handle, const Offset(0, -600), touchSlopY: 0);
    await tester.pumpAndSettle();
    expect(
      tester.getSize(sheet).height,
      tester.getSize(resultScaffoldBody()).height,
    );
    await tester.drag(
      find.byKey(const ValueKey('result-sheet-scroll')),
      const Offset(0, -100),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses the visible tab body for the Result sheet ceiling', (
    tester,
  ) async {
    await pumpIntegratedResultAtHeight(
      tester,
      640,
      width: 360,
      padding: const FakeViewPadding(top: 24, bottom: 48),
    );
    await expandSheet(tester);

    expect(
      tester.getSize(find.byKey(const ValueKey('result-sheet'))).height,
      tester.getSize(resultScaffoldBody()).height - 24,
    );
  });

  testWidgets('keeps the segment rail and Edit Route on one toolbar row', (
    tester,
  ) async {
    await pumpAtHeight(tester, 900, width: 360);
    await expandSheet(tester);

    final rail = find.byKey(const ValueKey('result-segment-rail'));
    final edit = find.byKey(const ValueKey('result-edit-toggle'));
    final export = find.byKey(const ValueKey('result-export'));
    expect(rail, findsOneWidget);
    expect(
      find.descendant(
        of: rail,
        matching: find.byKey(const ValueKey('result-highlights')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: rail,
        matching: find.byKey(const ValueKey('result-detailed')),
      ),
      findsOneWidget,
    );
    expect(tester.getRect(edit).center.dy, tester.getRect(rail).center.dy);
    expect(tester.getRect(edit).right, tester.getRect(export).right);
    expect(
      tester.widget<AppButton>(export).iconLeft,
      LucideIcons.external_link,
    );
  });

  testWidgets('does not overflow the Result toolbar at 320px and 1.5 scale', (
    tester,
  ) async {
    final errors = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previousOnError);
    await pumpAtHeight(tester, 900, width: 320, textScale: 1.5);
    await expandSheet(tester);

    FlutterError.onError = previousOnError;
    expect(
      errors.where((error) => error.toString().contains('result_screen.dart')),
      isEmpty,
    );
  });

  testWidgets('exports only active stops and disables Export below two', (
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
    expect(
      tester
          .widget<AppButton>(find.byKey(const ValueKey('result-export')))
          .onPressed,
      isNull,
    );
    expect(
      find.text('Keep at least two active stops to export a route.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('result-export')));
    expect(launched, isNull);
  });

  testWidgets('skipping stops disables Export and unskipping enables it', (
    tester,
  ) async {
    await pumpAtHeight(tester, 900);
    await expandSheet(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ResultScreen)),
    );
    final notifier = container.read(itineraryNotifierProvider.notifier);
    notifier.toggleSkipped(1);
    notifier.toggleSkipped(2);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<AppButton>(find.byKey(const ValueKey('result-export')))
          .onPressed,
      isNull,
    );
    expect(find.byKey(const ValueKey('result-export-reason')), findsOneWidget);
    notifier.toggleSkipped(1);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<AppButton>(find.byKey(const ValueKey('result-export')))
          .onPressed,
      isNotNull,
    );
    expect(find.byKey(const ValueKey('result-export-reason')), findsNothing);
  });

  for (final throws in [false, true]) {
    testWidgets(
      'Export launch ${throws ? 'exception' : 'refusal'} offers destination coordinates',
      (tester) async {
        final copied = <String>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              copied.add((call.arguments as Map)['text'] as String);
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
        await pumpAtHeight(
          tester,
          900,
          launcher: (_) async {
            if (throws) throw PlatformException(code: 'unavailable');
            return false;
          },
        );
        await expandSheet(tester);
        final container = ProviderScope.containerOf(
          tester.element(find.byType(ResultScreen)),
        );
        final notifier = container.read(itineraryNotifierProvider.notifier);
        notifier.toggleSkipped(2);
        notifier.reorder(0, 1);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('result-export')));
        await tester.pumpAndSettle();
        expect(
          find.text(
            'Google Maps could not be opened. You can copy the destination coordinates instead.',
          ),
          findsOneWidget,
        );
        final copy = find.text('Copy destination coordinates');
        await tester.ensureVisible(copy);
        await tester.tap(copy);
        await tester.pumpAndSettle();
        expect(copied, [
          '-12.4,130.8',
        ], reason: 'the last active stop follows live ordering');
        expect(find.text('Coordinates copied'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

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

  testWidgets(
    'an empty detailed plan shows one line in Detailed and Stop detail',
    (tester) async {
      const emptyPlan = 'No detailed plan for this stop.';
      const itinerary = Itinerary(
        title: 'A different trip',
        stops: [
          Stop(
            name: 'First',
            subtitle: '',
            lat: -12.4,
            lng: 130.8,
            hours: '',
            duration: 'First duration',
            aiNote: 'First highlight',
            tags: [],
            detailedPlan: [
              PlanEntry(time: '9:00am', activity: 'First activity'),
            ],
          ),
          Stop(
            name: 'Second',
            subtitle: '',
            lat: -12.5,
            lng: 131.0,
            hours: '',
            duration: 'Second duration',
            aiNote: 'Second highlight',
            tags: [],
            detailedPlan: [],
          ),
        ],
      );
      await pumpAtHeight(tester, 900, itinerary: itinerary);
      await expandSheet(tester);
      expect(find.text(emptyPlan), findsNothing);

      await tester.tap(find.byKey(const ValueKey('result-detailed')));
      await tester.pump();
      expect(
        find.byKey(const ValueKey('detailed-plan-empty-1')),
        findsOneWidget,
      );
      expect(find.text(emptyPlan), findsOneWidget);
      expect(find.text('First activity'), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(const ValueKey('result-stop-row-1')),
      );
      await tester.tap(find.byKey(const ValueKey('result-stop-row-1')));
      await tester.pumpAndSettle();
      expect(find.byType(StopDetailScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('detailed-plan-empty')), findsOneWidget);
    },
  );

  testWidgets('map fit padding clears the status bar', (tester) async {
    tester.view.physicalSize = const Size(411, 914);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 48);
    addTearDown(tester.view.reset);
    await pumpResult(tester);

    final fitPadding = tester.widget<TerraMap>(find.byType(TerraMap)).fitPadding;
    expect(fitPadding.top, greaterThanOrEqualTo(48 + AppMetrics.mapResultFitPadding));
  });
}
