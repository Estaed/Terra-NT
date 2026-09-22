import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:terra_nt/core/theme/colors.dart';
import 'package:terra_nt/core/theme/metrics.dart';
import 'package:terra_nt/shared/map/map.dart';

Widget mapHarness({
  required MapController controller,
  bool interactive = true,
  List<TerraMapMarker> markers = const [],
  LatLngBounds? bounds,
  Widget? topOverlay,
  EdgeInsets controlsPadding = EdgeInsets.zero,
}) => MaterialApp(
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
    await tester.pumpWidget(
      MaterialApp(
        home: PoiPinMarker(selected: true, onTap: () => tapped = true),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('poi-pin-marker')));
    expect(tapped, isTrue);
    final pin = tester.widget<Container>(
      find.byKey(const ValueKey('poi-pin-marker')),
    );
    expect((pin.decoration! as BoxDecoration).color, AppColors.primary);
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
            child: const PoiPinMarker(),
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
