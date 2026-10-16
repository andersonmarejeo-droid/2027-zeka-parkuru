import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/app_experience_controller.dart';
import '../services/app_language_controller.dart';
import '../services/daily_reminder_service.dart';
import '../services/game_audio_service.dart';
import '../theme/app_visual_theme.dart';
import '../theme/studio_visuals.dart';
import 'privacy_policy_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final GameAudioService _audio = GameAudioService.instance;
  final AppExperienceController _experience = AppExperienceController.instance;

  bool _loading = true;
  bool _effectsEnabled = true;
  bool _hapticsEnabled = true;
  bool _highContrast = false;
  bool _largeText = false;
  bool _dailyReminderEnabled = true;
  TimeOfDay _dailyReminderTime = const TimeOfDay(
    hour: DailyReminderService.defaultHour,
    minute: DailyReminderService.defaultMinute,
  );
  AppAnimationIntensity _animationIntensity = AppAnimationIntensity.system;

  double _effectsVolume = 0.82;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await Future.wait<void>(<Future<void>>[
      _audio.init(),
      _experience.init(),
      DailyReminderService.instance.initialize(),
    ]);

    if (!mounted) return;

    setState(() {
      _effectsEnabled = _audio.effectsEnabled;
      _hapticsEnabled = _audio.hapticsEnabled;
      _effectsVolume = _audio.effectsVolume;
      _highContrast = _experience.highContrast;
      _largeText = _experience.largeText;
      _animationIntensity = _experience.animationIntensity;
      _dailyReminderEnabled = DailyReminderService.instance.enabled;
      _dailyReminderTime = TimeOfDay(
        hour: DailyReminderService.instance.hour,
        minute: DailyReminderService.instance.minute,
      );
      _loading = false;
    });
  }

  Future<void> _setDailyReminderEnabled(bool value) async {
    final bool accepted = await DailyReminderService.instance.setEnabled(value);
    if (!mounted) return;

    setState(() {
      _dailyReminderEnabled = value && accepted;
    });

    if (value && !accepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.gameUi(
              context.l10n.isEnglish
                  ? 'Enable notification permission in Android settings to use daily reminders.'
                  : 'Günlük hatırlatıcı için Android ayarlarından bildirim iznini açın.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _pickDailyReminderTime() async {
    final TimeOfDay? selected = await showTimePicker(
      context: context,
      initialTime: _dailyReminderTime,
      helpText: context.l10n.gameUi(
        context.l10n.isEnglish
            ? 'DAILY REMINDER TIME'
            : 'GÜNLÜK HATIRLATMA SAATİ',
      ),
    );
    if (selected == null) return;

    await DailyReminderService.instance.setTime(
      hour: selected.hour,
      minute: selected.minute,
    );
    if (!mounted) return;
    setState(() => _dailyReminderTime = selected);
  }

  Future<void> _setEffectsEnabled(bool value) async {
    setState(() {
      _effectsEnabled = value;
    });

    await _audio.setEffectsEnabled(value);

    if (value) {
      await _audio.play(GameSound.uiClick);
    }
  }

  Future<void> _setHapticsEnabled(bool value) async {
    setState(() {
      _hapticsEnabled = value;
    });

    await _audio.setHapticsEnabled(value);

    if (value) {
      _audio.hapticMedium();
    }
  }

  Future<void> _saveEffectsVolume(double value) async {
    await _audio.setEffectsVolume(value);

    if (_effectsEnabled) {
      await _audio.play(GameSound.numberCorrect);
    }
  }

  Future<void> _setLanguage(AppLanguageMode mode) async {
    await AppLanguageController.instance.setMode(mode);

    if (!mounted) return;

    setState(() {});
    await _audio.play(GameSound.uiClick);
  }

  Future<void> _setAnimationIntensity(AppAnimationIntensity value) async {
    setState(() => _animationIntensity = value);
    await _experience.setAnimationIntensity(value);
  }

  Future<void> _setHighContrast(bool value) async {
    setState(() => _highContrast = value);
    await _experience.setHighContrast(value);
  }

  Future<void> _setLargeText(bool value) async {
    setState(() => _largeText = value);
    await _experience.setLargeText(value);
  }

  Future<void> _resetDefaults() async {
    const double defaultEffects = 0.82;

    await _audio.setEffectsEnabled(true);
    await _audio.setHapticsEnabled(true);
    await _audio.setEffectsVolume(defaultEffects);
    await _experience.resetDefaults();
    await DailyReminderService.instance.resetDefaults();

    if (!mounted) return;

    setState(() {
      _effectsEnabled = true;
      _hapticsEnabled = true;
      _effectsVolume = defaultEffects;
      _animationIntensity = AppAnimationIntensity.system;
      _highContrast = false;
      _largeText = false;
      _dailyReminderEnabled = DailyReminderService.instance.enabled;
      _dailyReminderTime = TimeOfDay(
        hour: DailyReminderService.instance.hour,
        minute: DailyReminderService.instance.minute,
      );
    });

    _audio.hapticMedium();
    await _audio.play(GameSound.uiUnlock);
  }

  @override
  Widget build(BuildContext context) {
    final ZpVisualPalette palette = ZpVisualPalette.of(context);
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.l10n.settingsTitle,
          style: const TextStyle(
            color: StudioVisuals.ink,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
                children: [
                  _HeaderCard(
                    effectsEnabled: _effectsEnabled,
                    hapticsEnabled: _hapticsEnabled,
                    reducedMotion:
                        _animationIntensity == AppAnimationIntensity.reduced,
                    highContrast: _highContrast,
                  ),
                  const SizedBox(height: 18),
                  _SettingsCard(
                    icon: Icons.language_rounded,
                    iconColor: StudioVisuals.teal,
                    title: context.l10n.language,
                    subtitle: context.l10n.languageDescription,
                    child: DropdownButtonFormField<AppLanguageMode>(
                      isExpanded: true,
                      initialValue: AppLanguageController.instance.mode,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: AppLanguageMode.system,
                          child: Text(context.l10n.systemDefault),
                        ),
                        DropdownMenuItem(
                          value: AppLanguageMode.turkish,
                          child: Text('🇹🇷  ${context.l10n.turkish}'),
                        ),
                        DropdownMenuItem(
                          value: AppLanguageMode.english,
                          child: Text('🇬🇧  ${context.l10n.english}'),
                        ),
                        DropdownMenuItem(
                          value: AppLanguageMode.arabic,
                          child: Text('🇸🇦  ${context.l10n.arabic}'),
                        ),
                        DropdownMenuItem(
                          value: AppLanguageMode.indonesian,
                          child: Text('🇮🇩  ${context.l10n.indonesian}'),
                        ),
                        DropdownMenuItem(
                          value: AppLanguageMode.brazilianPortuguese,
                          child: Text(
                            '🇧🇷  ${context.l10n.brazilianPortuguese}',
                          ),
                        ),
                        DropdownMenuItem(
                          value: AppLanguageMode.spanish,
                          child: Text('🌎  ${context.l10n.spanish}'),
                        ),
                        DropdownMenuItem(
                          value: AppLanguageMode.french,
                          child: Text('🇫🇷  ${context.l10n.french}'),
                        ),
                        DropdownMenuItem(
                          value: AppLanguageMode.german,
                          child: Text('🇩🇪  ${context.l10n.german}'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          _setLanguage(value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SettingsCard(
                    icon: Icons.notifications_active_rounded,
                    iconColor: StudioVisuals.amber,
                    title: context.l10n.gameUi(
                      context.l10n.isEnglish
                          ? 'Daily Course reminder'
                          : 'Günlük Parkur hatırlatıcısı',
                    ),
                    subtitle: context.l10n.gameUi(
                      context.l10n.isEnglish
                          ? 'A private on-device reminder when today’s course is still incomplete.'
                          : 'Bugünkü parkur tamamlanmadıysa cihaz içinde çalışan özel hatırlatma.',
                    ),
                    child: Column(
                      children: <Widget>[
                        SwitchListTile.adaptive(
                          key: const ValueKey<String>(
                            'daily_course_reminder_toggle',
                          ),
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            context.l10n.gameUi(
                              context.l10n.isEnglish
                                  ? 'Remind me every day'
                                  : 'Her gün hatırlat',
                            ),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            _dailyReminderEnabled
                                ? context.l10n.gameUi(
                                    context.l10n.isEnglish ? 'On' : 'Açık',
                                  )
                                : context.l10n.gameUi(
                                    context.l10n.isEnglish ? 'Off' : 'Kapalı',
                                  ),
                            style: const TextStyle(color: StudioVisuals.muted),
                          ),
                          value: _dailyReminderEnabled,
                          onChanged: _setDailyReminderEnabled,
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            key: const ValueKey<String>(
                              'daily_course_reminder_time_button',
                            ),
                            onPressed: _dailyReminderEnabled
                                ? _pickDailyReminderTime
                                : null,
                            icon: const Icon(Icons.schedule_rounded),
                            label: Text(
                              context.l10n.gameUi(
                                context.l10n.isEnglish
                                    ? 'Reminder: ${MaterialLocalizations.of(context).formatTimeOfDay(_dailyReminderTime)}'
                                    : 'Hatırlatma: ${MaterialLocalizations.of(context).formatTimeOfDay(_dailyReminderTime)}',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SettingsCard(
                    icon: Icons.volume_up_rounded,
                    iconColor: StudioVisuals.teal,
                    title: context.l10n.soundEffects,
                    subtitle: context.l10n.gameUi(
                      context.l10n.isEnglish
                          ? 'Simple game effects and one standard level-complete sound. Background music is disabled.'
                          : 'Sade oyun efektleri ve tek standart bölüm tamamlama sesi. Arka plan müziği kapalıdır.',
                    ),
                    child: Column(
                      children: [
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            context.l10n.useEffects,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            _effectsEnabled
                                ? context.l10n.on
                                : context.l10n.off,
                            style: const TextStyle(color: StudioVisuals.muted),
                          ),
                          value: _effectsEnabled,
                          onChanged: _setEffectsEnabled,
                        ),
                        const SizedBox(height: 4),
                        _VolumeRow(
                          icon: Icons.volume_down_rounded,
                          value: _effectsVolume,
                          enabled: _effectsEnabled,
                          label: context.l10n.effectVolume,
                          onChanged: (value) {
                            setState(() {
                              _effectsVolume = value;
                            });
                          },
                          onChangeEnd: _saveEffectsVolume,
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _effectsEnabled
                                ? () {
                                    _audio.play(GameSound.numberCorrect);
                                  }
                                : null,
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: Text(context.l10n.testEffect),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SettingsCard(
                    icon: Icons.music_off_rounded,
                    iconColor: StudioVisuals.muted,
                    title: context.l10n.gameUi(
                      context.l10n.isEnglish
                          ? 'Background music'
                          : 'Arka plan müziği',
                    ),
                    subtitle: context.l10n.gameUi(
                      context.l10n.isEnglish
                          ? 'Disabled. The game now uses only short sound effects.'
                          : 'Kapalı. Oyun artık yalnızca kısa ses efektleri kullanır.',
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: StudioVisuals.surfaceSoft,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: StudioVisuals.line),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.volume_off_rounded,
                            color: StudioVisuals.muted,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              context.l10n.gameUi(
                                context.l10n.isEnglish
                                    ? 'No music player is started during gameplay.'
                                    : 'Oyun sırasında hiçbir müzik oynatıcısı başlatılmaz.',
                              ),
                              style: const TextStyle(
                                color: StudioVisuals.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SettingsCard(
                    icon: Icons.vibration_rounded,
                    iconColor: StudioVisuals.amber,
                    title: context.l10n.haptics,
                    subtitle: context.l10n.hapticsDescription,
                    child: SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        context.l10n.useHaptics,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        _hapticsEnabled ? context.l10n.on : context.l10n.off,
                        style: const TextStyle(color: StudioVisuals.muted),
                      ),
                      value: _hapticsEnabled,
                      onChanged: _setHapticsEnabled,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SettingsCard(
                    icon: Icons.accessibility_new_rounded,
                    iconColor: StudioVisuals.amber,
                    title: context.l10n.gameUi(
                      context.l10n.isEnglish
                          ? 'Accessibility and motion'
                          : 'Erişilebilirlik ve hareket',
                    ),
                    subtitle: context.l10n.gameUi(
                      context.l10n.isEnglish
                          ? 'Animation intensity, contrast and text size are stored only on this device.'
                          : 'Animasyon yoğunluğu, kontrast ve metin boyutu yalnızca bu cihazda saklanır.',
                    ),
                    child: Column(
                      children: <Widget>[
                        DropdownButtonFormField<AppAnimationIntensity>(
                          isExpanded: true,
                          key: const ValueKey<String>(
                            'v9_animation_intensity_setting',
                          ),
                          initialValue: _animationIntensity,
                          decoration: InputDecoration(
                            labelText: context.l10n.gameUi(
                              context.l10n.isEnglish
                                  ? 'Animation intensity'
                                  : 'Animasyon yoğunluğu',
                            ),
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: <DropdownMenuItem<AppAnimationIntensity>>[
                            DropdownMenuItem<AppAnimationIntensity>(
                              value: AppAnimationIntensity.system,
                              child: Text(
                                context.l10n.gameUi(
                                  context.l10n.isEnglish
                                      ? 'Follow device setting'
                                      : 'Cihaz ayarını izle',
                                ),
                              ),
                            ),
                            DropdownMenuItem<AppAnimationIntensity>(
                              value: AppAnimationIntensity.full,
                              child: Text(
                                context.l10n.gameUi(
                                  context.l10n.isEnglish ? 'Full' : 'Tam',
                                ),
                              ),
                            ),
                            DropdownMenuItem<AppAnimationIntensity>(
                              value: AppAnimationIntensity.balanced,
                              child: Text(
                                context.l10n.gameUi(
                                  context.l10n.isEnglish
                                      ? 'Balanced'
                                      : 'Dengeli',
                                ),
                              ),
                            ),
                            DropdownMenuItem<AppAnimationIntensity>(
                              value: AppAnimationIntensity.reduced,
                              child: Text(
                                context.l10n.gameUi(
                                  context.l10n.isEnglish
                                      ? 'Reduced'
                                      : 'Azaltılmış',
                                ),
                              ),
                            ),
                          ],
                          onChanged: (AppAnimationIntensity? value) {
                            if (value != null) {
                              _setAnimationIntensity(value);
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile.adaptive(
                          key: const ValueKey<String>(
                            'v9_high_contrast_setting',
                          ),
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            context.l10n.gameUi(
                              context.l10n.isEnglish
                                  ? 'High contrast'
                                  : 'Yüksek kontrast',
                            ),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            context.l10n.gameUi(
                              context.l10n.isEnglish
                                  ? 'Strengthens focus and primary action colors.'
                                  : 'Odak ve ana eylem renklerini güçlendirir.',
                            ),
                            style: const TextStyle(color: StudioVisuals.muted),
                          ),
                          value: _highContrast,
                          onChanged: _setHighContrast,
                        ),
                        SwitchListTile.adaptive(
                          key: const ValueKey<String>('v9_large_text_setting'),
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            context.l10n.gameUi(
                              context.l10n.isEnglish
                                  ? 'Larger app text'
                                  : 'Daha büyük uygulama metni',
                            ),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            context.l10n.gameUi(
                              context.l10n.isEnglish
                                  ? 'Keeps the device text setting and applies at least 115%.'
                                  : 'Cihaz metin ayarını korur ve en az %115 uygular.',
                            ),
                            style: const TextStyle(color: StudioVisuals.muted),
                          ),
                          value: _largeText,
                          onChanged: _setLargeText,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SettingsCard(
                    icon: Icons.privacy_tip_outlined,
                    iconColor: StudioVisuals.teal,
                    title: context.l10n.gameUi(
                      context.l10n.isEnglish
                          ? 'Privacy and data'
                          : 'Gizlilik ve veri',
                    ),
                    subtitle: context.l10n.gameUi(
                      context.l10n.isEnglish
                          ? 'Review what is stored on-device and what online services may process.'
                          : 'Cihazda saklanan ve çevrim içi hizmetlerde işlenebilen verileri incele.',
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        key: const ValueKey<String>('privacy_policy_button'),
                        onPressed: () {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (_) => const PrivacyPolicyPage(),
                              settings: const RouteSettings(name: '/privacy'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.open_in_new_rounded),
                        label: Text(
                          context.l10n.gameUi(
                            context.l10n.isEnglish
                                ? 'OPEN PRIVACY POLICY'
                                : 'GİZLİLİK POLİTİKASINI AÇ',
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: _resetDefaults,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: Text(context.l10n.resetDefaults),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.settingsStored,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: StudioVisuals.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final bool effectsEnabled;
  final bool hapticsEnabled;
  final bool reducedMotion;
  final bool highContrast;

  const _HeaderCard({
    required this.effectsEnabled,
    required this.hapticsEnabled,
    required this.reducedMotion,
    required this.highContrast,
  });

  @override
  Widget build(BuildContext context) {
    final String summary = <String>[
      context.l10n.gameUi(
        context.l10n.isEnglish
            ? (effectsEnabled ? 'Effects on' : 'Effects off')
            : (effectsEnabled ? 'Efekt açık' : 'Efekt kapalı'),
      ),
      context.l10n.gameUi(
        context.l10n.isEnglish
            ? (hapticsEnabled ? 'Haptics on' : 'Haptics off')
            : (hapticsEnabled ? 'Titreşim açık' : 'Titreşim kapalı'),
      ),
      context.l10n.gameUi(
        context.l10n.isEnglish
            ? (reducedMotion ? 'Reduced motion' : 'Motion active')
            : (reducedMotion ? 'Hareket azaltılmış' : 'Hareket etkin'),
      ),
      context.l10n.gameUi(
        context.l10n.isEnglish
            ? (highContrast ? 'High contrast' : 'Standard contrast')
            : (highContrast ? 'Yüksek kontrast' : 'Standart kontrast'),
      ),
    ].join('  •  ');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[StudioVisuals.tealSoft, StudioVisuals.surface],
        ),
        borderRadius: StudioVisuals.cardRadius,
        border: Border.all(color: StudioVisuals.line),
        boxShadow: StudioVisuals.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: StudioVisuals.surface,
            ),
            child: const Icon(
              Icons.tune_rounded,
              size: 31,
              color: StudioVisuals.teal,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.gameExperience,
                  style: const TextStyle(
                    color: StudioVisuals.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  summary,
                  style: const TextStyle(
                    color: StudioVisuals.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget child;

  const _SettingsCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: StudioVisuals.surface,
        borderRadius: StudioVisuals.cardRadius,
        border: Border.all(color: StudioVisuals.line),
        boxShadow: StudioVisuals.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: StudioVisuals.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: StudioVisuals.muted,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Material(type: MaterialType.transparency, child: child),
        ],
      ),
    );
  }
}

class _VolumeRow extends StatelessWidget {
  final IconData icon;
  final double value;
  final bool enabled;
  final String label;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  const _VolumeRow({
    required this.icon,
    required this.value,
    required this.enabled,
    required this.label,
    required this.onChanged,
    required this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    final int percent = (value * 100).round();

    return Column(
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: enabled ? StudioVisuals.ink : StudioVisuals.muted,
              size: 21,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: enabled ? StudioVisuals.ink : StudioVisuals.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              width: 52,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: StudioVisuals.surfaceSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '%$percent',
                style: TextStyle(
                  color: enabled ? StudioVisuals.ink : StudioVisuals.muted,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: 0,
          max: 1,
          divisions: 20,
          onChanged: enabled ? onChanged : null,
          onChangeEnd: enabled ? onChangeEnd : null,
        ),
      ],
    );
  }
}
