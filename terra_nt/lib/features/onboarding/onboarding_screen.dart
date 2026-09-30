import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routes.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/elevation.dart';
import '../../core/theme/metrics.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/radius.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/util/onboarding_rules.dart';
import '../../data/models/onboarding_answers.dart';
import '../../data/repositories/notifiers.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_icon.dart';
import '../../shared/widgets/app_pill_badge.dart';
import 'widgets/progress_drive.dart';

const _stepCount = 15;
const _lastStep = _stepCount - 1;

/// The back control paints at [AppMetrics.onboardingBackButtonSize] but must
/// offer [AppMetrics.minTouchTarget]. Growing the target outwards by half the
/// difference keeps the painted circle exactly where the prototype puts it.
const _backTargetInset =
    (AppMetrics.minTouchTarget - AppMetrics.onboardingBackButtonSize) / 2;

/// The timings measured from the onboarding prototype.
class OnboardingMotion {
  OnboardingMotion._();

  static const stepSlide = AppMotion.onboardingStepSlide;
}

/// Data and callbacks supplied to a concrete step body.
///
/// Task-11 owns the five concrete question widgets. Keeping their contract here
/// lets that task fill the shell without changing the step machine.
class OnboardingStepData {
  const OnboardingStepData({
    required this.step,
    required this.answers,
    required this.updateAnswers,
  });

  final int step;
  final OnboardingAnswers answers;
  final ValueChanged<OnboardingAnswers> updateAnswers;
}

/// Builds the question area for one onboarding step.
typedef OnboardingStepBuilder = Widget Function(
  BuildContext context,
  OnboardingStepData data,
);

/// Fifteen-step onboarding shell with progress chrome and advance behaviour.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({
    super.key,
    this.stepBuilder,
    this.onExitToWelcome,
    this.onComplete,
  });

  /// A still, very dark illustration of the Territory behind the questions (D18).
  static const backdropAsset = 'assets/images/onboarding_backdrop.jpg';

  final OnboardingStepBuilder? stepBuilder;
  final VoidCallback? onExitToWelcome;
  final VoidCallback? onComplete;

  @override
  OnboardingScreenState createState() => OnboardingScreenState();
}

class OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _paintedStep = 0;
  double _stepDirection = 1;

  int get currentStep => ref.read(onboardingNotifierProvider).currentStep;

  OnboardingAnswers get answers => ref.read(onboardingNotifierProvider).answers;

  void updateAnswers(OnboardingAnswers updatedAnswers) {
    ref.read(onboardingNotifierProvider.notifier).setAnswers(updatedAnswers);
  }

  void onNext() {
    final state = ref.read(onboardingNotifierProvider);
    if (!canNext(state.currentStep, state.answers)) return;
    if (state.currentStep < _lastStep) {
      ref
          .read(onboardingNotifierProvider.notifier)
          .setStep(state.currentStep + 1);
      return;
    }
    _complete();
  }

  void onBack() {
    final step = currentStep;
    if (step == 0) {
      _exitToWelcome();
      return;
    }
    ref.read(onboardingNotifierProvider.notifier).setStep(step - 1);
  }

  void _exitToWelcome() {
    final callback = widget.onExitToWelcome;
    if (callback != null) {
      callback();
      return;
    }
    Navigator.of(context).pushReplacement(placeholderRoute(AppRoute.welcome));
  }

  void _complete() {
    final callback = widget.onComplete;
    if (callback != null) {
      callback();
      return;
    }
    Navigator.of(context).pushReplacement(placeholderRoute(AppRoute.loading));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingNotifierProvider);
    final step = state.currentStep;
    if (step != _paintedStep) {
      _stepDirection = step > _paintedStep ? 1 : -1;
      _paintedStep = step;
    }
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final canContinue = canNext(step, state.answers);
    final stepBody =
        widget.stepBuilder?.call(
          context,
          OnboardingStepData(
            step: step,
            answers: state.answers,
            updateAnswers: updateAnswers,
          ),
        ) ??
        _OnboardingStepStub(step: step);

    // System Back is the same gesture as the on-screen back control: it steps
    // back through the questions and, at step 0, leaves for Welcome rather than
    // the app (`docs/PRD.md` §7, deviation V7).
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        onBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        // The live map left onboarding for the progress track (deviation V13);
        // D18 puts back a still, bundled illustration of the Territory, so the
        // questions sit on the trip without a second animated map or a tile
        // fetch. The chrome and the card still hold clear of the system bars.
        body: Stack(
          fit: StackFit.expand,
          children: [
            const Image(
              key: ValueKey('onboarding-backdrop'),
              image: AssetImage(OnboardingScreen.backdropAsset),
              fit: BoxFit.cover,
              excludeFromSemantics: true,
            ),
            SafeArea(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _OnboardingTopBar(step: step, onBack: onBack),
                  Positioned.fill(
                    top: AppMetrics.onboardingCardTop,
                    bottom: AppMetrics.onboardingCardBottom,
                    left: AppMetrics.onboardingChromeSide,
                    right: AppMetrics.onboardingChromeSide,
                    child: Center(
                      child: SingleChildScrollView(
                        child: AnimatedSize(
                          duration: reduceMotion
                              ? Duration.zero
                              : OnboardingMotion.stepSlide,
                          curve: AppMotion.easeEmphasized,
                          child: TweenAnimationBuilder<double>(
                            key: ValueKey('onboarding-step-$step'),
                            duration: reduceMotion
                                ? Duration.zero
                                : OnboardingMotion.stepSlide,
                            curve: AppMotion.easeOut,
                            tween: Tween<double>(
                              begin: reduceMotion ? 0 : 1,
                              end: 0,
                            ),
                            builder: (context, progress, child) => Opacity(
                              opacity: 1 - progress,
                              child: Transform.translate(
                                offset: Offset(
                                  progress *
                                      _stepDirection *
                                      AppMetrics.onboardingStepSlideOffsetX,
                                  0,
                                ),
                                child: child,
                              ),
                            ),
                            child: Container(
                              key: const ValueKey('onboarding-step-card'),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppMetrics.onboardingCardPaddingX,
                                vertical: AppMetrics.onboardingCardPaddingY,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface1,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.card,
                                ),
                                border: Border.all(
                                  color: AppColors.hairlineStrong,
                                  width: AppElevation.hairlineWidth,
                                ),
                                boxShadow: AppElevation.shadowOverlay,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (step >= 9 && step <= 13) ...[
                                    const AppPillBadge(label: 'NT-specific'),
                                    const SizedBox(height: AppSpacing.sm),
                                  ],
                                  stepBody,
                                  const SizedBox(height: AppSpacing.md),
                                  AppButton(
                                    key: const ValueKey('onboarding-next'),
                                    fullWidth: true,
                                    onPressed: canContinue ? onNext : null,
                                    child: Expanded(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          step == _lastStep
                                              ? 'Generate My Route'
                                              : 'Next',
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingTopBar extends StatelessWidget {
  const _OnboardingTopBar({required this.step, required this.onBack});

  final int step;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned(
        top: AppMetrics.onboardingChromeTop - _backTargetInset,
        left: AppMetrics.onboardingChromeSide - _backTargetInset,
        child: GestureDetector(
          key: const ValueKey('onboarding-back'),
          onTap: onBack,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: AppMetrics.minTouchTarget,
            height: AppMetrics.minTouchTarget,
            child: Center(
              child: Container(
                key: const ValueKey('onboarding-back-circle'),
                width: AppMetrics.onboardingBackButtonSize,
                height: AppMetrics.onboardingBackButtonSize,
                decoration: BoxDecoration(
                  color: AppColors.onboardingChrome,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.hairlineStrong,
                    width: AppElevation.hairlineWidth,
                  ),
                ),
                alignment: Alignment.center,
                child: const AppIcon(LucideIcons.arrow_left),
              ),
            ),
          ),
        ),
      ),
      Positioned(
        top: AppMetrics.onboardingChromeTop,
        left: AppMetrics.onboardingProgressLeft,
        right: AppMetrics.onboardingChromeSide,
        // D18: no boxed pill — the step count reads as words above an open road.
        child: Column(
          key: const ValueKey('onboarding-progress-shell'),
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Step ${step + 1} of $_stepCount',
              key: const ValueKey('onboarding-counter'),
              style: AppType.captionApp.copyWith(color: AppColors.inkSubtle),
            ),
            const SizedBox(height: AppMetrics.onboardingProgressGap),
            ProgressDrive(percent: progressPercent(step)),
          ],
        ),
      ),
    ],
  );
}

class _OnboardingStepStub extends StatelessWidget {
  const _OnboardingStepStub({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) => Text(
    'Onboarding step ${step + 1}',
    key: const ValueKey('onboarding-step-stub'),
    style: AppType.cardTitle.copyWith(color: AppColors.ink),
  );
}
