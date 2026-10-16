import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/card_pairs/card_pairs_game_page.dart';
import 'package:zeka_parkuru/games/card_pairs/card_pairs_scenario.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('320×600 Turkish memory deck finds matching cards', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    const ParkurLevelSpec level = ParkurLevelSpec(
      number: 1,
      titleTr: 'Koleksiyon 01',
      titleEn: 'Collection 01',
      subtitleTr: 'Aynı görseli bul',
      subtitleEn: 'Find identical images',
      difficulty: 'GÖZLEM',
      icon: Icons.style_rounded,
    );
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: CardPairsPlayPage(level: level, previousBestScore: 0),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Kart Çifti'), findsOneWidget);
    final Finder hintButton = find.byKey(
      const ValueKey<String>('card_pairs_hint'),
    );
    final Text hintLabel = tester.widget<Text>(
      find.descendant(of: hintButton, matching: find.byType(Text)),
    );
    expect(hintLabel.maxLines, 1);
    expect(hintLabel.softWrap, isFalse);
    expect(hintLabel.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);

    final CardPairsScenario board = CardPairsScenario.forCampaignLevel(1);
    final GridView grid = tester.widget<GridView>(
      find.byKey(const ValueKey<String>('card_pairs_grid')),
    );
    final SliverGridDelegateWithFixedCrossAxisCount gridDelegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(gridDelegate.crossAxisCount, 2);
    expect(board.cards.length % gridDelegate.crossAxisCount, isNot(1));
    final Rect scrollBounds = tester.getRect(
      find.byKey(const ValueKey<String>('card_pairs_scroll')),
    );
    final Set<Color?> backColors = <Color?>{};
    final Set<Color?> backBorders = <Color?>{};
    final Set<IconData?> backIcons = <IconData?>{};
    for (final CardPairCard card in board.cards) {
      final Rect cardBounds = tester.getRect(
        find.byKey(ValueKey<String>('card_pairs_card_${card.id}')),
      );
      expect(
        cardBounds.bottom,
        lessThanOrEqualTo(scrollBounds.bottom),
        reason: 'Every opening-deck card should fit without scrolling.',
      );
      final Finder backArt = find.byKey(
        ValueKey<String>('card_pairs_back_art_${card.id}'),
      );
      final Container backContainer = tester.widget<Container>(backArt);
      final BoxDecoration backDecoration =
          backContainer.decoration! as BoxDecoration;
      backColors.add(backDecoration.color);
      backBorders.add((backDecoration.border! as Border).top.color);
      backIcons.add(
        tester
            .widget<Icon>(
              find.descendant(of: backArt, matching: find.byType(Icon)),
            )
            .icon,
      );
    }
    expect(backColors, hasLength(1));
    expect(backBorders, hasLength(1));
    expect(backIcons, hasLength(1));

    final CardPairCard firstCard = board.cards.first;
    await tester.ensureVisible(
      find.byKey(ValueKey<String>('card_pairs_card_${firstCard.id}')),
    );
    await tester.tap(
      find.byKey(ValueKey<String>('card_pairs_card_${firstCard.id}')),
    );
    await tester.pumpAndSettle();
    final Size openedCardSize = tester.getSize(
      find.byKey(ValueKey<String>('card_pairs_card_${firstCard.id}')),
    );
    final Size openedArtSize = tester.getSize(
      find.byKey(ValueKey<String>('card_pairs_art_${firstCard.id}')),
    );
    expect(
      openedArtSize.width,
      greaterThanOrEqualTo(openedCardSize.width - 4),
      reason: 'An opened card should show its image across the card face.',
    );
    expect(
      openedArtSize.height,
      greaterThanOrEqualTo(openedCardSize.height - 4),
      reason: 'An opened card should show its image across the card face.',
    );

    final Set<String> pairIds = board.cards
        .map((CardPairCard card) => card.pairId!)
        .toSet();
    for (final String pairId in pairIds) {
      final List<CardPairCard> cards = board.cardsForPair(pairId);
      for (final CardPairCard card in cards) {
        final Finder face = find.byKey(
          ValueKey<String>('card_pairs_card_${card.id}'),
        );
        await tester.ensureVisible(face);
        await tester.tap(face);
        await tester.pump();
      }
    }
    expect(
      find.byKey(const ValueKey<String>('card_pairs_finish')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  test('every campaign deck avoids a single orphan card on phone widths', () {
    for (final double width in <double>[240, 320, 360, 430, 768]) {
      for (int level = 1; level <= CardPairsScenario.campaignLevels; level++) {
        final CardPairsScenario board = CardPairsScenario.forCampaignLevel(
          level,
        );
        final int columns = CardPairsGridLayout.columnsFor(
          board.cards.length,
          width,
        );
        expect(columns, greaterThanOrEqualTo(2));
        expect(
          board.cards.length % columns,
          isNot(1),
          reason: 'level $level at width $width',
        );
      }
    }
  });

  testWidgets('800×1280 English hub scrolls through the master collection', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(800, 1280);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: CardPairsGamePage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Card Pairs'), findsOneWidget);
    final Finder finale = find.textContaining('Collection 20');
    await tester.scrollUntilVisible(
      finale,
      360,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(finale, findsOneWidget);
    expect(CardPairsGamePage.totalLevels, 30);
    expect(tester.takeException(), isNull);
  });
}
