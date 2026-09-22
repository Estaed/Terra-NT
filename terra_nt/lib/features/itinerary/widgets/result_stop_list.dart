import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/elevation.dart';
import '../../../core/theme/metrics.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/util/itinerary_ops.dart';
import '../../../core/util/tag_colors.dart';
import '../../../data/models/stop.dart';
import '../../../data/repositories/notifiers.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../shared/widgets/app_pill_badge.dart';
import '../../../shared/widgets/tag_dot.dart';
import 'plan_entry_list.dart';

/// The Result sheet's stop collection. Original indices remain the identity
/// across reorders, removals, restores, and skipped-state rendering.
class ResultStopList extends ConsumerWidget {
  const ResultStopList({
    super.key,
    required this.header,
    required this.detailed,
    required this.onOpenStop,
  });

  final Widget header;
  final bool detailed;
  final ValueChanged<int> onOpenStop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(itineraryNotifierProvider);
    final notifier = ref.read(itineraryNotifierProvider.notifier);
    final padding = const EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.xs,
      AppSpacing.md,
      AppSpacing.lg,
    );

    Widget rowAt(int position) {
      final originalIndex = state.order[position];
      return Padding(
        key: ValueKey('result-stop-item-$originalIndex'),
        padding: const EdgeInsets.only(bottom: AppMetrics.resultStopListGap),
        child: ResultStopRow(
          stop: state.itinerary.stops[originalIndex],
          originalIndex: originalIndex,
          position: position,
          order: state.order,
          baselineStops: state.itinerary.stops,
          detailed: detailed,
          editMode: state.editMode,
          skipped: state.skipped.contains(originalIndex),
          onOpen: () => onOpenStop(originalIndex),
          onRevert: () => notifier.revertOne(originalIndex),
          onRemove: () => notifier.remove(originalIndex),
        ),
      );
    }

    final paddedHeader = Padding(
      padding: const EdgeInsets.only(bottom: AppMetrics.resultStopListGap),
      child: header,
    );

    if (!state.editMode) {
      return ListView.builder(
        key: const ValueKey('result-stop-list-view'),
        padding: padding,
        itemCount: state.order.length + 1,
        itemBuilder: (context, index) =>
            index == 0 ? paddedHeader : rowAt(index - 1),
      );
    }

    // The edge auto-scroller runs untouched: an edit row is
    // [AppMetrics.resultStopEditRowHeight] tall, always shorter than the list
    // viewport at the max anchor edit mode snaps the sheet to, so
    // `EdgeDraggingAutoScroller` has room to scroll the dragged row instead of
    // asserting on it.
    return ReorderableListView.builder(
      key: const ValueKey('result-stop-list-edit'),
      padding: padding,
      header: paddedHeader,
      buildDefaultDragHandles: false,
      itemCount: state.order.length,
      onReorderItem: notifier.reorder,
      itemBuilder: (context, index) => rowAt(index),
    );
  }
}

class ResultStopRow extends StatelessWidget {
  const ResultStopRow({
    super.key,
    required this.stop,
    required this.originalIndex,
    required this.position,
    required this.order,
    required this.baselineStops,
    required this.detailed,
    required this.editMode,
    required this.skipped,
    required this.onOpen,
    required this.onRevert,
    required this.onRemove,
  });

  final Stop stop;
  final int originalIndex;
  final int position;
  final List<int> order;
  final List<Stop> baselineStops;
  final bool detailed;
  final bool editMode;
  final bool skipped;
  final VoidCallback onOpen;
  final VoidCallback onRevert;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final driveNext = driveNextForPosition(order, position, baselineStops);
    final decoration = BoxDecoration(
      color: AppColors.surface1,
      border: Border.all(
        color: AppColors.hairline,
        width: AppElevation.hairlineWidth,
      ),
      borderRadius: BorderRadius.circular(AppRadius.card),
    );

