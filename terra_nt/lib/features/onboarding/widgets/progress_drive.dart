import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/metrics.dart';
import '../../../core/theme/motion.dart';
import '../../../core/theme/radius.dart';
import '../../../shared/map/car_glyph.dart';

/// The onboarding progress track, driven by a car (deviation V13).
///
/// The track and its fill keep the tokens and the keys the plain progress bar
/// used, so what a step's percentage looks like has not changed. What is new is
/// the [CarGlyph] riding the fill's leading edge: on a step change the fill and
/// the car ease to the new position together, with the step card's curve and
/// duration, so the whole screen moves as one.
///
/// The car is the map backdrop's glyph, scaled down to
/// [AppMetrics.onboardingProgressCarHeight] and centred on the track, which it
/// deliberately overhangs — the track is 4px and a car that small is a smudge.
/// It faces the direction of travel, so going back drives it in reverse.
class ProgressDrive extends StatefulWidget {
  const ProgressDrive({super.key, required this.percent});

  /// The filled share of the track, 0–100, as `progressPercent` reports it.
  final int percent;

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

  double get _target => widget.percent / 100;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.onboardingStepSlide,
    );
    // The first step renders at its percentage rather than driving up to it.
    _fraction = _driveTo(from: _target, to: _target);
  }

  Animation<double> _driveTo({required double from, required double to}) =>
      Tween<double>(
        begin: from,
        end: to,
      ).animate(CurvedAnimation(parent: _controller, curve: AppMotion.easeOut));

  @override
  void didUpdateWidget(covariant ProgressDrive oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.percent == oldWidget.percent) return;
    // Starting from where the car actually is, not from the step it was headed
    // for, keeps a step change mid-drive continuous.
    final from = _fraction.value;
    _direction = _target >= from ? _forward : _reverse;
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
      height: AppMetrics.onboardingProgressHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xs),
            child: Stack(
              children: [
                const ColoredBox(color: AppColors.hairlineStrong),
                AnimatedBuilder(
                  animation: _fraction,
                  builder: (context, child) => SizedBox(
                    key: const ValueKey('onboarding-progress-fill'),
                    width: constraints.maxWidth * _fraction.value,
                    child: child,
                  ),
                  child: const ColoredBox(color: AppColors.primary),
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _fraction,
            builder: (context, child) => Positioned(
              left: _carLeft(constraints.maxWidth, _fraction.value),
              top: _carTop,
              width: AppMetrics.onboardingProgressCarWidth,
              height: AppMetrics.onboardingProgressCarHeight,
              child: child!,
            ),
            child: FittedBox(
              key: const ValueKey('onboarding-progress-car'),
              child: CarGlyph(longitudeDelta: _direction),
            ),
          ),
        ],
      ),
    ),
  );

  /// Negative: the car is taller than the track it is centred on.
  static const _carTop =
      (AppMetrics.onboardingProgressHeight -
          AppMetrics.onboardingProgressCarHeight) /
      2;

  /// The car's centre rides the leading edge, held inside the track's ends so
  /// it never drives off either one.
  static double _carLeft(double trackWidth, double fraction) {
    const car = AppMetrics.onboardingProgressCarWidth;
    return (trackWidth * fraction - car / 2).clamp(
      0.0,
      math.max(0.0, trackWidth - car),
    );
  }
}
