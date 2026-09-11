import 'package:flutter/widgets.dart';

import '../../core/util/tile_math.dart';
import 'terra_map.dart';

/// Warms the CARTO tiles covering the Northern Territory while Welcome is on
/// screen, so Explore does not open on empty tiles.
///
/// The tile list itself is tier-1 pure Dart in `core/util/tile_math.dart`; this
/// is only the `precacheImage` loop, which needs a `BuildContext`.
///
/// Known limitation, to be raised rather than worked around: `flutter_map`
/// 8.3.1 fetches through its own unexported `NetworkTileImageProvider` and its
/// built-in disk cache, so these `NetworkImage` entries do not share a cache
/// key with the tile layer. This warms Flutter's in-memory image cache and the
/// DNS/TLS path to the CDN, not `flutter_map`'s own cache. Making the caches
/// share a key needs a custom `TileProvider` returning `NetworkImage`, which
/// would give up the persistent disk cache an offline-first app wants.
Future<void> precacheNtTiles(BuildContext context) async {
  final urls = ntPrefetchTileUrls(
    urlTemplate: cartoDarkTileUrl,
    apiKey: cartoApiKey,
    retina: mapRetinaMode(context),
  );

  for (final url in urls) {
    if (!context.mounted) return;
    await precacheImage(
      NetworkImage(url),
      context,
      // An offline launch is the expected case for this app, not a failure.
      onError: (_, _) {},
    );
  }
}
