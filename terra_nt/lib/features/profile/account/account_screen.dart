import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/elevation.dart';
import '../../../core/theme/metrics.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../data/models/auth_failure.dart';
import '../../../data/repositories/notifiers.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../shared/widgets/settings_row.dart';

/// The read-only account details destination from Profile.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  bool? _emailVerified;
  var _verificationLoadFailed = false;
  var _resendPending = false;
  var _resendSent = false;
  String? _resendError;

  @override
  void initState() {
    super.initState();
    _loadEmailVerified();
  }

  Future<void> _loadEmailVerified() async {
    bool verified;
    try {
      verified = await ref.read(authRepositoryProvider).isEmailVerified();
    } on AuthException {
      if (!mounted) return;
      setState(() => _verificationLoadFailed = true);
      return;
    }
    if (!mounted) return;
    setState(() => _emailVerified = verified);
  }

  void _goBack(BuildContext context) {
    Navigator.of(context).pop();
  }

  Future<void> _resendVerification() async {
    setState(() {
      _resendPending = true;
      _resendError = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendEmailVerification();
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _resendPending = false;
        _resendError = error.failure == AuthFailure.network
            ? 'No connection. Check your signal and try again.'
            : 'Something went wrong. Try again.';
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _resendPending = false;
      _resendSent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SettingsRow(
                      leading: const _AccountAvatar(),
                      label: 'NT Explorer',
                      subtitle: email,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _EmailVerificationRow(
                      verified: _emailVerified,
                      loadFailed: _verificationLoadFailed,
                      resendPending: _resendPending,
                      resendSent: _resendSent,
                      resendError: _resendError,
                      onResend: _resendVerification,
                    ),
                  ],
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

/// The verification status row plus, when unverified, the resend action
/// beneath it. Until [verified] resolves the value line reads "Checking..."
/// in a muted colour -- no spinner (`docs/PRD.md` §3.10). Built from the
/// same card chrome `SettingsRow` uses, since the value and the resend
/// action stack vertically rather than sitting in `SettingsRow`'s single
/// line.
class _EmailVerificationRow extends StatelessWidget {
  const _EmailVerificationRow({
    required this.verified,
    required this.loadFailed,
    required this.resendPending,
    required this.resendSent,
    required this.resendError,
    required this.onResend,
  });

  final bool? verified;
  final bool loadFailed;
  final bool resendPending;
  final bool resendSent;
  final String? resendError;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final value = switch (verified) {
      _ when loadFailed => '',
      null => 'Checking…',
      true => 'Verified',
      false => 'Not verified',
    };
    final valueColor = verified == null && !loadFailed
        ? AppColors.inkTertiary
        : AppColors.inkSubtle;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppMetrics.padRowX,
        vertical: AppMetrics.padRowY,
      ),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Email verification', style: AppType.titleApp),
          Text(value, style: AppType.bodyApp.copyWith(color: valueColor)),
          if (verified == false) ...[
            const SizedBox(height: AppSpacing.xs),
            if (resendSent)
              Text(
                'Verification email sent.',
                style: AppType.caption.copyWith(color: AppColors.inkSubtle),
              )
            else ...[
              if (resendError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Text(
                    resendError!,
                    key: const ValueKey('account-resend-error'),
                    style: AppType.caption.copyWith(
                      color: AppColors.inkSubtle,
                    ),
                  ),
                ),
              _ResendVerificationLink(pending: resendPending, onTap: onResend),
            ],
          ],
        ],
      ),
    );
  }
}

class _ResendVerificationLink extends StatelessWidget {
  const _ResendVerificationLink({required this.pending, required this.onTap});

  final bool pending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('account-resend-verification'),
      behavior: HitTestBehavior.opaque,
      onTap: pending ? null : onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppMetrics.minTouchTarget),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Resend email',
            style: AppType.caption.copyWith(color: AppColors.ink),
          ),
        ),
      ),
    );
  }
}
