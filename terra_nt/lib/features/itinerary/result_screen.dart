import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

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
import '../../shared/map/terra_map.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_chip.dart';
import 'stop_detail/stop_detail_screen.dart';
import 'widgets/result_stop_list.dart';

typedef MapsLauncher = Future<bool> Function(Uri url);

/// The Result frame. Task-14 supplies the scrollable stop-list content.
class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({super.key, this.launcher = launchUrl, this.onOpenStop});

  final MapsLauncher launcher;
  final ValueChanged<int>? onOpenStop;

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  double? _sheetHeight;
  bool _dragging = false;

  Future<void> _export() async {
    final itineraryState = ref.read(itineraryNotifierProvider);
    final stops = [
      for (final originalIndex in itineraryState.order)
        if (!itineraryState.skipped.contains(originalIndex))
          itineraryState.itinerary.stops[originalIndex],
    ];
    final url = buildMapsUrl(stops);
    if (url != null) await widget.launcher(Uri.parse(url));
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
    final itineraryState = ref.watch(itineraryNotifierProvider);
    final answers = ref.watch(onboardingNotifierProvider).answers;
    final stops = itineraryState.visibleStops;
    final points = stops.map((stop) => LatLng(stop.lat, stop.lng)).toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final insets = MediaQuery.viewPaddingOf(context);
          final usableHeight =
              (constraints.maxHeight - insets.top - insets.bottom)
                  .clamp(0.0, AppMetrics.resultSheetMaxHeight)
                  .toDouble();
          final minHeight = AppMetrics.resultSheetMinHeight
              .clamp(0.0, usableHeight)
              .toDouble();
          final height = (_sheetHeight ?? minHeight)
              .clamp(minHeight, usableHeight)
              .toDouble();

          return Stack(
            children: [
              Positioned(
                key: const ValueKey('result-map'),
                top: 0,
                left: 0,
                right: 0,
                height: AppMetrics.resultMapHeight,
                child: TerraMap(
                  interactive: true,
                  zoomControl: true,
                  bounds: points.length > 1
                      ? LatLngBounds.fromPoints(points)
                      : null,
                  fitPadding: TerraMap.resultFitPadding,
                  markers: [
                    for (var index = 0; index < stops.length; index++)
                      TerraMapMarker(
                        key: ValueKey('result-pin-$index'),
                        point: points[index],
                        tooltip: stops[index].name,
                        child: NumberedPinMarker(number: index + 1),
                      ),
                  ],
                  polylines: points.length > 1
                      ? [DashedRoutePolyline.result(points: points)]
                      : const [],
                ),
              ),
              Positioned(
                left: AppSpacing.xxs,
                right: AppSpacing.xxs,
                bottom: AppMetrics.resultSheetBottomInset,
                height: height,
                child: AnimatedContainer(
                  key: const ValueKey('result-sheet'),
                  duration: _dragging
                      ? Duration.zero
                      : AppMotion.resultSheetSnap,
                  curve: Curves.easeOut,
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
                      GestureDetector(
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
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                          ),
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
                      Expanded(
                        child: ResultStopList(
                          key: const ValueKey('result-sheet-scroll'),
                          detailed: answers.detailed,
                          onOpenStop: (originalIndex) =>
                              _openStop(context, originalIndex),
                          header: _ResultHeader(
                            title: itineraryState.itinerary.title,
                            meta: derivedMeta(stops.length, answers.days),
                            detailed: answers.detailed,
                            editMode: itineraryState.editMode,
                            removedCount:
                                itineraryState.itinerary.stops.length -
                                stops.length,
                            onDetailedChanged: (detailed) => ref
                                .read(onboardingNotifierProvider.notifier)
                                .setAnswers(
                                  answers.copyWith(detailed: detailed),
                                ),
                            onEditChanged: () => ref
                                .read(itineraryNotifierProvider.notifier)
                                .setEditMode(!itineraryState.editMode),
                            onExport: _export,
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
    required this.onDetailedChanged,
    required this.onEditChanged,
    required this.onExport,
    required this.onRestoreRemoved,
  });

  final String title;
  final String meta;
  final bool detailed;
  final bool editMode;
  final int removedCount;
  final ValueChanged<bool> onDetailedChanged;
  final VoidCallback onEditChanged;
  final VoidCallback onExport;
  final VoidCallback onRestoreRemoved;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: AppType.titleApp.copyWith(color: AppColors.ink)),
      const SizedBox(height: AppSpacing.xxs),
      Text(meta, style: AppType.caption.copyWith(color: AppColors.inkSubtle)),
      const SizedBox(height: AppSpacing.md),
      Row(
        children: [
          AppChip(
            key: const ValueKey('result-highlights'),
            label: 'Highlights',
            selected: !detailed,
            onTap: () => onDetailedChanged(false),
          ),
          const SizedBox(width: AppSpacing.xs),
          AppChip(
            key: const ValueKey('result-detailed'),
            label: 'Detailed',
            selected: detailed,
            onTap: () => onDetailedChanged(true),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      AppChip(
        key: const ValueKey('result-edit-toggle'),
        label: editMode ? 'Done' : 'Edit Route',
        selected: editMode,
        icon: editMode ? LucideIcons.check : LucideIcons.pencil,
        onTap: onEditChanged,
      ),
      const SizedBox(height: AppSpacing.md),
      AppButton(
        key: const ValueKey('result-export'),
        fullWidth: true,
        iconLeft: LucideIcons.map,
        onPressed: onExport,
        child: const Text('Export to Google Maps'),
      ),
      if (removedCount > 0) ...[
        const SizedBox(height: AppSpacing.md),
        GestureDetector(
          key: const ValueKey('result-restore-removed'),
          behavior: HitTestBehavior.opaque,
          onTap: onRestoreRemoved,
          child: Text(
            removedLabel(removedCount),
            style: AppType.caption.copyWith(
              color: AppColors.inkTertiary,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.inkTertiary,
            ),
          ),
        ),
      ],
    ],
  );
}
