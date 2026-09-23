import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zeka_parkuru/games/candy_sort/candy_sort_game_page.dart';
import 'package:zeka_parkuru/games/logic/logic_game_page.dart';
import 'package:zeka_parkuru/games/number_sort/number_sort_game_page.dart';
import 'package:zeka_parkuru/games/picture_iq/picture_iq_game_page.dart';
import 'package:zeka_parkuru/games/shape_puzzle/shape_puzzle_game_page.dart';
import 'package:zeka_parkuru/games/word_hunt/word_hunt_game_page.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';
import 'package:zeka_parkuru/services/arena_service.dart';
import 'package:zeka_parkuru/services/daily_challenge_service.dart';
import 'package:zeka_parkuru/services/daily_course_service.dart';
import 'package:zeka_parkuru/services/online_leaderboard_service.dart';
import 'package:zeka_parkuru/services/unified_progress_service.dart';
import 'package:zeka_parkuru/services/zeka_scoring_service.dart';

import 'test_preferences.dart';

const List<String> _expectedGameIds = <String>[
  'logic',
  'numbers',
  'blocks',
  'memory',
  'hanoi',
  'word_hunt',
  'picture_iq',
  'candy_sort',
  'number_sort',
  'shape_puzzle',
  'reflex',
];

String _source(String relativePath) {
  return File(relativePath).readAsStringSync();
}

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  group('Sistem kayıt bütünlüğü', () {
    test(
      'Günün Parkuru tekrar rotası farklıdır ve oyunlar doğrudan başlar',
      () {
        final DailyCourseService service = DailyCourseService.instance;
        final DateTime date = DateTime(2026, 8, 29);

        final List<String> original = service.gamesForDate(date);
        final List<String> replayOne = service.gamesForReplay(date, 1);
        final List<String> replayOneAgain = service.gamesForReplay(date, 1);
        final List<String> replayTwo = service.gamesForReplay(date, 2);

        expect(replayOne, orderedEquals(replayOneAgain));
        expect(replayOne.length, DailyCourseService.dailyGameCount);
        expect(replayOne.toSet().length, replayOne.length);
        expect(replayOne, isNot(orderedEquals(original)));
        expect(replayTwo, isNot(orderedEquals(replayOne)));
        expect(replayOne, everyElement(isIn(_expectedGameIds)));

        for (final String gameId in _expectedGameIds) {
          final int level = service.levelForDailyCourse(
            date: date,
            gameId: gameId,
            runNumber: 1,
          );
          expect(level, inInclusiveRange(1, 10), reason: gameId);
        }

        final String page = _source('lib/pages/daily_course_page.dart');
        final String pageFactory = page.substring(
          page.indexOf('Widget _pageFor('),
          page.indexOf('String _gameName('),
        );

        expect(
          RegExp(r'competitionLevel:\s*competitionLevel')
              .allMatches(pageFactory)
              .length,
          11,
        );
        expect(
          RegExp(r'competitionLayoutCode:\s*layoutCode')
              .allMatches(pageFactory)
              .length,
          11,
        );
        expect(page, contains('Parkuru Tekrar Oyna'));
        expect(page, contains('Future<void> _startReplay()'));
        expect(page, contains('await _playCourseCompletionSound();'));
        expect(
          RegExp(r'_audio\.playMashallahCelebration\(\)')
              .allMatches(page)
              .length,
          1,
        );
        expect(page, contains('Tekrar puanı günlük ödülü yeniden artırmaz.'));
      },
    );
    test('11 oyun günlük parkur ve günlük görevlerde eşleşir', () {
      expect(DailyCourseService.dailyGameCount, 8);
      expect(DailyCourseService.gameIds, orderedEquals(_expectedGameIds));
      expect(
        DailyChallengeService.gameLabels.keys,
        orderedEquals(_expectedGameIds),
      );
      expect(DailyChallengeService.gameLabels.values, everyElement(isNotEmpty));
    });

    test('Türkçe ve İngilizce oyun metinleri 11 oyun için eksiksizdir', () {
      const AppLocalizations turkish = AppLocalizations(Locale('tr'));
      const AppLocalizations english = AppLocalizations(Locale('en'));

      for (final String gameId in _expectedGameIds) {
        expect(turkish.gameTitle(gameId), isNotEmpty, reason: gameId);
        expect(turkish.gameDescription(gameId), isNotEmpty, reason: gameId);
        expect(english.gameTitle(gameId), isNotEmpty, reason: gameId);
        expect(english.gameDescription(gameId), isNotEmpty, reason: gameId);
        expect(
          turkish.gameTitle(gameId),
          isNot(turkish.appName),
          reason: gameId,
        );
        expect(
          english.gameTitle(gameId),
          isNot(english.appName),
          reason: gameId,
        );
      }
    });

    test('günlük seçim aynı tarihte kararlı ve sekiz benzersiz oyundur', () {
      final DateTime date = DateTime(2026, 8, 23);
      final List<String> first = DailyCourseService.instance.gamesForDate(date);
      final List<String> second = DailyCourseService.instance.gamesForDate(
        date,
      );

      expect(first, orderedEquals(second));
      expect(first.length, DailyCourseService.dailyGameCount);
      expect(first.toSet().length, DailyCourseService.dailyGameCount);
      expect(first, everyElement(isIn(_expectedGameIds)));
    });
  });

  group('Seviye ve zorluk bütünlüğü', () {
    test('yeni beş parkurun seviye numaraları 1-10 aralığındadır', () {
      expect(
        WordHuntGamePage.levels.map((level) => level.number),
        orderedEquals(List<int>.generate(10, (index) => index + 1)),
      );
      expect(
        PictureIqGamePage.levels.map((level) => level.number),
        orderedEquals(List<int>.generate(10, (index) => index + 1)),
      );
      expect(
        CandySortGamePage.levels.map((level) => level.number),
        orderedEquals(List<int>.generate(10, (index) => index + 1)),
      );
      expect(
        NumberSortGamePage.levels.map((level) => level.number),
        orderedEquals(List<int>.generate(10, (index) => index + 1)),
      );
      expect(
        ShapePuzzleGamePage.levels.map((level) => level.number),
        orderedEquals(List<int>.generate(10, (index) => index + 1)),
      );
    });

    test('uzatılan oyun oturumlarının kaynak sözleşmeleri korunur', () {
      final String word = _source(
        'lib/games/word_hunt/word_hunt_game_page.dart',
      );
      final String blocks = _source('lib/games/blocks/block_game_page.dart');
      final String logic = _source('lib/games/logic/logic_game_page.dart');
      final String pictureIq = _source(
        'lib/games/picture_iq/picture_iq_game_page.dart',
      );
      final String shape = _source(
        'lib/games/shape_puzzle/shape_puzzle_game_page.dart',
      );

      expect(RegExp(r'boardCount: 2').allMatches(word).length, 10);
      expect(blocks, contains('targetLines: 24'));
      expect(blocks, contains('targetMoves: 108'));
      expect(logic, contains('int get hedefSayisi => switch'));
      expect(logic, contains('hedefler.length'));
      expect(pictureIq, contains('questionCount: 12'));
      expect(shape, contains('questionCount: 12'));
    });

    test(
      'Mantık Labirenti bombaları deterministik ve yalnız duvarlardadır',
      () {
        final Set<String> duvarlar = <String>{
          '0-0',
          '1-0',
          '2-0',
          '3-0',
          '0-1',
          '1-1',
          '2-1',
          '3-1',
        };
        final Set<String> ilk = labirentBombaKonumlariniSec(
          engeller: duvarlar,
          bombaSayisi: 3,
          seed: 20260829,
        );
        final Set<String> tekrar = labirentBombaKonumlariniSec(
          engeller: duvarlar,
          bombaSayisi: 3,
          seed: 20260829,
        );

        expect(ilk, equals(tekrar));
        expect(ilk.length, 3);
        expect(ilk, everyElement(isIn(duvarlar)));
        expect(duvarlar.length, 8, reason: 'Girdi duvarları değişmemelidir.');
        expect(labirentKalanCan(3), 2);
        expect(labirentKalanCan(1), 0);
        expect(labirentKalanCan(0), 0);

        final String source = _source('lib/games/logic/logic_game_page.dart');
        expect(source, contains('_LabirentDuvari'));
        expect(source, contains('_LabirentKasifi'));
        expect(source, contains('_BombaPatlamaEfekti'));
        expect(source, contains('GameSound.reflexBomb'));
        expect(source, contains('patlayanBombaKonumlari.add'));
        expect(source, contains('basarisizlikPenceresi'));
        expect(source, contains('Yeniden Başlat'));
      },
    );

    testWidgets('Mantık Labirenti can ve duvar arayüzü küçük ekranda taşmaz', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('tr'),
          theme: ThemeData.dark(useMaterial3: true),
          home: const LabirentOyunEkrani(
            seviye: LabirentSeviyesi(
              numara: 1,
              baslik: 'Test Labirenti',
              zorluk: 'KOLAY',
              oyuncuX: 0,
              oyuncuY: 0,
              hedefX: 5,
              hedefY: 5,
              engeller: <String>{
                '1-0',
                '1-1',
                '1-2',
                '3-1',
                '3-2',
                '3-3',
                '4-3',
              },
            ),
            toplamSeviye: 10,
            previousBestScore: 0,
            fixedSessionSeed: 20260829,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 240));

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.favorite_rounded), findsNWidgets(3));
      expect(find.byIcon(Icons.psychology_rounded), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  });

  group('V7.1 oynanış regresyonları', () {
    test('Kelime Avı kesin seçim ve yeni tur döngüsü korunur', () {
      final String source = _source(
        'lib/games/word_hunt/word_hunt_game_page.dart',
      );

      expect(source, contains('localPosition.dx < boardInset'));
      expect(source, isNot(contains('touchOverflow')));
      expect(source, isNot(contains('endTolerance')));
      expect(source, contains('_sameCells(_selection, placement)'));
      expect(source, isNot(contains('selectedText == word')));
      expect(source, contains('widget.level.number <= 3'));
      expect(source, contains('_targetLabel(word, found: found)'));
      expect(source, contains('PointerDownEvent'));
      expect(source, contains('PointerMoveEvent'));
      expect(source, contains('replayLevel: true'));
    });

    test('Şeker Sıralama listeleri büyüyebilir ve yeni tur desteklenir', () {
      final String source = _source(
        'lib/games/candy_sort/candy_sort_game_page.dart',
      );

      expect(
        RegExp(
          r'List<int>\.filled\([^;]+growable: true\)',
          dotAll: true,
        ).allMatches(source).length,
        greaterThanOrEqualTo(2),
      );
      expect(source, contains('removeLast()'));
      expect(source, contains('replayLevel: true'));
    });

    test('Şeker kutusu yalnız dolu ve tek renk olduğunda tamamlanır', () {
      expect(candyJarIsComplete(<int>[2, 2, 2], 3), isTrue);
      expect(candyJarIsComplete(<int>[2, 2], 3), isFalse);
      expect(candyJarIsComplete(<int>[2, 1, 2], 3), isFalse);
      expect(candyJarIsComplete(<int>[], 0), isFalse);

      final String source = _source(
        'lib/games/candy_sort/candy_sort_game_page.dart',
      );

      expect(source, contains('_startJarCelebration'));
      expect(source, contains('_jarCelebrationTimer?.cancel()'));
      expect(source, contains('GameSound.success'));
      expect(source, contains('celebrating: _celebratingJar == index'));
      expect(source, contains('TweenAnimationBuilder<double>'));
      expect(source, contains('_finishing = solved'));
    });

    test('Sayı Peteği yasal karıştırma ve ters çözüm yolunu saklar', () {
      final String source = _source(
        'lib/games/number_sort/number_sort_game_page.dart',
      );

      expect(source, contains('_neighbors(empty)'));
      expect(source, contains('movedValues.reversed.toList'));
      expect(source, contains('_solutionValues'));
      expect(source, contains('replayLevel: true'));
    });

    test(
      'Şekil Birleştirme seçenekleri tam görünür ve yeni tur desteklenir',
      () {
        final String source = _source(
          'lib/games/shape_puzzle/shape_puzzle_game_page.dart',
        );

        expect(source, contains('mainAxisExtent: compact ? 117 : 137'));
        expect(source, contains('dimension: compact ? 78 : 98'));
        expect(source, contains('clipBehavior: Clip.none'));
        expect(source, contains('replayLevel: true'));
      },
    );

    test(
      'beş yeni oyunun tamamı aynı sonuç ve yeni tur altyapısını kullanır',
      () {
        const List<String> files = <String>[
          'lib/games/word_hunt/word_hunt_game_page.dart',
          'lib/games/picture_iq/picture_iq_game_page.dart',
          'lib/games/candy_sort/candy_sort_game_page.dart',
          'lib/games/number_sort/number_sort_game_page.dart',
          'lib/games/shape_puzzle/shape_puzzle_game_page.dart',
        ];

        for (final String file in files) {
          final String source = _source(file);
          expect(source, contains('showParkurResultDialog'), reason: file);
          expect(source, contains('ParkurResultAction.replay'), reason: file);
          expect(
            source,
            anyOf(
              contains('replayLevel: true'),
              contains('replayLevel: action == ParkurResultAction.replay'),
            ),
            reason: file,
          );
        }
      },
    );
  });

  group('Puan, liderlik ve çevrimdışı güvenlik', () {
    test('11 parkurluk azami ilerleme ve Zeka Puanı eşikleri senkrondur', () {
      expect(UnifiedProgressData.maksimumSeviye, 110);
      expect(UnifiedProgressData.maksimumYildiz, 330);
      expect(ZekaScoringService.dailyResultPoints(0), 100);
      expect(ZekaScoringService.dailyResultPoints(3), 250);
    });

    test('bozuk liderlik önbelleği güvenli sınırlara çekilir', () {
      final OnlineLeaderboardEntry entry = OnlineLeaderboardEntry.fromCache(
        <String, dynamic>{
          'uid': 123,
          'displayName': '1234567890123456789012345',
          'avatar': '',
          'xp': -50,
          'level': 500,
          'score': 999999999,
          'stars': 999,
          'completedLevels': 999,
          'bestStreak': -2,
          'perfectDays': 50000,
          'league': '',
          'locale': '',
          'updatedAt': 'bozuk-tarih',
        },
      );

      expect(entry.uid, '');
      expect(entry.displayName.length, 18);
      expect(entry.avatar, '🧠');
      expect(entry.xp, 0);
      expect(entry.level, 50);
      expect(entry.score, 10000000);
      expect(entry.stars, 330);
      expect(entry.completedLevels, 110);
      expect(entry.bestStreak, 0);
      expect(entry.perfectDays, 10000);
      expect(entry.leagueShortName, 'BAŞLANGIÇ');
      expect(entry.locale, 'en');
      expect(entry.updatedAt, isNull);
    });

    test('Firestore V3 kuralları 110 bölüm ve 330 yıldızla uyumludur', () {
      final String rules = _source('firestore.rules');

      expect(rules, contains('match /leaderboard_v3_public/{uid}'));
      expect(rules, contains('data.score == data.xp'));
      expect(rules, contains('data.stars <= 330'));
      expect(rules, contains('data.completedLevels <= 110'));
      expect(rules, contains('data.friendCode.size() == 8'));
      expect(rules, contains('allow read, write: if false'));
    });
  });

  group('V8 çevrim içi sosyal arena', () {
    test('Android Firebase normal çalıştırmada yerel yapılandırmaya düşer', () {
      final String source = _source(
        'lib/services/firebase_bootstrap_service.dart',
      );

      expect(
        source,
        contains('defaultTargetPlatform == TargetPlatform.android'),
      );
      expect(source, contains('await Firebase.initializeApp();'));
      expect(source, contains('_configured = Firebase.apps.isNotEmpty'));
    });

    test('arkadaş kodu sekiz karakter ve kararlıdır', () {
      final OnlineLeaderboardService service =
          OnlineLeaderboardService.instance;

      expect(service.friendCodeForUid('abc-123_xyz'), 'ABC123XY');
      expect(service.friendCodeForUid('a!'), 'AXXXXXXX');
      expect(service.friendCodeForUid('abc-123_xyz'), 'ABC123XY');
    });

    test(
      'paylaşım, uygulama bağlantısı ve Android bildirim izni tanımlıdır',
      () {
        final String pubspec = _source('pubspec.yaml');
        final String manifest = _source(
          'android/app/src/main/AndroidManifest.xml',
        );

        expect(pubspec, contains('firebase_messaging:'));
        expect(pubspec, contains('app_links:'));
        expect(pubspec, contains('share_plus:'));
        expect(manifest, contains('android.permission.POST_NOTIFICATIONS'));
        expect(manifest, contains('android:scheme="zekaparkuru"'));
        expect(manifest, contains('android:host="challenge"'));
      },
    );

    test(
      'meydan okuma on bir oyundan altı oyun ve WhatsApp paylaşımı kullanır',
      () {
        final String challenge = _source(
          'lib/services/social_challenge_service.dart',
        );
        final String page = _source('lib/pages/challenge_center_page.dart');
        final String reflex = _source('lib/games/reflex/reflex_game_page.dart');

        expect(challenge, contains('shuffled.take(6)'));
        expect(challenge, contains("'schemaVersion': 4"));
        expect(challenge, contains("'layoutCodes': layoutCodes"));
        expect(page, contains('WHATSAPP İLE DAVET GÖNDER'));
        expect(page, contains('fixedSessionSeed: challenge.seed'));
        expect(reflex, contains('final int? fixedSessionSeed'));
      },
    );

    test('Firestore düello, arkadaş ve cihaz erişimini sınırlar', () {
      final String rules = _source('firestore.rules');
      final String indexes = _source('firestore.indexes.json');

      expect(rules, contains('match /challenges_v1/{challengeId}'));
      expect(rules, contains('validChallengeOutcome'));
      expect(rules, contains('match /friendships_v1/{friendshipId}'));
      expect(rules, contains('match /player_devices_v1/{uid}'));
      expect(indexes, contains('"fieldPath": "participantIds"'));
      expect(indexes, contains('"fieldPath": "updatedAt"'));
    });

    test('bildirim yönlendirmesi davet kabulü ve sonuç olaylarını dinler', () {
      final String service = _source(
        'lib/services/social_notification_service.dart',
      );
      final String main = _source('lib/main.dart');

      expect(service, contains('FirebaseMessaging.onMessageOpenedApp'));
      expect(service, contains('FirebaseMessaging.onMessage.listen'));
      expect(service, contains("collection('player_devices_v1')"));
      expect(main, contains('onChallengeLink: _openChallenge'));
      expect(main, contains("'AÇ'"));
      expect(main, contains('_noticeOverlay = OverlayEntry('));
      expect(main, contains('seconds: 6'));
    });

    test(
      'Cloud Functions hedefli davet, kabul ve sonuç bildirimi gönderir',
      () {
        final String functions = _source('functions/index.js');

        expect(functions, contains('onDocumentCreated'));
        expect(functions, contains('onDocumentUpdated'));
        expect(functions, contains('Davet kabul edildi!'));
        expect(functions, contains('Düello sonucu hazır'));
        expect(functions, contains('notification_events_v1'));
      },
    );

    test('Firebase Hosting davet sayfası uygulama bağlantısı üretir', () {
      final String hosting = _source('hosting/davet.html');
      final String firebase = _source('firebase.json');

      expect(hosting, contains('Zekâ Parkuru Düellosu'));
      expect(hosting, contains('zekaparkuru://challenge?id='));
      expect(firebase, contains('"public": "hosting"'));
      expect(firebase, contains('"source": "functions"'));
    });
  });

  group('Alt gezinme güvenliği', () {
    test('Görevler ve liderlik dönüş butonları güvenli alanda kalır', () {
      final String tasks = _source('lib/pages/daily_tasks_page.dart');
      final String leaderboard = _source('lib/pages/leaderboard_page.dart');

      for (final String source in <String>[tasks, leaderboard]) {
        expect(source, contains('SafeArea('));
        expect(source, contains('EdgeInsets.only(bottom: 18)'));
        expect(source, contains('width: double.infinity'));
        expect(source, contains('bool _leavingPage = false'));
        expect(source, contains('navigator.canPop()'));
      }
      expect(tasks, contains('_leavingPage ? null : _returnToGame'));
      expect(leaderboard, contains('_leavingPage ? null : _returnHome'));
    });
  });

  group('Refleks dokunma ve akış güvenliği', () {
    test(
      'düşen hedef alt bölgede erken kilitlenmez ve geniş alandan yakalanır',
      () {
        final String reflex = _source('lib/games/reflex/reflex_game_page.dart');

        expect(reflex, contains('fastFallingFlow'));
        expect(reflex, contains('widget.level.timeLimitMs * 0.68'));
        expect(reflex, contains('onPointerDown: (_)'));
        expect(reflex, contains('width: 112'));
        expect(reflex, contains('height: 112'));
        expect(reflex, contains('_roundGeneration'));
      },
    );
  });

  group('V8.1 Zekâ Arenası grup yarışmaları', () {
    test('arena kataloğu 11 oyunu eksiksiz ve benzersiz sunar', () {
      expect(ArenaService.allGameIds, orderedEquals(_expectedGameIds));
      expect(ArenaService.allGameIds.toSet().length, 11);
      expect(
        ArenaService.featuredGameIds,
        orderedEquals(<String>['hanoi', 'picture_iq', 'candy_sort']),
      );
    });

    test('yeni grup yarışmaları altı rastgele oyuna sabitlenir', () {
      final String service = _source('lib/services/arena_service.dart');
      final String rules = _source('firestore.rules');
      final String page = _source('lib/pages/arena_page.dart');

      expect(service, contains('shuffledGames.take(6)'));
      expect(rules, contains('data.gameIds.size() == 6'));
      expect(page, contains('6 OYUNLUK RASTGELE PARKUR'));
      expect(page, isNot(contains('BÜYÜK PARKUR • 11')));
    });

    test('yarışma oyunları seviye merkezini göstermeden bölümü açar', () {
      final String block = _source('lib/games/blocks/block_game_page.dart');
      final String memory = _source('lib/games/memory/memory_game_page.dart');
      final String hanoi = _source('lib/games/hanoi/hanoi_game_page.dart');
      final String reflex = _source('lib/games/reflex/reflex_game_page.dart');
      final String kit = _source('lib/games/shared/parkur_game_kit.dart');

      expect(block, contains('yukleniyor || widget.competitionLevel != null'));
      expect(memory, contains('loading || widget.competitionLevel != null'));
      expect(hanoi, contains('loading || widget.competitionLevel != null'));
      expect(reflex, contains('loading || widget.competitionLevel != null'));
      expect(kit, contains('_loading || widget.competitionLevel != null'));

      expect(block, contains('_openCompetitionLevelIfNeeded()'));
      expect(memory, contains('_openCompetitionLevelIfNeeded()'));
      expect(hanoi, contains('_openCompetitionLevelIfNeeded()'));
      expect(reflex, contains('_openCompetitionLevelIfNeeded()'));
      expect(kit, contains('_openCompetitionLevelIfNeeded()'));
    });

    test('iki dünya sıralaması ilk yirmi dışında kullanıcıyı gösterir', () {
      final String challenge = _source('lib/pages/challenge_center_page.dart');
      final String leaderboard = _source('lib/pages/leaderboard_page.dart');
      final String service = _source(
        'lib/services/online_leaderboard_service.dart',
      );

      expect(service, contains('sorted.add(currentEntry)'));
      expect(challenge, contains('world_current_player_separator'));
      expect(challenge, contains(r"'${player.displayName} • SEN'"));
      expect(challenge, contains('final bool isCurrent'));
      expect(leaderboard, contains('leaderboard_current_player_separator'));
      expect(leaderboard, contains('entry: entries.firstWhere'));
    });

    test('günlük parkur Refleks kilitli yarışma seviyesini açar', () {
      final String reflex = _source('lib/games/reflex/reflex_game_page.dart');
      final String daily = _source('lib/pages/daily_course_page.dart');

      expect(
        reflex,
        contains(
          'widget.competitionLevel == null && '
          'index + 1 > unlockedLevel',
        ),
      );
      expect(reflex, contains('_openCompetitionLevelIfNeeded()'));
      expect(daily, contains("case 'reflex':"));
      expect(daily, contains('return ReflexGamePage('));
    });

    test('günlük parkur tek merkezli ve güvenli ilerler', () {
      final String daily = _source('lib/pages/daily_course_page.dart');

      expect(daily, isNot(contains('class _DailyCourseGameShell')));
      expect(daily, contains("'daily_course_skip_button'"));
      expect(daily, contains("'BU BÖLÜMÜ GEÇ'"));
      expect(daily, contains('class _DailyCourseStageTransition'));
      expect(daily, contains('Future<bool> _showStageTransition'));
      expect(daily, contains('DailyStageResult.skipped'));
      expect(daily, contains('recordStageResult('));
      expect(daily, contains('onPopInvokedWithResult'));
      expect(daily, contains('_close(false)'));
      expect(
        RegExp(r'competitionLayoutCode:\s*layoutCode').allMatches(daily).length,
        11,
      );
      expect(daily, contains('Duration(milliseconds: 950)'));
    });

    test('11 oyunda yarışma sonucu oyun içi menüyü beklemez', () {
      final String kit = _source('lib/games/shared/parkur_game_kit.dart');
      final String numbers = _source('lib/games/numbers/number_game_page.dart');
      final String dailyResults = _source(
        'lib/services/daily_course_service.dart',
      );
      const List<String> directPlayFiles = <String>[
        'lib/games/logic/logic_game_page.dart',
        'lib/games/numbers/number_game_page.dart',
        'lib/games/blocks/block_game_page.dart',
        'lib/games/memory/memory_game_page.dart',
        'lib/games/memory/shape_match_game_page.dart',
        'lib/games/hanoi/hanoi_game_page.dart',
        'lib/games/word_hunt/word_hunt_game_page.dart',
        'lib/games/picture_iq/picture_iq_game_page.dart',
        'lib/games/candy_sort/candy_sort_game_page.dart',
        'lib/games/number_sort/number_sort_game_page.dart',
        'lib/games/shape_puzzle/shape_puzzle_game_page.dart',
        'lib/games/reflex/reflex_game_page.dart',
      ];

      expect(kit, contains('bool competitionMode'));
      expect(kit, contains('widget.competitionLevel != null'));
      expect(kit, contains('gameId: widget.gameId'));
      expect(kit, contains('DailyStageResult.failed(gameId: widget.gameId)'));
      expect(dailyResults, contains('outcome: DailyStageOutcome.failed'));
      expect(dailyResults, contains('stars: 0'));
      expect(dailyResults, contains('rawScore: 0'));
      expect(
        numbers,
        contains('widget.competitionLevel == null && index + 1 > acikSeviye'),
      );

      for (final String file in directPlayFiles) {
        final String source = _source(file);
        expect(source, contains('competitionMode'), reason: file);
        expect(source, contains('widget.competitionMode'), reason: file);
      }
    });

    test('grup parkuru ortak sonuç sözleşmesiyle güvenle ilerler', () {
      final String page = _source('lib/pages/arena_page.dart');

      expect(page, contains('Future<void> _playParkour('));
      expect(page, contains('buildChallengeCompetitionPage('));
      expect(page, contains('rawResult is DailyStageResult'));
      expect(page, contains('ArenaAttemptOutcome.failed'));
      expect(page, contains('ArenaAttemptOutcome.skipped'));
      expect(page, contains('await _arena.submitAttempt('));
      expect(page, contains('await _saveCheckpoint(currentCheckpoint)'));
      expect(page, contains('CompetitionStageTransition.show('));
      expect(page, contains('showCompetitionExitDecision('));
      expect(page, contains('event.gameIds.take(localNext)'));
      expect(page, isNot(contains('class _ArenaSeriesGameShell')));
      expect(page, isNot(contains('Widget _competitionPage(')));
    });
    test('hafıza yarışma başarısızlığı parkuru durdurmaz', () {
      final String memory = _source('lib/games/memory/memory_game_page.dart');

      expect(memory, contains('if (widget.competitionMode)'));
      expect(memory, contains('stars: 0'));
      expect(memory, contains('score: 0'));
      expect(memory, contains('MemoryLevelResult('));
    });

    test('meydan okuma ve grup sonucu ortak şampiyon kutlamasını kullanır', () {
      final String challenge = _source('lib/pages/challenge_center_page.dart');
      final String arena = _source('lib/pages/arena_page.dart');
      final String celebration = _source(
        'lib/widgets/champion_celebration_card.dart',
      );

      expect(challenge, contains("'MAŞALLAH!'"));
      expect(challenge, contains("'Şampiyon sensin 🏆'"));
      expect(challenge, contains('Bu mücadeleyi rakibin kazandı.'));
      expect(arena, contains("title: 'MAŞALLAH!'"));
      expect(arena, contains('grup şampiyonu 🏆'));
      expect(celebration, contains('GameSound.applause'));
      expect(celebration, contains('audio.hapticHeavy()'));
      expect(celebration, contains('_CelebrationConfettiPainter'));
    });

    test('grup sonucunda güvenli hazır mesajlar canlı paylaşılır', () {
      final String service = _source('lib/services/arena_service.dart');
      final String rules = _source('firestore.rules');
      final String page = _source('lib/pages/arena_page.dart');

      expect(service, contains("collection('arena_reactions_v1')"));
      expect(service, contains('Future<bool> sendReaction('));
      expect(rules, contains('match /arena_reactions_v1/{reactionId}'));
      expect(rules, contains('validArenaReaction'));
      expect(page, contains("'good_game': 'İyi yarıştın 👏'"));
      expect(page, contains("'rematch': 'Rövanş? ⚔️'"));
      expect(page, contains("'close_game': 'Çok yakındı 😅'"));
      expect(page, contains("'congrats': 'Tebrikler 🏆'"));
    });

    test('turnuva puanı tüm oyunlarda aynı 100-1000 ölçeğini kullanır', () {
      expect(ArenaService.competitionPoints(0), 100);
      expect(ArenaService.competitionPoints(1), 400);
      expect(ArenaService.competitionPoints(2), 700);
      expect(ArenaService.competitionPoints(3), 1000);
      expect(ArenaService.competitionPoints(99), 1000);
    });

    test('11 oyunun tamamı ortak seviye ve parkur düzeni kabul eder', () {
      const List<String> files = <String>[
        'lib/games/logic/logic_game_page.dart',
        'lib/games/numbers/number_game_page.dart',
        'lib/games/blocks/block_game_page.dart',
        'lib/games/memory/memory_game_page.dart',
        'lib/games/hanoi/hanoi_game_page.dart',
        'lib/games/word_hunt/word_hunt_game_page.dart',
        'lib/games/picture_iq/picture_iq_game_page.dart',
        'lib/games/candy_sort/candy_sort_game_page.dart',
        'lib/games/number_sort/number_sort_game_page.dart',
        'lib/games/shape_puzzle/shape_puzzle_game_page.dart',
        'lib/games/reflex/reflex_game_page.dart',
      ];
      for (final String file in files) {
        final String source = _source(file);
        expect(source, contains('competitionLevel'), reason: file);
        if (!file.contains('/hanoi/')) {
          expect(source, contains('competitionLayoutCode'), reason: file);
        }
      }
    });

    test('grup, yarışma ve tek deneme Firestore kurallarıyla sınırlıdır', () {
      final String rules = _source('firestore.rules');
      expect(rules, contains('match /arena_groups_v1/{groupId}'));
      expect(rules, contains('match /arena_events_v1/{eventId}'));
      expect(rules, contains('match /arena_attempts_v1/{attemptId}'));
      expect(rules, contains('data.participantIds.size() <= 30'));
      expect(rules, contains('data.points == 100 + data.stars * 300'));
      expect(rules, isNot(contains("'format': 'direct'")));
      expect(rules, contains("data.format == 'direct'"));
      expect(rules, contains('allow update, delete: if false'));
    });

    test('ana menü, WhatsApp daveti ve arena bağlantısı hazırdır', () {
      final String main = _source('lib/main.dart');
      final String page = _source('lib/pages/arena_page.dart');
      final String notifications = _source(
        'lib/services/social_notification_service.dart',
      );
      final String leaderboard = _source(
        'lib/services/online_leaderboard_service.dart',
      );
      final String manifest = _source(
        'android/app/src/main/AndroidManifest.xml',
      );
      final String hosting = _source('hosting/arena.html');

      expect(main, contains('_HomeArenaCard(onTap: arenayiAc)'));
      expect(page, contains('SharePlus.instance.share'));
      expect(page, contains('6 OYUNLUK RASTGELE PARKUR'));
      expect(leaderboard, contains('.take(30)'));
      expect(notifications, contains("uri.host == 'arena'"));
      expect(manifest, contains('android:host="arena"'));
      expect(hosting, contains('zekaparkuru://arena?g='));
    });

    test(
      'arena pencere yaşam döngüsü ve Firebase hataları güvenle yönetilir',
      () {
        final String arena = _source('lib/pages/arena_page.dart');
        final String bootstrap = _source(
          'lib/services/firebase_bootstrap_service.dart',
        );
        final String reachability = _source(
          'lib/services/firebase_reachability_io.dart',
        );
        final String manifest = _source(
          'android/app/src/main/AndroidManifest.xml',
        );

        expect(
          arena,
          isNot(contains('final TextEditingController controller')),
        );
        expect(arena, isNot(contains('controller.dispose();')));
        expect(arena, contains("String draftName = '';"));
        expect(arena, contains("String draftCode = '';"));
        expect(bootstrap, contains('canResolveFirebaseServices()'));
        expect(bootstrap, contains('.getToken(true)'));
        expect(bootstrap, contains('Debug anahtarlarını yönet'));
        expect(reachability, contains('firestore.googleapis.com'));
        expect(reachability, contains('firebaseappcheck.googleapis.com'));
        expect(reachability, contains('results.any'));
        expect(reachability, isNot(contains('results.every')));
        expect(
          manifest,
          contains('android:enableOnBackInvokedCallback="true"'),
        );
      },
    );

    test(
      'App Check tekrarları sınırlı ve bildirim yeniden bağlantısı hazırdır',
      () {
        final String bootstrap = _source(
          'lib/services/firebase_bootstrap_service.dart',
        );
        final String errors = _source(
          'lib/services/app_error_monitoring_service.dart',
        );
        final String notifications = _source(
          'lib/services/social_notification_service.dart',
        );
        final String arena = _source('lib/pages/arena_page.dart');
        final String challenge = _source(
          'lib/pages/challenge_center_page.dart',
        );
        final String leaderboard = _source('lib/pages/leaderboard_page.dart');
        final String gradle = _source('android/gradle.properties');

        expect(bootstrap, contains('bool forceRetry = false'));
        expect(bootstrap, contains('_automaticRetryAfter'));
        expect(bootstrap, contains("normalized.contains('too many attempts')"));
        expect(bootstrap, contains('const Duration(minutes: 1)'));
        expect(errors, contains('if (kDebugMode)'));
        expect(notifications, contains('_messagingStarted'));
        expect(notifications, contains('_scheduleStartupRetry()'));
        expect(notifications, contains('_ensureMessagingListeners'));
        expect(arena, contains('ensureOnline(forceRetry: forceRetry)'));
        expect(
          RegExp(r'ensureOnline\(\s*forceRetry:\s*forceRetry')
              .hasMatch(challenge),
          isTrue,
        );
        expect(arena, contains('unawaited(_initialize())'));
        expect(challenge, contains('unawaited(_initialize())'));
        expect(challenge, contains('if (_initializing) return;'));
        expect(arena, contains("PageStorageKey<String>('arena_home_scroll')"));
        expect(arena, contains('if (_initializing) return;'));
        expect(arena, isNot(contains(': RefreshIndicator(')));
        expect(
          challenge,
          contains('onRefresh: () => _initialize(forceRetry: true)'),
        );
        expect(leaderboard, contains('forceRetry: true'));
        expect(gradle, contains('--enable-native-access=ALL-UNNAMED'));
      },
    );
  });
}
