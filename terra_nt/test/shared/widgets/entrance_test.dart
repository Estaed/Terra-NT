import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terra_nt/core/theme/motion.dart';
import 'package:terra_nt/shared/widgets/entrance.dart';

double _opacity(WidgetTester tester) =>
    tester.widget<Opacity>(find.descendant(of: find.byType(Entrance), matching: find.byType(Opacity))).opacity;

Widget _host(Widget child, {bool reduceMotion = false}) => MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Directionality(textDirection: TextDirection.ltr, child: child),
    );

void main() {
  testWidgets('starts hidden and is fully shown after its duration', (tester) async {
    await tester.pumpWidget(_host(const Entrance(child: Text('x'))));
    expect(_opacity(tester), 0);
    await tester.pump(AppMotion.entrance);
    expect(_opacity(tester), 1);
  });

  testWidgets('a later index waits its stagger before starting', (tester) async {
    await tester.pumpWidget(_host(const Entrance(index: 3, child: Text('x'))));
    await tester.pump(AppMotion.entranceStagger * 3 - const Duration(milliseconds: 5));
    expect(_opacity(tester), 0);
    await tester.pump(AppMotion.entrance + const Duration(milliseconds: 5));
    expect(_opacity(tester), 1);
  });

  testWidgets('the stagger is capped', (tester) async {
    await tester.pumpWidget(_host(const Entrance(index: 500, child: Text('x'))));
    await tester.pump(AppMotion.entranceStagger * AppMotion.entranceStaggerMaxItems + AppMotion.entrance);
    expect(_opacity(tester), 1);
  });

  testWidgets('reduce motion shows the child at once', (tester) async {
    await tester.pumpWidget(_host(const Entrance(child: Text('x')), reduceMotion: true));
    expect(_opacity(tester), 1);
  });

  testWidgets('disposing mid-animation leaves nothing pending', (tester) async {
    await tester.pumpWidget(_host(const Entrance(index: 2, child: Text('x'))));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpWidget(_host(const SizedBox()));
    await tester.pump(AppMotion.entrance);
    expect(tester.takeException(), isNull);
    expect(find.byType(Entrance), findsNothing);
  });
}
