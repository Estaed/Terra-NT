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
}