    return Opacity(
      key: ValueKey('result-stop-opacity-$originalIndex'),
      opacity: skipped ? 0.5 : 1,
      child: GestureDetector(
        key: ValueKey('result-stop-row-$originalIndex'),
        behavior: HitTestBehavior.opaque,
        onTap: editMode ? null : onOpen,
        child: editMode
            ? Container(
                height: AppMetrics.resultStopEditRowHeight,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                decoration: decoration,
                child: _EditRow(
                  name: stop.name,
                  originalIndex: originalIndex,
                  position: position,
                  moved: position != originalIndex,
                  onRevert: onRevert,
                  onRemove: onRemove,
                ),
              )
            : Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppMetrics.padRowX,
                  vertical: AppMetrics.padRowY,
                ),
                decoration: decoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Heading(
                      stop: stop,
                      originalIndex: originalIndex,
                      position: position,
                      skipped: skipped,
                    ),
                    const SizedBox(height: AppMetrics.resultStopListGap),
                    Wrap(
                      key: ValueKey('result-stop-tags-$originalIndex'),
                      spacing: AppMetrics.resultStopEditActionGap,
                      runSpacing: AppMetrics.resultStopEditActionGap,
                      children: [
                        for (final tag in stop.tags)
                          TagDot(
                            color: tagColor(tag),
                            label: tag,
                            bordered: true,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppMetrics.resultStopListGap),
                    if (detailed)
                      _DetailedPlan(originalIndex: originalIndex, stop: stop)
                    else
                      _Highlight(
                        originalIndex: originalIndex,
                        note: stop.aiNote,
                      ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      height: AppElevation.hairlineWidth,
                      color: AppColors.hairline,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _Footer(
                      originalIndex: originalIndex,
                      duration: stop.duration,
                      driveNext: driveNext,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({
    required this.stop,
    required this.originalIndex,
    required this.position,
    required this.skipped,
  });

  final Stop stop;
  final int originalIndex;
  final int position;
  final bool skipped;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PositionBadge(originalIndex: originalIndex, position: position),
        const SizedBox(width: AppMetrics.resultStopListGap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stop.name,
                key: ValueKey('result-stop-name-$originalIndex'),
                style: AppType.titleApp.copyWith(color: AppColors.ink),
              ),
              const SizedBox(height: AppMetrics.resultStopSubtitleGap),
              Text(
                stop.subtitle,
                style: AppType.caption.copyWith(color: AppColors.inkSubtle),
              ),
            ],
          ),
        ),
        if (skipped) ...[
          const SizedBox(width: AppSpacing.xs),
          AppPillBadge(
            key: ValueKey('result-stop-skipped-$originalIndex'),
            label: 'Skipped',
            color: AppColors.inkSubtle,
          ),
        ],
        const SizedBox(width: AppSpacing.xs),
        AppIcon(
          LucideIcons.chevron_right,
          key: ValueKey('result-stop-chevron-$originalIndex'),
          color: AppColors.inkTertiary,
        ),
      ],
    );
  }
}

/// Edit mode's row: position badge, name, revert when the stop has moved,
/// remove, drag handle -- nothing else, inside one
/// [AppMetrics.resultStopEditRowHeight].
///
/// The name truncates rather than wrapping. The height is the point: a row
/// shorter than the list viewport is what lets the framework's edge
/// auto-scroller carry a reorder past the visible neighbours instead of
/// asserting, which is the defect `docs/DEVICE-TOUR.md` records.
class _EditRow extends StatelessWidget {
  const _EditRow({
    required this.name,
    required this.originalIndex,
    required this.position,
    required this.moved,
    required this.onRevert,
    required this.onRemove,
  });

