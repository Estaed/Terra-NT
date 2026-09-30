import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terra_nt/core/theme/app_theme.dart';
import 'package:terra_nt/core/theme/motion.dart';
import 'package:terra_nt/data/models/plan_entry.dart';
import 'package:terra_nt/data/models/stop.dart';
import 'package:terra_nt/data/repositories/notifiers.dart';
import 'package:terra_nt/data/seed/seed_data.dart';
import 'package:terra_nt/features/itinerary/stop_detail/stop_detail_screen.dart';
import 'package:terra_nt/features/itinerary/widgets/result_stop_list.dart';
import 'package:terra_nt/shared/widgets/entrance.dart';
import 'package:terra_nt/shared/widgets/placeholder_tile.dart';

Future<ProviderContainer> pumpDetail(
  WidgetTester tester, {
  Stop? stop,
  int originalIndex = 0,
  StopMapsLauncher? launcher,
}) async {
  final selectedStop = stop ?? seedStops[0];
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(theme: AppTheme.dark, home: const _ResultStub()),
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
    return const Scaffold(body: Center(child: Text('Result')));
  }
}

Future<void> pumpPictureRoute(
  WidgetTester tester, {
  int originalIndex = 0,
  bool reduceMotion = false,
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(disableAnimations: reduceMotion),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: SingleChildScrollView(
              child: ResultStopRow(
                stop: seedStops[originalIndex],
                originalIndex: originalIndex,
                position: originalIndex,
                order: List.generate(seedStops.length, (index) => index),
                baselineStops: seedStops,
                detailed: false,
                editMode: false,
                skipped: false,
                onRevert: () {},
                onRemove: () {},
                onOpen: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => StopDetailScreen(
                      stop: seedStops[originalIndex],
                      originalIndex: originalIndex,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
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

  testWidgets('hours label and value share a left edge with the value below', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpDetail(tester);
    await tester.ensureVisible(find.text(seedStops[0].hours));
    await tester.pumpAndSettle();
    final label = tester.getRect(find.text('Hours'));
    final value = tester.getRect(find.text(seedStops[0].hours));
    expect(value.left, label.left);
    expect(value.top, greaterThan(label.bottom));
    expect(
      tester.widget<Text>(find.text(seedStops[0].hours)).textAlign,
      TextAlign.left,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'every stop keeps its unique picture tag from Result into detail',
    (tester) async {
      final tags = <Object>{};
      for (var index = 0; index < seedStops.length; index++) {
        await pumpPictureRoute(tester, originalIndex: index);
        final sourceTag = tester.widget<Hero>(find.byType(Hero)).tag;
        expect(tags.add(sourceTag), isTrue);
        await tester.tap(find.byKey(ValueKey('result-stop-row-$index')));
        await tester.pumpAndSettle();
        final detailTag = tester.widget<Hero>(find.byType(Hero)).tag;
        expect(detailTag, sourceTag, reason: seedStops[index].name);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );

  testWidgets(
    'the picture flies between the card and hero in both directions',
    (tester) async {
      await pumpPictureRoute(tester);
      final cardRect = tester.getRect(find.byType(PlaceholderTile));
      await tester.tap(find.byKey(const ValueKey('result-stop-row-0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final outboundRect = tester.getRect(find.byType(PlaceholderTile));
      expect(outboundRect.height, greaterThan(cardRect.height));
      await tester.pumpAndSettle();
      final heroRect = tester.getRect(find.byType(PlaceholderTile));
      expect(outboundRect.height, lessThan(heroRect.height));

      await tester.tap(find.byKey(const ValueKey('stop-detail-back-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final inboundRect = tester.getRect(find.byType(PlaceholderTile));
      expect(
        inboundRect.height,
        inExclusiveRange(cardRect.height, heroRect.height),
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byType(PlaceholderTile)), cardRect);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('reduced motion disables the Hero on both routes', (
    tester,
  ) async {
    await pumpPictureRoute(tester, reduceMotion: true);
    final pictureModes = find.descendant(
      of: find.byType(StopPicture),
      matching: find.byType(HeroMode),
    );
    expect(tester.widget<HeroMode>(pictureModes).enabled, isFalse);
    await tester.tap(find.byKey(const ValueKey('result-stop-row-0')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final picture = find.descendant(
      of: find.byType(StopDetailScreen),
      matching: find.byType(PlaceholderTile),
    );
    expect(
      picture,
      findsOneWidget,
      reason: 'the destination stays in its route',
    );
    expect(
      tester.widgetList<HeroMode>(pictureModes).map((mode) => mode.enabled),
      everyElement(false),
    );
    final size = tester.getSize(picture);
    await tester.pumpAndSettle();
    expect(tester.getSize(picture), size);
    await tester.tap(find.byKey(const ValueKey('stop-detail-back-button')));
    await tester.pumpAndSettle();
    expect(find.byType(ResultStopRow), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('detail Skip gives exactly one light haptic and pops', (
    tester,
  ) async {
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
    final container = await pumpDetail(tester);
    calls.clear();
    await tester.tap(find.byKey(const ValueKey('stop-detail-skip')));
    await tester.pumpAndSettle();
    final haptics = calls.where(
      (call) => call.method == 'HapticFeedback.vibrate',
    );
    expect(haptics, hasLength(1));
    expect(haptics.single.arguments, 'HapticFeedbackType.lightImpact');
    expect(container.read(itineraryNotifierProvider).skipped, {0});
    expect(find.text('Result'), findsOneWidget);
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

  testWidgets('renders the aiNote when detailedPlan is empty', (tester) async {
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
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('detailed-plan-empty')))
          .data,
      'No detailed plan for this stop.',
    );
    expect(find.text(stop.aiNote), findsOneWidget);
  });

  testWidgets('the sections below the hero enter in reading order', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.dark,
          home: StopDetailScreen(stop: seedStops[0], originalIndex: 0),
        ),
      ),
    );

    Finder entranceOf(Finder target) =>
        find.ancestor(of: target, matching: find.byType(Entrance));
    double opacityOf(Finder target) => tester
        .widget<Opacity>(
          find
              .descendant(
                of: entranceOf(target),
                matching: find.byType(Opacity),
              )
              .first,
        )
        .opacity;
    final name = find.byKey(const ValueKey('stop-detail-name'));
    final note = find.byKey(const ValueKey('stop-detail-ai-note'));

    await tester.pump(AppMotion.entrance ~/ 2);
    expect(opacityOf(name), inExclusiveRange(0, 1));
    expect(
      opacityOf(note),
      lessThan(opacityOf(name)),
      reason: 'the AI note follows the heading',
    );
    expect(
      entranceOf(find.byKey(const ValueKey('stop-detail-back-button'))),
      findsNothing,
      reason: 'the hero arrives with the page itself',
    );
    expect(
      entranceOf(find.byKey(const ValueKey('stop-detail-footer'))),
      findsNothing,
    );

    await tester.pumpAndSettle();
    expect(opacityOf(name), 1);
    expect(opacityOf(note), 1);
  });
}
