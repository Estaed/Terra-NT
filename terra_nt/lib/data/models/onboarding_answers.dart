/// The single-select and multi-select fields hold stable machine keys from
/// `data/seed/onboarding_options.dart`, not the labels the screen shows.
class OnboardingAnswers {
  final String? ageRange;
  final int days;
  final String? companions;
  final List<String> focus;
  final String? vehicle;
  final String? budget;
  final String? accommodation;
  final String? activityLevel;
  final String? region;
  final String? offRoadConfidence;
  final int heat;
  final String? campingPreference;
  final String? wildlifeInterest;
  final bool? offGridComfortable;
  final String? startLocation;
  final String? endLocation;

  const OnboardingAnswers({
    this.ageRange,
    this.days = 7,
    this.companions,
    this.focus = const [],
    this.vehicle,
    this.budget,
    this.accommodation,
    this.activityLevel,
    this.region,
    this.offRoadConfidence,
    this.heat = 3,
    this.campingPreference,
    this.wildlifeInterest,
    this.offGridComfortable,
    this.startLocation,
    this.endLocation,
  });

  OnboardingAnswers copyWith({
    String? ageRange,
    int? days,
    String? companions,
    List<String>? focus,
    String? vehicle,
    String? budget,
    String? accommodation,
    String? activityLevel,
    String? region,
    String? offRoadConfidence,
    int? heat,
    String? campingPreference,
    String? wildlifeInterest,
    bool? offGridComfortable,
    String? startLocation,
    String? endLocation,
  }) {
    return OnboardingAnswers(
      ageRange: ageRange ?? this.ageRange,
      days: days ?? this.days,
      companions: companions ?? this.companions,
      focus: focus ?? this.focus,
      vehicle: vehicle ?? this.vehicle,
      budget: budget ?? this.budget,
      accommodation: accommodation ?? this.accommodation,
      activityLevel: activityLevel ?? this.activityLevel,
      region: region ?? this.region,
      offRoadConfidence: offRoadConfidence ?? this.offRoadConfidence,
      heat: heat ?? this.heat,
      campingPreference: campingPreference ?? this.campingPreference,
      wildlifeInterest: wildlifeInterest ?? this.wildlifeInterest,
      offGridComfortable: offGridComfortable ?? this.offGridComfortable,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
    );
  }
}
