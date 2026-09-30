import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terra_nt/core/theme/metrics.dart';
import 'package:terra_nt/core/theme/motion.dart';
import 'package:terra_nt/features/onboarding/widgets/progress_drive.dart';

void main() {
  const trackWidth = 300.0;
  final car = find.byKey(const ValueKey('onboarding-progress-car'));
  final fill = find.byKey(const ValueKey('onboarding-progress-fill'));

  Future<void> pumpDrive(
    WidgetTester tester,
    int percent, {
    bool reduceMotion = false,
  }) => tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: child!,
      ),
      home: Center(
        child: SizedBox(
          width: trackWidth,
          child: ProgressDrive(percent: percent),
        ),
      ),
    ),
  );

  testWidgets('reduced motion places the car and fill immediately both ways', (
    tester,
  ) async {
    await pumpDrive(tester, 20, reduceMotion: true);
    final startX = tester.getTopLeft(car).dx;
    await pumpDrive(tester, 60, reduceMotion: true);
    expect(tester.getSize(fill).width, trackWidth * 0.6);
    expect(tester.getTopLeft(car).dx, greaterThan(startX));
    await pumpDrive(tester, 20, reduceMotion: true);
    expect(tester.getSize(fill).width, trackWidth * 0.2);
    expect(tester.getTopLeft(car).dx, startX);
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('enabling reduced motion during a drive stops at the target', (
    tester,
  ) async {
    await pumpDrive(tester, 20);
    await pumpDrive(tester, 60);
    await tester.pump(AppMotion.onboardingStepSlide ~/ 4);
    expect(tester.getSize(fill).width, lessThan(trackWidth * 0.6));
    await pumpDrive(tester, 60, reduceMotion: true);
    await tester.pump();
    expect(tester.getSize(fill).width, trackWidth * 0.6);
    expect(tester.binding.transientCallbackCount, 0);
  });

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

  testWidgets('the road and its fill paint at the road height', (
    tester,
  ) async {
    await pumpDrive(tester, 20);

    expect(
      tester.getSize(find.byKey(const ValueKey('onboarding-progress-road'))),
      const Size(trackWidth, AppMetrics.progressRoadHeight),
    );
    expect(tester.getSize(fill).height, AppMetrics.progressRoadHeight);
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
