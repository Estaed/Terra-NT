import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terra_nt/core/theme/app_theme.dart';
import 'package:terra_nt/core/theme/motion.dart';
import 'package:terra_nt/data/models/itinerary.dart';
import 'package:terra_nt/data/models/plan_entry.dart';
import 'package:terra_nt/data/models/stop.dart';
import 'package:terra_nt/data/repositories/notifiers.dart';
import 'package:terra_nt/data/seed/seed_data.dart';
import 'package:terra_nt/features/itinerary/widgets/result_stop_list.dart';
import 'package:terra_nt/shared/widgets/entrance.dart';

const testStops = [
  Stop(
    name: 'Alpha',
    subtitle: 'Alpha subtitle',
    lat: -12,
    lng: 130,
    hours: 'Always',
    duration: 'Alpha duration',
    driveNext: 'Alpha to Bravo',
    aiNote: 'Alpha highlight',
    tags: ['Nature'],
    detailedPlan: [PlanEntry(time: '9:00am', activity: 'Alpha activity')],
  ),
  Stop(
    name: 'Bravo',
    subtitle: 'Bravo subtitle',
    lat: -13,
    lng: 131,
    hours: 'Always',
    duration: 'Bravo duration',
    driveNext: 'Bravo to Charlie',
    aiNote: 'Bravo highlight',
    tags: ['Culture'],
    detailedPlan: [PlanEntry(time: '10:00am', activity: 'Bravo activity')],
  ),
  Stop(
    name: 'Charlie',
    subtitle: 'Charlie subtitle',
    lat: -14,
    lng: 132,
    hours: 'Always',
    duration: 'Charlie duration',
    driveNext: 'Charlie to Delta',
    aiNote: 'Charlie highlight',
    tags: ['Adventure'],
    detailedPlan: [PlanEntry(time: '11:00am', activity: 'Charlie activity')],
  ),
  Stop(
    name: 'Delta',
    subtitle: 'Delta subtitle',
    lat: -15,
    lng: 133,
    hours: 'Always',
    duration: 'Delta duration',
    aiNote: 'Delta highlight',
    tags: ['Wildlife'],
    detailedPlan: [PlanEntry(time: '12:00pm', activity: 'Delta activity')],
  ),
];

Future<ProviderContainer> pumpList(
  WidgetTester tester, {
  Itinerary itinerary = const Itinerary(title: 'Test route', stops: testStops),
  bool detailed = false,
  bool editMode = false,
  bool reduceMotion = false,
  double textScale = 1,
  ValueChanged<int>? onOpenStop,
  Size size = const Size(360, 1600),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: reduceMotion,
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: ResultStopList(
            header: const Text('Header'),
            detailed: detailed,
            onOpenStop: onOpenStop ?? (_) {},
          ),
        ),
      ),
    ),
  );
  final container = ProviderScope.containerOf(
    tester.element(find.byType(ResultStopList)),
  );
  container.read(itineraryNotifierProvider.notifier).setItinerary(itinerary);
  container.read(itineraryNotifierProvider.notifier).setEditMode(editMode);
  await tester.pump();
  return container;
}

Finder inStop(int originalIndex, Finder matching) => find.descendant(
  of: find.byKey(ValueKey('result-stop-item-$originalIndex')),
  matching: matching,
);

