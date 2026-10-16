import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:zeka_parkuru/content_engine/content_fingerprint.dart';
import 'package:zeka_parkuru/content_engine/content_seed.dart';
import 'package:zeka_parkuru/content_engine/content_version.dart';
import 'package:zeka_parkuru/content_engine/recent_content_store.dart';
import 'package:zeka_parkuru/services/unified_progress_service.dart';
import 'package:zeka_parkuru/features/catalog/domain/studio_game_catalog.dart';

import 'test_preferences.dart';

String _source(String path) => File(path).readAsStringSync();

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  group('V10 ortak içerik çekirdeği', () {
    test('sürüm, tohum ve parmak izi deterministiktir', () {
      expect(kContentEngineVersion, 'v10_0');
      expect(
        ContentSeed.mix(sessionSeed: 42, level: 7, round: 3, salt: 11),
        ContentSeed.mix(sessionSeed: 42, level: 7, round: 3, salt: 11),
      );
      expect(
        contentFingerprint(<Object?>['  Görsel   IQ ', 7, 'MATRİS']),
        contentFingerprint(<Object?>['görsel iq', 7, 'matris']),
      );
    });

    test('yakın geçmiş aynı içeriği yeniden tanır', () async {
      final RecentContentStore store = RecentContentStore();
      expect(
        await store.rememberSession(
          gameId: 'contract_game',
          level: 4,
          fingerprint: 'session-a',
        ),
        isTrue,
      );
      expect(
        await store.rememberSession(
          gameId: 'contract_game',
          level: 4,
          fingerprint: 'session-a',
        ),
        isFalse,
      );
      expect(
        await store.rememberItems(
          gameId: 'contract_game',
          level: 4,
          fingerprints: <String>['q1', 'q2', 'q3'],
        ),
        isTrue,
      );
      expect(
        await store.rememberItems(
          gameId: 'contract_game',
          level: 4,
          fingerprints: <String>['q3', 'q4'],
        ),
        isFalse,
      );
    });

    test('30 bölüm standardı aktif oyunların kapasitesini kapsar', () {
      expect(UnifiedProgressData.maksimumSeviye, 1320);
      expect(UnifiedProgressData.maksimumYildiz, 3960);
    });
  });

  group('V10 soru ağırlıklı oyunlar', () {
    test('Sayı Ustası on aileli karma üretici kullanır', () {
      final String source = _source('lib/games/numbers/number_game_page.dart');
      for (final String family in <String>[
        'EKSİK SAYI',
        'ALTERNATİF DİZİ',
        'GELİŞMİŞ DİZİ',
        'İŞLEM',
        'PİRAMİT',
        'DENKLEM',
        'MATRİS',
        'SINIFLAMA',
        'SUDOKU',
        'BOSS',
      ]) {
        expect(source, contains("tur: '$family'"), reason: family);
      }
      expect(source, contains('aciklamaTr'));
      expect(source, contains('historyLimit: 250'));
    });

    test('Kelime Avı dilleri ayırır ve geniş bankaları korur', () {
      final String source = _source(
        'lib/games/word_hunt/word_hunt_game_page.dart',
      );
      final String turkish = source
          .split('_wordBankTr')[1]
          .split('_wordBankEn')[0];
      final String english = source
          .split('_wordBankEn')[1]
          .split('final GameAudioService')[0];
      final RegExp word = RegExp("'[^']+'");
      expect(word.allMatches(turkish).length, greaterThanOrEqualTo(220));
      expect(word.allMatches(english).length, greaterThanOrEqualTo(200));
      expect(
        source,
        contains("if (_languageCode == 'tr') return _wordBankTr;"),
      );
      expect(
        source,
        contains("if (_languageCode == 'en') return _wordBankEn;"),
      );
      expect(source, contains('WordHuntLocaleData.words(_languageCode)'));
      expect(source, contains('_sessionWords'));
    });

    test('Profesyonel Görsel Akıl ve Şekil biçimlerini açar', () {
      final String picture = _source(
        'lib/games/picture_iq/picture_iq_game_page.dart',
      );
      final String iqEngine = _source(
        'lib/games/picture_iq/professional_iq_engine.dart',
      );
      final String iqModels = _source(
        'lib/games/picture_iq/professional_iq_models.dart',
      );
      final String shape = _source(
        'lib/games/shape_puzzle/shape_puzzle_game_page.dart',
      );
      for (final String format in <String>[
        'analogy',
        'series',
        'matrix2',
        'matrix3',
        'relation',
        'oddOneOut',
      ]) {
        expect(iqModels, contains(format));
      }
      for (final String mode in <String>[
        'merge',
        'rotate',
        'mirror',
        'negativeSpace',
      ]) {
        expect(shape, contains('_ShapeQuestionMode.$mode'));
      }
      expect(iqEngine, contains('familyCount = 16'));
      expect(iqEngine, contains('historyLimit = 250'));
      expect(picture, contains('_ExplanationCard'));
      expect(picture, contains('_nextQuestion'));
      expect(shape, contains('historyLimit: 200'));
    });
  });

  group('V10 doğrulanmış bulmacalar ve senaryolar', () {
    test('Hanoi Arena tohumu ve gerçek minimum hamleyi kullanır', () {
      final String hanoi = _source('lib/games/hanoi/hanoi_game_page.dart');
      final String arena = _source('lib/pages/arena_page.dart');
      final String catalog = _source('lib/pages/challenge_game_catalog.dart');
      expect(hanoi, contains('competitionLayoutCode'));
      expect(hanoi, contains('HanoiSolver.minimumMoves'));
      expect(hanoi, contains('_randomizedLegalStart'));
      expect(arena, contains('layoutCode: event.layoutCodeFor(gameId)'));
      expect(catalog, contains('competitionLayoutCode: layoutCode'));
    });

    test(
      '15 taş hedefi ve şeker sıralama oyunu korunur',
      () {
        final String numberSort = _source(
          'lib/games/number_sort/number_sort_game_page.dart',
        );
        expect(StudioGameCatalog.byId('candy_sort')?.isRetired, isFalse);
        expect(numberSort, contains('_targetForLevel'));
        expect(numberSort, contains('_targetTiles'));
        expect(numberSort, contains('fingerprint: _lastGeneratedSignature'));
      },
    );

    test('sürekli oyunlar dengeli ve tekrarsız oturumlar kurar', () {
      final String blocks = _source('lib/games/blocks/block_game_page.dart');
      final String memory = _source('lib/games/memory/memory_game_page.dart');
      final String reflex = _source('lib/games/reflex/reflex_game_page.dart');
      expect(blocks, contains('_scenarioBoard'));
      expect(blocks, contains('_pieceHasPlacement'));
      expect(memory, contains('_adjacentCell'));
      expect(memory, contains('_reverseThisRound'));
      expect(reflex, contains('_buildBossSchedule'));
      expect(reflex, contains('ReflexMode.noGo'));
      expect(reflex, contains('Stopwatch()..start()'));
    });
  });
}
