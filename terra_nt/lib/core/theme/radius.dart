/// Corner radius tokens, transcribed from `design/design-system/tokens/radius.css`.
///
/// Pure Dart — these are numbers, fed to `BorderRadius.circular` at the call site.
class AppRadius {
  AppRadius._();

  static const xs = 4.0;
  static const sm = 6.0;
  static const md = 8.0;
  static const lg = 12.0;
  static const xl = 16.0;
  static const xxl = 24.0;
  static const pill = 9999.0;
  static const full = 9999.0;

  // Semantic aliases
  static const badge = xs;
  static const tag = sm;
  static const button = md;
  static const input = md;
  static const card = lg;
  static const panel = xl;
  static const bannerOversized = xxl;
  static const toggle = pill;
  static const avatar = full;
}