String expectedStraightLineFallback(
  double lat1,
  double lng1,
  double lat2,
  double lng2,
  String nextName,
) {
  const earthRadiusKm = 6371.0;
  double degToRad(double deg) => deg * math.pi / 180;
  final dLat = degToRad(lat2 - lat1);
  final dLng = degToRad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(degToRad(lat1)) *
          math.cos(degToRad(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  final km = earthRadiusKm * c;
  final roundedKm = math.max(5, (km / 5).round() * 5);
  return '$roundedKm km straight line to $nextName';
}

void main() {
  testWidgets(
    'drive line skips skipped stops and disappears on the last active stop',
    (tester) async {
      final container = await pumpList(tester, reduceMotion: true);
      final notifier = container.read(itineraryNotifierProvider.notifier);
      notifier.toggleSkipped(1);
      await tester.pump();
      expect(
        inStop(
          0,
          find.text(
            expectedStraightLineFallback(-12, 130, -14, 132, 'Charlie'),
          ),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('result-stop-drive-1')), findsNothing);
      notifier.toggleSkipped(2);
      notifier.toggleSkipped(3);
      await tester.pump();
      expect(find.byKey(const ValueKey('result-stop-drive-0')), findsNothing);
      notifier.toggleSkipped(1);
      await tester.pump();
      expect(inStop(0, find.text('Alpha to Bravo')), findsOneWidget);
    },
  );

  testWidgets('delete controls name their stop and delete through semantics', (
    tester,
  ) async {
    final container = await pumpList(
      tester,
      editMode: true,
      reduceMotion: true,
    );
    for (final stop in testStops) {
      expect(
        find.bySemanticsLabel('Delete ${stop.name} from trip'),
        findsOneWidget,
      );
    }
    final node = tester.getSemantics(
      find.bySemanticsLabel('Delete Bravo from trip'),
    );
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    tester.binding.renderViews.single.owner!.semanticsOwner!.performAction(
      node.id,
      SemanticsAction.tap,
    );
    await tester.pump();
    expect(container.read(itineraryNotifierProvider).order, [0, 2, 3]);
  });

  testWidgets('Result rows remain readable at 360px and 2x text', (
    tester,
  ) async {
    final container = await pumpList(
      tester,
      itinerary: const Itinerary(title: 'Full NT', stops: seedStops),
      detailed: true,
      reduceMotion: true,
      textScale: 2,
      size: const Size(360, 800),
    );
    container.read(itineraryNotifierProvider.notifier).toggleSkipped(0);
    await tester.pump();
    expect(find.byType(FittedBox), findsNothing);
    for (var index = 0; index < seedStops.length; index++) {
      final row = find.byKey(ValueKey('result-stop-row-$index'));
      await tester.scrollUntilVisible(
        row,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: seedStops[index].name);
    }
    container.read(itineraryNotifierProvider.notifier).setEditMode(true);
    await tester.pump();
    expect(find.byType(FittedBox), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed online Result photo shows the bundled category picture', (
    tester,
  ) async {
    const stop = Stop(
      name: 'An unfamiliar place',
      subtitle: '',
      lat: -12.4,
      lng: 130.8,
      hours: '',
      duration: '1 day',
      aiNote: '',
      tags: ['Nature'],
      detailedPlan: [],
      photoUrl: 'https://example.invalid/result-photo.jpg',
    );
    await pumpList(
      tester,
      itinerary: const Itinerary(title: 'Trip', stops: [stop]),
    );
    await tester.runAsync(() async => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    final assets = tester
        .widgetList<Image>(inStop(0, find.byType(Image)))
        .map((image) => image.image)
        .whereType<AssetImage>();
    expect(
      assets.map((image) => image.assetName),
      contains('assets/images/places/tag-nature.jpg'),
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('badges renumber while durations remain with their stops', (
    tester,
  ) async {
    final container = await pumpList(tester);
    container.read(itineraryNotifierProvider.notifier).reorder(0, 3);
    await tester.pump();

    expect(inStop(0, find.text('4')), findsOneWidget);
    expect(inStop(0, find.text('Alpha duration')), findsOneWidget);
    expect(inStop(1, find.text('1')), findsOneWidget);
    expect(inStop(1, find.text('Bravo duration')), findsOneWidget);
  });

  testWidgets('drive copy follows only truthful baseline adjacency', (
    tester,
  ) async {
    final container = await pumpList(tester);
    expect(inStop(0, find.text('Alpha to Bravo')), findsOneWidget);
    expect(find.byKey(const ValueKey('result-stop-drive-3')), findsNothing);

    container.read(itineraryNotifierProvider.notifier).reorder(1, 3);
    await tester.pump();

    expect(
      inStop(
        0,
        find.text(
          expectedStraightLineFallback(-12, 130, -14, 132, 'Charlie'),
        ),
      ),
      findsOneWidget,
    );
    expect(inStop(2, find.text('Charlie to Delta')), findsOneWidget);
    expect(find.byKey(const ValueKey('result-stop-drive-1')), findsNothing);
  });

  testWidgets('Red Centre uses its own baseline legs', (tester) async {
    final container = await pumpList(
      tester,
      itinerary: Itinerary(title: 'Red Centre', stops: redCentreStops),
    );
    expect(
      inStop(0, find.text('7 km · 15m to Alice Springs Desert Park')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('result-stop-drive-3')), findsNothing);

    container.read(itineraryNotifierProvider.notifier).reorder(0, 1);
    await tester.pump();
    expect(
      inStop(
        1,
        find.text(
          expectedStraightLineFallback(
            redCentreStops[1].lat,
            redCentreStops[1].lng,
            redCentreStops[0].lat,
            redCentreStops[0].lng,
            redCentreStops[0].name,
          ),
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('view and edit modes expose different interactions', (
    tester,
  ) async {
    int? opened;
    final container = await pumpList(
      tester,
      onOpenStop: (originalIndex) => opened = originalIndex,
    );

    expect(find.byType(ReorderableListView), findsNothing);
    expect(find.byKey(const ValueKey('result-stop-chevron-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('result-stop-drag-0')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('result-stop-row-0')));
    expect(opened, 0);

    opened = null;
    container.read(itineraryNotifierProvider.notifier).setEditMode(true);
    await tester.pump();
    expect(find.byType(ReorderableListView), findsOneWidget);
    expect(find.byKey(const ValueKey('result-stop-chevron-0')), findsNothing);
    expect(find.byKey(const ValueKey('result-stop-drag-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('result-stop-remove-0')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('result-stop-name-0')));
    expect(opened, isNull);
  });

  testWidgets('reorder callback exists only in edit mode', (tester) async {
    final container = await pumpList(tester, editMode: true);
    final list = tester.widget<ReorderableListView>(
      find.byType(ReorderableListView),
    );

    list.onReorderItem!(0, 2);
    await tester.pump();
    expect(container.read(itineraryNotifierProvider).order, [1, 2, 0, 3]);
  });

  testWidgets('per-row revert preserves other order and removed stops', (
    tester,
  ) async {
    final container = await pumpList(tester, editMode: true);
    final notifier = container.read(itineraryNotifierProvider.notifier);
    notifier.reorder(0, 3);
    notifier.remove(2);
    await tester.pump();
    await tester.pump(AppMotion.slow);
    expect(container.read(itineraryNotifierProvider).order, [1, 3, 0]);

    await tester.tap(find.byKey(const ValueKey('result-stop-revert-0')));
    await tester.pump();

    expect(container.read(itineraryNotifierProvider).order, [0, 1, 3]);
    expect(container.read(itineraryNotifierProvider).order, isNot(contains(2)));
  });

  testWidgets('revert is hidden at the original position', (tester) async {
    await pumpList(tester, editMode: true);

    for (var index = 0; index < testStops.length; index++) {
      expect(find.byKey(ValueKey('result-stop-revert-$index')), findsNothing);
    }
  });

  testWidgets('skipped and removed states stay independent', (tester) async {
    final container = await pumpList(tester);
    final notifier = container.read(itineraryNotifierProvider.notifier);
    notifier.toggleSkipped(1);
    notifier.remove(2);
    await tester.pumpAndSettle();

    expect(container.read(itineraryNotifierProvider).skipped, {1});
    expect(container.read(itineraryNotifierProvider).order, isNot(contains(2)));
    expect(find.byKey(const ValueKey('result-stop-item-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('result-stop-item-2')), findsNothing);
    expect(find.text('Skipped'), findsOneWidget);
    expect(
      tester
          .widget<Opacity>(find.byKey(const ValueKey('result-stop-opacity-1')))
          .opacity,
      0.5,
    );
  });

  testWidgets('remove collapses before the row leaves the list', (
    tester,
  ) async {
    final container = await pumpList(tester, editMode: true);
    final row = find.byKey(const ValueKey('result-stop-item-1'));
    final height = tester.getSize(row).height;

    await tester.tap(find.byKey(const ValueKey('result-stop-remove-1')));
    await tester.pump();
    expect(container.read(itineraryNotifierProvider).order, [0, 2, 3]);
    expect(tester.getSize(row).height, height);
    await tester.pump(AppMotion.slow ~/ 2);
    expect(tester.getSize(row).height, inExclusiveRange(0, height));
    await tester.pump(AppMotion.slow);
    expect(row, findsNothing);
  });

  testWidgets('restore expands at the original index and keeps other edits', (
    tester,
  ) async {
    final container = await pumpList(tester, editMode: true);
    final notifier = container.read(itineraryNotifierProvider.notifier);
    final row = find.byKey(const ValueKey('result-stop-item-1'));
    final height = tester.getSize(row).height;
    notifier.remove(1);
    await tester.pumpAndSettle();
    notifier.reorder(0, 2);
    await tester.pump();

    notifier.restoreRemoved();
    await tester.pump();
    expect(container.read(itineraryNotifierProvider).order, [2, 1, 3, 0]);
    expect(tester.getSize(row).height, 0);
    await tester.pump(AppMotion.slow ~/ 2);
    expect(tester.getSize(row).height, inExclusiveRange(0, height));
    await tester.pump(AppMotion.slow);
    expect(tester.getSize(row).height, height);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('result-stop-item-2'))).dy,
      lessThan(tester.getTopLeft(row).dy),
    );
    expect(
      tester.getTopLeft(row).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const ValueKey('result-stop-item-3'))).dy,
      ),
    );
  });

  testWidgets('restore during collapse reverses from the current height', (
    tester,
  ) async {
    final container = await pumpList(tester, editMode: true);
    final notifier = container.read(itineraryNotifierProvider.notifier);
    final row = find.byKey(const ValueKey('result-stop-item-1'));
    final height = tester.getSize(row).height;
    notifier.remove(1);
    await tester.pump();
    await tester.pump(AppMotion.slow ~/ 2);
    final collapsedHeight = tester.getSize(row).height;

    notifier.restoreRemoved();
    await tester.pump();
    expect(tester.getSize(row).height, closeTo(collapsedHeight, 0.001));
    await tester.pump(AppMotion.slow ~/ 2);
    expect(tester.getSize(row).height, greaterThan(collapsedHeight));
    await tester.pumpAndSettle();
    expect(tester.getSize(row).height, height);
    expect(container.read(itineraryNotifierProvider).order, [0, 1, 2, 3]);
  });

  testWidgets('skip and unskip fade without removing the stop', (tester) async {
    final container = await pumpList(tester);
    await tester.pumpAndSettle();
    final notifier = container.read(itineraryNotifierProvider.notifier);
    final opacity = find.byKey(const ValueKey('result-stop-opacity-1'));
    notifier.toggleSkipped(1);
    await tester.pump();
    expect(tester.widget<Opacity>(opacity).opacity, 1);
    await tester.pump(AppMotion.base ~/ 2);
    expect(tester.widget<Opacity>(opacity).opacity, inExclusiveRange(0.5, 1));
    await tester.pump(AppMotion.base);
    expect(tester.widget<Opacity>(opacity).opacity, 0.5);

    notifier.toggleSkipped(1);
    await tester.pump();
    await tester.pump(AppMotion.base ~/ 2);
    expect(tester.widget<Opacity>(opacity).opacity, inExclusiveRange(0.5, 1));
    await tester.pumpAndSettle();
    expect(tester.widget<Opacity>(opacity).opacity, 1);
    expect(container.read(itineraryNotifierProvider).order, [0, 1, 2, 3]);
    expect(find.text('Skipped'), findsNothing);
  });

  testWidgets('reduced motion applies remove, restore and skip at once', (
    tester,
  ) async {
    final container = await pumpList(tester, reduceMotion: true);
    final notifier = container.read(itineraryNotifierProvider.notifier);
    final row = find.byKey(const ValueKey('result-stop-item-1'));
    final height = tester.getSize(row).height;
    notifier.remove(1);
    await tester.pump();
    expect(row, findsNothing);
    notifier.restoreRemoved();
    await tester.pump();
    expect(tester.getSize(row).height, height);
    notifier.toggleSkipped(1);
    await tester.pump();
    expect(
      tester
          .widget<Opacity>(find.byKey(const ValueKey('result-stop-opacity-1')))
          .opacity,
      0.5,
    );
    notifier.toggleSkipped(1);
    notifier.reorder(0, 2);
    await tester.pump();
    expect(inStop(0, find.text('3')), findsOneWidget);
    expect(container.read(itineraryNotifierProvider).skipped, isEmpty);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets(
    'leaving during remove, restore or skip disposes the animations',
    (tester) async {
      for (final change in ['remove', 'restore', 'skip']) {
        final container = await pumpList(tester);
        await tester.pumpAndSettle();
        final notifier = container.read(itineraryNotifierProvider.notifier);
        if (change == 'restore') {
          notifier.remove(1);
          await tester.pumpAndSettle();
          notifier.restoreRemoved();
        } else if (change == 'remove') {
          notifier.remove(1);
        } else {
          notifier.toggleSkipped(1);
        }
        await tester.pump();
        await tester.pump(AppMotion.base ~/ 2);
        expect(tester.binding.transientCallbackCount, greaterThan(0));
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull, reason: change);
        expect(tester.binding.transientCallbackCount, 0, reason: change);
      }
    },
  );

  testWidgets(
    'skip, remove, restore and a reorder drop give one light haptic',
    (tester) async {
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => calls.add(call),
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });
      final container = await pumpList(tester, editMode: true);
      final notifier = container.read(itineraryNotifierProvider.notifier);
      calls.clear();
      notifier.toggleSkipped(1);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('result-stop-remove-1')));
      await tester.pumpAndSettle();
      notifier.restoreRemoved();
      await tester.pumpAndSettle();
      final list = tester.widget<ReorderableListView>(
        find.byType(ReorderableListView),
      );
      list.onReorderEnd!(2);
      list.onReorderItem!(0, 2);
      await tester.pump();
      final haptics = calls.where(
        (call) => call.method == 'HapticFeedback.vibrate',
      );
      expect(haptics, hasLength(4));
      expect(
        haptics.map((call) => call.arguments),
        everyElement('HapticFeedbackType.lightImpact'),
      );
    },
  );

  testWidgets('long seeded rows have no layout exception at 360px', (
    tester,
  ) async {
    await pumpList(
      tester,
      itinerary: const Itinerary(
        title: 'Full NT: Darwin to Uluru',
        stops: seedStops,
      ),
      detailed: true,
      size: const Size(360, 640),
    );
    expect(tester.takeException(), isNull);

    await tester.fling(
      find.byKey(const ValueKey('result-stop-list-view')),
      const Offset(0, -1200),
      1200,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  group('entrance (D18)', () {
    /// Longer than any staggered entrance in the list can take.
    final entranceSettled =
        AppMotion.entrance +
        AppMotion.entranceStagger * AppMotion.entranceStaggerMaxItems;

    /// The opacity of the [Entrance] that carries [target].
    double entranceOpacity(WidgetTester tester, Finder target) {
      final entrance = find
          .ancestor(
            of: target,
            matching: find.byType(Entrance, skipOffstage: false),
          )
          .first;
      return tester
          .widget<Opacity>(
            find
                .descendant(
                  of: entrance,
                  matching: find.byType(Opacity, skipOffstage: false),
                  skipOffstage: false,
                )
                .first,
          )
          .opacity;
    }

    final firstCard = find.byKey(const ValueKey('result-stop-row-0'));

    testWidgets('the header and the first stop card fade in, then rest', (
      tester,
    ) async {
      await pumpList(tester);

      expect(entranceOpacity(tester, firstCard), lessThan(1));
      expect(entranceOpacity(tester, find.text('Header')), lessThan(1));

      await tester.pump(entranceSettled);

      expect(entranceOpacity(tester, firstCard), 1);
      expect(entranceOpacity(tester, find.text('Header')), 1);
    });

    testWidgets('leaving edit mode shows the cards at once', (tester) async {
      final container = await pumpList(tester);
      await tester.pump(entranceSettled);

      final notifier = container.read(itineraryNotifierProvider.notifier);
      notifier.setEditMode(true);
      await tester.pump();
      notifier.setEditMode(false);
      await tester.pump();

      expect(
        entranceOpacity(tester, firstCard),
        1,
        reason: 'a working-state change is not an arrival',
      );
      expect(entranceOpacity(tester, find.text('Header')), 1);
    });

    testWidgets('a hidden tab holds its entrance until it is shown', (
      tester,
    ) async {
      final selectedTab = ValueNotifier<int>(1);
      addTearDown(selectedTab.dispose);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: ValueListenableBuilder<int>(
                valueListenable: selectedTab,
                builder: (context, index, _) => IndexedStack(
                  index: index,
                  children: [
                    ResultStopList(
                      header: const Text('Header'),
                      detailed: false,
                      onOpenStop: (_) {},
                    ),
                    const SizedBox.shrink(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      final hiddenCard = find.byKey(
        const ValueKey('result-stop-row-0'),
        skipOffstage: false,
      );
      expect(
        entranceOpacity(tester, hiddenCard),
        1,
        reason: 'nothing plays while the tab is hidden',
      );

      selectedTab.value = 0;
      await tester.pump();
      expect(entranceOpacity(tester, firstCard), lessThan(1));

      await tester.pump(entranceSettled);
      expect(entranceOpacity(tester, firstCard), 1);
    });
  });
}
