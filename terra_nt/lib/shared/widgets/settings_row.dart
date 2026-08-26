import 'package:flutter/widgets.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/elevation.dart';
import '../../core/theme/metrics.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/radius.dart';
import '../../core/theme/typography.dart';
import 'app_icon.dart';

/// Profile / Account / Language row chrome, written once.
///
/// `onTap == null` renders as a non-interactive row — Language is a plain `div` in
/// the prototype (L642). The avatar row (44px leading) absorbs its extra 2px of
/// gap through its own sizing rather than a flag, per the decision recorded in
/// `tasks/Task-02.md`.
class SettingsRow extends StatefulWidget {
  const SettingsRow({
    super.key,
    this.leading,
    required this.label,
    this.subtitle,
    this.value,
    this.trailing,
    this.showChevron = false,
    this.onTap,
    this.foregroundColor,
  });

  final Widget? leading;
  final String label;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final bool showChevron;
  final VoidCallback? onTap;
  final Color? foregroundColor;

  @override
  State<SettingsRow> createState() => _SettingsRowState();
}

class _SettingsRowState extends State<SettingsRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final interactive = widget.onTap != null;
    final labelColor = widget.foregroundColor ?? AppColors.ink;

    final row = Row(
      children: [
        if (widget.leading != null) ...[
          widget.leading!,
          const SizedBox(width: AppMetrics.gapRow),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.label, style: AppType.titleApp.copyWith(color: labelColor)),
              if (widget.subtitle != null)
                Text(
                  widget.subtitle!,
                  style: AppType.caption.copyWith(color: AppColors.inkSubtle),
                ),
            ],
          ),
        ),
        if (widget.value != null)
          Text(
            widget.value!,
            style: AppType.bodyApp.copyWith(color: AppColors.inkSubtle),
          ),
        if (widget.trailing != null) widget.trailing!,
        if (widget.showChevron) ...[
          const SizedBox(width: AppMetrics.gapRow),
          const AppIcon(
            LucideIcons.chevron_right,
            size: AppMetrics.iconMd,
            color: AppColors.inkTertiary,
          ),
        ],
      ],
    );

    final card = AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.easeOut,
      padding: const EdgeInsets.symmetric(
        horizontal: AppMetrics.padRowX,
        vertical: AppMetrics.padRowY,
      ),
      decoration: BoxDecoration(
        color: _pressed ? AppColors.bgCardHover : AppColors.surface1,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.hairline, width: AppElevation.hairlineWidth),
      ),
      child: row,
    );

    if (!interactive) return card;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: card,
    );
  }
}
