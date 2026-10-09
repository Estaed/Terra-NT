import '../models/stop.dart';
import '../models/poi.dart';
import '../models/saved_route.dart';
import '../models/plan_entry.dart';
import '../models/onboarding_answers.dart';

const List<Stop> seedStops = [
  Stop(
    name: "Darwin",
    subtitle: "Trip start · NT capital",
    hours: "Mindil Beach Sunset Market 5:00pm–10:00pm, Thu & Sun (May–Oct)",
    fee: null,
    lat: -12.4634,
    lng: 130.8456,
    driveNext: "115 km · 1h 30m to Litchfield National Park",
    duration: "1 day",
    aiNote: "Arrival day. The Mindil Beach sunset market runs Thursday and Sunday evenings if your dates line up.",
    tags: ["Relaxation", "Culture"],
    detailedPlan: [
      PlanEntry(time: "9:00am", activity: "Land in Darwin, collect vehicle"),
      PlanEntry(time: "11:00am", activity: "Check in, Waterfront precinct"),
      PlanEntry(time: "1:00pm", activity: "Lunch at Stokes Hill Wharf"),
      PlanEntry(time: "3:00pm", activity: "Free time — Museum & Art Gallery of the NT"),
      PlanEntry(time: "5:00pm", activity: "Mindil Beach Sunset Market"),
      PlanEntry(time: "7:30pm", activity: "Dinner, early night before the drive south"),
    ],
  ),
  Stop(
    name: "Litchfield National Park",
    subtitle: "Waterfalls & swimming holes",
    hours: "Park open 24 hours; visitor centre 8:00am–4:30pm",
    fee: "Free entry",
    lat: -13.1830,
    lng: 130.6805,
    driveNext: "230 km · 3h to Kakadu National Park",
    duration: "1 day",
    aiNote: "Closer to Darwin than Kakadu, so it works as the easier first stop. Wangi and Florence Falls are both safe for swimming in the dry season.",
    tags: ["Nature", "Adventure"],
    detailedPlan: [
      PlanEntry(time: "7:00am", activity: "Depart Darwin"),
      PlanEntry(time: "8:30am", activity: "Arrive Litchfield, Florence Falls walk & swim"),
      PlanEntry(time: "11:30am", activity: "Buley Rockholes"),
      PlanEntry(time: "1:00pm", activity: "Lunch, Wangi Falls picnic area"),
      PlanEntry(time: "2:30pm", activity: "Wangi Falls swim"),
      PlanEntry(time: "4:30pm", activity: "Tolmer Falls lookout"),
      PlanEntry(time: "6:00pm", activity: "Overnight near the park entrance"),
    ],
  ),
  Stop(
    name: "Kakadu National Park",
    subtitle: "Rock art, wetlands & wildlife",
    hours: "Bowali Visitor Centre 8:00am–5:00pm daily",
    fee: "Kakadu Park Pass — \$40 adult / 7 days",
    lat: -12.6692,
    lng: 132.8352,
    photoUrl: null,
    driveNext: "305 km · 3h 10m to Katherine",
    duration: "2 days",
    aiNote: "Two days covers Ubirr rock art and a Yellow Water cruise without rushing either. Both sit at the early-morning or late-afternoon end of the day to avoid the heat.",
    tags: ["Culture", "Nature", "Wildlife"],
    detailedPlan: [
      PlanEntry(time: "7:00am", activity: "Depart Litchfield"),
      PlanEntry(time: "10:00am", activity: "Arrive Jabiru, check in"),
      PlanEntry(time: "12:00pm", activity: "Bowali Visitor Centre"),
      PlanEntry(time: "3:00pm", activity: "Ubirr rock art walk"),
      PlanEntry(time: "5:30pm", activity: "Sunset over the Nadab floodplain"),
      PlanEntry(time: "6:30am", activity: "Day 2 - Yellow Water Billabong cruise"),
      PlanEntry(time: "9:30am", activity: "Breakfast, Cooinda"),
      PlanEntry(time: "11:00am", activity: "Nourlangie rock art site"),
      PlanEntry(time: "2:00pm", activity: "Free time - Gunlom plunge pool (seasonal)"),
      PlanEntry(time: "5:00pm", activity: "Depart for Katherine"),
    ],
  ),
  Stop(
    name: "Nitmiluk Gorge, Katherine",
    subtitle: "Gorge cruise & canoeing",
    hours: "Nitmiluk Tours desk 6:30am–5:00pm",
    fee: "Free park entry; gorge cruise from \$95",
    lat: -14.3103,
    lng: 132.4204,
    photoUrl: null,
    driveNext: "1,191 km · about 12h to Alice Springs",
    duration: "1 day",
    aiNote: "Allow about 12 hours for the long drive to Alice Springs, with breaks along the way. This stop stays light: one gorge cruise and an early night.",
    tags: ["Nature", "Adventure"],
    detailedPlan: [
      PlanEntry(time: "7:00am", activity: "Depart Kakadu"),
      PlanEntry(time: "10:30am", activity: "Arrive Katherine, check in"),
      PlanEntry(time: "12:00pm", activity: "Lunch in town"),
      PlanEntry(time: "2:00pm", activity: "Nitmiluk Gorge cruise (2hr)"),
      PlanEntry(time: "5:00pm", activity: "Katherine Hot Springs"),
      PlanEntry(time: "7:00pm", activity: "Dinner, early night"),
    ],
  ),
  Stop(
    name: "Alice Springs",
    subtitle: "Red Centre gateway",
    hours: "Alice Springs Desert Park 7:30am–6:00pm",
    fee: "Desert Park entry \$40 adult",
    lat: -23.6980,
    lng: 133.8807,
    photoUrl: null,
    driveNext: "473 km · 4h 50m to Kings Canyon",
    duration: "1 day",
    aiNote: "A rest day after the long drive. The Desert Park covers Central Australian ecology and Aboriginal land management in one stop.",
    tags: ["Culture", "Nature"],
    detailedPlan: [
      PlanEntry(time: "10:00am", activity: "Check in, rest after the drive"),
      PlanEntry(time: "1:00pm", activity: "Alice Springs Desert Park"),
      PlanEntry(time: "4:00pm", activity: "Anzac Hill lookout"),
      PlanEntry(time: "6:00pm", activity: "Todd Mall dinner precinct"),
    ],
  ),
  Stop(
    name: "Kings Canyon",
    subtitle: "Rim Walk & canyon views",
    hours: "Rim Walk starts by 8:00am in warmer months (heat closures can apply after 9:00am)",
    fee: "Free park entry",
    lat: -24.2634,
    lng: 131.5567,
    driveNext: "302 km · 3h 10m to Uluru",
    duration: "1 day",
    aiNote: "The Rim Walk is the highlight but starts early to beat the heat. The Kathleen Springs walk is a flatter alternative if mobility is a concern.",
    tags: ["Nature", "Adventure"],
    detailedPlan: [
      PlanEntry(time: "6:00am", activity: "Depart Alice Springs"),
      PlanEntry(time: "9:00am", activity: "Arrive Kings Canyon"),
      PlanEntry(time: "9:30am", activity: "Rim Walk (3.5hr, moderate-high effort)"),
      PlanEntry(time: "1:30pm", activity: "Lunch at Kings Canyon Resort"),
      PlanEntry(time: "3:30pm", activity: "Kathleen Springs walk (easy, optional)"),
      PlanEntry(time: "6:00pm", activity: "Sunset at the resort lookout"),
    ],
  ),
  Stop(
    name: "Uluru-Kata Tjuta",
    subtitle: "Trip end · sunrise & sunset viewing",
    hours: "Park open 5:00am–9:00pm (seasonal)",
    fee: "Uluru-Kata Tjuta Park Pass — \$38 adult / 3 days",
    lat: -25.3444,
    lng: 131.0369,
    driveNext: null,
    duration: "1 day",
    aiNote: "Base Walk in the cool of the morning, Kata Tjuta in the afternoon, then sunset at the designated viewing area to close the trip.",
    tags: ["Culture", "Nature", "Relaxation"],
    detailedPlan: [
      PlanEntry(time: "5:30am", activity: "Sunrise viewing, Talinguru Nyakunytjaku"),
      PlanEntry(time: "7:00am", activity: "Uluru Base Walk (10.6km, allow 3.5hr)"),
      PlanEntry(time: "11:00am", activity: "Cultural Centre"),
      PlanEntry(time: "1:00pm", activity: "Lunch, Yulara"),
      PlanEntry(time: "3:00pm", activity: "Kata Tjuta - Walpa Gorge walk"),
      PlanEntry(time: "6:00pm", activity: "Sunset viewing, trip ends"),
    ],
  ),
];

