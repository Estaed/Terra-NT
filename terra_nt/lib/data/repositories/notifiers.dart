import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/util/itinerary_ops.dart' as itinerary_ops;
import '../../core/util/poi_filter.dart';
import '../../core/util/saved_routes_ops.dart' as saved_routes_ops;
import '../models/itinerary.dart';
import '../models/onboarding_answers.dart';
import '../models/poi.dart';
import '../models/saved_route.dart';
import '../models/session.dart';
import '../models/stop.dart';
import '../seed/seed_data.dart';
import 'auth_repository.dart';
import 'firebase_auth_repository.dart';
import 'itinerary_repository.dart';
import 'preferences_store.dart';

final preferencesStoreProvider = Provider<PreferencesStore>(
  (ref) => PreferencesStore(),
);

final itineraryRepositoryProvider = Provider<ItineraryRepository>(
  (ref) => SeedItineraryRepository(),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(FirebaseAuth.instance),
);

/// The Explore tab reads POIs through this concrete, read-only phase-one source.
/// It keeps seeded data behind the same provider boundary as the rest of the UI
/// without adding another repository seam.
final poiProvider = Provider<List<Poi>>(
  (ref) => List<Poi>.unmodifiable(seedPois),
);

final sessionNotifierProvider = NotifierProvider<SessionNotifier, Session>(
  SessionNotifier.new,
);

final savedRoutesNotifierProvider =
    NotifierProvider<SavedRoutesNotifier, List<SavedRoute>>(
      SavedRoutesNotifier.new,
    );

final onboardingNotifierProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(
      OnboardingNotifier.new,
    );

final itineraryNotifierProvider =
    NotifierProvider<ItineraryNotifier, ItineraryState>(ItineraryNotifier.new);

final exploreNotifierProvider = NotifierProvider<ExploreNotifier, ExploreState>(
  ExploreNotifier.new,
);

final profileNotifierProvider = NotifierProvider<ProfileNotifier, ProfileState>(
  ProfileNotifier.new,
);

class SessionNotifier extends Notifier<Session> {
  PreferencesStore get _store => ref.read(preferencesStoreProvider);

  AuthRepository get _authRepository => ref.read(authRepositoryProvider);

  @override
  Session build() => const Session(email: null, onboardingDone: false);

  /// The signed-in user comes from the auth provider, which persisted it on the
  /// device itself; only the onboarding flag is ours to store.
  ///
  /// A provider that cannot answer means "nobody is signed in", not a launch
  /// that never finishes. `AppLaunch` renders a bare canvas until this future
  /// completes, and Blueprint's Key Constraints forbid a screen blocking at cold
  /// start, so an unavailable auth provider sends the user to Login or
  /// onboarding -- a recoverable state -- instead of a permanent blank screen.
  Future<void> load() async {
    String? email;
    try {
      email = await _authRepository.currentEmail();
    } on Exception {
      email = null;
    }
    state = Session(
      email: email,
      onboardingDone: await _store.readOnboardingDone(),
    );
  }

  Future<void> signInWithEmail(String email, String password) async {
    final authenticated = await _authRepository.signInWithEmail(
      email,
      password,
    );
    state = Session(
      email: authenticated.email,
      onboardingDone: state.onboardingDone,
    );
  }

  Future<void> createAccount(String email, String password) async {
    final authenticated = await _authRepository.createAccount(email, password);
    state = Session(
      email: authenticated.email,
      onboardingDone: state.onboardingDone,
    );
  }

  Future<void> signInWithGoogle() async {
    final authenticated = await _authRepository.signInWithGoogle();
    state = Session(
      email: authenticated.email,
      onboardingDone: state.onboardingDone,
    );
  }

  Future<void> setOnboardingDone(bool onboardingDone) async {
    state = Session(email: state.email, onboardingDone: onboardingDone);
    await _store.saveOnboardingDone(onboardingDone);
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
    state = Session(email: null, onboardingDone: state.onboardingDone);
  }

