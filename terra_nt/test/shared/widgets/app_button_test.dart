import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terra_nt/core/theme/colors.dart';
import 'package:terra_nt/shared/widgets/app_button.dart';

void main() {
  Widget host(Widget child) => Directionality(textDirection: TextDirection.ltr, child: child);

  group('AppButton', () {
    testWidgets('renders its child', (tester) async {
      await tester.pumpWidget(
        host(AppButton(onPressed: () {}, child: const Text('Continue'))),
      );

      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('invokes onPressed on tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        host(AppButton(onPressed: () => tapped = true, child: const Text('Continue'))),
      );

      await tester.tap(find.byType(AppButton));
      await tester.pump();

      expect(tapped, isTrue, reason: 'tapping an enabled button must fire onPressed');
    });

    testWidgets('primary and secondary resolve different background colours',
        (tester) async {
      await tester.pumpWidget(
        host(AppButton(onPressed: () {}, child: const Text('A'))),
      );
      final primaryDecoration =
          tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).decoration
              as BoxDecoration;

      await tester.pumpWidget(
        host(
          AppButton(
            onPressed: () {},
            variant: AppButtonVariant.secondary,
            child: const Text('A'),
          ),
        ),
      );
      final secondaryDecoration =
          tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).decoration
              as BoxDecoration;

      expect(primaryDecoration.color, AppColors.actionPrimaryBg);
      expect(secondaryDecoration.color, AppColors.actionSecondaryBg);
      expect(
        primaryDecoration.color,
        isNot(secondaryDecoration.color),
        reason: 'primary and secondary must resolve distinct backgrounds',
      );
    });

    testWidgets('disabled swallows the tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        host(const AppButton(onPressed: null, child: Text('Continue'))),
      );

      await tester.tap(find.byType(AppButton));
      await tester.pump();

      expect(tapped, isFalse, reason: 'a null onPressed must not fire on tap');
    });
  });
}
