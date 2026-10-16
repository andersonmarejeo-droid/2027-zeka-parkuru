import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'common_level_score_service.dart';

enum GameAudioGroup { ui, logic, numbers, blocks, memory, reflex }

enum GameSound {
  uiClick,
  uiBack,
  uiHint,
  uiUnlock,
  gameOpen,
  transition,
  countdownTick,
  timeWarning,
  logicMove,
  logicWall,
  logicHint,
  logicGoal,
  numberSelect,
  numberCorrect,
  numberWrong,
  numberCombo,
  numberStreak,
  blockPickup,
  blockPlace,
  blockInvalid,
  blockClear,
  blockDoubleClear,
  blockCombo,
  blockMega,
  blockGameOver,
  memoryTap,
  memoryRoundStart,
  memoryCorrect,
  memoryWrong,
  memoryDecoy,
  memoryStreak,
  reflexSpawn,
  reflexHit,
  reflexMiss,
  reflexMonkey,
  reflexBomb,
  reflexCorrect,
  reflexTimeWarning,
  reward,
  star,
  levelComplete,
  threeStars,
  bossIntro,
  bossComplete,
  unlock,
  monkeyHit,
  bombWrong,
  success,
  applause,
  mashallahCelebration,
}

enum GameMusic { menu, calm, action }

/// Zeka Parkuru sade ses motoru.
///
/// - Arka plan müziği yok.
/// - Eski audioplayers / Android MediaPlayer efekti yok.
/// - Eski soundpool eklentisi yok.
/// - Kısa WAV efektler SoLoud oyun ses motorunda RAM'e bir kez yüklenir.
/// - Rastgele varyant yok.
/// - Tüm bölümler aynı level_success.wav başarı sesini kullanır.
class GameAudioService {
  GameAudioService._();

  static final GameAudioService instance = GameAudioService._();

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();
  // SoLoud.instance bir FFI kitaplığı açar. Bunu servis oluşturulurken
  // çağırmak, yerel ses DLL'sinin bulunmadığı widget testlerinde daha
  // ekran kurulmadan hata üretir. Motoru ilk gerçek kullanımda oluştur.
  SoLoud? _soloud;

  final Map<String, AudioSource> _sources = <String, AudioSource>{};
  final Set<String> _unavailableAssets = <String>{};
  final Map<GameSound, DateTime> _lastPlayed = <GameSound, DateTime>{};

  Future<void>? _initializingFuture;
  bool _initialized = false;

  bool effectsEnabled = true;
  bool musicEnabled = false;
  bool hapticsEnabled = true;

  double effectsVolume = 0.82;
  double musicVolume = 0.0;

  static const String _effectsEnabledKey = 'audio_effects_enabled_final';
  static const String _hapticsEnabledKey = 'audio_haptics_enabled_final';
  static const String _effectsVolumeKey = 'audio_effects_volume_final';

  static const String _base = 'assets/sounds/';

