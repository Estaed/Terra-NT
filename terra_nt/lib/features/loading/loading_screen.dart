import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
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
import '../../core/util/trip_summary.dart';
import '../../data/models/itinerary.dart';
import '../../data/models/onboarding_answers.dart';
import '../../data/models/plan_failure.dart';
import '../../data/models/saved_route.dart';
import '../../data/repositories/itinerary_repository.dart';
import '../../data/repositories/notifiers.dart';
import '../../data/repositories/remote_itinerary_repository.dart';
import '../../shared/map/route_car_backdrop.dart';
import '../../shared/map/terra_map.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_icon.dart';
import '../../shared/widgets/entrance.dart';
import '../itinerary/result_screen.dart';

/// The transition from onboarding to the generated itinerary: a request with a
/// way out (`docs/PRD.md` §3.4, deviation V18).
class LoadingScreen extends ConsumerStatefulWidget {
  const LoadingScreen({super.key, this.answers, this.onComplete});

  static const noSignalAsset = 'assets/images/scenes/no_signal.jpg';

  /// Overrides the answers held by [onboardingNotifierProvider], which is useful
  /// for a caller that already owns the onboarding session.
  final OnboardingAnswers? answers;

  /// Called after the session flag and generated route have been persisted. When
  /// omitted, the screen replaces itself with the app's Result route.
  final VoidCallback? onComplete;

