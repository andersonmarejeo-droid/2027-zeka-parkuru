import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';
import 'package:zeka_parkuru/main.dart';
import 'package:zeka_parkuru/pages/daily_tasks_page.dart';
import 'package:zeka_parkuru/features/catalog/domain/studio_game_catalog.dart';
import 'package:zeka_parkuru/services/app_experience_controller.dart';
import 'package:zeka_parkuru/theme/app_visual_theme.dart';

import 'test_preferences.dart';

void main() {
  late AppExperienceController experience;

  setUpAll(() {
    installTestPreferences();
    experience = AppExperienceController.instance;
  });
  setUp(() async {
    await resetTestPreferences();
    await experience.setVisualTheme(AppVisualTheme.studioGarden);
  });
  tearDown(() async {
    await experience.setVisualTheme(AppVisualTheme.studioGarden);
  });
  tearDownAll(uninstallTestPreferences);

  testWidgets(
    'ana ekranda sekiz kategori alt alta görünür ve görselin tamamı açılır',
    (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.physicalSize = const Size(360, 780);
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

      expect(
        find.byKey(const ValueKey<String>('studio_garden_daily_card')),
        findsOneWidget,
      );
      for (final StudioGameClass gameClass in StudioGameClass.values) {
        final Finder categoryCard = find.byKey(
          ValueKey<String>('studio_garden_category_${gameClass.name}'),
        );
        expect(categoryCard, findsOneWidget);
        expect(
          tester.getSize(categoryCard).height,
          104,
          reason: 'Kategori kartları ana sayfada ortak, rahat dokunulur ölçüde olmalı.',
        );
      }
      expect(
        find.byKey(const ValueKey<String>('studio_garden_all_categories')),
        findsNothing,
      );

      final Finder memoryArt = find.byKey(
        const ValueKey<String>('studio_garden_category_art_memory'),
      );
      final Finder memoryCard = find.byKey(
        const ValueKey<String>('studio_garden_category_memory'),
      );
      await tester.ensureVisible(memoryCard);
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
      await tester.tap(memoryArt);
      await tester.pumpAndSettle(const Duration(milliseconds: 50));

      expect(
        find.byKey(const ValueKey<String>('studio_class_catalog_memory')),
        findsOneWidget,
        reason: 'Hafıza görselinin kendisi de kategori kartının tamamı gibi çalışmalı.',
      );
      expect(
        find.byKey(const ValueKey<String>('v9_game_card_4')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      // AnaSayfa's leaderboard fallback owns an eight-second timeout timer.
      await tester.pump(const Duration(seconds: 9));

      Navigator.of(
        tester.element(
          find.byKey(const ValueKey<String>('studio_class_catalog_memory')),
        ),
      ).pop();
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
    },
  );

  testWidgets('günlük meydan okuma kartının görsel alanı da tıklanabilir', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(360, 780);
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

    await tester.tapAt(
      tester.getCenter(
        find.byKey(const ValueKey<String>('studio_garden_daily_card')),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    // AnaSayfa's leaderboard fallback owns an eight-second timeout timer.
    // Let it complete so Flutter's test binding can verify clean disposal.
    await tester.pump(const Duration(seconds: 9));

    expect(find.byType(DailyTasksPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
