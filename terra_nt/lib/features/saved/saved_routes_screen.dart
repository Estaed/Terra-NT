import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/widgets/bottom_nav.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/elevation.dart';
import '../../core/theme/metrics.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/radius.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/util/swipe_snap.dart';
import '../../data/models/saved_route.dart';
import '../../data/repositories/notifiers.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_icon.dart';
import '../../shared/widgets/placeholder_tile.dart';

/// Saved routes list with a single hand-rolled swipe-to-delete row at a time.
class SavedRoutesScreen extends ConsumerStatefulWidget {
  const SavedRoutesScreen({
    super.key,
    this.onOpenRoute,
    this.onPlanAi,
    this.onTabSelected,
  });

  final ValueChanged<String>? onOpenRoute;
  final VoidCallback? onPlanAi;
  final ValueChanged<int>? onTabSelected;

  @override
  ConsumerState<SavedRoutesScreen> createState() => _SavedRoutesScreenState();
}

class _SavedRoutesScreenState extends ConsumerState<SavedRoutesScreen> {
  String? _openRouteId;
  String? _dragRouteId;
  double _dragStartX = 0;
  double _dragBaseOffset = 0;
  double _offset = 0;
  bool _dragging = false;
  bool _moved = false;

  @override
  void initState() {
    super.initState();
    unawaited(ref.read(savedRoutesNotifierProvider.notifier).load());
  }

  void _beginDrag(String routeId, DragDownDetails details) {
    setState(() {
      _dragRouteId = routeId;
      _dragStartX = details.globalPosition.dx;
      _dragBaseOffset = _openRouteId == routeId ? _offset : 0;
      _offset = _dragBaseOffset;
      _dragging = true;
      _moved = false;
    });
  }

  void _updateDrag(String routeId, DragUpdateDetails details) {
    if (_dragRouteId != routeId) return;
    final delta = details.globalPosition.dx - _dragStartX;
    setState(() {
      _moved = _moved || didMove(delta);
      _offset = clampOffset(_dragBaseOffset + delta);
    });
  }

  void _endDrag(String routeId) {
    if (_dragRouteId != routeId) return;
    final open = isOpenAfterRelease(_offset);
    setState(() {
      _openRouteId = open ? routeId : null;
      _offset = open ? -AppMetrics.savedRouteDeleteWidth : 0;
      _dragRouteId = null;
      _dragging = false;
      _moved = false;
    });
  }

  void _closeOpenRow() {
    setState(() {
      _openRouteId = null;
      _dragRouteId = null;
      _offset = 0;
      _dragging = false;
    });
  }

  Future<void> _handleRouteTap(SavedRoute route) async {
    if (_moved) {
      _moved = false;
      return;
    }
    if (_openRouteId == route.id && _offset != 0) {
      _closeOpenRow();
      return;
    }
    await ref
        .read(itineraryNotifierProvider.notifier)
        .loadForSavedRoute(route.id);
    if (mounted) widget.onOpenRoute?.call(route.id);
  }

  void _deleteRoute(String routeId) {
    _closeOpenRow();
    unawaited(ref.read(savedRoutesNotifierProvider.notifier).delete(routeId));
  }

