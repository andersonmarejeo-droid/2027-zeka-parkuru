import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const List<String> _soundFiles = <String>[
  'click.wav',
  'back.wav',
  'hint.wav',
  'correct.wav',
  'warning.wav',
  'step.wav',
  'wall.wav',
  'select.wav',
  'wrong.wav',
  'block_pickup.wav',
  'block_place.wav',
  'block_invalid.wav',
  'block_clear.wav',
  'memory_round.wav',
  'reflex_spawn.wav',
  'reflex_hit.wav',
  'reflex_bomb.wav',
  'level_success.wav',
  'mashallah_muhtesemsin.wav',
  'memory_note_01.wav',
  'memory_note_02.wav',
  'memory_note_03.wav',
  'memory_note_04.wav',
  'memory_note_05.wav',
  'memory_note_06.wav',
  'memory_note_07.wav',
  'memory_note_08.wav',
];

void main() {
  group('Varlık ve Android paket bütünlüğü', () {
    test('ses motorunun kullandığı bütün WAV dosyaları vardır', () {
      final List<String> missing = <String>[
        for (final String name in _soundFiles)
          if (!File('assets/sounds/$name').existsSync()) name,
      ];

      expect(
        missing,
        isEmpty,
        reason: 'Eksik ses dosyaları: ${missing.join(', ')}',
      );
    });

    test('açılış görselleri ve pubspec varlık kayıtları eksiksizdir', () {
      expect(File('assets/branding/opening_runner.webp').existsSync(), isTrue);
      expect(
        File('assets/branding/opening_background.webp').existsSync(),
        isTrue,
      );

      final String pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('- assets/sounds/'));
      expect(pubspec, contains('- assets/branding/'));
      expect(pubspec, contains('flutter_test:'));
    });

    test('Android manifest ağ ve titreşim izinlerini korur', () {
      final String manifest = File('android/app/src/main/AndroidManifest.xml')
          .readAsStringSync();

      expect(manifest, contains('android.permission.INTERNET'));
      expect(manifest, contains('android.permission.ACCESS_NETWORK_STATE'));
      expect(manifest, contains('android.permission.VIBRATE'));
      expect(manifest, contains('android:usesCleartextTraffic="false"'));
    });

    test('uygulama kimliği ve sürüm numarası yayın için tanımlıdır', () {
      final String gradle = File('android/app/build.gradle.kts')
          .readAsStringSync();
      final String pubspec = File('pubspec.yaml').readAsStringSync();

      expect(gradle, contains('applicationId'));
      expect(gradle, contains('minSdk'));
      expect(gradle, contains('targetSdk'));
      expect(
        pubspec,
        matches(RegExp(r'^version:\s*\d+\.\d+\.\d+\+\d+', multiLine: true)),
      );
    });
  });
}
