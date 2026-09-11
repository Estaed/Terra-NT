import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/map_visuals.dart';
import '../../core/theme/metrics.dart';
import '../../core/theme/motion.dart';

/// The decorative side-view car used by [RouteCarBackdrop].
class CarGlyph extends StatefulWidget {
  final double longitudeDelta;

  const CarGlyph({super.key, required this.longitudeDelta});

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

    return SizedBox(
      key: const ValueKey('car-glyph'),
      width: AppMetrics.mapCarMarkerWidth,
      height: AppMetrics.mapCarMarkerHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: AppMetrics.mapCarShadowBottom,
            child: Container(
              width: AppMetrics.mapCarShadowWidth,
              height: AppMetrics.mapCarShadowHeight,
              decoration: BoxDecoration(
                color: AppMapVisuals.carShadowColor,
                borderRadius: BorderRadius.circular(
                  AppMetrics.mapCarShadowHeight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppMapVisuals.carShadowBlurColor,
                    blurRadius: AppMetrics.mapCarBobOffset,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: AppMetrics.mapCarBodyTop,
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
                child: CustomPaint(
                  size: const Size(
                    AppMetrics.mapCarBodyWidth,
                    AppMetrics.mapCarBodyHeight,
                  ),
                  painter: _CarBodyPainter(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CarBodyPainter extends CustomPainter {
  static const _bodyTop = 0.23;
  static const _bodyBottom = 0.68;
  static const _roofStart = 0.22;
  static const _roofEnd = 0.76;
  static const _wheelCenterY = 0.71;
  static const _wheelRadius = 0.14;
  static const _frontWheelX = 0.72;
  static const _rearWheelX = 0.3;

  @override
  void paint(Canvas canvas, Size size) {
    final body = Path()
      ..moveTo(size.width * 0.07, size.height * _bodyBottom)
      ..lineTo(size.width * 0.15, size.height * 0.36)
      ..quadraticBezierTo(
        size.width * _roofStart,
        size.height * _bodyTop,
        size.width * 0.34,
        size.height * _bodyTop,
      )
      ..lineTo(size.width * _roofEnd, size.height * _bodyTop)
      ..quadraticBezierTo(
        size.width * 0.85,
        size.height * _bodyTop,
        size.width * 0.92,
        size.height * 0.36,
      )
      ..lineTo(size.width * 0.98, size.height * _bodyBottom)
      ..close();
    canvas.drawPath(body, Paint()..color = AppColors.primary);
    canvas.drawPath(
      body,
      Paint()
        ..color = AppColors.primaryFocus
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppMetrics.mapPinBorderWidth,
    );

    final window = Path()
      ..moveTo(size.width * 0.32, size.height * 0.28)
      ..lineTo(size.width * 0.73, size.height * 0.28)
      ..lineTo(size.width * 0.82, size.height * 0.48)
      ..lineTo(size.width * 0.23, size.height * 0.48)
      ..close();
    canvas.drawPath(window, Paint()..color = AppMapVisuals.carWindowColor);

    _drawWheel(canvas, size, _rearWheelX);
    _drawWheel(canvas, size, _frontWheelX);
  }

  void _drawWheel(Canvas canvas, Size size, double x) {
    final center = Offset(size.width * x, size.height * _wheelCenterY);
    final radius = size.height * _wheelRadius;
    canvas.drawCircle(center, radius, Paint()..color = AppColors.surface3);
    canvas.drawCircle(
      center,
      radius / AppMetrics.mapCarWheelHubDivisor,
      Paint()..color = AppColors.inkTertiary,
    );
  }

  @override
  bool shouldRepaint(covariant _CarBodyPainter oldDelegate) => false;
}
