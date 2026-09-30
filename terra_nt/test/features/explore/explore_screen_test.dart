import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:terra_nt/core/theme/app_theme.dart';
import 'package:terra_nt/core/theme/colors.dart';
import 'package:terra_nt/core/theme/motion.dart';
import 'package:terra_nt/data/models/poi.dart';
import 'package:terra_nt/data/repositories/notifiers.dart';
import 'package:terra_nt/core/theme/metrics.dart';
import 'package:terra_nt/data/seed/seed_data.dart';
import 'package:terra_nt/features/explore/explore_screen.dart';
import 'package:terra_nt/shared/map/map_markers.dart';
import 'package:terra_nt/shared/map/terra_map.dart';
import 'package:terra_nt/shared/widgets/tag_dot.dart';
import 'package:terra_nt/shared/widgets/app_icon.dart';

Future<void> pumpExplore(
  WidgetTester tester, {
  MapController? controller,
  List<Poi>? pois,
  bool reducedMotion = false,
  ExploreMapsLauncher? launcher,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [if (pois != null) poiProvider.overrideWithValue(pois)],
      child: MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(disableAnimations: reducedMotion),
          child: child!,
        ),
        home: SizedBox(
          width: 360,
          height: 700,
          child: ExploreScreen(
            mapController: controller,
            launcher: launcher ?? (_) async => true,
          ),
        ),
      ),
    ),
  );
}

List<Poi> controlledPois(List<int> sourceIndices) => [
  for (var index = 0; index < sourceIndices.length; index++)
    Poi(
      id: seedPois[sourceIndices[index]].id,
      name: seedPois[sourceIndices[index]].name,
      tag: seedPois[sourceIndices[index]].tag,
      rating: seedPois[sourceIndices[index]].rating,
      description: seedPois[sourceIndices[index]].description,
      lat: -18.0 - index * 2.0,
      lng: 132.0 + index * 2.0,
    ),
];

Future<void> focusMap(WidgetTester tester, MapController controller) async {
  controller.move(const LatLng(-18, 132), 5);
  await tester.pump();
}

ExploreState exploreState(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(ExploreScreen)))
        .read(exploreNotifierProvider);

Set<Key?> markerKeys(WidgetTester tester) => tester
    .widget<TerraMap>(find.byType(TerraMap))
    .markers
    .map((marker) => marker.key)
    .toSet();

