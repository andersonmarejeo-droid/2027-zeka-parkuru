import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/catalog/domain/studio_game_catalog.dart';
import '../../l10n/app_localizations.dart';
import '../../services/game_audio_service.dart';
import '../../theme/studio_visuals.dart';
import '../../widgets/realistic_game_object.dart';
import '../shared/game_audio_profile.dart';
import '../shared/parkur_game_kit.dart';
import '../shared/studio_game_contracts.dart';
import '../shared/studio_game_session.dart';
import '../shared/studio_game_skin.dart';
import 'card_pairs_scenario.dart';

abstract final class CardPairsGridLayout {
  /// Kartları kaydırma olmadan alana sığdıran en uygun sütun sayısı.
  /// Kart sayısı arttıkça sütun artar, kart boyutu kademeli küçülür.
  static int bestColumnsFor(
    int cardCount,
    double width,
    double height, {
    double gap = 6,
  }) {
    if (cardCount < 1) return 2;
    int best = 2;
    double bestSide = -1;
    final int minCols = cardCount >= 24 ? 4 : cardCount >= 14 ? 3 : 2;
    final int maxCols = cardCount >= 28 ? 6 : cardCount >= 16 ? 5 : 4;
    for (int columns = minCols; columns <= maxCols; columns++) {
      final int rows = (cardCount + columns - 1) ~/ columns;
      final double w = (width - gap * (columns - 1)) / columns;
      final double h = (height - gap * (rows - 1)) / rows;
      if (w <= 0 || h <= 0) continue;
      // Kartlar hafif dikey (genişlik : yükseklik = 1 : 1.15).
      final double side = math.min(w, h / 1.15);
      if (side > bestSide + 0.1) {
        bestSide = side;
        best = columns;
      }
    }
    return best;
  }

  static int columnsFor(int cardCount, double availableWidth) {
    if (cardCount < 1) return 2;
    if (availableWidth < 300 || cardCount < 6) return 2;
    if (availableWidth < 420) return cardCount >= 12 ? 4 : 3;
    if (availableWidth < 560) return cardCount >= 8 ? 4 : 3;
    return cardCount % 4 == 0 ? 4 : 3;
  }

  static double cardExtentFor(
    int cardCount,
    double availableWidth, {
    required double viewportHeight,
  }) {
    if (cardCount < 1) return 96;
    final int columns = columnsFor(cardCount, availableWidth);
    final int rows = (cardCount + columns - 1) ~/ columns;
    final double reservedHeight = viewportHeight < 460 ? 190 : 210;
    final double rowGaps = math.max(0, rows - 1).toDouble() * 8;
    final double fit = (viewportHeight - reservedHeight - rowGaps) / rows;
    return fit.clamp(68.0, 164.0).toDouble();
  }
}

class CardPairsGamePage extends StatefulWidget {
  const CardPairsGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  static const int totalLevels = GameContentPolicy.campaignLevels;
  static const int totalStars = totalLevels * 3;

  static final List<ParkurLevelSpec> levels = List<ParkurLevelSpec>.generate(
    GameContentPolicy.nativeStages('card_pairs'),
    (int index) {
      final int level = index + 1;
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Koleksiyon ${level.toString().padLeft(2, '0')}',
        titleEn: 'Collection ${level.toString().padLeft(2, '0')}',
        subtitleTr: switch (level) {
          <= 3 => 'Aynı görselin yerini ve eşini hatırla',
          <= 6 => 'Yüzey deseni değişse de şekli tanı',
          <= 10 => 'Farklı sembollerde ortak rengi izle',
          <= 16 => 'Anlamca bağlantılı kavramları eşleştir',
          <= 19 => 'Sekiz çift ve dört yanıltıcıyla odağını koru',
          _ => 'Usta finali • on çift ve altı tuzak kart',
        },
        subtitleEn: switch (level) {
          <= 3 => 'Remember the locations of identical images',
          <= 6 => 'Match the shape even when its surface changes',
          <= 10 => 'Track shared colors across different symbols',
          <= 16 => 'Match ideas that belong together by meaning',
          <= 19 => 'Keep focus across eight pairs and four decoys',
          _ => 'Master finale • ten pairs and six decoys',
        },
        difficulty: level <= 3
            ? 'GÖZLEM'
            : level <= 6
            ? 'ODAK'
            : level <= 10
            ? 'İLERİ'
            : level <= 16
            ? 'UZMAN'
            : 'USTA',
        icon: Icons.style_rounded,
      );
    },
    growable: false,
  );

  @override
  State<CardPairsGamePage> createState() => _CardPairsGamePageState();
}

