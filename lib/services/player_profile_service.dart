import 'package:shared_preferences/shared_preferences.dart';

class PlayerProfileData {
  final String displayName;
  final String avatar;

  const PlayerProfileData({
    required this.displayName,
    required this.avatar,
  });
}

class PlayerProfileService {
  PlayerProfileService._();

  static final PlayerProfileService instance =
      PlayerProfileService._();

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  static const String _nameKey = 'player_profile_v1_name';
  static const String _avatarKey = 'player_profile_v1_avatar';

  static const List<String> avatars = <String>[
    '🧠',
    '🚀',
    '⚡',
    '🎯',
    '🦊',
    '🐼',
    '🤖',
    '👑',
    '🧩',
    '🔥',
    '🌟',
    '🏆',
  ];

  Future<PlayerProfileData> load() async {
    final String name =
        await _prefs.getString(_nameKey) ?? 'Oyuncu';

    final String avatar =
        await _prefs.getString(_avatarKey) ?? avatars.first;

    return PlayerProfileData(
      displayName: _normalizeName(name),
      avatar: avatars.contains(avatar) ? avatar : avatars.first,
    );
  }

  Future<PlayerProfileData> save({
    required String displayName,
    required String avatar,
  }) async {
    final String safeName = _normalizeName(displayName);
    final String safeAvatar =
        avatars.contains(avatar) ? avatar : avatars.first;

    await _prefs.setString(_nameKey, safeName);
    await _prefs.setString(_avatarKey, safeAvatar);

    return PlayerProfileData(
      displayName: safeName,
      avatar: safeAvatar,
    );
  }

  String _normalizeName(String value) {
    final String trimmed = value.trim();

    if (trimmed.isEmpty) {
      return 'Oyuncu';
    }

    if (trimmed.length <= 18) {
      return trimmed;
    }

    return trimmed.substring(0, 18);
  }
}