void main() {
  testWidgets(
    'every POI marker speaks its place name and selection works without a tap',
    (tester) async {
      final controller = MapController();
      await pumpExplore(tester, controller: controller, reducedMotion: true);
      await tester.pumpAndSettle();
      // The widget labels exist for all places; map culling may remove an
      // off-screen marker from the current semantics tree.
      for (final poi in seedPois) {
        final marker = tester
            .widget<TerraMap>(find.byType(TerraMap))
            .markers
            .singleWhere(
              (marker) => marker.key == ValueKey('explore-marker-${poi.id}'),
            );
        expect((marker.child as PoiPinMarker).placeName, poi.name);
      }
      await tester.enterText(
        find.byKey(const ValueKey('explore-search-field')),
        'Mindil',
      );
      await tester.pumpAndSettle();
      final markerNode = tester.getSemantics(find.byType(PoiPinMarker));
      expect(markerNode.label, 'Mindil Beach');
      expect(
        markerNode.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
      );
      final close = tester.getSemantics(find.bySemanticsLabel('Close'));
      expect(close.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      tester.binding.renderViews.single.owner!.semanticsOwner!.performAction(
        close.id,
        SemanticsAction.tap,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('explore-poi-card')), findsNothing);
      tester.binding.renderViews.single.owner!.semanticsOwner!.performAction(
        markerNode.id,
        SemanticsAction.tap,
      );
      await tester.pumpAndSettle();
      expect(exploreState(tester).selectedPoiId, 'mindil');
      expect(find.byKey(const ValueKey('explore-poi-card')), findsOneWidget);
    },
  );

  testWidgets(
    'empty search shows one muted search_x and Clear search still works',
    (tester) async {
      await pumpExplore(tester, reducedMotion: true);
      await tester.enterText(
        find.byKey(const ValueKey('explore-search-field')),
        'no-such-place',
      );
      await tester.pumpAndSettle();
      final icon = tester.widget<AppIcon>(
        find.byKey(const ValueKey('explore-empty-search-icon')),
      );
      expect(icon.icon, LucideIcons.search_x);
      expect(icon.color, AppColors.inkTertiary);
      expect(find.text('No places match your search.'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('explore-clear-search')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('explore-empty-search-icon')),
        findsNothing,
      );
      expect(markerKeys(tester), hasLength(seedPois.length));
    },
  );

  testWidgets('selection eases the camera into the strip above the card', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = MapController();
    final pois = controlledPois([0, 1]);
    await pumpExplore(tester, controller: controller, pois: pois);
    controller.move(const LatLng(-12, 130), 5);
    await tester.pump();
    final before = controller.camera.center;
    final place = LatLng(pois.last.lat, pois.last.lng);
    final distanceBefore = const Distance().as(LengthUnit.Meter, before, place);
    await tester.tap(find.byType(PoiPinMarker).last);
    await tester.pump();
    expect(controller.camera.center, before);
    await tester.pump();
    await tester.pump(AppMotion.entrance ~/ 2);
    final halfway = controller.camera.center;
    expect(halfway, isNot(before));
    expect(
      const Distance().as(LengthUnit.Meter, halfway, place),
      lessThan(distanceBefore),
    );
    await tester.pump(AppMotion.entrance);
    expect(controller.camera.center, isNot(halfway));
    final position = controller.camera.latLngToScreenOffset(place);
    final card = tester.getRect(find.byKey(const ValueKey('explore-poi-card')));
    final search = tester.getRect(
      find.byKey(const ValueKey('explore-search-target')),
    );
    expect(position.dx, closeTo(180, 1));
    expect(
      position.dy - AppMetrics.minTouchTarget / 2,
      greaterThan(search.bottom),
    );
    expect(position.dy + AppMetrics.minTouchTarget / 2, lessThan(card.top));
    expect(tester.takeException(), isNull);
  });

  testWidgets('uluru search flies to its single match and clears selection', (
    tester,
  ) async {
    final controller = MapController();
    await pumpExplore(tester, controller: controller);
    final before = controller.camera.center;
    final field = find.byKey(const ValueKey('explore-search-field'));
    await tester.enterText(field, 'uluru');
    await tester.pump();
    await tester.pump();
    await tester.pump(AppMotion.entrance);
    expect(exploreState(tester).selectedPoiId, 'uluru');
    expect(find.text('Uluru'), findsOneWidget);
    expect(controller.camera.center, isNot(before));
    final selected = seedPois.singleWhere((poi) => poi.id == 'uluru');
    final position = controller.camera.latLngToScreenOffset(
      LatLng(selected.lat, selected.lng),
    );
    expect(
      position.dy,
      lessThan(
        tester.getRect(find.byKey(const ValueKey('explore-poi-card'))).top,
      ),
    );
    await tester.enterText(field, '   ');
    await tester.pump();
    expect(exploreState(tester).selectedPoiId, isNull);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('explore-poi-card')), findsNothing);
    expect(markerKeys(tester), {
      for (final poi in seedPois) ValueKey('explore-marker-${poi.id}'),
    });
  });

  testWidgets('Navigate launches driving directions to the selected POI', (
    tester,
  ) async {
    Uri? launched;
    await pumpExplore(
      tester,
      launcher: (url) async {
        launched = url;
        return true;
      },
    );
    await tester.enterText(
      find.byKey(const ValueKey('explore-search-field')),
      'uluru',
    );
    await tester.pump();
    await tester.pump(AppMotion.entrance);
    await tester.tap(find.byKey(const ValueKey('explore-poi-navigate')));
    await tester.pump();
    expect(launched?.scheme, 'https');
    expect(launched?.host, 'www.google.com');
    expect(launched?.path, '/maps/dir/');
    expect(launched?.queryParameters, {
      'api': '1',
      'destination': '-25.3444,131.0369',
      'travelmode': 'driving',
    });
  });

  testWidgets(
    'rapid changes and reopening during exit keep the last selection',
    (tester) async {
      final controller = MapController();
      await pumpExplore(tester, controller: controller);
      final field = find.byKey(const ValueKey('explore-search-field'));
      await tester.enterText(field, 'uluru');
      await tester.pump();
      await tester.pump(AppMotion.entrance ~/ 4);
      await tester.enterText(field, 'mindil');
      await tester.pump();
      await tester.pump(AppMotion.entrance ~/ 4);
      await tester.enterText(field, '');
      await tester.pump();
      await tester.pump(AppMotion.entrance ~/ 4);
      await tester.enterText(field, 'kings');
      await tester.pumpAndSettle();
      expect(exploreState(tester).selectedPoiId, 'kingscanyon');
      expect(find.byKey(const ValueKey('explore-poi-card')), findsOneWidget);
      expect(find.text('Kings Canyon'), findsOneWidget);
      expect(find.text('Mindil Beach'), findsNothing);
      expect(find.text('Uluru'), findsNothing);
      final poi = seedPois.singleWhere((poi) => poi.id == 'kingscanyon');
      final pin = controller.camera.latLngToScreenOffset(
        LatLng(poi.lat, poi.lng),
      );
      expect(
        pin.dy,
        lessThan(
          tester.getRect(find.byKey(const ValueKey('explore-poi-card'))).top,
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a manual map gesture stops the selection flight', (
    tester,
  ) async {
    final controller = MapController();
    await pumpExplore(tester, controller: controller);
    await tester.enterText(
      find.byKey(const ValueKey('explore-search-field')),
      'uluru',
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(AppMotion.entrance ~/ 4);
    final map = tester.getRect(find.byType(FlutterMap));
    final gesture = await tester.startGesture(
      Offset(map.center.dx, map.top + 120),
    );
    await gesture.moveBy(const Offset(40, 0));
    await tester.pump();
    final interrupted = controller.camera.center;
    await tester.pump(AppMotion.entrance);
    expect(controller.camera.center, interrupted);
    expect(exploreState(tester).selectedPoiId, 'uluru');
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion changes camera, marker and card immediately', (
    tester,
  ) async {
    final controller = MapController();
    await pumpExplore(tester, controller: controller, reducedMotion: true);
    final before = controller.camera.center;
    final field = find.byKey(const ValueKey('explore-search-field'));
    await tester.enterText(field, 'uluru');
    await tester.pump();
    expect(controller.camera.center, isNot(before));
    final settled = controller.camera.center;
    final card = find.byKey(const ValueKey('explore-poi-card'));
    final fade = tester.widget<FadeTransition>(
      find.ancestor(of: card, matching: find.byType(FadeTransition)).first,
    );
    expect(fade.opacity.value, 1);
    final scale = tester.widget<AnimatedScale>(
      find.descendant(
        of: find.byType(PoiPinMarker),
        matching: find.byType(AnimatedScale),
      ),
    );
    expect(scale.duration, Duration.zero);
    expect(scale.scale, AppMotion.loadingPulseMaxScale);
    final frame = tester.getRect(card);
    await tester.pump(AppMotion.entrance ~/ 2);
    expect(controller.camera.center, settled);
    expect(tester.getRect(card), frame);
    await tester.enterText(field, 'mindil');
    await tester.pump();
    await tester.pump();
    expect(find.text('Mindil Beach'), findsOneWidget);
    expect(find.text('Uluru'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('explore-poi-close')));
    await tester.pump();
    expect(card, findsNothing);
    expect(exploreState(tester).selectedPoiId, isNull);
    expect(tester.takeException(), isNull);
  });

  for (final injectController in [false, true]) {
    testWidgets(
      'leaving Explore mid-animation disposes tickers (injected: $injectController)',
      (tester) async {
        final controller = injectController ? MapController() : null;
        if (controller != null) addTearDown(controller.dispose);
        await pumpExplore(tester, controller: controller);
        await tester.enterText(
          find.byKey(const ValueKey('explore-search-field')),
          'uluru',
        );
        await tester.pump();
        await tester.pump(AppMotion.entrance ~/ 4);
        expect(tester.binding.transientCallbackCount, greaterThan(0));
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(AppMotion.entrance);
        expect(tester.binding.transientCallbackCount, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('markers show category icons and keep 48px targets', (
    tester,
  ) async {
    await pumpExplore(tester);
    final categories = {
      'Nature': LucideIcons.tree_pine,
      'Culture': LucideIcons.landmark,
      'Adventure': LucideIcons.mountain,
      'Wildlife': LucideIcons.paw_print,
      'Relaxation': LucideIcons.waves_horizontal,
    };
    for (final element in find.byType(PoiPinMarker).evaluate()) {
      final marker = element.widget as PoiPinMarker;
      final icon = tester.widget<AppIcon>(
        find.descendant(
          of: find.byWidget(marker),
          matching: find.byType(AppIcon),
        ),
      );
      expect(icon.icon, categories[marker.tag]);
    }
    final layer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
    for (final marker in layer.markers) {
      expect(marker.width, greaterThanOrEqualTo(AppMetrics.minTouchTarget));
      expect(marker.height, greaterThanOrEqualTo(AppMetrics.minTouchTarget));
    }
    await tester.pumpWidget(
      const MaterialApp(
        home: PoiPinMarker(tag: 'Unknown', accent: AppColors.inkTertiary),
      ),
    );
    expect(
      tester.widget<AppIcon>(find.byType(AppIcon)).icon,
      LucideIcons.map_pin,
    );
  });

  testWidgets('renders all POI markers at their POI coordinates', (
    tester,
  ) async {
    final controller = MapController();
    await pumpExplore(tester, controller: controller);
    await tester.pump();

    expect(find.byType(PoiPinMarker), findsNWidgets(15));
    final ubirr = tester
        .widget<TerraMap>(find.byType(TerraMap))
        .markers
        .singleWhere(
          (marker) => marker.key == const ValueKey('explore-marker-ubirr'),
        );
    expect(ubirr.point, const LatLng(-12.4260, 132.9760));
    expect(tester.takeException(), isNull);
  });

  testWidgets('marker selection swaps and closes the single info card', (
    tester,
  ) async {
    final controller = MapController();
    await pumpExplore(
      tester,
      controller: controller,
      pois: controlledPois([0, 1]),
    );
    await tester.pump();
    await focusMap(tester, controller);

    await tester.tap(find.byType(PoiPinMarker).at(0));
    await tester.pump();
    await tester.pump(AppMotion.entrance);
    expect(find.byKey(const ValueKey('explore-poi-card')), findsOneWidget);
    expect(find.text('Darwin Waterfront'), findsOneWidget);
    expect(find.text('4.6'), findsOneWidget);
    expect(
      find.text(
        'Historic wave pool, dining and sunset views right on the harbour.',
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<TagDot>(find.byType(TagDot)).color,
      AppColors.tagYellow,
    );

    await tester.tap(find.byType(PoiPinMarker).at(1));
    await tester.pump();
    await tester.pump(AppMotion.entrance);
    expect(find.byKey(const ValueKey('explore-poi-card')), findsOneWidget);
    expect(find.text('Mindil Beach'), findsOneWidget);
    expect(find.text('Darwin Waterfront'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('explore-poi-close')));
    await tester.pump();
    expect(exploreState(tester).selectedPoiId, isNull);
    expect(find.byKey(const ValueKey('explore-poi-card')), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('explore-poi-card')), findsNothing);
    expect(exploreState(tester).selectedPoiId, isNull);
  });

  testWidgets('the card slides in, crossfades content, and slides away', (
    tester,
  ) async {
    final controller = MapController();
    await pumpExplore(
      tester,
      controller: controller,
      pois: controlledPois([0, 1]),
    );
    await tester.pump();
    await focusMap(tester, controller);

    final card = find.byKey(const ValueKey('explore-poi-card'));
    double cardOpacity() => tester
        .widget<FadeTransition>(
          find.ancestor(of: card, matching: find.byType(FadeTransition)).first,
        )
        .opacity
        .value;

    await tester.tap(find.byType(PoiPinMarker).at(0));
    await tester.pump();
    expect(cardOpacity(), lessThan(1));
    final firstFrame = tester.getRect(card);

    await tester.pump(AppMotion.entrance);
    expect(cardOpacity(), 1);
    expect(tester.getRect(card).top, lessThan(firstFrame.top));
    final surface = tester.element(card);

    await tester.tap(find.byType(PoiPinMarker).at(1));
    await tester.pump();
    expect(cardOpacity(), 1, reason: 'the same surface stays open');
    expect(tester.element(card), same(surface));
    await tester.pump(AppMotion.base ~/ 2);
    for (final name in ['Darwin Waterfront', 'Mindil Beach']) {
      final fade = tester.widget<FadeTransition>(
        find
            .ancestor(
              of: find.text(name),
              matching: find.byType(FadeTransition),
            )
            .first,
      );
      expect(fade.opacity.value, inExclusiveRange(0, 1));
    }
    await tester.pump(AppMotion.entrance);
    expect(find.text('Darwin Waterfront'), findsNothing);
    final restingTop = tester.getRect(card).top;
    await tester.tap(find.byKey(const ValueKey('explore-poi-close')));
    await tester.pump();
    await tester.pump(AppMotion.entrance ~/ 2);
    expect(tester.getRect(card).top, greaterThan(restingTop));
    expect(card.hitTestable(), findsNothing);
    await tester.pump(AppMotion.entrance);
    expect(card, findsNothing);
  });

  testWidgets('Nature and Culture cards use their tag colours', (tester) async {
    final controller = MapController();
    await pumpExplore(
      tester,
      controller: controller,
      pois: controlledPois([2, 1]),
    );
    await tester.pump();
    await focusMap(tester, controller);

    await tester.tap(find.byType(PoiPinMarker).at(0));
    await tester.pump();
    await tester.pump(AppMotion.entrance);
    expect(
      tester.widget<TagDot>(find.byType(TagDot)).color,
      AppColors.tagGreen,
    );

    await tester.tap(find.byType(PoiPinMarker).at(1));
    await tester.pump();
    await tester.pump(AppMotion.entrance);
    expect(
      tester.widget<TagDot>(find.byType(TagDot)).color,
      AppColors.tagPurple,
    );
  });

  testWidgets('a single search match selects its card and clearing deselects', (
    tester,
  ) async {
    final controller = MapController();
    await pumpExplore(
      tester,
      controller: controller,
      pois: controlledPois([0, 6]),
    );
    await tester.pump();
    await focusMap(tester, controller);
    await tester.tap(find.byType(PoiPinMarker).at(0));
    await tester.pump();
    await tester.pump(AppMotion.entrance);
    await tester.enterText(
      find.byKey(const ValueKey('explore-search-field')),
      'KINGS',
    );
    await tester.pump();
    await tester.pump(AppMotion.entrance);
    expect(find.byType(PoiPinMarker), findsOneWidget);
    expect(find.byKey(const ValueKey('explore-poi-card')), findsOneWidget);
    expect(find.text('Kings Canyon'), findsOneWidget);
    expect(exploreState(tester).selectedPoiId, 'kingscanyon');
    final center = controller.camera.center;

    await tester.enterText(
      find.byKey(const ValueKey('explore-search-field')),
      'missing',
    );
    await tester.pump();
    await tester.pump(AppMotion.entrance);
    expect(find.byType(PoiPinMarker), findsNothing);
    expect(find.text('No places match your search.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('explore-clear-search')));
    await tester.pump();
    expect(find.byType(PoiPinMarker), findsNWidgets(2));
    expect(find.text('No places match your search.'), findsNothing);
    expect(exploreState(tester).selectedPoiId, isNull);
    expect(controller.camera.center, center);
  });

  testWidgets(
    'real seeded search handles trim, case, tags, descriptions, and field clearing',
    (tester) async {
      final controller = MapController();
      await pumpExplore(tester, controller: controller);
      await tester.pump();
      final zoom = controller.camera.zoom;
      final field = find.byKey(const ValueKey('explore-search-field'));
      final textField = tester.widget<TextField>(field);
      expect(textField.decoration!.hintText, 'Search the Territory');

      await tester.enterText(field, ' UbIrR ');
      await tester.pump();
      await tester.pump(AppMotion.entrance);
      expect(find.byType(PoiPinMarker), findsOneWidget);
      expect(markerKeys(tester), {const ValueKey('explore-marker-ubirr')});
      expect(exploreState(tester).selectedPoiId, 'ubirr');
      expect(
        find.text(seedPois.singleWhere((poi) => poi.id == 'ubirr').name),
        findsOneWidget,
      );
      final center = controller.camera.center;
      expect(controller.camera.zoom, zoom);

      await tester.enterText(field, ' CuLtUrE ');
      await tester.pump();
      expect(find.byType(PoiPinMarker), findsNWidgets(5));
      expect(markerKeys(tester), {
        const ValueKey('explore-marker-mindil'),
        const ValueKey('explore-marker-ubirr'),
        const ValueKey('explore-marker-uluru'),
        const ValueKey('explore-marker-kata-tjuta'),
        const ValueKey('explore-marker-karlu-karlu'),
      });
      expect(controller.camera.center, center);
      expect(controller.camera.zoom, zoom);

      await tester.enterText(field, 'floodplain');
      await tester.pump();
      await tester.pump(AppMotion.entrance);
      expect(find.byType(PoiPinMarker), findsNothing);
      expect(find.text('No places match your search.'), findsOneWidget);
      expect(controller.camera.center, center);
      expect(controller.camera.zoom, zoom);

      await tester.tap(find.byKey(const ValueKey('explore-clear-search')));
      await tester.pump();
      expect(textField.controller!.text, isEmpty);
      expect(exploreState(tester).selectedPoiId, isNull);
      expect(find.byType(PoiPinMarker), findsNWidgets(15));
      expect(controller.camera.center, center);
      expect(controller.camera.zoom, zoom);

      await tester.enterText(field, 'mindil');
      await tester.pump();
      await tester.enterText(field, '');
      await tester.pump();
      await tester.pump(AppMotion.entrance);
      expect(exploreState(tester).selectedPoiId, isNull);
      expect(find.byKey(const ValueKey('explore-poi-card')), findsNothing);
      expect(find.byType(PoiPinMarker), findsNWidgets(15));
      expect(find.text('No places match your search.'), findsNothing);
      expect(controller.camera.center, center);
      expect(controller.camera.zoom, zoom);
    },
  );

  testWidgets('selection stays open when its POI continues to match', (
    tester,
  ) async {
    final controller = MapController();
    await pumpExplore(
      tester,
      controller: controller,
      pois: controlledPois([0, 1]),
    );
    await tester.pump();
    await focusMap(tester, controller);

    await tester.tap(find.byType(PoiPinMarker).at(0));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('explore-search-field')),
      'dar',
    );
    await tester.pump();

    expect(find.byType(PoiPinMarker), findsOneWidget);
    expect(find.byKey(const ValueKey('explore-poi-card')), findsOneWidget);
    expect(find.text('Darwin Waterfront'), findsOneWidget);
  });

  testWidgets('map pans, zooms, and exposes POI tooltips', (tester) async {
    final controller = MapController();
    await pumpExplore(
      tester,
      controller: controller,
      pois: controlledPois([0, 1]),
    );
    await tester.pump();
    await focusMap(tester, controller);
    final center = controller.camera.center;

    await tester.drag(find.byType(FlutterMap), const Offset(80, 0));
    await tester.pump();
    expect(controller.camera.center, isNot(center));

    await tester.longPress(find.byType(PoiPinMarker).first);
    await tester.pump();
    expect(find.text('Darwin Waterfront'), findsOneWidget);
  });

  testWidgets('renders the open card at 360px without layout exceptions', (
    tester,
  ) async {
    final view = tester.view;
    view.physicalSize = const Size(360, 700);
    view.devicePixelRatio = 1;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);
    final controller = MapController();
    await pumpExplore(
      tester,
      controller: controller,
      pois: controlledPois([0, 1]),
    );
    await tester.pump();
    await focusMap(tester, controller);
    await tester.tap(find.byType(PoiPinMarker).at(0));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'map fit padding clears the status bar and the search pill',
    (tester) async {
      tester.view.physicalSize = const Size(411, 914);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 48);
      addTearDown(tester.view.reset);
      await pumpExplore(tester);
      await tester.pump();

      final fitPadding = tester
          .widget<TerraMap>(find.byType(TerraMap))
          .fitPadding;
      expect(
        fitPadding.top,
        greaterThanOrEqualTo(48 + AppMetrics.exploreSearchFieldHeight + 30),
      );
    },
  );
}
