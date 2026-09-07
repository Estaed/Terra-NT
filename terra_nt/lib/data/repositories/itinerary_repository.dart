import '../models/itinerary.dart';
import '../models/onboarding_answers.dart';
import '../seed/seed_data.dart';

abstract interface class ItineraryRepository {
  Future<Itinerary> itineraryFor(OnboardingAnswers answers);
  Future<Itinerary> itineraryForSavedRoute(String routeId);
}

class SeedItineraryRepository implements ItineraryRepository {
  static const _fullNtTitle = 'Full NT: Darwin to Uluru';
  static const _redCentreTitle = '7 Days in the Red Centre';

  @override
  Future<Itinerary> itineraryFor(OnboardingAnswers answers) async {
    return const Itinerary(title: _fullNtTitle, stops: seedStops);
  }

  @override
  Future<Itinerary> itineraryForSavedRoute(String routeId) async {
    if (routeId == 'red-centre') {
      return Itinerary(title: _redCentreTitle, stops: redCentreStops);
    }
    return const Itinerary(title: _fullNtTitle, stops: seedStops);
  }
}
