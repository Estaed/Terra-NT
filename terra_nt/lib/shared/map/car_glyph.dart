import 'package:flutter/material.dart';

import '../../core/theme/metrics.dart';
import '../../core/theme/motion.dart';

/// The side-view 4x4 that drives the map backdrop, the onboarding road and
/// Loading's looping bar: the rendered sprite `assets/images/car.png`.
///
/// It faces its direction of travel — a negative [longitudeDelta] mirrors it —
/// and bobs gently on [AppMotion.mapCarBob] while it is on screen.
///
/// The glyph owns its size, [width] wide at the sprite's own aspect. A parent
/// that hands it a smaller slot (the backdrop's 36x32 map marker) gets the car
/// centred on that slot and overflowing it, rather than a car shrunk to a
/// smudge.
class CarGlyph extends StatefulWidget {
  final double longitudeDelta;

  /// Logical width of the car; its height follows the sprite's aspect.
  final double width;

  const CarGlyph({
    super.key,
    required this.longitudeDelta,
    this.width = AppMetrics.mapCarSpriteWidth,
  });

  static const asset = 'assets/images/car.png';

  @override
  State<CarGlyph> createState() => _CarGlyphState();
}

class _CarGlyphState extends State<CarGlyph>
    with SingleTickerProviderStateMixin {
  static const flipDuration = AppMotion.mapCarFlip;
  static const bobDuration = AppMotion.mapCarBob;
  static const forwardScale = 1.0;
  static const reverseScale = -1.0;

  late final AnimationController _bobController;

  @override
  void initState() {
    super.initState();
    _bobController = AnimationController(vsync: this, duration: bobDuration)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final facingScale = widget.longitudeDelta < 0 ? reverseScale : forwardScale;
    final width = widget.width;
    final height = width / AppMetrics.carSpriteAspect;

    return OverflowBox(
      minWidth: width,
      maxWidth: width,
      minHeight: height,
      maxHeight: height,
      child: SizedBox(
        key: const ValueKey('car-glyph'),
        width: width,
        height: height,
        child: AnimatedBuilder(
          animation: _bobController,
          builder: (context, child) => Transform.translate(
            offset: Offset(
              0,
              -AppMetrics.mapCarBobOffset * _bobController.value,
            ),
            child: child,
          ),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: facingScale),
            duration: flipDuration,
            curve: Curves.linear,
            builder: (context, scale, child) => Transform.scale(
              key: const ValueKey('car-facing-transform'),
              scaleX: scale,
              child: child,
            ),
            child: Image.asset(
              CarGlyph.asset,
              width: width,
              height: height,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true,
              excludeFromSemantics: true,
            ),
          ),
        ),
      ),
    );
  }
}
