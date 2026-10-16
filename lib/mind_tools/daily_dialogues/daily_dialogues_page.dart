import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/studio_visuals.dart';
import 'dialogue_content.dart';
import 'dialogue_progress_store.dart';

class DailyDialoguesHomeCard extends StatelessWidget {
  const DailyDialoguesHomeCard({
    super.key,
    required this.isEnglish,
    required this.onTap,
  });

  final bool isEnglish;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: StudioVisuals.surface,
      borderRadius: StudioVisuals.cardRadius,
      border: Border.all(color: StudioVisuals.line),
    ),
    child: Row(
      children: <Widget>[
        SizedBox(
          width: 64,
          height: 64,
          child: Image.asset(
            'assets/branding/studio_tool_daily_dialogues.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                isEnglish ? 'REAL-LIFE PRACTICE' : 'GÜNLÜK YAŞAM PRATİĞİ',
                style: const TextStyle(
                  color: Color(0xFF527F9E),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isEnglish
                    ? 'Daily Conversation Tasks'
                    : 'Günlük Konuşma Görevleri',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: StudioVisuals.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                isEnglish
                    ? 'Practice clear, considerate choices in useful scenarios.'
                    : 'İşe yarar senaryolarda açık ve düşünceli yanıtları dene.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: StudioVisuals.muted,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        IconButton.filledTonal(
          key: const ValueKey<String>('daily_dialogues_open'),
          tooltip: isEnglish
              ? 'Open conversation practice'
              : 'Konuşma görevlerini aç',
          onPressed: onTap,
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFEAF2F6),
            foregroundColor: const Color(0xFF527F9E),
          ),
          icon: const Icon(Icons.arrow_forward_rounded),
        ),
      ],
    ),
  );
}

class DailyDialoguesPage extends StatefulWidget {
  const DailyDialoguesPage({super.key, this.progressStore});

  final DialogueProgressStore? progressStore;

  @override
  State<DailyDialoguesPage> createState() => _DailyDialoguesPageState();
}

class _DailyDialoguesPageState extends State<DailyDialoguesPage> {
  late final DialogueProgressStore _store =
      widget.progressStore ?? DialogueProgressStore();
  Map<String, int> _bestClarity = <String, int>{};
  bool _loading = true;

  bool get _english => context.l10n.isEnglish;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    try {
      final Map<String, int> progress = await _store.loadBestClarity();
      if (!mounted) return;
      setState(() {
        _bestClarity = progress;
        _loading = false;
      });
    } on FormatException {
      if (!mounted) return;
      setState(() => _loading = false);
      _message(
        _english
            ? 'Saved conversation progress was left untouched.'
            : 'Kayıtlı konuşma ilerlemesi silinmeden korundu.',
      );
    }
  }

  Future<void> _open(DialogueScenario scenario) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => DailyDialoguePracticePage(
          scenario: scenario,
          progressStore: _store,
        ),
      ),
    );
    await _reload();
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(value)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool english = _english;
    final int completed = _bestClarity.keys
        .where(
          (String id) => DailyDialogueLibrary.scenarios.any((s) => s.id == id),
        )
        .length;
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          english ? 'Daily conversations' : 'Günlük konuşmalar',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                children: <Widget>[
                  _DialogueOverview(
                    isEnglish: english,
                    completed: completed,
                    total: DailyDialogueLibrary.scenarios.length,
                  ),
                  const SizedBox(height: 19),
                  Text(
                    english ? 'Choose a situation' : 'Bir durum seç',
                    style: const TextStyle(
                      color: StudioVisuals.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (
                    int index = 0;
                    index < DailyDialogueLibrary.scenarios.length;
                    index++
                  ) ...<Widget>[
                    _DialogueScenarioTile(
                      scenario: DailyDialogueLibrary.scenarios[index],
                      index: index,
                      english: english,
                      bestClarity:
                          _bestClarity[DailyDialogueLibrary
                              .scenarios[index]
                              .id],
                      onTap: () => _open(DailyDialogueLibrary.scenarios[index]),
                    ),
                    const SizedBox(height: 9),
                  ],
                  const _DialogueOfflineNote(),
                ],
              ),
      ),
    );
  }
}

