import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:terra_nt/data/models/auth_failure.dart';
import 'package:terra_nt/data/models/onboarding_answers.dart';
import 'package:terra_nt/data/models/plan_failure.dart';
import 'package:terra_nt/data/repositories/remote_itinerary_repository.dart';

String _fixture(String name) =>
    File('test/fixtures/plan/$name').readAsStringSync();

/// The fixtures carry non-Latin1 bytes (·, –); `http.Response`'s default
/// encoding is Latin1, so every body in this file goes through utf8.
http.Response _response(String body, int statusCode) => http.Response.bytes(
  utf8.encode(body),
  statusCode,
  headers: const {'content-type': 'application/json; charset=utf-8'},
);

const _answers = OnboardingAnswers(
  ageRange: '26_35',
  days: 7,
  companions: 'couple',
  focus: ['nature', 'aboriginal_culture'],
  vehicle: 'four_wd',
  budget: 'mid_range',
  accommodation: 'camping',
  activityLevel: 'medium',
  region: 'top_end',
  offRoadConfidence: 'medium',
  heat: 3,
  campingPreference: 'mixed',
  wildlifeInterest: 'interested',
  offGridComfortable: true,
  startLocation: 'Darwin',
  endLocation: 'Uluru',
);

RemoteItineraryRepository _repository(
  Future<http.Response> Function(http.Request) handler, {
  Future<String?> Function()? idToken,
  Duration timeout = const Duration(milliseconds: 50),
}) {
  return RemoteItineraryRepository(
    client: MockClient(handler),
    baseUrl: Uri.parse('https://plan.example.com'),
    idToken: idToken ?? () async => 'test-token',
    timeout: timeout,
  );
}

void main() {
  test('sends the request with the auth header, the requestId and stable keys', () async {
    http.Request? sent;
    final repository = _repository((request) async {
      sent = request;
      return _response(_fixture('ok.json'), 200);
    });

    final itinerary = await repository.itineraryFor(_answers);

    expect(itinerary.stops, hasLength(5));
    expect(sent!.method, 'POST');
    expect(sent!.url.toString(), 'https://plan.example.com/v1/itinerary');
    expect(sent!.headers['Authorization'], 'Bearer test-token');

    final body = jsonDecode(sent!.body) as Map<String, Object?>;
    expect(body['schemaVersion'], 1);
    final answers = body['answers'] as Map<String, Object?>;
    expect(answers['companions'], 'couple');
  });

  test('422 with error_cannot_plan.json throws cannotPlan', () async {
    final repository = _repository(
      (request) async =>
          _response(_fixture('error_cannot_plan.json'), 422),
    );

    await expectLater(
      repository.itineraryFor(_answers),
      throwsA(
        isA<PlanException>().having(
          (e) => e.failure,
          'failure',
          PlanFailure.cannotPlan,
        ),
      ),
    );
  });

  test('401 throws unauthorised', () async {
    final repository = _repository(
      (request) async => _response('{"error":{"code":"unauthorised"}}', 401),
    );

    await expectLater(
      repository.itineraryFor(_answers),
      throwsA(
        isA<PlanException>().having(
          (e) => e.failure,
          'failure',
          PlanFailure.unauthorised,
        ),
      ),
    );
  });

  test('429 throws rateLimited', () async {
    final repository = _repository(
      (request) async =>
          _response(_fixture('error_rate_limited.json'), 429),
    );

    await expectLater(
      repository.itineraryFor(_answers),
      throwsA(
        isA<PlanException>().having(
          (e) => e.failure,
          'failure',
          PlanFailure.rateLimited,
        ),
      ),
    );
  });

  test('500 throws serverError', () async {
    final repository = _repository(
      (request) async =>
          _response('{"error":{"code":"server_error"}}', 500),
    );

    await expectLater(
      repository.itineraryFor(_answers),
      throwsA(
        isA<PlanException>().having(
          (e) => e.failure,
          'failure',
          PlanFailure.serverError,
        ),
      ),
    );
  });

  test('a SocketException from the handler throws network', () async {
    final repository = _repository((request) async {
      throw const SocketException('refused');
    });

    await expectLater(
      repository.itineraryFor(_answers),
      throwsA(
        isA<PlanException>().having(
          (e) => e.failure,
          'failure',
          PlanFailure.network,
        ),
      ),
    );
  });

  test('a handler that delays past the timeout throws timeout', () async {
    final repository = _repository((request) async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return _response(_fixture('ok.json'), 200);
    });

    await expectLater(
      repository.itineraryFor(_answers),
      throwsA(
        isA<PlanException>().having(
          (e) => e.failure,
          'failure',
          PlanFailure.timeout,
        ),
      ),
    );
  });

  test('invalid_one_stop.json throws invalidResponse', () async {
    final repository = _repository(
      (request) async => _response(_fixture('invalid_one_stop.json'), 200),
    );

    await expectLater(
      repository.itineraryFor(_answers),
      throwsA(
        isA<PlanException>().having(
          (e) => e.failure,
          'failure',
          PlanFailure.invalidResponse,
        ),
      ),
    );
  });

  test('a null token throws unauthorised without sending a request', () async {
    var requestSent = false;
    final repository = _repository(
      (request) async {
        requestSent = true;
        return _response(_fixture('ok.json'), 200);
      },
      idToken: () async => null,
    );

    await expectLater(
      repository.itineraryFor(_answers),
      throwsA(
        isA<PlanException>().having(
          (e) => e.failure,
          'failure',
          PlanFailure.unauthorised,
        ),
      ),
    );
    expect(requestSent, isFalse);
  });

  test('retry() resends the same requestId as the first attempt', () async {
    final requestIds = <String>[];
    final repository = _repository((request) async {
      final body = jsonDecode(request.body) as Map<String, Object?>;
      requestIds.add(body['requestId'] as String);
      return _response(_fixture('ok.json'), 200);
    });

    await repository.itineraryFor(_answers);
    final firstId = repository.lastRequestId;
    await repository.retry();

    expect(requestIds, hasLength(2));
    expect(requestIds[0], firstId);
    expect(requestIds[1], firstId);
  });

  test('retry() before itineraryFor() throws StateError', () {
    final repository = _repository(
      (request) async => _response(_fixture('ok.json'), 200),
    );

    expect(repository.retry, throwsStateError);
  });

  test('an AuthException from idToken() throws network', () async {
    final repository = _repository(
      (request) async => _response(_fixture('ok.json'), 200),
      idToken: () async => throw const AuthException(AuthFailure.network),
    );

    await expectLater(
      repository.itineraryFor(_answers),
      throwsA(
        isA<PlanException>().having(
          (e) => e.failure,
          'failure',
          PlanFailure.network,
        ),
      ),
    );
  });

  test('a ClientException from the handler throws network', () async {
    final repository = _repository((request) async {
      throw http.ClientException('connection closed');
    });

    await expectLater(
      repository.itineraryFor(_answers),
      throwsA(
        isA<PlanException>().having(
          (e) => e.failure,
          'failure',
          PlanFailure.network,
        ),
      ),
    );
  });
}
