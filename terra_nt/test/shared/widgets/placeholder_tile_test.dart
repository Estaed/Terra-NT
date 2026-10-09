import 'package:flutter/widgets.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terra_nt/shared/widgets/app_icon.dart';
import 'package:terra_nt/shared/widgets/placeholder_tile.dart';

void main() {
  testWidgets('a failed network image loads the bundled fallback', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: PlaceholderTile.hero(
          image: 'https://example.invalid/photo.jpg',
          fallbackImage: 'assets/images/places/uluru.jpg',
        ),
      ),
    );
    await tester.runAsync(() async => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    final assets = tester
        .widgetList<Image>(find.byType(Image))
        .map((image) => image.image)
        .whereType<AssetImage>();
    expect(
      assets.map((image) => image.assetName),
      contains('assets/images/places/uluru.jpg'),
    );
    expect(find.byType(AppIcon), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed network image and bad fallback still show the icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: PlaceholderTile.hero(
          image: 'https://example.invalid/bad-photo.jpg',
          fallbackImage: 'assets/images/places/does-not-exist.jpg',
        ),
      ),
    );
    await tester.runAsync(() async => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.byType(AppIcon), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('.square(size: 76) measures 76x76 and contains the image icon',
      (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: PlaceholderTile.square(size: 76)),
      ),
    );

    expect(tester.getSize(find.byType(PlaceholderTile)), const Size(76, 76));

    final icon = tester.widget<AppIcon>(find.byType(AppIcon));
    expect(icon.icon, LucideIcons.image);
  });

  testWidgets('.hero(image: ...) renders an Image with an AssetImage provider',
      (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PlaceholderTile.hero(image: 'assets/images/places/uluru.jpg'),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<AssetImage>());
    expect((image.image as AssetImage).assetName, 'assets/images/places/uluru.jpg');
  });

  testWidgets('.hero(image: null) renders no Image', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PlaceholderTile.hero(),
      ),
    );

    expect(find.byType(Image), findsNothing);

    final icon = tester.widget<AppIcon>(find.byType(AppIcon));
    expect(icon.icon, LucideIcons.image);
  });

  testWidgets('.square(image: <bad asset>) falls back to the placeholder icon on error',
      (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PlaceholderTile.square(size: 76, image: 'assets/images/places/does-not-exist.jpg'),
      ),
    );

    // First frame renders the Image widget while it resolves and fails.
    await tester.pump();
    await tester.pump();

    expect(find.byType(AppIcon), findsOneWidget);
  });
}
