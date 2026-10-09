import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routes.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/elevation.dart';
import '../../core/theme/map_visuals.dart';
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

  /// Bundled Territory artwork; its route is revealed separately with progress.
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
    if (state.currentStep < lastOnboardingStep) {
      ref
          .read(onboardingNotifierProvider.notifier)
          .setStep(nextOnboardingStep(state.currentStep, state.answers));
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
    ref
        .read(onboardingNotifierProvider.notifier)
        .setStep(previousOnboardingStep(step, answers));
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
    final percent = progressPercent(step, state.answers);
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
        // The bundled terrain stays offline. The route shares the road's step
        // percentage, duration and curve; the opaque question card stays legible.
        body: Stack(
          fit: StackFit.expand,
          children: [
            ColorFiltered(
              colorFilter: _terrainFilter,
              child: const Image(
                key: ValueKey('onboarding-backdrop'),
                image: AssetImage(OnboardingScreen.backdropAsset),
                fit: BoxFit.cover,
                excludeFromSemantics: true,
              ),
            ),
            IgnorePointer(
              child: ExcludeSemantics(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: percent / 100,
                    end: percent / 100,
                  ),
                  duration: reduceMotion
                      ? Duration.zero
                      : OnboardingMotion.stepSlide,
                  curve: AppMotion.easeOut,
                  builder: (context, fraction, _) => CustomPaint(
                    key: const ValueKey('onboarding-route-reveal'),
                    painter: OnboardingRoutePainter(fraction: fraction),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _OnboardingTopBar(
                    step: step,
                    answers: state.answers,
                    onBack: onBack,
                  ),
                  Positioned.fill(
                    top: AppMetrics.onboardingCardTop,
                    bottom: AppMetrics.onboardingCardBottom,
                    left: AppMetrics.onboardingChromeSide,
                    right: AppMetrics.onboardingChromeSide,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        key: const ValueKey('onboarding-step-card'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppMetrics.onboardingCardPaddingX,
                          vertical: AppMetrics.onboardingCardPaddingY,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface1,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(
                            color: AppColors.hairlineStrong,
                            width: AppElevation.hairlineWidth,
                          ),
                          boxShadow: AppElevation.shadowOverlay,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Only the question scrolls and enters. The footer
                            // remains under the thumb even during a transition.
                            Flexible(
                              child: SingleChildScrollView(
                                key: ValueKey('onboarding-scroll-$step'),
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
                                  builder: (context, progress, child) =>
                                      Opacity(
                                        opacity: 1 - progress,
                                        child: Transform.translate(
                                          offset: Offset(
                                            progress *
                                                _stepDirection *
                                                AppMetrics
                                                    .onboardingStepSlideOffsetX,
                                            0,
                                          ),
                                          child: child,
                                        ),
                                      ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (step >= 9 && step <= 13) ...[
                                        const AppPillBadge(
                                          label: 'NT-specific',
                                        ),
                                        const SizedBox(height: AppSpacing.sm),
                                      ],
                                      stepBody,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppButton(
                              key: const ValueKey('onboarding-next'),
                              fullWidth: true,
                              onPressed: canContinue ? onNext : null,
                              child: Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    step == lastOnboardingStep
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Artwork exposure, not a UI colour: neutral terrain is lifted threefold while
// the blue-heavy route baked into the JPEG is suppressed. That prevents a full
// static purple route from competing with the progress reveal. Alpha is intact.
const _terrainFilter = ColorFilter.matrix(<double>[
  0,
  6,
  -3,
  0,
  0,
  0,
  6,
  -3,
  0,
  0,
  0,
  6,
  -3,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
]);

/// Progress along the illustrated route. Coordinates trace the bundled artwork,
/// rather than representing a generated itinerary or introducing new UI tokens.
class OnboardingRoutePainter extends CustomPainter {
  const OnboardingRoutePainter({required this.fraction});

  final double fraction;

  // Source artwork dimensions and landmarks; the same centred cover fit as the
  // Image above keeps the trace aligned at any viewport size or orientation.
  static const _artworkSize = Size(1024, 1536);
  static final _route = Path()
    ..moveTo(397, 242)
    ..cubicTo(390, 286, 444, 315, 463, 351)
    ..cubicTo(475, 376, 449, 401, 453, 452)
    ..cubicTo(455, 508, 521, 535, 504, 592)
    ..cubicTo(498, 605, 499, 610, 500, 617)
    ..cubicTo(449, 674, 487, 720, 501, 770)
    ..cubicTo(507, 788, 520, 804, 514, 820)
    ..cubicTo(511, 882, 483, 934, 485, 999)
    ..cubicTo(487, 1045, 551, 1096, 519, 1143)
    ..cubicTo(508, 1159, 501, 1171, 500, 1182);

  /// The actual path painted, exposed for functional progress tests.
  Path get revealedPath {
    final metric = _route.computeMetrics().single;
    return metric.extractPath(0, metric.length * fraction.clamp(0.0, 1.0));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final fitted = applyBoxFit(BoxFit.cover, _artworkSize, size);
    final source = Alignment.center.inscribe(
      fitted.source,
      Offset.zero & _artworkSize,
    );
    final destination = Alignment.center.inscribe(
      fitted.destination,
      Offset.zero & size,
    );
    final scale = destination.width / source.width;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(
      destination.left - source.left * scale,
      destination.top - source.top * scale,
    );
    canvas.scale(scale);
    final paint = Paint()
      ..color = AppColors.primary.withValues(
        alpha: AppMapVisuals.backdropRouteOpacity,
      );
    final radius = AppMetrics.mapPolylineWidth / (2 * scale);
    final gap = AppMapVisuals.backdropDashPattern.last / scale;
    for (final metric in revealedPath.computeMetrics()) {
      for (var distance = 0.0; distance < metric.length; distance += gap) {
        final point = metric.getTangentForOffset(distance)!.position;
        canvas.drawCircle(point, radius, paint);
      }
      // The leading dot makes short forward/back changes readable too.
      final tip = metric.getTangentForOffset(metric.length)!.position;
      canvas.drawCircle(tip, AppMetrics.mapRouteDotSize / (2 * scale), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant OnboardingRoutePainter oldDelegate) =>
      fraction != oldDelegate.fraction;
}

class _OnboardingTopBar extends StatelessWidget {
  const _OnboardingTopBar({
    required this.step,
    required this.answers,
    required this.onBack,
  });

  final int step;
  final OnboardingAnswers answers;
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
              'Step ${onboardingStepNumber(step, answers)} of '
              '${visibleOnboardingStepCount(answers)}',
              key: const ValueKey('onboarding-counter'),
              style: AppType.captionApp.copyWith(color: AppColors.inkSubtle),
            ),
            const SizedBox(height: AppMetrics.onboardingProgressGap),
            ProgressDrive(percent: progressPercent(step, answers)),
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
