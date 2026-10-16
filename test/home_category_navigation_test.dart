import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';
import 'package:zeka_parkuru/main.dart';
import 'package:zeka_parkuru/services/app_experience_controller.dart';
import 'package:zeka_parkuru/theme/app_visual_theme.dart';
import 'package:zeka_parkuru/features/catalog/domain/studio_game_catalog.dart';

import 'test_preferences.dart';

void main() {
  setUpAll(installTestPreferences);
  setUp(() async {
    await resetTestPreferences();
    await AppExperienceController.instance.setVisualTheme(
      AppVisualTheme.studioGarden,
    );
  });
  tearDownAll(uninstallTestPreferences);

  testWidgets(
    'ana ekrandaki sekiz kategori kendi oynanabilir oyunlarını açar',
    (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('tr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const AnaSayfa(),
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 50));

      const Map<String, int> categories = <String, int>{
        'logic': 14,
        'numbers': 2,
        'visual': 3,
        'memory': 4,
        'strategy': 33,
        'language': 6,
        'speed': 51,
        'fun': 50,
      };

      for (final MapEntry<String, int> entry in categories.entries) {
        final Finder category = find.byKey(
          ValueKey<String>('studio_garden_category_${entry.key}'),
        );
        await tester.scrollUntilVisible(
          category,
          220,
          scrollable: find
              .descendant(
                of: find.byKey(const ValueKey<String>('v9_pro_home')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.tap(category);
        await tester.pumpAndSettle(const Duration(milliseconds: 50));

        expect(
          find.byKey(ValueKey<String>('studio_class_catalog_${entry.key}')),
          findsOneWidget,
          reason: '${entry.key} kategorisi kendi liste ekranını açmalı.',
        );
        final gameClass = StudioGameClass.values.firstWhere(
          (value) => value.name == entry.key,
        );
        if (StudioGameCatalog.playableCountFor(gameClass) > 0) {
          await tester.scrollUntilVisible(
            find.byKey(ValueKey<String>('v9_game_card_${entry.value}')),
            220,
            scrollable: find
                .descendant(
                  of: find.byKey(
                    ValueKey<String>('studio_class_catalog_${entry.key}'),
                  ),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          expect(
            find.byKey(ValueKey<String>('v9_game_card_${entry.value}')),
            findsOneWidget,
            reason: '${entry.key} kategorisinde kendi oyunu görünmeli.',
          );
        } else if (gameClass == StudioGameClass.fun &&
            StudioGameCatalog.plannedCountFor(gameClass) > 0) {
          final List<GameDefinition> plannedGames = StudioGameCatalog
              .inClass(gameClass)
              .where((GameDefinition game) => !game.isPlayable)
              .toList(growable: false);
          for (final GameDefinition game in plannedGames) {
            final Finder upcomingCard = find.byKey(
              ValueKey<String>('v9_upcoming_game_card_${game.id}'),
            );
            await tester.scrollUntilVisible(
              upcomingCard,
              220,
              scrollable: find
                  .descendant(
                    of: find.byKey(
                      ValueKey<String>(
                        'studio_class_catalog_${entry.key}',
                      ),
                    ),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            );
            expect(upcomingCard, findsOneWidget);
            expect(
              find.descendant(
                of: upcomingCard,
                matching: find.text('YAKINDA · BİR SONRAKİ SÜRÜM'),
              ),
              findsOneWidget,
            );
            expect(
              find.descendant(
                of: upcomingCard,
                matching: find.byType(InkWell),
              ),
              findsNothing,
            );
          }
        } else {
          expect(
            find.byWidgetPredicate(
              (widget) =>
                  widget.key is ValueKey<String> &&
                  (widget.key! as ValueKey<String>).value.startsWith(
                    'v9_game_card_',
                  ),
            ),
            findsNothing,
          );
        }
        expect(tester.takeException(), isNull);

        if (gameClass == StudioGameClass.language) {
          expect(
            find.textContaining('oyun hazır'),
            findsNothing,
            reason: 'Kategori başlığı sistem çeviri uyarısı gibi görünmemeli.',
          );
          expect(
            find.byIcon(Icons.translate_rounded),
            findsNothing,
            reason: 'Google Çeviri simgesi kategori ekranında görünmemeli.',
          );
          expect(find.byIcon(Icons.spellcheck_rounded), findsOneWidget);
        }

        Navigator.of(
          tester.element(
            find.byKey(ValueKey<String>('studio_class_catalog_${entry.key}')),
          ),
        ).pop();
        await tester.pumpAndSettle(const Duration(milliseconds: 50));
      }
    },
  );
}
