import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/metrics.dart';
import '../../../core/theme/motion.dart';
import '../../../core/theme/radius.dart';
import '../../../shared/map/car_glyph.dart';

/// The onboarding progress, drawn as a road the trip is driven along
/// (deviation V13, polished under D18).
///
/// The road is a quiet band with a dashed centre line; the stretch already
/// driven is paved in [AppColors.primary]. The [CarGlyph] 4x4 rests on the road
/// with its centre on the travelled part's leading edge: on a step change the
/// fill and the car ease to the new position together, with the step card's
/// curve and duration, so the whole screen moves as one. It faces the direction
/// of travel, so going back drives it in reverse.
///
/// The widget is as tall as the car, [AppMetrics.progressCarHeight], with the
/// road along its bottom edge, so a parent lays out car and road as one piece.
class ProgressDrive extends StatefulWidget {
  const ProgressDrive({super.key, required this.percent}) : looping = false;

  /// An indeterminate mode for a screen with no step percentage to show: the
  /// car drives the full track and back, repeating, over
  /// [AppMotion.loadingProgressDriveLoop].
  const ProgressDrive.looping({super.key}) : percent = 0, looping = true;

  /// The filled share of the track, 0–100, as `progressPercent` reports it.
  /// Unused when [looping] is true.
  final int percent;

  /// When true, ignores [percent] and drives the fill back and forth forever.
  final bool looping;

  @override
  State<ProgressDrive> createState() => _ProgressDriveState();
}

class _ProgressDriveState extends State<ProgressDrive>
    with SingleTickerProviderStateMixin {
  static const _forward = 1.0;
  static const _reverse = -1.0;

  late final AnimationController _controller;
  late Animation<double> _fraction;

  /// Handed to [CarGlyph] as its longitude delta: its sign is the only thing
  /// that widget reads, and that is exactly the facing this needs.
  double _direction = _forward;
  bool _reduceMotion = false;

  double get _target => widget.percent / 100;

  @override
  void initState() {
    super.initState();
    if (widget.looping) {
      _controller = AnimationController(
        vsync: this,
        duration: AppMotion.loadingProgressDriveLoop,
      );
      _fraction = _controller;
      _controller.addStatusListener(_onLoopStatus);
      _controller.repeat(reverse: true);
      return;
    }
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.onboardingStepSlide,
    );
    // The first step renders at its percentage rather than driving up to it.
    _fraction = _driveTo(from: _target, to: _target);
  }

  /// Flips the car's facing at each end of the loop, so it visibly reverses
  /// rather than snapping back.
  void _onLoopStatus(AnimationStatus status) {
    if (status == AnimationStatus.forward) {
      _direction = _forward;
    } else if (status == AnimationStatus.reverse) {
      _direction = _reverse;
    }
  }

  Animation<double> _driveTo({required double from, required double to}) =>
      Tween<double>(
        begin: from,
        end: to,
      ).animate(CurvedAnimation(parent: _controller, curve: AppMotion.easeOut));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;
    if (_reduceMotion) {
      _controller.stop();
      _fraction = AlwaysStoppedAnimation(widget.looping ? 0.5 : _target);
    } else if (widget.looping) {
      _fraction = _controller;
      _controller.repeat(reverse: true);
    } else {
      _fraction = _driveTo(from: _target, to: _target);
    }
  }

  @override
  void didUpdateWidget(covariant ProgressDrive oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.looping || widget.percent == oldWidget.percent) return;
    // Starting from where the car actually is, not from the step it was headed
    // for, keeps a step change mid-drive continuous.
    final from = _fraction.value;
    _direction = _target >= from ? _forward : _reverse;
    if (_reduceMotion) {
      _fraction = AlwaysStoppedAnimation(_target);
      return;
    }
    _fraction = _driveTo(from: from, to: _target);
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SizedBox(
      key: const ValueKey('onboarding-progress-track'),
      height: AppMetrics.progressCarHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: AppMetrics.progressRoadHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: Stack(
                children: [
                  // Both layers carry the road height themselves: a `Stack`
                  // lays its children out loosely, and a childless box there
                  // paints nothing.
                  SizedBox(
                    key: const ValueKey('onboarding-progress-road'),
                    width: constraints.maxWidth,
                    height: AppMetrics.progressRoadHeight,
                    child: const ColoredBox(
                      color: AppColors.hairline,
                      child: CustomPaint(painter: _CentreLinePainter()),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _fraction,
                    builder: (context, child) => SizedBox(
                      key: const ValueKey('onboarding-progress-fill'),
                      width: constraints.maxWidth * _fraction.value,
                      height: AppMetrics.progressRoadHeight,
                      child: child,
                    ),
                    child: const ColoredBox(color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _fraction,
            builder: (context, child) => Positioned(
              left: _carLeft(constraints.maxWidth, _fraction.value),
              bottom: 0,
              width: AppMetrics.progressCarWidth,
              height: AppMetrics.progressCarHeight,
              // Rebuilt every tick (not passed as `child`) so a looping drive's
              // direction flip at each end of the track is actually drawn.
              child: TickerMode(
                key: const ValueKey('onboarding-progress-car'),
                enabled: !_reduceMotion,
                // The shared glyph has ambient bob/flip tickers. Freeze those
                // too; a direction change gets a fresh, already-facing glyph.
                child: CarGlyph(
                  key: _reduceMotion ? ValueKey(_direction) : null,
                  longitudeDelta: _direction,
                  width: AppMetrics.progressCarWidth,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  /// The car's centre rides the leading edge, held inside the track's ends so
  /// it never drives off either one.
  static double _carLeft(double trackWidth, double fraction) {
    const car = AppMetrics.progressCarWidth;
    return (trackWidth * fraction - car / 2).clamp(
      0.0,
      math.max(0.0, trackWidth - car),
    );
  }
}

/// The road's dashed centre line, the one mark that turns a bar into a road.
class _CentreLinePainter extends CustomPainter {
  const _CentreLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.hairlineTertiary
      ..strokeWidth = AppMetrics.progressRoadDashThickness;
    final y = size.height / 2;
    const step =
        AppMetrics.progressRoadDashLength + AppMetrics.progressRoadDashGap;
    for (var x = AppMetrics.progressRoadDashGap; x < size.width; x += step) {
      final end = math.min(x + AppMetrics.progressRoadDashLength, size.width);
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CentreLinePainter oldDelegate) => false;
}
