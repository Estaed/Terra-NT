import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terra_nt/core/theme/motion.dart';
import 'package:terra_nt/data/models/saved_route.dart';
import 'package:terra_nt/data/repositories/notifiers.dart';
import 'package:terra_nt/data/repositories/preferences_store.dart';
import 'package:terra_nt/features/saved/saved_routes_screen.dart';
import 'package:terra_nt/shared/widgets/entrance.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SavedRoutesScreen', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer(
        overrides: [
          preferencesStoreProvider.overrideWithValue(PreferencesStore()),
        ],
      );
    });

    tearDown(() => container.dispose());

    Future<void> pumpSavedRoutes(
      WidgetTester tester, {
      ValueChanged<String>? onOpenRoute,
      VoidCallback? onPlanAi,
    }) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: SavedRoutesScreen(
              key: ValueKey(container.hashCode),
              onOpenRoute: onOpenRoute,
              onPlanAi: onPlanAi,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Finder row(String id) => find.byKey(ValueKey('saved-route-$id'));

    double offset(WidgetTester tester, String id) {
      final row = tester.widget<Transform>(
        find.byKey(ValueKey('saved-route-row-$id')),
      );
      return row.transform.getTranslation().x;
    }

    Future<void> swipeLeft(
      WidgetTester tester,
      String id,
      double pixels,
    ) async {
      await tester.drag(row(id), Offset(pixels, 0));
      await tester.pumpAndSettle();
    }

    testWidgets('renders the seeded routes with their exact copy', (
      tester,
    ) async {
      await pumpSavedRoutes(tester);

      expect(find.text('Full NT: Darwin to Uluru'), findsOneWidget);
      expect(find.text('8 days · 7 stops'), findsOneWidget);
      expect(find.text('Generated today'), findsOneWidget);
      expect(find.text('7 Days in the Red Centre'), findsOneWidget);
      expect(find.text('7 days · 4 stops'), findsOneWidget);
      expect(find.text('Generated 3 days ago'), findsOneWidget);
    });

    testWidgets('each thumbnail keys on the route\'s first stop', (
      tester,
    ) async {
      await pumpSavedRoutes(tester);

      String thumbnail(String id) {
        final image = tester.widget<Image>(
          find.descendant(of: row(id), matching: find.byType(Image)),
        );
        return (image.image as AssetImage).assetName;
      }

      expect(thumbnail('full-nt'), 'assets/images/places/darwin.jpg');
      expect(thumbnail('red-centre'), 'assets/images/places/alice-springs.jpg');
    });

    testWidgets('left drag reveals 76px and right drag stays at rest', (
      tester,
    ) async {
      await pumpSavedRoutes(tester);

      await swipeLeft(tester, 'full-nt', -100);
      expect(offset(tester, 'full-nt'), -76);

      await tester.drag(row('red-centre'), const Offset(100, 0));
      await tester.pumpAndSettle();
      expect(offset(tester, 'red-centre'), 0);
    });

    testWidgets('release boundary closes at -38 and opens at -39', (
      tester,
    ) async {
      await pumpSavedRoutes(tester);

      await swipeLeft(tester, 'full-nt', -38);
      expect(offset(tester, 'full-nt'), 0);

      await swipeLeft(tester, 'full-nt', -39);
      expect(offset(tester, 'full-nt'), -76);
    });

    testWidgets('opening another row closes the first', (tester) async {
      await pumpSavedRoutes(tester);

      await swipeLeft(tester, 'full-nt', -39);
      await swipeLeft(tester, 'red-centre', -39);

      expect(offset(tester, 'full-nt'), 0);
      expect(offset(tester, 'red-centre'), -76);
    });

    testWidgets('a drag does not open a route', (tester) async {
      var opened = 0;
      await pumpSavedRoutes(tester, onOpenRoute: (_) => opened++);

      await swipeLeft(tester, 'full-nt', -39);

      expect(opened, 0);
    });

    testWidgets('tapping an open row closes it without navigation', (
      tester,
    ) async {
      var opened = 0;
      await pumpSavedRoutes(tester, onOpenRoute: (_) => opened++);
      await swipeLeft(tester, 'full-nt', -39);

      await tester.tap(row('full-nt'));
      await tester.pumpAndSettle();

      expect(offset(tester, 'full-nt'), 0);
      expect(opened, 0);
    });

    testWidgets('tapping a closed route loads its saved itinerary', (
      tester,
    ) async {
      String? openedRoute;
      await pumpSavedRoutes(
        tester,
        onOpenRoute: (route) => openedRoute = route,
      );

      await tester.tap(row('red-centre'));
      await tester.pumpAndSettle();

      expect(openedRoute, 'red-centre');
      final opened = container.read(itineraryNotifierProvider).itinerary;
      expect(opened.stops, hasLength(4));
      expect(opened.title, '7 Days in the Red Centre');
    });

    testWidgets('delete removes immediately and resets the swipe state', (
      tester,
    ) async {
      await pumpSavedRoutes(tester);
      await swipeLeft(tester, 'full-nt', -39);

      await tester.tap(find.byKey(const ValueKey('delete-route-full-nt')));
      await tester.pumpAndSettle();

      expect(find.text('Full NT: Darwin to Uluru'), findsNothing);
      expect(container.read(savedRoutesNotifierProvider), hasLength(1));
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('empty state sends the user to Plan AI', (tester) async {
      var planAiCalls = 0;
      await pumpSavedRoutes(tester, onPlanAi: () => planAiCalls++);

      for (final id in ['full-nt', 'red-centre']) {
        await swipeLeft(tester, id, -39);
        await tester.tap(find.byKey(ValueKey('delete-route-$id')));
        await tester.pumpAndSettle();
      }

      expect(find.text('No saved routes yet'), findsOneWidget);
      expect(
        find.text("Generate an itinerary with Plan AI and it'll show up here."),
        findsOneWidget,
      );
      expect(find.text('Plan Your First Route'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('saved-routes-empty-bookmark')),
        findsOneWidget,
      );

      await tester.tap(find.text('Plan Your First Route'));
      expect(planAiCalls, 1);
    });

    testWidgets('a generated trip appears at the top', (tester) async {
      await pumpSavedRoutes(tester);
      await container
          .read(savedRoutesNotifierProvider.notifier)
          .upsert(
            const SavedRoute(
              id: 'generated-trip',
              title: 'Generated route',
              meta: '8 days · 7 stops',
              dateLabel: 'Generated just now',
              stops: [],
            ),
          );
      await tester.pumpAndSettle();

      final first = tester
          .widgetList<Transform>(
            find.byWidgetPredicate(
              (widget) => widget is Transform && widget.key is ValueKey,
            ),
          )
          .first;
      expect(first.key, const ValueKey('saved-route-row-generated-trip'));
    });

    testWidgets('deletions remain after rebuilding from PreferencesStore', (
      tester,
    ) async {
      await pumpSavedRoutes(tester);
      await swipeLeft(tester, 'full-nt', -39);
      await tester.tap(find.byKey(const ValueKey('delete-route-full-nt')));
      await tester.pumpAndSettle();

      container.dispose();
      container = ProviderContainer(
        overrides: [
          preferencesStoreProvider.overrideWithValue(PreferencesStore()),
        ],
      );
      await pumpSavedRoutes(tester);

      expect(find.text('Full NT: Darwin to Uluru'), findsNothing);
      expect(find.text('7 Days in the Red Centre'), findsOneWidget);
    });

    testWidgets('has no layout exception at 360px when a row is open', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpSavedRoutes(tester);

      await swipeLeft(tester, 'full-nt', -39);

      expect(tester.takeException(), isNull);
    });

    group('entrance (D18)', () {
      /// The opacity of the [Entrance] that carries route [id]'s card.
      double cardOpacity(WidgetTester tester, String id) {
        final entrance = find.ancestor(
          of: row(id),
          matching: find.byType(Entrance),
        );
        return tester
            .widget<Opacity>(
              find
                  .descendant(of: entrance, matching: find.byType(Opacity))
                  .first,
            )
            .opacity;
      }

      testWidgets('cards fade in one after another, then rest fully shown', (
        tester,
      ) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: SavedRoutesScreen()),
          ),
        );

        expect(cardOpacity(tester, 'full-nt'), lessThan(1));
        expect(cardOpacity(tester, 'red-centre'), lessThan(1));

        await tester.pump(AppMotion.entrance ~/ 2);
        expect(
          cardOpacity(tester, 'red-centre'),
          lessThan(cardOpacity(tester, 'full-nt')),
          reason: 'the second card is staggered behind the first',
        );

        await tester.pump(AppMotion.entrance + AppMotion.entranceStagger);
        expect(cardOpacity(tester, 'full-nt'), 1);
        expect(cardOpacity(tester, 'red-centre'), 1);
      });

      testWidgets('deleting a card does not replay the one that moves up', (
        tester,
      ) async {
        await pumpSavedRoutes(tester);
        await swipeLeft(tester, 'full-nt', -39);

        await tester.tap(find.byKey(const ValueKey('delete-route-full-nt')));
        await tester.pump();

        expect(cardOpacity(tester, 'red-centre'), 1);
      });
    });
  });
}
