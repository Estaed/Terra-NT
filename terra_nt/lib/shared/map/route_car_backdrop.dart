import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/metrics.dart';
import '../../core/theme/motion.dart';
import '../../core/util/route_sampler.dart';
import 'car_glyph.dart';
import 'dashed_route_polyline.dart';
import 'map_markers.dart';
import 'terra_map.dart';

enum RouteCarBackdropMode { ambient, progress }

/// A non-interactive map with a car that travels along the decorative NT route.
class RouteCarBackdrop extends StatefulWidget {
  static const ambientStartDelay = AppMotion.mapAmbientStartDelay;
  static const ambientPause = AppMotion.mapAmbientPause;
  static const travelBaseDurationMs = AppMotion.mapTravelBaseMilliseconds;
  static const travelSpanDurationMs = AppMotion.mapTravelSpanMilliseconds;

  static const List<List<double>> routeCoordinates = <List<double>>[
    <double>[-12.4634, 130.8456],
    <double>[-13.1830, 130.6805],
    <double>[-12.6692, 132.8352],
    <double>[-14.3103, 132.4204],
    <double>[-23.6980, 133.8807],
    <double>[-24.2634, 131.5567],
    <double>[-25.3444, 131.0369],
  ];

  final RouteCarBackdropMode mode;
  final double fraction;

  const RouteCarBackdrop.ambient({super.key})
    : mode = RouteCarBackdropMode.ambient,
      fraction = 0;

  const RouteCarBackdrop.progress({super.key, required this.fraction})
    : mode = RouteCarBackdropMode.progress;

  @override
  RouteCarBackdropState createState() => RouteCarBackdropState();
}

class RouteCarBackdropState extends State<RouteCarBackdrop>
    with SingleTickerProviderStateMixin {
  static const _minimumFraction = 0.0;
  static const _maximumFraction = 1.0;
  static const _easeOutCubic = _EaseOutCubic();

  late final AnimationController _travelController;
  Timer? _ambientTimer;
  double _fraction = _minimumFraction;
  List<double> _previousSample = RouteCarBackdrop.routeCoordinates.first;
  double _longitudeDelta = _minimumFraction;

  LatLng get currentPosition {
    final sample = pointAtFraction(
      RouteCarBackdrop.routeCoordinates,
      _fraction,
    );
    return LatLng(sample.first, sample.last);
  }

  double get currentFraction => _fraction;

  @override
  void initState() {
    super.initState();
    _travelController = AnimationController(vsync: this)
      ..addListener(_advanceTravel)
      ..addStatusListener(_completeTravel);
    if (widget.mode == RouteCarBackdropMode.ambient) {
      _ambientTimer = Timer(
        RouteCarBackdrop.ambientStartDelay,
        _startAmbientLoop,
      );
    }
  }

  @override
  void didUpdateWidget(covariant RouteCarBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mode != oldWidget.mode) {
      _ambientTimer?.cancel();
      _travelController.stop();
      if (widget.mode == RouteCarBackdropMode.ambient) {
        _ambientTimer = Timer(
          RouteCarBackdrop.ambientStartDelay,
          _startAmbientLoop,
        );
      } else {
        _animateTo(widget.fraction);
      }
      return;
    }
    if (widget.mode == RouteCarBackdropMode.progress &&
        widget.fraction != oldWidget.fraction) {
      _animateTo(widget.fraction);
    }
  }

  void _startAmbientLoop() => _animateTo(_maximumFraction);

  void _animateTo(double requestedTarget) {
    _ambientTimer?.cancel();
    final target = requestedTarget
        .clamp(_minimumFraction, _maximumFraction)
        .toDouble();
    final start = _fraction;
    final span = (target - start).abs();
    final durationMilliseconds =
        RouteCarBackdrop.travelBaseDurationMs +
        span * RouteCarBackdrop.travelSpanDurationMs;

    _travelController
      ..stop()
      ..duration = Duration(milliseconds: durationMilliseconds.round());
    _travelStart = start;
    _travelTarget = target;
    _travelController.forward(from: _minimumFraction);
  }

  double _travelStart = _minimumFraction;
  double _travelTarget = _minimumFraction;

  void _advanceTravel() {
    final easedProgress = _easeOutCubic.transform(_travelController.value);
    final fraction =
        _travelStart + (_travelTarget - _travelStart) * easedProgress;
    final sample = pointAtFraction(RouteCarBackdrop.routeCoordinates, fraction);
    if (!mounted) return;
    setState(() {
      _fraction = fraction;
      _longitudeDelta = sample.last - _previousSample.last;
      _previousSample = sample;
    });
  }

  void _completeTravel(AnimationStatus status) {
    if (status != AnimationStatus.completed ||
        widget.mode != RouteCarBackdropMode.ambient ||
        !mounted) {
      return;
    }
    final nextTarget = _travelTarget == _maximumFraction
        ? _minimumFraction
        : _maximumFraction;
    _ambientTimer = Timer(
      RouteCarBackdrop.ambientPause,
      () => _animateTo(nextTarget),
    );
  }

  @override
  void dispose() {
    _ambientTimer?.cancel();
    _travelController
      ..removeListener(_advanceTravel)
      ..removeStatusListener(_completeTravel)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final points = RouteCarBackdrop.routeCoordinates
        .map((point) => LatLng(point.first, point.last))
        .toList(growable: false);
    return SizedBox.expand(
      child: TerraMap(
        interactive: false,
        bounds: LatLngBounds.fromPoints(points),
        fitPadding: TerraMap.backdropFitPadding,
        polylines: [DashedRoutePolyline.backdrop(points: points)],
        markers: [
          ...points.map(
            (point) =>
                TerraMapMarker(point: point, child: const RouteDotMarker()),
          ),
          TerraMapMarker(
            key: const ValueKey('route-car-marker'),
            point: currentPosition,
            width: AppMetrics.mapCarMarkerWidth,
            height: AppMetrics.mapCarMarkerHeight,
            child: CarGlyph(longitudeDelta: _longitudeDelta),
          ),
        ],
      ),
    );
  }
}

class _EaseOutCubic extends Curve {
  const _EaseOutCubic();

  @override
  double transformInternal(double t) => 1 - math.pow(1 - t, 3).toDouble();
}
