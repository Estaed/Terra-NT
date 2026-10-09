import 'spacing.dart';

/// Measurements the prototype uses that the token bundle never carried.
///
/// Unlike [AppSpacing], [AppRadius] and [AppType], nothing here transcribes a `.css`
/// file line-for-line — these values are measured off `design/design-reference/Terra
/// NT.dc.html`'s inline styles (button heights, badge/tag/chip/row padding, icon
/// sizes). Keeping them out of the token files preserves those files' own contract:
/// a line-for-line diff against `design/design-system/tokens/`.
class AppMetrics {
  AppMetrics._();

  // Button
  static const buttonHeightLg = 40.0; // hint-size L58, L443, L567
  static const buttonHeightMd = 36.0; // hint-size L661
  static const gapButtonIcon = 6.0; // reconstructed: bundle is missing

  // Component padding the CSS does not carry
  static const padBadgeY = 2.0;
  static const padBadgeX = AppSpacing.xs; // 8
  static const padTagY = 3.0;
  static const padTagX = 9.0;
  static const padChipY = 7.0;
  static const padChipX = AppSpacing.padTabX; // 14
  static const padRowY = 14.0;
  static const padRowX = AppSpacing.md; // 16

  // Gaps
  static const gapTagDot = 5.0;
  static const gapChipIcon = 6.0;
  static const gapRow = 12.0;
  static const gapRowAvatar = 14.0;

  // Dimensions
  static const tagDotSize = 5.0;
  static const avatarSize = 44.0;

  /// Minimum hit target for any interactive control. The prototype paints
  /// several controls smaller than this; they keep their painted size and
  /// gain a transparent target around it.
  static const minTouchTarget = 48.0;

  // Icon ladder. The prototype's full set is 12/13/14/16/18/20/28/32.
  static const iconXxs = 12.0; // Result row next-leg arrow
  static const iconXs = 13.0; // Result row edit actions
  static const iconSm = 14.0; // chip icon
  static const iconMd = 16.0; // button icon, row chevron
  static const iconLg = 18.0; // row leading icon
  static const iconXl = 20.0; // placeholder tile icon
  static const iconXxl = 28.0; // hero tile icon
  static const iconHuge = 32.0; // saved-routes empty state

  // Map foundation
  static const mapRouteDotSize = 8.0;
  static const mapNumberedPinSize = 26.0;
  static const mapPoiPinSize = 30.0;
  static const mapPinBorderWidth = 1.5;
  static const mapPolylineWidth = 3.0;
  static const mapBackdropFitPadding = 26.0;
  static const mapExploreFitPadding = 30.0;
  static const mapResultFitPadding = 28.0;
  // Result can fit a long route into the narrow strip above the top anchor.
  // Its camera must be allowed below the other maps' Australia viewport floor.
  static const mapResultMinZoom = 0.0;
  static const mapTooltipOffset = 8.0;

  // Map camera limits. `CameraConstraint.contain` can only hold the camera
  // inside a box that is bigger than the viewport, and the box shrinks against
  // the viewport as you zoom out. 5 is the lowest zoom at which
  // AppMapVisuals.australiaCameraBounds still exceeds a phone viewport; at 4 it
  // does not, and flutter_map then rejects the camera outright.
  static const mapMinZoom = 5.0;
  static const mapMaxZoom = 19.0;

  /// The shortest strip of map the Result fit will leave itself above the
  /// sheet. At [mapMinZoom] the seeded route is about 305px tall, so a strip
  /// thinner than this cannot hold it and the northern pins fall off the top.
  static const mapResultMinimumStrip = 320.0;

  // Login
  static const loginSidePadding = 28.0;
  static const loginBottomPadding = 40.0;
  static const loginScrimMidpoint = 0.45;
  static const loginScrimOpaquePoint = 0.92;

  // Welcome
  static const welcomeCardSidePadding = 28.0;
  static const welcomeCardVerticalPadding = 24.0;

  // Loading (D18): the brand mark's round badge.
  static const loadingBrandBadgeSize = 88.0;

  // The brand mark above the title on Login and Create account (D18).
  static const authBrandMarkSize = 96.0;

  // Saved Routes
  static const savedRoutesHeaderX = 20.0;
  static const savedRoutesListGap = 10.0;
  static const savedRouteDeleteWidth = 76.0;
  static const savedRouteThumbnailSize = 60.0;
  static const savedRoutesEmptyPadX = 40.0;

  // Result screen
  static const resultSheetMinHeight = 190.0;
  static const resultSheetMidHeight = 430.0;
  static const resultSheetMaxHeight = 700.0;
  static const resultSheetGrabberWidth = 32.0;
  static const resultSegmentRailPadding = 3.0;
  static const resultSegmentRailGap = 4.0;
  static const resultSheetGrabberHeight = 4.0;
  static const resultSheetBottomInset = 0.0;
  static const resultStopListGap = 10.0;
  static const resultStopEditActionGap = 6.0;
  static const resultStopSubtitleGap = 1.0;

