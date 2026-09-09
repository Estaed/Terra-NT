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
    final moved = position != originalIndex;

    return Opacity(
      key: ValueKey('result-stop-opacity-$originalIndex'),
      opacity: skipped ? 0.5 : 1,
      child: GestureDetector(
        key: ValueKey('result-stop-row-$originalIndex'),
        behavior: HitTestBehavior.opaque,
        onTap: editMode ? null : onOpen,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppMetrics.padRowX,
            vertical: AppMetrics.padRowY,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface1,
            border: Border.all(
              color: AppColors.hairline,
              width: AppElevation.hairlineWidth,
            ),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Heading(
                stop: stop,
                originalIndex: originalIndex,
                position: position,
                editMode: editMode,
                skipped: skipped,
                moved: moved,
                onRevert: onRevert,
                onRemove: onRemove,
              ),
              const SizedBox(height: AppMetrics.resultStopListGap),
              Wrap(
                key: ValueKey('result-stop-tags-$originalIndex'),
                spacing: AppMetrics.resultStopEditActionGap,
                runSpacing: AppMetrics.resultStopEditActionGap,
                children: [
                  for (final tag in stop.tags)
                    TagDot(color: tagColor(tag), label: tag, bordered: true),
                ],
              ),
              const SizedBox(height: AppMetrics.resultStopListGap),
              if (detailed)
                _DetailedPlan(originalIndex: originalIndex, stop: stop)
              else
                _Highlight(originalIndex: originalIndex, note: stop.aiNote),
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
    required this.editMode,
    required this.skipped,
    required this.moved,
    required this.onRevert,
    required this.onRemove,
  });

  final Stop stop;
  final int originalIndex;
  final int position;
  final bool editMode;
  final bool skipped;
  final bool moved;
  final VoidCallback onRevert;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (editMode) ...[
          ReorderableDragStartListener(
            key: ValueKey('result-stop-drag-$originalIndex'),
            index: position,
            child: const AppIcon(
              LucideIcons.grip_vertical,
              color: AppColors.inkTertiary,
            ),
          ),
          const SizedBox(width: AppMetrics.resultStopListGap),
        ],
        Container(
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
        ),
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
        if (!editMode)
          AppIcon(
            LucideIcons.chevron_right,
            key: ValueKey('result-stop-chevron-$originalIndex'),
            color: AppColors.inkTertiary,
          )
        else
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (moved) ...[
                _EditAction(
                  key: ValueKey('result-stop-revert-$originalIndex'),
                  tooltip: 'Revert to AI Suggestion',
                  icon: LucideIcons.rotate_ccw,
                  color: AppColors.primary,
                  onTap: onRevert,
                ),
                const SizedBox(width: AppMetrics.resultStopEditActionGap),
              ],
              _EditAction(
                key: ValueKey('result-stop-remove-$originalIndex'),
                tooltip: 'Remove stop',
                icon: LucideIcons.trash_2,
                color: AppColors.inkSubtle,
                onTap: onRemove,
              ),
            ],
          ),
      ],
    );
  }
}

class _EditAction extends StatelessWidget {
  const _EditAction({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onTap,
  });

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
        child: Container(
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
      child: Column(
        children: [
          for (final entry in stop.detailedPlan)
            Padding(
              padding: const EdgeInsets.only(
                bottom: AppMetrics.resultStopEditActionGap,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: AppMetrics.resultStopPlanTimeWidth,
                    child: Text(
                      entry.time,
                      style: AppType.captionApp.copyWith(
                        color: AppColors.inkTertiary,
                        fontFamily: AppFonts.mono,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppMetrics.resultStopListGap),
                  Expanded(
                    child: Text(
                      entry.activity,
                      style: AppType.bodyApp.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
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
