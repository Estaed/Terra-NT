/// A single-select onboarding option: the stable wire [key] paired with the
/// [label] the screen shows. `docs/PHASE-3-CONTRACT.md` §2 fixes the keys.
class AnswerOption {
  final String key;
  final String label;
  final String? description;
  final String? imageAsset;
  const AnswerOption(this.key, this.label, {this.description, this.imageAsset});
}

/// Returns the label for [key] in [options], or [key] itself when unknown.
String labelFor(List<AnswerOption> options, String key) {
  for (final option in options) {
    if (option.key == key) return option.label;
  }
  return key;
}

const ageRangeOptions = [
  AnswerOption('18_25', '18–25'),
  AnswerOption('26_35', '26–35'),
  AnswerOption('36_50', '36–50'),
  AnswerOption('50_plus', '50+'),
];

const companionsOptions = [
  AnswerOption('solo', 'Solo'),
  AnswerOption('couple', 'Couple'),
  AnswerOption('family', 'Family'),
  AnswerOption('friends', 'Friends'),
];

const focusOptions = [
  AnswerOption('nature', 'Nature'),
  AnswerOption('aboriginal_culture', 'Aboriginal Culture'),
  AnswerOption('adventure', 'Adventure'),
  AnswerOption('relaxation', 'Relaxation'),
];

const vehicleOptions = [
  AnswerOption('four_wd', '4x4'),
  AnswerOption('campervan', 'Campervan'),
  AnswerOption('standard_car', 'Standard Car'),
  AnswerOption('guided_tour', 'Guided Tour'),
];

const budgetOptions = [
  AnswerOption('budget', 'Budget'),
  AnswerOption('mid_range', 'Mid-range'),
  AnswerOption('luxury', 'Luxury'),
];

const accommodationOptions = [
  AnswerOption('camping', 'Camping'),
  AnswerOption('motel_cabin', 'Motel/Cabin'),
  AnswerOption('hotel', 'Hotel'),
];

const activityLevelOptions = [
  AnswerOption('low', 'Low'),
  AnswerOption('medium', 'Medium'),
  AnswerOption('high', 'High'),
];

const regionOptions = [
  AnswerOption(
    'top_end',
    'Top End',
    description: 'Darwin, Litchfield, Kakadu',
    imageAsset: 'assets/images/scenes/top_end.jpg',
  ),
  AnswerOption(
    'red_centre',
    'Red Centre',
    description: 'Alice Springs, Uluru, Kings Canyon',
    imageAsset: 'assets/images/scenes/red_centre.jpg',
  ),
  AnswerOption(
    'full_nt',
    'Full NT',
    description: 'Top End to Red Centre',
    imageAsset: 'assets/images/scenes/full_nt.jpg',
  ),
];

const offRoadConfidenceOptions = [
  AnswerOption('low', 'Low'),
  AnswerOption('medium', 'Medium'),
  AnswerOption('high', 'High'),
];

const campingPreferenceOptions = [
  AnswerOption('camping', 'Camping all the way'),
  AnswerOption('mixed', 'Bit of both'),
  AnswerOption('resort', 'Resort comfort'),
];

const wildlifeInterestOptions = [
  AnswerOption('not_fussed', 'Not fussed'),
  AnswerOption('interested', 'Interested'),
  AnswerOption('big_draw', 'Big draw'),
];

/// Endpoint names already represented in the seed itinerary. Unlike enum-style
/// answer keys, the planning contract sends these location names verbatim.
const tripLocationOptions = [
  'Darwin',
  'Jabiru',
  'Katherine',
  'Alice Springs',
  'Uluru',
];