  void _selectTab(int index) {
    if (index == BottomNav.planAiIndex) {
      widget.onPlanAi?.call();
    }
    widget.onTabSelected?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    final routes = ref.watch(savedRoutesNotifierProvider);
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppMetrics.savedRoutesHeaderX,
                AppSpacing.lg,
                AppMetrics.savedRoutesHeaderX,
                AppSpacing.md,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Saved Routes',
                  style: AppType.headline.copyWith(color: AppColors.ink),
                ),
              ),
            ),
            Expanded(
              child: routes.isEmpty
                  ? _SavedRoutesEmptyState(
                      onPlanAi: () => _selectTab(BottomNav.planAiIndex),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppMetrics.savedRoutesHeaderX,
                        0,
                        AppMetrics.savedRoutesHeaderX,
                        AppSpacing.lg,
                      ),
                      itemCount: routes.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppMetrics.savedRoutesListGap),
                      itemBuilder: (context, index) {
                        final route = routes[index];
                        final active =
                            _dragRouteId == route.id ||
                            _openRouteId == route.id;
                        final offset = active ? _offset : 0.0;
                        return _SavedRouteCard(
                          route: route,
                          offset: offset,
                          dragging: _dragging && _dragRouteId == route.id,
                          settleDuration: AppMotion.savedRouteSwipeSettle,
                          onDragDown: (details) =>
                              _beginDrag(route.id, details),
                          onDragUpdate: (details) =>
                              _updateDrag(route.id, details),
                          onDragEnd: () => _endDrag(route.id),
                          onTap: () => _handleRouteTap(route),
                          onDelete: () => _deleteRoute(route.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedRouteCard extends StatelessWidget {
  const _SavedRouteCard({
    required this.route,
    required this.offset,
    required this.dragging,
    required this.settleDuration,
    required this.onDragDown,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onTap,
    required this.onDelete,
  });

  final SavedRoute route;
  final double offset;
  final bool dragging;
  final Duration settleDuration;
  final GestureDragDownCallback onDragDown;
  final GestureDragUpdateCallback onDragUpdate;
  final VoidCallback onDragEnd;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: AppMetrics.savedRouteDeleteWidth,
                child: GestureDetector(
                  key: ValueKey('delete-route-${route.id}'),
                  onTap: onDelete,
                  child: const ColoredBox(
                    color: AppColors.tagRed,
                    child: Center(
                      child: AppIcon(
                        LucideIcons.trash_2,
                        size: AppMetrics.iconLg,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          TweenAnimationBuilder<double>(
            duration: dragging ? Duration.zero : settleDuration,
            tween: Tween<double>(end: offset),
            curve: AppMotion.easeOut,
            builder: (context, value, child) => Transform.translate(
              key: ValueKey('saved-route-row-${route.id}'),
              offset: Offset(value, 0),
              child: child,
            ),
            child: GestureDetector(
              key: ValueKey('saved-route-${route.id}'),
              behavior: HitTestBehavior.opaque,
              onHorizontalDragDown: onDragDown,
              onHorizontalDragUpdate: onDragUpdate,
              onHorizontalDragEnd: (_) => onDragEnd(),
              onHorizontalDragCancel: onDragEnd,
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.all(AppMetrics.padRowY),
                decoration: BoxDecoration(
                  color: AppColors.surface1,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: AppColors.hairline,
                    width: AppElevation.hairlineWidth,
                  ),
                ),
                child: Row(
                  children: [
                    const PlaceholderTile.square(
                      size: AppMetrics.savedRouteThumbnailSize,
                      icon: LucideIcons.map,
                    ),
                    const SizedBox(width: AppMetrics.gapRow),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            route.title,
                            style: AppType.titleApp.copyWith(
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            route.meta,
                            style: AppType.caption.copyWith(
                              color: AppColors.inkSubtle,
                            ),
                          ),
                          Text(
                            route.dateLabel,
                            style: AppType.captionApp.copyWith(
                              color: AppColors.inkTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppMetrics.gapRow),
                    const AppIcon(
                      LucideIcons.chevron_right,
                      size: AppMetrics.iconMd,
                      color: AppColors.inkTertiary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedRoutesEmptyState extends StatelessWidget {
  const _SavedRoutesEmptyState({required this.onPlanAi});

  final VoidCallback onPlanAi;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppMetrics.savedRoutesEmptyPadX,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppIcon(
              LucideIcons.bookmark,
              key: ValueKey('saved-routes-empty-bookmark'),
              size: AppMetrics.iconHuge,
              color: AppColors.inkTertiary,
            ),
            const SizedBox(height: AppMetrics.gapRowAvatar),
            Text(
              'No saved routes yet',
              textAlign: TextAlign.center,
              style: AppType.cardTitle.copyWith(color: AppColors.ink),
            ),
            const SizedBox(height: AppMetrics.gapRowAvatar),
            Text(
              "Generate an itinerary with Plan AI and it'll show up here.",
              textAlign: TextAlign.center,
              style: AppType.bodySm.copyWith(color: AppColors.inkSubtle),
            ),
            const SizedBox(height: AppMetrics.gapRowAvatar),
            AppButton(
              onPressed: onPlanAi,
              child: const Text('Plan Your First Route'),
            ),
          ],
        ),
      ),
    );
  }
}