  /// The provider deletes first: a refused delete -- `requiresRecentLogin` --
  /// must leave the session, the onboarding flag and the saved routes untouched,
  /// so the exception propagates before anything here is cleared.
  Future<void> deleteAccount() async {
    await _authRepository.deleteAccount();
    state = const Session(email: null, onboardingDone: false);
    await _store.saveOnboardingDone(false);
    await ref
        .read(savedRoutesNotifierProvider.notifier)
        .clearForDeleteAccount();
  }
}

class SavedRoutesNotifier extends Notifier<List<SavedRoute>> {
  PreferencesStore get _store => ref.read(preferencesStoreProvider);

  @override
  List<SavedRoute> build() => List<SavedRoute>.from(seedSavedRoutes);

  Future<void> load() async {
    state = await _store.readSavedRoutes();
  }

  Future<void> upsert(SavedRoute route) async {
    state = saved_routes_ops.upsert(state, route);
    await _store.saveSavedRoutes(state);
  }

  Future<void> delete(String routeId) async {
    state = state.where((route) => route.id != routeId).toList(growable: false);
    await _store.saveSavedRoutes(state);
  }

  Future<void> clearForDeleteAccount() async {
    state = const [];
    await _store.saveSavedRoutes(state);
  }
}

class OnboardingState {
  final OnboardingAnswers answers;
  final int currentStep;

  const OnboardingState({
    this.answers = const OnboardingAnswers(),
    this.currentStep = 0,
  });

  OnboardingState copyWith({OnboardingAnswers? answers, int? currentStep}) {
    return OnboardingState(
      answers: answers ?? this.answers,
      currentStep: currentStep ?? this.currentStep,
    );
  }
}

class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => const OnboardingState();

  void setAnswers(OnboardingAnswers answers) {
    state = state.copyWith(answers: answers);
  }

  void setStep(int currentStep) {
    state = state.copyWith(currentStep: currentStep);
  }

  void reset() {
    state = const OnboardingState();
  }
}

class ItineraryState {
  final Itinerary itinerary;
  final List<int> order;
  final Set<int> skipped;
  final bool editMode;

  ItineraryState({
    required this.itinerary,
    required List<int> order,
    required Set<int> skipped,
    required this.editMode,
  }) : order = List<int>.unmodifiable(order),
       skipped = Set<int>.unmodifiable(skipped);

  factory ItineraryState.forItinerary(Itinerary itinerary) {
    return ItineraryState(
      itinerary: itinerary,
      order: List<int>.generate(itinerary.stops.length, (index) => index),
      skipped: const {},
      editMode: false,
    );
  }

  ItineraryState copyWith({
    Itinerary? itinerary,
    List<int>? order,
    Set<int>? skipped,
    bool? editMode,
  }) {
    return ItineraryState(
      itinerary: itinerary ?? this.itinerary,
      order: order ?? this.order,
      skipped: skipped ?? this.skipped,
      editMode: editMode ?? this.editMode,
    );
  }

  List<Stop> get visibleStops =>
      order.map((originalIndex) => itinerary.stops[originalIndex]).toList();
}

class ItineraryNotifier extends Notifier<ItineraryState> {
  ItineraryRepository get _repository => ref.read(itineraryRepositoryProvider);

  @override
  ItineraryState build() {
    return ItineraryState.forItinerary(
      const Itinerary(title: 'Full NT: Darwin to Uluru', stops: seedStops),
    );
  }

  Future<void> loadForAnswers(OnboardingAnswers answers) async {
    state = ItineraryState.forItinerary(
      await _repository.itineraryFor(answers),
    );
  }

  Future<void> loadForSavedRoute(String routeId) async {
    state = ItineraryState.forItinerary(
      await _repository.itineraryForSavedRoute(routeId),
    );
  }

  void setItinerary(Itinerary itinerary) {
    state = ItineraryState.forItinerary(itinerary);
  }

  void reorder(int from, int to) {
    state = state.copyWith(order: itinerary_ops.reorder(state.order, from, to));
  }

