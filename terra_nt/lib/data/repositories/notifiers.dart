import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../app/plan_config.dart';
import '../../core/util/itinerary_ops.dart' as itinerary_ops;
import '../../core/util/poi_filter.dart';
import '../../core/util/saved_routes_ops.dart' as saved_routes_ops;
import '../models/auth_failure.dart';
import '../models/itinerary.dart';
import '../models/onboarding_answers.dart';
import '../models/poi.dart';
import '../models/saved_route.dart';
import '../models/session.dart';
import '../models/stop.dart';
import '../seed/seed_data.dart';
import 'auth_repository.dart';
import 'firebase_auth_repository.dart';
import 'firestore_saved_routes.dart';
import 'itinerary_repository.dart';
import 'preferences_store.dart';
import 'remote_itinerary_repository.dart';

/// Firestore is looked up only when a remote call is made -- that is, only for
/// a signed-in uid -- so a signed-out screen never needs a Firebase app.
final preferencesStoreProvider = Provider<PreferencesStore>((ref) {
  FirestoreSavedRoutes remote() =>
      FirestoreSavedRoutes(FirebaseFirestore.instance);
  return PreferencesStore(
    pullRemote: (uid) => remote().pull(uid),
    pushRemote: (uid, routes) => remote().push(uid, routes),
  );
});

final itineraryRepositoryProvider = Provider<ItineraryRepository>((ref) {
  if (planApiUrl.isEmpty) return SeedItineraryRepository();
  return RemoteItineraryRepository(
    client: http.Client(),
    baseUrl: Uri.parse(planApiUrl),
    idToken: () => ref.read(authRepositoryProvider).idToken(),
  );
});

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(FirebaseAuth.instance),
);

/// The Explore tab reads POIs through this concrete, read-only phase-one source.
/// It keeps seeded data behind the same provider boundary as the rest of the UI
/// without adding another repository seam.
final poiProvider = Provider<List<Poi>>(
  (ref) => List<Poi>.unmodifiable(seedPois),
);

final loadingMessagesProvider = Provider<List<String>>((ref) => loadingMessages);

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
  /// device itself; only the onboarding flag is ours to store. `currentEmail`
  /// never touches the network, so this completes offline at cold start.
  Future<void> load() async {
    state = Session(
      email: await _authRepository.currentEmail(),
      onboardingDone: await _store.readOnboardingDone(),
      uid: await _authRepository.currentUid(),
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
      uid: authenticated.uid,
    );
  }

  Future<void> createAccount(String email, String password) async {
    final authenticated = await _authRepository.createAccount(email, password);
    state = Session(
      email: authenticated.email,
      onboardingDone: state.onboardingDone,
      uid: authenticated.uid,
    );
  }

  Future<void> signInWithGoogle() async {
    final authenticated = await _authRepository.signInWithGoogle();
    state = Session(
      email: authenticated.email,
      onboardingDone: state.onboardingDone,
      uid: authenticated.uid,
    );
  }

  Future<void> setOnboardingDone(bool onboardingDone) async {
    state = Session(
      email: state.email,
      onboardingDone: onboardingDone,
      uid: state.uid,
    );
    await _store.saveOnboardingDone(onboardingDone);
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
    state = Session(email: null, onboardingDone: state.onboardingDone);
  }

  /// `docs/PRD.md` §3.9 order: the remote copy is cleared first, then the
  /// provider deletes, then local state goes. A failure at either of the first
  /// two -- a remote that could not be cleared surfaces as
  /// `AuthFailure.network`, a refused delete as `requiresRecentLogin` -- leaves
  /// the session, the onboarding flag and the saved routes untouched.
  Future<void> deleteAccount() async {
    final uid = state.uid;
    if (uid != null) {
      try {
        await _store.clearRemote(uid);
      } on AuthException {
        rethrow;
      } catch (_) {
        throw const AuthException(AuthFailure.network);
      }
    }
    await _authRepository.deleteAccount();
    state = const Session(email: null, onboardingDone: false);
    await _store.saveOnboardingDone(false);
    await ref
        .read(savedRoutesNotifierProvider.notifier)
        .clearForDeleteAccount();
  }
}

class SavedRoutesNotifier extends Notifier<List<SavedRoute>> {
  ({SavedRoute route, int index, String? uid})? _deletedRoute;

  PreferencesStore get _store => ref.read(preferencesStoreProvider);

  /// The account whose remote copy follows these routes, or null signed out.
  String? get _uid => ref.read(sessionNotifierProvider).uid;

  @override
  List<SavedRoute> build() => List<SavedRoute>.from(seedSavedRoutes);