  static const Map<GameSound, String> _paths = <GameSound, String>{
    GameSound.uiClick: '${_base}click.wav',
    GameSound.uiBack: '${_base}back.wav',
    GameSound.uiHint: '${_base}hint.wav',
    GameSound.uiUnlock: '${_base}correct.wav',
    GameSound.gameOpen: '${_base}click.wav',
    GameSound.transition: '${_base}click.wav',
    GameSound.countdownTick: '${_base}click.wav',
    GameSound.timeWarning: '${_base}warning.wav',

    GameSound.logicMove: '${_base}step.wav',
    GameSound.logicWall: '${_base}wall.wav',
    GameSound.logicHint: '${_base}hint.wav',
    GameSound.logicGoal: '${_base}correct.wav',

    GameSound.numberSelect: '${_base}select.wav',
    GameSound.numberCorrect: '${_base}correct.wav',
    GameSound.numberWrong: '${_base}wrong.wav',
    GameSound.numberCombo: '${_base}correct.wav',
    GameSound.numberStreak: '${_base}correct.wav',

    GameSound.blockPickup: '${_base}block_pickup.wav',
    GameSound.blockPlace: '${_base}block_place.wav',
    GameSound.blockInvalid: '${_base}block_invalid.wav',
    GameSound.blockClear: '${_base}block_clear.wav',
    GameSound.blockDoubleClear: '${_base}block_clear.wav',
    GameSound.blockCombo: '${_base}block_clear.wav',
    GameSound.blockMega: '${_base}block_clear.wav',
    GameSound.blockGameOver: '${_base}wrong.wav',

    GameSound.memoryTap: '${_base}click.wav',
    GameSound.memoryRoundStart: '${_base}memory_round.wav',
    GameSound.memoryCorrect: '${_base}correct.wav',
    GameSound.memoryWrong: '${_base}wrong.wav',
    GameSound.memoryDecoy: '${_base}wrong.wav',
    GameSound.memoryStreak: '${_base}correct.wav',

    GameSound.reflexSpawn: '${_base}reflex_spawn.wav',
    GameSound.reflexHit: '${_base}reflex_hit.wav',
    GameSound.reflexMiss: '${_base}wrong.wav',
    GameSound.reflexMonkey: '${_base}reflex_hit.wav',
    GameSound.reflexBomb: '${_base}reflex_bomb.wav',
    GameSound.reflexCorrect: '${_base}correct.wav',
    GameSound.reflexTimeWarning: '${_base}warning.wav',

    GameSound.reward: '${_base}correct.wav',
    GameSound.star: '${_base}correct.wav',

    GameSound.levelComplete: '${_base}level_success.wav',
    GameSound.threeStars: '${_base}level_success.wav',
    GameSound.bossComplete: '${_base}level_success.wav',
    GameSound.applause: '${_base}level_success.wav',
    GameSound.mashallahCelebration: '${_base}mashallah_muhtesemsin.wav',

    GameSound.bossIntro: '${_base}warning.wav',
    GameSound.unlock: '${_base}correct.wav',
    GameSound.monkeyHit: '${_base}reflex_hit.wav',
    GameSound.bombWrong: '${_base}reflex_bomb.wav',
    GameSound.success: '${_base}correct.wav',
  };

  static const Map<String, double> _pathGain = <String, double>{
    '${_base}click.wav': 0.48,
    '${_base}back.wav': 0.56,
    '${_base}hint.wav': 0.68,
    '${_base}warning.wav': 0.62,
    '${_base}step.wav': 0.50,
    '${_base}wall.wav': 0.62,
    '${_base}select.wav': 0.50,
    '${_base}correct.wav': 0.72,
    '${_base}wrong.wav': 0.64,
    '${_base}block_pickup.wav': 0.52,
    '${_base}block_place.wav': 0.60,
    '${_base}block_invalid.wav': 0.62,
    '${_base}block_clear.wav': 0.80,
    '${_base}memory_round.wav': 0.58,
    '${_base}reflex_spawn.wav': 0.42,
    '${_base}reflex_hit.wav': 0.70,
    '${_base}reflex_bomb.wav': 0.84,
    '${_base}level_success.wav': 0.96,
    '${_base}mashallah_muhtesemsin.wav': 1.00,
  };

  static const Map<GameSound, Duration> _cooldowns = <GameSound, Duration>{
    GameSound.uiClick: Duration(milliseconds: 40),
    GameSound.logicMove: Duration(milliseconds: 28),
    GameSound.logicWall: Duration(milliseconds: 90),
    GameSound.numberSelect: Duration(milliseconds: 40),
    GameSound.blockPickup: Duration(milliseconds: 35),
    GameSound.blockPlace: Duration(milliseconds: 28),
    GameSound.blockInvalid: Duration(milliseconds: 80),
    GameSound.memoryTap: Duration(milliseconds: 30),
    GameSound.reflexSpawn: Duration(milliseconds: 25),
    GameSound.reflexHit: Duration(milliseconds: 18),
    GameSound.reflexMonkey: Duration(milliseconds: 20),
    GameSound.mashallahCelebration: Duration(seconds: 4),
  };

