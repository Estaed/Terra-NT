import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terra_nt/core/theme/colors.dart';
import 'package:terra_nt/shared/widgets/app_chip.dart';

void main() {
  group('AppChipColors.resolve', () {
    test('selected returns surface2 / ink / hairlineStrong', () {
      final colors = AppChipColors.resolve(true);

      expect(colors.background, AppColors.surface2);
      expect(colors.foreground, AppColors.ink);
      expect(colors.border, AppColors.hairlineStrong);
    });

    test('unselected returns surface1 / inkSubtle / hairline', () {
      final colors = AppChipColors.resolve(false);

      expect(colors.background, AppColors.surface1);
      expect(colors.foreground, AppColors.inkSubtle);
      expect(colors.border, AppColors.hairline);
    });
  });

  group('AppChip', () {
    testWidgets('paints the resolved background for its selected state',
        (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: AppChip(label: 'Waterfalls', selected: true),
        ),
      );

      final decoration =
          tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).decoration
              as BoxDecoration;

      expect(decoration.color, AppColors.surface2);
    });
  });
}
