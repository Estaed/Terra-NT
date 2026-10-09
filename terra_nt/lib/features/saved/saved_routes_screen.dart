import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../data/seed/place_images.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_icon.dart';
import '../../shared/widgets/app_text_input.dart';
import '../../shared/widgets/entrance.dart';
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
    if (open && _openRouteId != routeId) {
      unawaited(HapticFeedback.lightImpact());
    }
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

  void _handleRouteTap(SavedRoute route) {
    if (_moved) {
      _moved = false;
      return;
    }
    if (_openRouteId == route.id && _offset != 0) {
      _closeOpenRow();
      return;
    }
    ref.read(itineraryNotifierProvider.notifier).openSavedRoute(route);
    widget.onOpenRoute?.call(route.id);
  }

  void _deleteRoute(String routeId) {
    unawaited(HapticFeedback.lightImpact());
    _closeOpenRow();
    unawaited(ref.read(savedRoutesNotifierProvider.notifier).delete(routeId));
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          persist: false,
          backgroundColor: AppColors.bgMenu,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
            side: const BorderSide(
              color: AppColors.hairlineStrong,
              width: AppElevation.hairlineWidth,
            ),
          ),
          content: Text(
            'Route deleted',
            style: AppType.bodySm.copyWith(color: AppColors.ink),
          ),
          action: SnackBarAction(
            label: 'Undo',
            textColor: AppColors.primaryHover,
            onPressed: () {
              if (!mounted) return;
              unawaited(
                ref
                    .read(savedRoutesNotifierProvider.notifier)
                    .undoDelete(routeId),
              );
            },
          ),
        ),
      );
  }

  Future<void> _routeAction(SavedRoute route, _RouteAction action) async {
    _closeOpenRow();
    final notifier = ref.read(savedRoutesNotifierProvider.notifier);
    switch (action) {
      case _RouteAction.rename:
        final title = await showDialog<String>(
          context: context,
          builder: (_) => _RenameRouteDialog(title: route.title),
        );
        if (!mounted || title == null) return;
        await notifier.rename(route.id, title);
      case _RouteAction.moveUp:
        await notifier.moveUp(route.id);
      case _RouteAction.moveDown:
        await notifier.moveDown(route.id);
      case _RouteAction.delete:
        _deleteRoute(route.id);
    }
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
    // The tab shell keeps every tab built. Keying the entrances on whether
    // this tab is shown replays them when the user arrives, rather than
    // letting them run while the tab is hidden (`docs/PRD.md` D18).
    final shown = Visibility.of(context);
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
                      key: ValueKey('saved-routes-empty-shown-$shown'),
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
                        // Keyed by slot, not route: deleting a card must not
                        // replay the entrance of the ones that move up.
                        return Entrance(
                          key: ValueKey('saved-route-entrance-$shown-$index'),
                          index: index,
                          child: _SavedRouteCard(
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
                            canMoveUp: index > 0,
                            canMoveDown: index < routes.length - 1,
                            onMenuOpened: _closeOpenRow,
                            onAction: (action) =>
                                unawaited(_routeAction(route, action)),
                          ),
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
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMenuOpened,
    required this.onAction,
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
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onMenuOpened;
  final ValueChanged<_RouteAction> onAction;

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
                child: Semantics(
                  button: true,
                  label: 'Delete ${route.title}',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: PlaceholderTile.hero(
                        height: AppMetrics.resultStopImageHeight,
                        icon: LucideIcons.map,
                        image: savedRouteCoverFor(route),
                      ),
                    ),
                    const SizedBox(height: AppMetrics.gapRow),
                    Row(
                      children: [
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
                                  color: AppColors.inkSubtle,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppMetrics.gapRow),
                        PopupMenuButton<_RouteAction>(
                          key: ValueKey('route-menu-${route.id}'),
                          tooltip: 'Route options for ${route.title}',
                          color: AppColors.bgMenu,
                          elevation: 0,
                          surfaceTintColor: AppElevation.level0Bg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            side: const BorderSide(
                              color: AppColors.hairlineStrong,
                              width: AppElevation.hairlineWidth,
                            ),
                          ),
                          onOpened: onMenuOpened,
                          onSelected: onAction,
                          itemBuilder: (_) => [
                            _menuItem(_RouteAction.rename, 'Rename'),
                            _menuItem(
                              _RouteAction.moveUp,
                              'Move up',
                              enabled: canMoveUp,
                            ),
                            _menuItem(
                              _RouteAction.moveDown,
                              'Move down',
                              enabled: canMoveDown,
                            ),
                            // Swipe-to-delete is invisible to a screen reader;
                            // the menu is its reachable path.
                            _menuItem(_RouteAction.delete, 'Delete'),
                          ],
                          icon: const AppIcon(
                            LucideIcons.ellipsis,
                            size: AppMetrics.iconLg,
                            color: AppColors.inkSubtle,
                          ),
                        ),
                      ],
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

  PopupMenuItem<_RouteAction> _menuItem(
    _RouteAction action,
    String label, {
    bool enabled = true,
  }) => PopupMenuItem(
    value: action,
    enabled: enabled,
    height: AppMetrics.minTouchTarget,
    child: Text(
      label,
      style: AppType.bodySm.copyWith(
        color: enabled ? AppColors.ink : AppColors.inkTertiary,
      ),
    ),
  );
}