  Future<void> init() {
    if (_initialized) {
      return Future<void>.value();
    }

    final Future<void>? pending = _initializingFuture;
    if (pending != null) {
      return pending;
    }

    final Future<void> future = _doInit();
    _initializingFuture = future;

    return future.whenComplete(() {
      _initializingFuture = null;
    });
  }

  Future<void> _doInit() async {
    effectsEnabled = await _prefs.getBool(_effectsEnabledKey) ?? true;
    hapticsEnabled = await _prefs.getBool(_hapticsEnabledKey) ?? true;
    effectsVolume = await _prefs.getDouble(_effectsVolumeKey) ?? 0.82;

    musicEnabled = false;
    musicVolume = 0.0;

    try {
      final SoLoud soloud = _soloud ??= SoLoud.instance;

      if (!soloud.isInitialized) {
        await soloud.init(lowLatency: true, automaticCleanup: true);
        soloud.setMaxActiveVoiceCount(12);
      }
    } catch (error) {
      // Ses motoru oyunun zorunlu bir parçası değildir. Bir masaüstü test
      // ortamında yerel kitaplık bulunmayabilir; bu durumda sessiz çalış.
      _soloud = null;
      _initialized = true;
      debugPrint('Sade ses motoru kullanılamıyor; sessiz devam: $error');
      return;
    }

    final Set<String> uniquePaths = <String>{
      ..._paths.values,
      for (int i = 1; i <= 8; i++)
        '${_base}memory_note_${i.toString().padLeft(2, '0')}.wav',
    };

    for (final String path in uniquePaths) {
      await _loadSound(path);
    }

    _initialized = true;
  }

  Future<void> _loadSound(String path) async {
    if (_sources.containsKey(path) || _unavailableAssets.contains(path)) {
      return;
    }

    try {
      final SoLoud? soloud = _soloud;
      if (soloud == null) return;

      final AudioSource source = await soloud.loadAsset(
        path,
        mode: LoadMode.memory,
      );
      _sources[path] = source;
    } catch (error) {
      _unavailableAssets.add(path);
      debugPrint('Sade ses yüklenemedi: $path | $error');
    }
  }

  Future<void> preload(GameAudioGroup group) async {
    try {
      await init();
    } catch (error) {
      // Ses motoru yardımcıdır; bir cihaz/ test ortamı ses eklentisini
      // başlatamasa bile oyun ekranı çalışmaya devam etmelidir.
      debugPrint('Sade ses ön yüklemesi atlandı: $group | $error');
    }
  }

  Future<void> play(
    GameSound sound, {
    double gain = 1.0,
    bool countHintForScoring = true,
  }) async {
    if (countHintForScoring &&
        (sound == GameSound.uiHint || sound == GameSound.logicHint)) {
      CommonLevelScoreSession.recordHint();
    }
    try {
      await init();

      if (!effectsEnabled || _isCoolingDown(sound)) {
        return;
      }

      final String? path = _paths[sound];
      if (path == null) return;

      final AudioSource? source = _sources[path];
      if (source == null) return;

      final double volume = (effectsVolume * (_pathGain[path] ?? 0.70) * gain)
          .clamp(0.0, 1.0)
          .toDouble();

      final SoLoud? soloud = _soloud;
      if (soloud == null) return;

      soloud.play(source, volume: volume);

      _lastPlayed[sound] = DateTime.now();
    } catch (error) {
      debugPrint('Sade ses oynatılamadı: $sound | $error');
    }
  }

  Future<void> playMemoryNote(int noteIndex, {double gain = 1.0}) async {
    try {
      await init();

      if (!effectsEnabled) return;

      final int safeIndex = noteIndex.clamp(0, 7).toInt() + 1;
      final String path =
          '${_base}memory_note_${safeIndex.toString().padLeft(2, '0')}.wav';

      final AudioSource? source = _sources[path];
      if (source == null) return;

      final double volume = (effectsVolume * 0.66 * gain)
          .clamp(0.0, 1.0)
          .toDouble();

      final SoLoud? soloud = _soloud;
      if (soloud == null) return;

      soloud.play(source, volume: volume);
    } catch (error) {
      debugPrint('Hafıza notası oynatılamadı: $error');
    }
  }

