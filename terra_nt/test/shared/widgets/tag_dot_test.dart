import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terra_nt/core/theme/colors.dart';
import 'package:terra_nt/shared/widgets/tag_dot.dart';

void main() {
  Widget host(Widget child) => Directionality(textDirection: TextDirection.ltr, child: child);

  group('TagDot', () {
    testWidgets('paints the given colour on its dot', (tester) async {
      await tester.pumpWidget(
        host(const TagDot(color: AppColors.tagGreen, label: 'Waterfalls')),
      );

      final dot = tester
          .widgetList<Container>(find.byType(Container))
          .firstWhere((c) => (c.decoration as BoxDecoration).color == AppColors.tagGreen);
      final decoration = dot.decoration as BoxDecoration;

      expect(decoration.color, AppColors.tagGreen);
    });

    testWidgets('bare renders without the tag chip container', (tester) async {
      await tester.pumpWidget(
        host(const TagDot(color: AppColors.tagGreen, label: 'Waterfalls')),
      );

      expect(find.byType(Container), findsOneWidget, reason: 'only the dot itself');
    });

    testWidgets('bordered wraps the dot in the tag chip container', (tester) async {
      await tester.pumpWidget(
        host(
          const TagDot(color: AppColors.tagGreen, label: 'Waterfalls', bordered: true),
        ),
      );

      expect(find.byType(Container), findsNWidgets(2), reason: 'the chip plus the dot');
    });
  });
}
