import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terra_nt/core/theme/app_theme.dart';
import 'package:terra_nt/core/theme/motion.dart';
import 'package:terra_nt/core/theme/metrics.dart';
import 'package:terra_nt/core/util/itinerary_ops.dart';
import 'package:terra_nt/data/models/plan_entry.dart';
import 'package:terra_nt/data/models/stop.dart';
import 'package:terra_nt/data/repositories/notifiers.dart';
import 'package:terra_nt/data/seed/seed_data.dart';
import 'package:terra_nt/features/itinerary/stop_detail/stop_detail_screen.dart';
import 'package:terra_nt/features/itinerary/widgets/result_stop_list.dart';
import 'package:terra_nt/shared/widgets/entrance.dart';
import 'package:terra_nt/shared/widgets/app_icon.dart';
import 'package:terra_nt/shared/widgets/placeholder_tile.dart';

Future<ProviderContainer> pumpDetail(
  WidgetTester tester, {
  Stop? stop,
  int originalIndex = 0,
  StopMapsLauncher? launcher,
  double textScale = 1,
}) async {
  final selectedStop = stop ?? seedStops[0];
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
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
  for (final scale in [1.0, 2.0]) {
    testWidgets('schedule times stay whole at ${scale}x text on 360px', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      // The audited stop includes the longer 11:00am time, as well as am/pm.
      final stop = seedStops.last;
      expect(stop.detailedPlan.map((entry) => entry.time), contains('11:00am'));
      await pumpDetail(tester, stop: stop, textScale: scale);
      for (final entry in stop.detailedPlan) {
        final time = find.text(entry.time);
        await tester.ensureVisible(time);
        await tester.pumpAndSettle();
        final paragraph = tester.renderObject<RenderParagraph>(time);
        final boxes = paragraph.getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: entry.time.length),
        );
        expect(boxes, isNotEmpty);
        expect(
          boxes.map((box) => box.top).toSet(),
          hasLength(1),
          reason: entry.time,
        );
        expect(paragraph.didExceedMaxLines, isFalse, reason: entry.time);
        for (final box in boxes) {
          expect(box.left, greaterThanOrEqualTo(0));
          expect(box.right, lessThanOrEqualTo(paragraph.size.width));
        }
        expect(find.text(entry.activity), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      await tester.ensureVisible(find.text(stop.hours));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.text(stop.hours)).left,
        tester.getRect(find.text('Hours')).left,
      );
      if (stop.fee != null) {
        expect(
          tester.getRect(find.text(stop.fee!)).left,
          tester.getRect(find.text('Park entry fee')).left,
        );
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Back is named and works through its semantic action', (
    tester,
  ) async {
    await pumpDetail(tester);
    final node = tester.getSemantics(find.bySemanticsLabel('Back'));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    tester.binding.renderViews.single.owner!.semanticsOwner!.performAction(
      node.id,
      SemanticsAction.tap,
    );
    await tester.pumpAndSettle();
    expect(find.text('Result'), findsOneWidget);
    expect(find.byType(StopDetailScreen), findsNothing);
  });

  testWidgets('detail follows active legs after skip, removal and reorder', (
    tester,
  ) async {
    final container = await pumpDetail(tester);
    final notifier = container.read(itineraryNotifierProvider.notifier);
    expect(find.text(seedStops[0].driveNext!), findsOneWidget);
    notifier.toggleSkipped(1);
    await tester.pumpAndSettle();
    var state = container.read(itineraryNotifierProvider);
    expect(
      find.text(
        driveNextForPosition(
          state.order,
          0,
          seedStops,
          skipped: state.skipped,
        )!,
      ),
      findsOneWidget,
    );
    expect(find.text(seedStops[0].driveNext!), findsNothing);
    notifier.remove(2);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('km straight line to Nitmiluk Gorge, Katherine'),
      findsOneWidget,
    );
    notifier.reorder(0, state.order.length);
    await tester.pumpAndSettle();
    expect(find.text('Next active stop'), findsNothing);
    notifier.reset();
    notifier.toggleSkipped(0);
    await tester.pumpAndSettle();
    expect(find.text('Next active stop'), findsNothing);
  });

  testWidgets('road conditions opens the NT link with a connection notice', (
    tester,
  ) async {
    Uri? launched;
    await pumpDetail(
      tester,
      launcher: (url) async {
        launched = url;
        return true;
      },
    );
    final link = find.byKey(const ValueKey('stop-detail-road-conditions'));
    await tester.ensureVisible(link);
    await tester.pumpAndSettle();
    expect(find.text('An internet connection is needed.'), findsOneWidget);
    await tester.tap(link);
    await tester.pumpAndSettle();
    expect(
      launched,
      Uri.parse('https://nt.gov.au/driving/safety/check-road-conditions'),
    );
    expect(find.byType(StopDetailScreen), findsOneWidget);
  });

  for (final throws in [false, true]) {
    testWidgets(
      'road link handles ${throws ? 'an exception' : 'a refusal'} and retries',
      (tester) async {
        var calls = 0;
        await pumpDetail(
          tester,
          launcher: (_) async {
            calls++;
            if (calls > 1) return true;
            if (throws) throw PlatformException(code: 'unavailable');
            return false;
          },
        );
        final link = find.byKey(const ValueKey('stop-detail-road-conditions'));
        await tester.ensureVisible(link);
        await tester.pumpAndSettle();
        await tester.tap(link);
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Road conditions could not be opened.'),
          findsOneWidget,
        );
        await tester.tap(link);
        await tester.pumpAndSettle();
        expect(calls, 2);
        expect(
          find.textContaining('Road conditions could not be opened.'),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'practical sections show clock and ticket without narrowing values',
    (tester) async {
      await pumpDetail(tester, stop: seedStops[1], originalIndex: 1);
      final icons = tester
          .widgetList<AppIcon>(find.byType(AppIcon))
          .map((icon) => icon.icon);
      expect(icons, containsAll([LucideIcons.clock, LucideIcons.ticket]));
      expect(
        tester.getTopLeft(find.text('Hours')).dx,
        tester.getTopLeft(find.text(seedStops[1].hours)).dx,
      );
      expect(
        tester.getTopLeft(find.text('Park entry fee')).dx,
        tester.getTopLeft(find.text(seedStops[1].fee!)).dx,
      );
    },
  );

  testWidgets('detail actions stay at 2x text with 48px targets at 360px', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = await pumpDetail(
      tester,
      stop: seedStops[1],
      originalIndex: 1,
      textScale: 2,
    );
    expect(find.byType(FittedBox), findsNothing);
    for (final key in ['stop-detail-skip', 'stop-detail-navigate']) {
      final target = find.byKey(ValueKey(key));
      expect(
        tester.getSize(target).height,
        greaterThanOrEqualTo(AppMetrics.minTouchTarget),
      );
      expect(
        tester.getSize(target).width,
        greaterThanOrEqualTo(AppMetrics.minTouchTarget),
      );
      final text = find.descendant(of: target, matching: find.byType(Text));
      expect(MediaQuery.textScalerOf(tester.element(text)).scale(14), 28);
    }
    container.read(itineraryNotifierProvider.notifier).toggleSkipped(1);
    await tester.pumpAndSettle();
    expect(find.text('Unskip'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const ValueKey('stop-detail-road-conditions')),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

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

  for (final throws in [false, true]) {
    testWidgets(
      'Navigate launch ${throws ? 'exception' : 'refusal'} offers copy coordinates',
      (tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
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
        await pumpDetail(
          tester,
          stop: seedStops[1],
          launcher: (_) async {
            if (throws) throw PlatformException(code: 'unavailable');
            return false;
          },
        );
        await tester.tap(find.byKey(const ValueKey('stop-detail-navigate')));
        await tester.pumpAndSettle();
        expect(
          find.text(
            'Google Maps could not be opened. You can copy the destination coordinates instead.',
          ),
          findsOneWidget,
        );
        await tester.tap(find.text('Copy destination coordinates'));
        await tester.pumpAndSettle();
        expect(copied, ['-13.183,130.6805']);
        expect(find.text('Coordinates copied'), findsOneWidget);
        expect(find.byType(StopDetailScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('failed online detail photo shows the bundled place picture', (
    tester,
  ) async {
    const stop = Stop(
      name: 'Darwin',
      subtitle: '',
      lat: -12.4,
      lng: 130.8,
      hours: '',
      duration: '1 day',
      aiNote: '',
      tags: ['Nature'],
      detailedPlan: [],
      photoUrl: 'https://example.invalid/detail-photo.jpg',
    );
    await pumpDetail(tester, stop: stop);
    await tester.runAsync(() async => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    final assets = tester
        .widgetList<Image>(find.byType(Image))
        .map((image) => image.image)
        .whereType<AssetImage>();
    expect(
      assets.map((image) => image.assetName),
      contains('assets/images/places/darwin.jpg'),
    );
    expect(tester.takeException(), isNull);
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
