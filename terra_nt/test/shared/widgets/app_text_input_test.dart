import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terra_nt/shared/widgets/app_text_input.dart';

void main() {
  Widget host(Widget child) =>
      MaterialApp(home: Scaffold(body: Center(child: child)));

  group('AppTextInput', () {
    testWidgets('obscureText: true hides input', (tester) async {
      await tester.pumpWidget(host(const AppTextInput(label: 'Password', obscureText: true)));

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.obscureText, isTrue);
    });

    testWidgets('error slot renders supplied text', (tester) async {
      await tester.pumpWidget(
        host(const AppTextInput(label: 'Email', errorText: 'Required')),
      );

      expect(find.text('Required'), findsOneWidget);
    });

    testWidgets('errorText: null occupies zero height', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        host(AppTextInput(key: key, label: 'Email')),
      );

      final shrinkFinder = find.descendant(
        of: find.byKey(key),
        matching: find.byType(SizedBox),
      );
      final sizes = tester.widgetList<SizedBox>(shrinkFinder);
      final errorSlot = sizes.firstWhere((box) => box.height == 0 && box.width == 0);
      expect(
        tester.getSize(find.byWidget(errorSlot)).height,
        0,
        reason: 'a null errorText must not reserve vertical space',
      );
    });

    testWidgets('disposes its FocusNode cleanly', (tester) async {
      await tester.pumpWidget(host(const AppTextInput(label: 'Email')));
      await tester.pumpWidget(const SizedBox());

      expect(tester.takeException(), isNull);
    });
  });
}
