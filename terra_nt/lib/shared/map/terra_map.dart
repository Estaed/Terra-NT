import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/elevation.dart';
import '../../core/theme/map_visuals.dart';
import '../../core/theme/metrics.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/radius.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/util/itinerary_ops.dart';
import '../../data/models/poi.dart';
import '../widgets/app_icon.dart';
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
const _offlineAreaExplanation =
    'This map area is unavailable. Only areas you have opened '
    'are kept offline for up to 30 days. '
    'Use the stop or place list for details.';

/// The camera box covering every seeded place of interest.
///
/// Shared by Explore and the Welcome tile warm-up on purpose: the warm-up only
/// fetches the right tiles if it fits the same bounds as the screen it warms,
/// and two copies of this one line would be free to drift apart. This is the
/// `flutter_map` boundary, so it is also where `LatLng` gets constructed from
/// the models' raw doubles.
LatLngBounds poiBounds(List<Poi> pois) => LatLngBounds.fromPoints(
  pois.map((poi) => LatLng(poi.lat, poi.lng)).toList(growable: false),
);

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
  final ({Listenable listenable, List<DashedRoutePolyline> Function() build})?
  animatedPolylines;
  final bool interactive;
  final LatLng initialCenter;
  final double initialZoom;
  final LatLngBounds? bounds;
  final EdgeInsets fitPadding;
  final MapController? controller;
  final TileProvider? tileProvider;

  /// Result opts in to refitting its changing visible strip. A full-viewport
  /// Australia constraint and zoom floor would reject the fit above its tall
  /// sheet, so this mode allows the camera to zoom out to fit that strip.
  /// Other maps retain their existing camera limits and initial-only fit.
  final bool animateCameraFit;
  final bool suspendCameraFit;

  /// Result separates overlapping pin circles without changing their anchors.
  final bool separatePins;

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
    this.animatedPolylines,
    this.interactive = true,
    this.initialCenter = const LatLng(-18, 132),
    this.initialZoom = 5,
    this.bounds,
    this.fitPadding = const EdgeInsets.all(AppMetrics.mapResultFitPadding),
    this.controller,
    this.tileProvider,
    this.animateCameraFit = false,
    this.suspendCameraFit = false,
    this.separatePins = false,
    this.topOverlay,
    this.controlsPadding = EdgeInsets.zero,
  });

  static EdgeInsets backdropFitPadding = const EdgeInsets.all(
    AppMetrics.mapBackdropFitPadding,
  );
  static EdgeInsets exploreFitPadding = const EdgeInsets.all(
    AppMetrics.mapExploreFitPadding,
  );

  /// Explore's search pill floats over the map's top edge; the fit reserves
  /// the status bar plus the pill's own height and top margin so the
  /// northern pins land clear of both (V19, D15).
  ///
  /// The reservation gives way, exactly as [resultFitPaddingFor]'s does, when
  /// [viewportHeight] is too short to also hold [AppMetrics.mapExploreMinimumStrip]
  /// — the keyboard open over Explore's search field is the case that hits this.
  static EdgeInsets exploreFitPaddingFor(double topInset, double viewportHeight) {
    const margin = AppMetrics.mapExploreFitPadding;
    final desired =
        topInset +
        AppMetrics.exploreSearchInset +
        AppMetrics.exploreSearchFieldHeight;
    final extra = math.min(
      desired,
      math.max(
        0.0,
        viewportHeight - margin * 2 - AppMetrics.mapExploreMinimumStrip,
      ),
    );
    return EdgeInsets.fromLTRB(margin, margin + extra, margin, margin);
  }

  /// Result reserves its current sheet height and the status bar. Its camera
  /// can zoom out to fit the remaining strip, including at the top anchor.
  ///
  /// Without [sheetHeight], retain Loading's existing initial warm-up fit and
  /// its minimum strip, which uses the default map camera limits.
  static EdgeInsets resultFitPaddingFor(
    double viewportHeight,
    double topInset, {
    double? sheetHeight,
  }) {
    const margin = AppMetrics.mapResultFitPadding;
    if (sheetHeight != null) {
      // Prefer the usual breathing room, but retain pin-radius clearance in
      // a short strip. If the sheet covers the whole usable body there is no
      // physically visible map to fit; the refit then leaves the camera alone.
      final visibleHeight = math.max(
        0.0,
        viewportHeight - topInset - sheetHeight,
      );
      final verticalMargin = math.min(
        margin,
        math.max(AppMetrics.minTouchTarget / 2, visibleHeight / 4),
      );
      return EdgeInsets.fromLTRB(
        margin,
        topInset + verticalMargin,
        margin,
        sheetHeight + verticalMargin,
      );
    }
    final reserved = math.min(
      AppMetrics.resultSheetMidHeight,
      math.max(
        0.0,
        viewportHeight - AppMetrics.mapResultMinimumStrip - margin * 2,
      ),
    );
    return EdgeInsets.fromLTRB(
      margin,
      topInset + margin,
      margin,
      reserved + margin,
    );
  }

  @override
  State<TerraMap> createState() => _TerraMapState();
}

