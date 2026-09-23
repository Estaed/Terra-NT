import 'package:flutter/widgets.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/metrics.dart';
import '../../shared/map/route_car_backdrop.dart';

/// The decorative map and scrim shared by the pre-app authentication screens.
class AuthBackdrop extends StatelessWidget {
  const AuthBackdrop({super.key});

  static final _scrim = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    stops: const [
      0,
      AppMetrics.loginScrimMidpoint,
      AppMetrics.loginScrimOpaquePoint,
      1,
    ],
    colors: [
      AppColors.loginScrimStart,
      AppColors.loginScrimMid,
      AppColors.canvas,
      AppColors.canvas,
    ],
  );

  // Laid out at the full screen height even while the Scaffold shrinks its body
  // for the keyboard, so the map attribution goes behind the keyboard instead
  // of over the links. The body zeroes `MediaQuery` insets; `View` keeps them.
  @override
  Widget build(BuildContext context) {
    final view = View.of(context);
    final keyboardInset = view.viewInsets.bottom / view.devicePixelRatio;
    return LayoutBuilder(
      builder: (context, constraints) {
        final fullHeight = constraints.maxHeight + keyboardInset;
        return OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: fullHeight,
          maxHeight: fullHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const Positioned.fill(child: RouteCarBackdrop.ambient()),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(gradient: _scrim),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
