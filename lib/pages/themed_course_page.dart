import 'package:flutter/material.dart';

import '../games/attention_tunnel/attention_tunnel_game_page.dart';
import '../games/blocks/block_game_page.dart';
import '../games/card_pairs/card_pairs_game_page.dart';
import '../games/focus_filter/focus_filter_game_page.dart';
import '../games/hanoi/hanoi_game_page.dart';
import '../games/language_detective/language_detective_game_page.dart';
import '../games/letter_maze/letter_maze_game_page.dart';
import '../games/memory/memory_game_page.dart';
import '../games/meaning_match/meaning_match_game_page.dart';
import '../games/near_meaning/near_meaning_game_page.dart';
import '../games/number_sort/number_sort_game_page.dart';
import '../games/numbers/number_game_page.dart';
import '../games/picture_iq/picture_iq_game_page.dart';
import '../games/proverb_finish/proverb_finish_game_page.dart';
import '../games/reflex/reflex_game_page.dart';
import '../games/rhythm_memory/rhythm_memory_game_page.dart';
import '../games/sentence_builder/sentence_builder_game_page.dart';
import '../games/shape_puzzle/shape_puzzle_game_page.dart';
import '../games/story_order/story_order_game_page.dart';
import '../games/word_hunt/word_hunt_game_page.dart';
import '../games/candy_sort/candy_sort_game_page.dart';
import '../l10n/app_localizations.dart';
import '../services/daily_course_service.dart';
import '../services/game_audio_service.dart';
import '../services/themed_course_service.dart';
import '../theme/studio_visuals.dart';
import '../widgets/studio_card.dart';

enum _ThemedExitDecision { retry, skip, leave }

class ThemedCoursePage extends StatefulWidget {
  final ThemedCourseDefinition definition;

  const ThemedCoursePage({super.key, required this.definition});

  @override
  State<ThemedCoursePage> createState() => _ThemedCoursePageState();
}

class _ThemedCoursePageState extends State<ThemedCoursePage> {
  final ThemedCourseService _course = ThemedCourseService.instance;
  final GameAudioService _audio = GameAudioService.instance;

  ThemedCourseData? _data;
  bool _loading = true;
  bool _running = false;
  String? _loadError;