  /// Local first: the remote is only adopted when this device has no copy.
  Future<void> load() async {
    _deletedRoute = null;
    state = await _store.readSavedRoutes(uid: _uid);
  }

  Future<void> upsert(SavedRoute route) async {
    if (_deletedRoute?.route.id == route.id) _deletedRoute = null;
    state = saved_routes_ops.upsert(state, route);
    await _store.saveSavedRoutes(state, uid: _uid);
  }

  Future<void> delete(String routeId) async {
    final index = state.indexWhere((route) => route.id == routeId);
    if (index == -1) return;
    _deletedRoute = (route: state[index], index: index, uid: _uid);
    state = state.where((route) => route.id != routeId).toList(growable: false);
    await _store.saveSavedRoutes(state, uid: _uid);
  }

  Future<void> undoDelete(String routeId) async {
    final deleted = _deletedRoute;
    if (deleted == null || deleted.route.id != routeId) return;
    _deletedRoute = null;
    if (deleted.uid != _uid) return;
    await _saveChange(
      saved_routes_ops.restore(state, deleted.route, deleted.index),
    );
  }

  Future<void> rename(String routeId, String title) =>
      _saveChange(saved_routes_ops.rename(state, routeId, title));

  Future<void> moveUp(String routeId) =>
      _saveChange(saved_routes_ops.move(state, routeId, -1));

  Future<void> moveDown(String routeId) =>
      _saveChange(saved_routes_ops.move(state, routeId, 1));

  Future<void> _saveChange(List<SavedRoute> routes) async {
    if (identical(routes, state)) return;
    state = routes;
    await _store.saveSavedRoutes(state, uid: _uid);
  }

  /// Runs after the session is cleared, so the uid is null and nothing is
  /// pushed; `SessionNotifier.deleteAccount` already cleared the remote.
  Future<void> clearForDeleteAccount() async {
    _deletedRoute = null;
    state = const [];
    await _store.saveSavedRoutes(state, uid: _uid);
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
  final bool hasRoute;

  ItineraryState({
    required this.itinerary,
    required List<int> order,
    required Set<int> skipped,
    required this.editMode,
    required this.hasRoute,
  }) : order = List<int>.unmodifiable(order),
       skipped = Set<int>.unmodifiable(skipped);

  factory ItineraryState.forItinerary(
    Itinerary itinerary, {
    bool hasRoute = true,
  }) {
    return ItineraryState(
      itinerary: itinerary,
      order: List<int>.generate(itinerary.stops.length, (index) => index),
      skipped: const {},
      editMode: false,
      hasRoute: hasRoute,
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
      hasRoute: hasRoute,
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
      hasRoute: false,
    );
  }

  Future<void> loadForAnswers(OnboardingAnswers answers) async {
    final itinerary = await _repository.itineraryFor(answers);
    state = ItineraryState.forItinerary(
      Itinerary(
        title: itinerary.title,
        stops: itinerary.stops,
        days: answers.days,
      ),
    );
  }

  /// A saved route carries its own stops, so opening one never asks the seam.
  void openSavedRoute(SavedRoute route) {
    state = ItineraryState.forItinerary(
      Itinerary(
        title: route.title,
        stops: route.stops,
        days: route.days,
        storedMeta: route.meta,
      ),
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
    state = ItineraryState.forItinerary(
      state.itinerary,
      hasRoute: state.hasRoute,
    );
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
  final bool deleteAccountConfirmation;

  /// The copy shown under the confirmation's body when a delete was refused,
  /// or null. Opening or cancelling the confirmation clears it.
  final String? deleteAccountError;

  /// True while the delete call is in flight, which is what disables the
  /// confirmation's Delete account button.
  final bool deleteAccountPending;

  const ProfileState({
    this.deleteAccountConfirmation = false,
    this.deleteAccountError,
    this.deleteAccountPending = false,
  });
}

class ProfileNotifier extends Notifier<ProfileState> {
  @override
  ProfileState build() => const ProfileState();

  void showDeleteAccountConfirmation() {
    state = ProfileState(deleteAccountConfirmation: true);
  }

  void cancelDeleteAccount() {
    state = const ProfileState();
  }

  /// Marks the delete call as in flight and drops any earlier failure copy.
  void startDeleteAccount() {
    state = ProfileState(
      deleteAccountConfirmation: true,
      deleteAccountPending: true,
    );
  }

  /// A refused delete leaves the confirmation open with its reason.
  void failDeleteAccount(String message) {
    state = ProfileState(
      deleteAccountConfirmation: true,
      deleteAccountError: message,
    );
  }
}
