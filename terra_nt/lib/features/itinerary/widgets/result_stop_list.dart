import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/elevation.dart';
import '../../../core/theme/metrics.dart';
import '../../../core/theme/motion.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/util/itinerary_ops.dart';
import '../../../core/util/tag_colors.dart';
import '../../../data/models/stop.dart';
import '../../../data/repositories/notifiers.dart';
import '../../../data/seed/place_images.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../shared/widgets/app_pill_badge.dart';
import '../../../shared/widgets/entrance.dart';
import '../../../shared/widgets/placeholder_tile.dart';
import '../../../shared/widgets/tag_dot.dart';
import 'plan_entry_list.dart';

/// The Result sheet's stop collection. Original indices remain the identity
/// across reorders, removals, restores, and skipped-state rendering.
///
/// The header and the stop cards enter with [Entrance] each time the list
/// arrives on screen: when it first shows a route, and when its tab is shown
/// again (`docs/PRD.md` D18). Edit mode's rows do not enter; they are a
/// working state of cards that are already on screen.
class ResultStopList extends ConsumerStatefulWidget {
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
  ConsumerState<ResultStopList> createState() => _ResultStopListState();
}

class _ResultStopListState extends ConsumerState<ResultStopList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _changeController;
  late final CurvedAnimation _changeProgress;
  late List<int> _displayOrder;
  final Map<int, Tween<double>> _rowSizes = {};
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _displayOrder = ref.read(itineraryNotifierProvider).order.toList();
    _changeController =
        AnimationController(vsync: this, duration: AppMotion.slow)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              setState(() {
                _displayOrder = ref
                    .read(itineraryNotifierProvider)
                    .order
                    .toList();
                _rowSizes.clear();
              });
            }
          });
    _changeProgress = CurvedAnimation(
      parent: _changeController,
      curve: AppMotion.easeStandard,
    );
    ref.listenManual(itineraryNotifierProvider, (previous, next) {
      if (previous == null) return;
      final sameTrip = identical(previous.itinerary, next.itinerary);
      if (sameTrip &&
          _visible &&
          (ModalRoute.of(context)?.isCurrent ?? true) &&
          (previous.order.length != next.order.length ||
              !setEquals(previous.skipped, next.skipped))) {
        HapticFeedback.lightImpact();
      }
      if (!sameTrip || !listEquals(previous.order, next.order)) {
        _syncRows(next, reset: !sameTrip);
      }
    });
  }

  // Only presentation survives removal. The notifier remains the source of
  // truth for the route, export, positions and restore actions throughout.
  void _syncRows(ItineraryState state, {required bool reset}) {
    if (reset || _reduceMotion) {
      _changeController.stop();
      setState(() {
        _displayOrder = state.order.toList();
        _rowSizes.clear();
      });
      return;
    }

    final oldOrder = _displayOrder;
    final nextOrder = state.order.toList();
    for (var position = 0; position < oldOrder.length; position++) {
      final index = oldOrder[position];
      if (!state.order.contains(index)) {
        nextOrder.insert(position.clamp(0, nextOrder.length), index);
      }
    }
    final membershipChanged = !setEquals(
      oldOrder.where((index) => _rowSizes[index]?.end != 0).toSet(),
      state.order.toSet(),
    );
    setState(() {
      if (membershipChanged) {
        final sizes = {
          for (final index in nextOrder)
            index: Tween<double>(
              begin: oldOrder.contains(index)
                  ? _rowSizes[index]?.evaluate(_changeProgress) ?? 1
                  : 0,
              end: state.order.contains(index) ? 1 : 0,
            ),
        };
        _rowSizes
          ..clear()
          ..addAll(sizes);
      }
      _displayOrder = nextOrder;
    });
    if (membershipChanged) _changeController.forward(from: 0);
  }

  @override
  void dispose() {
    _changeProgress.dispose();
    _changeController.dispose();
    super.dispose();
  }

  /// Counts the list's arrivals. It is part of every entrance key, so a new
  /// arrival replays the entrances instead of keeping the ones already run.
  int _arrival = 0;

  /// True from an arrival until the end of the frame that lays it out. Only
  /// items built in that frame enter; one built later (scrolled into range,
  /// uncovered by raising the sheet, rebuilt by leaving edit mode) is simply
  /// there, so nothing fades in under a finger that is already moving.
  bool _arriving = false;

  /// The stagger slot the next item built during an arrival takes. Counting
  /// builds rather than positions lets the first item on screen lead even
  /// when the list was left scrolled down.
  int _arrivalSlot = 0;

  bool _visible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _changeController.stop();
      _displayOrder = ref.read(itineraryNotifierProvider).order.toList();
      _rowSizes.clear();
    }
    // The tab shell keeps every tab built, so a list that arrived while its
    // tab was hidden would play its entrance to nobody.
    final visible = Visibility.of(context);
    if (visible && !_visible) _arrive();
    _visible = visible;
  }

  void _arrive() {
    _arrival++;
    _arriving = true;
    _arrivalSlot = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) => _arriving = false);
  }

  Widget _entering(String id, Widget child) {
    final animate = _arriving;
    return _ArrivalEntrance(
      key: ValueKey('result-arrival-$_arrival-$id'),
      animate: animate,
      index: animate ? _arrivalSlot++ : 0,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(itineraryNotifierProvider);
    final notifier = ref.read(itineraryNotifierProvider.notifier);
    final padding = const EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.xs,
      AppSpacing.md,
      AppSpacing.lg,
    );

    Widget rowAt(int position) {
      final originalIndex = _displayOrder[position];
      final livePosition = state.order.indexOf(originalIndex);
      final removing = livePosition < 0;
      final row = ResultStopRow(
        stop: state.itinerary.stops[originalIndex],
        originalIndex: originalIndex,
        position: removing ? position : livePosition,
        dragIndex: position,
        order: removing ? _displayOrder : state.order,
        baselineStops: state.itinerary.stops,
        detailed: widget.detailed,
        editMode: state.editMode,
        skipped: state.skipped.contains(originalIndex),
        skippedStops: state.skipped,
        onOpen: () => widget.onOpenStop(originalIndex),
        onRevert: () {
          HapticFeedback.lightImpact();
          notifier.revertOne(originalIndex);
        },
        onRemove: () => notifier.remove(originalIndex),
      );
      return SizeTransition(
        key: ValueKey('result-stop-item-$originalIndex'),
        sizeFactor:
            _rowSizes[originalIndex]?.animate(_changeProgress) ??
            kAlwaysCompleteAnimation,
        alignment: Alignment.topCenter,
        child: IgnorePointer(
          ignoring: removing,
          child: Padding(
            padding: const EdgeInsets.only(
              bottom: AppMetrics.resultStopListGap,
            ),
            child: state.editMode ? row : _entering('stop-$originalIndex', row),
          ),
        ),
      );
    }

    final paddedHeader = Padding(
      padding: const EdgeInsets.only(bottom: AppMetrics.resultStopListGap),
      child: widget.header,
    );

    if (!state.editMode) {
      return ListView.builder(
        key: const ValueKey('result-stop-list-view'),
        padding: padding,
        itemCount: _displayOrder.length + 1,
        findChildIndexCallback: (key) {
          for (var position = 0; position < _displayOrder.length; position++) {
            if (key ==
                ValueKey('result-stop-item-${_displayOrder[position]}')) {
              return position + 1;
            }
          }
          return null;
        },
        itemBuilder: (context, index) =>
            index == 0 ? _entering('header', paddedHeader) : rowAt(index - 1),
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
      itemCount: _displayOrder.length,
      onReorderEnd: (_) => HapticFeedback.lightImpact(),
      onReorderItem: (from, to) {
        final liveFrom = state.order.indexOf(_displayOrder[from]);
        final liveTo =
            _displayOrder.take(to + 1).where(state.order.contains).length - 1;
        if (liveFrom >= 0) {
          notifier.reorder(liveFrom, liveTo.clamp(0, state.order.length - 1));
        }
      },
      itemBuilder: (context, index) => rowAt(index),
    );
  }
}

