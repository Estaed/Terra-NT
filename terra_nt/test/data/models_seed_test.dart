import 'package:flutter_test/flutter_test.dart';
import 'package:terra_nt/data/models/itinerary.dart';
import 'package:terra_nt/data/models/onboarding_answers.dart';
import 'package:terra_nt/data/seed/onboarding_options.dart';
import 'package:terra_nt/data/seed/seed_data.dart';

void main() {
  test('seeded road legs use Tourism NT driving figures', () {
    expect(seedStops[2].driveNext, '305 km · 3h 10m to Katherine');
    expect(seedStops[3].driveNext, '1,191 km · about 12h to Alice Springs');
    expect(seedStops[4].driveNext, '473 km · 4h 50m to Kings Canyon');
    expect(seedStops[5].driveNext, '302 km · 3h 10m to Uluru');
    expect(redCentreStops[1].driveNext, '473 km · 4h 50m to Kings Canyon');
    expect(redCentreStops[2].driveNext, '302 km · 3h 10m to Uluru');
    expect(seedStops[0].driveNext, '115 km · 1h 30m to Litchfield National Park');
    expect(seedStops[1].driveNext, '230 km · 3h to Kakadu National Park');
    expect(seedStops[3].aiNote, contains('about 12 hours'));
    expect(seedStops[3].aiNote, contains('breaks'));
  });

  group('local trip selection', () {
    for (final region in regionOptions) {
      for (final start in tripLocationOptions) {
        for (final end in tripLocationOptions) {
          test('${region.key}: $start to $end keeps both endpoints', () {
            final stops = localTripStops(
              OnboardingAnswers(
                region: region.key,
                startLocation: start,
                endLocation: end,
              ),
            );
            expect(stops.length, greaterThanOrEqualTo(2));
            expect(stops.first.name, start);
            expect(stops.last.name, end);
            expect(stops.last.driveNext, isNull);
            expect(stops.every((stop) => stop.detailedPlan.isEmpty), isTrue);
            expect(
              stops.every(
                (stop) => stop.aiNote.startsWith('Offline suggestion'),
              ),
              isTrue,
            );
          });
        }
      }
    }

    test('Top End and Red Centre defaults stay in their regions', () {
      final north = localTripStops(const OnboardingAnswers(region: 'top_end'));
      final south = localTripStops(
        const OnboardingAnswers(region: 'red_centre'),
      );
      expect(north.every((stop) => stop.lat > -15), isTrue);
      expect(south.every((stop) => stop.lat < -23), isTrue);
      expect(north.first.name, 'Darwin');
      expect(north.last.name, 'Nitmiluk Gorge, Katherine');
      expect(south.first.name, 'Alice Springs');
      expect(south.last.name, 'Uluru-Kata Tjuta');
    });

    test('reverse endpoints reverse only their part of the regional chain', () {
      final stops = localTripStops(
        const OnboardingAnswers(
          region: 'top_end',
          startLocation: 'Katherine',
          endLocation: 'Darwin',
        ),
      );
      expect(stops.map((stop) => stop.name), [
        'Katherine',
        'Kakadu National Park',
        'Litchfield National Park',
        'Darwin',
      ]);
      expect(
        stops.first.driveNext,
        'Next: Kakadu National Park · check drive time locally',
      );
      expect(stops.every((stop) => stop.duration == 'Suggested stop'), isTrue);
    });

    test('unknown locations fall back to regional endpoints', () {
      final stops = localTripStops(
        const OnboardingAnswers(
          region: 'red_centre',
          startLocation: 'Unknown',
          endLocation: 'Elsewhere',
        ),
      );
      expect(stops.first.name, 'Alice Springs');
      expect(stops.last.name, 'Uluru-Kata Tjuta');
      expect(stops.every((stop) => stop.lat < -23), isTrue);
    });

    test(
      'every bundled POI can be used as an endpoint without new coordinates',
      () {
        for (final poi in seedPois) {
          final stops = localTripStops(
            OnboardingAnswers(startLocation: poi.name, endLocation: poi.name),
          );
          expect(stops.first.name, poi.name);
          expect(stops.first.lat, poi.lat);
          expect(stops.first.lng, poi.lng);
          expect(stops.last.name, poi.name);
          expect(stops.length, greaterThan(2));
        }
      },
    );
  });

  test('seed routes carry day counts matching their stored meta', () {
    expect(seedSavedRoutes.map((route) => route.days), [8, 7]);
    for (final route in seedSavedRoutes) {
      expect(route.meta, '${route.days} days · ${route.stops.length} stops');
    }
  });

  group('Task-03 DoD Tests', () {
    test('seedStops.length == 7 and in correct order', () {
      expect(seedStops.length, 7);
      expect(seedStops[0].name, 'Darwin');
      expect(seedStops[1].name, 'Litchfield National Park');
      expect(seedStops[2].name, 'Kakadu National Park');
      expect(seedStops[3].name, 'Nitmiluk Gorge, Katherine');
      expect(seedStops[4].name, 'Alice Springs');
      expect(seedStops[5].name, 'Kings Canyon');
      expect(seedStops[6].name, 'Uluru-Kata Tjuta');
    });

    test('Itinerary carries title and stops', () {
      final itinerary = Itinerary(
        title: 'Custom Title',
        stops: redCentreStops,
      );
      expect(itinerary.title, 'Custom Title');
      expect(itinerary.stops.length, 4);
    });

    test('Last stop driveNext is null, fee matches prototype', () {
      expect(seedStops.last.driveNext, isNull);
      for (int i = 0; i < seedStops.length - 1; i++) {
        expect(seedStops[i].driveNext, isNotNull);
      }
      
      expect(seedStops[0].fee, isNull); // Darwin
      expect(seedStops[1].fee, 'Free entry'); // Litchfield
    });

    test('seedPois.length == 15 and Ubirr coordinates are correct', () {
      expect(seedPois.length, 15);
      final ubirr = seedPois.firstWhere((p) => p.id == 'ubirr');
      expect(ubirr.lat, -12.4260);
      expect(ubirr.lng, 132.9760);
    });

    test('loadingMessages length is 5 and last is "Routing..."', () {
      expect(loadingMessages.length, 5);
      expect(loadingMessages.last, 'Routing...');
    });

    test('heatLabels length is 5 and match verbatim', () {
      expect(heatLabels.length, 5);
      expect(heatLabels[0], 'Not well at all');
      expect(heatLabels[1], "Not great, but I'll manage");
      expect(heatLabels[2], "It's fine either way");
      expect(heatLabels[3], 'Handles it pretty well');
      expect(heatLabels[4], 'Thrives in the heat');
    });

    test('seedStops[2] detailedPlan has 10 entries, first time is "7:00am"', () {
      final kakadu = seedStops[2];
      expect(kakadu.detailedPlan.length, 10);
      expect(kakadu.detailedPlan.first.time, '7:00am');
    });

    test('redCentreStops matches the Q3 answer', () {
      expect(redCentreStops.length, 4);
      expect(redCentreStops[0].name, 'Alice Springs');
      expect(redCentreStops[1].name, 'Alice Springs Desert Park');
      expect(redCentreStops[2].name, 'Kings Canyon');
      expect(redCentreStops[3].name, 'Uluru-Kata Tjuta');

      // Only the last stop has no onward leg.
      expect(redCentreStops.last.driveNext, isNull);
      for (int i = 0; i < redCentreStops.length - 1; i++) {
        expect(redCentreStops[i].driveNext, isNotNull, reason: redCentreStops[i].name);
      }

      // The Desert Park carries its own point, distinct from the Alice Springs stop.
      expect(redCentreStops[1].lat, -23.7180);
      expect(redCentreStops[1].lng, 133.8330);
      expect(redCentreStops[0].lat, -23.6980);
      expect(redCentreStops[0].lng, 133.8807);

      // Sourced verbatim from the desertpark POI.
      final poi = seedPois.firstWhere((p) => p.id == 'desertpark');
      expect(redCentreStops[1].name, poi.name);
      expect(redCentreStops[1].aiNote, poi.description);
      expect(redCentreStops[1].tags, [poi.tag]);

      // The three reused stops keep every field except the recomputed leg.
      expect(redCentreStops[0].hours, seedStops[4].hours);
      expect(redCentreStops[0].fee, seedStops[4].fee);
      expect(redCentreStops[0].aiNote, seedStops[4].aiNote);
      expect(redCentreStops[2], same(seedStops[5]));
      expect(redCentreStops[3], same(seedStops[6]));

      // Q3's known redundancy: hours and fee describe the park on both stops.
      expect(redCentreStops[1].hours, seedStops[4].hours);
      expect(redCentreStops[1].fee, seedStops[4].fee);
    });

    test('photoUrl is null on every seeded stop and POI', () {
      for (final stop in seedStops) {
        expect(stop.photoUrl, isNull, reason: stop.name);
      }
      for (final stop in redCentreStops) {
        expect(stop.photoUrl, isNull, reason: stop.name);
      }
      for (final poi in seedPois) {
        expect(poi.photoUrl, isNull, reason: poi.id);
      }
    });

    test('driveNext separator is the middle dot the prototype uses', () {
      for (final stop in seedStops) {
        final next = stop.driveNext;
        if (next == null) continue;
        expect(next, contains('·'), reason: stop.name);
        expect(next, isNot(contains('•')), reason: stop.name);
      }
      expect(seedStops[0].driveNext, '115 km · 1h 30m to Litchfield National Park');
      expect(seedSavedRoutes[0].meta, '8 days · 7 stops');
      expect(seedSavedRoutes[1].meta, '7 days · 4 stops');
    });

    test('seeded saved routes carry their own stops', () {
      expect(seedSavedRoutes[0].stops, same(seedStops));
      expect(seedSavedRoutes[1].stops, same(redCentreStops));
    });

    test('stop 0 is transcribed from the prototype, not the darwin-wf POI', () {
      final darwin = seedStops[0];
      expect(darwin.name, 'Darwin');
      expect(darwin.subtitle, 'Trip start \u00b7 NT capital');
      expect(
        darwin.hours,
        'Mindil Beach Sunset Market 5:00pm\u201310:00pm, Thu & Sun (May\u2013Oct)',
      );
      expect(darwin.fee, isNull);
      expect(
        darwin.aiNote,
        'Arrival day. The Mindil Beach sunset market runs Thursday and Sunday '
        'evenings if your dates line up.',
      );

      // The stop and the POI are two different points and must stay that way.
      expect(darwin.lat, -12.4634);
      expect(darwin.lng, 130.8456);
      final poi = seedPois.firstWhere((p) => p.id == 'darwin-wf');
      expect(poi.lat, -12.4680);
      expect(poi.lng, 130.8410);
      expect(darwin.lat, isNot(poi.lat));

      // The prototype's plan opens with the arrival entry.
      expect(darwin.detailedPlan.length, 6);
      expect(darwin.detailedPlan.first.time, '9:00am');
      expect(darwin.detailedPlan.first.activity, 'Land in Darwin, collect vehicle');
      expect(
        darwin.detailedPlan[3].activity,
        'Free time \u2014 Museum & Art Gallery of the NT',
      );
    });

    test('typographic punctuation matches the prototype', () {
      // The prototype uses en dashes in time ranges and em dashes in fees.
      // Plain hyphens here mean the copy was retyped rather than transcribed.
      for (final stop in seedStops) {
        expect(stop.hours, isNot(matches(RegExp(r'[0-9](am|pm)-'))), reason: stop.name);
      }
      expect(seedStops[2].fee, 'Kakadu Park Pass \u2014 \$40 adult / 7 days');
      expect(seedStops[6].fee, 'Uluru-Kata Tjuta Park Pass \u2014 \$38 adult / 3 days');
      expect(seedStops[6].subtitle, 'Trip end \u00b7 sunrise & sunset viewing');
    });

    test('OnboardingAnswers defaults and copyWith', () {
      const answers = OnboardingAnswers();
      expect(answers.days, 7);
      expect(answers.heat, 3);
      expect(answers.startLocation, isNull);
      expect(answers.endLocation, isNull);
      expect(answers.focus, isEmpty);
      expect(answers.ageRange, isNull);

      final updated = answers.copyWith(
        days: 10,
        startLocation: 'Darwin',
        endLocation: 'Alice Springs',
      );
      expect(updated.days, 10);
      expect(updated.startLocation, 'Darwin');
      expect(updated.endLocation, 'Alice Springs');
      expect(updated.heat, 3); // Unchanged
    });
  });

  group('Task-30 onboarding_options DoD', () {
    const allOptionLists = <List<AnswerOption>>[
      ageRangeOptions,
      companionsOptions,
      focusOptions,
      vehicleOptions,
      budgetOptions,
      accommodationOptions,
      activityLevelOptions,
      regionOptions,
      offRoadConfidenceOptions,
      campingPreferenceOptions,
      wildlifeInterestOptions,
    ];

    test('every options list has unique keys and unique labels', () {
      for (final options in allOptionLists) {
        final keys = options.map((o) => o.key).toSet();
        final labels = options.map((o) => o.label).toSet();
        expect(keys.length, options.length, reason: '$options');
        expect(labels.length, options.length, reason: '$options');
      }
    });

    test('labels match the prototype strings verbatim', () {
      expect(ageRangeOptions.map((o) => o.label), ['18–25', '26–35', '36–50', '50+']);
      expect(companionsOptions.map((o) => o.label), ['Solo', 'Couple', 'Family', 'Friends']);
      expect(focusOptions.map((o) => o.label), ['Nature', 'Aboriginal Culture', 'Adventure', 'Relaxation']);
      expect(vehicleOptions.map((o) => o.label), ['4x4', 'Campervan', 'Standard Car', 'Guided Tour']);
      expect(budgetOptions.map((o) => o.label), ['Budget', 'Mid-range', 'Luxury']);
      expect(accommodationOptions.map((o) => o.label), ['Camping', 'Motel/Cabin', 'Hotel']);
      expect(activityLevelOptions.map((o) => o.label), ['Low', 'Medium', 'High']);
      expect(regionOptions.map((o) => o.label), ['Top End', 'Red Centre', 'Full NT']);
      expect(offRoadConfidenceOptions.map((o) => o.label), ['Low', 'Medium', 'High']);
      expect(campingPreferenceOptions.map((o) => o.label), ['Camping all the way', 'Bit of both', 'Resort comfort']);
      expect(wildlifeInterestOptions.map((o) => o.label), ['Not fussed', 'Interested', 'Big draw']);
    });

    test('labelFor returns the label or falls back to the key', () {
      expect(labelFor(companionsOptions, 'couple'), 'Couple');
      expect(labelFor(companionsOptions, 'unknown_key'), 'unknown_key');
    });
  });
}
