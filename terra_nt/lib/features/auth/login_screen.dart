import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/elevation.dart';
import '../../core/theme/metrics.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../data/repositories/notifiers.dart';
import '../../shared/map/route_car_backdrop.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_input.dart';
import 'welcome_screen.dart';

final _loginScrim = LinearGradient(
  begin: Alignment.bottomCenter,
  end: Alignment.topCenter,
  stops: const [
    0,
    AppMetrics.loginScrimMidpoint,
    AppMetrics.loginScrimOpaquePoint,
    1,
  ],
  colors: [
    AppColors.loginScrimStart,
    AppColors.loginScrimMid,
    AppColors.canvas,
    AppColors.canvas,
  ],
);

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
    if (emailError != null || passwordError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _focusInput(emailError != null ? _emailInputKey : _passwordInputKey);
      });
      return;
    }

    await ref
        .read(sessionNotifierProvider.notifier)
        .signInWithEmail(email, password);
    if (!mounted) return;
    _authenticated();
  }

  Future<void> _continueWithGoogle() async {
    await ref.read(sessionNotifierProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    _authenticated();
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
            const Positioned.fill(child: RouteCarBackdrop.ambient()),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(gradient: _loginScrim),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppMetrics.loginSidePadding,
                  AppMetrics.loginTopPadding,
                  AppMetrics.loginSidePadding,
                  AppMetrics.loginBottomPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Terra NT',
                      style: AppType.displayApp.copyWith(
                        color: AppColors.ink,
                        letterSpacing: AppType.loginHeadlineTracking,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Discover the Northern Territory.',
                      style: AppType.bodyLg.copyWith(color: AppColors.inkMuted),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    KeyedSubtree(
                      key: const ValueKey('login-email-input'),
                      child: AppTextInput(
                        key: _emailInputKey,
                        label: 'Email',
                        placeholder: 'you@email.com',
                        errorText: _submitted ? _emailError : null,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: _onEmailChanged,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    KeyedSubtree(
                      key: const ValueKey('login-password-input'),
                      child: AppTextInput(
                        key: _passwordInputKey,
                        label: 'Password',
                        placeholder: '••••••••',
                        errorText: _submitted ? _passwordError : null,
                        obscureText: true,
                        controller: _passwordController,
                        onChanged: _onPasswordChanged,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      key: const ValueKey('login-submit'),
                      fullWidth: true,
                      onPressed: _submitEmail,
                      child: Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: const Text('Start Exploring'),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const _OrDivider(),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      key: const ValueKey('login-google'),
                      fullWidth: true,
                      variant: AppButtonVariant.secondary,
                      onPressed: _continueWithGoogle,
                      child: Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: const Text('Continue with Google'),
                        ),
                      ),
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