  final String name;
  final int originalIndex;
  final int position;
  final bool moved;
  final VoidCallback onRevert;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PositionBadge(originalIndex: originalIndex, position: position),
        const SizedBox(width: AppMetrics.resultStopListGap),
        Expanded(
          child: Text(
            name,
            key: ValueKey('result-stop-name-$originalIndex'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppType.titleApp.copyWith(color: AppColors.ink),
          ),
        ),
        if (moved)
          ResultIconAction(
            key: ValueKey('result-stop-revert-$originalIndex'),
            visualKey: ValueKey('result-stop-revert-visual-$originalIndex'),
            tooltip: 'Revert to AI Suggestion',
            icon: LucideIcons.rotate_ccw,
            color: AppColors.primary,
            onTap: onRevert,
          ),
        ResultIconAction(
          key: ValueKey('result-stop-remove-$originalIndex'),
          visualKey: ValueKey('result-stop-remove-visual-$originalIndex'),
          tooltip: 'Remove stop',
          icon: LucideIcons.trash_2,
          color: AppColors.inkSubtle,
          onTap: onRemove,
        ),
        ReorderableDragStartListener(
          key: ValueKey('result-stop-drag-$originalIndex'),
          index: position,
          // The grip keeps its icon size inside a 48px drag target.
          child: SizedBox(
            width: AppMetrics.minTouchTarget,
            height: AppMetrics.minTouchTarget,
            child: Center(
              child: AppIcon(
                LucideIcons.grip_vertical,
                key: ValueKey('result-stop-drag-visual-$originalIndex'),
                color: AppColors.inkTertiary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PositionBadge extends StatelessWidget {
  const _PositionBadge({required this.originalIndex, required this.position});

  final int originalIndex;
  final int position;

  @override
  Widget build(BuildContext context) => Container(
    key: ValueKey('result-stop-badge-$originalIndex'),
    width: AppMetrics.resultStopBadgeSize,
    height: AppMetrics.resultStopBadgeSize,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.surface2,
      border: Border.all(
        color: AppColors.hairlineStrong,
        width: AppElevation.hairlineWidth,
      ),
      borderRadius: BorderRadius.circular(AppRadius.full),
    ),
    child: Text(
      '${position + 1}',
      style: AppType.caption.copyWith(
        color: AppColors.ink,
        fontFamily: AppFonts.mono,
      ),
    ),
  );
}

/// An edit-mode action: painted at the prototype's 26px circle, tapped through
/// a transparent [AppMetrics.minTouchTarget] square around it.
class ResultIconAction extends StatelessWidget {
  const ResultIconAction({
    super.key,
    required this.visualKey,
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final Key visualKey;
  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: AppMetrics.minTouchTarget,
          height: AppMetrics.minTouchTarget,
          child: Center(
            child: Container(
              key: visualKey,
              width: AppMetrics.resultStopActionVisualSize,
              height: AppMetrics.resultStopActionVisualSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surface2,
                border: Border.all(
                  color: AppColors.hairline,
                  width: AppElevation.hairlineWidth,
                ),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: AppIcon(icon, size: AppMetrics.iconXs, color: color),
            ),
          ),
        ),
      ),
    );
  }
}

class _Highlight extends StatelessWidget {
  const _Highlight({required this.originalIndex, required this.note});

  final int originalIndex;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: ValueKey('result-stop-highlight-$originalIndex'),
      padding: const EdgeInsets.only(top: AppMetrics.resultStopContentTopGap),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: AppMetrics.resultStopContentTopGap),
            child: AppIcon(
              LucideIcons.zap,
              size: AppMetrics.iconSm,
              color: AppColors.inkSubtle,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              note,
              style: AppType.bodyApp.copyWith(color: AppColors.inkMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailedPlan extends StatelessWidget {
  const _DetailedPlan({required this.originalIndex, required this.stop});

  final int originalIndex;
  final Stop stop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: ValueKey('result-stop-detailed-$originalIndex'),
      padding: const EdgeInsets.only(top: AppMetrics.resultStopContentTopGap),
      child: stop.detailedPlan.isEmpty
          ? Text(
              'No detailed plan for this stop.',
              key: ValueKey('detailed-plan-empty-$originalIndex'),
              style: AppType.caption.copyWith(color: AppColors.inkTertiary),
            )
          : PlanEntryList(entries: stop.detailedPlan),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.originalIndex,
    required this.duration,
    required this.driveNext,
  });

  final int originalIndex;
  final String duration;
  final String? driveNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          duration,
          style: AppType.caption.copyWith(color: AppColors.inkSubtle),
        ),
        if (driveNext != null) ...[
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    driveNext!,
                    key: ValueKey('result-stop-drive-$originalIndex'),
                    textAlign: TextAlign.right,
                    style: AppType.caption.copyWith(color: AppColors.inkSubtle),
                  ),
                ),
                const SizedBox(width: AppMetrics.resultStopEditActionGap),
                const AppIcon(
                  LucideIcons.arrow_right,
                  size: AppMetrics.iconXxs,
                  color: AppColors.inkSubtle,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
