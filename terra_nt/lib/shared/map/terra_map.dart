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

const cartoDarkTileUrl =
    'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
const cartoAttribution = '© OpenStreetMap © CARTO';

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
      width: marker.width ?? _markerWidth(marker.child),
      height: marker.height ?? _markerHeight(marker.child),
      child: _MapMarkerGesture(
        tooltip: marker.tooltip,
        onTap: marker.onTap,
        child: marker.child,
      ),
    );
  }).toList();

  double _markerWidth(Widget child) {
    if (child is RouteDotMarker) return AppMetrics.mapRouteDotSize;
    if (child is NumberedPinMarker) return AppMetrics.mapNumberedPinSize;
    return AppMetrics.mapPoiPinSize;
  }

  double _markerHeight(Widget child) => _markerWidth(child);

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
            subdomains: const ['a', 'b', 'c', 'd'],
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
      const Positioned(
        right: AppMetrics.mapTooltipOffset,
        bottom: AppMetrics.mapTooltipOffset,
        child: _MapAttribution(),
      ),
      if (widget.zoomControl)
        Positioned(
          right: AppMetrics.mapTooltipOffset,
          top: AppMetrics.mapTooltipOffset,
          child: _ZoomControls(controller: _controller),
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

  @override
  Widget build(BuildContext context) => DecoratedBox(
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
