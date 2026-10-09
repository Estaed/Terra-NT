import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/screen_routes.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/elevation.dart';
import '../../core/theme/metrics.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/radius.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/util/itinerary_ops.dart';
import '../../core/util/maps_url.dart';
import '../../core/util/sheet_snap.dart';
import '../../data/repositories/notifiers.dart';
import '../../shared/map/dashed_route_polyline.dart';
import '../../shared/map/map_markers.dart';
import '../../shared/map/route_reveal.dart';
import '../../shared/map/terra_map.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_chip.dart';
import 'stop_detail/stop_detail_screen.dart';
import 'widgets/result_empty_state.dart';
import 'widgets/result_stop_list.dart';

typedef MapsLauncher = Future<bool> Function(Uri url);

/// The Result frame. Task-14 supplies the scrollable stop-list content.
class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({
    super.key,
    this.launcher = launchUrl,
    this.onOpenStop,
    this.onOpenSavedRoutes,
  });

  final MapsLauncher launcher;
  final ValueChanged<int>? onOpenStop;
  final VoidCallback? onOpenSavedRoutes;

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  double? _sheetHeight;
  bool _dragging = false;

  /// Highlights/Detailed is Result-local and defaults to Highlights: onboarding
  /// no longer asks how detailed the plan should be (V11), and the choice is a
  /// way of reading this screen rather than a property of the trip, so it is
  /// not persisted and resets with the session.
  bool _detailed = false;

  /// Whether the inline "Discard edits and plan again?" confirmation is open.
  /// Session-only, like Profile's delete-account confirmation.
  bool _confirmPlanAgain = false;
  String? _exportFailureCoordinates;

  void _planAgain(BuildContext context) {
    ref.read(onboardingNotifierProvider.notifier).reset();
    ref.read(itineraryNotifierProvider.notifier).reset();
    _confirmPlanAgain = false;
    replaceWithOnboarding(context);
  }

  Future<void> _export() async {
    final itineraryState = ref.read(itineraryNotifierProvider);
    final stops = [
      for (final originalIndex in activeStopOrder(
        itineraryState.order,
        itineraryState.skipped,
      ))
        itineraryState.itinerary.stops[originalIndex],
    ];
    final url = buildMapsUrl(stops);
    if (url == null) return;
    var opened = false;
    try {
      opened = await widget.launcher(Uri.parse(url));
    } catch (_) {
      // Platform failures have the same useful fallback as a refused launch.
    }
    if (!mounted) return;
    setState(() {
      _exportFailureCoordinates = opened
          ? null
          : destinationCoordinates(stops.last);
    });
  }

  void _openStop(BuildContext context, int originalIndex) {
    final callback = widget.onOpenStop;
    if (callback != null) {
      callback(originalIndex);
      return;
    }
    final itinerary = ref.read(itineraryNotifierProvider).itinerary;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StopDetailScreen(
          stop: itinerary.stops[originalIndex],
          originalIndex: originalIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Entering edit mode snaps the sheet to its top anchor. A reorder drag can
    // only auto-scroll while the dragged row is shorter than the list viewport,
    // and at the peek anchor nothing is (`docs/DEVICE-TOUR.md`). Listening to
    // the notifier rather than the toggle's callback keeps that true however
    // edit mode was entered.
    ref.listen(itineraryNotifierProvider.select((state) => state.editMode), (
      previous,
      next,
    ) {
      if (next && previous != true) {
        setState(() => _sheetHeight = AppMetrics.resultSheetMaxHeight);
      }
    });

    final itineraryState = ref.watch(itineraryNotifierProvider);
    final stops = itineraryState.visibleStops;
    final canExport =
        activeStopOrder(itineraryState.order, itineraryState.skipped).length >=
        2;
    final points = stops.map((stop) => LatLng(stop.lat, stop.lng)).toList();
    final reveal = RouteRevealGeometry(points);

    if (!itineraryState.hasRoute) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        body: ResultEmptyState(
          onPlanMyRoute: () => _planAgain(context),
          onOpenSavedRoutes: ref.watch(savedRoutesNotifierProvider).isNotEmpty
              ? widget.onOpenSavedRoutes
              : null,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final insets = MediaQuery.paddingOf(context);
          final usableHeight =
              (constraints.maxHeight - insets.top - insets.bottom)
                  .clamp(0.0, AppMetrics.resultSheetMaxHeight)
                  .toDouble();
          final minHeight = AppMetrics.resultSheetMinHeight
              .clamp(0.0, usableHeight)
              .toDouble();
          // The sheet opens at the middle anchor, as the prototype does
          // (`Terra NT.dc.html` L820), clamped on a viewport too short for it.
          final height = (_sheetHeight ?? AppMetrics.resultSheetMidHeight)
              .clamp(minHeight, usableHeight)
              .toDouble();

          return Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('result-map'),
                child: RouteReveal(
                  routeIdentity: itineraryState.itinerary,
                  builder: (context, progress) => TerraMap(
                    interactive: true,
                    animateCameraFit: true,
                    separatePins: true,
                    suspendCameraFit: _dragging,
                    bounds: points.isNotEmpty
                        ? LatLngBounds.fromPoints(points)
                        : null,
                    fitPadding: TerraMap.resultFitPaddingFor(
                      constraints.maxHeight,
                      insets.top,
                      sheetHeight: height,
                    ),
                    animatedMarkers: (
                      listenable: progress,
                      build: () => [
                        for (var index = 0; index < stops.length; index++)
                          TerraMapMarker(
                            key: ValueKey('result-pin-$index'),
                            point: points[index],
                            tooltip:
                                reveal.pinOpacity(index, progress.value) > 0
                                ? stops[index].name
                                : null,
                            onTap: reveal.pinOpacity(index, progress.value) > 0
                                ? () => _openStop(
                                    context,
                                    itineraryState.order[index],
                                  )
                                : null,
                            child: Opacity(
                              opacity: reveal.pinOpacity(index, progress.value),
                              child: NumberedPinMarker(
                                number: index + 1,
                                placeName: stops[index].name,
                              ),
                            ),
                            width: AppMetrics.minTouchTarget,
                            height: AppMetrics.minTouchTarget,
                          ),
                      ],
                    ),
                    animatedPolylines: (
                      listenable: progress,
                      build: () {
                        final drawn = reveal.pointsAt(progress.value);
                        return drawn.length > 1
                            ? [DashedRoutePolyline.result(points: drawn)]
                            : const [];
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                left: AppSpacing.xxs,
                right: AppSpacing.xxs,
                bottom: AppMetrics.resultSheetBottomInset,
                height: height,
                child: AnimatedContainer(
                  key: const ValueKey('result-sheet'),
                  duration: _dragging || MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : AppMotion.resultSheetSnap,
                  curve: AppMotion.easeOut,
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
                  child: Column(
                    children: [
                      Semantics(
                        label: 'Trip stops',
                        value: height <= minHeight
                            ? 'Collapsed'
                            : height >= usableHeight
                            ? 'Expanded'
                            : 'Partially expanded',
                        customSemanticsActions: {
                          if (height < usableHeight)
                            const CustomSemanticsAction(label: 'Expand'): () =>
                                setState(() => _sheetHeight = usableHeight),
                          if (height > minHeight)
                            const CustomSemanticsAction(
                              label: 'Collapse',
                            ): () =>
                                setState(() => _sheetHeight = minHeight),
                        },
                        child: GestureDetector(
                          key: const ValueKey('result-sheet-handle'),
                          behavior: HitTestBehavior.opaque,
                          onVerticalDragStart: (_) =>
                              setState(() => _dragging = true),
                          onVerticalDragUpdate: (details) => setState(() {
                            _sheetHeight = (height - details.delta.dy)
                                .clamp(minHeight, usableHeight)
                                .toDouble();
                          }),
                          onVerticalDragEnd: (_) => setState(() {
                            _sheetHeight = nearestSnap(
                              _sheetHeight ?? height,
                              usableHeight: usableHeight,
                            );
                            _dragging = false;
                          }),
                          onVerticalDragCancel: () => setState(() {
                            _sheetHeight = nearestSnap(
                              height,
                              usableHeight: usableHeight,
                            );
                            _dragging = false;
                          }),
                          child: SizedBox(
                            height: AppMetrics.minTouchTarget,
                            child: Center(
                              child: Container(
                                width: AppMetrics.resultSheetGrabberWidth,
                                height: AppMetrics.resultSheetGrabberHeight,
                                decoration: BoxDecoration(
                                  color: AppColors.hairlineStrong,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ResultStopList(
                          key: const ValueKey('result-sheet-scroll'),
                          detailed: _detailed,
                          onOpenStop: (originalIndex) =>
                              _openStop(context, originalIndex),
                          header: _ResultHeader(
                            title: itineraryState.itinerary.title,
                            meta: itineraryMeta(
                              itineraryState.itinerary,
                              stops.length,
                            ),
                            detailed: _detailed,
                            editMode: itineraryState.editMode,
                            removedCount:
                                itineraryState.itinerary.stops.length -
                                stops.length,
                            confirmPlanAgain: _confirmPlanAgain,
                            onDetailedChanged: (detailed) =>
                                setState(() => _detailed = detailed),
                            onPlanAgain: () {
                              if (hasEdits(
                                itineraryState.order,
                                itineraryState.skipped,
                                itineraryState.itinerary.stops.length,
                              )) {
                                setState(() => _confirmPlanAgain = true);
                                return;
                              }
                              _planAgain(context);
                            },
                            onConfirmPlanAgain: () => _planAgain(context),
                            onCancelPlanAgain: () =>
                                setState(() => _confirmPlanAgain = false),
                            onEditChanged: () => ref
                                .read(itineraryNotifierProvider.notifier)
                                .setEditMode(!itineraryState.editMode),
                            onExport: canExport ? _export : null,
                            exportFailureCoordinates: _exportFailureCoordinates,
                            onRestoreRemoved: () => ref
                                .read(itineraryNotifierProvider.notifier)
                                .restoreRemoved(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ResultHeader extends StatelessWidget {
  const _ResultHeader({
    required this.title,
    required this.meta,
    required this.detailed,
    required this.editMode,
    required this.removedCount,
    required this.confirmPlanAgain,
    required this.onDetailedChanged,
    required this.onEditChanged,
    required this.onExport,
    required this.exportFailureCoordinates,
    required this.onRestoreRemoved,
    required this.onPlanAgain,
    required this.onConfirmPlanAgain,
    required this.onCancelPlanAgain,
  });

  final String title;
  final String meta;
  final bool detailed;
  final bool editMode;
  final int removedCount;
  final bool confirmPlanAgain;
  final ValueChanged<bool> onDetailedChanged;
  final VoidCallback onEditChanged;
  final VoidCallback? onExport;
  final String? exportFailureCoordinates;
  final VoidCallback onRestoreRemoved;
  final VoidCallback onPlanAgain;
  final VoidCallback onConfirmPlanAgain;
  final VoidCallback onCancelPlanAgain;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppType.titleApp.copyWith(color: AppColors.ink),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  meta,
                  style: AppType.caption.copyWith(color: AppColors.inkSubtle),
                ),
              ],
            ),
          ),
          ResultIconAction(
            key: const ValueKey('result-plan-again'),
            visualKey: const ValueKey('result-plan-again-visual'),
            tooltip: 'Plan again',
            icon: LucideIcons.sparkles,
            color: AppColors.primary,
            onTap: onPlanAgain,
          ),
        ],
      ),
      if (confirmPlanAgain) ...[
        const SizedBox(height: AppSpacing.xs),
        _PlanAgainConfirmation(
          onConfirm: onConfirmPlanAgain,
          onCancel: onCancelPlanAgain,
        ),
      ],
      const SizedBox(height: AppSpacing.md),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: _ResultSegmentRail(
                detailed: detailed,
                onDetailedChanged: onDetailedChanged,
              ),
            ),
          ),
          Flexible(
            child: FittedBox(
              alignment: Alignment.centerRight,
              fit: BoxFit.scaleDown,
              child: AppChip(
                key: const ValueKey('result-edit-toggle'),
                label: editMode ? 'Done' : 'Edit Route',
                selected: editMode,
                icon: editMode ? LucideIcons.check : LucideIcons.pencil,
                onTap: onEditChanged,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      AppButton(
        key: const ValueKey('result-export'),
        fullWidth: true,
        iconLeft: LucideIcons.external_link,
        onPressed: onExport,
        // The label keeps its exact copy and shrinks inside the button rather
        // than overflowing it at a narrow width or a scaled text size.
        child: const Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('Export to Google Maps'),
          ),
        ),
      ),
      if (onExport == null) ...[
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Keep at least two active stops to export a route.',
          key: const ValueKey('result-export-reason'),
          style: AppType.bodySm.copyWith(color: AppColors.inkSubtle),
        ),
      ],
      if (exportFailureCoordinates != null) ...[
        const SizedBox(height: AppSpacing.xs),
        MapsLaunchFailure(coordinates: exportFailureCoordinates!),
      ],
      if (removedCount > 0) ...[
        const SizedBox(height: AppSpacing.md),
        GestureDetector(
          key: const ValueKey('result-restore-removed'),
          behavior: HitTestBehavior.opaque,
          onTap: onRestoreRemoved,
          child: ConstrainedBox(
            // The link paints as a caption; the target around it is 48px.
            constraints: const BoxConstraints(
              minWidth: AppMetrics.minTouchTarget,
              minHeight: AppMetrics.minTouchTarget,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    removedLabel(removedCount),
                    key: const ValueKey('result-restore-removed-label'),
                    style: AppType.caption.copyWith(
                      color: AppColors.inkTertiary,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.inkTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ],
  );
}

class _ResultSegmentRail extends StatelessWidget {
  const _ResultSegmentRail({
    required this.detailed,
    required this.onDetailedChanged,
  });

  final bool detailed;
  final ValueChanged<bool> onDetailedChanged;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('result-segment-rail'),
    padding: const EdgeInsets.all(AppMetrics.resultSegmentRailPadding),
    decoration: BoxDecoration(
      color: AppColors.canvas,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      border: Border.all(
        color: AppColors.hairline,
        width: AppElevation.hairlineWidth,
      ),
    ),
    child: FittedBox(
      alignment: Alignment.centerLeft,
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppChip(
            key: const ValueKey('result-highlights'),
            label: 'Highlights',
            selected: !detailed,
            onTap: () => onDetailedChanged(false),
          ),
          const SizedBox(width: AppMetrics.resultSegmentRailGap),
          AppChip(
            key: const ValueKey('result-detailed'),
            label: 'Detailed',
            selected: detailed,
            onTap: () => onDetailedChanged(true),
          ),
        ],
      ),
    ),
  );
}

/// The inline "Plan again" confirmation, in the shape Profile's delete-account
/// confirmation already established: a panel in the flow rather than a dialog,
/// so the choice that throws away edits stays in the surface that raised it.
class _PlanAgainConfirmation extends StatelessWidget {
  const _PlanAgainConfirmation({
    required this.onConfirm,
    required this.onCancel,
  });

  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('result-plan-again-confirm'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppMetrics.padRowY),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: AppColors.hairline,
          width: AppElevation.hairlineWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Discard edits and plan again?',
            style: AppType.bodyApp.copyWith(color: AppColors.inkSubtle),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  key: const ValueKey('result-plan-again-cancel'),
                  onPressed: onCancel,
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.md,
                  fullWidth: true,
                  child: const Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Cancel'),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: AppButton(
                  key: const ValueKey('result-plan-again-confirm-action'),
                  onPressed: onConfirm,
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.md,
                  fullWidth: true,
                  foregroundColor: AppColors.primary,
                  child: const Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Plan again'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
