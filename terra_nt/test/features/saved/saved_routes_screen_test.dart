import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terra_nt/core/theme/colors.dart';
import 'package:terra_nt/core/theme/motion.dart';
import 'package:terra_nt/data/models/saved_route.dart';
import 'package:terra_nt/data/repositories/notifiers.dart';
import 'package:terra_nt/data/repositories/preferences_store.dart';
import 'package:terra_nt/data/seed/seed_data.dart';
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
      double textScale = 1,
    }) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            ),
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
      await tester.ensureVisible(row(id));
      await tester.pumpAndSettle();
      await tester.drag(row(id), Offset(pixels, 0));
      await tester.pumpAndSettle();
    }

    Future<void> openMenu(WidgetTester tester, String id) async {
      final menu = find.byKey(ValueKey('route-menu-$id'));
      await tester.ensureVisible(menu);
      await tester.pumpAndSettle();
      await tester.tap(menu);
      await tester.pumpAndSettle();
    }

    Future<void> menuAction(
      WidgetTester tester,
      String id,
      String action,
    ) async {
      await openMenu(tester, id);
      await tester.tap(find.text(action));
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

    testWidgets('each seeded route shows its regional cover', (tester) async {
      await pumpSavedRoutes(tester);

      String thumbnail(String id) {
        final image = tester.widget<Image>(
          find.descendant(of: row(id), matching: find.byType(Image)),
        );
        return (image.image as AssetImage).assetName;
      }

      expect(thumbnail('full-nt'), 'assets/images/scenes/full_nt.jpg');
      expect(thumbnail('red-centre'), 'assets/images/scenes/red_centre.jpg');
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

    testWidgets('light haptics answer revealing Delete and deleting a route', (
      tester,
    ) async {
      final haptics = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments);
          }
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });
      await pumpSavedRoutes(tester);
      await swipeLeft(tester, 'full-nt', -38);
      expect(haptics, isEmpty);
      await swipeLeft(tester, 'full-nt', -39);
      expect(haptics, ['HapticFeedbackType.lightImpact']);
      await tester.tap(row('full-nt'));
      await tester.pumpAndSettle();
      expect(haptics, hasLength(1));
      await swipeLeft(tester, 'full-nt', -39);
      await tester.tap(find.byKey(const ValueKey('delete-route-full-nt')));
      await tester.pumpAndSettle();
      expect(haptics, List.filled(3, 'HapticFeedbackType.lightImpact'));
      expect(container.read(savedRoutesNotifierProvider), hasLength(1));
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
      expect(find.text('Route deleted'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets(
      'Undo restores the card at its original position and persists it',
      (tester) async {
        await pumpSavedRoutes(tester);
        final original = container.read(savedRoutesNotifierProvider);
        await swipeLeft(tester, 'full-nt', -39);
        await tester.tap(find.byKey(const ValueKey('delete-route-full-nt')));
        await tester.pumpAndSettle();
        expect(row('full-nt'), findsNothing);
        expect(find.text('Route deleted'), findsOneWidget);
        await tester.tap(find.text('Undo'));
        await tester.pumpAndSettle();
        expect(row('full-nt'), findsOneWidget);
        expect(
          tester.getTopLeft(row('full-nt')).dy,
          lessThan(tester.getTopLeft(row('red-centre')).dy),
        );
        expect(container.read(savedRoutesNotifierProvider), original);
        expect(offset(tester, 'full-nt'), 0);
        await container.read(savedRoutesNotifierProvider.notifier).load();
        await tester.pumpAndSettle();
        expect(find.text('Full NT: Darwin to Uluru'), findsOneWidget);
      },
    );

    testWidgets(
      'successive deletes replace Undo and the last card can be restored',
      (tester) async {
        await pumpSavedRoutes(tester);
        for (final id in ['full-nt', 'red-centre']) {
          await swipeLeft(tester, id, -39);
          await tester.tap(find.byKey(ValueKey('delete-route-$id')));
          await tester.pumpAndSettle();
        }
        expect(find.text('No saved routes yet'), findsOneWidget);
        expect(find.text('Undo'), findsOneWidget);
        await tester.tap(find.text('Undo'));
        await tester.pumpAndSettle();
        expect(row('red-centre'), findsOneWidget);
        expect(row('full-nt'), findsNothing);
        expect(find.text('No saved routes yet'), findsNothing);
      },
    );

    testWidgets('Delete in the route menu deletes without a swipe, with Undo', (
      tester,
    ) async {
      await pumpSavedRoutes(tester);
      await menuAction(tester, 'full-nt', 'Delete');

      expect(row('full-nt'), findsNothing);
      expect(find.text('Route deleted'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(row('full-nt'), findsOneWidget);
    });

    testWidgets('the revealed delete button is named for screen readers', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpSavedRoutes(tester);
      await swipeLeft(tester, 'full-nt', -39);

      expect(
        find.bySemanticsLabel('Delete Full NT: Darwin to Uluru'),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets(
      'Undo expires after a few seconds without restoring the route',
      (tester) async {
        await pumpSavedRoutes(tester);
        await swipeLeft(tester, 'full-nt', -39);
        await tester.tap(find.byKey(const ValueKey('delete-route-full-nt')));
        await tester.pumpAndSettle();
        expect(find.text('Undo'), findsOneWidget);
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        expect(find.text('Undo'), findsNothing);
        expect(row('full-nt'), findsNothing);
      },
    );

    testWidgets('Rename changes the card and opening uses the new title', (
      tester,
    ) async {
      String? opened;
      await pumpSavedRoutes(tester, onOpenRoute: (id) => opened = id);
      await menuAction(tester, 'full-nt', 'Rename');
      expect(opened, isNull);
      expect(find.text('Rename route'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Full NT: Darwin to Uluru',
      );
      await tester.enterText(find.byType(TextField), '  Family holiday  ');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Family holiday'), findsOneWidget);
      final route = container.read(savedRoutesNotifierProvider).first;
      expect(route.id, 'full-nt');
      expect(route.stops, seedSavedRoutes.first.stops);
      await tester.tap(row('full-nt'));
      expect(opened, 'full-nt');
      expect(
        container.read(itineraryNotifierProvider).itinerary.title,
        'Family holiday',
      );
    });

    testWidgets('Rename refuses blank names and Cancel keeps the title', (
      tester,
    ) async {
      await pumpSavedRoutes(tester);
      await menuAction(tester, 'full-nt', 'Rename');
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();
      final save = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Save'),
      );
      expect(save.onPressed, isNull);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Full NT: Darwin to Uluru'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Move up/down reorders cards and disables moves at each end', (
      tester,
    ) async {
      var opened = 0;
      await pumpSavedRoutes(tester, onOpenRoute: (_) => opened++);
      await openMenu(tester, 'full-nt');
      bool enabled(String label) => tester
          .widget<PopupMenuItem<dynamic>>(
            find.ancestor(
              of: find.text(label),
              matching: find.byWidgetPredicate(
                (widget) => widget is PopupMenuItem,
              ),
            ),
          )
          .enabled;
      expect(enabled('Move up'), isFalse);
      expect(enabled('Move down'), isTrue);
      await tester.tap(find.text('Move down'));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(row('red-centre')).dy,
        lessThan(tester.getTopLeft(row('full-nt')).dy),
      );
      await openMenu(tester, 'full-nt');
      expect(enabled('Move down'), isFalse);
      expect(enabled('Move up'), isTrue);
      await tester.tap(find.text('Move up'));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(row('full-nt')).dy,
        lessThan(tester.getTopLeft(row('red-centre')).dy),
      );
      expect(opened, 0);
      await swipeLeft(tester, 'red-centre', -39);
      expect(offset(tester, 'red-centre'), -76);
    });

    testWidgets(
      'an explicit empty list survives rebuilding after the Undo expires',
      (tester) async {
        await pumpSavedRoutes(tester);
        for (final id in ['full-nt', 'red-centre']) {
          await swipeLeft(tester, id, -39);
          await tester.tap(find.byKey(ValueKey('delete-route-$id')));
          await tester.pumpAndSettle();
        }
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        container.dispose();
        container = ProviderContainer(
          overrides: [
            preferencesStoreProvider.overrideWithValue(PreferencesStore()),
          ],
        );
        await pumpSavedRoutes(tester);
        expect(find.text('No saved routes yet'), findsOneWidget);
        expect(container.read(savedRoutesNotifierProvider), isEmpty);
        expect(find.text('Undo'), findsNothing);
      },
    );

    testWidgets(
      'menu, rename and Undo work at 360px and 2x text without overflow',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await pumpSavedRoutes(tester, textScale: 2);
        await openMenu(tester, 'full-nt');
        expect(find.text('Rename'), findsOneWidget);
        expect(find.text('Move up'), findsOneWidget);
        expect(find.text('Move down'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Rename'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.enterText(find.byType(TextField), 'Family holiday');
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(find.text('Family holiday'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await swipeLeft(tester, 'full-nt', -39);
        await tester.tap(find.byKey(const ValueKey('delete-route-full-nt')));
        await tester.pumpAndSettle();
        expect(find.text('Route deleted'), findsOneWidget);
        expect(find.text('Undo'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Undo'));
        await tester.pumpAndSettle();
        expect(find.text('Family holiday'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

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

    testWidgets(
      'wide covers and long titles stay readable at 360px and 2x text',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await pumpSavedRoutes(tester, textScale: 2);
        const title = 'Top End in 7 days: Darwin, Kakadu and Katherine holiday';
        await container
            .read(savedRoutesNotifierProvider.notifier)
            .upsert(
              const SavedRoute(
                id: 'generated-trip',
                title: title,
                meta: '7 days · 4 stops',
                dateLabel: 'Your latest plan',
                stops: seedStops,
              ),
            );
        await tester.pumpAndSettle();
        final image = find.descendant(
          of: row('generated-trip'),
          matching: find.byType(Image),
        );
        final imageSize = tester.getSize(image);
        expect(imageSize.width, greaterThan(imageSize.height));
        expect(
          tester.widget<Image>(image).image,
          const AssetImage('assets/images/scenes/top_end.jpg'),
        );
        final date = find.text('Your latest plan');
        expect(tester.widget<Text>(date).style!.color, AppColors.inkSubtle);
        expect(
          tester.getRect(find.text(title)).bottom,
          lessThanOrEqualTo(tester.getRect(date).top),
        );
        expect(tester.takeException(), isNull);
        await swipeLeft(tester, 'generated-trip', -39);
        expect(offset(tester, 'generated-trip'), -76);
        expect(tester.takeException(), isNull);
      },
    );

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
