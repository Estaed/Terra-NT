import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terra_nt/core/theme/motion.dart';
import 'package:terra_nt/shared/widgets/journey_scene.dart';

Widget _host({bool reduceMotion = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: const Scaffold(body: JourneyScene()),
  ),
);

void main() {
  testWidgets('the bundled scene is decorative and does not receive taps', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as AssetImage).assetName,
      'assets/images/scenes/start_trip.jpg',
    );
    expect(image.excludeFromSemantics, isTrue);
    void checkDecorative(SemanticsNode node) {
      expect(node.flagsCollection.isImage, isFalse);
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
      node.visitChildren((child) {
        checkDecorative(child);
        return true;
      });
    }

    checkDecorative(tester.getSemantics(find.byType(Scaffold)));
    expect(find.byType(Image).hitTestable(), findsNothing);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('the scene fades in and honours reduced motion', (tester) async {
    await tester.pumpWidget(_host());
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0);
    await tester.pump(AppMotion.entrance);
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(_host(reduceMotion: true));
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
  });

  testWidgets('leaving during the scene entrance disposes its ticker', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });
}
