import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:terra_nt/core/theme/colors.dart';
import 'package:terra_nt/core/util/itinerary_ops.dart';
import 'package:terra_nt/core/util/maps_url.dart';
import 'package:terra_nt/core/util/onboarding_rules.dart';
import 'package:terra_nt/core/util/route_sampler.dart';
import 'package:terra_nt/core/util/saved_routes_ops.dart';
import 'package:terra_nt/core/util/sheet_snap.dart';
import 'package:terra_nt/core/util/swipe_snap.dart';
import 'package:terra_nt/core/util/tag_colors.dart';
import 'package:terra_nt/data/models/onboarding_answers.dart';
import 'package:terra_nt/data/models/saved_route.dart';
import 'package:terra_nt/data/seed/seed_data.dart';

void main() {
  group('route sampler', () {
    const route = <List<double>>[
      [0, 0],
      [0, 10],
      [10, 10],
    ];

    test('clamps endpoints and samples the correct segment', () {
      expect(pointAtFraction(route, -1), [0, 0]);
      expect(pointAtFraction(route, 0), [0, 0]);
      expect(pointAtFraction(route, 0.75), [5, 10]);
      expect(pointAtFraction(route, 1.5), [10, 10]);
    });

    test('walks every segment during a full sweep', () {
      final samples = List.generate(
        21,
        (index) => pointAtFraction(route, index / 20),
      );
      expect(samples.any((point) => point[0] == 0 && point[1] > 0), isTrue);
      expect(samples.any((point) => point[1] == 10 && point[0] > 0), isTrue);
      for (var i = 1; i < samples.length; i++) {
        final previous = samples[i - 1];
        final current = samples[i];
        expect((current[0] - previous[0]).abs(), lessThanOrEqualTo(1));
        expect((current[1] - previous[1]).abs(), lessThanOrEqualTo(1));
      }
    });

    test('zero-length segments do not divide by zero', () {
      expect(
        pointAtFraction(const <List<double>>[
          [0, 0],
          [0, 0],
          [0, 10],
        ], 0),
        [0, 0],
      );
    });
  });

  group('onboarding rules', () {
    test('all gated steps require and accept their answer', () {
      const empty = OnboardingAnswers();
      final gatedSteps = <int>[0, 2, 3, 4, 5, 6, 7, 8, 9, 11, 12, 13, 14];
      for (final step in gatedSteps) {
        expect(canNext(step, empty), isFalse, reason: 'step $step');
      }

      expect(canNext(0, empty.copyWith(ageRange: '25-34')), isTrue);
      expect(canNext(2, empty.copyWith(companions: 'Solo')), isTrue);
      expect(canNext(3, empty.copyWith(focus: ['Nature'])), isTrue);
      expect(canNext(4, empty.copyWith(vehicle: '2WD')), isTrue);
      expect(canNext(5, empty.copyWith(budget: 'Moderate')), isTrue);
      expect(canNext(6, empty.copyWith(accommodation: 'Hotel')), isTrue);
      expect(canNext(7, empty.copyWith(activityLevel: 'Moderate')), isTrue);
      expect(canNext(8, empty.copyWith(region: 'Top End')), isTrue);
      expect(canNext(9, empty.copyWith(offRoadConfidence: 'Some')), isTrue);
      expect(canNext(11, empty.copyWith(campingPreference: 'Mix')), isTrue);
      expect(canNext(12, empty.copyWith(wildlifeInterest: 'High')), isTrue);
      expect(canNext(13, empty.copyWith(offGridComfortable: false)), isTrue);
      expect(
        canNext(
          14,
          empty.copyWith(startLocation: 'Darwin', endLocation: 'Uluru'),
        ),
        isTrue,
      );
    });

    test('the location step needs both ends, and whitespace is not an end', () {
      const empty = OnboardingAnswers();
      expect(canNext(14, empty), isFalse);
      expect(canNext(14, empty.copyWith(startLocation: 'Darwin')), isFalse);
      expect(canNext(14, empty.copyWith(endLocation: 'Uluru')), isFalse);
      expect(
        canNext(14, empty.copyWith(startLocation: '   ', endLocation: 'Uluru')),
        isFalse,
      );
      expect(
        canNext(
          14,
          empty.copyWith(startLocation: 'Darwin', endLocation: 'Uluru'),
        ),
        isTrue,
      );
    });

    test('slider steps are ungated', () {
      const empty = OnboardingAnswers();
      for (final step in <int>[1, 10]) {
        expect(canNext(step, empty), isTrue);
      }
      expect(canNext(3, empty), isFalse);
      expect(canNext(3, empty.copyWith(focus: ['Adventure'])), isTrue);
    });

    test('progress percent uses its specified denominator', () {
      expect(progressPercent(0), 7);
      expect(progressPercent(14), 100);
    });
  });

  group('sheet and swipe snaps', () {
    test('nearest snap chooses lower value on ties', () {
      expect(nearestSnap(190), 190);
      expect(nearestSnap(430), 430);
      expect(nearestSnap(700), 700);
      expect(nearestSnap(250), 190);
      expect(nearestSnap(310), 190);
      expect(nearestSnap(565), 430);
      expect(nearestSnap(600), 700);
    });

    test('usable height clamps and deduplicates anchors', () {
      expect(nearestSnap(600, usableHeight: 600), 600);
      expect(nearestSnap(700, usableHeight: 600), 600);
      expect(nearestSnap(100, usableHeight: 600), 190);
      expect(nearestSnap(300, usableHeight: 100), 100);
      expect(nearestSnap(700), 700);
    });

    test('swipe thresholds match the prototype', () {
      expect(clampOffset(-100), -76);
      expect(clampOffset(10), 0);
      expect(clampOffset(-38), -38);
      expect(isOpenAfterRelease(-38), isFalse);
      expect(isOpenAfterRelease(-39), isTrue);
      expect(didMove(4), isFalse);
      expect(didMove(-4), isFalse);
      expect(didMove(4.01), isTrue);
    });
  });

  group('maps URLs', () {
    test('has no waypoints for a two-stop route', () {
      final url = buildMapsUrl(seedStops.sublist(0, 2));
      expect(url, contains('origin=-12.4634%2C130.8456'));
      expect(url, contains('destination=-13.183%2C130.6805'));
      expect(url, isNot(contains('waypoints')));
    });

    test('encodes intermediate waypoints and excludes skipped stops', () {
      final url = buildMapsUrl(seedStops.sublist(0, 3), skipped: {1});
      expect(url, contains('origin=-12.4634%2C130.8456'));
      expect(url, contains('destination=-12.6692%2C132.8352'));
      expect(url, isNot(contains('130.6805')));
      expect(url, isNot(contains('waypoints')));

      final threeStopUrl = buildMapsUrl(seedStops.sublist(0, 3));
      expect(threeStopUrl, contains('waypoints=-13.183%2C130.6805'));
    });

    test('returns null below two live stops and supports one destination', () {
      expect(buildMapsUrl(seedStops.take(1).toList()), isNull);
      expect(buildMapsUrl(seedStops.sublist(0, 2), skipped: {0}), isNull);
      expect(
        singleDestinationUrl(seedStops.first),
        contains('destination=-12.4634%2C130.8456'),
      );
    });
  });

  group('itinerary operations', () {
    test('reorder and remove are immutable order operations', () {
      expect(reorder([0, 1, 2, 3], 1, 3), [0, 2, 3, 1]);
      expect(remove([0, 1, 2, 3], 2), [0, 1, 3]);
    });

    test('revertOne restores only a present stop', () {
      expect(revertOne([0, 3, 2], 2), [0, 3, 2]);
      expect(revertOne([0, 2], 2), [0, 2]);
      expect(revertOne([0, 3], 2), [0, 3]);
      expect(revertOne([3, 0, 2], 0), [0, 3, 2]);
    });

    test('restoreRemoved preserves the manual order of present stops', () {
      expect(restoreRemoved([2, 0, 4], 5), [2, 1, 0, 3, 4]);
      expect(removedCount([2, 0, 4], 5), 2);
    });

    test('removed labels and derived metadata are dynamic', () {
      expect(removedLabel(1), 'Restore 1 removed stop');
      expect(removedLabel(2), 'Restore 2 removed stops');
      expect(derivedMeta(7, 8), '8 days · 7 stops');
      expect(derivedMeta(6, 8), '8 days · 6 stops');
    });

    test('hasEdits sees a skip, a removal and a reorder, and nothing else', () {
      expect(hasEdits([0, 1, 2], const {}, 3), isFalse);
      expect(hasEdits([0, 1, 2], const {1}, 3), isTrue);
      expect(hasEdits([0, 2], const {}, 3), isTrue);
      expect(hasEdits([0, 2, 1], const {}, 3), isTrue);
    });

    test('driveNext only applies to unchanged adjacent baseline legs', () {
      expect(
        driveNextForPosition([0, 1], 0, seedStops),
        seedStops[0].driveNext,
      );
      expect(
        driveNextForPosition([0, 2, 1], 0, seedStops),
        'Drive time unavailable',
      );
      expect(driveNextForPosition([0, 2], 1, seedStops), isNull);
      expect(
        driveNextForPosition([0, 2], 0, seedStops),
        'Drive time unavailable',
      );
      expect(
        driveNextForPosition([0, 1, 2, 3], 0, redCentreStops),
        redCentreStops[0].driveNext,
      );
    });
  });

  group('tag colors and saved routes', () {
    test('returns a statically typed Color, never dynamic', () {
      // A `dynamic` return would defeat type checking at every call site while
      // leaving `flutter analyze` clean, so the type itself is pinned here.
      expect(tagColor('Nature'), isA<Color>());
      expect(tagColor('Unknown'), isA<Color>());
    });

    test('maps known tags and falls back for unknown tags', () {
      expect(tagColor('Nature'), AppColors.tagGreen);
      expect(tagColor('Culture'), AppColors.tagPurple);
      expect(tagColor('Adventure'), AppColors.tagOrange);
      expect(tagColor('Wildlife'), AppColors.tagBlue);
      expect(tagColor('Relaxation'), AppColors.tagYellow);
      expect(tagColor('Unknown'), AppColors.inkTertiary);
    });

    test('upsert inserts at the top and replaces in place', () {
      const routes = <SavedRoute>[
        SavedRoute(
          id: 'a',
          title: 'A',
          meta: '1 day · 1 stop',
          dateLabel: 'Today',
        ),
        SavedRoute(
          id: 'b',
          title: 'B',
          meta: '2 days · 2 stops',
          dateLabel: 'Yesterday',
        ),
        SavedRoute(
          id: 'c',
          title: 'C',
          meta: '3 days · 3 stops',
          dateLabel: 'Earlier',
        ),
      ];
      const replacement = SavedRoute(
        id: 'b',
        title: 'B updated',
        meta: '4 days · 4 stops',
        dateLabel: 'Now',
      );
      final replaced = upsert(routes, replacement);
      expect(replaced.map((route) => route.id), ['a', 'b', 'c']);
      expect(replaced[1].title, 'B updated');
      final inserted = upsert(
        routes,
        const SavedRoute(
          id: 'new',
          title: 'New',
          meta: '1 day · 1 stop',
          dateLabel: 'Now',
        ),
      );
      expect(inserted.first.id, 'new');
      expect(routes.first.id, 'a');
    });
  });
}
