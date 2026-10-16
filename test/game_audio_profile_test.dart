import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/features/catalog/domain/studio_game_catalog.dart';
import 'package:zeka_parkuru/games/shared/game_audio_profile.dart';
import 'package:zeka_parkuru/services/game_audio_service.dart';

void main() {
  test('every game class has a complete and restrained audio profile', () {
    for (final StudioGameClass gameClass in StudioGameClass.values) {
      final GameAudioProfile profile = GameAudioProfile.forClass(gameClass);

      expect(profile.maximumGain, lessThanOrEqualTo(0.86));
      for (final GameAudioEvent event in GameAudioEvent.values) {
        expect(profile.soundFor(event), isA<GameSound>());
      }
    }
  });

  test('speed games reserve the dedicated reflex warning sound', () {
    expect(
      GameAudioProfile.forClass(StudioGameClass.speed)
          .soundFor(GameAudioEvent.timeWarning),
      GameSound.reflexTimeWarning,
    );
  });

  test('fun games use the restrained arcade audio family', () {
    final GameAudioProfile profile = GameAudioProfile.forClass(
      StudioGameClass.fun,
    );
    expect(profile.preloadGroup, GameAudioGroup.reflex);
    expect(profile.soundFor(GameAudioEvent.accepted), GameSound.reflexHit);
    expect(
      profile.soundFor(GameAudioEvent.levelComplete),
      GameSound.levelComplete,
    );
  });

  test('Maşallah milestone levels are exactly every five levels through 30', () {
    expect(GameAudioService.isMashallahMilestone(5), isTrue);
    expect(GameAudioService.isMashallahMilestone(10), isTrue);
    expect(GameAudioService.isMashallahMilestone(15), isTrue);
    expect(GameAudioService.isMashallahMilestone(20), isTrue);
    expect(GameAudioService.isMashallahMilestone(25), isTrue);
    expect(GameAudioService.isMashallahMilestone(30), isTrue);
    for (final int level in <int>[1, 4, 6, 9, 11, 29, 31, 40]) {
      expect(GameAudioService.isMashallahMilestone(level), isFalse);
    }
  });
}
