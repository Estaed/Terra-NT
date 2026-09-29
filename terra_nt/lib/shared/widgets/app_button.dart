import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/elevation.dart';
import '../../core/theme/metrics.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/radius.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import 'app_icon.dart';

enum AppButtonVariant { primary, secondary, inverse }

enum AppButtonSize { lg, md }

/// The prototype's `Button` component (`_ds_bundle.js`, not in the repo).
///
/// Reconstructed from Task-01's tokens and the 14 call sites' inline CSS
/// (`docs/PRD.md` §2, gap 3). Pressed, the fill steps to its pressed colour and
/// the painted box settles to [AppMotion.pressScale] over [AppMotion.fast], the
/// press state the polish pass adds (`docs/PRD.md` D18). The scale is paint-only:
/// layout, hit target and neighbours stay where they were. Still no ripple.
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
    this.leading,
    this.foregroundColor,
  }) : assert(
         iconLeft == null || leading == null,
         'iconLeft and leading are mutually exclusive',
       );

  final Widget child;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool fullWidth;
  final IconData? iconLeft;
  final IconData? iconRight;
  final Widget? leading;
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
      case AppButtonVariant.inverse:
        return pressed
            ? AppColors.actionInverseBgHover
            : AppColors.actionInverseBg;
    }
  }

  Color get _foreground {
    if (widget.foregroundColor != null) return widget.foregroundColor!;
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return AppColors.actionPrimaryFg;
      case AppButtonVariant.secondary:
        return AppColors.actionSecondaryFg;
      case AppButtonVariant.inverse:
        return AppColors.actionInverseFg;
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
          AppIcon(
            widget.iconLeft!,
            size: AppMetrics.iconMd,
            color: _foreground,
          ),
          const SizedBox(width: AppMetrics.gapButtonIcon),
        ],
        if (widget.leading != null) ...[
          widget.leading!,
          const SizedBox(width: AppMetrics.gapButtonIcon),
        ],
        DefaultTextStyle.merge(
          style: AppType.button.copyWith(color: _foreground),
          child: widget.child,
        ),
        if (widget.iconRight != null) ...[
          const SizedBox(width: AppMetrics.gapButtonIcon),
          AppIcon(
            widget.iconRight!,
            size: AppMetrics.iconMd,
            color: _foreground,
          ),
        ],
      ],
    );

    final button = GestureDetector(
      onTapDown: widget._disabled
          ? null
          : (_) => setState(() => _pressed = true),
      onTapCancel: widget._disabled
          ? null
          : () => setState(() => _pressed = false),
      onTapUp: widget._disabled
          ? null
          : (_) => setState(() => _pressed = false),
      onTap: widget.onPressed,
      // Scaled below the detector: the pointer was claimed at full size on
      // tap-down, so settling the paint cannot drop a press near the edge.
      child: AnimatedScale(
        scale: _pressed && !widget._disabled ? AppMotion.pressScale : 1,
        duration: AppMotion.fast,
        curve: AppMotion.easeOut,
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
      ),
    );

    // The prototype paints 40px (lg) and 36px (md), both under the minimum
    // finger target. [_MinTapTarget] keeps those painted heights and the layout
    // height the parent sees, and grows only the area that accepts a pointer
    // into the gap the screens already leave around a button.
    return _MinTapTarget(
      minSize: const Size.square(AppMetrics.minTouchTarget),
      child: Opacity(opacity: widget._disabled ? 0.5 : 1, child: button),
    );
  }
}

/// Grows a button's hit target outwards without changing the size it reports to
/// its parent.
///
/// Wrapping the button in a larger [SizedBox] — the pattern the screens use for
/// controls that sit in their own free space — would push every neighbour
/// apart, and `CLAUDE.md` Part 2 makes a moved pixel a defect. This box lays the
/// child out exactly as before and only widens the area that accepts a pointer,
/// spending the transparent margin already present around the button.
///
/// A pointer landing in that margin is forwarded to the centre of the child, so
/// the child needs no knowledge of the grown target. An ancestor that clips its
/// hit tests — a scroll viewport, a [ClipRect] — still wins: the margin only
/// works where the surrounding pixels belong to the same unclipped parent.
class _MinTapTarget extends SingleChildRenderObjectWidget {
  const _MinTapTarget({required this.minSize, required Widget super.child});

  /// The smallest area, centred on the child, that must accept a pointer.
  final Size minSize;

  @override
  _RenderMinTapTarget createRenderObject(BuildContext context) =>
      _RenderMinTapTarget(minSize);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderMinTapTarget renderObject,
  ) {
    renderObject.minSize = minSize;
  }
}

/// Sizes to its child; hit-tests larger.
class _RenderMinTapTarget extends RenderProxyBox {
  _RenderMinTapTarget(this.minSize);

  /// The smallest area, centred on the child, that must accept a pointer.
  ///
  /// Nothing painted or laid out depends on it — [hitTest] reads it live — so
  /// assigning it needs neither a layout nor a paint pass.
  Size minSize;

  /// The area that accepts a pointer, centred on the painted box.
  Rect get tapRect {
    final dx = math.max(0.0, (minSize.width - size.width) / 2);
    final dy = math.max(0.0, (minSize.height - size.height) / 2);
    return Rect.fromLTRB(-dx, -dy, size.width + dx, size.height + dy);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (super.hitTest(result, position: position)) return true;

    final child = this.child;
    if (child == null || !tapRect.contains(position)) return false;

    final center = child.size.center(Offset.zero);
    final hit = result.addWithRawTransform(
      transform: MatrixUtils.forceToPoint(center),
      position: center,
      hitTest: (BoxHitTestResult result, Offset position) =>
          child.hitTest(result, position: center),
    );
    if (hit) result.add(BoxHitTestEntry(this, position));
    return hit;
  }
}
