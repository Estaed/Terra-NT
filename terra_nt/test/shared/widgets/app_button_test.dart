import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terra_nt/core/theme/colors.dart';
import 'package:terra_nt/core/theme/metrics.dart';
import 'package:terra_nt/shared/widgets/app_button.dart';

void main() {
  // `Center` stands in for the free space every screen leaves around a button:
  // it hands the button loose constraints, so the painted box takes its own
  // height instead of the whole test surface.
  Widget host(Widget child) => Directionality(
    textDirection: TextDirection.ltr,
    child: Center(child: child),
  );

  /// Whether a pointer at [point] reaches the button rather than the space
  /// around it.
  bool reachesButton(WidgetTester tester, Offset point) {
    final target = tester.renderObject(find.byType(AppButton));
    return tester
        .hitTestOnBinding(point)
        .path
        .any((entry) => entry.target == target);
  }

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

    group('hit target', () {
      // The prototype paints 40px and 36px. Growing the finger target must not
      // grow either the painted box or the space the button occupies, or every
      // neighbour on every screen moves.
      for (final (size, painted) in const [
        (AppButtonSize.lg, AppMetrics.buttonHeightLg),
        (AppButtonSize.md, AppMetrics.buttonHeightMd),
      ]) {
        testWidgets('$size paints exactly $painted and claims no more space', (
          tester,
        ) async {
          await tester.pumpWidget(
            host(
              AppButton(
                onPressed: () {},
                size: size,
                child: const Text('Continue'),
              ),
            ),
          );

          expect(
            tester.getSize(find.byType(AnimatedContainer)).height,
            painted,
            reason: 'the painted box must keep the prototype height',
          );
          expect(
            tester.getSize(find.byType(AppButton)).height,
            painted,
            reason: 'the layout height the parent sees must not grow either',
          );
        });

        testWidgets('$size accepts a pointer across a full minimum target', (
          tester,
        ) async {
          await tester.pumpWidget(
            host(
              AppButton(
                onPressed: () {},
                size: size,
                child: const Text('Continue'),
              ),
            ),
          );

          // Height is the whole defect: a button fills the width its parent
          // offers, so the painted box is already past the minimum there.
          final paintedBox = tester.getRect(find.byType(AppButton));
          expect(paintedBox.height, lessThan(AppMetrics.minTouchTarget));
          expect(
            paintedBox.width,
            greaterThanOrEqualTo(AppMetrics.minTouchTarget),
          );

          final required = Rect.fromCenter(
            center: paintedBox.center,
            width: AppMetrics.minTouchTarget,
            height: AppMetrics.minTouchTarget,
          );
          const nudge = 0.5;
          for (final corner in [
            required.topLeft + const Offset(nudge, nudge),
            required.topRight + const Offset(-nudge, nudge),
            required.bottomLeft + const Offset(nudge, -nudge),
            required.bottomRight + const Offset(-nudge, -nudge),
          ]) {
            expect(
              reachesButton(tester, corner),
              isTrue,
              reason: 'a pointer at $corner must reach the button',
            );
          }
        });
      }

      testWidgets('a tap above the painted box still fires onPressed', (
        tester,
      ) async {
        var taps = 0;
        await tester.pumpWidget(
          host(AppButton(onPressed: () => taps++, child: const Text('Continue'))),
        );

        final paintedBox = tester.getRect(find.byType(AppButton));
        final inMargin = Offset(
          paintedBox.center.dx,
          paintedBox.top -
              (AppMetrics.minTouchTarget - AppMetrics.buttonHeightLg) / 4,
        );
        expect(paintedBox.contains(inMargin), isFalse);

        await tester.tapAt(inMargin);
        await tester.pump();

        expect(taps, 1, reason: 'the transparent margin must act as the button');
      });
    });
  });
}
