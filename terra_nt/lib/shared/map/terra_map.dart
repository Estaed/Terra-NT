import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/elevation.dart';
import '../../core/theme/metrics.dart';
import '../../core/theme/radius.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import 'dashed_route_polyline.dart';
import 'map_markers.dart';

/// CARTO began watermarking unauthenticated raster tiles in late August 2026.
/// The key is free, and the endpoint still serves the same watermarked tile
/// without one, so a checkout with no key keeps rendering instead of going blank.
/// The key lives in the gitignored `terra_nt/.env`, read at build time with
/// `--dart-define-from-file=.env`. Copy `.env.example` to start.
const cartoApiKey = String.fromEnvironment('CARTO_API_KEY');
const cartoDarkTileUrl =
    'https://basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}{r}.png?key={key}';
const cartoAttribution = '© OpenStreetMap © CARTO';
const mapUserAgentPackageName = 'au.edu.cdu.terra_nt';

class TerraMapMarker {
  final LatLng point;
  final Widget child;
  final String? tooltip;
  final VoidCallback? onTap;
  final Key? key;
  final double? width;
  final double? height;

  const TerraMapMarker({
    required this.point,
    required this.child,
    this.tooltip,
    this.onTap,
    this.key,
    this.width,
    this.height,
  });
}

class TerraMap extends StatefulWidget {
  final List<TerraMapMarker> markers;
  final List<DashedRoutePolyline> polylines;
  final bool interactive;
  final bool zoomControl;
  final LatLng initialCenter;
  final double initialZoom;
  final LatLngBounds? bounds;
  final EdgeInsets fitPadding;
  final MapController? controller;

  /// A screen-owned control that floats above the map, stacked directly above
  /// the zoom buttons so a full-width overlay can never cover them.
  final Widget? topOverlay;

  /// Keeps the floating controls clear of system UI. The caller supplies the
  /// safe-area insets; the map itself stays full-bleed behind them.
  final EdgeInsets controlsPadding;

  const TerraMap({
    super.key,
    this.markers = const [],
    this.polylines = const [],
    this.interactive = true,
    this.zoomControl = true,
    this.initialCenter = const LatLng(-18, 132),
    this.initialZoom = 5,
    this.bounds,
    this.fitPadding = const EdgeInsets.all(AppMetrics.mapResultFitPadding),
    this.controller,
    this.topOverlay,
    this.controlsPadding = EdgeInsets.zero,
  });

  static EdgeInsets backdropFitPadding = const EdgeInsets.all(
    AppMetrics.mapBackdropFitPadding,
  );
  static EdgeInsets exploreFitPadding = const EdgeInsets.all(
    AppMetrics.mapExploreFitPadding,
  );
  static EdgeInsets resultFitPadding = const EdgeInsets.all(
    AppMetrics.mapResultFitPadding,
  );

  @override
  State<TerraMap> createState() => _TerraMapState();
}

class _TerraMapState extends State<TerraMap> {
  late final MapController _ownedController;

  MapController get _controller => widget.controller ?? _ownedController;

  @override
  void initState() {
    super.initState();
    _ownedController = MapController();
  }

  @override
  void dispose() {
    _ownedController.dispose();
    super.dispose();
  }

  List<Marker> _buildMarkers() => widget.markers.map((marker) {
    return Marker(
      key: marker.key,
      point: marker.point,
      width: marker.width ?? _markerWidth(marker),
      height: marker.height ?? _markerHeight(marker),
      child: _MapMarkerGesture(
        tooltip: marker.tooltip,
        onTap: marker.onTap,
        child: marker.child,
      ),
    );
  }).toList();

  /// A tappable marker keeps its painted pin but is laid out inside a box big
  /// enough to hit with a thumb; the pin stays centred on its coordinate.
  double _markerWidth(TerraMapMarker marker) {
    final painted = switch (marker.child) {
      RouteDotMarker() => AppMetrics.mapRouteDotSize,
      NumberedPinMarker() => AppMetrics.mapNumberedPinSize,
      _ => AppMetrics.mapPoiPinSize,
    };
    if (marker.onTap == null) return painted;
    return math.max(painted, AppMetrics.minTouchTarget);
  }

