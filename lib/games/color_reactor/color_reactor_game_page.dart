import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/catalog/domain/studio_game_catalog.dart';
import '../../l10n/app_localizations.dart';
import '../../services/game_audio_service.dart';
import '../../theme/studio_visuals.dart';
import '../shared/game_audio_profile.dart';
import '../shared/parkur_game_kit.dart';
import '../shared/studio_game_session.dart';
import '../shared/studio_game_skin.dart';
import 'color_reactor_scenario.dart';

class ColorReactorGamePage extends StatelessWidget {
  const ColorReactorGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  static const int totalCases = ReactorScenario.maximumLevels;
  static const int totalStars = totalCases * 3;

  static final List<ParkurLevelSpec>
  _levels = List<ParkurLevelSpec>.generate(totalCases, (int index) {
    final int level = index + 1;
    final String tr = switch (level) {
      <= 3 => 'Darbe yaklaşırken doğru çıkış kanalını seç.',
      <= 6 => 'İki ve üç kanallı renk dizisini sırayla yönlendir.',
      7 || 8 => 'İleri: hızlanan akışta hedef biçimi ve kanalı birlikte izle.',
      9 => 'Uzman: sıkı aralıklarla gelen darbelerde iki hatayı aşma.',
      _ => 'Usta finali: üç kanalı değişken ritimde kusursuz senkronla.',
    };
    final String en = switch (level) {
      <= 3 => 'Choose the correct output as each pulse nears the valve.',
      <= 6 => 'Route the two- and three-channel color sequence in order.',
      7 ||
      8 => 'Advanced: track the target shape and channel as flow speeds up.',
      9 => 'Expert: stay within two mistakes as pulses arrive closer together.',
      _ => 'Master finale: synchronise all three channels at a changing tempo.',
    };
    return ParkurLevelSpec(
      number: level,
      titleTr: 'Reaktör Dizisi ${level.toString().padLeft(2, '0')}',
      titleEn: 'Reactor Sequence ${level.toString().padLeft(2, '0')}',
      subtitleTr: tr,
      subtitleEn: en,
      difficulty: switch (level) {
        <= 6 => level <= 3 ? 'USTALAŞMA' : 'DERİNLEŞME',
        7 || 8 => 'İLERİ',
        9 => 'UZMAN',
        _ => 'USTA',
      },
      icon: Icons.bubble_chart_rounded,
    );
  }, growable: false);

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.fun);
    return ParkurLevelHub(
      gameId: 'color_match',
      progressPrefix: 'color_match',
      titleTr: 'Renk Reaktörü',
      titleEn: 'Color Reactor',
      taglineTr: 'Darbeyi oku • Vanayı seç • Akışı eşleştir',
      taglineEn: 'Read the pulse • Set the valve • Route the flow',
      accent: skin.accent,
      icon: Icons.bubble_chart_rounded,
      levels: _levels,
      dailyCourseMode: dailyCourseMode,
      competitionLevel: competitionLevel,
      competitionLayoutCode: competitionLayoutCode,
      playBuilder:
          (
            BuildContext context,
            ParkurLevelSpec level,
            int previousBestScore,
            int? competitionLayoutCode,
            bool competitionMode,
          ) => ColorReactorPlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class _ReactorFlight {
  _ReactorFlight(this.id, this.spec);

  final int id;
  final ReactorPulseSpec spec;
  double age = 0;
  double x = -.08;
  double y = 0;
  bool routed = false;
  int route = 0;
  bool resolved = false;
}

class ColorReactorPlayPage extends StatefulWidget {
  const ColorReactorPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<ColorReactorPlayPage> createState() => _ColorReactorPlayPageState();
}

class _ColorReactorPlayPageState extends State<ColorReactorPlayPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const Color _ink = Color(0xFF25404A);
  static const Color _accent = Color(0xFF318C82);
  static const List<Color> _channels = <Color>[
    Color(0xFF57C6B2),
    Color(0xFFFF907B),
    Color(0xFFF0BF66),
  ];
  static const List<IconData> _channelShapes = <IconData>[
    Icons.change_history_rounded,
    Icons.diamond_outlined,
    Icons.circle_outlined,
  ];

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.fun,
  );
  final List<_ReactorFlight> _flights = <_ReactorFlight>[];
  late final Ticker _ticker;
  late ReactorScenario _scenario;
  late StudioGameSession _session;
  Duration _lastTick = Duration.zero;
  double _elapsed = 0;
  int _spawnCursor = 0;
  int _selectedChannel = 0;
  int _routed = 0;
  int _mistakes = 0;
  int _integrity = 3;
  int _score = 0;
  bool _ready = false;
  bool _paused = false;
  bool _finished = false;
  bool _english = false;

  int get _stars {
    if (_mistakes == 0 && _routed == _scenario.pulses.length) return 3;
    if (_mistakes <= 1 && _routed >= _scenario.requiredHits) return 2;
    return 1;
  }

  int? get _promptChannel {
    for (final _ReactorFlight flight in _flights) {
      if (!flight.routed && !flight.resolved) return flight.spec.destination;
    }
    if (_spawnCursor < _scenario.pulses.length) {
      return _scenario.pulses[_spawnCursor].destination;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_tick);
    unawaited(_audioProfile.preload(_audio));
    unawaited(_prepareScenario());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (_ready && !_paused && !_finished) _setPaused(true);
    } else if (state == AppLifecycleState.resumed && _paused && !_finished) {
      _setPaused(false);
    }
  }

  Future<void> _prepareScenario() async {
    ReactorScenario scenario = ReactorScenario.forLevel(widget.level.number);
    try {
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      final String visitKey = 'color_match_level_${widget.level.number}_visits';
      final int visits = await preferences.getInt(visitKey) ?? 0;
      if (visits > 0) {
        final int index =
            await preferences.getInt('color_match_practice_index') ?? 0;
        if (index < ReactorScenario.maximumPracticeRounds) {
          final int next = index + 1;
          await preferences.setInt('color_match_practice_index', next);
          scenario = ReactorScenario.forPracticeRound(next);
        }
      }
      await preferences.setInt(visitKey, visits + 1);
    } catch (_) {
      scenario = ReactorScenario.forLevel(widget.level.number);
    }
    if (!mounted) return;
    _scenario = scenario;
    _startRound();
    setState(() => _ready = true);
  }

  void _startRound() {
    _ticker.stop();
    _lastTick = Duration.zero;
    _elapsed = 0;
    _spawnCursor = 0;
    _selectedChannel = 0;
    _routed = 0;
    _mistakes = 0;
    _integrity = 3;
    _score = 0;
    _flights.clear();
    _paused = false;
    _finished = false;
    _session = StudioGameSession(
      level: widget.level.number,
      seed: _scenario.seed,
    )..start();
    _ticker.start();
  }

  void _setPaused(bool paused) {
    if (!_ready || _finished) return;
    setState(() => _paused = paused);
    if (paused) {
      _session.pause();
      _ticker.stop();
      unawaited(_audio.play(GameSound.uiClick, gain: .25));
    } else {
      _session.resume();
      _lastTick = Duration.zero;
      _ticker.start();
      unawaited(_audio.play(GameSound.uiClick, gain: .25));
    }
  }

  void _selectChannel(int channel) {
    if (!_ready || _paused || _finished || channel >= _scenario.channelCount) {
      return;
    }
    setState(() => _selectedChannel = channel);
    _audio.hapticSelection();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .22),
    );
  }

  void _tick(Duration elapsed) {
    if (!_ready || _paused || _finished) return;
    final double raw = (elapsed - _lastTick).inMicroseconds / 1000000;
    _lastTick = elapsed;
    if (raw <= 0) return;
    final double delta = raw.clamp(0, .04).toDouble();
    _elapsed += delta;
    while (_spawnCursor < _scenario.pulses.length &&
        _elapsed >= _scenario.pulses[_spawnCursor].spawnAt) {
      _flights.add(
        _ReactorFlight(_spawnCursor, _scenario.pulses[_spawnCursor]),
      );
      _spawnCursor++;
    }
    for (final _ReactorFlight flight in _flights) {
      if (flight.resolved) continue;
      flight.age += delta;
      flight.x = -.08 + flight.age * flight.spec.speed;
      if (!flight.routed && flight.x >= .50) {
        flight.routed = true;
        flight.route = _selectedChannel;
        if (flight.route == flight.spec.destination) {
          _routed++;
          final int points = 180 + math.min(_integrity, 3) * 32;
          _score += points;
          _session.recordAccepted(points: points);
          unawaited(
            _audioProfile.play(_audio, GameAudioEvent.accepted, gain: .29),
          );
          _audio.hapticLight();
        } else {
          _mistakes++;
          _integrity--;
          _session.recordMistake();
          unawaited(
            _audioProfile.play(_audio, GameAudioEvent.rejected, gain: .42),
          );
          _audio.hapticHeavy();
        }
      }
      final double routeProgress = ((flight.x - .50) / .44)
          .clamp(0, 1)
          .toDouble();
      flight.y =
          _laneY(flight.spec.inputLane) +
          (_laneY(flight.route) - _laneY(flight.spec.inputLane)) *
              _ease(routeProgress);
      if (flight.x > 1.03) flight.resolved = true;
    }
    _flights.removeWhere((_ReactorFlight flight) => flight.resolved);

    if (_integrity <= 0) {
      unawaited(_finish(completed: false));
    } else if (_spawnCursor >= _scenario.pulses.length && _flights.isEmpty) {
      unawaited(_finish(completed: _routed >= _scenario.requiredHits));
    }
    if (mounted && !_finished) setState(() {});
  }

  static double _laneY(int lane) => const <double>[.31, .50, .69][lane];

  static double _ease(double value) => value * value * (3 - 2 * value);

  Future<void> _finish({required bool completed}) async {
    if (_finished || !mounted) return;
    _finished = true;
    _ticker.stop();
    if (!completed) {
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .36));
      final bool retry =
          await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) => AlertDialog(
              title: Text(
                _english ? 'Reactor overloaded' : 'Reaktör aşırı yüklendi',
              ),
              content: Text(
                _english
                    ? '$_routed of ${_scenario.requiredHits} pulses routed. Recalibrate and try again?'
                    : '${_scenario.requiredHits} hedeften $_routed darbe yönlendirildi. Kalibrasyonu yenileyip tekrar dener misin?',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(_english ? 'Level map' : 'Bölüm listesi'),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: Text(_english ? 'Retry' : 'Tekrar dene'),
                ),
              ],
            ),
          ) ??
          false;
      if (!mounted) return;
      if (retry) {
        setState(_startRound);
      } else {
        Navigator.of(context)
            .pop(StudioGameResult.failed(score: _score).toParkurResult());
      }
      return;
    }

    _session.complete(
      stars: _stars,
      action: widget.level.number < ColorReactorGamePage.totalCases
          ? StudioResultAction.next
          : StudioResultAction.map,
    );
    unawaited(_audioProfile.play(
      _audio,
      GameAudioEvent.levelComplete,
      levelNumber: widget.level.number,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 170));
    if (!mounted) return;
    final ParkurResultAction? result = await showParkurResultDialog(
      context: context,
      accent: _accent,
      titleTr: 'REAKTÖR DİZİSİ TAMAMLANDI',
      titleEn: 'REACTOR SEQUENCE COMPLETE',
      detailTr: '$_routed doğru akış · $_mistakes hata.',
      detailEn: '$_routed clean routes · $_mistakes errors.',
      stars: _stars,
      score: _score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < ColorReactorGamePage.totalCases,
    );
    if (!mounted) return;
    final StudioResultAction action = switch (result) {
      ParkurResultAction.replay => StudioResultAction.replay,
      ParkurResultAction.next => StudioResultAction.next,
      _ => StudioResultAction.map,
    };
    Navigator.of(context).pop(
      StudioGameResult.completed(
        score: _score,
        stars: _stars,
        action: action,
      ).toParkurResult(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _english = context.l10n.isEnglish;
    if (!_ready) {
      return Scaffold(
        backgroundColor: StudioVisuals.canvas,
        appBar: AppBar(
          backgroundColor: StudioVisuals.canvas,
          title: Text(_english ? 'COLOR REACTOR' : 'RENK REAKTÖRÜ'),
        ),
        body: const Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: _ink,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _english ? 'COLOR REACTOR' : 'RENK REAKTÖRÜ',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('reactor_pause'),
            tooltip: _paused
                ? (_english ? 'Resume' : 'Devam et')
                : (_english ? 'Pause' : 'Duraklat'),
            onPressed: () => _setPaused(!_paused),
            icon: Icon(
              _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              child: Column(
                children: <Widget>[
                  _ReactorHud(
                    routed: _routed,
                    requiredHits: _scenario.requiredHits,
                    integrity: _integrity,
                    targetChannel: _promptChannel ?? 0,
                    english: _english,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints limits) {
                        final double height = math.min(
                          limits.maxHeight,
                          limits.maxWidth * 1.08,
                        );
                        return Center(
                          child: SizedBox(
                            width: limits.maxWidth,
                            height: height,
                            child: CustomPaint(
                              key: const ValueKey<String>('reactor_scene'),
                              painter: _ReactorPainter(
                                flights: List<_ReactorFlight>.of(_flights),
                                selectedChannel: _selectedChannel,
                                channelCount: _scenario.channelCount,
                                promptChannel: _promptChannel ?? 0,
                                integrity: _integrity,
                                elapsed: _elapsed,
                                paused: _paused,
                                english: _english,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 7),
                  _ChannelSelector(
                    selected: _selectedChannel,
                    channelCount: _scenario.channelCount,
                    english: _english,
                    onSelected: _selectChannel,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _english
                        ? 'Select the outlined receiver before the pulse reaches the glass valve.'
                        : 'Darbe cam vanaya ulaşmadan çerçeveli çıkış kanalını seç.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: StudioVisuals.muted,
                      fontSize: 10,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
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

class _ReactorHud extends StatelessWidget {
  const _ReactorHud({
    required this.routed,
    required this.requiredHits,
    required this.integrity,
    required this.targetChannel,
    required this.english,
  });

  final int routed;
  final int requiredHits;
  final int integrity;
  final int targetChannel;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey<String>('reactor_hud'),
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
    decoration: BoxDecoration(
      color: StudioVisuals.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: StudioVisuals.line),
      boxShadow: StudioVisuals.softShadow,
    ),
    child: Row(
      children: <Widget>[
        Expanded(
          child: _ReactorMetric(
            label: english ? 'ROUTED' : 'AKIŞ',
            value: '$routed / $requiredHits',
            icon: Icons.bubble_chart_rounded,
            color: _ColorReactorPlayPageState._accent,
          ),
        ),
        Container(width: 1, height: 26, color: StudioVisuals.line),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                english ? 'TARGET GATE' : 'HEDEF KAPI',
                style: const TextStyle(
                  color: StudioVisuals.muted,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .35,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    _ColorReactorPlayPageState._channelShapes[targetChannel],
                    color: _ColorReactorPlayPageState._channels[targetChannel],
                    size: 17,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${targetChannel + 1}',
                    style: TextStyle(
                      color:
                          _ColorReactorPlayPageState._channels[targetChannel],
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(width: 1, height: 26, color: StudioVisuals.line),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Icon(
                Icons.favorite_rounded,
                color: integrity <= 1
                    ? StudioVisuals.danger
                    : const Color(0xFFD97872),
                size: 17,
              ),
              const SizedBox(width: 4),
              Text(
                '$integrity',
                style: const TextStyle(
                  color: _ColorReactorPlayPageState._ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ReactorMetric extends StatelessWidget {
  const _ReactorMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.start,
    children: <Widget>[
      Icon(icon, color: color, size: 17),
      const SizedBox(width: 4),
      Flexible(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: StudioVisuals.muted,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: .35,
              ),
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _ColorReactorPlayPageState._ink,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _ChannelSelector extends StatelessWidget {
  const _ChannelSelector({
    required this.selected,
    required this.channelCount,
    required this.english,
    required this.onSelected,
  });

  final int selected;
  final int channelCount;
  final bool english;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      for (int channel = 0; channel < 3; channel++) ...<Widget>[
        if (channel > 0) const SizedBox(width: 7),
        Expanded(
          child: _ChannelButton(
            channel: channel,
            selected: selected == channel,
            available: channel < channelCount,
            english: english,
            onTap: () => onSelected(channel),
          ),
        ),
      ],
    ],
  );
}

class _ChannelButton extends StatelessWidget {
  const _ChannelButton({
    required this.channel,
    required this.selected,
    required this.available,
    required this.english,
    required this.onTap,
  });

  final int channel;
  final bool selected;
  final bool available;
  final bool english;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = _ColorReactorPlayPageState._channels[channel];
    return Semantics(
      button: true,
      enabled: available,
      selected: selected,
      label:
          '${english ? 'Channel' : 'Kanal'} ${channel + 1}, ${english ? 'color' : 'renk'} ${channel + 1}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey<String>('reactor_channel_$channel'),
          onTap: available ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            height: 50,
            decoration: BoxDecoration(
              color: available
                  ? color.withValues(alpha: selected ? .18 : .07)
                  : StudioVisuals.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? color : StudioVisuals.line,
                width: selected ? 2 : 1,
              ),
              boxShadow: selected
                  ? <BoxShadow>[
                      BoxShadow(
                        color: color.withValues(alpha: .12),
                        blurRadius: 9,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  _ColorReactorPlayPageState._channelShapes[channel],
                  size: 17,
                  color: available ? color : StudioVisuals.muted,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '${english ? 'CH' : 'KANAL'} ${channel + 1}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: available
                          ? _ColorReactorPlayPageState._ink
                          : StudioVisuals.muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReactorPainter extends CustomPainter {
  _ReactorPainter({
    required this.flights,
    required this.selectedChannel,
    required this.channelCount,
    required this.promptChannel,
    required this.integrity,
    required this.elapsed,
    required this.paused,
    required this.english,
  });

  final List<_ReactorFlight> flights;
  final int selectedChannel;
  final int channelCount;
  final int promptChannel;
  final int integrity;
  final double elapsed;
  final bool paused;
  final bool english;

  static const Color _top = Color(0xFF162735);
  static const Color _bottom = Color(0xFF0C1722);

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(24)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[_top, _bottom],
        ).createShader(bounds),
    );
    _drawEnvironment(canvas, size);
    for (int lane = 0; lane < 3; lane++) {
      _drawLane(canvas, size, lane);
    }
    _drawValve(canvas, size);
    for (int lane = 0; lane < 3; lane++) {
      _drawReceiver(canvas, size, lane);
    }
    for (final _ReactorFlight flight in flights) {
      _drawPulse(canvas, size, flight);
    }
    if (paused) _drawPause(canvas, size);
  }

  void _drawEnvironment(Canvas canvas, Size size) {
    final Paint glow = Paint()
      ..shader =
          RadialGradient(
            colors: <Color>[
              _ReactorPlayColors.teal.withValues(alpha: .13),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * .52, size.height * .5),
              radius: size.width * .72,
            ),
          );
    canvas.drawRect(Offset.zero & size, glow);
    final Paint frame = Paint()
      ..color = const Color(0xFF9CB8C7).withValues(alpha: .12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (int row = 0; row < 5; row++) {
      final double y = size.height * (.15 + row * .17);
      canvas.drawLine(
        Offset(size.width * .05, y),
        Offset(size.width * .95, y),
        frame,
      );
    }
    final Paint screw = Paint()
      ..color = const Color(0xFF8299A7).withValues(alpha: .44);
    for (final Offset point in <Offset>[
      Offset(size.width * .055, size.height * .07),
      Offset(size.width * .945, size.height * .07),
      Offset(size.width * .055, size.height * .93),
      Offset(size.width * .945, size.height * .93),
    ]) {
      canvas.drawCircle(point, 2.5, screw);
    }
    final Paint light = Paint()
      ..color = _ReactorPlayColors.gold.withValues(
        alpha: .18 + .05 * math.sin(elapsed),
      );
    canvas.drawCircle(Offset(size.width * .5, size.height * .13), 3.5, light);
  }

  void _drawLane(Canvas canvas, Size size, int lane) {
    final Color color = _ReactorPlayColors.channels[lane];
    final double y = _laneY(lane);
    final Path path = Path()
      ..moveTo(size.width * .08, size.height * y)
      ..cubicTo(
        size.width * .23,
        size.height * y,
        size.width * .30,
        size.height * .5,
        size.width * .5,
        size.height * .5,
      );
    _drawTube(canvas, path, color);
    final Paint smallNode = Paint()..color = color.withValues(alpha: .72);
    canvas.drawCircle(
      Offset(size.width * .09, size.height * y),
      size.width * .025,
      smallNode,
    );
    final Path output = Path()
      ..moveTo(size.width * .5, size.height * .5)
      ..cubicTo(
        size.width * .68,
        size.height * .5,
        size.width * .73,
        size.height * y,
        size.width * .90,
        size.height * y,
      );
    _drawTube(canvas, output, color);
  }

  void _drawTube(Canvas canvas, Path path, Color color) {
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF0B1119)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 19
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: .22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 15
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: .67)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    final Path glint = Path();
    for (final metric in path.computeMetrics()) {
      glint.addPath(metric.extractPath(0, metric.length), Offset(0, -1.7));
    }
    canvas.drawPath(
      glint,
      Paint()
        ..color = Colors.white.withValues(alpha: .28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawValve(Canvas canvas, Size size) {
    final Offset center = Offset(size.width * .5, size.height * .5);
    final double radius = size.width * .12;
    final Color targetColor = _ReactorPlayColors.channels[promptChannel];
    canvas.drawCircle(
      center,
      radius * 1.48,
      Paint()..color = _ReactorPlayColors.teal.withValues(alpha: .08),
    );
    canvas.drawCircle(
      center,
      radius * 1.24,
      Paint()
        ..color = const Color(0xFF263D4A)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      radius * 1.24,
      Paint()
        ..color = const Color(0xFF91AEBE).withValues(alpha: .65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    for (int channel = 0; channel < channelCount; channel++) {
      final double angle = -math.pi / 2 + channel * math.pi * 2 / channelCount;
      final Offset dot =
          center + Offset(math.cos(angle), math.sin(angle)) * radius * .92;
      canvas.drawCircle(
        dot,
        radius * (channel == selectedChannel ? .18 : .11),
        Paint()
          ..color = _ReactorPlayColors.channels[channel].withValues(
            alpha: channel == selectedChannel ? .96 : .54,
          ),
      );
    }
    final Paint rotor = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          targetColor.withValues(alpha: .96),
          const Color(0xFF314A57),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * .84));
    canvas.drawCircle(center, radius * .72, rotor);
    canvas.drawCircle(
      center,
      radius * .72,
      Paint()
        ..color = Colors.white.withValues(alpha: .4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    final Path pointer = Path()
      ..moveTo(center.dx, center.dy - radius * .45)
      ..lineTo(center.dx + radius * .28, center.dy + radius * .22)
      ..lineTo(center.dx - radius * .28, center.dy + radius * .22)
      ..close();
    canvas.drawPath(pointer, Paint()..color = const Color(0xFF0D2029));
    canvas.drawCircle(
      center,
      radius * .11,
      Paint()..color = const Color(0xFFF4E8C9),
    );
    final Paint goalRing = Paint()
      ..color = targetColor.withValues(alpha: .88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius * 1.42, goalRing);
  }

  void _drawReceiver(Canvas canvas, Size size, int lane) {
    final Offset center = Offset(size.width * .91, size.height * _laneY(lane));
    final double radius = size.width * .048;
    final Color color = _ReactorPlayColors.channels[lane];
    final bool highlighted = lane == promptChannel;
    final Paint glow = Paint()
      ..color = color.withValues(alpha: highlighted ? .18 : .07)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, radius * 1.8, glow);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            color.withValues(alpha: .88),
            const Color(0xFF1B2D38),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = highlighted ? Colors.white : color.withValues(alpha: .58)
        ..style = PaintingStyle.stroke
        ..strokeWidth = highlighted ? 2.5 : 1,
    );
    final TextPainter number = TextPainter(
      text: TextSpan(
        text: '${lane + 1}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    number.paint(canvas, center - Offset(number.width / 2, number.height / 2));
  }

  void _drawPulse(Canvas canvas, Size size, _ReactorFlight flight) {
    final double progress = ((flight.x - .50) / .44).clamp(0, 1).toDouble();
    final double y = flight.routed
        ? _laneY(flight.spec.inputLane) +
              (_laneY(flight.route) - _laneY(flight.spec.inputLane)) *
                  progress *
                  progress *
                  (3 - 2 * progress)
        : _laneY(flight.spec.inputLane);
    final Offset center = Offset(size.width * flight.x, size.height * y);
    final Color color = _ReactorPlayColors.channels[flight.spec.destination];
    final Paint trail = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: <Color>[Colors.transparent, color.withValues(alpha: .72)],
          ).createShader(
            Rect.fromLTWH(
              center.dx - size.width * .11,
              center.dy - 2,
              size.width * .11,
              4,
            ),
          )
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx - size.width * .11, center.dy),
      center,
      trail,
    );
    canvas.drawCircle(
      center,
      size.width * .045,
      Paint()..color = color.withValues(alpha: .2),
    );
    canvas.drawCircle(
      center,
      size.width * .027,
      Paint()
        ..shader =
            RadialGradient(
              colors: <Color>[
                Colors.white,
                color,
                color.withValues(alpha: .58),
              ],
            ).createShader(
              Rect.fromCircle(center: center, radius: size.width * .03),
            ),
    );
    final Paint iconPaint = Paint()
      ..color = Colors.white.withValues(alpha: .92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    switch (flight.spec.destination) {
      case 0:
        final Path triangle = Path()
          ..moveTo(center.dx, center.dy - size.width * .009)
          ..lineTo(center.dx + size.width * .009, center.dy + size.width * .008)
          ..lineTo(center.dx - size.width * .009, center.dy + size.width * .008)
          ..close();
        canvas.drawPath(triangle, iconPaint);
      case 1:
        final Path diamond = Path()
          ..moveTo(center.dx, center.dy - size.width * .011)
          ..lineTo(center.dx + size.width * .010, center.dy)
          ..lineTo(center.dx, center.dy + size.width * .011)
          ..lineTo(center.dx - size.width * .010, center.dy)
          ..close();
        canvas.drawPath(diamond, iconPaint);
      default:
        canvas.drawCircle(center, size.width * .009, iconPaint);
    }
  }

  void _drawPause(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(24),
      ),
      Paint()..color = const Color(0xCC101D28),
    );
    final TextPainter label = TextPainter(
      text: TextSpan(
        text: english ? 'Ⅱ   PAUSED' : 'Ⅱ   DURAKLATILDI',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(
      canvas,
      Offset((size.width - label.width) / 2, size.height * .49),
    );
  }

  static double _laneY(int lane) => const <double>[.31, .50, .69][lane];

  @override
  bool shouldRepaint(covariant _ReactorPainter oldDelegate) =>
      oldDelegate.flights != flights ||
      oldDelegate.selectedChannel != selectedChannel ||
      oldDelegate.channelCount != channelCount ||
      oldDelegate.promptChannel != promptChannel ||
      oldDelegate.integrity != integrity ||
      oldDelegate.elapsed != elapsed ||
      oldDelegate.paused != paused ||
      oldDelegate.english != english;
}

abstract final class _ReactorPlayColors {
  static const Color teal = Color(0xFF57C6B2);
  static const Color gold = Color(0xFFF0BF66);
  static const List<Color> channels = <Color>[
    Color(0xFF57C6B2),
    Color(0xFFFF907B),
    Color(0xFFF0BF66),
  ];
}
