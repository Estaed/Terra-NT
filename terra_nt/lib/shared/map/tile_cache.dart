import 'dart:io';

import 'package:flutter_map/flutter_map.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/util/tile_cache_key.dart';

/// CARTO Basemap Terms (2026-09-29): device caching at most 30 days.
/// https://carto.com/legal/basemap-terms/
const tileCacheFreshAge = Duration(days: 30);

/// Configure the singleton before any map (including Welcome's warm-up) loads.
/// NetworkTileProvider uses this same instance by default on every map.
Future<BuiltInMapCachingProvider> initializeTileCache({
  Future<Directory> Function() applicationSupportDirectory =
      getApplicationSupportDirectory,
}) async {
  String? cacheDirectory;
  try {
    cacheDirectory = (await applicationSupportDirectory()).path;
  } catch (_) {
    // Keep startup working with flutter_map's default cache location if the
    // platform cannot supply app support. Freshness and key rules still apply.
  }

  return BuiltInMapCachingProvider.getOrCreateInstance(
    cacheDirectory: cacheDirectory,
    overrideFreshAge: tileCacheFreshAge,
    // The normalized URL is the identity; the UUID makes it a safe filename.
    tileKeyGenerator: (url) =>
        BuiltInMapCachingProvider.uuidTileKeyGenerator(tileCacheKey(url)),
  );
}
