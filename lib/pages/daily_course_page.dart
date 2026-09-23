import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_visual_theme.dart';

import '../games/blocks/block_game_page.dart';
import '../games/hanoi/hanoi_game_page.dart';
import '../games/logic/logic_game_page.dart';
import '../games/memory/memory_game_page.dart';
import '../games/numbers/number_game_page.dart';
import '../games/candy_sort/candy_sort_game_page.dart';
import '../games/number_sort/number_sort_game_page.dart';
import '../games/picture_iq/picture_iq_game_page.dart';
import '../games/reflex/reflex_game_page.dart';
import '../games/shape_puzzle/shape_puzzle_game_page.dart';
import '../games/word_hunt/word_hunt_game_page.dart';
import '../l10n/app_localizations.dart';
import '../services/daily_challenge_service.dart';
import '../services/daily_course_service.dart';
import '../services/daily_reminder_service.dart';
import '../services/game_audio_service.dart';
import '../services/zeka_scoring_service.dart';

enum _DailyExitDecision { retry, skip, leave }

class DailyCoursePage extends StatefulWidget {
  const DailyCoursePage({super.key});

  @override
  State<DailyCoursePage> createState() => _DailyCoursePageState();
}

class _DailyCoursePageState extends State<DailyCoursePage> {
  final DailyCourseService _course = DailyCourseService.instance;
  final GameAudioService _audio = GameAudioService.instance;

