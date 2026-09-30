import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:terra_nt/core/theme/colors.dart';
import 'package:terra_nt/core/theme/metrics.dart';
import 'package:terra_nt/core/theme/motion.dart';
import 'package:terra_nt/core/util/tag_colors.dart';
import 'package:terra_nt/data/seed/seed_data.dart';
import 'package:terra_nt/shared/map/map.dart';

Widget mapHarness({
  required MapController controller,
  bool interactive = true,
  List<TerraMapMarker> markers = const [],
  LatLngBounds? bounds,
  Widget? topOverlay,
  EdgeInsets controlsPadding = EdgeInsets.zero,
  EdgeInsets fitPadding = const EdgeInsets.all(AppMetrics.mapResultFitPadding),
  bool animateCameraFit = false,
  bool suspendCameraFit = false,
  bool separatePins = false,
  bool disableAnimations = false,
}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: disableAnimations),
    child: child!,
  ),
  home: SizedBox(
    width: 360,
    height: 640,
    child: TerraMap(
      controller: controller,
      interactive: interactive,
      markers: markers,
      bounds: bounds,
      topOverlay: topOverlay,
      controlsPadding: controlsPadding,
      fitPadding: fitPadding,
      animateCameraFit: animateCameraFit,
      suspendCameraFit: suspendCameraFit,
      separatePins: separatePins,
    ),
  ),
);

Future<void> scaleMap(WidgetTester tester, double scale) async {
  final center = tester.getCenter(find.byType(FlutterMap));
  final first = await tester.startGesture(center + const Offset(-20, 0));
  final second = await tester.startGesture(center + const Offset(20, 0));
  await first.moveTo(center + Offset(-20 * scale, 0));
  await second.moveTo(center + Offset(20 * scale, 0));
  await tester.pump();
  await first.up();
  await second.up();
}

