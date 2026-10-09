import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/elevation.dart';
import '../../core/theme/metrics.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../data/models/auth_failure.dart';
import '../../data/repositories/notifiers.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_input.dart';
import '../../shared/widgets/entrance.dart';
import 'auth_backdrop.dart';
import 'create_account_screen.dart';
import 'welcome_screen.dart';

/// The pre-app sign-in screen.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.onAuthenticated});

  /// Allows the app shell owner to supply its route transition.
  final VoidCallback? onAuthenticated;


  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  final _emailInputKey = GlobalKey();
  final _passwordInputKey = GlobalKey();
  String? _emailError;
  String? _passwordError;
  var _submitted = false;
  var _pending = false;
  var _resetPending = false;
  var _resetSent = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onEmailChanged(String value) {
    if (_emailError == null) return;
    setState(() => _emailError = null);
  }

  void _onPasswordChanged(String value) {
    if (_passwordError == null) return;
    setState(() => _passwordError = null);
  }

  bool _isValidEmail(String value) {
    return value.isNotEmpty &&
        !RegExp(r'\s').hasMatch(value) &&
        RegExp(r'^.+@.+\..+$').hasMatch(value);
  }

  void _focusInput(GlobalKey inputKey) {
    final inputContext = inputKey.currentContext;
    if (inputContext == null) return;
    FocusNode? inputFocusNode;
    inputContext.visitChildElements((element) {
      void visit(Element child) {
        final widget = child.widget;
        if (widget is TextField) {
          inputFocusNode = widget.focusNode;
        }
        child.visitChildren(visit);
      }

      element.visitChildren(visit);
    });
    if (inputFocusNode != null) {
      FocusScope.of(context).requestFocus(inputFocusNode);
    }
  }

  Future<void> _submitEmail() async {
    final email = _emailController.text;
    final password = _passwordController.text;
    final emailError = _isValidEmail(email)
        ? null
        : 'Enter a valid email address.';
    final passwordError = password.isEmpty ? 'Enter your password.' : null;

    setState(() {
      _submitted = true;
      _emailError = emailError;
      _passwordError = passwordError;
    });
    // The client-side checks run first; the repository is called only once they
    // pass.
    if (emailError != null || passwordError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _focusInput(emailError != null ? _emailInputKey : _passwordInputKey);
      });
      return;
    }

    setState(() => _pending = true);
    try {
      await ref
          .read(sessionNotifierProvider.notifier)
          .signInWithEmail(email, password);
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _pending = false;
        _showFailure(error.failure);
      });
      return;
    }
    if (!mounted) return;
    setState(() => _pending = false);
    _authenticated();
  }

  Future<void> _requestPasswordReset() async {
    final email = _emailController.text;
    if (!_isValidEmail(email)) {
      setState(() {
        _submitted = true;
        _emailError = 'Enter your email to reset your password.';
      });
      return;
    }

    setState(() => _resetPending = true);
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _resetPending = false;
        _submitted = true;
        _passwordError = error.failure == AuthFailure.network
            ? 'No connection. Check your signal and try again.'
            : 'Something went wrong. Try again.';
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _resetPending = false;
      _resetSent = true;
    });
  }

  Future<void> _continueWithGoogle() async {
    setState(() {
      _submitted = true;
      _emailError = null;
      _passwordError = null;
      _pending = true;
    });
    try {
      await ref.read(sessionNotifierProvider.notifier).signInWithGoogle();
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _pending = false;
        // Every Google failure reads the same on screen; a dismissed sheet is
        // not a failure and shows nothing.
        if (error.failure != AuthFailure.cancelled) {
          _passwordError = "Google sign-in didn't work. Try again.";
        }
      });
      return;
    }
    if (!mounted) return;
    setState(() => _pending = false);
    _authenticated();
  }

  /// Form-level failures land in the error slot of the last field on the form --
  /// the password -- because that is the field the eye is on when the button is
  /// pressed. Called inside a `setState`.
  void _showFailure(AuthFailure failure) {
    switch (failure) {
      case AuthFailure.cancelled:
        break;
      case AuthFailure.invalidEmail:
        _emailError = 'Enter a valid email address.';
      case AuthFailure.invalidCredential:
        _passwordError = 'Email or password is incorrect.';
      case AuthFailure.network:
        _passwordError = 'No connection. Check your signal and try again.';
      case AuthFailure.tooManyRequests:
        _passwordError = 'Too many attempts. Try again later.';
      case AuthFailure.emailAlreadyInUse:
      case AuthFailure.weakPassword:
      case AuthFailure.requiresRecentLogin:
      case AuthFailure.unknown:
        _passwordError = 'Something went wrong. Try again.';
    }
  }

  void _authenticated() {
    final callback = widget.onAuthenticated;
    if (callback != null) {
      callback();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'welcome'),
        builder: (_) => const WelcomeScreen(),
      ),
    );
  }

  void _openCreateAccount() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'create-account'),
        builder: (_) => CreateAccountScreen(onAuthenticated: widget.onAuthenticated),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // While the soft keyboard covers the screen, system Back dismisses it
    // instead of leaving Login.
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    return PopScope(
      canPop: !keyboardVisible,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: const ValueKey('screen-login'),
        backgroundColor: AppColors.canvas,
        body: Stack(
          // Without this the stack takes its height from the scroll view,
          // which shrink-wraps its content, and the full-bleed backdrop stops
          // partway down a tall phone.
          fit: StackFit.expand,
          children: [
            const AuthBackdrop(),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, viewportConstraints) =>
                    SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: viewportConstraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Padding(
                            // No top padding of its own: the header's
                            // padding is the space under the status bar.
                            padding: const EdgeInsets.only(
                              left: AppMetrics.loginSidePadding,
                              right: AppMetrics.loginSidePadding,
                              bottom: AppMetrics.loginBottomPadding,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // The header centres in whatever height the
                                // form leaves; its padding keeps it off the
                                // form when the keyboard leaves none.
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.lg,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Entrance(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              AuthBrandMark(
                                                markKey: const ValueKey(
                                                  'login-brand-mark',
                                                ),
                                                size:
                                                    AppMetrics.authBrandMarkSize,
                                                collapsed: keyboardVisible,
                                              ),
                                              Text(
                                                'Terra NT',
                                                style: AppType.displayApp
                                                    .copyWith(
                                                      color: AppColors.ink,
                                                      letterSpacing: AppType
                                                          .loginHeadlineTracking,
                                                    ),
                                              ),
                                              const SizedBox(
                                                height: AppSpacing.xs,
                                              ),
                                              Text(
                                                'Discover the Northern Territory.',
                                                style: AppType.bodyLg.copyWith(
                                                  color: AppColors.inkMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                KeyedSubtree(
                                  key: const ValueKey('login-email-input'),
                                  child: Entrance(
                                    index: 1,
                                    child: AppTextInput(
                                      key: _emailInputKey,
                                      label: 'Email',
                                      placeholder: 'you@email.com',
                                      errorText: _submitted
                                          ? _emailError
                                          : null,
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      onChanged: _onEmailChanged,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                KeyedSubtree(
                                  key: const ValueKey('login-password-input'),
                                  child: Entrance(
                                    index: 2,
                                    child: AppTextInput(
                                      key: _passwordInputKey,
                                      label: 'Password',
                                      placeholder: '••••••••',
                                      errorText: _submitted
                                          ? _passwordError
                                          : null,
                                      obscureText: true,
                                      controller: _passwordController,
                                      onChanged: _onPasswordChanged,
                                    ),
                                  ),
                                ),
                                // Wider than the gap between the fields: the
                                // inputs end here and the actions begin.
                                const SizedBox(height: AppSpacing.lg),
                                Entrance(
                                  index: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      AppButton(
                                        key: const ValueKey('login-submit'),
                                        fullWidth: true,
                                        onPressed: _pending
                                            ? null
                                            : _submitEmail,
                                        child: Expanded(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: const Text(
                                              'Start Exploring',
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      const _OrDivider(),
                                      const SizedBox(height: AppSpacing.md),
                                      AppButton(
                                        key: const ValueKey('login-google'),
                                        fullWidth: true,
                                        variant: AppButtonVariant.inverse,
                                        leading: Image.asset(
                                          'assets/images/google_g.png',
                                          width: AppMetrics.iconMd,
                                          height: AppMetrics.iconMd,
                                        ),
                                        onPressed: _pending
                                            ? null
                                            : _continueWithGoogle,
                                        child: Expanded(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: const Text(
                                              'Continue with Google',
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Each link carries a 48px target, which
                                // already spaces the pair: one quiet footer,
                                // not two more actions.
                                const SizedBox(height: AppSpacing.xs),
                                Entrance(
                                  index: 4,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _AuthLink(
                                        key: const ValueKey('login-sign-up'),
                                        leading: "Don't have an account? ",
                                        trailing: 'Sign up',
                                        onTap: _openCreateAccount,
                                      ),
                                      if (_resetSent)
                                        // Holds the link's height, so the
                                        // form does not jump when it swaps.
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            minHeight:
                                                AppMetrics.minTouchTarget,
                                          ),
                                          child: Center(
                                            child: Text(
                                              'Check your email for a reset link.',
                                              key: const ValueKey(
                                                'login-reset-sent',
                                              ),
                                              style: AppType.caption.copyWith(
                                                color: AppColors.inkSubtle,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        )
                                      else
                                        _AuthLink(
                                          key: const ValueKey(
                                            'login-forgot-password',
                                          ),
                                          leading: 'Forgot your password? ',
                                          trailing: 'Reset it',
                                          onTap: _resetPending
                                              ? null
                                              : _requestPasswordReset,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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

/// The brand mark over the Login and Create account titles, with the gap under
/// it (`docs/PRD.md` D18).
///
/// While the keyboard is up it folds away, fading as it goes: typing needs the
/// room more than the brand does, and the header stays one block. The fold is
/// an [AnimatedAlign] height factor, which the screens' `IntrinsicHeight`
/// measures as it animates, so nothing overflows mid-fold.
class AuthBrandMark extends StatelessWidget {
  const AuthBrandMark({
    super.key,
    required this.markKey,
    required this.size,
    required this.collapsed,
  });

  /// Carried by the image itself, so a finder lands on the [Image].
  final Key markKey;
  final double size;
  final bool collapsed;

  @override
  Widget build(BuildContext context) => ClipRect(
    child: AnimatedAlign(
      alignment: Alignment.bottomLeft,
      heightFactor: collapsed ? 0 : 1,
      duration: AppMotion.slow,
      curve: AppMotion.easeStandard,
      child: AnimatedOpacity(
        opacity: collapsed ? 0 : 1,
        duration: AppMotion.slow,
        curve: AppMotion.easeStandard,
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Image.asset(
            'assets/images/brand_mark.png',
            key: markKey,
            height: size,
            excludeFromSemantics: true,
          ),
        ),
      ),
    ),
  );
}

class _AuthLink extends StatelessWidget {
  const _AuthLink({
    super.key,
    required this.leading,
    required this.trailing,
    required this.onTap,
  });

  final String leading;
  final String trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Center(
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: AppMetrics.minTouchTarget,
          minHeight: AppMetrics.minTouchTarget,
        ),
        child: Center(
          child: Text.rich(
            TextSpan(
              style: AppType.caption.copyWith(color: AppColors.inkSubtle),
              children: [
                TextSpan(text: leading),
                TextSpan(
                  text: trailing,
                  style: AppType.caption.copyWith(
                    color: AppColors.ink,
                    fontWeight: AppWeights.medium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(
        child: Divider(
          color: AppColors.hairline,
          height: AppElevation.hairlineWidth,
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Text(
          'or',
          style: AppType.caption.copyWith(color: AppColors.inkSubtle),
        ),
      ),
      const Expanded(
        child: Divider(
          color: AppColors.hairline,
          height: AppElevation.hairlineWidth,
        ),
      ),
    ],
  );
}
