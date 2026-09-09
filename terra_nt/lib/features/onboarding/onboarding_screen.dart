import 'dart:async';

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
import '../../shared/map/route_car_backdrop.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_icon.dart';
import '../../shared/widgets/app_pill_badge.dart';

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
  static const autoAdvance = AppMotion.onboardingAutoAdvance;
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
    required this.selectAndAdvance,
  });

  final int step;
  final OnboardingAnswers answers;
  final ValueChanged<OnboardingAnswers> updateAnswers;
  final ValueChanged<OnboardingAnswers> selectAndAdvance;
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

  final OnboardingStepBuilder? stepBuilder;
  final VoidCallback? onExitToWelcome;
  final VoidCallback? onComplete;

  @override
  OnboardingScreenState createState() => OnboardingScreenState();
}

class OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  Timer? _advanceTimer;

  int get currentStep => ref.read(onboardingNotifierProvider).currentStep;

  OnboardingAnswers get answers => ref.read(onboardingNotifierProvider).answers;

  bool get hasPendingAutoAdvance => _advanceTimer?.isActive ?? false;

  @override
  void dispose() {
    _cancelAutoAdvance();
    super.dispose();
  }

  void updateAnswers(OnboardingAnswers updatedAnswers) {
    ref.read(onboardingNotifierProvider.notifier).setAnswers(updatedAnswers);
  }

  void selectAndAdvance(OnboardingAnswers updatedAnswers) {
    updateAnswers(updatedAnswers);
    _scheduleAutoAdvance();
  }

  void onNext() {
    _cancelAutoAdvance();
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
    _cancelAutoAdvance();
    final step = currentStep;
    if (step == 0) {
      _exitToWelcome();
      return;
    }
    ref.read(onboardingNotifierProvider.notifier).setStep(step - 1);
  }

  void _scheduleAutoAdvance() {
    _cancelAutoAdvance();
    if (!_autoAdvances(currentStep)) return;
    _advanceTimer = Timer(OnboardingMotion.autoAdvance, onNext);
  }

  void _cancelAutoAdvance() {
    _advanceTimer?.cancel();
    _advanceTimer = null;
  }

  bool _autoAdvances(int step) => switch (step) {
    0 || 2 || 4 || 5 || 6 || 7 || 8 || 9 || 10 || 12 || 13 => true,
    _ => false,
  };

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
    final canContinue = canNext(step, state.answers);
    final stepBody =
        widget.stepBuilder?.call(
          context,
          OnboardingStepData(
            step: step,
            answers: state.answers,
            updateAnswers: updateAnswers,
            selectAndAdvance: selectAndAdvance,
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
        body: Stack(
          fit: StackFit.expand,
          children: [
            RouteCarBackdrop.progress(fraction: mapFraction(step)),
            ColoredBox(color: AppColors.onboardingScrim),
            // The backdrop and scrim stay full-bleed; only the chrome and the
            // card are held clear of the status and navigation bars.
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
                        child: TweenAnimationBuilder<double>(
                          key: ValueKey('onboarding-step-$step'),
                          duration: OnboardingMotion.stepSlide,
                          curve: AppMotion.easeOut,
                          tween: Tween<double>(
                            begin: AppMetrics.onboardingStepSlideOffsetX,
                            end: 0,
                          ),
                          builder: (context, offset, child) =>
                              Transform.translate(
                                offset: Offset(offset, 0),
                                child: child,
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
                                if (step >= 10) ...[
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
        child: Container(
          key: const ValueKey('onboarding-progress-shell'),
          padding: const EdgeInsets.symmetric(
            horizontal: AppMetrics.onboardingProgressPaddingX,
            vertical: AppMetrics.onboardingProgressPaddingY,
          ),
          decoration: BoxDecoration(
            color: AppColors.onboardingChrome,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: AppColors.hairlineStrong,
              width: AppElevation.hairlineWidth,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _OnboardingProgressBar(percent: progressPercent(step)),
              ),
              const SizedBox(width: AppMetrics.onboardingProgressGap),
              Text(
                '${step + 1}/$_stepCount',
                key: const ValueKey('onboarding-counter'),
                style: AppType.captionApp.copyWith(
                  fontFamily: AppFonts.mono,
                  color: AppColors.inkSubtle,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _OnboardingProgressBar extends StatelessWidget {
  const _OnboardingProgressBar({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const ValueKey('onboarding-progress-track'),
    height: AppMetrics.onboardingProgressHeight,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xs),
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: [
            const ColoredBox(color: AppColors.hairlineStrong),
            SizedBox(
              key: const ValueKey('onboarding-progress-fill'),
              width: constraints.maxWidth * (percent / 100),
              child: const ColoredBox(color: AppColors.primary),
            ),
          ],
        ),
      ),
    ),
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
