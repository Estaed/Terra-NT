import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routes.dart';
import '../../app/tab_shell.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/elevation.dart';
import '../../core/theme/metrics.dart';
import '../../core/theme/radius.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../data/repositories/notifiers.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_icon.dart';
import '../../shared/widgets/settings_row.dart';

/// The Profile tab, including its session-only offline-maps setting.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, this.onShowAccount, this.onShowLanguage});

  final VoidCallback? onShowAccount;
  final VoidCallback? onShowLanguage;

  void _showAccount(BuildContext context) {
    final callback = onShowAccount;
    if (callback != null) {
      callback();
      return;
    }
    AppShell.of(context).showAccount();
  }

  void _showLanguage(BuildContext context) {
    final callback = onShowLanguage;
    if (callback != null) {
      callback();
      return;
    }
    AppShell.of(context).showLanguage();
  }

  Future<void> _logOut(BuildContext context, WidgetRef ref) async {
    await ref.read(sessionNotifierProvider.notifier).signOut();
    if (!context.mounted) return;
    _showLogin(context);
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    await ref.read(sessionNotifierProvider.notifier).deleteAccount();
    ref.read(profileNotifierProvider.notifier).cancelDeleteAccount();
    if (!context.mounted) return;
    _showLogin(context);
  }

  void _showLogin(BuildContext context) {
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushReplacement(placeholderRoute(AppRoute.login));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionNotifierProvider);
    final profile = ref.watch(profileNotifierProvider);
    final email = session.email?.isNotEmpty == true
        ? session.email!
        : 'explorer@example.com';

    return Scaffold(
      key: const ValueKey('profile-screen'),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Profile', style: AppType.headline),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, viewportConstraints) =>
                    SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.xxs,
                        AppSpacing.md,
                        AppSpacing.xl,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: viewportConstraints.maxWidth,
                          minHeight: viewportConstraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SettingsRow(
                                leading: const _ProfileAvatar(),
                                label: 'NT Explorer',
                                subtitle: email,
                                showChevron: true,
                                onTap: () => _showAccount(context),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              SettingsRow(
                                leading: const AppIcon(
                                  LucideIcons.download,
                                  size: AppMetrics.iconLg,
                                  color: AppColors.inkSubtle,
                                ),
                                label: 'Offline Maps',
                                subtitle:
                                    'Download maps for areas with no signal',
                                trailing: _OfflineMapsToggle(
                                  enabled: profile.offlineMaps,
                                  onTap: () {
                                    ref
                                        .read(profileNotifierProvider.notifier)
                                        .setOfflineMaps(!profile.offlineMaps);
                                  },
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              SettingsRow(
                                leading: const AppIcon(
                                  LucideIcons.globe,
                                  size: AppMetrics.iconLg,
                                  color: AppColors.inkSubtle,
                                ),
                                label: 'Language',
                                value: 'English',
                                showChevron: true,
                                onTap: () => _showLanguage(context),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              SettingsRow(
                                leading: const AppIcon(
                                  LucideIcons.log_out,
                                  size: AppMetrics.iconLg,
                                  color: AppColors.tagRed,
                                ),
                                label: 'Log Out',
                                foregroundColor: AppColors.tagRed,
                                onTap: () => _logOut(context, ref),
                              ),
                              const Spacer(),
                              const SizedBox(height: AppSpacing.xxl),
                              if (profile.deleteAccountConfirmation)
                                _DeleteAccountConfirmation(
                                  onCancel: () {
                                    ref
                                        .read(profileNotifierProvider.notifier)
                                        .cancelDeleteAccount();
                                  },
                                  onDelete: () => _deleteAccount(context, ref),
                                )
                              else
                                Align(
                                  alignment: Alignment.center,
                                  child: GestureDetector(
                                    key: const ValueKey('delete-account-link'),
                                    onTap: () {
                                      ref
                                          .read(
                                            profileNotifierProvider.notifier,
                                          )
                                          .showDeleteAccountConfirmation();
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.all(AppSpacing.xs),
                                      child: Text(
                                        'Delete account',
                                        style: AppType.caption.copyWith(
                                          color: AppColors.inkTertiary,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar();

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

class _OfflineMapsToggle extends StatelessWidget {
  const _OfflineMapsToggle({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final trackColor = enabled ? AppColors.surface3 : AppColors.surface2;
    final borderColor = enabled ? AppColors.hairlineStrong : AppColors.hairline;
    final thumbColor = enabled ? AppColors.ink : AppColors.inkTertiary;

    return GestureDetector(
      key: const ValueKey('offline-maps-toggle'),
      onTap: onTap,
      child: DecoratedBox(
        key: const ValueKey('offline-maps-toggle-track'),
        decoration: BoxDecoration(
          color: trackColor,
          borderRadius: BorderRadius.circular(AppRadius.toggle),
          border: Border.all(
            color: borderColor,
            width: AppElevation.hairlineWidth,
          ),
        ),
        child: SizedBox(
          width: AppMetrics.buttonHeightLg,
          height: AppSpacing.lg,
          child: Align(
            alignment: enabled ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              key: const ValueKey('offline-maps-toggle-thumb'),
              width: AppMetrics.iconSm,
              height: AppMetrics.iconSm,
              margin: const EdgeInsets.all(AppSpacing.xxs),
              decoration: BoxDecoration(
                color: thumbColor,
                borderRadius: BorderRadius.circular(AppRadius.avatar),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteAccountConfirmation extends StatelessWidget {
  const _DeleteAccountConfirmation({
    required this.onCancel,
    required this.onDelete,
  });

  final VoidCallback onCancel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('delete-account-confirmation'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppMetrics.padRowY),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: AppColors.hairline,
          width: AppElevation.hairlineWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Delete your account and all saved routes? This can't be undone.",
            style: AppType.bodyApp.copyWith(color: AppColors.inkSubtle),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  key: const ValueKey('cancel-delete-account'),
                  onPressed: onCancel,
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.md,
                  fullWidth: true,
                  child: const Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Cancel'),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: AppButton(
                  key: const ValueKey('confirm-delete-account'),
                  onPressed: onDelete,
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.md,
                  fullWidth: true,
                  foregroundColor: AppColors.tagRed,
                  child: const Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Delete account'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
