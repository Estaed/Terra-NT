// `Color` is a `dart:ui` type, so naming the real return type here keeps every call
// site statically checked without importing the Flutter framework into tier 1.
import 'dart:ui' show Color;

import '../theme/colors.dart';

Color tagColor(String tag) {
  switch (tag) {
    case 'Nature':
      return AppColors.tagGreen;
    case 'Culture':
      return AppColors.tagPurple;
    case 'Adventure':
      return AppColors.tagOrange;
    case 'Wildlife':
      return AppColors.tagBlue;
    case 'Relaxation':
      return AppColors.tagYellow;
    default:
      return AppColors.inkTertiary;
  }
}
