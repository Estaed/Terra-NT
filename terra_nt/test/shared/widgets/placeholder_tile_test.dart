import 'package:flutter/widgets.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terra_nt/shared/widgets/app_icon.dart';
import 'package:terra_nt/shared/widgets/placeholder_tile.dart';

void main() {
  testWidgets('.square(size: 76) measures 76x76 and contains the image icon',
      (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: PlaceholderTile.square(size: 76)),
      ),
    );

    expect(tester.getSize(find.byType(PlaceholderTile)), const Size(76, 76));

    final icon = tester.widget<AppIcon>(find.byType(AppIcon));
    expect(icon.icon, LucideIcons.image);
  });
}