  ThemedCourseDefinition get definition => widget.definition;

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
      final ThemedCourseData data = await _course.load(definition.id);
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Themed course load failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _data = null;
        _loading = false;
        _loadError = '$error';
      });
    }
  }

  Future<void> _startNewRoundAndRun() async {
    if (_running) return;
    final ThemedCourseData? data = _data;
    if (data?.allCompleted == true) {
      await _course.startNewRound(definition.id);
      await _load();
    }
    if (mounted) await _startOrResume();
  }

  Future<void> _startOrResume() async {
    if (_running) return;
    setState(() => _running = true);
    bool replayRequested = false;

    try {
      await _audio.play(GameSound.uiClick);
      if (!mounted) return;

      while (mounted) {
        final ThemedCourseData current = await _course.load(definition.id);
        if (!mounted) return;
        setState(() => _data = current);

        final String? gameId = current.nextGameId;
        if (gameId == null) {
          replayRequested = await _showCompletion(current);
          break;
        }

        final int competitionLevel = _course.levelFor(
          courseId: definition.id,
          gameId: gameId,
          round: current.round,
        );
        final int layoutCode = _course.layoutCodeFor(
          courseId: definition.id,
          gameId: gameId,
          round: current.round,
        );

        DailyStageResult? result = await _openStage(
          gameId: gameId,
          competitionLevel: competitionLevel,
          layoutCode: layoutCode,
        );
        if (!mounted) return;

        if (result == null || result.outcome == DailyStageOutcome.exited) {
          final _ThemedExitDecision decision = await _showExitDecision(gameId);
          if (!mounted) return;
          switch (decision) {
            case _ThemedExitDecision.retry:
              continue;
            case _ThemedExitDecision.skip:
              result = DailyStageResult.skipped(gameId: gameId);
            case _ThemedExitDecision.leave:
              await _load();
              return;
          }
        }

        if (result.gameId != gameId) {
          throw StateError(
            'Tematik parkur sonucu yanlış oyundan döndü: '
            '${result.gameId} != $gameId',
          );
        }

        final ThemedCourseData updated = await _course.recordStageResult(
          courseId: definition.id,
          result: result,
        );
        if (!mounted) return;
        setState(() => _data = updated);

        if (updated.allCompleted) {
          await _audio.play(GameSound.levelComplete);
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
      debugPrint('Themed course run failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Tematik parkur güvenli şekilde durduruldu. İlerlemen korundu.',
              ),
            ),
          );
        await _load();
      }
    } finally {
      if (mounted) setState(() => _running = false);
    }

    if (replayRequested && mounted) {
      await _course.startNewRound(definition.id);
      await _load();
      if (mounted) await _startOrResume();
    }
  }

  Future<DailyStageResult?> _openStage({
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

  Future<_ThemedExitDecision> _showExitDecision(String gameId) async {
    if (!mounted) return _ThemedExitDecision.leave;
    final bool english = context.l10n.isEnglish;
    final String gameName = _gameName(gameId, english);
    return await showModalBottomSheet<_ThemedExitDecision>(
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
                      colors: [StudioVisuals.surface, StudioVisuals.tealSoft],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    border: Border.all(color: StudioVisuals.line),
                    boxShadow: StudioVisuals.softShadow,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.save_alt_rounded,
                        color: StudioVisuals.teal,
                        size: 40,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        english
                            ? 'LEAVE THIS CIRCUIT?'
                            : 'BU PARKURDAN ÇIKILSIN MI?',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: StudioVisuals.ink,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        english
                            ? '$gameName is not resolved. Your place will be kept.'
                            : '$gameName henüz sonuçlanmadı. Kaldığın yer korunacak.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: StudioVisuals.muted,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: () => Navigator.pop(
                          sheetContext,
                          _ThemedExitDecision.retry,
                        ),
                        icon: const Icon(Icons.replay_rounded),
                        label: Text(
                          english ? 'RETURN TO GAME' : 'OYUNA DÖN',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(height: 9),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.pop(
                          sheetContext,
                          _ThemedExitDecision.skip,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: StudioVisuals.amber,
                          side: const BorderSide(color: StudioVisuals.amber),
                        ),
                        icon: const Icon(Icons.skip_next_rounded),
                        label: Text(
                          english ? 'SKIP THIS SECTION' : 'BU BÖLÜMÜ GEÇ',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => Navigator.pop(
                          sheetContext,
                          _ThemedExitDecision.leave,
                        ),
                        icon: const Icon(Icons.exit_to_app_rounded),
                        style: TextButton.styleFrom(
                          foregroundColor: StudioVisuals.muted,
                        ),
                        label: Text(
                          english ? 'LEAVE THE CIRCUIT' : 'PARKURDAN ÇIK',
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
        _ThemedExitDecision.leave;
  }

  Future<bool> _showStageTransition({
    required int completedCount,
    required int totalCount,
    required DailyStageResult result,
    required String? nextGameId,
  }) async {
    if (!mounted) return false;
    final bool english = context.l10n.isEnglish;
    final String nextName = nextGameId == null
        ? ''
        : _gameName(nextGameId, english);
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            final bool success = result.outcome == DailyStageOutcome.completed;
            return AlertDialog(
              backgroundColor: StudioVisuals.surface,
              title: Row(
                children: [
                  Icon(
                    success
                        ? Icons.check_circle_rounded
                        : Icons.flag_circle_rounded,
                    color: success ? StudioVisuals.teal : StudioVisuals.amber,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$completedCount / $totalCount',
                      style: const TextStyle(
                        color: StudioVisuals.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              content: Text(
                nextName.isEmpty
                    ? (english ? 'Circuit complete.' : 'Parkur tamamlandı.')
                    : (english
                          ? 'Next: $nextName'
                          : 'Sıradaki: $nextName'),
                style: const TextStyle(
                  color: StudioVisuals.muted,
                  height: 1.4,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(english ? 'PAUSE' : 'BEKLET'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: Text(english ? 'CONTINUE' : 'DEVAM ET'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<bool> _showCompletion(ThemedCourseData data) async {
    if (!mounted) return false;
    final bool english = context.l10n.isEnglish;
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              backgroundColor: StudioVisuals.surface,
              title: Text(
                english ? 'CIRCUIT COMPLETE' : 'PARKUR TAMAMLANDI',
                style: const TextStyle(
                  color: StudioVisuals.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: Text(
                english
                    ? '${data.totalStars} stars • ${data.totalScore} Brain Points\nStart another round with a new difficulty layout.'
                    : '${data.totalStars} yıldız • ${data.totalScore} Zeka Puanı\nYeni zorluk düzeniyle bir tur daha başlatabilirsin.',
                style: const TextStyle(
                  color: StudioVisuals.muted,
                  height: 1.45,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(english ? 'CLOSE' : 'KAPAT'),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  icon: const Icon(Icons.replay_rounded),
                  label: Text(english ? 'NEW ROUND' : 'YENİ TUR'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Widget _pageFor(String gameId, int competitionLevel, int layoutCode) {
    switch (gameId) {
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
      case 'card_pairs':
        return CardPairsGamePage(
          dailyCourseMode: true,
          competitionLevel: competitionLevel,
          competitionLayoutCode: layoutCode,
        );
      case 'focus_filter':
        return FocusFilterGamePage(
          dailyCourseMode: true,
          competitionLevel: competitionLevel,
          competitionLayoutCode: layoutCode,
        );
      case 'rhythm_memory':
        return RhythmMemoryGamePage(
          dailyCourseMode: true,
          competitionLevel: competitionLevel,
          competitionLayoutCode: layoutCode,
        );
      case 'attention_tunnel':
        return AttentionTunnelGamePage(
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
      case 'candy_sort':
        return CandySortGamePage(
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
      case 'meaning_match':
        return MeaningMatchGamePage(
          dailyCourseMode: true,
          competitionLevel: competitionLevel,
          competitionLayoutCode: layoutCode,
        );
      case 'proverb_finish':
        return ProverbFinishGamePage(
          dailyCourseMode: true,
          competitionLevel: competitionLevel,
          competitionLayoutCode: layoutCode,
        );
      case 'sentence_builder':
        return SentenceBuilderGamePage(
          dailyCourseMode: true,
          competitionLevel: competitionLevel,
          competitionLayoutCode: layoutCode,
        );
      case 'near_meaning':
        return NearMeaningGamePage(
          dailyCourseMode: true,
          competitionLevel: competitionLevel,
          competitionLayoutCode: layoutCode,
        );
      case 'letter_maze':
        return LetterMazeGamePage(
          dailyCourseMode: true,
          competitionLevel: competitionLevel,
          competitionLayoutCode: layoutCode,
        );
      case 'language_detective':
        return LanguageDetectiveGamePage(
          dailyCourseMode: true,
          competitionLevel: competitionLevel,
          competitionLayoutCode: layoutCode,
        );
      case 'story_order':
        return StoryOrderGamePage(
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
        return _UnavailableThemedGame(gameId: gameId);
    }
  }

  String _gameName(String gameId, bool english) {
    switch (gameId) {
      case 'numbers':
        return english ? 'Number Arena' : 'Sayı Arenası';
      case 'blocks':
        return english ? 'Block Mind' : 'Blok Zekâ';
      case 'memory':
        return english ? 'Memory Master' : 'Hafıza Ustası';
      case 'card_pairs':
        return english ? 'Card Pairs' : 'Kart Çifti';
      case 'focus_filter':
        return english ? 'Focus Filter' : 'Odak Filtresi';
      case 'rhythm_memory':
        return english ? 'Rhythm Memory' : 'Ritim Hafızası';
      case 'attention_tunnel':
        return english ? 'Attention Tunnel' : 'Dikkat Tüneli';
      case 'hanoi':
        return english ? 'Tower of Hanoi' : 'Hanoi Kulesi';
      case 'candy_sort':
        return english ? 'Candy Sort' : 'Şeker Sıralama';
      case 'word_hunt':
        return english ? 'Word Hunt' : 'Kelime Avı';
      case 'meaning_match':
        return english ? 'Meaning Match' : 'Anlam Eşleştir';
      case 'proverb_finish':
        return english ? 'Finish the Proverb' : 'Atasözü Tamamla';
      case 'sentence_builder':
        return english ? 'Sentence Builder' : 'Cümle Kur';
      case 'near_meaning':
        return english ? 'Near Meaning' : 'Yakın Anlam';
      case 'letter_maze':
        return english ? 'Letter Maze' : 'Harf Labirenti';
      case 'language_detective':
        return english ? 'Language Detective' : 'Dil Dedektifi';
      case 'story_order':
        return english ? 'Story Order' : 'Hikâye Sırası';
      case 'picture_iq':
        return english ? 'Visual IQ' : 'Görsel IQ';
      case 'number_sort':
        return english ? '15-Tile Master' : '15 Taş Ustası';
      case 'shape_puzzle':
        return english ? 'Shape Merge' : 'Şekil Birleştir';
      case 'reflex':
        return english ? 'Reflex Hunt' : 'Refleks Avı';
      default:
        return english ? 'Game' : 'Oyun';
    }
  }

  IconData _gameIcon(String gameId) {
    switch (gameId) {
      case 'numbers':
        return Icons.calculate_rounded;
      case 'blocks':
        return Icons.view_in_ar_rounded;
      case 'memory':
        return Icons.grid_view_rounded;
      case 'card_pairs':
        return Icons.style_rounded;
      case 'focus_filter':
        return Icons.filter_center_focus_rounded;
      case 'rhythm_memory':
        return Icons.graphic_eq_rounded;
      case 'attention_tunnel':
        return Icons.blur_on_rounded;
      case 'hanoi':
        return Icons.account_balance_rounded;
      case 'candy_sort':
        return Icons.cookie_rounded;
      case 'word_hunt':
        return Icons.travel_explore_rounded;
      case 'meaning_match':
        return Icons.hub_rounded;
      case 'proverb_finish':
        return Icons.menu_book_rounded;
      case 'sentence_builder':
        return Icons.format_align_left_rounded;
      case 'near_meaning':
        return Icons.manage_search_rounded;
      case 'letter_maze':
        return Icons.route_rounded;
      case 'language_detective':
        return Icons.manage_search_rounded;
      case 'story_order':
        return Icons.timeline_rounded;
      case 'picture_iq':
        return Icons.auto_awesome_mosaic_rounded;
      case 'number_sort':
        return Icons.grid_4x4_rounded;
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
      case 'numbers':
      case 'memory':
      case 'card_pairs':
      case 'rhythm_memory':
      case 'attention_tunnel':
        return StudioVisuals.teal;
      case 'blocks':
      case 'number_sort':
      case 'hanoi':
        return StudioVisuals.amber;
      case 'reflex':
      case 'focus_filter':
        return StudioVisuals.danger;
      default:
        return StudioVisuals.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemedCourseData? data = _data;
    final bool english = context.l10n.isEnglish;

    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.l10n.gameTitle(definition.id),
          style: const TextStyle(
            color: StudioVisuals.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: StudioPageFrame(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : data == null
            ? _ErrorState(message: _loadError ?? 'Parkur yüklenemedi.')
            : RefreshIndicator(
                color: StudioVisuals.teal,
                backgroundColor: StudioVisuals.surface,
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    StudioVisuals.pageGutter,
                    12,
                    StudioVisuals.pageGutter,
                    30,
                  ),
                  children: [
                    _ThemedCourseHero(
                      data: data,
                      english: english,
                      accent: _courseAccent(definition.id),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      english ? 'CIRCUIT STEPS' : 'PARKUR ADIMLARI',
                      style: const TextStyle(
                        color: StudioVisuals.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...List<Widget>.generate(data.games.length, (int index) {
                      final String gameId = data.games[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ThemedStepCard(
                          number: index + 1,
                          title: _gameName(gameId, english),
                          icon: _gameIcon(gameId),
                          color: _gameColor(gameId),
                          completed: data.isCompleted(gameId),
                          current: data.nextGameId == gameId,
                          outcome: data.outcomeFor(gameId),
                        ),
                      );
                    }),
                    const SizedBox(height: 7),
                    SafeArea(
                      top: false,
                      child: FilledButton.icon(
                        onPressed: _running ? null : _startNewRoundAndRun,
                        style: FilledButton.styleFrom(
                          backgroundColor: _courseAccent(definition.id),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: Icon(
                          data.allCompleted
                              ? Icons.replay_rounded
                              : data.completedCount > 0
                              ? Icons.play_arrow_rounded
                              : Icons.route_rounded,
                        ),
                        label: Text(
                          data.allCompleted
                              ? (english ? 'NEW ROUND' : 'YENİ TUR')
                              : data.completedCount > 0
                              ? (english ? 'CONTINUE CIRCUIT' : 'PARKURA DEVAM ET')
                              : (english ? 'START CIRCUIT' : 'PARKURU BAŞLAT'),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Color _courseAccent(String id) {
    switch (id) {
      case 'star_hunt':
        return StudioVisuals.amber;
      case 'mind_gym':
        return StudioVisuals.teal;
      case 'high_iq':
        return const Color(0xFF665AA2);
      case 'word_labyrinth':
        return const Color(0xFF3D7183);
      case 'speed_precision':
        return StudioVisuals.danger;
      default:
        return StudioVisuals.teal;
    }
  }
}

class _ThemedCourseHero extends StatelessWidget {
  final ThemedCourseData data;
  final bool english;
  final Color accent;

  const _ThemedCourseHero({
    required this.data,
    required this.english,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final ThemedCourseDefinition definition = data.definition;
    final double progress = data.games.isEmpty
        ? 0
        : data.completedCount / data.games.length;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: StudioVisuals.surface,
        borderRadius: StudioVisuals.cardRadius,
        border: Border.all(color: accent.withValues(alpha: 0.28)),
        boxShadow: StudioVisuals.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  data.allCompleted
                      ? Icons.workspace_premium_rounded
                      : Icons.route_rounded,
                  color: accent,
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.gameTitle(definition.id),
                      style: const TextStyle(
                        color: StudioVisuals.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      definition.subtitle(english: english),
                      style: TextStyle(
                        color: accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'TUR ${data.round}',
                style: TextStyle(
                  color: accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            definition.description(english: english),
            style: const TextStyle(
              color: StudioVisuals.muted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroChip(
                icon: Icons.extension_rounded,
                label: '${data.games.length} ${english ? 'games' : 'oyun'}',
                color: accent,
              ),
              _HeroChip(
                icon: Icons.signal_cellular_alt_rounded,
                label: english
                    ? 'Levels ${definition.minLevel}-${definition.maxLevel}'
                    : 'Seviye ${definition.minLevel}-${definition.maxLevel}',
                color: accent,
              ),
              _HeroChip(
                icon: Icons.star_rounded,
                label: '${data.totalStars} ⭐',
                color: StudioVisuals.amber,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: StudioVisuals.surfaceSoft,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            '${data.completedCount}/${data.games.length} ${english ? 'steps complete' : 'adım tamamlandı'}',
            style: const TextStyle(
              color: StudioVisuals.muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _HeroChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemedStepCard extends StatelessWidget {
  final int number;
  final String title;
  final IconData icon;
  final Color color;
  final bool completed;
  final bool current;
  final DailyStageOutcome? outcome;

  const _ThemedStepCard({
    required this.number,
    required this.title,
    required this.icon,
    required this.color,
    required this.completed,
    required this.current,
    required this.outcome,
  });

  @override
  Widget build(BuildContext context) {
    final bool success = outcome == DailyStageOutcome.completed;
    final Color stateColor = completed
        ? success
              ? StudioVisuals.teal
              : StudioVisuals.amber
        : current
        ? color
        : StudioVisuals.muted;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StudioVisuals.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: stateColor.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: stateColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Center(
              child: completed
                  ? Icon(
                      success
                          ? Icons.check_rounded
                          : Icons.skip_next_rounded,
                      color: stateColor,
                      size: 23,
                    )
                  : Text(
                      '$number',
                      style: TextStyle(
                        color: stateColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: StudioVisuals.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  completed
                      ? success
                            ? 'Tamamlandı'
                            : 'Geçildi'
                      : current
                      ? 'Sıradaki bölüm'
                      : 'Kilitli bölüm',
                  style: TextStyle(
                    color: stateColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            completed ? Icons.done_all_rounded : icon,
            color: stateColor,
            size: 24,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: StudioVisuals.muted),
        ),
      ),
    );
  }
}

class _UnavailableThemedGame extends StatelessWidget {
  final String gameId;

  const _UnavailableThemedGame({required this.gameId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Oyun')),
      body: Center(child: Text('Oyun kullanılamıyor: $gameId')),
    );
  }
}
