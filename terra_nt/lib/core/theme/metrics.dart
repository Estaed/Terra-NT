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

  // Icon ladder. The prototype's full set is 12/13/14/16/18/20/28/32; these five
  // are the sizes Task-02 needs. Names are pre-allocated on the full ladder so
  // iconXxs (12), iconXs (13) and iconHuge (32) slot in later without renaming.
  static const iconSm = 14.0; // chip icon
  static const iconMd = 16.0; // button icon, row chevron
  static const iconLg = 18.0; // row leading icon
  static const iconXl = 20.0; // placeholder tile icon
  static const iconXxl = 28.0; // hero tile icon
  static const iconHuge = 32.0; // saved-routes empty state

  // Map foundation
  static const mapRouteDotSize = 8.0;
  static const mapRouteDotRingWidth = 3.0;
  static const mapNumberedPinSize = 26.0;
  static const mapPoiPinSize = 30.0;
  static const mapPinBorderWidth = 1.5;
  static const mapPolylineWidth = 3.0;
  static const mapBackdropFitPadding = 26.0;
  static const mapExploreFitPadding = 30.0;
  static const mapResultFitPadding = 28.0;
  static const mapTooltipOffset = 8.0;
  static const mapZoomControlButtonSize = 26.0;

  // Saved Routes
  static const savedRoutesHeaderX = 20.0;
  static const savedRoutesListGap = 10.0;
  static const savedRouteDeleteWidth = 76.0;
  static const savedRouteThumbnailSize = 60.0;
  static const savedRoutesEmptyPadX = 40.0;

  // Result screen
  static const resultMapHeight = 340.0;
  static const resultSheetMinHeight = 190.0;
  static const resultSheetMidHeight = 430.0;
  static const resultSheetMaxHeight = 700.0;
  static const resultSheetGrabberWidth = 32.0;
  static const resultSheetGrabberHeight = 4.0;
  static const resultSheetBottomInset = 0.0;

  // Animated backdrop car, measured from terra-nt-bg-map.html.
  static const mapCarMarkerWidth = 36.0;
  static const mapCarMarkerHeight = 32.0;
  static const mapCarBodyWidth = 30.0;
  static const mapCarBodyHeight = 24.0;
  static const mapCarBodyTop = 2.0;
  static const mapCarShadowWidth = 24.0;
  static const mapCarShadowHeight = 7.0;
  static const mapCarShadowBottom = 1.0;
  static const mapCarBobOffset = 1.5;

  // Onboarding shell, measured from Terra NT.dc.html L91-102.
  static const onboardingBackButtonSize = 36.0;
  static const onboardingChromeTop = 20.0;
  static const onboardingChromeSide = 20.0;
  static const onboardingProgressLeft = 68.0;
  static const onboardingProgressGap = 10.0;
  static const onboardingProgressPaddingY = 9.0;
  static const onboardingProgressPaddingX = 14.0;
  static const onboardingProgressHeight = 4.0;
  static const onboardingCardTop = 88.0;
  static const onboardingCardBottom = 24.0;
  static const onboardingCardPaddingY = 22.0;
  static const onboardingCardPaddingX = 20.0;
  static const onboardingStepSlideOffsetX = 18.0;
}
