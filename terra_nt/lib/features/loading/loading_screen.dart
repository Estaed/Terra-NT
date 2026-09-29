import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

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
import '../../shared/map/route_car_backdrop.dart';
import '../../shared/map/terra_map.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/entrance.dart';
import '../onboarding/widgets/progress_drive.dart';

/// The transition from onboarding to the generated itinerary: a request with a
/// way out (`docs/PRD.md` §3.4, deviation V18).
class LoadingScreen extends ConsumerStatefulWidget {
  const LoadingScreen({super.key, this.answers, this.onComplete});

  /// The app icon's route-and-pin artwork, at the centre of the panel.
  static const brandMarkAsset = 'assets/images/brand_mark.png';

  /// The round badge the brand mark sits in. The artwork runs corner to
  /// corner, so with an [AppSpacing.sm] inset this is the smallest circle
  /// that keeps its start dot and pin clear of the badge's edge.

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

  /// The itinerary a successful response resolved to, held only to warm
  /// Result's map tiles before Result itself opens (V1's 7000 ms minimum
  /// display time otherwise runs against a cold map).
  Itinerary? _completedItinerary;

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
    // Warmed as soon as the itinerary is in hand rather than after the
    // minimum delay below, so its tiles have the whole remaining wait to
    // load before Result opens on them.
    if (_isCurrent(attempt)) {
      setState(() => _completedItinerary = itinerary);
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

  Widget _inFlight() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _StatusMessage(index: _messageIndex),
      const SizedBox(height: AppSpacing.lg),
      // No pill around the bar: on the panel it would be a box in a box.
      const SizedBox(
        key: ValueKey('loading-progress-shell'),
        height: AppMetrics.onboardingProgressCarHeight,
        child: Center(child: ProgressDrive.looping()),
      ),
      const SizedBox(height: AppSpacing.lg),
      // Once the route is being saved there is nothing left to cancel; the
      // button keeps its space so the panel, and the map above it, hold still.
      Visibility(
        visible: !_succeeded,
        maintainSize: true,
        maintainAnimation: true,
        maintainState: true,
        child: AppButton(
          key: const ValueKey('loading-cancel'),
          variant: AppButtonVariant.secondary,
          fullWidth: true,
          onPressed: _cancel,
          child: const Text('Cancel'),
        ),
      ),
    ],
  );

  Widget _failed(PlanFailureCopy failure) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        failure.title,
        key: const ValueKey('loading-failure-title'),
        textAlign: TextAlign.center,
        style: AppType.titleApp.copyWith(color: AppColors.ink),
      ),
      const SizedBox(height: AppSpacing.xxs),
      Text(
        failure.body,
        key: const ValueKey('loading-failure-body'),
        textAlign: TextAlign.center,
        style: AppType.bodySm.copyWith(color: AppColors.inkSubtle),
      ),
      const SizedBox(height: AppSpacing.lg),
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
  );

  String _primaryLabel(PlanFailureAction action) => switch (action) {
    PlanFailureAction.tryAgain => 'Try again',
    PlanFailureAction.changeAnswers => 'Change answers',
    PlanFailureAction.signIn => 'Sign in',
  };

  /// Mounts Result's exact map offstage, once the itinerary is known, so its
  /// tiles are already cached by the time Result opens. Sized and fitted like
  /// Result's own map area (`result_screen.dart`): both screens' Scaffolds
  /// fill the full window with no app bar or bottom nav, so Result's
  /// `constraints.maxHeight` and this screen's `MediaQuery` height agree.
  Widget _resultMapWarmup(BuildContext context, Itinerary itinerary) {
    final screen = MediaQuery.sizeOf(context);
    final topInset = MediaQuery.paddingOf(context).top;
    final points = itinerary.stops
        .map((stop) => LatLng(stop.lat, stop.lng))
        .toList(growable: false);
    return Offstage(
      key: const ValueKey('loading-result-map-warmup'),
      child: SizedBox(
        width: screen.width,
        height: screen.height,
        child: TerraMap(
          interactive: false,
          bounds: points.length > 1 ? LatLngBounds.fromPoints(points) : null,
          fitPadding: TerraMap.resultFitPaddingFor(screen.height, topInset),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completedItinerary = _completedItinerary;
    final failure = _failure;
    return PopScope(
      // System Back is Cancel, in flight and on a failure alike (PRD §3.4).
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _cancel();
      },
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        // Expanded rather than sized to its children: once the warm-up
        // mounts it is the only non-positioned child, and an Offstage lays
        // out at zero size, which would take the map and panel down with it.
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (completedItinerary != null)
              _resultMapWarmup(context, completedItinerary),
            // The map above, the request below: the same map-and-panel
            // arrangement Result opens with, so one hands over to the other.
            Positioned.fill(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _LoadingBackdrop(frozen: failure != null)),
                  _LoadingPanel(
                    children: [
                      Entrance(
                        child: _BrandPulse(
                          pulse: failure == null ? _pulse : null,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      // Keyed by state, so a failure (and the retry after it)
                      // enters rather than popping in over the old content.
                      Entrance(
                        key: ValueKey(failure == null),
                        index: 1,
                        child: switch (failure) {
                          null => _inFlight(),
                          final failure => _failed(failure),
                        },
                      ),
                    ],
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

/// The ambient Territory map, the same one behind Welcome and Login, under a
/// scrim that keeps it behind the panel rather than competing with it.
///
/// It is laid out above the panel, not under it, so the whole route (and the
/// car driving it) stays in view. A failure freezes it where it is: nothing
/// ticks while the failure copy is up, and a stopped car reads as a stopped
/// request.
///
/// The shared backdrop fits its route to its own box with no room for the
/// status bar, so it is laid out below the top inset, or Darwin and the car
/// land under the clock. The strip above it is filled by a still map fitted
/// to the same route over the full height, with the inset added to its top
/// padding: both resolve to the same camera, so the tiles run on unbroken to
/// the top edge, as they do behind Result.
class _LoadingBackdrop extends StatelessWidget {
  const _LoadingBackdrop({required this.frozen});

  final bool frozen;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return Stack(
      key: const ValueKey('loading-backdrop'),
      fit: StackFit.expand,
      children: [
        if (topInset > 0)
          TerraMap(
            key: const ValueKey('loading-backdrop-underlay'),
            interactive: false,
            bounds: LatLngBounds.fromPoints(
              RouteCarBackdrop.routeCoordinates
                  .map((point) => LatLng(point.first, point.last))
                  .toList(growable: false),
            ),
            fitPadding:
                TerraMap.backdropFitPadding + EdgeInsets.only(top: topInset),
          ),
        Padding(
          padding: EdgeInsets.only(top: topInset),
          child: TickerMode(
            enabled: !frozen,
            child: const RouteCarBackdrop.ambient(),
          ),
        ),
        IgnorePointer(child: ColoredBox(color: AppColors.welcomeScrim)),
      ],
    );
  }
}

/// The docked panel that holds the request: Result's sheet surface, without
/// the grabber, since nothing here drags.
class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    key: const ValueKey('loading-panel'),
    decoration: BoxDecoration(
      color: AppColors.surface1,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.panel),
      ),
      border: Border.all(
        color: AppColors.hairline,
        width: AppElevation.hairlineWidth,
      ),
    ),
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    ),
  );
}

/// The brand mark on a pin-like badge, with a ring breathing around it on the
/// loading pulse while the request is in flight. With no [pulse] (a failure)
/// the badge sits still and the ring is gone.
///
/// The box reserves the ring's largest extent, so the breathing never pushes
/// or overlaps the text below it.
class _BrandPulse extends StatelessWidget {
  const _BrandPulse({required this.pulse});

  final Animation<double>? pulse;

  @override
  Widget build(BuildContext context) {
    final pulse = this.pulse;
    return SizedBox(
      height: AppMetrics.loadingBrandBadgeSize * AppMotion.loadingPulseMaxScale,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (pulse != null)
            AnimatedBuilder(
              animation: pulse,
              builder: (context, child) {
                final progress = pulse.value;
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
              // The ring the Result pins wear, so the mark reads as a place
              // on the map being worked out.
              child: SizedBox.square(
                key: const ValueKey('loading-halo'),
                dimension: AppMetrics.loadingBrandBadgeSize,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary,
                      width: AppMetrics.mapPinBorderWidth,
                    ),
                  ),
                ),
              ),
            ),
          Container(
            width: AppMetrics.loadingBrandBadgeSize,
            height: AppMetrics.loadingBrandBadgeSize,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.hairlineStrong,
                width: AppElevation.hairlineWidth,
              ),
            ),
            child: Image.asset(
              LoadingScreen.brandMarkAsset,
              key: const ValueKey('loading-brand-mark'),
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

/// The rotating status line, crossfading from one message to the next.
///
/// Every message is given the height of the tallest one at the current width
/// and text scale, so a message that wraps to a second line does not resize
/// the panel, and with it the map, mid-rotation.
class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    // Measured with exactly what the [Text] below renders with.
    final style = DefaultTextStyle.of(context).style
        .merge(AppType.titleApp.copyWith(color: AppColors.ink));
    final textScaler = MediaQuery.textScalerOf(context);
    final textDirection = Directionality.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        var tallest = 0.0;
        for (final message in loadingMessages) {
          final painter = TextPainter(
            text: TextSpan(text: message, style: style),
            textAlign: TextAlign.center,
            textDirection: textDirection,
            textScaler: textScaler,
          )..layout(maxWidth: constraints.maxWidth);
          tallest = math.max(tallest, painter.height);
          painter.dispose();
        }
        return Semantics(
          liveRegion: true,
          child: SizedBox(
            key: const ValueKey('loading-status'),
            height: tallest,
            child: AnimatedSwitcher(
              duration: AppMotion.slow,
              switchInCurve: AppMotion.easeOut,
              switchOutCurve: AppMotion.easeOut,
              child: Text(
                loadingMessages[index],
                key: ValueKey(index),
                textAlign: TextAlign.center,
                style: style,
              ),
            ),
          ),
        );
      },
    );
  }
}
