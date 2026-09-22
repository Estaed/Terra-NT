import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:terra_nt/data/models/poi.dart';
import 'package:terra_nt/shared/map/terra_map.dart';
import 'package:terra_nt/shared/map/tile_warmup.dart';

const _pois = [
  Poi(
    id: 'a',
    name: 'A',
    tag: 'Nature',
    rating: '4.5',
    description: 'desc',
    lat: -12.4634,
    lng: 130.8456,
  ),
  Poi(
    id: 'b',
    name: 'B',
    tag: 'Culture',
    rating: '4.0',
    description: 'desc',
    lat: -13.1830,
    lng: 130.6805,
  ),
];

Widget _harness({
  required EdgeInsets padding,
  EdgeInsets viewInsets = EdgeInsets.zero,
}) => MaterialApp(
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(padding: padding, viewInsets: viewInsets),
      child: const TileWarmup(pois: _pois),
    ),
  ),
);

Finder _map() => find.byType(TerraMap, skipOffstage: false);

void main() {
  testWidgets(
    'passes the same fit padding Explore computes for its own viewport',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _harness(padding: const EdgeInsets.only(top: 48)),
      );

      final map = tester.widget<TerraMap>(_map());
      // Same formula Explore derives in `explore_screen.dart`: the Scaffold
      // body's height once the keyboard has resized it. No keyboard here, so
      // it is just the screen height — matching Task-37's regression, which
      // left this warm-up on the old flat `exploreFitPadding` instead.
      const bodyHeight = 800.0;
      expect(map.fitPadding, TerraMap.exploreFitPaddingFor(48, bodyHeight));
    },
  );

  testWidgets(
    'shrinks the fit padding input by the keyboard inset, like Explore',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _harness(
          padding: const EdgeInsets.only(top: 48),
          viewInsets: const EdgeInsets.only(bottom: 300),
        ),
      );

      final map = tester.widget<TerraMap>(_map());
      const bodyHeight = 800.0 - 300.0;
      expect(map.fitPadding, TerraMap.exploreFitPaddingFor(48, bodyHeight));
    },
  );

  testWidgets('still fits the same bounds and stays non-interactive', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(padding: EdgeInsets.zero));

    final map = tester.widget<TerraMap>(_map());
    expect(map.bounds, poiBounds(_pois));
    expect(map.interactive, isFalse);
  });
}
