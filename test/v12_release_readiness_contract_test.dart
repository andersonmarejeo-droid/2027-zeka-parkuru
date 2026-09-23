import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('V12 release readiness contract', () {
    test('Android release never uses debug signing and targets API 36', () {
      final String gradle = File('android/app/build.gradle.kts').readAsStringSync();
      expect(gradle, contains('compileSdk = 36'));
      expect(gradle, contains('targetSdk = 36'));
      expect(gradle, isNot(contains('signingConfigs.getByName("debug")')));
      expect(gradle, contains('hasReleaseSigning'));
    });

    test('Firebase Hosting invite, arena and privacy pages exist', () {
      expect(File('hosting/davet.html').existsSync(), isTrue);
      expect(File('hosting/arena.html').existsSync(), isTrue);
      expect(File('hosting/privacy.html').existsSync(), isTrue);
      final String firebase = File('firebase.json').readAsStringSync();
      expect(firebase, contains('"public": "hosting"'));
    });

    test('privacy policy is reachable from settings', () {
      expect(File('lib/pages/privacy_policy_page.dart').existsSync(), isTrue);
      final String settings = File('lib/pages/settings_page.dart').readAsStringSync();
      expect(settings, contains('privacy_policy_button'));
      expect(settings, contains('PrivacyPolicyPage'));
    });

    test('Arena join codes cannot be collection-listed', () {
      final String rules = File('firestore.rules').readAsStringSync();
      final String arena = File('lib/services/arena_service.dart').readAsStringSync();
      expect(rules, contains('match /arena_invites_v1/{code}'));
      expect(rules, contains('allow list: if false'));
      expect(arena, contains("collection('arena_invites_v1')"));
      expect(arena, isNot(contains("where('joinCode', isEqualTo: code)")));
    });

    test('online data deletion path exists end to end', () {
      expect(File('lib/services/account_data_service.dart').existsSync(), isTrue);
      final String rules = File('firestore.rules').readAsStringSync();
      final String functions = File('functions/index.js').readAsStringSync();
      expect(rules, contains('account_deletion_requests_v1'));
      expect(functions, contains('accountDeletionRequested'));
      expect(functions, contains('deleteUser(uid)'));
    });

    test('sensitive release files remain ignored', () {
      final String androidIgnore = File('android/.gitignore').readAsStringSync();
      expect(androidIgnore, contains('key.properties'));
      expect(androidIgnore, contains('**/*.jks'));
      expect(androidIgnore, contains('**/*.keystore'));
    });
  });
}
