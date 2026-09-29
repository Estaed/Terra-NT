import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/elevation.dart';
import '../../core/theme/metrics.dart';
import '../../core/theme/radius.dart';
import '../../core/theme/typography.dart';
import '../../core/util/poi_filter.dart';
import '../../core/util/tag_colors.dart';
import '../../data/models/poi.dart';
import '../../data/repositories/notifiers.dart';
import '../../data/seed/place_images.dart';
import '../../shared/map/map_markers.dart';
import '../../shared/map/terra_map.dart';
import '../../shared/widgets/app_icon.dart';
import '../../shared/widgets/placeholder_tile.dart';
import '../../shared/widgets/tag_dot.dart';

/// Read-only map browsing for the eight seeded places of interest.
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key, this.mapController});

  /// Test injection only; [TerraMap] owns its controller in normal app use.
  final MapController? mapController;

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  late final TextEditingController _searchController;
  final _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(exploreNotifierProvider).searchQuery,
    );
    _searchFocusNode.addListener(_onSearchFocusChanged);
  }

  @override
  void dispose() {
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
    ref.read(exploreNotifierProvider.notifier).setSearchQuery(query);
  }

  void _clearSearch() {
    _searchController.clear();
    _setSearchQuery('');
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
    // The Scaffold body's own height once the keyboard has resized it —
    // the same effective viewport CameraFit lays the bounds out inside.
    final bodyHeight =
        MediaQuery.sizeOf(context).height - MediaQuery.viewInsetsOf(context).bottom;

    return PopScope(
      // With the keyboard up, Back closes it instead of leaving Explore.
      canPop: !_searchFocusNode.hasFocus,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _searchFocusNode.unfocus();
      },
      child: Scaffold(
        key: const ValueKey('explore-screen'),
        backgroundColor: AppColors.surface1,
        body: Stack(
          children: [
            Positioned.fill(
              child: TerraMap(
                controller: widget.mapController,
                interactive: true,
                bounds: allBounds,
                fitPadding: TerraMap.exploreFitPaddingFor(
                  safeArea.top,
                  bodyHeight,
                ),
                controlsPadding: EdgeInsets.only(
                  top: safeArea.top + AppMetrics.exploreSearchInset,
                  bottom: safeArea.bottom,
                ),
                topOverlay: Padding(
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
                      onTap: () => ref
                          .read(exploreNotifierProvider.notifier)
                          .selectPoi(poi.id),
                      child: PoiPinMarker(
                        selected: poi.id == selectedPoi?.id,
                        accent: tagColor(poi.tag),
                      ),
                    ),
                ],
              ),
            ),
            if (filteredPois.isEmpty) _EmptySearchState(onClear: _clearSearch),
            if (selectedPoi != null)
              Positioned(
                left: AppMetrics.exploreCardInset,
                right: AppMetrics.exploreCardInset,
                bottom: AppMetrics.exploreCardInset + safeArea.bottom,
                child: _PoiInfoCard(
                  poi: selectedPoi,
                  onClose: () => ref
                      .read(exploreNotifierProvider.notifier)
                      .selectPoi(null),
                ),
              ),
          ],
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

class _PoiInfoCard extends StatelessWidget {
  const _PoiInfoCard({required this.poi, required this.onClose});

  final Poi poi;
  final VoidCallback onClose;

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
    child: Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppMetrics.exploreCardPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PlaceholderTile.square(
                size: AppMetrics.explorePlaceholderSize,
                image: poi.photoUrl ?? placeImageFor(poi.name, tags: [poi.tag]),
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
                        const SizedBox(width: AppMetrics.exploreCardMetaGap),
                        Text(
                          poi.rating,
                          style: AppType.caption.copyWith(
                            color: AppColors.inkSubtle,
                          ),
                        ),
                        const SizedBox(width: AppMetrics.exploreCardMetaGap),
                        Container(
                          width: AppMetrics.exploreMetaSeparatorSize,
                          height: AppMetrics.exploreMetaSeparatorSize,
                          decoration: const BoxDecoration(
                            color: AppColors.hairlineStrong,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppMetrics.exploreCardMetaGap),
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
                  ],
                ),
              ),
            ],
          ),
        ),
        // The circle keeps its painted size in the same corner; the thumb-sized
        // target around it reaches into the card.
        Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
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
      ],
    ),
  );
}
