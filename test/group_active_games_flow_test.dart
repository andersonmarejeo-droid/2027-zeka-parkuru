import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/features/catalog/domain/studio_game_catalog.dart';
import 'package:zeka_parkuru/games/reference_games/atlas_puzzle.dart';
import 'package:zeka_parkuru/games/shared/campaign_asset_bank.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';
import 'package:zeka_parkuru/pages/challenge_game_catalog.dart';
import 'package:zeka_parkuru/services/daily_course_service.dart';
import 'package:zeka_parkuru/widgets/competition_stage_page.dart';

import 'test_preferences.dart';

void main() {
  setUpAll(() async {
    installTestPreferences();
    final String sdk = Platform.environment['FLUTTER_ROOT'] ?? 'C:/flutter';
    for (final String family in <String>['Roboto', 'Ahem', 'serif']) {
      final FontLoader font = FontLoader(family)
        ..addFont(
          File('$sdk/bin/cache/artifacts/material_fonts/roboto-regular.ttf')
              .readAsBytes()
              .then(ByteData.sublistView),
        );
      await font.load();
    }
    for (final String id in CampaignAssetBank.gameIds) {
      await CampaignAssetBank.prepare(id);
    }
    await AtlasDataset.load(AtlasKind.turkey);
    await AtlasDataset.load(AtlasKind.world);
  });
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  for (final GameDefinition game in StudioGameCatalog.playable) {
    testWidgets(
      '${game.id}: group stage opens, keeps controls and advances on skip',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final List<Object?> results = <Object?>[];
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('tr'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: ThemeData.light(useMaterial3: true),
            home: Builder(
              builder: (context) => Scaffold(
                body: FilledButton(
                  child: const Text('YARIŞMAYA BAŞLA'),
                  onPressed: () async {
                    final Object? result = await Navigator.of(context)
                        .push<Object?>(
                          MaterialPageRoute<Object?>(
                            builder: (_) => CompetitionStagePage(
                              gameId: game.id,
                              gameName: game.titleTr,
                              stageNumber: 1,
                              stageCount: 6,
                              gameBuilder: (_) => buildChallengeCompetitionPage(
                                gameId: game.id,
                                level: 1,
                                layoutCode: 1,
                              ),
                            ),
                          ),
                        );
                    results.add(result);
                    if (context.mounted &&
                        result is DailyStageResult &&
                        result.resolvesStage) {
                      await Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              const Scaffold(body: Text('SONRAKİ BÖLÜM')),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('YARIŞMAYA BAŞLA'));
        // Several games have repeating clocks/animations. Pump bounded frames
        // so the check exercises their running screen rather than waiting for
        // an animation to stop before the player can skip.
        for (int frame = 0; frame < 20; frame++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(tester.takeException(), isNull, reason: '${game.id} opening');
        final Finder skip = find.byKey(
          const ValueKey<String>('competition_skip_stage'),
        );
        expect(skip, findsOneWidget);
        expect(tester.getBottomLeft(skip).dy, lessThanOrEqualTo(800));
        await tester.tap(skip);
        for (int frame = 0; frame < 10; frame++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(results, hasLength(1), reason: game.id);
        final DailyStageResult result = results.single! as DailyStageResult;
        expect(result.gameId, game.id);
        expect(result.outcome, DailyStageOutcome.skipped);
        expect(result.stars, 0);
        expect(result.rawScore, 0);
        expect(find.text('SONRAKİ BÖLÜM'), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '${game.id} transition');
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 1));
      },
    );
  }
}