/// [Entrance] when [animate] is true; the child shown at once otherwise.
///
/// Both cases build the same tree, so an item the list rebuilds after its
/// arrival (a skip, a restore) is updated in place rather than remounted in
/// the middle of a gesture. "At once" is asked for through [Entrance]'s own
/// reduce-motion switch, and the child below gets the real media query back.
class _ArrivalEntrance extends StatelessWidget {
  const _ArrivalEntrance({
    super.key,
    required this.animate,
    required this.index,
    required this.child,
  });

  final bool animate;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: animate ? media : media.copyWith(disableAnimations: true),
      child: Entrance(
        index: index,
        child: MediaQuery(data: media, child: child),
      ),
    );
  }
}

class ResultStopRow extends StatelessWidget {
  const ResultStopRow({
    super.key,
    required this.stop,
    required this.originalIndex,
    required this.position,
    this.dragIndex,
    required this.order,
    required this.baselineStops,
    required this.detailed,
    required this.editMode,
    required this.skipped,
    this.skippedStops = const {},
    required this.onOpen,
    required this.onRevert,
    required this.onRemove,
  });

  final Stop stop;
  final int originalIndex;
  final int position;
  final int? dragIndex;
  final List<int> order;
  final List<Stop> baselineStops;
  final bool detailed;
  final bool editMode;
  final bool skipped;
  final Set<int> skippedStops;
  final VoidCallback onOpen;
  final VoidCallback onRevert;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final driveNext = driveNextForPosition(
      order,
      position,
      baselineStops,
      skipped: skippedStops,
    );
    final image = stop.photoUrl ?? placeImageFor(stop.name, tags: stop.tags);
    final decoration = BoxDecoration(
      color: AppColors.surface1,
      border: Border.all(
        color: AppColors.hairline,
        width: AppElevation.hairlineWidth,
      ),
      borderRadius: BorderRadius.circular(AppRadius.card),
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(end: skipped ? 0.5 : 1),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : AppMotion.base,
      curve: AppMotion.easeStandard,
      builder: (context, opacity, child) => Opacity(
        key: ValueKey('result-stop-opacity-$originalIndex'),
        opacity: opacity,
        child: child,
      ),
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
                  dragIndex: dragIndex ?? position,
                  moved: position != originalIndex,
                  onRevert: onRevert,
                  onRemove: onRemove,
                ),
              )
            : Container(
                decoration: decoration,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // D18: the place is seen before it is read about. No
                    // picture for this stop means no band, never a placeholder.
                    if (image != null)
                      StopPicture(
                        key: ValueKey('result-stop-image-$originalIndex'),
                        originalIndex: originalIndex,
                        height: AppMetrics.resultStopImageHeight,
                        image: image,
                        fallbackImage: placeImageFor(
                          stop.name,
                          tags: stop.tags,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppMetrics.padRowX,
                        vertical: AppMetrics.padRowY,
                      ),
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
                            _DetailedPlan(
                              originalIndex: originalIndex,
                              stop: stop,
                            )
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
                  ],
                ),
              ),
      ),
    );
  }
}