const List<Poi> seedPois = [
  Poi(id: "darwin-wf", name: "Darwin Waterfront", tag: "Relaxation", rating: "4.6", description: "Historic wave pool, dining and sunset views right on the harbour.", lat: -12.4680, lng: 130.8410),
  Poi(id: "mindil", name: "Mindil Beach", tag: "Culture", rating: "4.7", description: "Home to the famous sunset market, Thursdays and Sundays in the dry season.", lat: -12.4380, lng: 130.8330),
  Poi(id: "litchfield", name: "Litchfield National Park", tag: "Nature", rating: "4.8", description: "Waterfalls and safe swimming holes, an easy day trip from Darwin.", lat: -13.1830, lng: 130.6805),
  Poi(id: "ubirr", name: "Kakadu (Ubirr)", tag: "Culture", rating: "4.8", description: "Ancient rock art galleries overlooking the Nadab floodplain.", lat: -12.4260, lng: 132.9760),
  Poi(id: "nitmiluk", name: "Nitmiluk Gorge", tag: "Nature", rating: "4.7", description: "Thirteen sandstone gorges, best seen by cruise or canoe.", lat: -14.3103, lng: 132.4204),
  Poi(id: "desertpark", name: "Alice Springs Desert Park", tag: "Nature", rating: "4.6", description: "Central Australian wildlife and desert ecology in one walkable park.", lat: -23.7180, lng: 133.8330),
  Poi(id: "kingscanyon", name: "Kings Canyon", tag: "Adventure", rating: "4.9", description: "The Rim Walk is one of the most dramatic day walks in the Red Centre.", lat: -24.2634, lng: 131.5567),
  Poi(id: "uluru", name: "Uluru", tag: "Culture", rating: "4.9", description: "The Territory's most recognisable landmark, best at sunrise or sunset.", lat: -25.3444, lng: 131.0369, photoUrl: null),
  // Task-46: coordinates from Nominatim for the name as written; ratings read 2026-09-29.
  // Rating: https://www.tripadvisor.com/Attraction_Review-g256205-d258575-Reviews-Kata_Tjuta_The_Olgas-Uluru_Kata_Tjuta_National_Park_Red_Centre_Northern_Territory.html
  Poi(id: "kata-tjuta", name: "Kata Tjuta", tag: "Culture", rating: "4.7", description: "Thirty-six red domes, seen on the Walpa Gorge and Valley of the Winds walks.", lat: -25.2993, lng: 130.7406),
  // Rating: https://www.tripadvisor.com/Attraction_Review-g1729515-d12083838-Reviews-Ormiston_Gorge-West_MacDonnell_National_Park_Red_Centre_Northern_Territory.html
  Poi(id: "ormiston", name: "Ormiston Gorge", tag: "Nature", rating: "4.8", description: "Swim the permanent waterhole beneath the red cliffs of the West MacDonnells.", lat: -23.6323, lng: 132.7267),
  // Rating: https://www.tripadvisor.com.au/Attraction_Review-g494978-d496570-Reviews-Karlu_Karlu_Devils_Marbles_Conservation_Reserve-Wauchope_Barkly_Northern_Territory.html
  Poi(id: "karlu-karlu", name: "Karlu Karlu (Devils Marbles)", tag: "Culture", rating: "4.6", description: "Balanced granite boulders, best seen from the walking tracks at sunset.", lat: -20.5662, lng: 134.2917),
  // Rating: https://www.tripadvisor.com/Attraction_Review-g494973-d10467081-Reviews-Mataranka_Thermal_Pool-Mataranka_Top_End_Northern_Territory.html
  Poi(id: "mataranka", name: "Mataranka Thermal Pool", tag: "Relaxation", rating: "4.1", description: "A warm, spring-fed swimming pool shaded by palms in Elsey National Park.", lat: -14.9230, lng: 133.1356),
  // Rating: https://www.tripadvisor.com/Attraction_Review-g256203-d2502044-Reviews-Edith_Falls-Katherine_Top_End_Northern_Territory.html
  Poi(id: "edith-falls", name: "Leliyn (Edith Falls)", tag: "Nature", rating: "4.6", description: "Swim the plunge pool below the falls, or walk up to the upper pool.", lat: -14.1797, lng: 132.1875),
  // Rating: https://www.tripadvisor.com/Attraction_Review-g2213397-d566732-Reviews-Territory_Wildlife_Park-Berry_Springs_Top_End_Northern_Territory.html
  Poi(id: "wildlife-park", name: "Territory Wildlife Park", tag: "Wildlife", rating: "4.6", description: "Top End animals in natural habitats, with a walk-through aviary and bird show.", lat: -12.7065, lng: 130.9897),
  // Rating: https://www.tripadvisor.com/Attraction_Review-g1729515-d3265283-Reviews-Standley_Chasm_Angkerle-West_MacDonnell_National_Park_Red_Centre_Northern_Territ.html
  Poi(id: "standley-chasm", name: "Standley Chasm", tag: "Adventure", rating: "4.1", description: "Visit around midday, when the sun lights the narrow chasm walls orange.", lat: -23.7161, lng: 133.4702),
];

