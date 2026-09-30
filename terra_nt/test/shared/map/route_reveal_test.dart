import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:terra_nt/core/theme/motion.dart';
import 'package:terra_nt/shared/map/route_reveal.dart';

void main() {
  const points = [LatLng(-12, 130), LatLng(-12, 131), LatLng(-12, 134)];

  test('clips within a long leg by distance rather than stop count', () {
    final reveal = RouteRevealGeometry(points);
    expect(reveal.pointsAt(0), isEmpty);
    expect(reveal.pointsAt(0.125), [points.first, const LatLng(-12, 130.5)]);
    expect(reveal.pointsAt(0.25), points.take(2));
    expect(reveal.pointsAt(0.5), [
      points.first,
      points[1],
      const LatLng(-12, 132),
    ]);
    expect(reveal.pointsAt(1), points);
    expect(reveal.pointsAt(2), points);
  });

  test('pins fade in order as the route reaches each stop', () {
    final reveal = RouteRevealGeometry(points);
    expect([for (var i = 0; i < 3; i++) reveal.pinOpacity(i, 0)], [1, 0, 0]);
    expect(reveal.pinOpacity(1, 0.21), closeTo(0.5, 0.001));
    expect(reveal.pinOpacity(2, 0.21), 0);
    expect(reveal.pinOpacity(1, 0.5), 1);
    expect(reveal.pinOpacity(2, 0.96), closeTo(0.5, 0.001));
    expect([for (var i = 0; i < 3; i++) reveal.pinOpacity(i, 1)], [1, 1, 1]);
  });

  test(
    'closely spaced first stops do not appear together on the first frame',
    () {
      final reveal = RouteRevealGeometry([
        points.first,
        const LatLng(-12, 130.01),
        const LatLng(-12, 130.02),
        points.last,
      ]);
      expect(reveal.pinOpacity(1, 0), 0);
      expect(reveal.pinOpacity(2, 0), 0);
      expect(reveal.pinOpacity(1, 0.001), greaterThan(0));
      expect(reveal.pinOpacity(2, 0.001), 0);
    },
  );

  test('empty, single and repeated points stay finite', () {
    expect(RouteRevealGeometry([]).pointsAt(0.5), isEmpty);
    final single = RouteRevealGeometry([points.first]);
    expect(single.pointsAt(0.5), [points.first]);
    expect(single.pinOpacity(0, 0), 1);
    final repeated = RouteRevealGeometry([
      points.first,
      points.first,
      points.last,
    ]);
    expect(repeated.pointsAt(0.5).last, const LatLng(-12, 132));
    final coincident = RouteRevealGeometry(List.filled(3, points.first));
    expect(coincident.pointsAt(0.5), List.filled(3, points.first));
    expect(coincident.pinOpacity(1, 0), 0);
    expect(coincident.pinOpacity(1, 0.5), 1);
    expect(coincident.pinOpacity(2, 0.5), 0);
  });

  testWidgets('only a different identity replays; disposal stops the ticker', (
    tester,
  ) async {
    final first = Object();
    final second = Object();
    late Animation<double> progress;
    Widget harness(Object identity) => MediaQuery(
      data: const MediaQueryData(),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: RouteReveal(
          routeIdentity: identity,
          builder: (_, animation) {
            progress = animation;
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpWidget(harness(first));
    await tester.pump(AppMotion.resultRouteReveal ~/ 2);
    expect(progress.value, closeTo(0.5, 0.001));
    await tester.pumpWidget(harness(first));
    expect(progress.value, closeTo(0.5, 0.001));
    await tester.pump(AppMotion.resultRouteReveal ~/ 2);
    expect(progress.value, 1);
    await tester.pumpWidget(harness(second));
    expect(progress.value, 0);
    await tester.pump(const Duration(milliseconds: 100));
    expect(progress.value, greaterThan(0));
    await tester.pumpWidget(const SizedBox());
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pump(AppMotion.resultRouteReveal);
    expect(tester.takeException(), isNull);
  });
}