  void remove(int originalIndex) {
    state = state.copyWith(
      order: itinerary_ops.remove(state.order, originalIndex),
    );
  }

  void revertOne(int originalIndex) {
    state = state.copyWith(
      order: itinerary_ops.revertOne(state.order, originalIndex),
    );
  }

  void restoreRemoved() {
    state = state.copyWith(
      order: itinerary_ops.restoreRemoved(
        state.order,
        state.itinerary.stops.length,
      ),
    );
  }

  void toggleSkipped(int originalIndex) {
    final skipped = Set<int>.from(state.skipped);
    if (!skipped.add(originalIndex)) {
      skipped.remove(originalIndex);
    }
    state = state.copyWith(skipped: skipped);
  }

  void setEditMode(bool editMode) {
    state = state.copyWith(editMode: editMode);
  }

  /// Drops the session-only edits -- order, skipped stops, edit mode -- back to
  /// the loaded itinerary's baseline. "Plan again" calls it before onboarding
  /// restarts so the next generated route does not inherit the old ordering.
  void reset() {
    state = ItineraryState.forItinerary(state.itinerary);
  }
}

class ExploreState {
  final String? selectedPoiId;
  final String searchQuery;

  const ExploreState({this.selectedPoiId, this.searchQuery = ''});

  ExploreState copyWith({String? selectedPoiId, String? searchQuery}) {
    return ExploreState(
      selectedPoiId: selectedPoiId ?? this.selectedPoiId,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class ExploreNotifier extends Notifier<ExploreState> {
  @override
  ExploreState build() => const ExploreState();

  void selectPoi(String? poiId) {
    state = ExploreState(selectedPoiId: poiId, searchQuery: state.searchQuery);
  }

  void setSearchQuery(String searchQuery) {
    final selectedPoiId = state.selectedPoiId;
    final selectionRemainsVisible =
        selectedPoiId != null &&
        filterPois(
          ref.read(poiProvider),
          searchQuery,
        ).any((poi) => poi.id == selectedPoiId);
    state = ExploreState(
      selectedPoiId: selectionRemainsVisible ? selectedPoiId : null,
      searchQuery: searchQuery,
    );
  }
}

class ProfileState {
  final bool offlineMaps;
  final bool deleteAccountConfirmation;

  /// The copy shown under the confirmation's body when a delete was refused,
  /// or null. Opening or cancelling the confirmation clears it.
  final String? deleteAccountError;

  /// True while the delete call is in flight, which is what disables the
  /// confirmation's Delete account button.
  final bool deleteAccountPending;

  const ProfileState({
    this.offlineMaps = false,
    this.deleteAccountConfirmation = false,
    this.deleteAccountError,
    this.deleteAccountPending = false,
  });
}

class ProfileNotifier extends Notifier<ProfileState> {
  @override
  ProfileState build() => const ProfileState();

  void setOfflineMaps(bool offlineMaps) {
    state = ProfileState(
      offlineMaps: offlineMaps,
      deleteAccountConfirmation: state.deleteAccountConfirmation,
      deleteAccountError: state.deleteAccountError,
      deleteAccountPending: state.deleteAccountPending,
    );
  }

  void showDeleteAccountConfirmation() {
    state = ProfileState(
      offlineMaps: state.offlineMaps,
      deleteAccountConfirmation: true,
    );
  }

  void cancelDeleteAccount() {
    state = ProfileState(offlineMaps: state.offlineMaps);
  }

  /// Marks the delete call as in flight and drops any earlier failure copy.
  void startDeleteAccount() {
    state = ProfileState(
      offlineMaps: state.offlineMaps,
      deleteAccountConfirmation: true,
      deleteAccountPending: true,
    );
  }

  /// A refused delete leaves the confirmation open with its reason.
  void failDeleteAccount(String message) {
    state = ProfileState(
      offlineMaps: state.offlineMaps,
      deleteAccountConfirmation: true,
      deleteAccountError: message,
    );
  }
}
