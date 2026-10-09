import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:terra_nt/core/util/plan_response.dart';
import 'package:terra_nt/data/models/plan_failure.dart';

String _fixture(String name) =>
    File('test/fixtures/plan/$name').readAsStringSync();

void main() {
  group('parsePlanResponse — ok.json', () {
    final itinerary = parsePlanResponse(_fixture('ok.json'), days: 7);

    test('keeps all 5 stops', () {
      expect(itinerary.stops, hasLength(5));
    });

    test('keeps the title', () {
      expect(itinerary.title, 'Top End in 7 days: Darwin to Kakadu');
    });

    test('keeps a null fee', () {
      expect(itinerary.stops[0].fee, isNull);
    });

    test('keeps a null driveNext on the last stop', () {
      expect(itinerary.stops.last.driveNext, isNull);
    });

    test('keeps the https photoUrl', () {
      expect(
        itinerary.stops[2].photoUrl,
        'https://images.example.com/nitmiluk.jpg',
      );
    });

    test('keeps an unknown tag', () {
      expect(itinerary.stops[1].tags, contains('Foodie'));
    });

    test('keeps an empty detailedPlan', () {
      expect(itinerary.stops[3].detailedPlan, isEmpty);
    });
  });

  test('invalid_one_stop.json throws invalidResponse', () {
    expect(
      () => parsePlanResponse(_fixture('invalid_one_stop.json'), days: 7),
      throwsA(
        isA<PlanException>().having(
          (e) => e.failure,
          'failure',
          PlanFailure.invalidResponse,
        ),
      ),
    );
  });

  test('invalid_version.json throws invalidResponse', () {
    expect(
      () => parsePlanResponse(_fixture('invalid_version.json'), days: 7),
      throwsA(
        isA<PlanException>().having(
          (e) => e.failure,
          'failure',
          PlanFailure.invalidResponse,
        ),
      ),
    );
  });

  test('missing_title.json falls back to the day-count title', () {
    final itinerary = parsePlanResponse(
      _fixture('missing_title.json'),
      days: 7,
    );
    expect(itinerary.title, '7-day Northern Territory trip');
  });

  test('stop_without_name.json drops the nameless stop, keeps 4', () {
    final itinerary = parsePlanResponse(
      _fixture('stop_without_name.json'),
      days: 7,
    );
    expect(itinerary.stops, hasLength(4));
  });

  test('stop_empty_name.json drops the blank-name stop, keeps 4', () {
    final itinerary = parsePlanResponse(
      _fixture('stop_empty_name.json'),
      days: 7,
    );
    expect(itinerary.stops, hasLength(4));
  });

  test('stop_string_lat.json drops the malformed-lat stop, keeps 4', () {
    final itinerary = parsePlanResponse(
      _fixture('stop_string_lat.json'),
      days: 7,
    );
    expect(itinerary.stops, hasLength(4));
  });

  test('stop_outside_nt.json drops the out-of-box stop, keeps 4', () {
    final itinerary = parsePlanResponse(
      _fixture('stop_outside_nt.json'),
      days: 7,
    );
    expect(itinerary.stops, hasLength(4));
  });

  test('stop_missing_fields.json applies the contract fallbacks', () {
    final itinerary = parsePlanResponse(
      _fixture('stop_missing_fields.json'),
      days: 7,
    );
    final stop = itinerary.stops.firstWhere((s) => s.name == 'Bare Minimum Stop');
    expect(stop.subtitle, '');
    expect(stop.duration, '1 day');
    expect(stop.driveNext, isNull);
    expect(stop.hours, 'Hours not listed');
    expect(stop.fee, isNull);
    expect(stop.tags, isEmpty);
    expect(stop.aiNote, '');
    expect(stop.detailedPlan, isEmpty);
    expect(stop.photoUrl, isNull);
  });

  test('bad_plan_entry.json drops only the malformed entry', () {
    final itinerary = parsePlanResponse(
      _fixture('bad_plan_entry.json'),
      days: 7,
    );
    final stop = itinerary.stops.firstWhere(
      (s) => s.name == 'Kakadu National Park',
    );
    expect(stop.detailedPlan, hasLength(2));
    expect(stop.detailedPlan[0].activity, 'Yellow Water Billabong cruise');
    expect(
      stop.detailedPlan[1].activity,
      'Ubirr rock art walk and sunset lookout',
    );
  });

  test('bad_photo_url.json falls back to null', () {
    final itinerary = parsePlanResponse(
      _fixture('bad_photo_url.json'),
      days: 7,
    );
    final stop = itinerary.stops.firstWhere(
      (s) => s.name == 'Kakadu National Park',
    );
    expect(stop.photoUrl, isNull);
  });

  test('fifteen_stops.json keeps only the first 14', () {
    final itinerary = parsePlanResponse(
      _fixture('fifteen_stops.json'),
      days: 14,
    );
    expect(itinerary.stops, hasLength(14));
    expect(itinerary.stops.last.name, 'Stop 14');
  });

  group('failureForStatus', () {
    test('200 with an error body — the code wins', () {
      expect(
        failureForStatus(200, _fixture('error_cannot_plan.json')),
        PlanFailure.cannotPlan,
      );
    });

    test('400 → cannotPlan', () {
      expect(failureForStatus(400, '{}'), PlanFailure.cannotPlan);
    });

    test('401 → unauthorised', () {
      expect(failureForStatus(401, '{}'), PlanFailure.unauthorised);
    });

    test('422 → cannotPlan', () {
      expect(failureForStatus(422, '{}'), PlanFailure.cannotPlan);
    });

    test('429 → rateLimited', () {
      expect(
        failureForStatus(429, _fixture('error_rate_limited.json')),
        PlanFailure.rateLimited,
      );
    });

    test('500 → serverError', () {
      expect(failureForStatus(500, '{}'), PlanFailure.serverError);
    });

    test('503 → serverError', () {
      expect(failureForStatus(503, '{}'), PlanFailure.serverError);
    });

    test('400 with an unknown error code falls back to the status', () {
      expect(
        failureForStatus(400, _fixture('error_unknown_code.json')),
        PlanFailure.cannotPlan,
      );
    });
  });
}
