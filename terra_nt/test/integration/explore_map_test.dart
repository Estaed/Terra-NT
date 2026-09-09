import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:terra_nt/core/theme/app_theme.dart';
import 'package:terra_nt/core/theme/colors.dart';
import 'package:terra_nt/core/theme/metrics.dart';
import 'package:terra_nt/data/models/poi.dart';
import 'package:terra_nt/data/repositories/notifiers.dart';
import 'package:terra_nt/data/seed/seed_data.dart';
import 'package:terra_nt/features/explore/explore_screen.dart';
import 'package:terra_nt/shared/map/map_markers.dart';

/// The phone viewport and the system insets Task-20 measures Explore against.
const phoneSize = Size(360, 640);
const statusBarInset = 24.0;
const gestureBarInset = 48.0;
const keyboardInset = 300.0;
const deviceSafeArea = EdgeInsets.only(
  top: statusBarInset,
  bottom: gestureBarInset,
);

/// Two POIs far enough apart that both pins stay tappable at the fitted camera.
List<Poi> spreadPois() => [
  for (var index = 0; index < 2; index++)
    Poi(
      id: seedPois[index].id,
      name: seedPois[index].name,
      tag: seedPois[index].tag,
      rating: seedPois[index].rating,
      description: seedPois[index].description,
      lat: -18.0 - index * 2.0,
      lng: 132.0 + index * 2.0,
    ),
];