class _DialogueOverview extends StatelessWidget {
  const _DialogueOverview({
    required this.isEnglish,
    required this.completed,
    required this.total,
  });
  final bool isEnglish;
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[Colors.white, Color(0xFFF0F6F8)],
      ),
      borderRadius: StudioVisuals.cardRadius,
      border: Border.all(color: const Color(0xFFDCE9EE)),
      boxShadow: StudioVisuals.softShadow,
    ),
    child: Row(
      children: <Widget>[
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2F6),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.forum_outlined, color: Color(0xFF527F9E)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                isEnglish
                    ? 'Practice the conversation, not a script.'
                    : 'Ezberlenmiş replik değil, konuşma pratiği.',
                style: const TextStyle(
                  color: StudioVisuals.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isEnglish
                    ? 'Choices change the other person’s response. Work offline; no microphone is requested.'
                    : 'Seçimin karşı tarafın yanıtını değiştirir. Çevrimdışı çalışır; mikrofon izni istemez.',
                style: const TextStyle(
                  color: StudioVisuals.muted,
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$completed/$total',
          style: const TextStyle(
            color: Color(0xFF527F9E),
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _DialogueScenarioTile extends StatelessWidget {
  const _DialogueScenarioTile({
    required this.scenario,
    required this.index,
    required this.english,
    required this.bestClarity,
    required this.onTap,
  });

  final DialogueScenario scenario;
  final int index;
  final bool english;
  final int? bestClarity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: StudioVisuals.surface,
    borderRadius: StudioVisuals.compactRadius,
    child: InkWell(
      key: ValueKey<String>('dialogue_scenario_${scenario.id}'),
      onTap: onTap,
      borderRadius: StudioVisuals.compactRadius,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          borderRadius: StudioVisuals.compactRadius,
          border: Border.all(color: StudioVisuals.line),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2F6),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Center(
                child: bestClarity != null
                    ? const Icon(
                        Icons.check_rounded,
                        color: StudioVisuals.teal,
                        size: 20,
                      )
                    : Text(
                        '${index + 1}'.padLeft(2, '0'),
                        style: const TextStyle(
                          color: Color(0xFF527F9E),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    scenario.category(english),
                    style: const TextStyle(
                      color: Color(0xFF527F9E),
                      fontSize: 8,
                      letterSpacing: .55,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    scenario.title(english),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: StudioVisuals.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    bestClarity == null
                        ? (english
                              ? 'Branching dialogue · 2 decisions'
                              : 'Dallanan diyalog · 2 karar')
                        : (english
                              ? 'Best clarity $bestClarity / 4'
                              : 'En iyi netlik $bestClarity / 4'),
                    style: const TextStyle(
                      color: StudioVisuals.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              color: StudioVisuals.muted,
              size: 19,
            ),
          ],
        ),
      ),
    ),
  );
}

class _DialogueOfflineNote extends StatelessWidget {
  const _DialogueOfflineNote();

  @override
  Widget build(BuildContext context) {
    final bool english = context.l10n.isEnglish;
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Text(
        english
            ? 'Scenario choices and progress stay on this device. Speech input is not recorded.'
            : 'Senaryo seçimleri ve ilerleme bu cihazda kalır. Konuşma kaydı alınmaz.',
        style: const TextStyle(
          color: StudioVisuals.muted,
          fontSize: 10,
          height: 1.35,
        ),
      ),
    );
  }
}

class DailyDialoguePracticePage extends StatefulWidget {
  const DailyDialoguePracticePage({
    super.key,
    required this.scenario,
    required this.progressStore,
  });

  final DialogueScenario scenario;
  final DialogueProgressStore progressStore;

  @override
  State<DailyDialoguePracticePage> createState() =>
      _DailyDialoguePracticePageState();
}

class _DialogueExchange {
  const _DialogueExchange({
    required this.otherPerson,
    required this.reply,
    required this.response,
  });
  final String otherPerson;
  final String reply;
  final String response;
}

class _DailyDialoguePracticePageState extends State<DailyDialoguePracticePage> {
  late String _stepId = widget.scenario.startStepId;
  DialogueOption? _selected;
  final List<_DialogueExchange> _history = <_DialogueExchange>[];
  int _clarityPoints = 0;
  int _decisionCount = 0;
  bool _finished = false;
  String _ending = '';

  bool get _english => context.l10n.isEnglish;
  DialogueStep get _step => widget.scenario.steps[_stepId]!;

  void _choose(DialogueOption option) {
    if (_selected != null) return;
    setState(() {
      _selected = option;
      _clarityPoints += option.clarityPoints;
      _decisionCount++;
    });
  }

  Future<void> _continue() async {
    final DialogueOption? choice = _selected;
    if (choice == null) return;
    _history.add(
      _DialogueExchange(
        otherPerson: _step.otherPerson(_english),
        reply: choice.reply(_english),
        response: choice.response(_english),
      ),
    );
    final DialogueStep next = widget.scenario.steps[choice.nextStepId]!;
    if (next.isEnding) {
      await widget.progressStore.recordCompletion(
        widget.scenario.id,
        _clarityPoints.clamp(0, 4),
      );
      if (!mounted) return;
      setState(() {
        _ending = next.ending(_english);
        _finished = true;
      });
      return;
    }
    setState(() {
      _stepId = next.id;
      _selected = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool english = _english;
    if (_finished) return _buildFinished(english);
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.scenario.title(english),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        actions: <Widget>[
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${_decisionCount + 1}/2',
                style: const TextStyle(
                  color: StudioVisuals.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          key: const ValueKey<String>('dialogue_practice_scroll'),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: <Widget>[
            _DialogueSceneBanner(scenario: widget.scenario, isEnglish: english),
            const SizedBox(height: 14),
            for (final _DialogueExchange exchange in _history) ...<Widget>[
              _ChatBubble(text: exchange.otherPerson, fromOther: true),
              const SizedBox(height: 7),
              _ChatBubble(text: exchange.reply, fromOther: false),
              const SizedBox(height: 7),
              _ChatBubble(text: exchange.response, fromOther: true),
              const SizedBox(height: 13),
            ],
            _ChatBubble(text: _step.otherPerson(english), fromOther: true),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: StudioVisuals.surface,
                borderRadius: StudioVisuals.cardRadius,
                border: Border.all(color: StudioVisuals.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _step.prompt(english),
                    style: const TextStyle(
                      color: StudioVisuals.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 11),
                  for (
                    int index = 0;
                    index < _step.options.length;
                    index++
                  ) ...<Widget>[
                    _DialogueChoiceTile(
                      keyName: 'dialogue_choice_$index',
                      text: _step.options[index].reply(english),
                      selected: identical(_selected, _step.options[index]),
                      enabled: _selected == null,
                      onTap: () => _choose(_step.options[index]),
                    ),
                    if (index + 1 < _step.options.length)
                      const SizedBox(height: 8),
                  ],
                  if (_selected != null) ...<Widget>[
                    const SizedBox(height: 10),
                    _ChatBubble(
                      text: _selected!.response(english),
                      fromOther: true,
                    ),
                    const SizedBox(height: 9),
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: StudioVisuals.tealSoft,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Icon(
                            Icons.lightbulb_outline_rounded,
                            size: 17,
                            color: StudioVisuals.teal,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selected!.coaching(english),
                              style: const TextStyle(
                                color: StudioVisuals.ink,
                                fontSize: 11,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 11),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: const ValueKey<String>('dialogue_continue'),
                        onPressed: _continue,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF527F9E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        child: Text(
                          english
                              ? 'Continue conversation'
                              : 'Konuşmaya devam et',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              english
                  ? 'Communication clarity only · no game points, rankings or microphone recording.'
                  : 'Yalnızca iletişim netliği · oyun puanı, sıralama veya mikrofon kaydı yok.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: StudioVisuals.muted,
                fontSize: 9,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinished(bool english) => Scaffold(
    backgroundColor: StudioVisuals.canvas,
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: StudioVisuals.surface,
                borderRadius: StudioVisuals.cardRadius,
                border: Border.all(color: StudioVisuals.line),
                boxShadow: StudioVisuals.softShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 74,
                    height: 74,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAF2F6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.forum_rounded,
                      color: Color(0xFF527F9E),
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    english ? 'Conversation complete' : 'Konuşma tamamlandı',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: StudioVisuals.ink,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${english ? 'Clarity' : 'Netlik'} · $_clarityPoints / 4',
                    style: const TextStyle(
                      color: Color(0xFF527F9E),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _ending,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: StudioVisuals.muted,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        english ? 'Back to scenarios' : 'Senaryolara dön',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _DialogueSceneBanner extends StatelessWidget {
  const _DialogueSceneBanner({required this.scenario, required this.isEnglish});
  final DialogueScenario scenario;
  final bool isEnglish;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF2F6),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Icon(Icons.place_outlined, color: Color(0xFF527F9E), size: 19),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                scenario.category(isEnglish),
                style: const TextStyle(
                  color: Color(0xFF527F9E),
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                scenario.setting(isEnglish),
                style: const TextStyle(
                  color: StudioVisuals.ink,
                  fontSize: 11,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.text, required this.fromOther});
  final String text;
  final bool fromOther;

  @override
  Widget build(BuildContext context) => Align(
    alignment: fromOther ? Alignment.centerLeft : Alignment.centerRight,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * .82,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: fromOther ? StudioVisuals.surface : const Color(0xFFEAF2F6),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: Radius.circular(fromOther ? 4 : 15),
            bottomRight: Radius.circular(fromOther ? 15 : 4),
          ),
          border: Border.all(
            color: fromOther ? StudioVisuals.line : const Color(0xFFDCE9EE),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: StudioVisuals.ink,
            fontSize: 12,
            height: 1.35,
          ),
        ),
      ),
    ),
  );
}

class _DialogueChoiceTile extends StatelessWidget {
  const _DialogueChoiceTile({
    required this.keyName,
    required this.text,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String keyName;
  final String text;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? StudioVisuals.tealSoft : StudioVisuals.surface,
    borderRadius: BorderRadius.circular(13),
    child: InkWell(
      key: ValueKey<String>(keyName),
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected ? StudioVisuals.teal : StudioVisuals.line,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.chat_bubble_outline_rounded,
              color: selected ? StudioVisuals.teal : StudioVisuals.muted,
              size: 17,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: StudioVisuals.ink,
                  fontSize: 11,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
