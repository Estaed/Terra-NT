import 'package:flutter/widgets.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/elevation.dart';
import '../../core/theme/metrics.dart';
import '../../core/theme/radius.dart';
import 'app_icon.dart';

/// A place picture, with a bundled fallback for failed online photos and an
/// icon when neither picture can be loaded.
///
/// Two named constructors because the hero genuinely differs from the boxed forms:
/// no border, no radius.
class PlaceholderTile extends StatelessWidget {
  const PlaceholderTile.square({
    super.key,
    required double size,
    this.icon = LucideIcons.image,
    this.iconSize = AppMetrics.iconXl,
    this.image,
    this.fallbackImage,
  })  : width = size,
        height = size,
        _hero = false;

  const PlaceholderTile.hero({
    super.key,
    this.height = 260,
    this.icon = LucideIcons.image,
    this.iconSize = AppMetrics.iconXxl,
    this.image,
    this.fallbackImage,
  })  : width = double.infinity,
        _hero = true;

  final double width;
  final double height;
  final IconData icon;
  final double iconSize;
  final String? image;
  final String? fallbackImage;
  final bool _hero;

  Widget _placeholder() => ColoredBox(
        color: AppColors.surface2,
        child: Center(child: AppIcon(icon, size: iconSize, color: AppColors.inkTertiary)),
      );

  Widget _image(String image) {
    final isNetwork = image.startsWith("http://") || image.startsWith("https://");
    return isNetwork
        ? Image.network(
            image,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                fallbackImage == null ? _placeholder() : _asset(fallbackImage!),
          )
        : _asset(image);
  }

  Widget _asset(String path) => Image.asset(
    path,
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) => _placeholder(),
  );

  @override
  Widget build(BuildContext context) {
    final content = image == null ? _placeholder() : _image(image!);

    if (_hero) {
      return SizedBox(width: width, height: height, child: content);
    }

    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.hairline, width: AppElevation.hairlineWidth),
      ),
      child: content,
    );
  }
}
