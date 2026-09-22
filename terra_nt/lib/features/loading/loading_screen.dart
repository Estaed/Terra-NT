import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routes.dart';
import '../../app/screen_routes.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/elevation.dart';
import '../../core/theme/metrics.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/radius.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing.dart';
import '../../core/util/itinerary_ops.dart';
import '../../core/util/plan_failure_copy.dart';
import '../../data/models/itinerary.dart';
import '../../data/models/onboarding_answers.dart';
import '../../data/models/plan_failure.dart';
import '../../data/models/saved_route.dart';
import '../../data/repositories/notifiers.dart';
import '../../data/repositories/remote_itinerary_repository.dart';
import '../../data/seed/seed_data.dart';
import '../../shared/widgets/app_button.dart';
import '../onboarding/widgets/progress_drive.dart';

/// The transition from onboarding to the generated itinerary: a request with a
/// way out (`docs/PRD.md` §3.4, deviation V18).
class LoadingScreen extends ConsumerStatefulWidget {
  const LoadingScreen({super.key, this.answers, this.onComplete});

  /// Overrides the answers held by [onboardingNotifierProvider], which is useful
  /// for a caller that already owns the onboarding session.
  final OnboardingAnswers? answers;

  /// Called after the session flag and generated route have been persisted. When
  /// omitted, the screen replaces itself with the app's Result route.
  final VoidCallback? onComplete;

