import 'plan_entry.dart';

class Stop {
  final String name;
  final String subtitle;
  final double lat;
  final double lng;
  final String hours;
  final String? fee;
  final String duration;
  final String? driveNext;
  final String aiNote;
  final List<String> tags;
  final List<PlanEntry> detailedPlan;
  final String? photoUrl;

  const Stop({
    required this.name,
    required this.subtitle,
    required this.lat,
    required this.lng,
    required this.hours,
    this.fee,
    required this.duration,
    this.driveNext,
    required this.aiNote,
    required this.tags,
    required this.detailedPlan,
    this.photoUrl,
  });
}