// Not const: redCentreStops is built from seedStops entries at run time.
final List<SavedRoute> seedSavedRoutes = [
  SavedRoute(id: "full-nt", title: "Full NT: Darwin to Uluru", meta: "8 days · 7 stops", dateLabel: "Generated today", stops: seedStops, days: 8),
  SavedRoute(id: "red-centre", title: "7 Days in the Red Centre", meta: "7 days · 4 stops", dateLabel: "Generated 3 days ago", stops: redCentreStops, days: 7),
];

const List<String> loadingMessages = [
  "Analyzing NT preferences...",
  "Consulting outback AI...",
  "Mapping stops across the Territory...",
  "Calculating drive times...",
  "Routing...",
];

const List<String> heatLabels = [
  "Not well at all",
  "Not great, but I'll manage",
  "It's fine either way",
  "Handles it pretty well",
  "Thrives in the heat",
];

// docs/PRD.md Q3: Alice Springs -> Alice Springs Desert Park -> Kings Canyon ->
// Uluru-Kata Tjuta. Three stops are seedStops entries reused verbatim; only the legs
// the shorter route changes are recomputed.
//
// The Desert Park's sourced fields come from the `desertpark` POI and the Alice Springs
// stop. Four fields the Stop model needs have no source in either, and Q3 records them
// as derived: `subtitle` trimmed from the POI description, `duration` matching every
// other single-day stop, `detailedPlan` built from the hours string plus the Alice
// Springs plan entry that already names the park, and the short in-town leg below.
const Stop _desertParkStop = Stop(
  name: "Alice Springs Desert Park",
  subtitle: "Wildlife & desert ecology",
  lat: -23.7180,
  lng: 133.8330,
  hours: "Alice Springs Desert Park 7:30am–6:00pm",
  fee: "Desert Park entry \$40 adult",
  duration: "1 day",
  driveNext: "473 km · 4h 50m to Kings Canyon",
  aiNote: "Central Australian wildlife and desert ecology in one walkable park.",
  tags: ["Nature"],
  detailedPlan: [
    PlanEntry(time: "7:30am", activity: "Desert Park opens"),
    PlanEntry(time: "1:00pm", activity: "Alice Springs Desert Park"),
    PlanEntry(time: "6:00pm", activity: "Desert Park closes"),
  ],
);