enum _RouteAction { rename, moveUp, moveDown, delete }

class _RenameRouteDialog extends StatefulWidget {
  const _RenameRouteDialog({required this.title});

  final String title;

  @override
  State<_RenameRouteDialog> createState() => _RenameRouteDialogState();
}

class _RenameRouteDialogState extends State<_RenameRouteDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.title);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AppColors.bgMenu,
    elevation: 0,
    surfaceTintColor: AppElevation.level0Bg,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.panel),
      side: const BorderSide(
        color: AppColors.hairlineStrong,
        width: AppElevation.hairlineWidth,
      ),
    ),
    title: Text(
      'Rename route',
      style: AppType.cardTitle.copyWith(color: AppColors.ink),
    ),
    content: AppTextInput(
      label: 'Route name',
      controller: _controller,
      onChanged: (_) => setState(() {}),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(
          'Cancel',
          style: AppType.button.copyWith(color: AppColors.inkSubtle),
        ),
      ),
      TextButton(
        onPressed: _controller.text.trim().isEmpty
            ? null
            : () => Navigator.of(context).pop(_controller.text.trim()),
        child: Text(
          'Save',
          style: AppType.button.copyWith(
            color: _controller.text.trim().isEmpty
                ? AppColors.inkTertiary
                : AppColors.primaryHover,
          ),
        ),
      ),
    ],
  );
}

class _SavedRoutesEmptyState extends StatelessWidget {
  const _SavedRoutesEmptyState({super.key, required this.onPlanAi});

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
            const Entrance(
              child: AppIcon(
                LucideIcons.bookmark,
                key: ValueKey('saved-routes-empty-bookmark'),
                size: AppMetrics.iconHuge,
                color: AppColors.inkTertiary,
              ),
            ),
            const SizedBox(height: AppMetrics.gapRowAvatar),
            Entrance(
              index: 1,
              child: Text(
                'No saved routes yet',
                textAlign: TextAlign.center,
                style: AppType.cardTitle.copyWith(color: AppColors.ink),
              ),
            ),
            const SizedBox(height: AppMetrics.gapRowAvatar),
            Entrance(
              index: 2,
              child: Text(
                "Generate an itinerary with Plan AI and it'll show up here.",
                textAlign: TextAlign.center,
                style: AppType.bodySm.copyWith(color: AppColors.inkSubtle),
              ),
            ),
            const SizedBox(height: AppMetrics.gapRowAvatar),
            Entrance(
              index: 3,
              child: AppButton(
                onPressed: onPlanAi,
                child: const Text('Plan Your First Route'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
