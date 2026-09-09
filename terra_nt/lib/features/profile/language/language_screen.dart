import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/metrics.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../shared/widgets/settings_row.dart';

/// The single-option language destination from Profile.
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  void _goBack(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('language-screen'),
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xs,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  IconButton(
                    key: const ValueKey('language-back-button'),
                    tooltip: 'Back',
                    onPressed: () => _goBack(context),
                    icon: const AppIcon(
                      LucideIcons.arrow_left,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  const Expanded(
                    child: Text('Language', style: AppType.headline),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xxs,
                  AppSpacing.md,
                  AppSpacing.xl,
                ),
                child: SettingsRow(
                  label: 'English',
                  trailing: const AppIcon(
                    LucideIcons.check,
                    key: ValueKey('language-selected'),
                    size: AppMetrics.iconMd,
                    color: AppColors.ink,
                  ),
                  onTap: () {},
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
