import 'package:flutter_test/flutter_test.dart';
import 'package:terra_nt/data/models/itinerary.dart';
import 'package:terra_nt/data/models/onboarding_answers.dart';
import 'package:terra_nt/data/seed/seed_data.dart';

void main() {
  group('Task-03 DoD Tests', () {
    test('seedStops.length == 7 and in correct order', () {
      expect(seedStops.length, 7);
      expect(seedStops[0].name, 'Darwin Waterfront');
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

    test('seedPois.length == 8 and Ubirr coordinates are correct', () {
      expect(seedPois.length, 8);
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

    test('OnboardingAnswers defaults and copyWith', () {
      const answers = OnboardingAnswers();
      expect(answers.days, 7);
      expect(answers.heat, 3);
      expect(answers.detailed, false);
      expect(answers.focus, isEmpty);
      expect(answers.ageRange, isNull);

      final updated = answers.copyWith(days: 10, detailed: true);
      expect(updated.days, 10);
      expect(updated.detailed, true);
      expect(updated.heat, 3); // Unchanged
    });
  });
}
