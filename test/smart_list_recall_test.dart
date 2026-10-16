import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/mind_tools/smart_list/smart_list_models.dart';
import 'package:zeka_parkuru/mind_tools/smart_list/smart_list_recall_practice.dart';

void main() {
  const List<SmartListItem> items = <SmartListItem>[
    SmartListItem(id: 'milk', text: 'Süt', checked: false, quantity: '2 litre'),
    SmartListItem(id: 'passport', text: 'Pasaport', checked: false),
    SmartListItem(id: 'hotel', text: 'Oteli ara', checked: false),
  ];

  test(
    'recall matching ignores case, surrounding spaces and final punctuation',
    () {
      final SmartListRecallResult result = evaluateSmartListRecall(
        expectedItems: items,
        response: '  SÜT!  \npasaport.\nYolda şarj et',
      );

      expect(
        result.rememberedItems.map((SmartListItem item) => item.id),
        <String>['milk', 'passport'],
      );
      expect(result.missedItems.map((SmartListItem item) => item.id), <String>[
        'hotel',
      ]);
      expect(result.extraAnswerCount, 1);
      expect(result.rememberedCount, 2);
    },
  );

  test('blank and repeated answers cannot inflate the recalled count', () {
    final SmartListRecallResult result = evaluateSmartListRecall(
      expectedItems: items,
      response: '\nSüt\nsüt\n\nSÜT\n',
    );

    expect(
      result.rememberedItems.map((SmartListItem item) => item.id),
      <String>['milk'],
    );
    expect(result.missedItems, hasLength(2));
    expect(result.extraAnswerCount, 0);
  });

  test('Turkish dotted and dotless I follow Turkish case matching', () {
    const List<SmartListItem> turkishItems = <SmartListItem>[
      SmartListItem(id: 'light', text: 'Işık', checked: false),
      SmartListItem(id: 'fig', text: 'İncir', checked: false),
    ];
    final SmartListRecallResult result = evaluateSmartListRecall(
      expectedItems: turkishItems,
      response: 'IŞIK\nincir',
    );

    expect(result.rememberedCount, 2);
    expect(result.missedItems, isEmpty);
  });

  test('English I and i remain case-insensitive', () {
    const List<SmartListItem> englishItems = <SmartListItem>[
      SmartListItem(id: 'city', text: 'Istanbul', checked: false),
    ];
    final SmartListRecallResult result = evaluateSmartListRecall(
      expectedItems: englishItems,
      response: 'istanbul',
      turkishCaseRules: false,
    );

    expect(result.rememberedCount, 1);
    expect(result.missedItems, isEmpty);
  });

  test('recall result is immutable and keeps list metadata intact', () {
    final SmartListRecallResult result = evaluateSmartListRecall(
      expectedItems: items,
      response: 'süt\npasaport\noteli ara',
    );

    expect(result.rememberedItems, hasLength(3));
    expect(result.rememberedItems.first.quantity, '2 litre');
    expect(
      () => result.rememberedItems.add(items.first),
      throwsUnsupportedError,
    );
  });
}
