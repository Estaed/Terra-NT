import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/motion.dart';
import '../../core/util/route_sampler.dart';

/// Clips a route by distance, so long legs draw continuously rather than
/// waiting for the next stop. Pins share the same distance-based timeline.
class RouteRevealGeometry {
  RouteRevealGeometry(this.points)
    : distances = cumulativeDistances([
        for (final point in points) [point.latitude, point.longitude],
      ]);

  final List<LatLng> points;
  final List<double> distances;

  List<LatLng> pointsAt(double progress) {
    if (points.isEmpty || progress <= 0) return const [];
    if (progress >= 1 || distances.last == 0) return points;
    final target = distances.last * progress;
    final revealed = <LatLng>[points.first];
    for (var index = 1; index < points.length; index++) {
      if (distances[index] <= target) {
        revealed.add(points[index]);
        continue;
      }
      final fraction =
          (target - distances[index - 1]) /
          (distances[index] - distances[index - 1]);
      final start = points[index - 1];
      final end = points[index];
      if (fraction > 0) {
        revealed.add(
          LatLng(
            start.latitude + (end.latitude - start.latitude) * fraction,
            start.longitude + (end.longitude - start.longitude) * fraction,
          ),
        );
      }
      break;
    }
    return revealed;
  }

  double pinOpacity(int index, double progress) {
    if (index == 0 || progress >= 1) return 1;
    final total = distances.last;
    final arrival = total == 0
        ? index / (points.length - 1)
        : distances[index] / total;
    final previousArrival = total == 0
        ? (index - 1) / (points.length - 1)
        : distances[index - 1] / total;
    final fadeSpan =
        AppMotion.resultPinReveal.inMicroseconds /
        AppMotion.resultRouteReveal.inMicroseconds;
    // Fade into place just as the drawing reaches this stop; the last pin
    // finishes with the line, without another animation tail.
    final start = math.max(previousArrival, arrival - fadeSpan);
    if (arrival == start) return progress >= arrival ? 1 : 0;
    return ((progress - start) / (arrival - start)).clamp(0.0, 1.0);
  }
}

/// Owns one reveal per opened itinerary. Edits preserve [routeIdentity] and
/// therefore preserve its progress. The builder wires only the map's moving
/// layers to the animation, leaving the sheet and tiles out of the tick loop.
class RouteReveal extends StatefulWidget {
  const RouteReveal({
    super.key,
    required this.routeIdentity,
    required this.builder,
  });

  final Object routeIdentity;
  final Widget Function(BuildContext, Animation<double>) builder;

  @override
  State<RouteReveal> createState() => _RouteRevealState();
}

class _RouteRevealState extends State<RouteReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.resultRouteReveal,
  );
  late final Animation<double> _progress = _controller.drive(
    CurveTween(curve: AppMotion.resultRouteRevealCurve),
  );
  bool _started = false;
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (!_started) {
      _started = true;
      _start();
    } else if (_reduceMotion) {
      _controller.value = 1;
    }
  }

  void _start() {
    if (_reduceMotion) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(RouteReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.routeIdentity, widget.routeIdentity)) _start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _progress);
}
