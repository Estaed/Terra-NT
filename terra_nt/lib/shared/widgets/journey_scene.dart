import 'package:flutter/material.dart';

import '../../core/theme/metrics.dart';
import '../../core/theme/radius.dart';
import 'entrance.dart';

/// A decorative, bundled NT road trip shared by the two starting surfaces.
/// Text and actions belong below this frame, never over the artwork.
class JourneyScene extends StatelessWidget {
  const JourneyScene({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: Entrance(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Image.asset(
            'assets/images/scenes/start_trip.jpg',
            width: double.infinity,
            height: AppMetrics.stopDetailHeroHeight,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
          ),
        ),
      ),
    ),
  );
}