class _CardPairsGamePageState extends State<CardPairsGamePage> {
  static const String _practiceKey = 'card_pairs_next_practice_round';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  bool _practiceLoading = true;
  int _nextPracticeRound = 1;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPracticeRound());
  }

  Future<void> _loadPracticeRound() async {
    final int stored = await _preferences.getInt(_practiceKey) ?? 1;
    if (!mounted) return;
    setState(() {
      _nextPracticeRound = stored
          .clamp(1, CardPairsScenario.uniquePracticeRounds)
          .toInt();
      _practiceLoading = false;
    });
  }

  Future<void> _openPractice() async {
    final bool english = context.l10n.isEnglish;
    final int round = _nextPracticeRound;
    final ParkurGameResult? result = await Navigator.of(context)
        .push<ParkurGameResult>(
          MaterialPageRoute<ParkurGameResult>(
            builder: (BuildContext context) => CardPairsPlayPage(
              level: CardPairsGamePage
                  .levels[(round - 1) % CardPairsGamePage.totalLevels],
              previousBestScore: 0,
              practiceRound: round,
            ),
          ),
        );
    if (!mounted || result?.completed != true) return;
    final int next = round == CardPairsScenario.uniquePracticeRounds
        ? 1
        : round + 1;
    await _preferences.setInt(_practiceKey, next);
    if (!mounted) return;
    setState(() => _nextPracticeRound = next);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          english
              ? 'Collection cleared • unique deck $next / 300'
              : 'Koleksiyon tamamlandı • farklı deste $next / 300',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forId('card_pairs');
    final bool english = context.l10n.isEnglish;
    return ParkurLevelHub(
      gameId: 'card_pairs',
      progressPrefix: 'card_pairs',
      titleTr: 'Kart Çifti',
      titleEn: 'Card Pairs',
      taglineTr: 'Kuralı çöz • konumları kodla • anlamlı eşleri bul',
      taglineEn: 'Read the rule • encode locations • find meaningful pairs',
      accent: skin.accent,
      icon: Icons.style_rounded,
      levels: CardPairsGamePage.levels,
      dailyCourseMode: widget.dailyCourseMode,
      competitionLevel: widget.competitionLevel,
      competitionLayoutCode: widget.competitionLayoutCode,
      hubAction: widget.competitionLevel != null
          ? null
          : OutlinedButton.icon(
              onPressed: _practiceLoading ? null : _openPractice,
              icon: const Icon(Icons.shuffle_rounded),
              label: Text(
                _practiceLoading
                    ? (english ? 'Loading…' : 'Yükleniyor…')
                    : english
                    ? 'UNIQUE DECK • $_nextPracticeRound / 300'
                    : 'FARKLI DESTE • $_nextPracticeRound / 300',
              ),
            ),
      playBuilder:
          (
            BuildContext context,
            ParkurLevelSpec level,
            int previousBestScore,
            int? competitionLayoutCode,
            bool competitionMode,
          ) => CardPairsPlayPage(
            level: level,
            previousBestScore: previousBestScore,
            practiceRound: competitionMode && competitionLayoutCode != null
                ? (competitionLayoutCode.abs() %
                          CardPairsScenario.uniquePracticeRounds) +
                      1
                : null,
          ),
    );
  }
}

class CardPairsPlayPage extends StatefulWidget {
  const CardPairsPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
    this.practiceRound,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;
  final int? practiceRound;

  @override
  State<CardPairsPlayPage> createState() => _CardPairsPlayPageState();
}

