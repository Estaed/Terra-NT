import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routes.dart';
import '../../app/screen_routes.dart';
import '../../app/tab_shell.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/elevation.dart';
import '../../core/theme/metrics.dart';
import '../../core/theme/radius.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../data/models/auth_failure.dart';
import '../../data/repositories/notifiers.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_icon.dart';
import '../../shared/widgets/settings_row.dart';

/// The Profile tab with account actions and app information.
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

  /// A refused delete leaves the confirmation open with its reason; only a
  /// delete that returned closes it and goes back to Login.
  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final profile = ref.read(profileNotifierProvider.notifier);
    profile.startDeleteAccount();
    try {
      await ref.read(sessionNotifierProvider.notifier).deleteAccount();
    } on AuthException catch (error) {
      profile.failDeleteAccount(_deleteAccountFailureCopy(error.failure));
      return;
    }
    profile.cancelDeleteAccount();
    if (!context.mounted) return;
    _showLogin(context);
  }

  String _deleteAccountFailureCopy(AuthFailure failure) {
    switch (failure) {
      case AuthFailure.requiresRecentLogin:
        return 'Sign in again, then delete your account.';
      case AuthFailure.network:
        return 'No connection. Check your signal and try again.';
      case AuthFailure.invalidCredential:
      case AuthFailure.emailAlreadyInUse:
      case AuthFailure.weakPassword:
      case AuthFailure.invalidEmail:
      case AuthFailure.tooManyRequests:
      case AuthFailure.cancelled:
      case AuthFailure.unknown:
        return 'Something went wrong. Try again.';
    }
  }

  void _showLogin(BuildContext context) {
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushReplacement(rootScreenRoute(AppRoute.login));
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
                              const SettingsRow(
                                key: ValueKey('profile-crash-reports'),
                                leading: AppIcon(
                                  LucideIcons.shield_check,
                                  size: AppMetrics.iconLg,
                                  color: AppColors.inkSubtle,
                                ),
                                label: 'Crash reports',
                                subtitle: 'Sent anonymously to fix bugs.',
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              const SettingsRow(
                                key: ValueKey('profile-offline-maps'),
                                leading: AppIcon(
                                  LucideIcons.map,
                                  size: AppMetrics.iconLg,
                                  color: AppColors.inkSubtle,
                                ),
                                label: 'Offline maps',
                                subtitle:
                                    'Map areas you have opened stay available offline for up to 30 days.',
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
                                  errorText: profile.deleteAccountError,
                                  onCancel: () {
                                    ref
                                        .read(profileNotifierProvider.notifier)
                                        .cancelDeleteAccount();
                                  },
                                  onDelete: profile.deleteAccountPending
                                      ? null
                                      : () => _deleteAccount(context, ref),
                                )
                              else
                                Align(
                                  alignment: Alignment.center,
                                  child: GestureDetector(
                                    key: const ValueKey('delete-account-link'),
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      ref
                                          .read(
                                            profileNotifierProvider.notifier,
                                          )
                                          .showDeleteAccountConfirmation();
                                    },
                                    // Caption-sized link, 48px target.
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        minWidth: AppMetrics.minTouchTarget,
                                        minHeight: AppMetrics.minTouchTarget,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: Padding(
                                              padding: const EdgeInsets.all(
                                                AppSpacing.xs,
                                              ),
                                              child: Text(
                                                'Delete account',
                                                style: AppType.caption.copyWith(
                                                  color: AppColors.inkTertiary,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                        ],
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

class _DeleteAccountConfirmation extends StatelessWidget {
  const _DeleteAccountConfirmation({
    required this.errorText,
    required this.onCancel,
    required this.onDelete,
  });

  /// Why the last delete was refused, or null. Styled like an input's error.
  final String? errorText;
  final VoidCallback onCancel;

  /// Null while a delete is in flight, which renders the button disabled.
  final VoidCallback? onDelete;

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
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxs),
              child: Text(
                errorText!,
                key: const ValueKey('delete-account-error'),
                style: AppType.caption.copyWith(color: AppColors.tagRed),
              ),
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
