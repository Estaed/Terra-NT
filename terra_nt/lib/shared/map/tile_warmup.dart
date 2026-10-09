import 'package:flutter/material.dart';

import '../../core/theme/spacing.dart';
import '../../data/models/poi.dart';
import 'terra_map.dart';

/// Warms `flutter_map`'s own tile cache while Welcome is on screen, so Explore
/// does not open on empty tiles.
///
/// It mounts the very map Explore mounts — same bounds, same fit padding, same
/// viewport size — and then hides it. `RenderOffstage` lays its child out with
/// the incoming constraints and skips only painting, hit testing and
/// semantics, and `flutter_map`'s tile loading is layout-driven, not
/// paint-driven: `FlutterMap` derives `MapCamera` from a `LayoutBuilder`, and
/// `TileLayer` reads that camera in `didChangeDependencies` and `build` to call
/// `TileImage.load()`. So the tiles are fetched through the real
/// `NetworkTileProvider` and written to its default `BuiltInMapCachingProvider`
/// disk cache — the same cache, under the same keys, that Explore then reads.
///
/// That shared key is the whole point, and why the `precacheImage` loop this
/// replaces could not work: `flutter_map` resolves tiles through its own
/// unexported `NetworkTileImageProvider`, which shares no cache key with
/// `NetworkImage`, so that loop only warmed DNS/TLS and Flutter's generic
/// image cache.
class TileWarmup extends StatelessWidget {
  const TileWarmup({super.key, required this.pois});

  /// The same list Explore fits its camera to; the bounds decide which tiles
  /// load, so warming a different box would warm the wrong tiles.
  final List<Poi> pois;

  @override
  Widget build(BuildContext context) {
    // Explore's map fills the tab shell's body, not the whole screen: below it
    // sit `BottomNav`'s own `AppSpacing.padFooterY` of content and the device's
    // bottom inset. The height has to match, because `flutter_map` picks its
    // tile level with `zoom.round()` — fitting the same bounds into a taller
    // box can round to a different zoom and cache tiles Explore never asks for.
    final screen = MediaQuery.sizeOf(context);
    final shellBodyHeight =
        screen.height -
        AppSpacing.padFooterY -
        MediaQuery.paddingOf(context).bottom;
    // The same formula Explore uses for its own fit padding
    // (`explore_screen.dart`): the Scaffold body's height once the keyboard
    // has resized it. Kept separate from `shellBodyHeight` above, which
    // sizes this offstage box to match the tab shell's real viewport.
    final bodyHeight = screen.height - MediaQuery.viewInsetsOf(context).bottom;
    return Offstage(
      child: SizedBox(
        width: screen.width,
        height: shellBodyHeight,
        child: TerraMap(
          interactive: false,
          bounds: poiBounds(pois),
          fitPadding: TerraMap.exploreFitPaddingFor(
            MediaQuery.paddingOf(context).top,
            bodyHeight,
          ),
        ),
      ),
    );
  }
}