  double _markerHeight(TerraMapMarker marker) => _markerWidth(marker);

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      FlutterMap(
        mapController: _controller,
        options: MapOptions(
          initialCenter: widget.initialCenter,
          initialZoom: widget.initialZoom,
          initialCameraFit: widget.bounds == null
              ? null
              : CameraFit.bounds(
                  bounds: widget.bounds!,
                  padding: widget.fitPadding,
                ),
          backgroundColor: AppColors.surface1,
          interactionOptions: InteractionOptions(
            flags: widget.interactive
                ? InteractiveFlag.all
                : InteractiveFlag.none,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: cartoDarkTileUrl,
            additionalOptions: const {'key': cartoApiKey},
            retinaMode: RetinaMode.isHighDensity(context),
            userAgentPackageName: mapUserAgentPackageName,
            maxZoom: 19,
          ),
          if (widget.polylines.isNotEmpty)
            PolylineLayer(
              polylines: widget.polylines
                  .map((polyline) => polyline.toPolyline())
                  .toList(),
            ),
          if (widget.markers.isNotEmpty) MarkerLayer(markers: _buildMarkers()),
        ],
      ),
      Positioned(
        right: AppMetrics.mapTooltipOffset + widget.controlsPadding.right,
        bottom: AppMetrics.mapTooltipOffset + widget.controlsPadding.bottom,
        child: const _MapAttribution(),
      ),
      if (widget.topOverlay != null || widget.zoomControl)
        Positioned(
          left: widget.controlsPadding.left,
          right: widget.controlsPadding.right,
          top: widget.controlsPadding.top,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.topOverlay != null) widget.topOverlay!,
              if (widget.zoomControl)
                Align(
                  alignment: Alignment.centerRight,
                  child: _ZoomControls(controller: _controller),
                ),
            ],
          ),
        ),
    ],
  );
}

class _MapAttribution extends StatelessWidget {
  const _MapAttribution();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.xxs,
      vertical: AppSpacing.xxs,
    ),
    color: AppColors.surface1,
    child: Text(
      cartoAttribution,
      style: AppType.caption.copyWith(color: AppColors.inkTertiary),
    ),
  );
}

class _ZoomControls extends StatelessWidget {
  final MapController controller;

  const _ZoomControls({required this.controller});

  void _changeZoom(double amount) {
    controller.move(controller.camera.center, controller.camera.zoom + amount);
  }

  /// The two buttons keep their painted size and sit centred in a column of
  /// two [AppMetrics.minTouchTarget] squares, so each one owns a thumb-sized
  /// transparent target. The painted buttons paint last and so still take
  /// their own taps where the two overlap.
  @override
  Widget build(BuildContext context) => SizedBox(
    width: AppMetrics.minTouchTarget,
    height: AppMetrics.minTouchTarget * 2,
    child: Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: AppMetrics.minTouchTarget,
          child: GestureDetector(
            key: const ValueKey('map-zoom-in-target'),
            behavior: HitTestBehavior.opaque,
            onTap: () => _changeZoom(1),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: AppMetrics.minTouchTarget,
          child: GestureDetector(
            key: const ValueKey('map-zoom-out-target'),
            behavior: HitTestBehavior.opaque,
            onTap: () => _changeZoom(-1),
          ),
        ),
        Center(child: _paintedControls()),
      ],
    ),
  );

  Widget _paintedControls() => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.surface1,
      border: Border.all(color: AppColors.hairline),
      borderRadius: BorderRadius.circular(AppRadius.sm),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: AppMetrics.mapZoomControlButtonSize,
          height: AppMetrics.mapZoomControlButtonSize,
          child: IconButton(
            key: const ValueKey('map-zoom-in'),
            onPressed: () => _changeZoom(1),
            icon: const Icon(Icons.add),
            color: AppColors.ink,
            iconSize: AppMetrics.iconMd,
            padding: EdgeInsets.zero,
          ),
        ),
        Container(
          height: AppElevation.hairlineWidth,
          color: AppColors.hairline,
        ),
        SizedBox(
          width: AppMetrics.mapZoomControlButtonSize,
          height: AppMetrics.mapZoomControlButtonSize,
          child: IconButton(
            key: const ValueKey('map-zoom-out'),
            onPressed: () => _changeZoom(-1),
            icon: const Icon(Icons.remove),
            color: AppColors.ink,
            iconSize: AppMetrics.iconMd,
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    ),
  );
}

class _MapMarkerGesture extends StatefulWidget {
  final Widget child;
  final String? tooltip;
  final VoidCallback? onTap;

  const _MapMarkerGesture({
    required this.child,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_MapMarkerGesture> createState() => _MapMarkerGestureState();
}

class _MapMarkerGestureState extends State<_MapMarkerGesture> {
  bool _showTooltip = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: widget.onTap,
    onLongPress: widget.tooltip == null
        ? null
        : () => setState(() => _showTooltip = true),
    child: Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        widget.child,
        if (_showTooltip)
          Positioned(
            bottom: AppMetrics.mapTooltipOffset,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface1,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.hairline),
                ),
                child: Text(
                  widget.tooltip!,
                  style: AppType.caption.copyWith(color: AppColors.ink),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
