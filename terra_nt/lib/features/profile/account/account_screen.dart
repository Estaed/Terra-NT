import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/elevation.dart';
import '../../../core/theme/metrics.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../data/repositories/notifiers.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../shared/widgets/settings_row.dart';

/// The read-only account details destination from Profile.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  void _goBack(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionNotifierProvider);
    final email = session.email?.isNotEmpty == true
        ? session.email!
        : 'explorer@example.com';

    return Scaffold(
      key: const ValueKey('account-screen'),
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
                    key: const ValueKey('account-back-button'),
                    tooltip: 'Back',
                    onPressed: () => _goBack(context),
                    icon: const AppIcon(
                      LucideIcons.arrow_left,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  const Expanded(
                    child: Text('Account', style: AppType.headline),
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
                  leading: const _AccountAvatar(),
                  label: 'NT Explorer',
                  subtitle: email,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountAvatar extends StatelessWidget {
  const _AccountAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppMetrics.avatarSize,
      height: AppMetrics.avatarSize,
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppRadius.avatar),
        border: Border.all(
          color: AppColors.hairlineStrong,
          width: AppElevation.hairlineWidth,
        ),
      ),
      alignment: Alignment.center,
      child: const AppIcon(
        LucideIcons.user,
        size: AppMetrics.iconXl,
        color: AppColors.inkSubtle,
      ),
    );
  }
}