  @override
  ConsumerState<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends ConsumerState<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;
  Timer? _messageTimer;
  Timer? _minimumTimer;
  Completer<void>? _minimumCompleter;
  var _messageIndex = 0;
  var _attempt = 0;
  var _cancelled = false;
  var _succeeded = false;
  PlanFailureCopy? _failure;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: AppMotion.loadingPulse,
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);
    _startMessages();
    _complete();
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _cancelMinimumDelay();
    _pulseController.dispose();
    super.dispose();
  }

  void _startMessages() {
    _messageTimer?.cancel();
    _messageTimer = Timer.periodic(AppMotion.loadingMessageInterval, (_) {
      if (!mounted) {
        return;
      }
      if (_messageIndex >= loadingMessages.length - 1) {
        _messageTimer?.cancel();
        return;
      }
      setState(() => _messageIndex++);
    });
  }

  /// A response is acted on only while this screen is still waiting for it:
  /// not after Cancel, and not once a newer attempt has been sent.
  bool _isCurrent(int attempt) => mounted && !_cancelled && attempt == _attempt;

  /// V1's minimum display time for a successful response (`docs/PRD.md` §3.4):
  /// a real [Timer] rather than [Future.delayed], so Cancel/dispose/a newer
  /// attempt can cancel it outright instead of leaving it pending.
  Future<void> _startMinimumDelay() {
    final completer = Completer<void>();
    _minimumCompleter = completer;
    _minimumTimer = Timer(AppMotion.loadingCompletionDelay, () {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
    return completer.future;
  }

  void _cancelMinimumDelay() {
    _minimumTimer?.cancel();
    _minimumTimer = null;
    final completer = _minimumCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
    _minimumCompleter = null;
  }

  /// [retry] resends the previous request with the same `requestId` when the
  /// repository is the remote one (contract §1, idempotency); any other
  /// repository is simply asked again.
  Future<void> _complete({bool retry = false}) async {
    final attempt = ++_attempt;
    final answers =
        widget.answers ?? ref.read(onboardingNotifierProvider).answers;
    final repository = ref.read(itineraryRepositoryProvider);
    final request = retry && repository is RemoteItineraryRepository
        ? repository.retry()
        : repository.itineraryFor(answers);
    final minimumDelay = _startMinimumDelay();
    final Itinerary itinerary;
    try {
      itinerary = await request;
    } on PlanException catch (error) {
      _cancelMinimumDelay();
      if (_isCurrent(attempt)) {
        _fail(error.failure);
      }
      return;
    }
    await minimumDelay;
    if (!_isCurrent(attempt)) {
      return;
    }
    _messageTimer?.cancel();
    setState(() => _succeeded = true);
    ref.read(itineraryNotifierProvider.notifier).setItinerary(itinerary);

    await ref.read(sessionNotifierProvider.notifier).setOnboardingDone(true);
    if (!mounted) {
      return;
    }

    await ref
        .read(savedRoutesNotifierProvider.notifier)
        .upsert(
          SavedRoute(
            id: 'generated-trip',
            title: itinerary.title,
            meta: derivedMeta(itinerary.stops.length, answers.days),
            dateLabel: 'Generated just now',
            stops: itinerary.stops,
          ),
        );
    if (!mounted) {
      return;
    }

    final onComplete = widget.onComplete;
    if (onComplete != null) {
      onComplete();
      return;
    }
    Navigator.of(context).pushReplacement(placeholderRoute(AppRoute.result));
  }

  void _fail(PlanFailure failure) {
    _messageTimer?.cancel();
    _pulseController.stop();
    setState(() => _failure = copyForFailure(failure));
  }

  void _tryAgain() {
    setState(() {
      _failure = null;
      _messageIndex = 0;
    });
    _pulseController.repeat(reverse: true);
    _startMessages();
    _complete(retry: true);
  }

  void _stop() {
    _cancelled = true;
    _messageTimer?.cancel();
    _cancelMinimumDelay();
    _pulseController.stop();
  }

  /// Cancel, Back and Change answers: discard whatever comes back and return to
  /// onboarding, whose notifier still holds the answers and the last step.
  /// Loading replaced onboarding on the way in, so there is no route to pop to.
  void _cancel() {
    _stop();
    Navigator.of(context).pushReplacement(rootScreenRoute(AppRoute.onboarding));
  }

  Future<void> _signIn() async {
    _stop();
    await ref.read(sessionNotifierProvider.notifier).signOut();
    if (!mounted) {
      return;
    }
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushReplacement(rootScreenRoute(AppRoute.login));
  }

  void _onPrimary(PlanFailureAction action) {
    switch (action) {
      case PlanFailureAction.tryAgain:
        _tryAgain();
      case PlanFailureAction.changeAnswers:
        _cancel();
      case PlanFailureAction.signIn:
        _signIn();
    }
  }

  List<Widget> _inFlight() => [
    ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: AppMetrics.loadingStatusMinHeight,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppMetrics.loadingStatusSidePadding,
        ),
        child: Text(
          loadingMessages[_messageIndex],
          key: const ValueKey('loading-status'),
          textAlign: TextAlign.center,
          style: AppType.titleApp.copyWith(
            color: AppColors.inkSubtle,
            fontWeight: AppWeights.regular,
          ),
        ),
      ),
    ),
    const SizedBox(height: AppMetrics.loadingContentGap),
    const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppMetrics.loadingStatusSidePadding,
      ),
      child: _LoadingProgressShell(),
    ),
    if (!_succeeded) ...[
      const SizedBox(height: AppSpacing.md),
      TextButton(
        key: const ValueKey('loading-cancel'),
        onPressed: _cancel,
        style: TextButton.styleFrom(
          minimumSize: const Size(
            AppMetrics.minTouchTarget,
            AppMetrics.minTouchTarget,
          ),
        ),
        child: Text(
          'Cancel',
          style: AppType.buttonApp.copyWith(
            color: AppColors.inkSubtle,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.inkSubtle,
          ),
        ),
      ),
    ],
  ];

  List<Widget> _failed(PlanFailureCopy failure) => [
    Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppMetrics.loadingStatusSidePadding,
      ),
      child: Column(
        children: [
          Text(
            failure.title,
            key: const ValueKey('loading-failure-title'),
            textAlign: TextAlign.center,
            style: AppType.titleApp.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            failure.body,
            key: const ValueKey('loading-failure-body'),
            textAlign: TextAlign.center,
            style: AppType.titleApp.copyWith(
              color: AppColors.inkSubtle,
              fontWeight: AppWeights.regular,
            ),
          ),
          const SizedBox(height: AppMetrics.loadingContentGap),
          AppButton(
            key: const ValueKey('loading-failure-primary'),
            fullWidth: true,
            onPressed: () => _onPrimary(failure.primary),
            child: Text(_primaryLabel(failure.primary)),
          ),
          if (failure.showBack) ...[
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              key: const ValueKey('loading-failure-back'),
              variant: AppButtonVariant.secondary,
              fullWidth: true,
              onPressed: _cancel,
              child: const Text('Back'),
            ),
          ],
        ],
      ),
    ),
  ];

  String _primaryLabel(PlanFailureAction action) => switch (action) {
    PlanFailureAction.tryAgain => 'Try again',
    PlanFailureAction.changeAnswers => 'Change answers',
    PlanFailureAction.signIn => 'Sign in',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) {
                final progress = _pulse.value;
                return Opacity(
                  opacity:
                      AppMotion.loadingPulseMaxOpacity -
                      ((AppMotion.loadingPulseMaxOpacity -
                              AppMotion.loadingPulseMinOpacity) *
                          progress),
                  child: Transform.scale(
                    scale:
                        1 + ((AppMotion.loadingPulseMaxScale - 1) * progress),
                    child: child,
                  ),
                );
              },
              child: const SizedBox(
                width: AppMetrics.loadingCircleSize,
                height: AppMetrics.loadingCircleSize,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppMetrics.loadingContentGap),
            ...switch (_failure) {
              null => _inFlight(),
              final failure => _failed(failure),
            },
          ],
        ),
      ),
    );
  }
}

/// Carries the looping drive on the same pill the onboarding progress bar sits
/// in. On the bare canvas the 4px track alone is invisible and the car reads as
/// a speck beside the pulsing disc; the pill gives both an element to belong to.
class _LoadingProgressShell extends StatelessWidget {
  const _LoadingProgressShell();

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('loading-progress-shell'),
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
    // Onboarding's counter text is what makes that pill tall enough for the
    // car; with no counter here the row has to reserve the height itself.
    child: const SizedBox(
      height: AppMetrics.onboardingProgressCarHeight,
      child: Center(child: ProgressDrive.looping()),
    ),
  );
}
