import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/metrics.dart';
import '../../core/theme/typography.dart';
import '../../data/repositories/notifiers.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_input.dart';
import 'auth_backdrop.dart';
import 'welcome_screen.dart';

/// The phase-one account creation screen. It validates credentials locally and
/// creates only the in-memory mocked-auth session.
class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key, this.onAuthenticated});

  final VoidCallback? onAuthenticated;

  @override
  ConsumerState<CreateAccountScreen> createState() =>
      _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmationController;
  final _emailInputKey = GlobalKey();
  final _passwordInputKey = GlobalKey();
  final _confirmationInputKey = GlobalKey();
  String? _emailError;
  String? _passwordError;
  String? _confirmationError;
  var _submitted = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmationController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String value) =>
      value.isNotEmpty &&
      !RegExp(r'\s').hasMatch(value) &&
      RegExp(r'^.+@.+\..+$').hasMatch(value);

  void _onEmailChanged(String value) {
    if (_emailError == null) return;
    setState(() => _emailError = null);
  }

  void _onPasswordChanged(String value) {
    if (_passwordError == null) return;
    setState(() => _passwordError = null);
  }

  void _onConfirmationChanged(String value) {
    if (_confirmationError == null) return;
    setState(() => _confirmationError = null);
  }

  void _focusInput(GlobalKey inputKey) {
    final inputContext = inputKey.currentContext;
    if (inputContext == null) return;
    FocusNode? inputFocusNode;
    inputContext.visitChildElements((element) {
      void visit(Element child) {
        final widget = child.widget;
        if (widget is TextField) inputFocusNode = widget.focusNode;
        child.visitChildren(visit);
      }

      element.visitChildren(visit);
    });
    if (inputFocusNode != null) {
      FocusScope.of(context).requestFocus(inputFocusNode);
    }
  }

  Future<void> _submit() async {
    final email = _emailController.text;
    final password = _passwordController.text;
    final confirmation = _confirmationController.text;
    final emailError = _isValidEmail(email)
        ? null
        : 'Enter a valid email address.';
    final passwordError = password.isEmpty ? 'Enter a password.' : null;
    final confirmationError = confirmation.isEmpty
        ? 'Confirm your password.'
        : confirmation != password
        ? 'Passwords do not match.'
        : null;

    setState(() {
      _submitted = true;
      _emailError = emailError;
      _passwordError = passwordError;
      _confirmationError = confirmationError;
    });
    if (emailError != null ||
        passwordError != null ||
        confirmationError != null) {
      final firstInvalid = emailError != null
          ? _emailInputKey
          : passwordError != null
          ? _passwordInputKey
          : _confirmationInputKey;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusInput(firstInvalid);
      });
      return;
    }

    await ref
        .read(sessionNotifierProvider.notifier)
        .createAccount(email, password);
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
    return Scaffold(
      key: const ValueKey('screen-create-account'),
      backgroundColor: AppColors.canvas,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AuthBackdrop(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, viewportConstraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: viewportConstraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppMetrics.loginSidePadding,
                        AppMetrics.loginTopPadding,
                        AppMetrics.loginSidePadding,
                        AppMetrics.loginBottomPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Create account',
                                    maxLines: 1,
                                    style: AppType.displayApp.copyWith(
                                      color: AppColors.ink,
                                      letterSpacing:
                                          AppType.loginHeadlineTracking,
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: AppMetrics.loginHeaderGap,
                                ),
                                Text(
                                  'Start exploring the Northern Territory.',
                                  style: AppType.bodyLg.copyWith(
                                    color: AppColors.inkMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          KeyedSubtree(
                            key: const ValueKey('create-account-email-input'),
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
                          const SizedBox(height: AppMetrics.loginFormGap),
                          KeyedSubtree(
                            key: const ValueKey(
                              'create-account-password-input',
                            ),
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
                          const SizedBox(height: AppMetrics.loginFormGap),
                          KeyedSubtree(
                            key: const ValueKey(
                              'create-account-confirmation-input',
                            ),
                            child: AppTextInput(
                              key: _confirmationInputKey,
                              label: 'Confirm password',
                              placeholder: '••••••••',
                              errorText: _submitted ? _confirmationError : null,
                              obscureText: true,
                              controller: _confirmationController,
                              onChanged: _onConfirmationChanged,
                            ),
                          ),
                          const SizedBox(height: AppMetrics.loginFormGap),
                          AppButton(
                            key: const ValueKey('create-account-submit'),
                            fullWidth: true,
                            onPressed: _submit,
                            child: Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: const Text('Create Account'),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppMetrics.loginFormGap),
                          _SignInLink(onTap: () => Navigator.of(context).pop()),
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
    );
  }
}

class _SignInLink extends StatelessWidget {
  const _SignInLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Center(
    child: GestureDetector(
      key: const ValueKey('create-account-sign-in'),
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
                const TextSpan(text: 'Already have an account? '),
                TextSpan(
                  text: 'Sign in',
                  style: AppType.caption.copyWith(color: AppColors.ink),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
