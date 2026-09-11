import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terra_nt/core/theme/app_theme.dart';
import 'package:terra_nt/data/models/plan_entry.dart';
import 'package:terra_nt/data/models/stop.dart';
import 'package:terra_nt/data/repositories/notifiers.dart';
import 'package:terra_nt/data/seed/seed_data.dart';
import 'package:terra_nt/features/itinerary/stop_detail/stop_detail_screen.dart';

Future<ProviderContainer> pumpDetail(
  WidgetTester tester, {
  Stop? stop,
  int originalIndex = 0,
  StopMapsLauncher? launcher,
}) async {
  final selectedStop = stop ?? seedStops[0];
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.dark,
        home: const _ResultStub(),
      ),
    ),
  );
  final navigator = tester.state<NavigatorState>(find.byType(Navigator));
  navigator.push<void>(
    MaterialPageRoute<void>(
      builder: (_) => StopDetailScreen(
        stop: selectedStop,
        originalIndex: originalIndex,
        launcher: launcher ?? (_) async => true,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(
    tester.element(find.byType(StopDetailScreen)),
  );
}

class _ResultStub extends StatelessWidget {
  const _ResultStub();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Result')),
    );
  }
}

void main() {
  testWidgets('renders seeded copy and omits a missing fee', (tester) async {
    await pumpDetail(tester);

    expect(find.text(seedStops[0].name), findsOneWidget);
    expect(find.text(seedStops[0].subtitle), findsOneWidget);
    expect(find.text(seedStops[0].hours), findsOneWidget);
    expect(find.text(seedStops[0].aiNote), findsOneWidget);
    expect(find.text('Park entry fee'), findsNothing);
  });

  testWidgets('renders the fee only when one exists', (tester) async {
    await pumpDetail(tester, stop: seedStops[1], originalIndex: 1);

    expect(find.text('Park entry fee'), findsOneWidget);
    expect(find.text('Free entry'), findsOneWidget);
  });

  testWidgets('skip label follows the notifier state', (tester) async {
    final container = await pumpDetail(tester);
    expect(find.text('Skip'), findsOneWidget);

    container.read(itineraryNotifierProvider.notifier).toggleSkipped(0);
    await tester.pump();
    expect(find.text('Unskip'), findsOneWidget);
  });

  testWidgets('skip toggles the original index and pops', (tester) async {
    final container = await pumpDetail(tester, originalIndex: 2);
    await tester.tap(find.byKey(const ValueKey('stop-detail-skip')));
    await tester.pumpAndSettle();

    expect(container.read(itineraryNotifierProvider).skipped, contains(2));
    expect(find.byKey(const ValueKey('stop-detail-screen')), findsNothing);
    expect(find.text('Result'), findsOneWidget);
  });

  testWidgets('back returns to Result', (tester) async {
    await pumpDetail(tester);

    await tester.tap(find.byKey(const ValueKey('stop-detail-back-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('stop-detail-screen')), findsNothing);
    expect(find.text('Result'), findsOneWidget);
  });

  testWidgets('navigate launches the stop coordinates', (tester) async {
    Uri? launched;
    await pumpDetail(
      tester,
      stop: seedStops[1],
      originalIndex: 1,
      launcher: (url) async {
        launched = url;
        return true;
      },
    );

    await tester.tap(find.byKey(const ValueKey('stop-detail-navigate')));
    await tester.pump();

    expect(launched.toString(), contains('destination=-13.183%2C130.6805'));
  });

  testWidgets('has no layout exception at 360px width', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpDetail(tester, stop: seedStops[0]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not render bottom navigation', (tester) async {
    await pumpDetail(tester);

    expect(find.byKey(const ValueKey('bottom-nav')), findsNothing);
  });

  testWidgets('renders all detailedPlan entries under the header', (
    tester,
  ) async {
    final stop = Stop(
      name: 'Test Stop',
      subtitle: 'A stop with a plan',
      lat: -12.4634,
      lng: 130.8456,
      hours: '9:00am–5:00pm',
      duration: '1 day',
      aiNote: 'This stop has a schedule.',
      tags: const ['Nature'],
      detailedPlan: const [
        PlanEntry(time: '9:00am', activity: 'Arrive and check in'),
        PlanEntry(time: '1:00pm', activity: 'Lunch at the visitor centre'),
      ],
    );

    await pumpDetail(tester, stop: stop);

    expect(find.byKey(const ValueKey('stop-detail-plan')), findsOneWidget);
    expect(find.text('9:00am'), findsOneWidget);
    expect(find.text('Arrive and check in'), findsOneWidget);
    expect(find.text('1:00pm'), findsOneWidget);
    expect(find.text('Lunch at the visitor centre'), findsOneWidget);
  });

  testWidgets('renders the aiNote when detailedPlan is empty', (
    tester,
  ) async {
    final stop = Stop(
      name: 'Test Stop',
      subtitle: 'A stop with no plan',
      lat: -12.4634,
      lng: 130.8456,
      hours: '9:00am–5:00pm',
      duration: '1 day',
      aiNote: 'No detailed schedule for this stop yet.',
      tags: const ['Nature'],
      detailedPlan: const [],
    );

    await pumpDetail(tester, stop: stop);

    expect(find.byKey(const ValueKey('stop-detail-plan')), findsNothing);
    expect(find.text(stop.aiNote), findsOneWidget);
  });
}
