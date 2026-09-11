import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/map_visuals.dart';
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

/// Whether to ask CARTO for `@2x` tiles, matching what [TileLayer] resolves
/// `{r}` to. The tile prefetch reads the same value so its URLs stay identical
/// to the ones the tile layer later asks for — a prefetch under a different URL
/// warms nothing.
///
/// Left on: turning it off was profiled on 2026-09-12 (Task-22b) and bought no
/// frame time outside the noise band, while visibly softening the basemap on a
/// high density screen. An unproven gain does not justify a fidelity cost.
bool mapRetinaMode(BuildContext context) => RetinaMode.isHighDensity(context);

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

  /// Rebuilds *only* the marker layer whenever `listenable` notifies.
  ///
  /// An animated marker driven by `setState` on the caller rebuilds this whole
  /// widget, which hands `FlutterMap` a fresh `MapOptions` and `TileLayer`
  /// every tick. Scoping the rebuild to the marker layer leaves the tile and
  /// polyline layers alone. Supplied instead of [markers], not alongside.
  final ({Listenable listenable, List<TerraMapMarker> Function() build})?
  animatedMarkers;

  final List<DashedRoutePolyline> polylines;
  final bool interactive;
  final LatLng initialCenter;
  final double initialZoom;
  final LatLngBounds? bounds;
  final EdgeInsets fitPadding;
  final MapController? controller;

  /// A screen-owned control that floats above the map.
  final Widget? topOverlay;

  /// Keeps the floating controls clear of system UI. The caller supplies the
  /// safe-area insets; the map itself stays full-bleed behind them.
  final EdgeInsets controlsPadding;

  const TerraMap({
    super.key,
    this.markers = const [],
    this.animatedMarkers,
    this.polylines = const [],
    this.interactive = true,
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

  /// The Result map is full-screen behind its sheet, so the fit reserves the
  /// sheet's middle anchor at the bottom or every pin lands underneath it.
  ///
  /// The reservation gives way only when the screen is too short to hold both
  /// it and [AppMetrics.mapResultMinimumStrip]: squeezing the strip further
  /// bottoms the fit out at [AppMetrics.mapMinZoom] and shoves the northern
  /// pins off the top edge — the opposite of the problem it is there to solve.
  static EdgeInsets resultFitPaddingFor(double viewportHeight) {
    const margin = AppMetrics.mapResultFitPadding;
    final reserved = math.min(
      AppMetrics.resultSheetMidHeight,
      math.max(
        0.0,
        viewportHeight - AppMetrics.mapResultMinimumStrip - margin * 2,
      ),
    );
    return EdgeInsets.fromLTRB(margin, margin, margin, reserved + margin);
  }

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

  List<Marker> _toMarkers(List<TerraMapMarker> source) => source.map((marker) {
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

  /// The camera [widget.bounds] fits inside a viewport of [size], resolved
  /// before the map is built rather than after its first layout.
  ///
  /// `initialCameraFit` moves the camera only once the map has laid out, by
  /// which point the tile layer has already requested the tiles for the
  /// throwaway initial camera. A tile that is still in flight for that camera
  /// and is also needed by the fitted one is never re-requested, so the map can
  /// sit blank on its background colour until the user moves it — the Result
  /// map did exactly that on device. Fitting first means only one camera ever
  /// asks for tiles.
  (LatLng, double) _fittedCamera(LatLngBounds bounds, Size size) {
    if (!size.isFinite || size.isEmpty) {
      return (widget.initialCenter, widget.initialZoom);
    }
    final fitted = CameraFit.bounds(bounds: bounds, padding: widget.fitPadding)
        .fit(
          MapCamera(
            crs: const Epsg3857(),
            center: widget.initialCenter,
            zoom: widget.initialZoom,
            rotation: 0,
            nonRotatedSize: size,
            minZoom: AppMetrics.mapMinZoom,
            maxZoom: AppMetrics.mapMaxZoom,
          ),
        );
    return (
      fitted.center,
      fitted.zoom.clamp(AppMetrics.mapMinZoom, AppMetrics.mapMaxZoom),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bounds = widget.bounds;
    if (bounds == null) {
      return _buildMap(context, widget.initialCenter, widget.initialZoom);
    }
    // A later size change (rotation) leaves the camera where the user left it,
    // which is the same thing `initialCameraFit` did.
    return LayoutBuilder(
      builder: (context, constraints) {
        final (center, zoom) = _fittedCamera(bounds, constraints.biggest);
        return _buildMap(context, center, zoom);
      },
    );
  }

  Widget _buildMap(
    BuildContext context,
    LatLng initialCenter,
    double initialZoom,
  ) {
    final animatedMarkers = widget.animatedMarkers;
    return Stack(
      children: [
        FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: initialZoom,
            backgroundColor: AppColors.surface1,
            minZoom: AppMetrics.mapMinZoom,
            maxZoom: AppMetrics.mapMaxZoom,
            // Keeps the camera over Australia: without this the map pans off
            // into empty ocean and zooms out past the edge of the world.
            cameraConstraint: CameraConstraint.contain(
              bounds: AppMapVisuals.australiaCameraBounds,
            ),
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
              retinaMode: mapRetinaMode(context),
              userAgentPackageName: mapUserAgentPackageName,
              maxZoom: AppMetrics.mapMaxZoom,
            ),
            if (widget.polylines.isNotEmpty)
              PolylineLayer(
                polylines: widget.polylines
                    .map((polyline) => polyline.toPolyline())
                    .toList(),
              ),
            if (animatedMarkers != null)
              ListenableBuilder(
                listenable: animatedMarkers.listenable,
                builder: (context, _) =>
                    MarkerLayer(markers: _toMarkers(animatedMarkers.build())),
              )
            else if (widget.markers.isNotEmpty)
              MarkerLayer(markers: _toMarkers(widget.markers)),
          ],
        ),
        Positioned(
          right: AppMetrics.mapTooltipOffset + widget.controlsPadding.right,
          bottom: AppMetrics.mapTooltipOffset + widget.controlsPadding.bottom,
          child: const _MapAttribution(),
        ),
        if (widget.topOverlay != null)
          Positioned(
            left: widget.controlsPadding.left,
            right: widget.controlsPadding.right,
            top: widget.controlsPadding.top,
            child: widget.topOverlay!,
          ),
      ],
    );
  }
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
