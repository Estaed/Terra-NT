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
    // Keep the usual 64px bar, growing for wrapped system-scaled labels.
    // The device's bottom inset stays below the content.
    return DecoratedBox(
      key: const ValueKey('bottom-nav'),
      decoration: const BoxDecoration(
        color: AppColors.surface1,
        border: Border(top: BorderSide(color: AppColors.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpacing.padFooterY),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      excludeSemantics: true,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xxs,
                          vertical: AppSpacing.xs,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppIcon(
                              item.icon,
                              key: ValueKey('bottom-nav-icon-$index'),
                              size: AppMetrics.iconXl,
                              color: color,
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              item.label,
                              key: ValueKey('bottom-nav-label-$index'),
                              textAlign: TextAlign.center,
                              style: AppType.captionApp.copyWith(
                                color: active
                                    ? AppColors.ink
                                    : AppColors.inkSubtle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
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
