import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/services/game_audio_service.dart';

import 'test_preferences.dart';

void main() {
  setUp(() {
    installTestPreferences();
  });

  tearDown(() {
    uninstallTestPreferences();
  });

  test('GameAudioService lifecycle observer transitions smoothly', () async {
    final GameAudioService service = GameAudioService.instance;

    await service.init();

    // App goes to background
    service.didChangeAppLifecycleState(AppLifecycleState.paused);

    // App returns to foreground
    service.didChangeAppLifecycleState(AppLifecycleState.resumed);

    // Engine recover can be called safely
    await service.recoverEngine();

    // Sound can be requested without throwing
    await service.play(GameSound.uiClick);
    await service.playMemoryNote(1);
  });
}
