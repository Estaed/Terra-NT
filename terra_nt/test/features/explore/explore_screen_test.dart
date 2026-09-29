import 'package:flutter/material.dart';
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

Future<void> pumpExplore(
  WidgetTester tester, {
  MapController? controller,
  List<Poi>? pois,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [if (pois != null) poiProvider.overrideWithValue(pois)],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: SizedBox(
          width: 360,
          height: 700,
          child: ExploreScreen(mapController: controller),
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
    expect(find.byKey(const ValueKey('explore-poi-card')), findsOneWidget);
    expect(find.text('Mindil Beach'), findsOneWidget);
    expect(find.text('Darwin Waterfront'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('explore-poi-close')));
    await tester.pump();
    expect(find.byKey(const ValueKey('explore-poi-card')), findsNothing);
    expect(exploreState(tester).selectedPoiId, isNull);
  });

  testWidgets('the info card fades in where it rests, afresh for each place', (
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
        .widget<Opacity>(
          find.ancestor(of: card, matching: find.byType(Opacity)).first,
        )
        .opacity;

    await tester.tap(find.byType(PoiPinMarker).at(0));
    await tester.pump();
    expect(cardOpacity(), lessThan(1));
    final firstFrame = tester.getRect(card);

    await tester.pump(AppMotion.entrance);
    expect(cardOpacity(), 1);
    expect(
      tester.getRect(card),
      firstFrame,
      reason: 'the card fades in place rather than travelling',
    );

    await tester.tap(find.byType(PoiPinMarker).at(1));
    await tester.pump();
    expect(cardOpacity(), lessThan(1), reason: 'another place arrives afresh');
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
    expect(
      tester.widget<TagDot>(find.byType(TagDot)).color,
      AppColors.tagGreen,
    );

    await tester.tap(find.byType(PoiPinMarker).at(1));
    await tester.pump();
    expect(
      tester.widget<TagDot>(find.byType(TagDot)).color,
      AppColors.tagPurple,
    );
  });

  testWidgets('search filters markers, closes excluded selection, and clears', (
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
    final center = controller.camera.center;

    await tester.tap(find.byType(PoiPinMarker).at(0));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('explore-search-field')),
      'KINGS',
    );
    await tester.pump();
    expect(find.byType(PoiPinMarker), findsOneWidget);
    expect(find.byKey(const ValueKey('explore-poi-card')), findsNothing);
    expect(exploreState(tester).selectedPoiId, isNull);
    expect(controller.camera.center, center);

    await tester.enterText(
      find.byKey(const ValueKey('explore-search-field')),
      'missing',
    );
    await tester.pump();
    expect(find.byType(PoiPinMarker), findsNothing);
    expect(find.text('No places match your search.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('explore-clear-search')));
    await tester.pump();
    expect(find.byType(PoiPinMarker), findsNWidgets(2));
    expect(find.text('No places match your search.'), findsNothing);
    expect(controller.camera.center, center);
  });

  testWidgets(
    'real seeded search handles trim, case, tags, descriptions, and field clearing',
    (tester) async {
      final controller = MapController();
      await pumpExplore(tester, controller: controller);
      await tester.pump();
      final center = controller.camera.center;
      final zoom = controller.camera.zoom;
      final field = find.byKey(const ValueKey('explore-search-field'));
      final textField = tester.widget<TextField>(field);
      expect(textField.decoration!.hintText, 'Search the Territory');

      await tester.enterText(field, ' UbIrR ');
      await tester.pump();
      expect(find.byType(PoiPinMarker), findsOneWidget);
      expect(markerKeys(tester), {const ValueKey('explore-marker-ubirr')});
      expect(controller.camera.center, center);
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
      expect(find.byType(PoiPinMarker), findsNothing);
      expect(find.text('No places match your search.'), findsOneWidget);
      expect(controller.camera.center, center);
      expect(controller.camera.zoom, zoom);

      await tester.tap(find.byKey(const ValueKey('explore-clear-search')));
      await tester.pump();
      expect(textField.controller!.text, isEmpty);
      expect(find.byType(PoiPinMarker), findsNWidgets(15));
      expect(controller.camera.center, center);
      expect(controller.camera.zoom, zoom);

      await tester.enterText(field, 'mindil');
      await tester.pump();
      await tester.enterText(field, '');
      await tester.pump();
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
