import '../models/itinerary.dart';
import '../models/onboarding_answers.dart';
import '../seed/seed_data.dart';

abstract interface class ItineraryRepository {
  Future<Itinerary> itineraryFor(OnboardingAnswers answers);
}

class SeedItineraryRepository implements ItineraryRepository {
  static const _fullNtTitle = 'Full NT: Darwin to Uluru';

  @override
  Future<Itinerary> itineraryFor(OnboardingAnswers answers) async {
    return const Itinerary(title: _fullNtTitle, stops: seedStops);
  }
}
