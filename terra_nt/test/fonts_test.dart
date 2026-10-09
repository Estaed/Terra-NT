import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

/// Proves the bundled fonts are actually declared and shipped.
///
/// Asserting only that a TextStyle carries the string 'Inter' would pass even
/// when the asset path in pubspec.yaml is wrong and the font never loads —
/// `flutter test` substitutes a stub font either way. `rootBundle.load` reads
/// the real asset manifest, so a misdeclared path fails here instead of
/// silently degrading typography at runtime.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const declaredFonts = <String>[
    'assets/fonts/Inter-Regular.ttf',
    'assets/fonts/Inter-Medium.ttf',
    'assets/fonts/Inter-SemiBold.ttf',
    'assets/fonts/Inter-Bold.ttf',
    'assets/fonts/JetBrainsMono-Regular.ttf',
    'assets/fonts/JetBrainsMono-Medium.ttf',
  ];

  group('bundled font assets', () {
    for (final path in declaredFonts) {
      test('$path is bundled and non-empty', () async {
        final data = await rootBundle.load(path);
        expect(
          data.lengthInBytes,
          greaterThan(0),
          reason: '$path resolved but is empty',
        );
      });
    }

    // Guards the guard: proves the assertions above are not passing vacuously.
    // If rootBundle silently returned data for anything, every check here would
    // be worthless, so a path that cannot exist must fail.
    test('a path that does not exist fails to load', () async {
      Object? caught;
      try {
        await rootBundle.load('assets/fonts/ThisFontDoesNotExist.ttf');
      } catch (error) {
        caught = error;
      }
      expect(
        caught,
        isNotNull,
        reason: 'rootBundle resolved a path that cannot exist, so the '
            'assertions above prove nothing',
      );
    });
  });

  testWidgets('Text resolves to the Inter family', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Text('Terra NT', style: TextStyle(fontFamily: 'Inter')),
      ),
    );

    final text = tester.widget<Text>(find.text('Terra NT'));
    expect(text.style?.fontFamily, 'Inter');
  });
}
