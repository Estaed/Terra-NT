import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terra_nt/core/theme/app_theme.dart';
import 'package:terra_nt/data/models/itinerary.dart';
import 'package:terra_nt/data/models/plan_entry.dart';
import 'package:terra_nt/data/models/stop.dart';
import 'package:terra_nt/data/repositories/notifiers.dart';
import 'package:terra_nt/data/seed/seed_data.dart';
import 'package:terra_nt/features/itinerary/widgets/result_stop_list.dart';

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

void main() {
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

    expect(inStop(0, find.text('Drive time unavailable')), findsOneWidget);
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
    expect(inStop(1, find.text('Drive time unavailable')), findsOneWidget);
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
    await tester.pump();

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
}
