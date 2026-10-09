import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terra_nt/core/theme/colors.dart';
import 'package:terra_nt/core/theme/elevation.dart';
import 'package:terra_nt/core/theme/metrics.dart';
import 'package:terra_nt/core/theme/spacing.dart';
import 'package:terra_nt/shared/widgets/app_text_input.dart';

void main() {
  Widget host(Widget child) =>
      MaterialApp(home: Scaffold(body: Center(child: child)));

  Finder decoratedBox() => find.descendant(
    of: find.byType(AppTextInput),
    matching: find.byType(Container),
  );

  bool hasFocus(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus;

  Border borderOf(WidgetTester tester) =>
      (tester.widget<Container>(decoratedBox()).decoration as BoxDecoration)
              .border!
          as Border;

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

    group('hit target', () {
      testWidgets('tapping the decorated box padding focuses the field', (
        tester,
      ) async {
        await tester.pumpWidget(host(const AppTextInput(label: 'Email')));
        expect(hasFocus(tester), isFalse);

        final box = tester.getRect(decoratedBox());
        final inPadding = Offset(
          box.left + AppSpacing.padInputX / 2,
          box.center.dy,
        );
        expect(
          tester.getRect(find.byType(TextField)).contains(inPadding),
          isFalse,
          reason: 'the probe must land outside the inner field box',
        );

        await tester.tapAt(inPadding);
        await tester.pump();

        expect(hasFocus(tester), isTrue);
      });

      testWidgets('tapping the label focuses the field', (tester) async {
        await tester.pumpWidget(host(const AppTextInput(label: 'Email')));

        await tester.tap(find.text('Email'));
        await tester.pump();

        expect(hasFocus(tester), isTrue);
      });

      testWidgets('the control clears the minimum target in both dimensions', (
        tester,
      ) async {
        await tester.pumpWidget(host(const AppTextInput(label: 'Email')));

        final control = tester.getRect(find.byType(AppTextInput));
        expect(
          control.height,
          greaterThanOrEqualTo(AppMetrics.minTouchTarget),
        );
        expect(control.width, greaterThanOrEqualTo(AppMetrics.minTouchTarget));

        // Size alone is not the target: the whole box must accept a pointer,
        // gaps between the label and the field included.
        final target = tester.renderObject(find.byType(AppTextInput));
        const nudge = 0.5;
        for (final corner in [
          control.topLeft + const Offset(nudge, nudge),
          control.topRight + const Offset(-nudge, nudge),
          control.bottomLeft + const Offset(nudge, -nudge),
          control.bottomRight + const Offset(-nudge, -nudge),
        ]) {
          expect(
            tester
                .hitTestOnBinding(corner)
                .path
                .any((entry) => entry.target == target),
            isTrue,
            reason: 'a pointer at $corner must reach the input',
          );
        }
      });

      testWidgets('the decorated box keeps its painted height', (tester) async {
        await tester.pumpWidget(host(const AppTextInput(label: 'Email')));

        final field = tester.getSize(find.byType(TextField)).height;
        expect(
          tester.getSize(decoratedBox()).height,
          field +
              AppSpacing.padInputY * 2 +
              AppElevation.hairlineWidth * 2,
          reason: 'the box is one line of field plus its padding and hairline',
        );
      });

      testWidgets('the focus ring is unchanged', (tester) async {
        await tester.pumpWidget(host(const AppTextInput(label: 'Email')));

        final resting = borderOf(tester).top;
        expect(resting.color, AppColors.borderCard);
        expect(resting.width, AppElevation.hairlineWidth);

        await tester.tap(find.byType(TextField));
        await tester.pump();

        final ring = borderOf(tester).top;
        expect(ring.color, AppElevation.ringFocusColor);
        expect(ring.width, AppElevation.ringFocusWidth);
      });
    });
  });
}