  /// Açılış jingle'ı yok.
  Future<void> playOpeningJingle() async {
    await init();
  }

  /// Bütün normal, 3 yıldız ve boss bölümlerinde
  /// tek standart başarı sesi kullanılır.
  Future<void> playVictory({
    required int stars,
    required bool boss,
    int? levelNumber,
  }) async {
    if (levelNumber == null) {
      await play(GameSound.levelComplete);
      return;
    }
    await playLevelComplete(levelNumber: levelNumber);
  }

  /// Plays the standard success jingle for every completed level and the
  /// spoken celebration only on the selected milestone levels.
  Future<void> playLevelComplete({required int levelNumber, double gain = 1}) async {
    await play(GameSound.levelComplete, gain: gain);
    if (isMashallahMilestone(levelNumber)) {
      await playMashallahCelebration();
    }
  }

  /// The spoken celebration is intentionally limited to these six levels.
  /// Replays use the same rule, so a replay of level 5/10/15/20/25/30 gets
  /// the celebration again while all other levels remain jingle-only.
  static bool isMashallahMilestone(int levelNumber) {
    return const <int>{5, 10, 15, 20, 25, 30}.contains(levelNumber);
  }

  Future<void> playMashallahCelebration() async {
    // Bolum basari sesinin altinda kaybolmamasi icin kisa bir ara ver.
    await Future<void>.delayed(const Duration(milliseconds: 800));
    await play(GameSound.mashallahCelebration);
  }

  /// Ayrı yıldız ses dizisi yok.
  Future<void> playStarSequence(int stars) async {}

  /// Arka plan müziği tamamen kaldırılmıştır.
  Future<void> playMusic(GameMusic music) async {}

  Future<void> stopMusic() async {}

  Future<void> pauseMusic() async {}

  Future<void> resumeMusic() async {}

  bool _isCoolingDown(GameSound sound) {
    final Duration? cooldown = _cooldowns[sound];
    final DateTime? lastPlayed = _lastPlayed[sound];

    if (cooldown == null || lastPlayed == null) {
      return false;
    }

    return DateTime.now().difference(lastPlayed) < cooldown;
  }

  void hapticSelection() {
    if (!hapticsEnabled) return;
    HapticFeedback.selectionClick();
  }

  void hapticLight() {
    if (!hapticsEnabled) return;
    HapticFeedback.lightImpact();
  }

  void hapticMedium() {
    if (!hapticsEnabled) return;
    HapticFeedback.mediumImpact();
  }

  void hapticHeavy() {
    if (!hapticsEnabled) return;
    HapticFeedback.heavyImpact();
  }

  Future<void> setEffectsEnabled(bool value) async {
    effectsEnabled = value;
    await _prefs.setBool(_effectsEnabledKey, value);
  }

  Future<void> setMusicEnabled(bool value) async {
    musicEnabled = false;
  }

  Future<void> setHapticsEnabled(bool value) async {
    hapticsEnabled = value;
    await _prefs.setBool(_hapticsEnabledKey, value);
  }

  Future<void> setEffectsVolume(double value) async {
    effectsVolume = value.clamp(0.0, 1.0).toDouble();
    await _prefs.setDouble(_effectsVolumeKey, effectsVolume);
  }

  Future<void> setMusicVolume(double value) async {
    musicVolume = 0.0;
  }

  Future<void> dispose() async {
    try {
      final SoLoud? soloud = _soloud;
      if (soloud != null && soloud.isInitialized) {
        await soloud.disposeAllSources();
        await soloud.deinitAsync();
      }
    } catch (error) {
      debugPrint('SoLoud kapatma atlandı: $error');
    }

    _sources.clear();
    _unavailableAssets.clear();
    _lastPlayed.clear();
    _soloud = null;
    _initialized = false;
  }
}