final List<Stop> redCentreStops = [
  // Alice Springs reused verbatim except for the recomputed leg to the Desert Park.
  Stop(
    name: seedStops[4].name,
    subtitle: seedStops[4].subtitle,
    lat: seedStops[4].lat,
    lng: seedStops[4].lng,
    hours: seedStops[4].hours,
    fee: seedStops[4].fee,
    duration: seedStops[4].duration,
    driveNext: "7 km · 15m to Alice Springs Desert Park",
    aiNote: seedStops[4].aiNote,
    tags: seedStops[4].tags,
    detailedPlan: seedStops[4].detailedPlan,
    photoUrl: seedStops[4].photoUrl,
  ),
  _desertParkStop,
  seedStops[5], // Kings Canyon, verbatim -- its leg to Uluru is unchanged.
  seedStops[6], // Uluru-Kata Tjuta, verbatim -- driveNext stays null as the last stop.
];

/// A regional chain drawn only from places already bundled with the app.
/// Endpoint aliases use the existing area's anchor, not invented town data.
List<Stop> localTripStops(OnboardingAnswers answers) {
  final regional = switch (answers.region) {
    'top_end' => seedStops.take(4).toList(),
    'red_centre' => redCentreStops,
    _ => seedStops,
  };
  Stop? endpoint(String? value) {
    final name = value?.trim();
    final alias = switch (name?.toLowerCase()) {
      'jabiru' => seedStops[2],
      'katherine' => seedStops[3],
      'uluru' => seedStops[6],
      _ => null,
    };
    if (alias != null) return _localStop(alias, name: name);
    for (final stop in [...seedStops, ...redCentreStops]) {
      if (stop.name.toLowerCase() == name?.toLowerCase()) return stop;
    }
    for (final poi in seedPois) {
      if (poi.name.toLowerCase() == name?.toLowerCase()) {
        return Stop(
          name: poi.name,
          subtitle: poi.description,
          lat: poi.lat,
          lng: poi.lng,
          hours: 'Check opening hours locally',
          duration: 'Suggested stop',
          aiNote: poi.description,
          tags: [poi.tag],
          detailedPlan: const [],
          photoUrl: poi.photoUrl,
        );
      }
    }
    return null;
  }

  final start = endpoint(answers.startLocation) ?? regional.first;
  final end = endpoint(answers.endLocation) ?? regional.last;
  bool samePlace(Stop a, Stop b) => a.lat == b.lat && a.lng == b.lng;
  final startIndex = regional.indexWhere((stop) => samePlace(stop, start));
  final endIndex = regional.indexWhere((stop) => samePlace(stop, end));
  final roundTrip = samePlace(start, end);
  final reverse = startIndex >= 0 && endIndex >= 0 && startIndex > endIndex;
  final chain = reverse ? regional.reversed.toList() : regional;
  final from = chain.indexWhere((stop) => samePlace(stop, start));
  final to = chain.indexWhere((stop) => samePlace(stop, end));
  final middle = roundTrip
      ? chain
      : chain.sublist(from < 0 ? 0 : from, to < 0 ? chain.length : to + 1);
  final selected = [
    start,
    for (final stop in middle)
      if (!samePlace(stop, start) && !samePlace(stop, end)) stop,
    end,
  ];
  // The original schedules and drive times belong to a different route. Keep
  // place information, but never present those old legs as a computed plan.
  return List<Stop>.unmodifiable([
    for (var index = 0; index < selected.length; index++)
      _localStop(
        selected[index],
        next: index + 1 < selected.length ? selected[index + 1].name : null,
      ),
  ]);
}

Stop _localStop(Stop stop, {String? name, String? next}) => Stop(
  name: name ?? stop.name,
  subtitle: stop.subtitle,
  lat: stop.lat,
  lng: stop.lng,
  hours: stop.hours,
  fee: stop.fee,
  duration: 'Suggested stop',
  driveNext: next == null ? null : 'Next: $next · check drive time locally',
  aiNote:
      'Offline suggestion from stored places. This route has not been '
      'checked by the planner.',
  tags: stop.tags,
  detailedPlan: const [],
  photoUrl: stop.photoUrl,
);