Future<void> pumpExploreOnPhone(
  WidgetTester tester, {
  MapController? controller,
  List<Poi>? pois,
  EdgeInsets padding = deviceSafeArea,
  EdgeInsets viewInsets = EdgeInsets.zero,
  double textScale = 1,
}) async {
  tester.view.physicalSize = phoneSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [if (pois != null) poiProvider.overrideWithValue(pois)],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: MediaQuery(
          data: MediaQueryData(
            size: phoneSize,
            padding: padding,
            viewPadding: padding,
            viewInsets: viewInsets,
            textScaler: TextScaler.linear(textScale),
          ),
          child: ExploreScreen(mapController: controller),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> focusMap(WidgetTester tester, MapController controller) async {
  controller.move(const LatLng(-18, 132), 5);
  await tester.pump();
}

Future<void> openFirstCard(
  WidgetTester tester,
  MapController controller,
) async {
  await focusMap(tester, controller);
  await tester.tap(find.byType(PoiPinMarker).at(0));
  await tester.pump();
}

Rect rectOf(WidgetTester tester, String key) =>
    tester.getRect(find.byKey(ValueKey(key)));

void main() {
  testWidgets('the search pill clears the status-bar region', (tester) async {
    await pumpExploreOnPhone(tester);

    final pill = rectOf(tester, 'explore-search-pill');
    expect(pill.top, greaterThanOrEqualTo(statusBarInset));
    expect(pill.top, statusBarInset + AppMetrics.exploreSearchInset);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the search overlay leaves the zoom controls hit-testable', (
    tester,
  ) async {
    final controller = MapController();
    await pumpExploreOnPhone(tester, controller: controller);

    final search = rectOf(tester, 'explore-search-target');
    final zoomIn = rectOf(tester, 'map-zoom-in');
    final zoomOut = rectOf(tester, 'map-zoom-out');
    expect(zoomIn.overlaps(search), isFalse);
    expect(zoomOut.overlaps(search), isFalse);
    expect(zoomIn.top, greaterThanOrEqualTo(search.bottom));
    expect(find.byKey(const ValueKey('map-zoom-in')).hitTestable(), findsOne);
    expect(find.byKey(const ValueKey('map-zoom-out')).hitTestable(), findsOne);

    final zoom = controller.camera.zoom;
    await tester.tap(find.byKey(const ValueKey('map-zoom-in')));
    await tester.pump();
    expect(controller.camera.zoom, greaterThan(zoom));
  });

  testWidgets('no essential action sits behind the system insets', (
    tester,
  ) async {
    final controller = MapController();
    await pumpExploreOnPhone(
      tester,
      controller: controller,
      pois: spreadPois(),
    );
    await openFirstCard(tester, controller);

    const safeTop = statusBarInset;
    final safeBottom = phoneSize.height - gestureBarInset;
    for (final key in [
      'explore-search-target',
      'map-zoom-in-target',
      'map-zoom-out-target',
      'explore-poi-close-target',
    ]) {
      final rect = rectOf(tester, key);
      expect(rect.top, greaterThanOrEqualTo(safeTop), reason: key);
      expect(rect.bottom, lessThanOrEqualTo(safeBottom), reason: key);
    }
    for (final key in [
      'explore-search-field',
      'map-zoom-in',
      'map-zoom-out',
      'explore-poi-close',
    ]) {
      expect(find.byKey(ValueKey(key)).hitTestable(), findsOne, reason: key);
    }
    expect(
      tester.getRect(find.text('© OpenStreetMap © CARTO')).bottom,
      lessThanOrEqualTo(safeBottom),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the focused field and clear action stay above the keyboard', (
    tester,
  ) async {
    await pumpExploreOnPhone(
      tester,
      viewInsets: const EdgeInsets.only(bottom: keyboardInset),
    );
    final field = find.byKey(const ValueKey('explore-search-field'));
    final keyboardTop = phoneSize.height - keyboardInset;

    await tester.tap(find.byKey(const ValueKey('explore-search-target')));
    await tester.pump();
    expect(tester.widget<TextField>(field).focusNode!.hasFocus, isTrue);
    expect(tester.getRect(field).bottom, lessThanOrEqualTo(keyboardTop));

    await tester.enterText(field, 'no such place');
    await tester.pump();
    final clear = find.byKey(const ValueKey('explore-clear-search'));
    expect(tester.getRect(clear).bottom, lessThanOrEqualTo(keyboardTop));
    expect(clear.hitTestable(), findsOne);
    await tester.tap(clear);
    await tester.pump();
    expect(find.byType(PoiPinMarker), findsNWidgets(8));
    expect(tester.takeException(), isNull);

    // System Back closes the keyboard before it leaves Explore.
    await tester.tap(find.byKey(const ValueKey('explore-search-target')));
    await tester.pump();
    expect(tester.widget<TextField>(field).focusNode!.hasFocus, isTrue);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(tester.widget<TextField>(field).focusNode!.hasFocus, isFalse);
    expect(find.byKey(const ValueKey('explore-screen')), findsOne);
  });

  for (final textScale in [1.0, 1.5]) {
    testWidgets('search pill and info card survive text scale $textScale', (
      tester,
    ) async {
      final controller = MapController();
      await pumpExploreOnPhone(
        tester,
        controller: controller,
        pois: spreadPois(),
        textScale: textScale,
      );
      await openFirstCard(tester, controller);

      expect(find.text('Search the Territory'), findsOne);
      expect(find.text('Darwin Waterfront'), findsOne);
      final card = rectOf(tester, 'explore-poi-card');
      expect(card.top, greaterThanOrEqualTo(0.0));
      expect(card.bottom, lessThanOrEqualTo(phoneSize.height));
      expect(rectOf(tester, 'explore-search-pill').top, isPositive);
      expect(
        rectOf(tester, 'map-zoom-in').top,
        greaterThanOrEqualTo(rectOf(tester, 'explore-search-target').bottom),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('every Explore control keeps its paint inside a 48px target', (
    tester,
  ) async {
    final controller = MapController();
    await pumpExploreOnPhone(
      tester,
      controller: controller,
      pois: spreadPois(),
    );
    await openFirstCard(tester, controller);

    // Search field: the pill paints at its own height inside a bigger target.
    final searchTarget = rectOf(tester, 'explore-search-target');
    final pill = rectOf(tester, 'explore-search-pill');
    expect(searchTarget.height, AppMetrics.minTouchTarget);
    expect(pill.height, lessThan(AppMetrics.minTouchTarget));
    expect(pill.top, searchTarget.top);

    // Zoom buttons: 26px painted, 48px target.
    for (final button in ['map-zoom-in', 'map-zoom-out']) {
      expect(
        tester.getSize(find.byKey(ValueKey(button))),
        const Size(
          AppMetrics.mapZoomControlButtonSize,
          AppMetrics.mapZoomControlButtonSize,
        ),
      );
      expect(
        tester.getSize(find.byKey(ValueKey('$button-target'))),
        const Size(AppMetrics.minTouchTarget, AppMetrics.minTouchTarget),
      );
    }

    // Info-card close: 26px circle inside a 48px target that still closes.
    expect(
      tester.getSize(find.byKey(const ValueKey('explore-poi-close'))),
      const Size(
        AppMetrics.exploreCardCloseSize,
        AppMetrics.exploreCardCloseSize,
      ),
    );
    final closeTarget = rectOf(tester, 'explore-poi-close-target');
    expect(
      closeTarget.size,
      const Size(AppMetrics.minTouchTarget, AppMetrics.minTouchTarget),
    );
    await tester.tapAt(closeTarget.bottomLeft + const Offset(6, -6));
    await tester.pump();
    expect(find.byKey(const ValueKey('explore-poi-card')), findsNothing);

    // POI pin: 30px painted, tappable well outside the pin.
    final pin = tester.getRect(find.byType(PoiPinMarker).at(0));
    expect(
      pin.size,
      const Size(AppMetrics.mapPoiPinSize, AppMetrics.mapPoiPinSize),
    );
    await tester.tapAt(
      pin.center + const Offset(0, -AppMetrics.minTouchTarget / 2 + 2),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('explore-poi-card')), findsOne);

    // Clear search reaches the minimum target too.
    await tester.enterText(
      find.byKey(const ValueKey('explore-search-field')),
      'no such place',
    );
    await tester.pump();
    expect(
      tester
          .getSize(find.byKey(const ValueKey('explore-clear-search')))
          .height,
      greaterThanOrEqualTo(AppMetrics.minTouchTarget),
    );
  });

  // No tile ever arrives here: the test binding answers every HTTP request
  // with status 400 and makes no network call, which is what Explore sees on
  // a phone with no signal. Nothing retries and nothing is cached.
  testWidgets('keeps local markers, controls and attribution offline', (
    tester,
  ) async {
    final controller = MapController();
    await pumpExploreOnPhone(tester, controller: controller);
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(PoiPinMarker), findsNWidgets(8));
    expect(find.byKey(const ValueKey('map-zoom-in')).hitTestable(), findsOne);
    expect(find.byKey(const ValueKey('map-zoom-out')).hitTestable(), findsOne);
    expect(find.text('© OpenStreetMap © CARTO'), findsOne);
    expect(find.text('Search the Territory'), findsOne);
    expect(
      tester.widget<FlutterMap>(find.byType(FlutterMap)).options.backgroundColor,
      AppColors.surface1,
    );

    final zoom = controller.camera.zoom;
    await tester.tap(find.byKey(const ValueKey('map-zoom-in')));
    await tester.pump();
    expect(controller.camera.zoom, greaterThan(zoom));
    expect(tester.takeException(), isNull);
  });
}