class _CardPairsPlayPageState extends State<CardPairsPlayPage> {
  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.memory,
  );
  late StudioGameSession _session;
  late CardPairsScenario _scenario;
  bool _initialized = false;
  bool _solved = false;
  bool _resolving = false;
  bool _hintUsed = false;
  final List<String> _revealed = <String>[];
  final Set<String> _matched = <String>{};
  String? _hintPair;
  String? _feedback;

  bool get _english => context.l10n.isEnglish;
  bool get _practice => widget.practiceRound != null;
  List<CardPairCard> get _selectedCards => <CardPairCard>[
    for (final String id in _revealed)
      _scenario.cards.firstWhere((CardPairCard card) => card.id == id),
  ];

  @override
  void initState() {
    super.initState();
    _session = StudioGameSession(
      level: widget.level.number,
      seed: widget.practiceRound ?? widget.level.number,
    )..start();
    unawaited(_audioProfile.preload(_audio));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final int? round = widget.practiceRound;
    _scenario = round == null
        ? (widget.level.poolIndex != null
              ? CardPairsScenario.forPracticeRound(
                  widget.level.contentIndex,
                  english: _english,
                )
              : CardPairsScenario.forCampaignLevel(
                  widget.level.contentLevel,
                  english: _english,
                ))
        : CardPairsScenario.forPracticeRound(round, english: _english);
  }

  void _tapCard(CardPairCard card) {
    if (_solved ||
        _resolving ||
        !_session.acceptsInput ||
        _revealed.contains(card.id) ||
        card.pairId != null && _matched.contains(card.pairId)) {
      return;
    }
    _revealed.add(card.id);
    _hintPair = null;
    _audio.hapticSelection();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .12),
    );
    if (_revealed.length < 2) {
      setState(() => _feedback = null);
      return;
    }
    final List<CardPairCard> chosen = _selectedCards;
    if (chosen[0].pairId != null && chosen[0].pairId == chosen[1].pairId) {
      _matched.add(chosen[0].pairId!);
      _revealed.clear();
      _session.recordAccepted(points: 90 + widget.level.number * 14);
      _audio.hapticMedium();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .32));
      _feedback = _scenario.rule == CardPairsRule.semanticLink
          ? _english
                ? 'Meaning link secured.'
                : 'Anlam bağı bulundu.'
          : _english
          ? 'Pair secured. Keep the rule in mind.'
          : 'Çift bulundu. Eşleşme kuralını aklında tut.';
      if (_matched.length == _scenario.pairCount) {
        setState(() {
          _solved = true;
          _feedback = _english
              ? 'Every relationship is in place.'
              : 'Bütün ilişkiler doğru yerde.';
        });
      } else {
        setState(() {});
      }
      return;
    }
    _resolving = true;
    setState(
      () => _feedback = _english
          ? 'Look closely, then encode both positions.'
          : 'Dikkatle bak, iki konumu da aklında tut.',
    );
    unawaited(_resolveMismatch());
  }

  Future<void> _resolveMismatch() async {
    await Future<void>.delayed(const Duration(milliseconds: 680));
    if (!mounted) return;
    _session.recordMistake();
    _audio.hapticLight();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .25));
    setState(() {
      _revealed.clear();
      _resolving = false;
      // Bu oyunda deneme sınırı yok: oyuncu istediği kadar deneyebilir.
      _feedback = _english
          ? 'Not a pair. Try again — attempts are unlimited.'
          : 'Bu kartlar eş değil. Tekrar dene, deneme sınırı yok.';
    });
  }

  void _showHint() {
    if (_solved || _resolving || !_session.useHint(pointCost: 90)) return;
    final String? pair = _scenario.cards
        .where(
          (CardPairCard card) =>
              card.pairId != null && !_matched.contains(card.pairId),
        )
        .map((CardPairCard card) => card.pairId!)
        .firstOrNull;
    if (pair == null) return;
    setState(() {
      _hintUsed = true;
      _hintPair = pair;
      _feedback = _english
          ? 'The amber edge marks the next pair.'
          : 'Kehribar çerçeve sıradaki çifti gösterir.';
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .25));
  }

  // ignore: unused_element
  void _reset() {
    setState(() {
      _revealed.clear();
      _matched.clear();
      _hintPair = null;
      _feedback = null;
      _solved = false;
      _resolving = false;
      _hintUsed = false;
      _session = StudioGameSession(
        level: widget.level.number,
        seed: widget.practiceRound ?? widget.level.number,
      )..start();
    });
  }

  void _finish() {
    if (!_solved || _session.phase != StudioGamePhase.playing) return;
    final int stars = !_hintUsed && _session.mistakes == 0
        ? 3
        : _session.mistakes <= 1
        ? 2
        : 1;
    final StudioGameResult result = _session.complete(
      stars: stars,
      action: !_practice && widget.level.number < CardPairsGamePage.totalLevels
          ? StudioResultAction.next
          : StudioResultAction.map,
    );
    unawaited(
      _audioProfile.play(
        _audio,
        GameAudioEvent.levelComplete,
        gain: .42,
        levelNumber: widget.level.number,
      ),
    );
    if (mounted) Navigator.of(context).pop(result.toParkurResult());
  }

  int _realisticIndexFor(String key) => switch (key) {
    'map' => 0,
    'compass' => 1,
    'lock' => 2,
    'key' => 3,
    'grain' => 4,
    'eco' => 5,
    'lens' => 6,
    'center_focus_strong' => 7,
    'public' => 8,
    'orbit' => 9,
    'schedule' => 10,
    'rotate_right' => 11,
    'waves' => 12,
    'beach_access' => 13,
    'menu_book' => 14,
    'bookmark' => 15,
    'music_note' => 0,
    'graphic_eq' => 1,
    'rainy' => 2,
    'umbrella' => 3,
    'brush' => 4,
    'palette' => 5,
    'coffee' => 6,
    'circle' => 7,
    'lightbulb' => 8,
    'wb_sunny' => 9,
    'landscape' => 10,
    'route' => 11,
    'mail' => 12,
    'forward_to_inbox' => 13,
    'radio_button_checked' => 14,
    'grid_3x3' => 15,
    'change_history' => 0,
    'hexagon' => 5,
    'diamond' => 3,
    'flare' => 2,
    'cloud' => 4,
    'star' => 8,
    'water_drop' => 7,
    'sailing' => 9,
    'park' => 10,
    'extension' => 11,
    'polyline' => 12,
    'pets' => 13,
    'pentagon' => 14,
    'ac_unit' => 15,
    'local_florist' => 5,
    'bolt' => 1,
    _ => 0,
  };

  Widget _card(
    CardPairCard card,
    List<Color> accents, {
    required double cardWidth,
    required double cardExtent,
  }) {
    final bool faceUp =
        _revealed.contains(card.id) ||
        card.pairId != null && _matched.contains(card.pairId);
    final bool matched = card.pairId != null && _matched.contains(card.pairId);
    final bool hinted = card.pairId != null && card.pairId == _hintPair;
    final Color accent = accents[card.colorIndex % accents.length];
    // Leave enough vertical room for the label on compact rows.  The grid
    // can legitimately make a card shorter than 76 px at later levels; a
    // hard 40 px artwork minimum would then make the face-up content taller
    // than the cell even though the back of the card still fits.
    final double radius = cardWidth < 65 ? 10.0 : cardWidth < 90 ? 14.0 : 18.0;
    final double artSize = math
        .min(cardWidth * .74, (cardExtent - (cardExtent < 75 ? 20 : cardExtent < 90 ? 26 : 28)) * .88)
        .clamp(cardExtent < 70 ? 22.0 : cardExtent < 90 ? 28.0 : 36.0, 108.0)
        .toDouble();
    return Semantics(
      label: faceUp ? card.label : (_english ? 'Hidden card' : 'Kapalı kart'),
      button: true,
      child: Material(
        color: StudioVisuals.surface,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          key: ValueKey<String>('card_pairs_card_${card.id}'),
          onTap: () => _tapCard(card),
          borderRadius: BorderRadius.circular(radius),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: faceUp
                ? EdgeInsets.zero
                : const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            decoration: BoxDecoration(
              color: StudioVisuals.surface,
              gradient: faceUp
                  ? null
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[Color(0xFFFFFEFA), Color(0xFFE9F3EF)],
                    ),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: matched
                    ? StudioVisuals.teal
                    : hinted
                    ? StudioVisuals.amber
                    : faceUp
                    ? accent.withValues(alpha: .4)
                    : const Color(0xFFD8E5E0),
                width: hinted || matched ? 2.2 : 1.2,
              ),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x24121F2A),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: faceUp
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(radius - 2),
                    child: Container(
                      key: ValueKey<String>('card_pairs_art_${card.id}'),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[
                            accent.withValues(alpha: .20),
                            accent.withValues(alpha: .08),
                          ],
                        ),
                      ),
                      child: Center(
                        child: RealisticGameObject(
                          sheet: RealisticObjectSheet.memory,
                          index: _realisticIndexFor(card.iconKey),
                          borderRadius: 16,
                        ),
                      ),
                    ),
                  )
                : Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Container(
                        key: ValueKey<String>('card_pairs_back_art_${card.id}'),
                        width: artSize,
                        height: artSize,
                        decoration: BoxDecoration(
                          color: StudioVisuals.tealSoft,
                          borderRadius: BorderRadius.circular(radius - 2),
                          border: Border.all(
                            color: StudioVisuals.teal.withValues(alpha: .2),
                          ),
                        ),
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          color: StudioVisuals.teal,
                          size: artSize * .57,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  void _showHowToPlay(BuildContext context, bool english) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: StudioVisuals.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: StudioVisuals.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(
                      Icons.style_rounded,
                      color: Color(0xFFD89A42),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      english ? 'How to Play' : 'Nasıl Oynanır?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: StudioVisuals.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _scenario.instruction,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                    color: StudioVisuals.ink,
                  ),
                ),
                if (_scenario.decoyCount > 0) ...[
                  const SizedBox(height: 10),
                  Text(
                    english
                        ? '⚠️ Beware of ${_scenario.decoyCount} decoy cards on the board that have no pair!'
                        : '⚠️ Dikkat: Tahtada çifti olmayan ${_scenario.decoyCount} adet tuzak kart bulunmaktadır!',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: StudioVisuals.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  english
                      ? '• Tap cards to reveal them and match identical or related pairs.\n• Keep errors below the limit to win maximum stars!'
                      : '• Kartlara dokunarak açın ve eşleşen çiftleri bulun.\n• Maksimum yıldız için hata limitini aşmadan tahtayı temizleyin!',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: StudioVisuals.muted,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD89A42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      english ? 'Got it' : 'Anladım',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forId('card_pairs');
    const List<Color> accents = <Color>[
      Color(0xFFD89A42),
      Color(0xFF5B88C8),
      Color(0xFF259C89),
      Color(0xFFC76E93),
      Color(0xFF7869C6),
      Color(0xFFD37A4D),
      Color(0xFF4E9AA0),
      Color(0xFFAD755E),
    ];
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 12,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _english ? 'Card Pairs' : 'Kart Çifti',
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
            Text(
              _practice
                  ? (_english
                        ? 'PRACTICE • ${widget.practiceRound} / 300'
                        : 'PRATİK • ${widget.practiceRound} / 300')
                  : (_english
                        ? 'COLLECTION • ${widget.level.number} / ${GameContentPolicy.campaignLevels}'
                        : 'KOLEKSİYON • ${widget.level.number} / ${GameContentPolicy.campaignLevels}'),
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: StudioVisuals.muted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: .45,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: _english ? 'How to play' : 'Nasıl Oynanır?',
            onPressed: () => _showHowToPlay(context, _english),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveGameFrame(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Column(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: StudioVisuals.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: StudioVisuals.line),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _scenario.ruleTitle,
                            maxLines: 1,
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              color: skin.accent,
                              fontSize: 10,
                              letterSpacing: 0.3,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _PairStat(
                        icon: Icons.layers_rounded,
                        value: '${_matched.length}/${_scenario.pairCount}',
                        accent: StudioVisuals.tealInk,
                      ),
                      const SizedBox(width: 6),
                      _PairStat(
                        icon: Icons.all_inclusive_rounded,
                        value: '${_session.mistakes}',
                        accent: skin.accent,
                      ),
                      const SizedBox(width: 6),
                      _PairStat(
                        icon: Icons.stars_rounded,
                        value: '${_session.score}',
                        accent: StudioVisuals.amber,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Container(
                    key: const ValueKey<String>('card_pairs_scroll'),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: skin.boardBackground,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: StudioVisuals.line),
                    ),
                    child: LayoutBuilder(
                      builder:
                          (
                            BuildContext context,
                            BoxConstraints gridConstraints,
                          ) {
                            final int cardCount = _scenario.cards.length;
                            final double gap = cardCount >= 16 ? 5.0 : 6.5;
                            final int columns = CardPairsGridLayout.bestColumnsFor(
                              cardCount,
                              gridConstraints.maxWidth,
                              gridConstraints.maxHeight,
                              gap: gap,
                            );
                            final int rows = (cardCount / columns).ceil();
                            final double fitWidth =
                                (gridConstraints.maxWidth -
                                    gap * (columns - 1)) /
                                columns;
                            final double fitHeight =
                                (gridConstraints.maxHeight - gap * (rows - 1)) /
                                rows;
                            // Kart hiçbir zaman gereğinden büyük olmaz;
                            // ilk bölümlerde de kompakt kalır.
                            final double cardWidth = math.min(
                              math.min(fitWidth, fitHeight / 1.15),
                              118,
                            );
                            final double extent = cardWidth * 1.15;
                            final double gridWidth =
                                cardWidth * columns + gap * (columns - 1);
                            final double gridHeight =
                                extent * rows + gap * (rows - 1);
                            return Center(
                              child: SizedBox(
                                width: gridWidth,
                                height: gridHeight,
                                child: GridView.builder(
                              key: const ValueKey<String>('card_pairs_grid'),
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemCount: cardCount,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    crossAxisSpacing: gap,
                                    mainAxisSpacing: gap,
                                    mainAxisExtent: extent,
                                  ),
                              itemBuilder: (BuildContext context, int index) =>
                                  _card(
                                    _scenario.cards[index],
                                    accents,
                                    cardWidth: cardWidth,
                                    cardExtent: extent,
                                  ),
                                ),
                              ),
                            );
                          },
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Sabit yükseklikli durum çubuğu: Kart seçimlerinde/eşleşmelerde
                // alanın açılıp kapanarak ekranın zıplamasını/sekmesini %100 önler.
                Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _solved
                        ? StudioVisuals.tealSoft
                        : _feedback != null
                        ? StudioVisuals.surface
                        : Colors.transparent,
                    borderRadius: StudioVisuals.compactRadius,
                    border: Border.all(
                      color: _solved
                          ? StudioVisuals.teal.withValues(alpha: .2)
                          : _feedback != null
                          ? StudioVisuals.line
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        _solved
                            ? Icons.check_circle_outline_rounded
                            : _feedback != null
                            ? Icons.info_outline_rounded
                            : Icons.touch_app_outlined,
                        size: 15,
                        color: _solved
                            ? StudioVisuals.teal
                            : _feedback != null
                            ? StudioVisuals.muted
                            : StudioVisuals.muted.withValues(alpha: .35),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _feedback ??
                              (_english
                                  ? (_revealed.isEmpty
                                      ? 'Choose the first card'
                                      : 'Now find its matching pair')
                                  : (_revealed.isEmpty
                                      ? 'Birinci kartı seç'
                                      : 'Şimdi eşini bul')),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            color: _solved
                                ? StudioVisuals.tealInk
                                : _feedback != null
                                ? StudioVisuals.ink
                                : StudioVisuals.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                if (_solved)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const ValueKey<String>('card_pairs_finish'),
                      onPressed: _finish,
                      icon: const Icon(Icons.celebration_rounded),
                      label: Text(
                        _english
                            ? 'COMPLETE COLLECTION'
                            : 'KOLEKSİYONU TAMAMLA',
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(48, 44),
                        backgroundColor: skin.accent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  )
                else
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const ValueKey<String>('card_pairs_hint'),
                          onPressed: _resolving ? null : _showHint,
                          icon: const Icon(
                            Icons.lightbulb_outline_rounded,
                            size: 18,
                          ),
                          label: Text(
                            _english ? 'HINT −90' : 'İPUCU −90',
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(48, 42),
                            foregroundColor: StudioVisuals.ink,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            textStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                            side: const BorderSide(color: StudioVisuals.line),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _english
                              ? 'Tap two cards. Pairs stay open.'
                              : 'İki karta dokun. Eşler açık kalır.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            color: StudioVisuals.muted,
                            fontSize: 11.5,
                            height: 1.15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PairStat extends StatelessWidget {
  const _PairStat({
    required this.icon,
    required this.value,
    required this.accent,
  });
  final IconData icon;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 60, minHeight: 30),
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      color: StudioVisuals.surface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: StudioVisuals.line),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(icon, size: 15, color: accent),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Roboto',
            color: StudioVisuals.ink,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}
