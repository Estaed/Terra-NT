import '../models/itinerary.dart';
import '../models/onboarding_answers.dart';
import '../seed/seed_data.dart';

abstract interface class ItineraryRepository {
  Future<Itinerary> itineraryFor(OnboardingAnswers answers);
}

/// Both implementations have the same on-device fallback. An extension keeps
/// it available through the existing seam without changing the remote contract.
extension OfflineItinerary on ItineraryRepository {
  Itinerary offlineItineraryFor(OnboardingAnswers answers) {
    final stops = localTripStops(answers);
    return Itinerary(
      title: 'Offline suggestion: ${stops.first.name} to ${stops.last.name}',
      stops: stops,
      days: answers.days,
    );
  }
}

class SeedItineraryRepository implements ItineraryRepository {
  static const _fullNtTitle = 'Full NT: Darwin to Uluru';

  @override
  Future<Itinerary> itineraryFor(OnboardingAnswers answers) async {
    return const Itinerary(title: _fullNtTitle, stops: seedStops);
  }
}
