import 'package:flutter/widgets.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/elevation.dart';
import '../../core/theme/metrics.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/radius.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import 'app_icon.dart';

enum AppButtonVariant { primary, secondary }

enum AppButtonSize { lg, md }

/// The prototype's `Button` component (`_ds_bundle.js`, not in the repo).
///
/// Reconstructed from Task-01's tokens and the 14 call sites' inline CSS
/// (`docs/PRD.md` §2, gap 3). Press is colour-only — no scale, no translate, no
/// ripple — per `design-system/README.md`.
///
/// `onPressed == null` renders disabled at `Opacity(0.5)` and ignores taps. No
/// disabled action token exists to reconstruct from, so 0.5 is chosen to match the
/// skipped-stop precedent (`docs/PRD.md` §3.6).
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.lg,
    this.fullWidth = false,
    this.iconLeft,
    this.iconRight,
    this.foregroundColor,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool fullWidth;
  final IconData? iconLeft;
  final IconData? iconRight;
  final Color? foregroundColor;

  bool get _disabled => onPressed == null;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  Color get _background {
    final pressed = _pressed && !widget._disabled;
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return pressed
            ? AppColors.actionPrimaryBgPressed
            : AppColors.actionPrimaryBg;
      case AppButtonVariant.secondary:
        return pressed
            ? AppColors.actionSecondaryBgHover
            : AppColors.actionSecondaryBg;
    }
  }

  Color get _foreground {
    if (widget.foregroundColor != null) return widget.foregroundColor!;
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return AppColors.actionPrimaryFg;
      case AppButtonVariant.secondary:
        return AppColors.actionSecondaryFg;
    }
  }

  double get _height => switch (widget.size) {
        AppButtonSize.lg => AppMetrics.buttonHeightLg,
        AppButtonSize.md => AppMetrics.buttonHeightMd,
      };

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.iconLeft != null) ...[
          AppIcon(widget.iconLeft!, size: AppMetrics.iconMd, color: _foreground),
          const SizedBox(width: AppMetrics.gapButtonIcon),
        ],
        DefaultTextStyle.merge(
          style: AppType.button.copyWith(color: _foreground),
          child: widget.child,
        ),
        if (widget.iconRight != null) ...[
          const SizedBox(width: AppMetrics.gapButtonIcon),
          AppIcon(widget.iconRight!, size: AppMetrics.iconMd, color: _foreground),
        ],
      ],
    );

    final button = GestureDetector(
      onTapDown: widget._disabled ? null : (_) => setState(() => _pressed = true),
      onTapCancel: widget._disabled ? null : () => setState(() => _pressed = false),
      onTapUp: widget._disabled ? null : (_) => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.easeOut,
        height: _height,
        width: widget.fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.padButtonX,
          vertical: AppSpacing.padButtonY,
        ),
        decoration: BoxDecoration(
          color: _background,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: widget.variant == AppButtonVariant.secondary
              ? Border.all(
                  color: AppColors.borderCard,
                  width: AppElevation.hairlineWidth,
                )
              : null,
        ),
        alignment: Alignment.center,
        child: content,
      ),
    );

    return Opacity(opacity: widget._disabled ? 0.5 : 1, child: button);
  }
}
