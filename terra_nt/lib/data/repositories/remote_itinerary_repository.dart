import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../app/plan_config.dart';
import '../../core/util/plan_request.dart';
import '../../core/util/plan_response.dart';
import '../models/auth_failure.dart';
import '../models/itinerary.dart';
import '../models/onboarding_answers.dart';
import '../models/plan_failure.dart';
import 'itinerary_repository.dart';

/// The second implementation of the generation seam
/// (`docs/PHASE-3-CONTRACT.md`, `docs/PRD.md` D14). Chosen only when
/// `PLAN_API_URL` is configured; a keyless checkout and the test suite never
/// reach this class.
class RemoteItineraryRepository implements ItineraryRepository {
  RemoteItineraryRepository({
    required this.client,
    required this.baseUrl,
    required this.idToken,
    this.timeout = planTimeout,
    this.requestId = newRequestId,
  });

  final http.Client client;

  /// No trailing slash.
  final Uri baseUrl;

  /// `AuthRepository.idToken()`. Returns null when signed out; throws
  /// [AuthException] when it cannot reach Firebase to refresh.
  final Future<String?> Function() idToken;

  final Duration timeout;

  /// Generates the wire `requestId` for a fresh attempt; overridable so a
  /// test can assert on a known value.
  final String Function() requestId;

  String? _lastRequestId;
  OnboardingAnswers? _lastAnswers;

  /// The `requestId` of the last attempt, reused by [retry].
  String? get lastRequestId => _lastRequestId;

  /// One attempt. Throws [PlanException]; never returns a partial itinerary.
  @override
  Future<Itinerary> itineraryFor(OnboardingAnswers answers) {
    _lastAnswers = answers;
    return _attempt(answers, requestId());
  }

  /// Resends the last answers with the same `requestId`
  /// (`docs/PHASE-3-CONTRACT.md` §1, idempotency).
  Future<Itinerary> retry() {
    final answers = _lastAnswers;
    final id = _lastRequestId;
    if (answers == null || id == null) {
      throw StateError('retry() called before itineraryFor()');
    }
    return _attempt(answers, id);
  }

  Future<Itinerary> _attempt(OnboardingAnswers answers, String id) async {
    _lastRequestId = id;

    final String? token;
    try {
      token = await idToken();
    } on AuthException {
      throw const PlanException(PlanFailure.network);
    }
    if (token == null) {
      throw const PlanException(PlanFailure.unauthorised);
    }

    final http.Response response;
    try {
      response = await client
          .post(
            Uri.parse('$baseUrl/v1/itinerary'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json',
            },
            body: jsonEncode(buildPlanRequest(answers, requestId: id)),
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const PlanException(PlanFailure.timeout);
    } on SocketException {
      throw const PlanException(PlanFailure.network);
    } on http.ClientException {
      throw const PlanException(PlanFailure.network);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PlanException(
        failureForStatus(response.statusCode, response.body),
      );
    }

    return parsePlanResponse(response.body, days: answers.days);
  }
}
