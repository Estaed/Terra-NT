import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:terra_nt/core/theme/spacing.dart';
import 'package:terra_nt/data/repositories/notifiers.dart';
import 'package:terra_nt/features/auth/welcome_screen.dart';
import 'package:terra_nt/shared/map/terra_map.dart';
import 'package:terra_nt/shared/map/tile_warmup.dart';

const _warmupKey = ValueKey('welcome-tile-warmup');

Widget _harness() =>
    const ProviderScope(child: MaterialApp(home: WelcomeScreen()));

/// The warm-up lives under an `Offstage`, and finders skip offstage subtrees by
/// default — so every finder that reaches inside it has to opt back in. That
/// the default finder cannot see this map is itself the invisibility check,
/// asserted directly below.
Finder _insideWarmup(Type type) => find.descendant(
  of: find.byKey(_warmupKey),
  matching: find.byType(type, skipOffstage: false),
  skipOffstage: false,
);

void main() {
  testWidgets('welcome mounts a real tile layer to warm the tile cache', (
    tester,
  ) async {
    await tester.pumpWidget(_harness());

    // A mounted TileLayer is the whole point: flutter_map fetches through its
    // own NetworkTileProvider into its own disk cache, which is the cache
    // Explore reads. Nothing outside that tile path can warm it.
    expect(_insideWarmup(TileLayer), findsOneWidget);
  });

  testWidgets('the warm-up map is laid out, which is what loads tiles', (
    tester,
  ) async {
    await tester.pumpWidget(_harness());

    // TileLayer reads MapCamera, which FlutterMap derives from a LayoutBuilder,
    // so a non-zero laid-out map is the precondition for any tile request.
    // Offstage lays its child out and skips only paint, which is why this
    // works at all.
    final mapSize = tester.getSize(_insideWarmup(FlutterMap));
    expect(mapSize.width, greaterThan(0));
    expect(mapSize.height, greaterThan(0));
  });

  testWidgets('the warm-up map is fitted to the same bounds as explore', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(_harness());

    final map = tester.widget<TerraMap>(_insideWarmup(TerraMap));
    final context = tester.element(_insideWarmup(TerraMap));

    // Explore fits these same bounds with this same padding — computed the
    // same way Explore computes its own — because warming any other box
    // would cache tiles Explore never asks for.
    final bodyHeight =
        MediaQuery.sizeOf(context).height -
        MediaQuery.viewInsetsOf(context).bottom;
    expect(map.bounds, poiBounds(container.read(poiProvider)));
    expect(
      map.fitPadding,
      TerraMap.exploreFitPaddingFor(
        MediaQuery.paddingOf(context).top,
        bodyHeight,
      ),
    );
    expect(map.interactive, isFalse);
  });

  testWidgets('the warm-up is neither visible nor hit-testable', (
    tester,
  ) async {
    await tester.pumpWidget(_harness());

    expect(tester.widget<Offstage>(_insideWarmup(Offstage)).offstage, isTrue);

    // Offstage takes no room, is not painted, and swallows hit tests, so the
    // warm-up can neither be seen nor intercept a tap meant for the buttons.
    // A default finder skips offstage subtrees, so this reaching nothing is
    // the invisibility itself. Scoped to the warm-up so the cache loader is
    // checked independently of Welcome's decorative artwork.
    expect(
      find.descendant(
        of: find.byKey(_warmupKey),
        matching: find.byType(TileLayer),
      ),
      findsNothing,
    );
    expect(find.byKey(_warmupKey).hitTestable(), findsNothing);
    expect(tester.getSize(find.byKey(_warmupKey)), Size.zero);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the welcome actions stay tappable above the warm-up', (
    tester,
  ) async {
    await tester.pumpWidget(_harness());

    expect(
      find.byKey(const ValueKey('welcome-create-route')).hitTestable(),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('welcome-skip')).hitTestable(),
      findsOneWidget,
    );
  });

  testWidgets('the warm-up leaves no exception behind when welcome is left', (
    tester,
  ) async {
    await tester.pumpWidget(_harness());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const SizedBox());
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('TileWarmup sizes itself to the tab shell body', (tester) async {
    await tester.pumpWidget(_warmupHarness(bottomInset: 0));

    // The camera fit depends on the viewport, and Explore's viewport is the
    // shell body — the screen less the nav bar, not the whole screen.
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(
      tester.getSize(_mapInside(tester)),
      Size(screen.width, screen.height - AppSpacing.padFooterY),
    );
  });

  testWidgets('TileWarmup drops the bottom inset the nav bar pushes down', (
    tester,
  ) async {
    const inset = 34.0;
    await tester.pumpWidget(_warmupHarness(bottomInset: inset));

    // BottomNav wraps its 64px of content in a SafeArea, so the bar occupies
    // the inset too and the body Explore's map fills is that much shorter.
    // Getting this wrong changes `zoom.round()` and caches the wrong tiles.
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(
      tester.getSize(_mapInside(tester)).height,
      screen.height - AppSpacing.padFooterY - inset,
    );
  });
}

/// Mirrors how Welcome mounts the warm-up: a non-positioned child of a `Stack`,
/// which passes loose constraints. Handed the screen's tight constraints
/// instead, the warm-up's own `SizedBox` could not shrink below them and its
/// chosen size would never be the size it got.
Widget _warmupHarness({required double bottomInset}) => ProviderScope(
  child: MaterialApp(
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(padding: EdgeInsets.only(bottom: bottomInset)),
        child: Stack(
          children: [
            Consumer(
              builder: (context, ref, _) =>
                  TileWarmup(pois: ref.watch(poiProvider)),
            ),
          ],
        ),
      ),
    ),
  ),
);

Finder _mapInside(WidgetTester tester) => find.descendant(
  of: find.byType(TileWarmup, skipOffstage: false),
  matching: find.byType(TerraMap, skipOffstage: false),
  skipOffstage: false,
);