  DailyCourseData? _data;
  bool _loading = true;
  bool _running = false;
  int _replayRound = 0;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }
    try {
      final DailyCourseData data = await _course.loadToday();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Daily Course load failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _data = null;
        _loading = false;
        _loadError = '$error';
      });
    }
  }

  Future<void> _startOrResume() async {
    if (_running) return;
    setState(() => _running = true);
    bool replayRequested = false;
    try {
      await _audio.play(GameSound.uiClick);
      if (!mounted) return;

      while (mounted) {
        final DailyCourseData current = await _course.loadToday();
        if (!mounted) return;
        setState(() => _data = current);

        final String? gameId = current.nextGameId;
        if (gameId == null) {
          replayRequested = await _showCompletion(current);
          break;
        }

        final DateTime runDate = DateTime.parse(current.dateKey);
        final int competitionLevel = _course.levelForDailyCourse(
          date: runDate,
          gameId: gameId,
          runNumber: 0,
        );
        final int layoutCode = _course.layoutCodeForDailyCourse(
          date: runDate,
          gameId: gameId,
          runNumber: 0,
        );

        DailyStageResult? result = await _openDailyStage(
          gameId: gameId,
          competitionLevel: competitionLevel,
          layoutCode: layoutCode,
        );
        if (!mounted) return;

        if (result == null || result.outcome == DailyStageOutcome.exited) {
          final _DailyExitDecision decision = await _showExitDecision(gameId);
          if (!mounted) return;
          switch (decision) {
            case _DailyExitDecision.retry:
              continue;
            case _DailyExitDecision.skip:
              result = DailyStageResult.skipped(gameId: gameId);
            case _DailyExitDecision.leave:
              await _load();
              return;
          }
        }

        if (result.gameId != gameId) {
          throw StateError(
            'Günlük parkur sonucu yanlış oyundan döndü: '
            '${result.gameId} != $gameId',
          );
        }

        final DailyCourseData updated = await _course.recordStageResult(
          result,
          expectedDateKey: current.dateKey,
        );
        if (!mounted) return;
        setState(() => _data = updated);

        if (result.outcome == DailyStageOutcome.completed &&
            updated.dateKey == current.dateKey &&
            updated.successfulGames.contains(gameId)) {
          await DailyChallengeService.instance.recordLevelCompleted(
            gameId: gameId,
            stars: result.stars,
            score: result.rawScore,
          );
          if (!mounted) return;
        }

        if (updated.allCompleted) {
          await DailyReminderService.instance.markTodayCompleted();
          await _playCourseCompletionSound();
          if (!mounted) return;
          replayRequested = await _showCompletion(updated);
          break;
        }

        await _audio.play(
          result.outcome == DailyStageOutcome.completed
              ? GameSound.success
              : GameSound.uiClick,
        );
        if (!mounted) return;

        final bool continueCourse = await _showStageTransition(
          completedCount: updated.completedCount,
          totalCount: updated.games.length,
          result: result,
          nextGameId: updated.nextGameId,
        );
        if (!continueCourse) {
          await _load();
          return;
        }
      }
    } catch (error, stackTrace) {
      debugPrint('Daily Course run failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Günün Parkuru güvenli şekilde durduruldu. İlerlemen korundu.',
              ),
            ),
          );
        await _load();
      }
    } finally {
      if (mounted) setState(() => _running = false);
    }

    if (replayRequested && mounted) {
      await _startReplay();
    }
  }

  Future<DailyStageResult?> _openDailyStage({
    required String gameId,
    required int competitionLevel,
    required int layoutCode,
  }) {
    return Navigator.push<DailyStageResult>(
      context,
      MaterialPageRoute<DailyStageResult>(
        builder: (_) => _pageFor(gameId, competitionLevel, layoutCode),
      ),
    );
  }

  Future<_DailyExitDecision> _showExitDecision(String gameId) async {
    if (!mounted) return _DailyExitDecision.leave;
    final bool english = context.l10n.isEnglish;
    final String gameName = _gameName(gameId, english);
    return await showModalBottomSheet<_DailyExitDecision>(
          context: context,
          useSafeArea: true,
          isDismissible: false,
          enableDrag: false,
          backgroundColor: Colors.transparent,
          builder: (BuildContext sheetContext) {
            return PopScope(
              canPop: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[Color(0xFF18345F), Color(0xFF111E3B)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFF4C79AE)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Icon(
                        Icons.save_alt_rounded,
                        color: Color(0xFF7DEFD1),
                        size: 40,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        english
                            ? 'LEAVE THE DAILY COURSE?'
                            : 'GÜNÜN PARKURUNDAN ÇIKILSIN MI?',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        english
                            ? '$gameName is not resolved. The same game, level and layout will be kept.'
                            : '$gameName henüz sonuçlanmadı. Aynı oyun, seviye ve düzen korunacak.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: () => Navigator.pop(
                          sheetContext,
                          _DailyExitDecision.retry,
                        ),
                        icon: const Icon(Icons.replay_rounded),
                        label: Text(
                          english ? 'RETURN TO GAME' : 'OYUNA DÖN',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(height: 9),
                      OutlinedButton.icon(
                        key: const ValueKey<String>('daily_course_skip_button'),
                        onPressed: () => Navigator.pop(
                          sheetContext,
                          _DailyExitDecision.skip,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFFD334),
                          side: const BorderSide(color: Color(0xFFFFD334)),
                        ),
                        icon: const Icon(Icons.skip_next_rounded),
                        label: Text(
                          english ? 'SKIP THIS SECTION' : 'BU BÖLÜMÜ GEÇ',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        english
                            ? 'Skipping records 0 stars and 0 points.'
                            : 'Geçilen bölüm 0 yıldız ve 0 puanla kaydedilir.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => Navigator.pop(
                          sheetContext,
                          _DailyExitDecision.leave,
                        ),
                        icon: const Icon(Icons.exit_to_app_rounded),
                        label: Text(
                          english ? 'LEAVE THE COURSE' : 'PARKURDAN ÇIK',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ) ??
        _DailyExitDecision.leave;
  }

  Future<void> _startReplay() async {
    if (_running) return;
    setState(() {
      _running = true;
    });
    bool replayAgain = false;

    try {
      await _audio.play(GameSound.uiClick);
      if (!mounted) return;

      final DailyCourseData savedData = await _course.loadToday();
      if (!mounted) return;

      final int replayRound = _replayRound + 1;
      final DateTime runDate = DateTime.now();
      final List<String> games = _course.gamesForReplay(runDate, replayRound);
      setState(() => _replayRound = replayRound);

      int totalStars = 0;
      int totalScore = 0;
      final Set<String> successfulGames = <String>{};
      final Set<String> failedGames = <String>{};
      final Set<String> skippedGames = <String>{};

      for (int index = 0; mounted && index < games.length; index++) {
        final String gameId = games[index];
        final int competitionLevel = _course.levelForDailyCourse(
          date: runDate,
          gameId: gameId,
          runNumber: replayRound,
        );
        final int layoutCode = _course.layoutCodeForDailyCourse(
          date: runDate,
          gameId: gameId,
          runNumber: replayRound,
        );

        DailyStageResult? result;
        while (mounted) {
          result = await _openDailyStage(
            gameId: gameId,
            competitionLevel: competitionLevel,
            layoutCode: layoutCode,
          );
          if (!mounted) return;
          if (result != null && result.outcome != DailyStageOutcome.exited) {
            break;
          }

          final _DailyExitDecision decision = await _showExitDecision(gameId);
          if (!mounted) return;
          if (decision == _DailyExitDecision.retry) continue;
          if (decision == _DailyExitDecision.skip) {
            result = DailyStageResult.skipped(gameId: gameId);
            break;
          }
          return;
        }
        if (result == null) return;

        if (result.outcome == DailyStageOutcome.completed) {
          successfulGames.add(gameId);
          totalStars += result.stars.clamp(0, 3).toInt();
          totalScore += ZekaScoringService.dailyResultPoints(result.stars);
        } else if (result.outcome == DailyStageOutcome.failed) {
          failedGames.add(gameId);
        } else if (result.outcome == DailyStageOutcome.skipped) {
          skippedGames.add(gameId);
        }

        if (index < games.length - 1) {
          await _audio.play(
            result.outcome == DailyStageOutcome.completed
                ? GameSound.success
                : GameSound.uiClick,
          );
          if (!mounted) return;
          final bool continueCourse = await _showStageTransition(
            completedCount: index + 1,
            totalCount: games.length,
            result: result,
            nextGameId: games[index + 1],
          );
          if (!continueCourse) return;
          continue;
        }

        await _playCourseCompletionSound();
        if (!mounted) return;

        replayAgain = await _showCompletion(
          DailyCourseData(
            dateKey: savedData.dateKey,
            games: games,
            completedGames: games.toSet(),
            successfulGames: successfulGames,
            failedGames: failedGames,
            skippedGames: skippedGames,
            totalStars: totalStars,
            totalScore: totalScore,
          ),
          replay: true,
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Daily Course replay failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Tekrar parkuru güvenli şekilde durduruldu.'),
            ),
          );
      }
    } finally {
      if (mounted) {
        setState(() => _running = false);
      }
    }

    if (replayAgain && mounted) {
      await _startReplay();
    }
  }

  Future<bool> _showStageTransition({
    required int completedCount,
    required int totalCount,
    required DailyStageResult result,
    required String? nextGameId,
  }) async {
    if (!mounted) return false;

    final bool english = context.l10n.isEnglish;
    final String nextGameName = nextGameId == null
        ? ''
        : _gameName(nextGameId, english);

    return await showGeneralDialog<bool>(
          context: context,
          barrierDismissible: false,
          barrierLabel: english ? 'Course transition' : 'Parkur geçişi',
          barrierColor: const Color(0xD907162E),
          transitionDuration: const Duration(milliseconds: 260),
          pageBuilder: (_, _, _) {
            return _DailyCourseStageTransition(
              completedCount: completedCount,
              totalCount: totalCount,
              outcome: result.outcome,
              stars: result.stars,
              score: result.rawScore,
              nextGameName: nextGameName,
              english: english,
            );
          },
          transitionBuilder: (_, Animation<double> animation, _, Widget child) {
            final Animation<double> curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            );
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: curved, child: child),
            );
          },
        ) ??
        false;
  }

  Future<void> _playCourseCompletionSound() async {
    await _audio.play(GameSound.levelComplete);
    await _audio.playMashallahCelebration();
  }

  Widget _pageFor(String gameId, int competitionLevel, int layoutCode) {
    switch (gameId) {
      case 'logic':
        return LogicGamePage(
          dailyCourseMode: true,
          competitionLevel: competitionLevel,
          competitionLayoutCode: layoutCode,
        );
      case 'numbers':
        return NumberGamePage(
          dailyCourseMode: true,
          competitionLevel: competitionLevel,
          competitionLayoutCode: layoutCode,
        );
      case 'blocks':
        return BlockGamePage(
          dailyCourseMode: true,
          competitionLevel: competitionLevel,
          competitionLayoutCode: layoutCode,
        );
      case 'memory':
        return MemoryGamePage(
          dailyCourseMode: true,
          competitionLevel: competitionLevel,
          competitionLayoutCode: layoutCode,
        );
      case 'hanoi':
        return HanoiGamePage(
          dailyCourseMode: true,
          competitionLevel: competitionLevel,
          competitionLayoutCode: layoutCode,
        );
      case 'word_hunt':
        return WordHuntGamePage(
          dailyCourseMode: true,
          competitionLevel: competitionLevel,
          competitionLayoutCode: layoutCode,
        );
      case 'picture_iq':
        return PictureIqGamePage(
          dailyCourseMode: true,
          competitionLevel: competitionLevel,
          competitionLayoutCode: layoutCode,
        );
      case 'candy_sort':
        return CandySortGamePage(
          dailyCourseMode: true,
          competitionLevel: competitionLevel,
          competitionLayoutCode: layoutCode,
        );
      case 'number_sort':
        return NumberSortGamePage(
          dailyCourseMode: true,
          competitionLevel: competitionLevel,
          competitionLayoutCode: layoutCode,
        );
      case 'shape_puzzle':
        return ShapePuzzleGamePage(
          dailyCourseMode: true,
          competitionLevel: competitionLevel,
          competitionLayoutCode: layoutCode,
        );
      case 'reflex':
        return ReflexGamePage(
          dailyCourseMode: true,
          competitionLevel: competitionLevel,
          competitionLayoutCode: layoutCode,
        );
      default:
        return _DailyCourseUnavailablePage(gameId: gameId);
    }
  }

  String _gameName(String gameId, bool english) {
    switch (gameId) {
      case 'logic':
        return english ? 'Logic Path' : 'Mantık Yolu';
      case 'numbers':
        return english ? 'Number Arena' : 'Sayı Arenası';
      case 'blocks':
        return english ? 'Block Mind' : 'Blok Zekâ';
      case 'memory':
        return english ? 'Memory Master' : 'Hafıza Ustası';
      case 'hanoi':
        return english ? 'Tower of Hanoi' : 'Hanoi Kulesi';
      case 'word_hunt':
        return english ? 'Word Hunt' : 'Kelime Avı';
      case 'picture_iq':
        return english ? 'Visual IQ' : 'Görsel IQ';
      case 'candy_sort':
        return english ? 'Candy Sort' : 'Şeker Sıralama';
      case 'number_sort':
        return english ? 'Number Hive' : 'Sayı Peteği';
      case 'shape_puzzle':
        return english ? 'Shape Merge' : 'Şekil Birleştir';
      case 'reflex':
        return english ? 'Reflex Hunt' : 'Refleks Avı';
      default:
        return english ? 'Game' : 'Oyun';
    }
  }

  String _gameDescription(String gameId, bool english) {
    switch (gameId) {
      case 'logic':
        return english
            ? 'Find the route and solve the logic.'
            : 'Rotayı bul, mantığı çöz.';
      case 'numbers':
        return english
            ? 'Complete a number challenge.'
            : 'Bir sayı meydan okumasını tamamla.';
      case 'blocks':
        return english
            ? 'Place the pieces with a smart move.'
            : 'Parçaları akıllı hamleyle yerleştir.';
      case 'memory':
        return english
            ? 'Put your visual memory to work.'
            : 'Görsel hafızanı çalıştır.';
      case 'hanoi':
        return english
            ? 'Move the rings in the right order.'
            : 'Halkaları doğru sırayla taşı.';
      case 'word_hunt':
        return english
            ? 'Find every hidden word.'
            : 'Gizlenen kelimelerin tamamını bul.';
      case 'picture_iq':
        return english
            ? 'Decode a visual transformation.'
            : 'Görsel dönüşüm kuralını çöz.';
      case 'candy_sort':
        return english
            ? 'Group candies by color.'
            : 'Şekerleri renklerine göre grupla.';
      case 'number_sort':
        return english
            ? 'Restore the number order.'
            : 'Sayıları doğru sıraya getir.';
      case 'shape_puzzle':
        return english
            ? 'Combine fragments into a silhouette.'
            : 'Parçaları tek silüette birleştir.';
      case 'reflex':
        return english
            ? 'React to the correct target.'
            : 'Doğru hedefe hızla tepki ver.';
      default:
        return '';
    }
  }

  IconData _gameIcon(String gameId) {
    switch (gameId) {
      case 'logic':
        return Icons.route_rounded;
      case 'numbers':
        return Icons.calculate_rounded;
      case 'blocks':
        return Icons.view_in_ar_rounded;
      case 'memory':
        return Icons.grid_view_rounded;
      case 'hanoi':
        return Icons.account_balance_rounded;
      case 'word_hunt':
        return Icons.travel_explore_rounded;
      case 'picture_iq':
        return Icons.auto_awesome_mosaic_rounded;
      case 'candy_sort':
        return Icons.cookie_rounded;
      case 'number_sort':
        return Icons.hive_rounded;
      case 'shape_puzzle':
        return Icons.interests_rounded;
      case 'reflex':
        return Icons.bolt_rounded;
      default:
        return Icons.sports_esports_rounded;
    }
  }

  Color _gameColor(String gameId) {
    switch (gameId) {
      case 'logic':
        return const Color(0xFF52E86B);
      case 'numbers':
        return const Color(0xFF00D9FF);
      case 'blocks':
        return const Color(0xFFFF8A00);
      case 'memory':
        return const Color(0xFFE748CF);
      case 'hanoi':
        return const Color(0xFFB06CFF);
      case 'word_hunt':
        return const Color(0xFF00D9A6);
      case 'picture_iq':
        return const Color(0xFFFF4FA3);
      case 'candy_sort':
        return const Color(0xFFFF8A3D);
      case 'number_sort':
        return const Color(0xFFFFD334);
      case 'shape_puzzle':
        return const Color(0xFF8C6CFF);
      case 'reflex':
        return const Color(0xFFFF5B5B);
      default:
        return Colors.white;
    }
  }

  Future<bool> _showCompletion(
    DailyCourseData data, {
    bool replay = false,
  }) async {
    if (!mounted) return false;
    final bool english = context.l10n.isEnglish;
    final bool perfect = data.allSuccessful;

    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF173B69), Color(0xFF351D70)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x8800D9FF),
                      blurRadius: 30,
                      spreadRadius: -14,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 78,
                      height: 78,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFD334),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        color: Color(0xFF5D3A00),
                        size: 47,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      perfect
                          ? english
                                ? 'Daily Course Complete!'
                                : 'Günün Parkuru Tamamlandı!'
                          : english
                          ? 'Daily Route Complete'
                          : 'Günlük Rota Tamamlandı',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      perfect
                          ? english
                                ? 'You cleared all ${data.games.length} brain stations.'
                                : '${data.games.length} zekâ istasyonunu da başarıyla geçtin.'
                          : english
                          ? '${data.successfulCount} completed • '
                                '${data.failedGames.length} failed • '
                                '${data.skippedGames.length} skipped'
                          : '${data.successfulCount} tamamlandı • '
                                '${data.failedGames.length} başarısız • '
                                '${data.skippedGames.length} geçildi',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _ResultStat(
                            icon: Icons.star_rounded,
                            color: const Color(0xFFFFD334),
                            value: '${data.totalStars}',
                            label: english ? 'Stars' : 'Yıldız',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ResultStat(
                            icon: Icons.bolt_rounded,
                            color: const Color(0xFF00D9FF),
                            value: '${data.totalScore}',
                            label: english ? 'Brain Points' : 'Zeka Puanı',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF00D9FF),
                          foregroundColor: const Color(0xFF041527),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        icon: const Icon(Icons.replay_rounded),
                        label: Text(
                          english ? 'Play a New Course' : 'Parkuru Tekrar Oyna',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: Text(
                        english ? 'Finish for now' : 'Şimdilik Tamam',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    if (replay)
                      Text(
                        english
                            ? 'Replay scores do not add the daily reward again.'
                            : 'Tekrar puanı günlük ödülü yeniden artırmaz.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 9,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final DailyCourseData? data = _data;
    final bool english = context.l10n.isEnglish;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          english ? 'Daily Brain Course' : 'Günün Zekâ Parkuru',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : data == null
          ? _DailyCourseLoadFailure(error: _loadError, onRetry: _load)
          : SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                children: [
                  _CourseHero(data: data, english: english),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          english ? "Today's Route" : 'Bugünün Rotası',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        '${data.completedCount}/${data.games.length}',
                        style: const TextStyle(
                          color: Color(0xFF7BEAFF),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  for (int index = 0; index < data.games.length; index++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 11),
                      child: _CourseStepCard(
                        number: index + 1,
                        name: _gameName(data.games[index], english),
                        description: _gameDescription(
                          data.games[index],
                          english,
                        ),
                        icon: _gameIcon(data.games[index]),
                        color: _gameColor(data.games[index]),
                        outcome: data.outcomeFor(data.games[index]),
                        current: data.nextGameId == data.games[index],
                      ),
                    ),
                  const SizedBox(height: 5),
                  SizedBox(
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _running
                          ? null
                          : data.allCompleted
                          ? _startReplay
                          : _startOrResume,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF00D9FF),
                        foregroundColor: const Color(0xFF041527),
                        disabledBackgroundColor: const Color(0xFF173B69),
                        disabledForegroundColor: Colors.white70,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      icon: _running
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              data.allCompleted
                                  ? Icons.replay_rounded
                                  : data.completedCount == 0
                                  ? Icons.play_arrow_rounded
                                  : Icons.fast_forward_rounded,
                            ),
                      label: Text(
                        data.allCompleted
                            ? english
                                  ? 'Play a New Course'
                                  : 'Parkuru Tekrar Oyna'
                            : data.completedCount == 0
                            ? english
                                  ? 'Start the Course'
                                  : 'Parkuru Başlat'
                            : english
                            ? 'Continue the Course'
                            : 'Parkura Devam Et',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 11),
                  Text(
                    english
                        ? 'Complete one level in each game. Your normal game progress is preserved.'
                        : 'Her oyunda bir seviye tamamla. Normal oyun ilerlemen aynen korunur.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _DailyCourseLoadFailure extends StatelessWidget {
  final String? error;
  final Future<void> Function() onRetry;

  const _DailyCourseLoadFailure({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final bool english = context.l10n.isEnglish;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.cloud_off_rounded,
              color: Color(0xFFFFB44A),
              size: 54,
            ),
            const SizedBox(height: 14),
            Text(
              english
                  ? 'The daily course could not be loaded.'
                  : 'Günün parkuru yüklenemedi.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            if (error != null && error!.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                error!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(english ? 'Try Again' : 'Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyCourseUnavailablePage extends StatelessWidget {
  final String gameId;

  const _DailyCourseUnavailablePage({required this.gameId});

  @override
  Widget build(BuildContext context) {
    final bool english = context.l10n.isEnglish;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.extension_off_rounded,
                color: Color(0xFFFFB44A),
                size: 56,
              ),
              const SizedBox(height: 14),
              Text(
                english
                    ? 'This daily stage is not available.'
                    : 'Bu günlük parkur bölümü kullanılamıyor.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(gameId, style: const TextStyle(color: Colors.white54)),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => Navigator.pop(
                  context,
                  DailyStageResult.exited(gameId: gameId),
                ),
                icon: const Icon(Icons.arrow_back_rounded),
                label: Text(english ? 'Return to Route' : 'Rotaya Dön'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseHero extends StatelessWidget {
  final DailyCourseData data;
  final bool english;

  const _CourseHero({required this.data, required this.english});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF07577A), Color(0xFF303080), Color(0xFF6A246E)],
        ),
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: Colors.white24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x5500D9FF),
            blurRadius: 26,
            spreadRadius: -13,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24),
            ),
            child: Icon(
              data.allSuccessful
                  ? Icons.emoji_events_rounded
                  : data.allCompleted
                  ? Icons.flag_circle_rounded
                  : Icons.route_rounded,
              color: const Color(0xFFFFD334),
              size: 38,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.allCompleted
                      ? data.allSuccessful
                            ? english
                                  ? 'Perfect run!'
                                  : 'Kusursuz parkur!'
                            : english
                            ? 'Route complete'
                            : 'Rota tamamlandı'
                      : english
                      ? '${data.games.length} games, one daily run'
                      : '${data.games.length} oyun, tek günlük rota',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  data.allCompleted
                      ? english
                            ? '${data.totalStars} stars • ${data.totalScore} Brain Points'
                            : '${data.totalStars} yıldız • ${data.totalScore} Zeka Puanı'
                      : english
                      ? 'Finish the route and train ${data.games.length} different skills.'
                      : 'Rotayı bitir, ${data.games.length} farklı beceriyi çalıştır.',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseStepCard extends StatelessWidget {
  final int number;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final DailyStageOutcome? outcome;
  final bool current;

  const _CourseStepCard({
    required this.number,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.outcome,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final bool resolved = outcome != null;
    final Color statusColor;
    final IconData statusIcon;
    switch (outcome) {
      case DailyStageOutcome.completed:
        statusColor = const Color(0xFF52E86B);
        statusIcon = Icons.check_rounded;
      case DailyStageOutcome.failed:
        statusColor = const Color(0xFFFF6868);
        statusIcon = Icons.close_rounded;
      case DailyStageOutcome.skipped:
        statusColor = const Color(0xFFFFB44A);
        statusIcon = Icons.skip_next_rounded;
      case DailyStageOutcome.exited:
        statusColor = color;
        statusIcon = Icons.logout_rounded;
      case null:
        statusColor = current ? color : Colors.white24;
        statusIcon = icon;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: current
            ? color.withValues(alpha: 0.11)
            : ZpVisualPalette.of(context).surface,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: statusColor.withValues(
            alpha: resolved || current ? 0.65 : 0.30,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(statusIcon, color: statusColor, size: 28),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 29,
            height: 29,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _ResultStat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 23),
          const SizedBox(width: 7),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: Colors.white54, fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DailyCourseStageTransition extends StatefulWidget {
  final int completedCount;
  final int totalCount;
  final DailyStageOutcome outcome;
  final int stars;
  final int score;
  final String nextGameName;
  final bool english;

  const _DailyCourseStageTransition({
    required this.completedCount,
    required this.totalCount,
    required this.outcome,
    required this.stars,
    required this.score,
    required this.nextGameName,
    required this.english,
  });

  @override
  State<_DailyCourseStageTransition> createState() =>
      _DailyCourseStageTransitionState();
}

class _DailyCourseStageTransitionState
    extends State<_DailyCourseStageTransition> {
  Timer? _timer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 950), () => _close(true));
  }

  void _close(bool continueCourse) {
    if (!mounted || _closing) return;
    _closing = true;
    _timer?.cancel();
    Navigator.of(context).pop(continueCourse);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = switch (widget.outcome) {
      DailyStageOutcome.completed => const Color(0xFF6CFF9B),
      DailyStageOutcome.failed => const Color(0xFFFF6868),
      DailyStageOutcome.skipped => const Color(0xFFFFB44A),
      DailyStageOutcome.exited => const Color(0xFF7BEAFF),
    };
    final IconData statusIcon = switch (widget.outcome) {
      DailyStageOutcome.completed => Icons.check_circle_rounded,
      DailyStageOutcome.failed => Icons.heart_broken_rounded,
      DailyStageOutcome.skipped => Icons.skip_next_rounded,
      DailyStageOutcome.exited => Icons.logout_rounded,
    };
    final String title = switch (widget.outcome) {
      DailyStageOutcome.completed =>
        widget.english ? 'SECTION COMPLETE' : 'BÖLÜM TAMAMLANDI',
      DailyStageOutcome.failed =>
        widget.english ? 'LIVES EXHAUSTED' : 'CANLAR TÜKENDİ',
      DailyStageOutcome.skipped =>
        widget.english ? 'SECTION SKIPPED' : 'BÖLÜM GEÇİLDİ',
      DailyStageOutcome.exited =>
        widget.english ? 'COURSE PAUSED' : 'PARKUR DURAKLATILDI',
    };

    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, bool? result) {
        if (!didPop) _close(false);
      },
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          child: Center(
            child: Container(
              width: min(MediaQuery.sizeOf(context).width - 36, 430.0),
              margin: const EdgeInsets.all(18),
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Color(0xFF173B69), Color(0xFF31215D)],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: accent, width: 1.6),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: accent.withValues(alpha: 0.28),
                    blurRadius: 34,
                    spreadRadius: -8,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(statusIcon, color: accent, size: 58),
                  const SizedBox(height: 11),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    '${widget.completedCount}/${widget.totalCount}  •  '
                    '${widget.stars.clamp(0, 3)} ★  •  ${widget.score} ',
                    style: TextStyle(
                      color: accent,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 13),
                  Text(
                    widget.english
                        ? 'Next: ${widget.nextGameName}'
                        : 'Sırada: ${widget.nextGameName}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 13),
                  LinearProgressIndicator(
                    value: widget.completedCount / widget.totalCount,
                    minHeight: 7,
                    borderRadius: BorderRadius.circular(99),
                    color: accent,
                    backgroundColor: Colors.white12,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
