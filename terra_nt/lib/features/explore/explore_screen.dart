import 'dart:math' as math;

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
import '../../core/util/maps_url.dart';
import '../../core/util/poi_filter.dart';
import '../../core/util/tag_colors.dart';
import '../../data/models/poi.dart';
import '../../data/models/stop.dart';
import '../../data/repositories/notifiers.dart';
import '../../data/seed/place_images.dart';
import '../../shared/map/map_markers.dart';
import '../../shared/map/terra_map.dart';
import '../../shared/widgets/app_icon.dart';
import '../../shared/widgets/placeholder_tile.dart';
import '../../shared/widgets/tag_dot.dart';

typedef ExploreMapsLauncher = Future<bool> Function(Uri url);

/// Map browsing and directions for the local places of interest.
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({
    super.key,
    this.mapController,
    this.launcher = launchUrl,
  });

  /// Test injection; the screen owns the controller in normal app use.
  final MapController? mapController;
  final ExploreMapsLauncher launcher;

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _searchController;
  final _searchFocusNode = FocusNode();
  late final MapController _mapController;
  late final AnimationController _cameraAnimation;
  final _cardKey = GlobalKey();
  final _searchKey = GlobalKey();
  Offset? _cameraStart;
  Offset? _cameraEnd;
  String? _cameraPoiId;
  Size? _cameraViewport;
  EdgeInsets? _cameraInsets;
  bool? _cameraReducedMotion;
  double? _cameraTextScale;
  int _cameraRequest = 0;

  @override
  void initState() {
    super.initState();
    _mapController = widget.mapController ?? MapController();
    _cameraAnimation = AnimationController(
      vsync: this,
      duration: AppMotion.entrance,
    )..addListener(_moveCamera);
    _searchController = TextEditingController(
      text: ref.read(exploreNotifierProvider).searchQuery,
    );
    _searchFocusNode.addListener(_onSearchFocusChanged);
  }

  @override
  void dispose() {
    _cameraAnimation.dispose();
    if (widget.mapController == null) _mapController.dispose();
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Whether the keyboard is up decides what system Back does, so the screen
  /// rebuilds when focus moves.
  void _onSearchFocusChanged() {
    if (mounted) setState(() {});
  }

  void _setSearchQuery(String query) {
    final notifier = ref.read(exploreNotifierProvider.notifier);
    notifier.setSearchQuery(query);
    if (query.trim().isEmpty) {
      notifier.selectPoi(null);
      return;
    }
    final match = singleSearchMatch(ref.read(poiProvider), query);
    if (match != null) notifier.selectPoi(match.id);
  }

  void _clearSearch() {
    _searchController.clear();
    _setSearchQuery('');
  }

  void _selectPoi(Poi poi) {
    // Retapping a place brings it back into view after a manual pan.
    _cameraPoiId = null;
    ref.read(exploreNotifierProvider.notifier).selectPoi(poi.id);
  }

  void _moveCamera() {
    final start = _cameraStart;
    final end = _cameraEnd;
    if (start == null || end == null || _cameraAnimation.value == 0) return;
    final camera = _mapController.camera;
    final progress = AppMotion.easeEmphasized.transform(_cameraAnimation.value);
    _mapController.move(
      camera.unprojectAtZoom(Offset.lerp(start, end, progress)!),
      camera.zoom,
    );
  }

  /// Measure the actual card and search overlay after layout. The selected pin
  /// lands halfway through the remaining strip, even with the keyboard open.
  void _queueCamera(Poi? poi, Size viewport, EdgeInsets insets) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    if (_cameraPoiId == poi?.id &&
        _cameraViewport == viewport &&
        _cameraInsets == insets &&
        _cameraReducedMotion == reducedMotion &&
        _cameraTextScale == textScale) {
      return;
    }
    _cameraPoiId = poi?.id;
    _cameraViewport = viewport;
    _cameraInsets = insets;
    _cameraReducedMotion = reducedMotion;
    _cameraTextScale = textScale;
    _cameraAnimation.stop();
    final request = ++_cameraRequest;
    if (poi == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || request != _cameraRequest) return;
      final card = _cardKey.currentContext?.findRenderObject() as RenderBox?;
      final search =
          _searchKey.currentContext?.findRenderObject() as RenderBox?;
      if (card == null || search == null) return;
      final top =
          insets.top + AppMetrics.exploreSearchInset + search.size.height;
      final bottom =
          viewport.height -
          insets.bottom -
          AppMetrics.exploreCardInset -
          card.size.height -
          AppMetrics.exploreCardGap;
      final target = Offset(viewport.width / 2, (top + bottom) / 2);
      final camera = _mapController.camera;
      final point = LatLng(poi.lat, poi.lng);
      // screenOffsetToLatLng also accounts for a user-rotated map.
      _cameraStart = camera.projectAtZoom(camera.center);
      _cameraEnd =
          camera.projectAtZoom(point) +
          camera.projectAtZoom(camera.center) -
          camera.projectAtZoom(camera.screenOffsetToLatLng(target));
      if (reducedMotion) {
        _mapController.move(camera.unprojectAtZoom(_cameraEnd!), camera.zoom);
      } else {
        _cameraAnimation.forward(from: 0);
      }
    });
  }

  Future<void> _navigate(Poi poi) async {
    // The existing directions helper takes a Stop; only its coordinates enter
    // the URL. No itinerary or persistence state is changed by this action.
    final url = singleDestinationUrl(
      Stop(
        name: poi.name,
        subtitle: '',
        lat: poi.lat,
        lng: poi.lng,
        hours: '',
        duration: '',
        aiNote: '',
        tags: [poi.tag],
        detailedPlan: const [],
      ),
    );
    if (url != null) await widget.launcher(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exploreNotifierProvider);
    final pois = ref.watch(poiProvider);
    final filteredPois = filterPois(pois, state.searchQuery);
    final selectedPoi = switch (state.selectedPoiId) {
      final id? => filteredPois.where((poi) => poi.id == id).firstOrNull,
      null => null,
    };
    final allBounds = poiBounds(pois);
    final safeArea = MediaQuery.paddingOf(context);

    return PopScope(
      // With the keyboard up, Back closes it instead of leaving Explore.
      canPop: !_searchFocusNode.hasFocus,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _searchFocusNode.unfocus();
      },
      child: Scaffold(
        key: const ValueKey('explore-screen'),
        backgroundColor: AppColors.surface1,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final viewport = constraints.biggest;
            _queueCamera(selectedPoi, viewport, safeArea);
            final searchHeight = math.max(
              AppMetrics.minTouchTarget,
              AppMetrics.exploreSearchPaddingY * 2 +
                  MediaQuery.textScalerOf(context)
                          .scale(AppType.bodySm.fontSize!) *
                      (AppType.bodySm.height ?? 1),
            );
            final cardMaxHeight = math.max(
              0.0,
              viewport.height -
                  safeArea.vertical -
                  AppMetrics.exploreSearchInset -
                  searchHeight -
                  AppMetrics.exploreCardInset -
                  AppMetrics.exploreCardGap * 2 -
                  AppMetrics.minTouchTarget,
            );
            return Stack(
              children: [
                Positioned.fill(
                  child: Listener(
                    onPointerDown: (_) {
                      ++_cameraRequest;
                      _cameraAnimation.stop();
                    },
                    child: TerraMap(
                      controller: _mapController,
                      interactive: true,
                      bounds: allBounds,
                      fitPadding: TerraMap.exploreFitPaddingFor(
                        safeArea.top,
                        viewport.height,
                      ),
                      controlsPadding: EdgeInsets.only(
                        top: safeArea.top + AppMetrics.exploreSearchInset,
                        bottom: safeArea.bottom,
                      ),
                      topOverlay: Padding(
                        key: _searchKey,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppMetrics.exploreSearchInset,
                        ),
                        child: _SearchPill(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          onChanged: _setSearchQuery,
                        ),
                      ),
                      markers: [
                        for (final poi in filteredPois)
                          TerraMapMarker(
                            key: ValueKey('explore-marker-${poi.id}'),
                            point: LatLng(poi.lat, poi.lng),
                            tooltip: poi.name,
                            onTap: () => _selectPoi(poi),
                            child: PoiPinMarker(
                              placeName: poi.name,
                              selected: poi.id == selectedPoi?.id,
                              accent: tagColor(poi.tag),
                              tag: poi.tag,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (filteredPois.isEmpty)
                  _EmptySearchState(onClear: _clearSearch),
                Positioned(
                  left: AppMetrics.exploreCardInset,
                  right: AppMetrics.exploreCardInset,
                  bottom: AppMetrics.exploreCardInset + safeArea.bottom,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: cardMaxHeight),
                    child: _PoiCardPanel(
                      poi: selectedPoi,
                      cardKey: _cardKey,
                      onNavigate: _navigate,
                      onClose: () => ref
                          .read(exploreNotifierProvider.notifier)
                          .selectPoi(null),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SearchPill extends StatelessWidget {
  const _SearchPill({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  /// The pill paints at its measured height; a transparent target below it
  /// brings the field up to the minimum thumb size.
  @override
  Widget build(BuildContext context) => GestureDetector(
    key: const ValueKey('explore-search-target'),
    behavior: HitTestBehavior.opaque,
    onTap: focusNode.requestFocus,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppMetrics.minTouchTarget),
      child: Align(alignment: Alignment.topCenter, child: _pill()),
    ),
  );

  Widget _pill() => Container(
    key: const ValueKey('explore-search-pill'),
    decoration: BoxDecoration(
      color: AppColors.surface1,
      border: Border.all(
        color: AppColors.hairline,
        width: AppElevation.hairlineWidth,
      ),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      boxShadow: AppElevation.shadowOverlay,
    ),
    padding: const EdgeInsets.symmetric(
      horizontal: AppMetrics.exploreSearchPaddingX,
      vertical: AppMetrics.exploreSearchPaddingY,
    ),
    child: Row(
      children: [
        const AppIcon(
          LucideIcons.search,
          size: AppMetrics.iconMd,
          color: AppColors.inkTertiary,
        ),
        const SizedBox(width: AppMetrics.exploreSearchGap),
        Expanded(
          child: TextField(
            key: const ValueKey('explore-search-field'),
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            style: AppType.bodySm.copyWith(color: AppColors.ink),
            decoration: InputDecoration(
              hintText: 'Search the Territory',
              hintStyle: AppType.bodySm.copyWith(color: AppColors.inkTertiary),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    ),
  );
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppIcon(
          LucideIcons.search_x,
          key: ValueKey('explore-empty-search-icon'),
          size: AppMetrics.iconXxl,
          color: AppColors.inkTertiary,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'No places match your search.',
          style: AppType.bodySm.copyWith(color: AppColors.inkTertiary),
        ),
        TextButton(
          key: const ValueKey('explore-clear-search'),
          onPressed: onClear,
          style: TextButton.styleFrom(
            minimumSize: const Size(
              AppMetrics.minTouchTarget,
              AppMetrics.minTouchTarget,
            ),
          ),
          child: Text(
            'Clear search',
            style: AppType.buttonApp.copyWith(
              color: AppColors.inkSubtle,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.inkSubtle,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Keep one surface while its contents crossfade. A closing card retains its
/// last place only for the exit animation and cannot receive taps.
class _PoiCardPanel extends StatefulWidget {
  const _PoiCardPanel({
    required this.poi,
    required this.cardKey,
    required this.onClose,
    required this.onNavigate,
  });

  final Poi? poi;
  final GlobalKey cardKey;
  final VoidCallback onClose;
  final Future<void> Function(Poi) onNavigate;

  @override
  State<_PoiCardPanel> createState() => _PoiCardPanelState();
}

class _PoiCardPanelState extends State<_PoiCardPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;
  late final Animation<double> _progress;
  Poi? _displayedPoi;
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    _displayedPoi = widget.poi;
    _animation = AnimationController(vsync: this, duration: AppMotion.entrance);
    _progress = _animation.drive(CurveTween(curve: AppMotion.easeEmphasized));
  }

  void _update() {
    if (widget.poi != null) _displayedPoi = widget.poi;
    if (_reducedMotion) {
      _animation.value = widget.poi == null ? 0 : 1;
    } else if (widget.poi != null) {
      if (_animation.status != AnimationStatus.forward &&
          !_animation.isCompleted) {
        _animation.forward();
      }
    } else if (_animation.status != AnimationStatus.reverse &&
        !_animation.isDismissed) {
      _animation.reverse();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    _update();
  }

  @override
  void didUpdateWidget(_PoiCardPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _update();
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final poi = _displayedPoi;
    if (poi == null) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        if (_animation.isDismissed && widget.poi == null) {
          return const SizedBox.shrink();
        }
        return IgnorePointer(
          ignoring: widget.poi == null,
          child: SlideTransition(
            position: _progress.drive(
              Tween(begin: const Offset(0, 1), end: Offset.zero),
            ),
            child: FadeTransition(opacity: _progress, child: child),
          ),
        );
      },
      child: _PoiInfoCard(
        key: widget.cardKey,
        poi: poi,
        onClose: widget.onClose,
        onNavigate: () => widget.onNavigate(poi),
      ),
    );
  }
}

class _PoiInfoCard extends StatelessWidget {
  const _PoiInfoCard({
    super.key,
    required this.poi,
    required this.onClose,
    required this.onNavigate,
  });

  final Poi poi;
  final VoidCallback onClose;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('explore-poi-card'),
    decoration: BoxDecoration(
      color: AppColors.surface1,
      borderRadius: BorderRadius.circular(AppRadius.card),
      border: Border.all(
        color: AppColors.hairlineStrong,
        width: AppElevation.hairlineWidth,
      ),
      boxShadow: AppElevation.shadowOverlay,
    ),
    clipBehavior: Clip.antiAlias,
    child: Stack(
      children: [
        SingleChildScrollView(
          child: AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : AppMotion.base,
            switchInCurve: AppMotion.easeOut,
            switchOutCurve: AppMotion.easeOut,
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topCenter,
              children: [
                for (final child in previous)
                  IgnorePointer(child: ExcludeSemantics(child: child)),
                ?current,
              ],
            ),
            child: Padding(
              key: ValueKey(poi.id),
              padding: const EdgeInsets.all(AppMetrics.exploreCardPadding),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PlaceholderTile.square(
                    size: AppMetrics.explorePlaceholderSize,
                    image:
                        poi.photoUrl ??
                        placeImageFor(poi.name, tags: [poi.tag]),
                  ),
                  const SizedBox(width: AppMetrics.exploreCardGap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            right: AppMetrics.exploreCardCloseSize,
                          ),
                          child: Text(
                            poi.name,
                            style: AppType.body.copyWith(
                              color: AppColors.ink,
                              fontWeight: AppWeights.semibold,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppMetrics.exploreCardTextGap),
                        // One line at the design's text size; it runs onto a
                        // second line rather than clipping when text is scaled up.
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          runSpacing: AppMetrics.exploreCardTextGap,
                          children: [
                            const AppIcon(
                              LucideIcons.star,
                              size: AppMetrics.iconXxs,
                              color: AppColors.inkSubtle,
                            ),
                            const SizedBox(
                              width: AppMetrics.exploreCardMetaGap,
                            ),
                            Text(
                              poi.rating,
                              style: AppType.caption.copyWith(
                                color: AppColors.inkSubtle,
                              ),
                            ),
                            const SizedBox(
                              width: AppMetrics.exploreCardMetaGap,
                            ),
                            Container(
                              width: AppMetrics.exploreMetaSeparatorSize,
                              height: AppMetrics.exploreMetaSeparatorSize,
                              decoration: const BoxDecoration(
                                color: AppColors.hairlineStrong,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(
                              width: AppMetrics.exploreCardMetaGap,
                            ),
                            TagDot(color: tagColor(poi.tag), label: poi.tag),
                          ],
                        ),
                        const SizedBox(height: AppMetrics.exploreCardTextGap),
                        Text(
                          poi.description,
                          style: AppType.bodySm.copyWith(
                            color: AppColors.inkMuted,
                            fontSize: AppMetrics.exploreDescriptionFontSize,
                            height: AppMetrics.exploreDescriptionHeight,
                          ),
                        ),
                        TextButton.icon(
                          key: const ValueKey('explore-poi-navigate'),
                          onPressed: onNavigate,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.ink,
                            minimumSize: const Size(
                              AppMetrics.minTouchTarget,
                              AppMetrics.minTouchTarget,
                            ),
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerLeft,
                          ),
                          icon: const AppIcon(
                            LucideIcons.navigation,
                            size: AppMetrics.iconSm,
                            color: AppColors.ink,
                          ),
                          label: Text('Navigate', style: AppType.buttonApp),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // The close target stays fixed while the card content scrolls.
        Positioned(
          top: 0,
          right: 0,
          child: Semantics(
            label: 'Close',
            button: true,
            onTap: onClose,
            excludeSemantics: true,
            child: GestureDetector(
              excludeFromSemantics: true,
              key: const ValueKey('explore-poi-close-target'),
              behavior: HitTestBehavior.opaque,
              onTap: onClose,
              child: SizedBox(
                width: AppMetrics.minTouchTarget,
                height: AppMetrics.minTouchTarget,
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(
                      AppMetrics.exploreCardCloseInset,
                    ),
                    child: SizedBox(
                      width: AppMetrics.exploreCardCloseSize,
                      height: AppMetrics.exploreCardCloseSize,
                      child: IconButton(
                        key: const ValueKey('explore-poi-close'),
                        onPressed: onClose,
                        padding: EdgeInsets.zero,
                        icon: const AppIcon(
                          LucideIcons.x,
                          size: AppMetrics.iconXs,
                          color: AppColors.inkSubtle,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surface2,
                          shape: const CircleBorder(
                            side: BorderSide(
                              color: AppColors.hairline,
                              width: AppElevation.hairlineWidth,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
