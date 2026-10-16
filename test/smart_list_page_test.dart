import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';
import 'package:zeka_parkuru/mind_tools/smart_list/smart_list_models.dart';
import 'package:zeka_parkuru/mind_tools/smart_list/smart_list_page.dart';
import 'package:zeka_parkuru/mind_tools/smart_list/smart_list_store.dart';

import 'test_preferences.dart';

void main() {
  setUp(installTestPreferences);
  tearDown(uninstallTestPreferences);

  testWidgets(
    '320×600 creates a travel list, adds a checklist and completes an item',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 600);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final SmartListStore store = SmartListStore();

      await tester.pumpWidget(
        MaterialApp(
          locale: Locale('tr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: SmartListsPage(store: store),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Listelerim'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('smart_list_create')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey<String>('smart_list_title')),
        'Hafta sonu çantası',
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('smart_list_kind_travel')),
      );
      await tester.tap(find.byKey(const ValueKey<String>('smart_list_save')));
      await tester.pumpAndSettle();
      expect(find.text('Hafta sonu çantası'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('smart_list_add_item')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey<String>('smart_list_item_text')),
        'Seyahat belgesi',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('smart_list_item_quantity')),
        '1 adet',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('smart_list_item_section')),
        'Önemli evraklar',
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('smart_list_item_save')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Seyahat belgesi'), findsOneWidget);
      expect(find.text('1 adet · Önemli evraklar'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('smart_list_add_item')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey<String>('smart_list_item_text')),
        'Powerbank',
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('smart_list_item_save')),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('smart_list_recall_entry')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('smart_list_recall_entry')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Kayıtları gözden geçir'), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('smart_list_recall_begin')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('smart_list_recall_begin')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Neleri hatırlıyorsun?'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey<String>('smart_list_recall_input')),
        'Seyahat belgesi',
      );
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('smart_list_recall_check')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('smart_list_recall_check')),
      );
      await tester.pumpAndSettle();
      expect(find.text('2 kayıttan 1 tanesini hatırladın'), findsOneWidget);
      expect(find.text('Powerbank'), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('smart_list_recall_done')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('smart_list_recall_done')),
      );
      await tester.pumpAndSettle();
      final SmartListDocument savedAfterPractice =
          (await store.loadAll()).single;
      expect(savedAfterPractice.openCount, 2);
      expect(
        savedAfterPractice.items.every((SmartListItem item) => !item.checked),
        isTrue,
      );

      await tester.ensureVisible(find.byType(Checkbox).first);
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();
      expect(find.text('TAMAMLANDI · 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Hafta sonu çantası'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('800×1280 home card calls its route action', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1280);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    bool opened = false;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: SmartListHomeCard(isEnglish: true, onTap: () => opened = true),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey<String>('smart_lists_open')));
    expect(opened, isTrue);
    expect(find.text('Shopping & Prep Assistant'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