/// The same original-index identity follows a picture into detail and back.
/// The image alone flies; card text and the detail's Back control stay put.
class StopPicture extends StatelessWidget {
  const StopPicture({
    super.key,
    required this.originalIndex,
    required this.height,
    required this.image,
    this.fallbackImage,
  });

  final int originalIndex;
  final double height;
  final String? image;
  final String? fallbackImage;

  @override
  Widget build(BuildContext context) {
    return HeroMode(
      enabled: !MediaQuery.disableAnimationsOf(context),
      child: Hero(
        tag: 'stop-picture-$originalIndex',
        child: PlaceholderTile.hero(
          height: height,
          image: image,
          fallbackImage: fallbackImage,
        ),
      ),
    );
  }
}

/// A persistent fallback when an external maps app refuses to open.
class MapsLaunchFailure extends StatelessWidget {
  const MapsLaunchFailure({super.key, required this.coordinates});

  final String coordinates;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Google Maps could not be opened. You can copy the destination coordinates instead.',
        style: AppType.bodySm.copyWith(color: AppColors.inkSubtle),
      ),
      TextButton(
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: coordinates));
          if (!context.mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Coordinates copied')));
        },
        child: Text(
          'Copy destination coordinates',
          style: AppType.bodySm.copyWith(color: AppColors.primary),
        ),
      ),
    ],
  );
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
    required this.dragIndex,
    required this.moved,
    required this.onRevert,
    required this.onRemove,
  });

  final String name;
  final int originalIndex;
  final int position;
  final int dragIndex;
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
          tooltip: 'Delete $name from trip',
          icon: LucideIcons.trash_2,
          color: AppColors.inkSubtle,
          onTap: onRemove,
        ),
        ReorderableDragStartListener(
          key: ValueKey('result-stop-drag-$originalIndex'),
          index: dragIndex,
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
      excludeFromSemantics: true,
      child: Semantics(
        container: true,
        label: tooltip,
        button: true,
        onTap: onTap,
        excludeSemantics: true,
        child: GestureDetector(
          excludeFromSemantics: true,
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
