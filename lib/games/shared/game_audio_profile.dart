import '../../features/catalog/domain/studio_game_catalog.dart';
import '../../services/game_audio_service.dart';

/// Meaningful, reusable audio moments for every catalog game.
///
/// A game chooses an event instead of reaching for an unrelated sound. The
/// sound service still owns cooldowns, user preference and the shared final
/// celebration, so adding a game cannot create a noisy audio island.
enum GameAudioEvent {
  menu,
  primaryAction,
  accepted,
  rejected,
  hint,
  timeWarning,
  levelComplete,
}

class GameAudioProfile {
  // Keep the public `sounds` input mapped to private storage.
  const GameAudioProfile({
    required this.preloadGroup,
    required Map<GameAudioEvent, GameSound> sounds,
    this.maximumGain = 0.86,
  }) : _sounds = sounds; // ignore: prefer_initializing_formals

  final GameAudioGroup preloadGroup;
  final Map<GameAudioEvent, GameSound> _sounds;
  final double maximumGain;

  GameSound soundFor(GameAudioEvent event) => _sounds[event]!;

  Future<void> preload(GameAudioService audio) => audio.preload(preloadGroup);

  Future<void> play(
    GameAudioService audio,
    GameAudioEvent event, {
    double gain = 1,
    int? levelNumber,
  }) {
    final double safeGain = gain.clamp(0.0, maximumGain).toDouble();
    if (event == GameAudioEvent.levelComplete && levelNumber != null) {
      return audio.playLevelComplete(levelNumber: levelNumber, gain: safeGain);
    }
    return audio.play(
      soundFor(event),
      gain: safeGain,
      // StudioGameSession.useHint records the scoring penalty. The profile
      // only plays its sound so one hint is never charged twice.
      countHintForScoring: event != GameAudioEvent.hint,
    );
  }

  /// Keeps the established level-end voice celebration for future games.
  Future<void> playCourseCompletion(
    GameAudioService audio, {
    int? levelNumber,
  }) {
    if (levelNumber == null) return Future<void>.value();
    return audio.playLevelComplete(levelNumber: levelNumber);
  }

  static GameAudioProfile forClass(StudioGameClass gameClass) {
    return switch (gameClass) {
      StudioGameClass.logic || StudioGameClass.strategy => _logicProfile,
      StudioGameClass.numbers => _numbersProfile,
      StudioGameClass.visual => _blocksProfile,
      StudioGameClass.fun => _funProfile,
      StudioGameClass.memory => _memoryProfile,
      StudioGameClass.language => _languageProfile,
      StudioGameClass.speed => _reflexProfile,
    };
  }

  static const GameAudioProfile _logicProfile = GameAudioProfile(
    preloadGroup: GameAudioGroup.logic,
    sounds: <GameAudioEvent, GameSound>{
      GameAudioEvent.menu: GameSound.uiClick,
      GameAudioEvent.primaryAction: GameSound.logicMove,
      GameAudioEvent.accepted: GameSound.logicGoal,
      GameAudioEvent.rejected: GameSound.logicWall,
      GameAudioEvent.hint: GameSound.logicHint,
      GameAudioEvent.timeWarning: GameSound.timeWarning,
      GameAudioEvent.levelComplete: GameSound.levelComplete,
    },
  );

  static const GameAudioProfile _numbersProfile = GameAudioProfile(
    preloadGroup: GameAudioGroup.numbers,
    sounds: <GameAudioEvent, GameSound>{
      GameAudioEvent.menu: GameSound.uiClick,
      GameAudioEvent.primaryAction: GameSound.numberSelect,
      GameAudioEvent.accepted: GameSound.numberCorrect,
      GameAudioEvent.rejected: GameSound.numberWrong,
      GameAudioEvent.hint: GameSound.uiHint,
      GameAudioEvent.timeWarning: GameSound.timeWarning,
      GameAudioEvent.levelComplete: GameSound.levelComplete,
    },
  );

  static const GameAudioProfile _blocksProfile = GameAudioProfile(
    preloadGroup: GameAudioGroup.blocks,
    sounds: <GameAudioEvent, GameSound>{
      GameAudioEvent.menu: GameSound.uiClick,
      GameAudioEvent.primaryAction: GameSound.blockPickup,
      GameAudioEvent.accepted: GameSound.blockPlace,
      GameAudioEvent.rejected: GameSound.blockInvalid,
      GameAudioEvent.hint: GameSound.uiHint,
      GameAudioEvent.timeWarning: GameSound.timeWarning,
      GameAudioEvent.levelComplete: GameSound.levelComplete,
    },
  );

  static const GameAudioProfile _funProfile = GameAudioProfile(
    preloadGroup: GameAudioGroup.reflex,
    sounds: <GameAudioEvent, GameSound>{
      GameAudioEvent.menu: GameSound.uiClick,
      GameAudioEvent.primaryAction: GameSound.reflexSpawn,
      GameAudioEvent.accepted: GameSound.reflexHit,
      GameAudioEvent.rejected: GameSound.reflexMiss,
      GameAudioEvent.hint: GameSound.uiHint,
      GameAudioEvent.timeWarning: GameSound.reflexTimeWarning,
      GameAudioEvent.levelComplete: GameSound.levelComplete,
    },
  );

  static const GameAudioProfile _memoryProfile = GameAudioProfile(
    preloadGroup: GameAudioGroup.memory,
    sounds: <GameAudioEvent, GameSound>{
      GameAudioEvent.menu: GameSound.uiClick,
      GameAudioEvent.primaryAction: GameSound.memoryTap,
      GameAudioEvent.accepted: GameSound.memoryCorrect,
      GameAudioEvent.rejected: GameSound.memoryWrong,
      GameAudioEvent.hint: GameSound.uiHint,
      GameAudioEvent.timeWarning: GameSound.timeWarning,
      GameAudioEvent.levelComplete: GameSound.levelComplete,
    },
  );

  static const GameAudioProfile _languageProfile = GameAudioProfile(
    preloadGroup: GameAudioGroup.logic,
    sounds: <GameAudioEvent, GameSound>{
      GameAudioEvent.menu: GameSound.uiClick,
      GameAudioEvent.primaryAction: GameSound.numberSelect,
      GameAudioEvent.accepted: GameSound.success,
      GameAudioEvent.rejected: GameSound.numberWrong,
      GameAudioEvent.hint: GameSound.uiHint,
      GameAudioEvent.timeWarning: GameSound.timeWarning,
      GameAudioEvent.levelComplete: GameSound.levelComplete,
    },
  );

  static const GameAudioProfile _reflexProfile = GameAudioProfile(
    preloadGroup: GameAudioGroup.reflex,
    sounds: <GameAudioEvent, GameSound>{
      GameAudioEvent.menu: GameSound.uiClick,
      GameAudioEvent.primaryAction: GameSound.reflexSpawn,
      GameAudioEvent.accepted: GameSound.reflexHit,
      GameAudioEvent.rejected: GameSound.reflexMiss,
      GameAudioEvent.hint: GameSound.uiHint,
      GameAudioEvent.timeWarning: GameSound.reflexTimeWarning,
      GameAudioEvent.levelComplete: GameSound.levelComplete,
    },
  );
}
