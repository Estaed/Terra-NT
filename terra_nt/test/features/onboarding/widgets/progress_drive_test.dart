import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terra_nt/core/theme/colors.dart';
import 'package:terra_nt/core/theme/metrics.dart';
import 'package:terra_nt/core/theme/motion.dart';
import 'package:terra_nt/features/onboarding/widgets/progress_drive.dart';

void main() {
  const trackWidth = 300.0;
  final car = find.byKey(const ValueKey('onboarding-progress-car'));
  final fill = find.byKey(const ValueKey('onboarding-progress-fill'));

  Future<void> pumpDrive(WidgetTester tester, int percent) => tester.pumpWidget(
    MaterialApp(
      home: Center(
        child: SizedBox(
          width: trackWidth,
          child: ProgressDrive(percent: percent),
        ),
      ),
    ),
  );

  testWidgets('the car and the fill drive to the new step and settle', (
    tester,
  ) async {
    await pumpDrive(tester, 20);
    // The car glyph bobs on its own ticker for as long as it is on screen;
    // the drive must add a second ticker and then give it back.
    final idleTickers = tester.binding.transientCallbackCount;
    final startX = tester.getTopLeft(car).dx;
    expect(tester.getSize(fill).width, trackWidth * 0.2);

    await pumpDrive(tester, 60);
    await tester.pump(AppMotion.onboardingStepSlide ~/ 2);
    final midX = tester.getTopLeft(car).dx;
    expect(midX, greaterThan(startX));
    expect(tester.getSize(fill).width, lessThan(trackWidth * 0.6));

    await tester.pump(AppMotion.onboardingStepSlide);
    final endX = tester.getTopLeft(car).dx;
    expect(endX, greaterThan(midX));
    expect(tester.getSize(fill).width, moreOrLessEquals(trackWidth * 0.6));
    // The drive's ticker unschedules on the frame after it completes.
    await tester.pump();
    expect(tester.binding.transientCallbackCount, idleTickers);
  });

  testWidgets('the track and its fill paint at the track height', (
    tester,
  ) async {
    await pumpDrive(tester, 20);

    final bar = find.byWidgetPredicate(
      (widget) =>
          widget is ColoredBox && widget.color == AppColors.hairlineStrong,
    );
    expect(
      tester.getSize(bar),
      const Size(trackWidth, AppMetrics.onboardingProgressHeight),
    );
    expect(tester.getSize(fill).height, AppMetrics.onboardingProgressHeight);
  });

  testWidgets('going back drives the car in reverse', (tester) async {
    await pumpDrive(tester, 60);
    final startX = tester.getTopLeft(car).dx;
    await pumpDrive(tester, 20);
    await tester.pump(AppMotion.onboardingStepSlide);
    expect(tester.getTopLeft(car).dx, lessThan(startX));
  });

  testWidgets('disposal mid-drive leaves no ticker running', (tester) async {
    await pumpDrive(tester, 20);
    final idleTickers = tester.binding.transientCallbackCount;
    await pumpDrive(tester, 60);
    await tester.pump(AppMotion.onboardingStepSlide ~/ 4);
    expect(tester.binding.transientCallbackCount, greaterThan(idleTickers));

    await tester.pumpWidget(const SizedBox());
    expect(tester.binding.transientCallbackCount, 0);
  });
}
