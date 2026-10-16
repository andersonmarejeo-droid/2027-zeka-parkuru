import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/mind_tools/smart_list/smart_list_models.dart';
import 'package:zeka_parkuru/mind_tools/smart_list/smart_list_store.dart';

import 'test_preferences.dart';

void main() {
  late SmartListStore store;

  setUp(() {
    installTestPreferences();
    store = SmartListStore();
  });

  tearDown(uninstallTestPreferences);

  group('Smart lists local store', () {
    test(
      'keeps list type, quantities, sections and check state on device',
      () async {
        final SmartListDocument list = await store.createList(
          title: 'Hafta sonu pazarı',
          kind: SmartListKind.shopping,
          now: DateTime(2026, 9, 20),
        );
        final SmartListDocument withItem = await store.addItem(
          listId: list.id,
          text: 'Domates',
          quantity: '6 adet',
          section: 'Sebze',
        );
        expect(withItem.openCount, 1);
        final SmartListItem item = withItem.items.single;
        final SmartListDocument checked = await store.toggleItem(
          listId: list.id,
          itemId: item.id,
        );
        final SmartListDocument reloaded =
            (await SmartListStore().loadAll()).single;

        expect(reloaded.kind, SmartListKind.shopping);
        expect(reloaded.checkedCount, 1);
        expect(reloaded.items.single.quantity, '6 adet');
        expect(reloaded.items.single.section, 'Sebze');
        expect(reloaded.items.single.checked, isTrue);
        expect(checked.openCount, 0);
      },
    );

    test(
      'separates list categories and rejects accidental duplicates',
      () async {
        await store.createList(title: 'Hazırlık', kind: SmartListKind.travel);
        await store.createList(title: 'Hazırlık', kind: SmartListKind.tasks);
        await expectLater(
          store.createList(title: ' hazırlık ', kind: SmartListKind.travel),
          throwsStateError,
        );
        final SmartListDocument list = (await store.loadAll()).first;
        await store.addItem(listId: list.id, text: 'Pasaport');
        await expectLater(
          store.addItem(listId: list.id, text: 'pasaport'),
          throwsStateError,
        );
        await expectLater(
          store.addItem(listId: list.id, text: '  '),
          throwsArgumentError,
        );
        expect(
          (await store.loadAll()).fold<int>(
            0,
            (sum, value) => sum + value.items.length,
          ),
          1,
        );
      },
    );

    test(
      'rename, remove, clear completed and delete retain only intended data',
      () async {
        final SmartListDocument list = await store.createList(
          title: 'Uçak çantası',
          kind: SmartListKind.travel,
        );
        final SmartListDocument withPassport = await store.addItem(
          listId: list.id,
          text: 'Pasaport',
        );
        final SmartListDocument withCharger = await store.addItem(
          listId: list.id,
          text: 'Şarj aleti',
        );
        await store.toggleItem(
          listId: list.id,
          itemId: withPassport.items.first.id,
        );
        final SmartListDocument renamed = await store.renameList(
          listId: list.id,
          title: 'Yurt dışı uçuşu',
        );
        expect(renamed.title, 'Yurt dışı uçuşu');
        expect(renamed.checkedCount, 1);

        await store.removeItem(
          listId: list.id,
          itemId: withCharger.items.last.id,
        );
        expect(
          (await store.loadAll()).single.items.map((item) => item.text),
          <String>['Pasaport'],
        );
        final SmartListDocument cleared = await store.clearCompleted(list.id);
        expect(cleared.items, isEmpty);
        await store.deleteList(list.id);
        expect(await store.loadAll(), isEmpty);
      },
    );
  });
}
