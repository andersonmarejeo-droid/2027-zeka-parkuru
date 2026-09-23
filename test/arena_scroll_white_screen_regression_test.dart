import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Arena kaydırma beyaz ekran regresyonu', () {
    test('arena kaydırması yenilemeyi tetiklemez ve durumunu korur', () {
      final String arena = File('lib/pages/arena_page.dart').readAsStringSync();

      expect(arena, contains('bool _initializing = false;'));
      expect(arena, contains('if (_initializing) return;'));
      expect(arena, contains('ScrollConfiguration('));
      expect(arena, contains('overscroll: false'));
      expect(arena, contains('ClampingScrollPhysics('));
      expect(arena, contains("PageStorageKey<String>('arena_home_scroll')"));
      expect(arena, contains(r"'arena_group_${group.id}'"));
      expect(arena, isNot(contains(': RefreshIndicator(')));
      expect(
        arena,
        contains('Yenileme tamamlanamadı. Mevcut ekran korunuyor.'),
      );
    });

    test('Android kalıcı beyaz yüzey için güvenli çizim yolunu kullanır', () {
      final String manifest = File('android/app/src/main/AndroidManifest.xml')
          .readAsStringSync();

      expect(
        RegExp(
          r'<meta-data\s+'
          r'android:name="io\.flutter\.embedding\.android\.EnableImpeller"\s+'
          r'android:value="false"\s*/>',
        ).hasMatch(manifest),
        isTrue,
      );
    });
  });
}
