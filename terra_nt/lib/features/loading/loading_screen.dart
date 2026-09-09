import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routes.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/metrics.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/typography.dart';
import '../../core/util/itinerary_ops.dart';
import '../../data/models/onboarding_answers.dart';
import '../../data/models/saved_route.dart';
import '../../data/repositories/notifiers.dart';
import '../../data/seed/seed_data.dart';

/// The non-interruptible transition from onboarding to the generated itinerary.
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
  Timer? _completionTimer;
  var _messageIndex = 0;
  var _completionStarted = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: AppMotion.loadingPulse,
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);
    _messageTimer = Timer.periodic(AppMotion.loadingMessageInterval, (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        if (_messageIndex < loadingMessages.length - 1) {
          _messageIndex++;
        }
      });
    });
    _completionTimer = Timer(AppMotion.loadingCompletionDelay, _complete);
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _completionTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    if (!mounted || _completionStarted) {
      return;
    }
    _completionStarted = true;
    _messageTimer?.cancel();

    final answers =
        widget.answers ?? ref.read(onboardingNotifierProvider).answers;
    final itinerary = await ref
        .read(itineraryRepositoryProvider)
        .itineraryFor(answers);
    if (!mounted) {
      return;
    }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          ],
        ),
      ),
    );
  }
}
