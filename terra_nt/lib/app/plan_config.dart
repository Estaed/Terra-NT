/// `docs/PHASE-3-CONTRACT.md` §6. Empty means no server is configured, so
/// `itineraryRepositoryProvider` keeps [SeedItineraryRepository] and nothing
/// in the app blocks on the network at cold start.
const planApiUrl = String.fromEnvironment('PLAN_API_URL');

/// `docs/PHASE-3-CONTRACT.md` §1 — one value, no per-phase split.
const planTimeout = Duration(milliseconds: 60000);
