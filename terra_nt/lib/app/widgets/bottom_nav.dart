import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/metrics.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../shared/widgets/app_icon.dart';

/// The shell's fixed four-item navigation bar.
class BottomNav extends StatelessWidget {
  const BottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  static const planAiIndex = 1;
  static const profileIndex = 3;
  static const tabCount = 4;

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = [
    _BottomNavItem('Explore', LucideIcons.compass),
    _BottomNavItem('Plan AI', LucideIcons.sparkles),
    _BottomNavItem('Saved Routes', LucideIcons.bookmark),
    _BottomNavItem('Profile', LucideIcons.user),
  ];

  @override
  Widget build(BuildContext context) {
    // The bar keeps its measured 64px of content and pushes the device's bottom
    // inset below it, so no tab label sits under the gesture bar.
    return DecoratedBox(
      key: const ValueKey('bottom-nav'),
      decoration: const BoxDecoration(
        color: AppColors.surface1,
        border: Border(top: BorderSide(color: AppColors.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppSpacing.padFooterY,
          child: Row(
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final active = index == selectedIndex;
              final color = active ? AppColors.ink : AppColors.inkTertiary;
              return Expanded(
                child: InkWell(
                  key: ValueKey('bottom-nav-tab-$index'),
                  onTap: () => onSelected(index),
                  child: Semantics(
                    selected: active,
                    button: true,
                    label: item.label,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppIcon(
                          item.icon,
                          key: ValueKey('bottom-nav-icon-$index'),
                          size: AppMetrics.iconXl,
                          color: color,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        // Scaled-up type must shrink rather than push the label
                        // out of the bar's fixed height.
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              item.label,
                              key: ValueKey('bottom-nav-label-$index'),
                              maxLines: 1,
                              softWrap: false,
                              style: AppType.captionApp.copyWith(color: color),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem {
  const _BottomNavItem(this.label, this.icon);

  final String label;
  final IconData icon;
}
