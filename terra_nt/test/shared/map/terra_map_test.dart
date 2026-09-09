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
  bool zoomControl = true,
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
      zoomControl: zoomControl,
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

  testWidgets('zoom controls are conditional and change camera zoom', (
    tester,
  ) async {
    final controller = MapController();
    await tester.pumpWidget(mapHarness(controller: controller));
    final zoom = controller.camera.zoom;

    expect(find.byKey(const ValueKey('map-zoom-in')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('map-zoom-in')));
    await tester.pump();
    expect(controller.camera.zoom, greaterThan(zoom));

    await tester.pumpWidget(
      mapHarness(controller: controller, zoomControl: false),
    );
    expect(find.byKey(const ValueKey('map-zoom-in')), findsNothing);
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

  testWidgets('a full-width top overlay never covers the zoom controls', (
    tester,
  ) async {
    final controller = MapController();
    await tester.pumpWidget(
      mapHarness(
        controller: controller,
        topOverlay: const SizedBox(height: 60, child: ColoredBox(
          color: AppColors.surface1,
          child: Text('overlay', textDirection: TextDirection.ltr),
        )),
      ),
    );

    final overlay = tester.getRect(find.text('overlay'));
    final zoomIn = tester.getRect(find.byKey(const ValueKey('map-zoom-in')));
    final zoomOut = tester.getRect(find.byKey(const ValueKey('map-zoom-out')));
    expect(zoomIn.overlaps(overlay), isFalse);
    expect(zoomOut.overlaps(overlay), isFalse);
    expect(zoomIn.top, greaterThanOrEqualTo(overlay.bottom));
    expect(find.byKey(const ValueKey('map-zoom-in')).hitTestable(), findsOne);
    expect(find.byKey(const ValueKey('map-zoom-out')).hitTestable(), findsOne);
  });

  testWidgets('controls padding keeps the floating controls off system UI', (
    tester,
  ) async {
    final controller = MapController();
    await tester.pumpWidget(mapHarness(controller: controller));
    final baseZoom = tester.getRect(find.byKey(const ValueKey('map-zoom-in')));
    final baseAttribution = tester.getRect(find.text(cartoAttribution));

    await tester.pumpWidget(
      mapHarness(
        controller: controller,
        controlsPadding: const EdgeInsets.only(top: 24, bottom: 48),
      ),
    );

    expect(
      tester.getRect(find.byKey(const ValueKey('map-zoom-in'))).top,
      baseZoom.top + 24,
    );
    expect(
      tester.getRect(find.text(cartoAttribution)).bottom,
      baseAttribution.bottom - 48,
    );
  });

  testWidgets('zoom buttons keep 26px paint inside a 48px touch target', (
    tester,
  ) async {
    final controller = MapController();
    await tester.pumpWidget(mapHarness(controller: controller));

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

    final target = tester.getRect(
      find.byKey(const ValueKey('map-zoom-in-target')),
    );
    final zoom = controller.camera.zoom;
    await tester.tapAt(target.topLeft + const Offset(4, 4));
    await tester.pump();
    expect(controller.camera.zoom, greaterThan(zoom));

    final outTarget = tester.getRect(
      find.byKey(const ValueKey('map-zoom-out-target')),
    );
    final raised = controller.camera.zoom;
    await tester.tapAt(outTarget.bottomLeft + const Offset(4, -4));
    await tester.pump();
    expect(controller.camera.zoom, lessThan(raised));
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
    final controls = tester.widget<DecoratedBox>(
      find
          .ancestor(
            of: find.byKey(const ValueKey('map-zoom-in')),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect((controls.decoration as BoxDecoration).color, AppColors.surface1);
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
