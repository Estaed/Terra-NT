import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:terra_nt/core/util/route_sampler.dart';
import 'package:terra_nt/shared/map/car_glyph.dart';
import 'package:terra_nt/shared/map/route_car_backdrop.dart';

Widget backdropHarness(RouteCarBackdrop backdrop) =>
    MaterialApp(home: SizedBox(width: 360, height: 640, child: backdrop));

double distanceToChord(LatLng point, LatLng start, LatLng end) {
  final dx = end.latitude - start.latitude;
  final dy = end.longitude - start.longitude;
  final numerator =
      ((point.latitude - start.latitude) * dy -
              (point.longitude - start.longitude) * dx)
          .abs();
  return numerator / math.sqrt(dx * dx + dy * dy);
}

void main() {
  testWidgets('samples every route waypoint across a full sweep', (
    tester,
  ) async {
    final key = GlobalKey<RouteCarBackdropState>();
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 360,
          height: 640,
          child: RouteCarBackdrop.progress(key: key, fraction: 0),
        ),
      ),
    );

    final cumulative = cumulativeDistances(RouteCarBackdrop.routeCoordinates);
    final total = cumulative.last;
    final fractions = <double>[
      ...cumulative.map((distance) => distance / total),
      ...List<double>.generate(13, (index) => (index + 1) / 14),
    ]..sort();
    expect(fractions, hasLength(20));

    final samples = <LatLng>[];
    for (final fraction in fractions) {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 360,
            height: 640,
            child: RouteCarBackdrop.progress(key: key, fraction: fraction),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 5));
      samples.add(key.currentState!.currentPosition);
    }

    for (final routePoint in RouteCarBackdrop.routeCoordinates) {
      expect(
        samples.any(
          (sample) =>
              (sample.latitude - routePoint.first).abs() < 0.0001 &&
              (sample.longitude - routePoint.last).abs() < 0.0001,
        ),
        isTrue,
      );
    }
  });

  testWidgets('progress follows the route rather than the endpoint chord', (
    tester,
  ) async {
    final key = GlobalKey<RouteCarBackdropState>();
    await tester.pumpWidget(
      backdropHarness(RouteCarBackdrop.progress(key: key, fraction: 0)),
    );
    await tester.pumpWidget(
      backdropHarness(RouteCarBackdrop.progress(key: key, fraction: 1)),
    );
    final samples = <LatLng>[];
    for (final elapsed in const <Duration>[
      Duration(milliseconds: 800),
      Duration(milliseconds: 800),
      Duration(milliseconds: 800),
    ]) {
      await tester.pump(elapsed);
      samples.add(key.currentState!.currentPosition);
    }

    final start = RouteCarBackdrop.routeCoordinates.first;
    final end = RouteCarBackdrop.routeCoordinates.last;
    expect(
      samples
          .map(
            (sample) => distanceToChord(
              sample,
              LatLng(start.first, start.last),
              LatLng(end.first, end.last),
            ),
          )
          .any((distance) => distance > 0.001),
      isTrue,
    );
  });

  testWidgets('car flips horizontally as longitude direction changes', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: CarGlyph(longitudeDelta: 1)),
    );
    await tester.pumpWidget(
      const MaterialApp(home: CarGlyph(longitudeDelta: -1)),
    );
    await tester.pump(const Duration(milliseconds: 140));

    final transform = tester.widget<Transform>(
      find.byKey(const ValueKey('car-facing-transform')),
    );
    expect(transform.transform.storage.first, lessThan(0));
  });

  testWidgets('ambient reverses after reaching the route end', (tester) async {
    final key = GlobalKey<RouteCarBackdropState>();
    await tester.pumpWidget(
      backdropHarness(RouteCarBackdrop.ambient(key: key)),
    );
    await tester.pump(RouteCarBackdrop.ambientStartDelay);
    for (var frame = 0; frame < 43; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final atEnd = key.currentState!.currentFraction;
    final reverseSamples = <double>[];
    for (var frame = 0; frame < 18; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
      reverseSamples.add(key.currentState!.currentFraction);
    }

    expect(reverseSamples.any((fraction) => fraction < atEnd), isTrue);
  });

  testWidgets('disposal leaves no active callbacks', (tester) async {
    await tester.pumpWidget(backdropHarness(const RouteCarBackdrop.ambient()));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const SizedBox());
    await tester.pump();

    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('both modes render at phone width without exceptions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(backdropHarness(const RouteCarBackdrop.ambient()));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
      backdropHarness(const RouteCarBackdrop.progress(fraction: 1)),
    );
    expect(tester.takeException(), isNull);
  });
}
