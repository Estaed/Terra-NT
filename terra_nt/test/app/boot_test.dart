import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terra_nt/main.dart';

void main() {
  testWidgets('app boots inside a ProviderScope without throwing',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TerraNtApp()));

    expect(tester.takeException(), isNull);
    expect(find.text('Terra NT'), findsOneWidget);
  });

  testWidgets('Riverpod is wired at the root', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TerraNtApp()));

    // A container resolved from the tree proves ProviderScope is above the app,
    // which is what every later task's notifiers depend on.
    final element = tester.element(find.byType(TerraNtApp));
    expect(ProviderScope.containerOf(element, listen: false), isNotNull);
  });
}