void main() {
  test(
    'Result padding reserves each live anchor instead of a minimum strip',
    () {
      for (final height in [190.0, 430.0, 700.0]) {
        final padding = TerraMap.resultFitPaddingFor(
          914,
          48,
          sheetHeight: height,
        );
        expect(padding.top, 48 + AppMetrics.mapResultFitPadding);
        expect(padding.bottom, height + AppMetrics.mapResultFitPadding);
        expect(914 - padding.vertical, greaterThan(0));
      }
      final squeezed = TerraMap.resultFitPaddingFor(800, 48, sheetHeight: 700);
      expect(squeezed.top, 48 + AppMetrics.minTouchTarget / 2);
      expect(squeezed.bottom, 700 + AppMetrics.minTouchTarget / 2);
    },
  );

  for (final route in seedSavedRoutes) {
    for (final size in [
      const Size(360, 640),
      const Size(393, 852),
      const Size(411, 914),
    ]) {
      testWidgets('${route.id} fits and separates every full pin at $size', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final controller = MapController();
        final points = [
          for (final stop in route.stops) LatLng(stop.lat, stop.lng),
        ];
        final tapped = <int>[];
        const topInset = 44.0;
        final anchors = [
          AppMetrics.resultSheetMidHeight,
          AppMetrics.resultSheetMinHeight,
          if (size.height - topInset - AppMetrics.resultSheetMaxHeight >=
              AppMetrics.minTouchTarget)
            AppMetrics.resultSheetMaxHeight,
        ];
        for (final sheet in anchors) {
          await tester.pumpWidget(
            mapHarness(
              controller: controller,
              bounds: LatLngBounds.fromPoints(points),
              fitPadding: TerraMap.resultFitPaddingFor(
                size.height,
                topInset,
                sheetHeight: sheet,
              ),
              animateCameraFit: true,
              separatePins: true,
              markers: [
                for (var index = 0; index < points.length; index++)
                  TerraMapMarker(
                    key: ValueKey('fit-pin-$index'),
                    point: points[index],
                    child: NumberedPinMarker(number: index + 1),
                    onTap: () => tapped.add(index),
                  ),
              ],
            ),
          );
          await tester.pumpAndSettle();
          final strip = Rect.fromLTRB(
            0,
            topInset,
            size.width,
            size.height - sheet,
          );
          final targets = <Rect>[];
          for (var index = 0; index < points.length; index++) {
            final target = tester.getRect(
              find.byKey(ValueKey('fit-pin-$index')),
            );
            expect(target.size, const Size.square(AppMetrics.minTouchTarget));
            expect(target.left, greaterThanOrEqualTo(strip.left));
            expect(target.right, lessThanOrEqualTo(strip.right));
            expect(target.top, greaterThanOrEqualTo(strip.top));
            expect(target.bottom, lessThanOrEqualTo(strip.bottom));
            for (final other in targets) {
              expect(
                target.overlaps(other),
                isFalse,
                reason: '${route.id} pins overlap at $sheet',
              );
            }
            targets.add(target);
            await tester.tapAt(target.center);
            expect(tapped.last, index);
          }
          expect(tester.takeException(), isNull);
        }
        await tester.pumpWidget(const SizedBox.shrink());
        expect(tester.binding.transientCallbackCount, 0);
      });
    }
  }

  testWidgets('default maps keep their camera when fit inputs change', (
    tester,
  ) async {
    final controller = MapController();
    final bounds = LatLngBounds(const LatLng(-12, 131), const LatLng(-25, 135));
    await tester.pumpWidget(mapHarness(controller: controller, bounds: bounds));
    final before = controller.camera;
    await tester.pumpWidget(
      mapHarness(
        controller: controller,
        bounds: LatLngBounds(const LatLng(-13, 132), const LatLng(-16, 134)),
        fitPadding: const EdgeInsets.only(bottom: 300),
      ),
    );
    await tester.pumpAndSettle();
    expect(controller.camera.center, before.center);
    expect(controller.camera.zoom, before.zoom);
  });

  testWidgets(
    'Result pins render once at world zoom and follow camera rotation',
    (tester) async {
      final controller = MapController();
      final points = [for (final stop in seedStops) LatLng(stop.lat, stop.lng)];
      final tapped = <int>[];
      await tester.pumpWidget(
        mapHarness(
          controller: controller,
          bounds: LatLngBounds.fromPoints(points),
          animateCameraFit: true,
          separatePins: true,
          markers: [
            for (var i = 0; i < points.length; i++)
              TerraMapMarker(
                key: ValueKey('world-pin-$i'),
                point: points[i],
                child: NumberedPinMarker(number: i + 1),
                onTap: () => tapped.add(i),
              ),
          ],
        ),
      );
      controller.move(controller.camera.center, 0);
      controller.rotate(30);
      await tester.pump();
      expect(find.byType(NumberedPinMarker), findsNWidgets(seedStops.length));
      final targets = <Rect>[];
      for (var i = 0; i < points.length; i++) {
        final pin = find.byKey(ValueKey('world-pin-$i'));
        expect(pin, findsOneWidget);
        final rect = tester.getRect(pin);
        expect(rect.size, const Size.square(AppMetrics.minTouchTarget));
        for (final other in targets) {
          expect(rect.overlaps(other), isFalse);
        }
        targets.add(rect);
        await tester.tapAt(rect.center);
        expect(tapped.last, i);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('reduced motion refits immediately without a camera ticker', (
    tester,
  ) async {
    final controller = MapController();
    final bounds = LatLngBounds(const LatLng(-12, 131), const LatLng(-25, 135));
    await tester.pumpWidget(
      mapHarness(
        controller: controller,
        bounds: bounds,
        animateCameraFit: true,
        disableAnimations: true,
      ),
    );
    final before = controller.camera;
    await tester.pumpWidget(
      mapHarness(
        controller: controller,
        bounds: bounds,
        animateCameraFit: true,
        disableAnimations: true,
        fitPadding: const EdgeInsets.only(bottom: 300),
      ),
    );
    expect(controller.camera.center, isNot(before.center));
    expect(controller.camera.zoom, lessThan(before.zoom));
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets(
    'drag suspends fitting; a snap retargets and disposal stops the camera',
    (tester) async {
      final controller = MapController();
      final bounds = LatLngBounds(
        const LatLng(-12, 131),
        const LatLng(-25, 135),
      );
      await tester.pumpWidget(
        mapHarness(
          controller: controller,
          bounds: bounds,
          animateCameraFit: true,
        ),
      );
      final before = controller.camera;
      await tester.pumpWidget(
        mapHarness(
          controller: controller,
          bounds: bounds,
          animateCameraFit: true,
          suspendCameraFit: true,
          fitPadding: const EdgeInsets.only(bottom: 300),
        ),
      );
      await tester.pump(AppMotion.resultCameraFit);
      expect(controller.camera.center, before.center);
      await tester.pumpWidget(
        mapHarness(
          controller: controller,
          bounds: bounds,
          animateCameraFit: true,
          fitPadding: const EdgeInsets.only(bottom: 300),
        ),
      );
      await tester.pump();
      await tester.pump(AppMotion.resultCameraFit ~/ 2);
      expect(controller.camera.zoom, lessThan(before.zoom));
      final midway = controller.camera;
      await tester.pumpWidget(
        mapHarness(
          controller: controller,
          bounds: bounds,
          animateCameraFit: true,
          fitPadding: const EdgeInsets.only(bottom: 400),
        ),
      );
      expect(controller.camera.center, midway.center);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpWidget(const SizedBox());
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pump(AppMotion.resultCameraFit);
      expect(tester.takeException(), isNull);
    },
  );

  test('uses the keyed CARTO dark raster tile template', () {
    expect(
      cartoDarkTileUrl,
      'https://basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}{r}.png'
      '?key={key}',
    );
    expect(cartoDarkTileUrl.contains('{s}'), isFalse);
  });

  test('identifies the app to the tile server', () {
    expect(mapUserAgentPackageName, 'au.edu.cdu.terra_nt');
  });

  test('Explore fit padding clears the status bar and the search pill', () {
    final padding = TerraMap.exploreFitPaddingFor(48, 900);

    expect(
      padding.top,
      48 +
          AppMetrics.exploreSearchInset +
          AppMetrics.exploreSearchFieldHeight +
          AppMetrics.mapExploreFitPadding,
    );
    expect(padding.left, AppMetrics.mapExploreFitPadding);
    expect(padding.right, AppMetrics.mapExploreFitPadding);
    expect(padding.bottom, AppMetrics.mapExploreFitPadding);
  });

  test(
    'Explore fit padding gives way to the minimum strip on a squeezed viewport',
    () {
      final padding = TerraMap.exploreFitPaddingFor(24, 340);

      expect(padding.top, AppMetrics.mapExploreFitPadding);
    },
  );

  test('Result fit padding clears the status bar and keeps the sheet reserve', () {
    final padding = TerraMap.resultFitPaddingFor(900, 48);

    expect(padding.top, 48 + AppMetrics.mapResultFitPadding);
    expect(padding.left, AppMetrics.mapResultFitPadding);
    expect(padding.right, AppMetrics.mapResultFitPadding);
    expect(padding.bottom, greaterThan(AppMetrics.mapResultFitPadding));
  });

  testWidgets('feeds the API key into the tile layer', (tester) async {
    await tester.pumpWidget(mapHarness(controller: MapController()));

    final layer = tester.widget<TileLayer>(find.byType(TileLayer));
    expect(layer.urlTemplate, cartoDarkTileUrl);
    expect(layer.additionalOptions['key'], cartoApiKey);
  });

  testWidgets('renders the required map attribution', (tester) async {
    final controller = MapController();
    await tester.pumpWidget(mapHarness(controller: controller));

    expect(find.textContaining('OpenStreetMap'), findsOneWidget);
    expect(find.textContaining('CARTO'), findsOneWidget);
  });

  testWidgets('disables and enables map interaction', (tester) async {
    final lockedController = MapController();
    await tester.pumpWidget(
      mapHarness(controller: lockedController, interactive: false),
    );
    final lockedCenter = lockedController.camera.center;
    await tester.drag(find.byType(FlutterMap), const Offset(80, 0));
    await tester.pump();
    expect(lockedController.camera.center, lockedCenter);
    final lockedZoom = lockedController.camera.zoom;
    await scaleMap(tester, 2);
    expect(lockedController.camera.zoom, lockedZoom);

    final activeController = MapController();
    await tester.pumpWidget(mapHarness(controller: activeController));
    final activeCenter = activeController.camera.center;
    await tester.drag(find.byType(FlutterMap), const Offset(80, 0));
    await tester.pump();
    expect(activeController.camera.center, isNot(activeCenter));
    final activeZoom = activeController.camera.zoom;
    await scaleMap(tester, 2);
    expect(activeController.camera.zoom, greaterThan(activeZoom));
  });

  testWidgets('numbered pins render their supplied number', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: NumberedPinMarker(number: 3)),
    );

    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('POI pins invoke taps and expose selected colour', (
    tester,
  ) async {
    var tapped = false;
    final accent = tagColor('Wildlife');
    await tester.pumpWidget(
      MaterialApp(
        home: PoiPinMarker(
          selected: true,
          accent: accent,
          onTap: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('poi-pin-marker')));
    expect(tapped, isTrue);
    final pin = tester.widget<Container>(
      find.byKey(const ValueKey('poi-pin-marker')),
    );
    final decoration = pin.decoration! as BoxDecoration;
    expect(decoration.color, accent);
    expect(decoration.border!.top.color, accent);
  });

  testWidgets('unselected POI pins ring and dot the accent colour', (
    tester,
  ) async {
    final accent = tagColor('Wildlife');
    await tester.pumpWidget(
      MaterialApp(home: PoiPinMarker(accent: accent)),
    );

    final pin = tester.widget<Container>(
      find.byKey(const ValueKey('poi-pin-marker')),
    );
    final decoration = pin.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.surface2);
    expect(decoration.border!.top.color, accent);

    final dot = tester.widget<Container>(
      find.byKey(const ValueKey('poi-pin-marker-dot')),
    );
    expect((dot.decoration! as BoxDecoration).color, accent);
  });

  testWidgets('an unknown tag falls back to inkTertiary', (tester) async {
    final accent = tagColor('Not A Real Tag');
    expect(accent, AppColors.inkTertiary);

    await tester.pumpWidget(
      MaterialApp(home: PoiPinMarker(accent: accent)),
    );

    final dot = tester.widget<Container>(
      find.byKey(const ValueKey('poi-pin-marker-dot')),
    );
    expect((dot.decoration! as BoxDecoration).color, AppColors.inkTertiary);
  });

  testWidgets('renders every supplied marker', (tester) async {
    final controller = MapController();
    final markers = List.generate(
      3,
      (index) => TerraMapMarker(
        point: LatLng(-18.0 + index, 132),
        child: const RouteDotMarker(),
      ),
    );
    await tester.pumpWidget(
      mapHarness(controller: controller, markers: markers),
    );

    expect(find.byType(RouteDotMarker), findsNWidgets(3));
  });

  testWidgets('fits bounds after the map receives layout constraints', (
    tester,
  ) async {
    final controller = MapController();
    final bounds = LatLngBounds(
      const LatLng(-25.3444, 130.6805),
      const LatLng(-12.4634, 133.8807),
    );
    await tester.pumpWidget(mapHarness(controller: controller, bounds: bounds));
    await tester.pump();

    expect(
      controller.camera.visibleBounds.contains(
        const LatLng(-12.4634, 130.8456),
      ),
      isTrue,
    );
    expect(
      controller.camera.visibleBounds.contains(
        const LatLng(-25.3444, 131.0369),
      ),
      isTrue,
    );
  });

  testWidgets('fits bounds on the very first frame', (tester) async {
    final controller = MapController();
    final bounds = LatLngBounds(
      const LatLng(-25.3444, 130.6805),
      const LatLng(-12.4634, 133.8807),
    );
    // One pump only: the fitted camera has to be the camera the tile layer
    // sees first, or the tiles requested for a throwaway camera are lost.
    await tester.pumpWidget(mapHarness(controller: controller, bounds: bounds));

    final options = tester.widget<FlutterMap>(find.byType(FlutterMap)).options;
    expect(options.initialCameraFit, isNull);
    expect(bounds.contains(options.initialCenter), isTrue);
    expect(
      controller.camera.zoom,
      inInclusiveRange(AppMetrics.mapMinZoom, AppMetrics.mapMaxZoom),
    );
    expect(bounds.contains(controller.camera.center), isTrue);
  });

  testWidgets('long press reveals a marker tooltip', (tester) async {
    final controller = MapController();
    await tester.pumpWidget(
      mapHarness(
        controller: controller,
        markers: [
          TerraMapMarker(
            point: const LatLng(-18, 132),
            tooltip: 'Darwin',
            child: const NumberedPinMarker(number: 1),
          ),
        ],
      ),
    );

    expect(find.text('Darwin'), findsNothing);
    await tester.longPress(find.byType(NumberedPinMarker));
    await tester.pump();
    expect(find.text('Darwin'), findsOneWidget);
  });

  testWidgets('controls padding keeps the floating controls off system UI', (
    tester,
  ) async {
    const overlay = SizedBox(
      height: 60,
      child: ColoredBox(
        color: AppColors.surface1,
        child: Text('overlay', textDirection: TextDirection.ltr),
      ),
    );
    final controller = MapController();
    await tester.pumpWidget(
      mapHarness(controller: controller, topOverlay: overlay),
    );
    final baseOverlay = tester.getRect(find.text('overlay'));
    final baseAttribution = tester.getRect(find.text(cartoAttribution));

    await tester.pumpWidget(
      mapHarness(
        controller: controller,
        topOverlay: overlay,
        controlsPadding: const EdgeInsets.only(top: 24, bottom: 48),
      ),
    );

    expect(tester.getRect(find.text('overlay')).top, baseOverlay.top + 24);
    expect(
      tester.getRect(find.text(cartoAttribution)).bottom,
      baseAttribution.bottom - 48,
    );
  });

  testWidgets('a tappable marker keeps its pin inside a 48px touch target', (
    tester,
  ) async {
    final controller = MapController();
    var taps = 0;
    await tester.pumpWidget(
      mapHarness(
        controller: controller,
        markers: [
          TerraMapMarker(
            point: const LatLng(-18, 132),
            onTap: () => taps++,
            child: PoiPinMarker(accent: tagColor('Wildlife')),
          ),
        ],
      ),
    );

    final pin = tester.getRect(find.byType(PoiPinMarker));
    expect(
      pin.size,
      const Size(AppMetrics.mapPoiPinSize, AppMetrics.mapPoiPinSize),
    );

    await tester.tapAt(
      pin.center + const Offset(0, -AppMetrics.minTouchTarget / 2 + 2),
    );
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('controls stay legible over a watermarked unkeyed tile', (
    tester,
  ) async {
    final controller = MapController();
    await tester.pumpWidget(mapHarness(controller: controller));

    final attribution = tester.widget<Container>(
      find
          .ancestor(
            of: find.text(cartoAttribution),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(attribution.color, AppColors.surface1);
    expect(
      tester.widget<FlutterMap>(find.byType(FlutterMap)).options.backgroundColor,
      AppColors.surface1,
    );
  });

  testWidgets('renders at phone width without a layout exception', (
    tester,
  ) async {
    final controller = MapController();
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      mapHarness(
        controller: controller,
        markers: [
          TerraMapMarker(
            point: const LatLng(-18, 132),
            tooltip: 'Darwin',
            child: const NumberedPinMarker(number: 1),
          ),
        ],
      ),
    );

    expect(tester.takeException(), isNull);
  });

}
