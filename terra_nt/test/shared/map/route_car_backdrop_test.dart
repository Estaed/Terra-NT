import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:terra_nt/data/models/onboarding_answers.dart';
import 'package:terra_nt/data/repositories/itinerary_repository.dart';
import 'package:terra_nt/data/seed/onboarding_options.dart';

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
  test(
    'each region and endpoint pair supplies at least two backdrop points',
    () {
      for (final region in regionOptions) {
        for (final start in tripLocationOptions) {
          for (final end in tripLocationOptions) {
            final route = SeedItineraryRepository().offlineItineraryFor(
              OnboardingAnswers(
                region: region.key,
                startLocation: start,
                endLocation: end,
              ),
            );
            final backdrop = RouteCarBackdrop.ambient(
              coordinates: [
                for (final stop in route.stops) [stop.lat, stop.lng],
              ],
            );
            expect(backdrop.coordinates.length, greaterThanOrEqualTo(2));
            if (region.key == 'red_centre' &&
                ['Alice Springs', 'Uluru'].contains(start) &&
                ['Alice Springs', 'Uluru'].contains(end)) {
              expect(
                backdrop.coordinates.every((point) => point.first < -23),
                isTrue,
              );
            }
          }
        }
      }
    },
  );

  testWidgets('the car drives the supplied Darwin to Katherine route', (
    tester,
  ) async {
    final key = GlobalKey<RouteCarBackdropState>();
    final route = SeedItineraryRepository().offlineItineraryFor(
      const OnboardingAnswers(
        region: 'top_end',
        startLocation: 'Darwin',
        endLocation: 'Katherine',
      ),
    );
    await tester.pumpWidget(
      backdropHarness(
        RouteCarBackdrop.ambient(
          key: key,
          coordinates: [
            for (final stop in route.stops) [stop.lat, stop.lng],
          ],
        ),
      ),
    );
    expect(key.currentState!.currentPosition, const LatLng(-12.4634, 130.8456));
    await tester.pump(RouteCarBackdrop.ambientStartDelay);
    for (var frame = 0; frame < 43; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
      expect(key.currentState!.currentPosition.latitude, greaterThan(-15));
    }
    expect(key.currentState!.currentPosition, const LatLng(-14.3103, 132.4204));
    await tester.pumpWidget(const SizedBox());
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('the car follows the route rather than the endpoint chord', (
    tester,
  ) async {
    final key = GlobalKey<RouteCarBackdropState>();
    await tester.pumpWidget(
      backdropHarness(RouteCarBackdrop.ambient(key: key)),
    );
    await tester.pump(RouteCarBackdrop.ambientStartDelay);
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

  testWidgets('renders at phone width without exceptions', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(backdropHarness(const RouteCarBackdrop.ambient()));
    expect(tester.takeException(), isNull);
  });
}
