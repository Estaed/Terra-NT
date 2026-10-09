import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:terra_nt/app/crash_reporting.dart';

// IOClient wraps SocketException in a ClientException implementing both types.
class _ClientSocketException extends http.ClientException
    implements SocketException {
  _ClientSocketException(String url)
    : super('Failed host lookup', Uri.parse(url));

  @override
  InternetAddress? get address => null;
  @override
  OSError? get osError => null;
  @override
  int? get port => null;
}

void main() {
  test(
    'offline tile image failures are handled; other errors reach Firebase',
    () {
      final previousFlutter = FlutterError.onError;
      final previousPlatform = PlatformDispatcher.instance.onError;
      final previousPresent = FlutterError.presentError;
      addTearDown(() {
        FlutterError.onError = previousFlutter;
        PlatformDispatcher.instance.onError = previousPlatform;
        FlutterError.presentError = previousPresent;
      });
      final fatal = <FlutterErrorDetails>[];
      final presented = <FlutterErrorDetails>[];
      final platformFatal = <Object>[];
      FlutterError.presentError = presented.add;
      installCrashReporting(
        recordFlutterFatalError: fatal.add,
        recordFatalError: (error, stack) => platformFatal.add(error),
      );
      final offline = _ClientSocketException(
        'https://basemaps.cartocdn.com/rastertiles/dark_all/8/220/135@2x.png',
      );
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: offline,
          library: 'image resource service',
          silent: true,
        ),
      );
      expect(fatal, isEmpty);
      expect(presented, hasLength(1));

      final genuine = <FlutterErrorDetails>[
        FlutterErrorDetails(exception: StateError('widget failed')),
        FlutterErrorDetails(
          exception: StateError('invalid image data'),
          library: 'image resource service',
        ),
        FlutterErrorDetails(
          exception: http.ClientException('HTTP 403', offline.uri),
          library: 'image resource service',
        ),
        FlutterErrorDetails(
          exception: _ClientSocketException(
            'https://example.com/rastertiles/a.png',
          ),
          library: 'image resource service',
        ),
        FlutterErrorDetails(
          exception: _ClientSocketException(
            'https://basemaps.cartocdn.com/api',
          ),
          library: 'image resource service',
        ),
        // Even the same exception outside image loading is unexpected.
        FlutterErrorDetails(exception: offline, library: 'widgets library'),
      ];
      for (final details in genuine) {
        FlutterError.reportError(details);
      }
      expect(fatal, orderedEquals(genuine));
      expect(presented, hasLength(genuine.length + 1));
      final error = StateError('unhandled async failure');
      expect(
        PlatformDispatcher.instance.onError!(error, StackTrace.current),
        isTrue,
      );
      expect(platformFatal, [error]);
    },
  );
}
