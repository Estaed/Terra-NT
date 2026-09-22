import 'package:flutter/widgets.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/elevation.dart';
import '../../core/theme/metrics.dart';
import '../../core/theme/radius.dart';
import 'app_icon.dart';

/// The icon-in-box treatment used wherever a photo would go — no image loading of
/// any kind (`docs/PRD.md` §2, gap 3: the prototype's images never resolve either).
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
  })  : width = size,
        height = size,
        _hero = false;

  const PlaceholderTile.hero({
    super.key,
    this.height = 260,
    this.icon = LucideIcons.image,
    this.iconSize = AppMetrics.iconXxl,
    this.image,
  })  : width = double.infinity,
        _hero = true;

  final double width;
  final double height;
  final IconData icon;
  final double iconSize;
  final String? image;
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
            errorBuilder: (context, error, stackTrace) => _placeholder(),
          )
        : Image.asset(
            image,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _placeholder(),
          );
  }

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