class _TerraMapState extends State<TerraMap>
    with SingleTickerProviderStateMixin {
  late final MapController _ownedController;
  late final AnimationController _cameraAnimation;
  MapCamera? _cameraFrom;
  MapCamera? _cameraTo;
  Size? _lastSize;
  bool _fitQueued = false;
  bool _fitImmediately = false;
  final Set<Object> _failedTiles = {};
  bool _tileStatusQueued = false;
  bool _offlineAreaUnavailable = false;

  void _onTileStatus(Object identity, bool failed) {
    if (!mounted) return;
    final changed = failed
        ? _failedTiles.add(identity)
        : _failedTiles.remove(identity);
    if (!changed || _tileStatusQueued) return;
    // Tile builders and disposal run during build. Defer the one shared
    // notice until that frame is complete, instead of rebuilding per tile.
    _tileStatusQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tileStatusQueued = false;
      final unavailable = _failedTiles.isNotEmpty;
      if (mounted && unavailable != _offlineAreaUnavailable) {
        setState(() => _offlineAreaUnavailable = unavailable);
        // A status change must not leave the new note over pins while the
        // camera animates. Tile churn with the same status never refits.
        _queueFit(immediate: true);
      }
    });
  }

  MapController get _controller => widget.controller ?? _ownedController;
  double get _minZoom => widget.animateCameraFit
      ? AppMetrics.mapResultMinZoom
      : AppMetrics.mapMinZoom;

  bool get _compactNotice => widget.separatePins;

  // Keep the explanation out of Result's fitted route. A tall sheet leaves
  // too little room for a text row, so use a side control in that case.
  bool _noticeAtSide(Size size) =>
      size.height -
          widget.fitPadding.bottom -
          MediaQuery.paddingOf(context).top <
      AppMetrics.minTouchTarget * 2 + AppSpacing.sm * 2;

  EdgeInsets _routeFitPadding(Size size) {
    final padding = widget.fitPadding;
    if (!_compactNotice || !_offlineAreaUnavailable) return padding;
    const clearance = AppMetrics.minTouchTarget / 2;
    if (_noticeAtSide(size)) {
      return padding.copyWith(
        left: math.max(
          padding.left,
          widget.controlsPadding.left +
              AppSpacing.sm +
              AppMetrics.minTouchTarget +
              clearance,
        ),
      );
    }
    return padding.copyWith(
      top: math.max(
        padding.top,
        MediaQuery.paddingOf(context).top +
            AppSpacing.sm +
            AppMetrics.minTouchTarget +
            clearance,
      ),
    );
  }

  void _showOfflineExplanation() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(
            color: AppColors.hairline,
            width: AppElevation.hairlineWidth,
          ),
        ),
        scrollable: true,
        content: Text(
          _offlineAreaExplanation,
          style: AppType.bodySm.copyWith(color: AppColors.inkSubtle),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: AppType.button.copyWith(color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _ownedController = MapController();
    _cameraAnimation = AnimationController(
      vsync: this,
      duration: AppMotion.resultCameraFit,
    )..addListener(_moveCamera);
  }

  @override
  void didUpdateWidget(TerraMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.suspendCameraFit || !widget.animateCameraFit) {
      _cameraAnimation.stop();
    }
    if (oldWidget.bounds != widget.bounds ||
        oldWidget.fitPadding != widget.fitPadding ||
        oldWidget.suspendCameraFit != widget.suspendCameraFit) {
      _queueFit();
    }
  }

  void _queueFit({bool immediate = false}) {
    if (!widget.animateCameraFit || widget.suspendCameraFit) {
      return;
    }
    _fitImmediately |= immediate;
    if (_fitQueued) return;
    _fitQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitQueued = false;
      final immediate = _fitImmediately;
      _fitImmediately = false;
      if (!mounted || !widget.animateCameraFit || widget.suspendCameraFit) {
        return;
      }
      final bounds = widget.bounds;
      if (bounds == null) return;
      final camera = _controller.camera;
      final padding = _routeFitPadding(camera.nonRotatedSize);
      if (camera.nonRotatedSize.height <= padding.vertical ||
          camera.nonRotatedSize.width <= padding.horizontal) {
        return;
      }
      _cameraFrom = camera;
      _cameraTo = CameraFit.bounds(
        bounds: bounds,
        padding: padding,
        maxZoom: AppMetrics.mapMaxZoom,
      ).fit(camera);
      if (immediate || MediaQuery.disableAnimationsOf(context)) {
        _cameraAnimation.value = 1;
        _moveCamera();
      } else {
        _cameraAnimation.forward(from: 0);
      }
    });
  }

  void _moveCamera() {
    final from = _cameraFrom;
    final to = _cameraTo;
    if (from == null || to == null) return;
    final progress = AppMotion.resultCameraFitCurve.transform(
      _cameraAnimation.value,
    );
    // Interpolate in map space, where the route itself is drawn, rather than
    // latitude space. Retargeting always starts at the current camera.
    final start = from.projectAtZoom(from.center, 0);
    final end = to.projectAtZoom(to.center, 0);
    final center = from.unprojectAtZoom(Offset.lerp(start, end, progress)!, 0);
    _controller.move(center, from.zoom + (to.zoom - from.zoom) * progress);
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if (hasGesture) _cameraAnimation.stop();
  }

  @override
  void dispose() {
    _cameraAnimation.dispose();
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

  Widget _markerLayer(List<TerraMapMarker> markers) {
    if (!widget.separatePins) return MarkerLayer(markers: _toMarkers(markers));
    // Place each route pin once in screen space. MarkerLayer repeats markers
    // across worlds at low zoom, which can also duplicate their keys when a
    // tab's preserved map is laid out offstage during navigation.
    return Builder(
      builder: (context) {
        final camera = MapCamera.of(context);
        final padding = _routeFitPadding(camera.nonRotatedSize);
        final points = [
          for (final marker in markers)
            camera.latLngToScreenOffset(marker.point),
        ];
        final separated = fanOutPins(
          [for (final point in points) (point.dx, point.dy)],
          left: padding.left,
          top: padding.top,
          right: camera.nonRotatedSize.width - padding.right,
          bottom: camera.nonRotatedSize.height - padding.bottom,
          diameter: AppMetrics.mapNumberedPinSize,
        );
        final targets = [
          for (var i = 0; i < markers.length; i++)
            Rect.fromCenter(
              center: Offset(separated[i].$1, separated[i].$2),
              width: markers[i].width ?? _markerWidth(markers[i]),
              height: markers[i].height ?? _markerHeight(markers[i]),
            ),
        ];
        final hitTargets = [
          for (var i = 0; i < markers.length; i++)
            if (markers[i].onTap != null || markers[i].tooltip != null)
              targets[i]
            else
              null,
        ];
        return Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  key: const ValueKey('route-pin-leaders'),
                  painter: _PinLeadersPainter(
                    anchors: points,
                    centres: [
                      for (final point in separated) Offset(point.$1, point.$2),
                    ],
                    opacities: [
                      for (final marker in markers)
                        switch (marker.child) {
                          Opacity(:final opacity) => opacity,
                          _ => 1.0,
                        },
                    ],
                  ),
                ),
              ),
            ),
            for (var index = 0; index < markers.length; index++)
              Positioned(
                key: markers[index].key,
                left: targets[index].left,
                top: targets[index].top,
                width: targets[index].width,
                height: targets[index].height,
                child: _PinHitRegion(
                  index: index,
                  target: targets[index],
                  hitTargets: hitTargets,
                  child: _MapMarkerGesture(
                    tooltip: markers[index].tooltip,
                    onTap: markers[index].onTap,
                    child: markers[index].child,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

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
    final fitted =
        CameraFit.bounds(bounds: bounds, padding: _routeFitPadding(size)).fit(
          MapCamera(
            crs: const Epsg3857(),
            center: widget.initialCenter,
            zoom: widget.initialZoom,
            rotation: 0,
            nonRotatedSize: size,
            minZoom: _minZoom,
            maxZoom: AppMetrics.mapMaxZoom,
          ),
        );
    return (fitted.center, fitted.zoom.clamp(_minZoom, AppMetrics.mapMaxZoom));
  }

  @override
  Widget build(BuildContext context) {
    final bounds = widget.bounds;
    if (bounds == null) {
      return _buildMap(context, widget.initialCenter, widget.initialZoom);
    }
    // Default maps keep their initial-only fit. Result refits after a resize.
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        if (_lastSize != null && _lastSize != size) _queueFit();
        _lastSize = size;
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
    final animatedPolylines = widget.animatedPolylines;
    return Stack(
      children: [
        FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: initialZoom,
            backgroundColor: AppColors.surface1,
            minZoom: _minZoom,
            maxZoom: AppMetrics.mapMaxZoom,
            // Default maps stay over Australia. Result needs its full camera
            // to extend beyond that box to fit a route above a tall sheet.
            cameraConstraint: widget.animateCameraFit
                ? const CameraConstraint.unconstrained()
                : CameraConstraint.contain(
                    bounds: AppMapVisuals.australiaCameraBounds,
                  ),
            onPositionChanged: widget.animateCameraFit
                ? _onPositionChanged
                : null,
            interactionOptions: InteractionOptions(
              flags: widget.interactive
                  ? InteractiveFlag.all
                  : InteractiveFlag.none,
            ),
          ),
          children: [
            // The default network provider shares the cache configured in main,
            // including this map when mounted by Welcome's TileWarmup.
            TileLayer(
              tileProvider: widget.tileProvider,
              tileBuilder: (context, child, tile) => _TileStatus(
                failed: tile.loadError,
                onStatus: _onTileStatus,
                child: child,
              ),
              urlTemplate: cartoDarkTileUrl,
              additionalOptions: const {'key': cartoApiKey},
              // Retina stays on: turning it off was profiled on 2026-09-12 and
              // bought no measurable frame time, while visibly softening the
              // basemap on a high density screen.
              retinaMode: RetinaMode.isHighDensity(context),
              userAgentPackageName: mapUserAgentPackageName,
              maxZoom: AppMetrics.mapMaxZoom,
            ),
            if (animatedPolylines != null)
              ListenableBuilder(
                listenable: animatedPolylines.listenable,
                builder: (context, _) => PolylineLayer(
                  polylines: animatedPolylines
                      .build()
                      .map((polyline) => polyline.toPolyline())
                      .toList(),
                ),
              )
            else if (widget.polylines.isNotEmpty)
              PolylineLayer(
                polylines: widget.polylines
                    .map((polyline) => polyline.toPolyline())
                    .toList(),
              ),
            if (animatedMarkers != null)
              ListenableBuilder(
                listenable: animatedMarkers.listenable,
                builder: (context, _) => _markerLayer(animatedMarkers.build()),
              )
            else if (widget.markers.isNotEmpty)
              _markerLayer(widget.markers),
          ],
        ),
        if (_offlineAreaUnavailable && _compactNotice)
          Positioned(
            left: widget.controlsPadding.left + AppSpacing.sm,
            top: MediaQuery.paddingOf(context).top + AppSpacing.sm,
            child: Builder(
              builder: (context) {
                final atSide = _noticeAtSide(
                  _lastSize ?? MediaQuery.sizeOf(context),
                );
                return SizedBox(
                  width: atSide
                      ? AppMetrics.minTouchTarget
                      : (_lastSize ?? MediaQuery.sizeOf(context)).width -
                            widget.controlsPadding.horizontal -
                            AppSpacing.sm * 2,
                  height: AppMetrics.minTouchTarget,
                  child: TextButton(
                    key: const ValueKey('map-offline-area-notice'),
                    onPressed: _showOfflineExplanation,
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.surface1,
                      foregroundColor: AppColors.inkSubtle,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        side: const BorderSide(
                          color: AppColors.hairline,
                          width: AppElevation.hairlineWidth,
                        ),
                      ),
                    ),
                    child: atSide
                        ? const Tooltip(
                            message: 'Map area unavailable. Show details',
                            child: AppIcon(
                              LucideIcons.info,
                              size: AppMetrics.iconMd,
                              color: AppColors.inkSubtle,
                            ),
                          )
                        : Text(
                            'Map area unavailable · Details',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.bodySm.copyWith(
                              color: AppColors.inkSubtle,
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
        if (_offlineAreaUnavailable && !_compactNotice)
          Positioned(
            left: widget.controlsPadding.left + AppSpacing.sm,
            right: widget.controlsPadding.right + AppSpacing.sm,
            top: widget.topOverlay == null
                ? MediaQuery.paddingOf(context).top + AppSpacing.sm
                : widget.controlsPadding.top +
                      AppMetrics.exploreSearchFieldHeight +
                      AppSpacing.md,
            child: IgnorePointer(
              child: Container(
                key: const ValueKey('map-offline-area-notice'),
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surface1,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: AppColors.hairline,
                    width: AppElevation.hairlineWidth,
                  ),
                ),
                child: Text(
                  _offlineAreaExplanation,
                  style: AppType.bodySm.copyWith(color: AppColors.inkSubtle),
                ),
              ),
            ),
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

/// TileLayer builds only rendered tiles. Registering their lifetime keeps the
/// notice specific to the current viewport and removes it on recovery or pan.
class _TileStatus extends StatefulWidget {
  const _TileStatus({
    required this.failed,
    required this.onStatus,
    required this.child,
  });

  final bool failed;
  final void Function(Object identity, bool failed) onStatus;
  final Widget child;

  @override
  State<_TileStatus> createState() => _TileStatusState();
}

class _TileStatusState extends State<_TileStatus> {
  final Object _identity = Object();

  @override
  void initState() {
    super.initState();
    widget.onStatus(_identity, widget.failed);
  }

  @override
  void didUpdateWidget(_TileStatus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.failed != widget.failed) {
      widget.onStatus(_identity, widget.failed);
    }
  }

  @override
  void dispose() {
    widget.onStatus(_identity, false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Overlapping thumb-sized targets give the tap to the nearest visible pin.
/// This preserves each pin's own centre even when zooming out densely.
class _PinHitRegion extends SingleChildRenderObjectWidget {
  final int index;
  final Rect target;
  final List<Rect?> hitTargets;

  const _PinHitRegion({
    required this.index,
    required this.target,
    required this.hitTargets,
    required super.child,
  });

  @override
  RenderProxyBox createRenderObject(BuildContext context) =>
      _RenderPinHitRegion(index, target, hitTargets);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderPinHitRegion renderObject,
  ) {
    renderObject
      ..index = index
      ..target = target
      ..hitTargets = hitTargets;
  }
}

class _RenderPinHitRegion extends RenderProxyBox {
  int index;
  Rect target;
  List<Rect?> hitTargets;

  _RenderPinHitRegion(this.index, this.target, this.hitTargets);

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final mapPosition = position + target.topLeft;
    final distance = (mapPosition - target.center).distanceSquared;
    for (var i = 0; i < hitTargets.length; i++) {
      final other = hitTargets[i];
      if (i == index || other == null || !other.contains(mapPosition)) continue;
      final otherDistance = (mapPosition - other.center).distanceSquared;
      if (otherDistance < distance ||
          (otherDistance == distance && i > index)) {
        return false;
      }
    }
    return super.hitTest(result, position: position);
  }
}

class _PinLeadersPainter extends CustomPainter {
  final List<Offset> anchors;
  final List<Offset> centres;
  final List<double> opacities;

  const _PinLeadersPainter({
    required this.anchors,
    required this.centres,
    required this.opacities,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = AppMetrics.mapPinBorderWidth
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < anchors.length; i++) {
      if (opacities[i] == 0 ||
          (centres[i] - anchors[i]).distance <=
              AppMetrics.mapNumberedPinSize / 2) {
        continue;
      }
      paint.color = AppColors.primary.withValues(alpha: opacities[i]);
      canvas.drawLine(anchors[i], centres[i], paint);
    }
  }

  @override
  bool shouldRepaint(_PinLeadersPainter oldDelegate) => true;
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