  @override
  ConsumerState<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends ConsumerState<LoadingScreen> {
  Timer? _messageTimer;
  Timer? _minimumTimer;
  Completer<void>? _minimumCompleter;
  var _messageIndex = 0;
  var _attempt = 0;
  var _cancelled = false;
  var _succeeded = false;
  PlanFailureCopy? _failure;
  late final OnboardingAnswers _answers;
  late final Itinerary _offlineItinerary;
  late final List<List<double>> _backdropCoordinates;
  late final List<String> _messages;

  /// The itinerary a successful response resolved to, held only to warm
  /// Result's map tiles before Result itself opens (V1's 7000 ms minimum
  /// display time otherwise runs against a cold map).
  Itinerary? _completedItinerary;

  @override
  void initState() {
    super.initState();
    _answers = widget.answers ?? ref.read(onboardingNotifierProvider).answers;
    _offlineItinerary = ref
        .read(itineraryRepositoryProvider)
        .offlineItineraryFor(_answers);
    _backdropCoordinates = [
      for (final stop in _offlineItinerary.stops) [stop.lat, stop.lng],
    ];
    _messages = ref.read(loadingMessagesProvider);
    _startMessages();
    _complete();
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _cancelMinimumDelay();
    super.dispose();
  }

  void _startMessages() {
    _messageTimer?.cancel();
    _messageTimer = Timer.periodic(AppMotion.loadingMessageInterval, (_) {
      if (!mounted) {
        return;
      }
      if (_messageIndex >= _messages.length - 1) {
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
    final answers = _answers;
    final repository = ref.read(itineraryRepositoryProvider);
    final request = retry && repository is RemoteItineraryRepository
        ? repository.retry()
        : repository.itineraryFor(answers);
    final minimumDelay = _startMinimumDelay();
    final Itinerary itinerary;
    try {
      final planned = await request;
      itinerary = Itinerary(
        title: planned.title,
        stops: planned.stops,
        days: answers.days,
      );
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
    await _saveAndOpen(itinerary);
  }

  Future<void> _saveAndOpen(Itinerary itinerary, {bool offline = false}) async {
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
            meta: itineraryMeta(itinerary, itinerary.stops.length),
            dateLabel: offline ? 'Offline suggestion' : 'Your latest plan',
            stops: itinerary.stops,
            days: itinerary.days,
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
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: AppRoute.result.name),
        builder: (_) => const ResultScreen(),
      ),
    );
  }

  void _useOffline() {
    if (_succeeded || _failure == null) return;
    ++_attempt;
    _cancelMinimumDelay();
    _saveAndOpen(_offlineItinerary, offline: true);
  }

  void _fail(PlanFailure failure) {
    _messageTimer?.cancel();
    setState(() => _failure = copyForFailure(failure));
  }

  void _tryAgain() {
    setState(() {
      _failure = null;
      _messageIndex = 0;
    });
    _startMessages();
    _complete(retry: true);
  }

  void _stop() {
    _cancelled = true;
    _messageTimer?.cancel();
    _cancelMinimumDelay();
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
      // D18: say whose trip this is while the wait runs.
      for (final (index, line) in tripSummaryLines(_answers).indexed)
        Text(
          line,
          key: ValueKey('loading-trip-summary-$index'),
          textAlign: TextAlign.center,
          style: AppType.captionApp.copyWith(color: AppColors.inkSubtle),
        ),
      const SizedBox(height: AppSpacing.xs),
      _StatusMessage(index: _messageIndex, messages: _messages),
      const SizedBox(height: AppSpacing.lg),
      // One quiet progress cue; the journey's car stays on the map above.
      const LinearProgressIndicator(
        key: ValueKey('loading-progress-shell'),
        minHeight: AppMetrics.progressRoadHeight,
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
        color: AppColors.primary,
        backgroundColor: AppColors.surface3,
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
          child: _buttonLabel('Cancel'),
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
        onPressed: _succeeded ? null : () => _onPrimary(failure.primary),
        child: _buttonLabel(_primaryLabel(failure.primary)),
      ),
      if (failure.showOffline) ...[
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          key: const ValueKey('loading-failure-offline'),
          variant: AppButtonVariant.secondary,
          fullWidth: true,
          onPressed: _succeeded ? null : _useOffline,
          child: _buttonLabel('Use an offline route'),
        ),
      ],
      if (failure.showBack) ...[
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          key: const ValueKey('loading-failure-back'),
          variant: AppButtonVariant.secondary,
          fullWidth: true,
          onPressed: _succeeded ? null : _cancel,
          child: _buttonLabel('Back'),
        ),
      ],
    ],
  );

  // AppButton has a fixed-height label row. Constrain long action labels at
  // accessibility text sizes so they stay readable inside their tap target.
  Widget _buttonLabel(String label) => Flexible(
    child: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
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
              child: LayoutBuilder(
                builder: (context, constraints) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _LoadingBackdrop(
                        frozen: failure != null,
                        coordinates: _backdropCoordinates,
                      ),
                    ),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: math.max(
                          0,
                          constraints.maxHeight -
                              MediaQuery.paddingOf(context).top -
                              AppMetrics.loadingBrandBadgeSize,
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: _LoadingPanel(
                          children: [
                            if (failure != null) ...[
                              Entrance(
                                child:
                                    failure.visual == PlanFailureVisual.noSignal
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.card,
                                        ),
                                        child: Image.asset(
                                          LoadingScreen.noSignalAsset,
                                          key: const ValueKey(
                                            'loading-no-signal-scene',
                                          ),
                                          height:
                                              AppMetrics.resultStopImageHeight,
                                          fit: BoxFit.cover,
                                          excludeFromSemantics: true,
                                        ),
                                      )
                                    : Center(
                                        child: AppIcon(
                                          failure.visual ==
                                                  PlanFailureVisual.signIn
                                              ? LucideIcons.log_in
                                              : LucideIcons.circle_alert,
                                          key: const ValueKey(
                                            'loading-failure-icon',
                                          ),
                                          size: AppMetrics.iconHuge,
                                          color: AppColors.inkMuted,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                            ],
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
  const _LoadingBackdrop({required this.frozen, required this.coordinates});

  final bool frozen;
  final List<List<double>> coordinates;

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
              coordinates
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
            child: RouteCarBackdrop.ambient(coordinates: coordinates),
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

/// The rotating status line, crossfading from one message to the next.
///
/// Every message is given the height of the tallest one at the current width
/// and text scale, so a message that wraps to a second line does not resize
/// the panel, and with it the map, mid-rotation.
class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.index, required this.messages});

  final int index;
  final List<String> messages;

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
        for (final message in messages) {
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
                messages[index],
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