  /// The place picture across the top of a Result stop card (D18).
  static const resultStopImageHeight = 112.0;
  static const resultStopContentTopGap = 2.0;
  static const resultStopBadgeSize = 26.0;
  static const resultStopActionVisualSize = 26.0;
  static const resultStopPlanTimeWidth = 58.0;

  /// Edit mode's compact row: one [minTouchTarget] of controls plus a hairline
  /// of breathing room above and below. Reordering only works when the dragged
  /// row is shorter than the list viewport, so this height is load-bearing.
  static const resultStopEditRowHeight = 56.0;

  // Explore, measured from Terra NT.dc.html L389-416.
  static const exploreSearchInset = 20.0;
  static const exploreSearchGap = 8.0;
  static const exploreSearchPaddingY = 11.0;
  static const exploreSearchPaddingX = 14.0;
  static const exploreCardInset = 16.0;
  static const exploreCardPadding = 16.0;
  static const exploreCardGap = 12.0;
  static const exploreCardTextGap = 5.0;
  static const exploreCardMetaGap = 6.0;
  static const exploreCardCloseInset = 10.0;
  static const exploreCardCloseSize = 26.0;
  static const explorePlaceholderSize = 76.0;
  static const exploreMetaSeparatorSize = 3.0;
  static const exploreDescriptionFontSize = 12.5;
  static const exploreDescriptionHeight = 1.4;

  // Animated backdrop car, measured from terra-nt-bg-map.html.
  static const mapCarMarkerWidth = 36.0;
  static const mapCarMarkerHeight = 32.0;
  static const mapCarBobOffset = 1.5;

  // Onboarding shell, measured from Terra NT.dc.html L91-102.
  static const onboardingBackButtonSize = 36.0;
  static const onboardingChromeTop = 20.0;
  static const onboardingChromeSide = 20.0;
  static const onboardingProgressLeft = 68.0;
  static const onboardingProgressGap = 10.0;
  static const onboardingCardTop = 88.0;
  static const onboardingCardBottom = 24.0;
  static const onboardingCardPaddingY = 22.0;
  static const onboardingCardPaddingX = 20.0;
  static const onboardingStepSlideOffsetX = 18.0;

  // The row Loading reserves for its looping progress car (V13).
  static const onboardingProgressCarHeight = 24.0;

  // Map fit padding — the flat pad clears the status bar and whatever floats
  // over the map's top edge too (V19, D15). The search pill's own height,
  // content-box: 2 * exploreSearchPaddingY + iconMd (Terra NT.dc.html L389).
  static const exploreSearchFieldHeight = 38.0;

  /// The shortest strip of map Explore's fit will leave itself under the
  /// status bar and search pill reservation, mirroring
  /// [mapResultMinimumStrip]. With the keyboard open the Scaffold body
  /// shrinks well below a phone's full height; past this point the full
  /// reservation would force the camera below [mapMinZoom], and the clamp
  /// leaves the bounds too big for the viewport — shoving pins off-screen
  /// instead of just under the status bar.
  static const mapExploreMinimumStrip = 280.0;

  // Stop detail screen
  static const stopDetailHeroHeight = 260.0;
  static const stopDetailBackButtonSize = 36.0;
  static const stopDetailContentPadding = 20.0;
  static const stopDetailContentGap = 16.0;
  static const stopDetailInfoGap = 10.0;
  static const stopDetailFooterGap = 12.0;
  static const stopDetailFooterIconMinimumWidth = 160.0;
  static const stopDetailFooterPaddingTop = 16.0;
  static const stopDetailFooterPaddingBottom = 24.0;

  // The rendered car sprite (Task-48, docs/PRD.md D18). assets/images/car.png
  // is 384x187; every size below keeps that aspect, so the sprite is never
  // stretched. It replaced the drawn car and its blob shadow.
  static const carSpriteAspect = 384 / 187;

  /// The car on the map behind Login and Welcome. Wider than the 36x32 marker
  /// slot the backdrop reserves; the glyph overflows that slot, centred on the
  /// route point, so a side-view 4x4 reads as one at phone size.
  static const mapCarSpriteWidth = 56.0;

  /// The car riding the onboarding road and Loading's looping bar. Its height
  /// (about 21.4) stays under [onboardingProgressCarHeight], the row Loading
  /// reserves for the bar, so the car rests on the road without clipping.
  static const progressCarWidth = 44.0;
  static const progressCarHeight = progressCarWidth / carSpriteAspect;

  /// The road the car drives along: a quiet band with a dashed centre line.
  static const progressRoadHeight = 6.0;
  static const progressRoadDashLength = 6.0;
  static const progressRoadDashGap = 5.0;
  static const progressRoadDashThickness = 1.0;
}
