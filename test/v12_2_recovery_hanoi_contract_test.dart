import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Hanoi progress loading cannot block the game indefinitely', () {
    final source = File('lib/games/hanoi/hanoi_game_page.dart')
        .readAsStringSync();
    expect(source, contains('_progressLoadTimeout'));
    expect(source, contains('.timeout(_progressLoadTimeout)'));
    expect(source, contains('_openWithSafeDefaults'));
    expect(source, contains('loading = false'));
  });

  test('release baseline has a valid current version', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final RegExpMatch? version = RegExp(
      r'^version:\s+\d+\.\d+\.\d+\+(\d+)$',
      multiLine: true,
    ).firstMatch(pubspec);
    expect(version, isNotNull);
    expect(int.parse(version!.group(1)!), greaterThanOrEqualTo(19));
    expect(
      File('test/v13_picture_iq_2_0_quality_gate_test.dart').existsSync(),
      isFalse,
    );
  });
}
