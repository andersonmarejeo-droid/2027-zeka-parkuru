import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_experience_controller.dart';
import '../services/onboarding_preference_service.dart';
import '../theme/app_visual_theme.dart';
import '../theme/studio_visuals.dart';

class FirstRunProfilePage extends StatefulWidget {
  const FirstRunProfilePage({required this.destination, super.key})
    : editMode = false;

  const FirstRunProfilePage.edit({super.key})
    : destination = null,
      editMode = true;

  final Widget? destination;
  final bool editMode;

  @override
  State<FirstRunProfilePage> createState() => _FirstRunProfilePageState();
}

class _FirstRunProfilePageState extends State<FirstRunProfilePage> {
  final OnboardingPreferenceService _preferences =
      OnboardingPreferenceService.instance;
  final AppExperienceController _experience = AppExperienceController.instance;

  PlayerAgeGroup? _ageGroup;
  PlayerGameGoal? _gameGoal;
  int _step = 0;
  bool _loading = true;
  bool _saving = false;

  bool get _isTurkish =>
      Localizations.localeOf(context).languageCode.toLowerCase() == 'tr';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await _experience.init();
      final OnboardingPreferences saved = await _preferences.load();
      if (!mounted) return;
      setState(() {
        _ageGroup = saved.ageGroup;
        _gameGoal = saved.gameGoal;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _continue() {
    if (_step == 0) {
      if (_ageGroup == null) return;
      HapticFeedback.selectionClick();
      setState(() => _step = 1);
      return;
    }
    if (_step == 1 && !widget.editMode) {
      if (_gameGoal == null) return;
    }
    _save();
  }

  Future<void> _save() async {
    final PlayerAgeGroup? ageGroup = _ageGroup;
    final PlayerGameGoal? gameGoal = _gameGoal;
    if (ageGroup == null || gameGoal == null || _saving) return;

    setState(() => _saving = true);
    try {
      await _experience.setVisualTheme(AppVisualTheme.studioGarden);
      await _preferences.save(ageGroup: ageGroup, gameGoal: gameGoal);
      if (!mounted) return;
      HapticFeedback.lightImpact();

      final Widget? destination = widget.destination;
      if (destination == null) {
        Navigator.of(context).pop(true);
        return;
      }

      await Navigator.of(context).pushReplacement<void, void>(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 320),
          pageBuilder: (context, animation, secondaryAnimation) => destination,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: child,
            );
          },
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isTurkish
                ? 'Tercihler kaydedilemedi. Lütfen tekrar deneyin.'
                : 'Preferences could not be saved. Please try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ZpVisualPalette palette = ZpVisualPalette.garden;
    final bool canContinue = switch (_step) {
      0 => _ageGroup != null,
      _ => _gameGoal != null,
    };

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: palette.onboardingBackground,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: palette.onboardingBackground,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: PopScope(
        canPop: widget.editMode,
        child: Scaffold(
          backgroundColor: palette.onboardingBackground,
          body: SafeArea(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(
                      color: palette.onboardingAccent,
                    ),
                  )
                : Column(
                    children: <Widget>[
                      _TopBar(
                        step: _step,
                        editMode: widget.editMode,
                        isTurkish: _isTurkish,
                        totalSteps: 2,
                        accent: palette.onboardingAccent,
                        onBack: () {
                          if (_step > 0) {
                            setState(() => _step--);
                          } else if (widget.editMode) {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.06, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: switch (_step) {
                            0 => _AgeStep(
                              key: const ValueKey<String>('age'),
                              selected: _ageGroup,
                              isTurkish: _isTurkish,
                              accent: palette.onboardingAccent,
                              surface: palette.onboardingSurface,
                              onSelected: (value) {
                                HapticFeedback.selectionClick();
                                setState(() => _ageGroup = value);
                              },
                            ),
                            _ => _GoalStep(
                              key: const ValueKey<String>('goal'),
                              selected: _gameGoal,
                              isTurkish: _isTurkish,
                              accent: palette.onboardingAccent,
                              surface: palette.onboardingSurface,
                              onSelected: (value) {
                                HapticFeedback.selectionClick();
                                setState(() => _gameGoal = value);
                              },
                            ),
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                        child: Column(
                          children: <Widget>[
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: FilledButton(
                                onPressed: canContinue && !_saving
                                    ? _continue
                                    : null,
                                style: FilledButton.styleFrom(
                                  backgroundColor: palette.onboardingAccent,
                                  disabledBackgroundColor: StudioVisuals.line,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: _saving
                                    ? const SizedBox.square(
                                        dimension: 23,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        _buttonLabel,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _isTurkish
                                  ? 'Bu bilgiler yalnızca bu cihazda tutulur; puanını, sıralamanı ve Arena sonuçlarını etkilemez.'
                                  : 'These choices stay on this device and do not affect scores, rankings or Arena results.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: StudioVisuals.muted,
                                fontSize: 10.5,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  String get _buttonLabel {
    if (_step == 0) return _isTurkish ? 'DEVAM ET' : 'CONTINUE';
    if (widget.editMode) return _isTurkish ? 'KAYDET' : 'SAVE';
    return _isTurkish ? 'OYUNA BAŞLA' : 'START PLAYING';
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.step,
    required this.editMode,
    required this.isTurkish,
    required this.totalSteps,
    required this.accent,
    required this.onBack,
  });

  final int step;
  final bool editMode;
  final bool isTurkish;
  final int totalSteps;
  final Color accent;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final bool showBack = step > 0 || editMode;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 18, 4),
      child: Row(
        children: <Widget>[
          SizedBox.square(
            dimension: 46,
            child: showBack
                ? IconButton(
                    tooltip: isTurkish ? 'Geri' : 'Back',
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                  )
                : Center(
                    child: Icon(
                      Icons.psychology_alt_rounded,
                      color: accent,
                      size: 30,
                    ),
                  ),
          ),
          const Spacer(),
          for (int index = 0; index < totalSteps; index++) ...<Widget>[
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: index == step ? 28 : 9,
              height: 9,
              decoration: BoxDecoration(
                color: index <= step ? accent : StudioVisuals.line,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            if (index < totalSteps - 1) const SizedBox(width: 7),
          ],
          const Spacer(),
          SizedBox(
            width: 46,
            child: Text(
              '${step + 1}/$totalSteps',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: StudioVisuals.muted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgeStep extends StatelessWidget {
  const _AgeStep({
    required this.selected,
    required this.isTurkish,
    required this.accent,
    required this.surface,
    required this.onSelected,
    super.key,
  });

  final PlayerAgeGroup? selected;
  final bool isTurkish;
  final Color accent;
  final Color surface;
  final ValueChanged<PlayerAgeGroup> onSelected;

  @override
  Widget build(BuildContext context) {
    const List<PlayerAgeGroup> groups = PlayerAgeGroup.values;
    return _ChoiceStep<PlayerAgeGroup>(
      title: isTurkish ? 'Yaş grubun nedir?' : 'What is your age group?',
      subtitle: isTurkish
          ? 'Deneyimi sana daha uygun hazırlamak için bir aralık seç.'
          : 'Choose a range to help tailor your experience.',
      selected: selected,
      choices: groups,
      labelFor: (group) => switch (group) {
        PlayerAgeGroup.age6To8 => '6-8',
        PlayerAgeGroup.age9To12 => '9-12',
        PlayerAgeGroup.age13To17 => '13-17',
        PlayerAgeGroup.age18To40 => '18-40',
        PlayerAgeGroup.age40Plus => '40+',
        PlayerAgeGroup.preferNotToSay =>
          isTurkish ? 'Belirtmek istemiyorum' : 'Prefer not to say',
      },
      iconFor: (group) => switch (group) {
        PlayerAgeGroup.age6To8 => Icons.toys_rounded,
        PlayerAgeGroup.age9To12 => Icons.extension_rounded,
        PlayerAgeGroup.age13To17 => Icons.bolt_rounded,
        PlayerAgeGroup.age18To40 => Icons.rocket_launch_rounded,
        PlayerAgeGroup.age40Plus => Icons.auto_awesome_rounded,
        PlayerAgeGroup.preferNotToSay => Icons.shield_outlined,
      },
      accent: accent,
      surface: surface,
      onSelected: onSelected,
    );
  }
}

class _GoalStep extends StatelessWidget {
  const _GoalStep({
    required this.selected,
    required this.isTurkish,
    required this.accent,
    required this.surface,
    required this.onSelected,
    super.key,
  });

  final PlayerGameGoal? selected;
  final bool isTurkish;
  final Color accent;
  final Color surface;
  final ValueChanged<PlayerGameGoal> onSelected;

  @override
  Widget build(BuildContext context) {
    const List<PlayerGameGoal> goals = PlayerGameGoal.values;
    return _ChoiceStep<PlayerGameGoal>(
      title: isTurkish ? 'Oyun hedefin ne?' : 'What is your game goal?',
      subtitle: isTurkish
          ? 'Zeka Parkuru’nu kullanma amacını seç.'
          : 'Choose what you want from Zeka Parkuru.',
      selected: selected,
      choices: goals,
      labelFor: (goal) => switch (goal) {
        PlayerGameGoal.haveFun =>
          isTurkish ? 'Eğlenmek istiyorum' : 'I want to have fun',
        PlayerGameGoal.improveMind =>
          isTurkish
              ? 'Zihnimi geliştirmek istiyorum'
              : 'I want to improve my mind',
        PlayerGameGoal.dailyExercise =>
          isTurkish
              ? 'Günlük egzersiz yapmak istiyorum'
              : 'I want a daily mental workout',
        PlayerGameGoal.competeWithFriends =>
          isTurkish
              ? 'Arkadaşlarımla yarışmak istiyorum'
              : 'I want to compete with friends',
      },
      iconFor: (goal) => switch (goal) {
        PlayerGameGoal.haveFun => Icons.celebration_rounded,
        PlayerGameGoal.improveMind => Icons.psychology_rounded,
        PlayerGameGoal.dailyExercise => Icons.calendar_month_rounded,
        PlayerGameGoal.competeWithFriends => Icons.groups_rounded,
      },
      accent: accent,
      surface: surface,
      onSelected: onSelected,
    );
  }
}

class _ChoiceStep<T> extends StatelessWidget {
  const _ChoiceStep({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.choices,
    required this.labelFor,
    required this.iconFor,
    required this.accent,
    required this.surface,
    required this.onSelected,
  });

  final String title;
  final String subtitle;
  final T? selected;
  final List<T> choices;
  final String Function(T choice) labelFor;
  final IconData Function(T choice) iconFor;
  final Color accent;
  final Color surface;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: StudioVisuals.ink,
                fontSize: 27,
                height: 1.12,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: StudioVisuals.muted,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 22),
            for (final T choice in choices) ...<Widget>[
              _ChoiceTile(
                label: labelFor(choice),
                icon: iconFor(choice),
                selected: selected == choice,
                accent: accent,
                surface: surface,
                onTap: () => onSelected(choice),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.accent,
    required this.surface,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color accent;
  final Color surface;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? accent.withValues(alpha: 0.16) : surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? accent : StudioVisuals.line,
                width: selected ? 1.6 : 1,
              ),
              boxShadow: selected
                  ? <BoxShadow>[
                      BoxShadow(
                        color: accent.withValues(alpha: 0.20),
                        blurRadius: 18,
                        spreadRadius: 1,
                      ),
                    ]
                  : const <BoxShadow>[],
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: selected ? accent : StudioVisuals.surfaceSoft,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    icon,
                    color: selected ? Colors.white : StudioVisuals.teal,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: StudioVisuals.ink,
                      fontSize: 14.5,
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    key: ValueKey<bool>(selected),
                    color: selected ? accent : StudioVisuals.muted,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
