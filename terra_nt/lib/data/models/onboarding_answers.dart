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
  final bool detailed;
  final String? offRoadConfidence;
  final int heat;
  final String? campingPreference;
  final String? wildlifeInterest;
  final bool? offGridComfortable;

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
    this.detailed = false,
    this.offRoadConfidence,
    this.heat = 3,
    this.campingPreference,
    this.wildlifeInterest,
    this.offGridComfortable,
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
    bool? detailed,
    String? offRoadConfidence,
    int? heat,
    String? campingPreference,
    String? wildlifeInterest,
    bool? offGridComfortable,
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
      detailed: detailed ?? this.detailed,
      offRoadConfidence: offRoadConfidence ?? this.offRoadConfidence,
      heat: heat ?? this.heat,
      campingPreference: campingPreference ?? this.campingPreference,
      wildlifeInterest: wildlifeInterest ?? this.wildlifeInterest,
      offGridComfortable: offGridComfortable ?? this.offGridComfortable,
    );
  }
}
