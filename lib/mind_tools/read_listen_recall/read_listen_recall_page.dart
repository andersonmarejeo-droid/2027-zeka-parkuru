import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/studio_visuals.dart';
import '../vocabulary_notebook/vocabulary_notebook_store.dart';
import 'device_narration_service.dart';
import 'reader_content.dart';
import 'reader_progress_store.dart';

class ReadListenRecallHomeCard extends StatelessWidget {
  const ReadListenRecallHomeCard({
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
            'assets/branding/studio_tool_read_listen.png',
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
                isEnglish ? 'READ · LISTEN · RECALL' : 'OKU · DİNLE · HATIRLA',
                style: const TextStyle(
                  color: Color(0xFF6F63C8),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .55,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isEnglish
                    ? 'Micro-stories & comprehension'
                    : 'Mikro öyküler ve anlama',
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
                    ? 'Read or hear original short passages, then retrieve the details.'
                    : 'Özgün kısa metinleri oku ya da dinle, ardından ayrıntıları hatırla.',
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
          key: const ValueKey<String>('read_listen_recall_open'),
          tooltip: isEnglish ? 'Open reading practice' : 'Okuma çalışmasını aç',
          onPressed: onTap,
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFEDEBF8),
            foregroundColor: const Color(0xFF6F63C8),
          ),
          icon: const Icon(Icons.arrow_forward_rounded),
        ),
      ],
    ),
  );
}

class ReadListenRecallPage extends StatefulWidget {
  const ReadListenRecallPage({super.key, this.progressStore});

  final ReaderProgressStore? progressStore;

  @override
  State<ReadListenRecallPage> createState() => _ReadListenRecallPageState();
}

class _ReadListenRecallPageState extends State<ReadListenRecallPage> {
  late final ReaderProgressStore _progress =
      widget.progressStore ?? ReaderProgressStore();
  Set<String> _completed = <String>{};
  Map<String, ReaderReviewSchedule> _reviewSchedules =
      <String, ReaderReviewSchedule>{};
  bool _loading = true;

  bool get _english => context.l10n.isEnglish;

  bool _isDueForReview(String storyId) {
    final ReaderReviewSchedule? schedule = _reviewSchedules[storyId];
    return schedule != null && !schedule.dueAt.isAfter(DateTime.now());
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final Set<String> completed = await _progress.completedStoryIds();
      Map<String, ReaderReviewSchedule> reviews =
          <String, ReaderReviewSchedule>{};
      try {
        reviews = await _progress.ensureReviewSchedulesFor(completed);
      } on FormatException {
        // Keep completion progress available if only the new review schedule is
        // malformed; the stored value is never silently overwritten.
      }
      if (!mounted) return;
      setState(() {
        _completed = completed;
        _reviewSchedules = reviews;
        _loading = false;
      });
    } on FormatException {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _open(RecallArticle article) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            ReadListenStoryPage(article: article, progressStore: _progress),
      ),
    );
    await _load();
  }

  Future<void> _openReview(RecallArticle article) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ReadListenRecallReviewPage(
          article: article,
          progressStore: _progress,
        ),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final bool english = _english;
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          english ? 'Read · Listen · Recall' : 'Oku · Dinle · Hatırla',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 26),
                children: <Widget>[
                  _ReaderOverview(
                    isEnglish: english,
                    completed: _completed.length,
                    total: RecallArticleLibrary.articles.length,
                  ),
                  const SizedBox(height: 19),
                  Text(
                    english ? 'Choose a short story' : 'Kısa bir metin seç',
                    style: const TextStyle(
                      color: StudioVisuals.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (
                    int index = 0;
                    index < RecallArticleLibrary.articles.length;
                    index++
                  ) ...<Widget>[
                    _ReaderArticleTile(
                      article: RecallArticleLibrary.articles[index],
                      index: index,
                      isEnglish: english,
                      completed: _completed.contains(
                        RecallArticleLibrary.articles[index].id,
                      ),
                      dueForReview: _isDueForReview(
                        RecallArticleLibrary.articles[index].id,
                      ),
                      onTap: () => _open(RecallArticleLibrary.articles[index]),
                      onReviewTap: () =>
                          _openReview(RecallArticleLibrary.articles[index]),
                    ),
                    const SizedBox(height: 9),
                  ],
                  const _ReaderLocalNote(),
                ],
              ),
      ),
    );
  }
}

class _ReaderOverview extends StatelessWidget {
  const _ReaderOverview({
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
        colors: <Color>[Colors.white, Color(0xFFF2F0FC)],
      ),
      borderRadius: StudioVisuals.cardRadius,
      border: Border.all(color: const Color(0xFFE5E1F2)),
      boxShadow: StudioVisuals.softShadow,
    ),
    child: Row(
      children: <Widget>[
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEDEBF8),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.headphones_rounded, color: Color(0xFF6F63C8)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                isEnglish
                    ? 'Original passages. Active recall.'
                    : 'Özgün metin. Etkin hatırlama.',
                style: const TextStyle(
                  color: StudioVisuals.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isEnglish
                    ? 'Read at your pace or use the device’s installed voice.'
                    : 'Kendi hızında oku veya cihazındaki kurulu sesi dinle.',
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
            color: Color(0xFF6F63C8),
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _ReaderArticleTile extends StatelessWidget {
  const _ReaderArticleTile({
    required this.article,
    required this.index,
    required this.isEnglish,
    required this.completed,
    required this.dueForReview,
    required this.onTap,
    required this.onReviewTap,
  });

  final RecallArticle article;
  final int index;
  final bool isEnglish;
  final bool completed;
  final bool dueForReview;
  final VoidCallback onTap;
  final VoidCallback onReviewTap;

  @override
  Widget build(BuildContext context) => Material(
    color: StudioVisuals.surface,
    borderRadius: StudioVisuals.compactRadius,
    child: InkWell(
      key: ValueKey<String>('reader_article_${article.id}'),
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
                color: const Color(0xFFEDEBF8),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Center(
                child: completed
                    ? const Icon(
                        Icons.check_rounded,
                        color: StudioVisuals.teal,
                        size: 20,
                      )
                    : Text(
                        '${index + 1}'.padLeft(2, '0'),
                        style: const TextStyle(
                          color: Color(0xFF6F63C8),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
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
                    article.category(isEnglish),
                    style: const TextStyle(
                      color: Color(0xFF6F63C8),
                      fontSize: 8,
                      letterSpacing: .55,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    article.title(isEnglish),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: StudioVisuals.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    dueForReview
                        ? (isEnglish
                              ? 'Recall review due · 1 min'
                              : 'Hatırlama zamanı · 1 dk')
                        : isEnglish
                        ? '2 recall questions · 3 min'
                        : '2 hatırlama sorusu · 3 dk',
                    style: const TextStyle(
                      color: StudioVisuals.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (dueForReview)
              IconButton(
                key: ValueKey<String>('reader_review_${article.id}'),
                tooltip: isEnglish
                    ? 'Start recall review'
                    : 'Hatırlama turunu başlat',
                onPressed: onReviewTap,
                color: const Color(0xFF6F63C8),
                icon: const Icon(Icons.psychology_alt_rounded),
              )
            else
              Icon(
                completed
                    ? Icons.check_circle_rounded
                    : Icons.arrow_forward_rounded,
                color: completed ? StudioVisuals.teal : StudioVisuals.muted,
                size: 19,
              ),
          ],
        ),
      ),
    ),
  );
}

class _ReaderLocalNote extends StatelessWidget {
  const _ReaderLocalNote();

  @override
  Widget build(BuildContext context) {
    final bool english = context.l10n.isEnglish;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        english
            ? 'The stories and question progress work offline. Speech uses the voice installed on your Android device.'
            : 'Öyküler ve soru ilerlemesi çevrimdışı çalışır. Seslendirme Android cihazına kurulu sesi kullanır.',
        style: const TextStyle(
          color: StudioVisuals.muted,
          fontSize: 10,
          height: 1.35,
        ),
      ),
    );
  }
}

class ReadListenStoryPage extends StatefulWidget {
  const ReadListenStoryPage({
    super.key,
    required this.article,
    required this.progressStore,
  });

  final RecallArticle article;
  final ReaderProgressStore progressStore;

  @override
  State<ReadListenStoryPage> createState() => _ReadListenStoryPageState();
}

class _ReadListenStoryPageState extends State<ReadListenStoryPage> {
  final DeviceNarrationService _narration = DeviceNarrationService();
  final VocabularyNotebookStore _vocabulary = VocabularyNotebookStore();
  int _questionIndex = 0;
  int? _selected;
  bool _speaking = false;
  bool _complete = false;
  bool _savingWord = false;
  String? _audioMessage;

  bool get _english => context.l10n.isEnglish;
  List<RecallQuestion> get _questions => widget.article.questions(_english);
  RecallQuestion get _question => _questions[_questionIndex];

  Future<void> _toggleSpeech() async {
    if (_speaking) {
      await _narration.stop();
      if (mounted) setState(() => _speaking = false);
      return;
    }
    final bool started = await _narration.speak(
      text: widget.article.body(_english),
      languageTag: _english ? 'en-US' : 'tr-TR',
      onFinished: () {
        if (mounted) setState(() => _speaking = false);
      },
    );
    if (!mounted) return;
    setState(() {
      _speaking = started;
      _audioMessage = started
          ? null
          : (_english
                ? 'No compatible device voice is installed. You can still read the passage.'
                : 'Uygun cihaz sesi kurulu değil. Metni okuyarak devam edebilirsin.');
    });
  }

  void _answer(int index) {
    setState(() => _selected = index);
  }

  Future<void> _continue() async {
    if (_selected != _question.correctIndex) return;
    if (_questionIndex + 1 < _questions.length) {
      setState(() {
        _questionIndex++;
        _selected = null;
      });
      return;
    }
    await widget.progressStore.markCompleted(widget.article.id);
    if (mounted) setState(() => _complete = true);
  }

  Future<void> _saveWord() async {
    if (_savingWord) return;
    setState(() => _savingWord = true);
    try {
      await _vocabulary.add(
        word: widget.article.word(_english),
        meaning: widget.article.meaning(_english),
        example: widget.article.example(_english),
      );
      _message(
        _english
            ? 'Word saved to your notebook on this device.'
            : 'Kelime bu cihazdaki defterine kaydedildi.',
      );
    } on StateError {
      _message(
        _english
            ? 'That word is already in your notebook.'
            : 'Bu kelime defterinde zaten var.',
      );
    } finally {
      if (mounted) setState(() => _savingWord = false);
    }
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: Text(value)),
      );
  }

  @override
  void dispose() {
    _narration.stop();
    _narration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool english = _english;
    if (_complete) return _buildComplete(english);
    final int selected = _selected ?? -1;
    final bool answerCorrect = selected == _question.correctIndex;
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.article.title(english),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          key: const ValueKey<String>('reader_story_scroll'),
          padding: const EdgeInsets.fromLTRB(17, 8, 17, 30),
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    widget.article.category(english),
                    style: const TextStyle(
                      color: Color(0xFF6F63C8),
                      fontSize: 9,
                      letterSpacing: .7,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  english ? 'ORIGINAL · OFFLINE' : 'ÖZGÜN · ÇEVRİMDIŞI',
                  style: const TextStyle(
                    color: StudioVisuals.muted,
                    fontSize: 8,
                    letterSpacing: .4,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.article.title(english),
              style: const TextStyle(
                color: StudioVisuals.ink,
                fontSize: 23,
                fontWeight: FontWeight.w900,
                letterSpacing: -.3,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const ValueKey<String>('reader_play_audio'),
              onPressed: _toggleSpeech,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6F63C8),
                backgroundColor: const Color(0xFFEDEBF8),
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: Icon(
                _speaking ? Icons.stop_rounded : Icons.volume_up_rounded,
              ),
              label: Text(
                _speaking
                    ? (english ? 'Stop narration' : 'Seslendirmeyi durdur')
                    : (english
                          ? 'Listen to this passage'
                          : 'Metni sesli dinle'),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            if (_audioMessage != null) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                _audioMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: StudioVisuals.muted,
                  fontSize: 10,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: StudioVisuals.surface,
                borderRadius: StudioVisuals.cardRadius,
                border: Border.all(color: StudioVisuals.line),
                boxShadow: StudioVisuals.softShadow,
              ),
              child: Text(
                widget.article.body(english),
                style: const TextStyle(
                  color: StudioVisuals.ink,
                  fontSize: 14,
                  height: 1.62,
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              key: const ValueKey<String>('reader_save_word'),
              onPressed: _savingWord ? null : _saveWord,
              style: OutlinedButton.styleFrom(
                foregroundColor: StudioVisuals.teal,
                alignment: Alignment.centerLeft,
                side: const BorderSide(color: Color(0xFFDDEBE9)),
              ),
              icon: const Icon(Icons.bookmark_add_outlined),
              label: Text(
                english
                    ? 'Save “${widget.article.word(english)}” to Vocabulary Notebook'
                    : '“${widget.article.word(english)}” kelimesini Kelime Defteri’ne ekle',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 19),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    english ? 'Recall check' : 'Hatırlama kontrolü',
                    style: const TextStyle(
                      color: StudioVisuals.ink,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '${_questionIndex + 1}/${_questions.length}',
                  style: const TextStyle(
                    color: StudioVisuals.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              _question.prompt,
              style: const TextStyle(
                color: StudioVisuals.ink,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 9),
            for (
              int index = 0;
              index < _question.options.length;
              index++
            ) ...<Widget>[
              _ReaderAnswerOption(
                keyName: 'reader_answer_$index',
                text: _question.options[index],
                selected: selected == index,
                correct: index == _question.correctIndex,
                submitted: _selected != null,
                onTap: () => _answer(index),
              ),
              const SizedBox(height: 7),
            ],
            if (_selected != null) ...<Widget>[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: answerCorrect
                      ? StudioVisuals.tealSoft
                      : StudioVisuals.amberSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${answerCorrect ? (english ? 'Correct. ' : 'Doğru. ') : (english ? 'Look again. ' : 'Bir daha düşün. ')}${_question.evidence}',
                  style: const TextStyle(
                    color: StudioVisuals.ink,
                    fontSize: 11,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (answerCorrect) ...<Widget>[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const ValueKey<String>('reader_continue'),
                    onPressed: _continue,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6F63C8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      _questionIndex + 1 < _questions.length
                          ? (english ? 'Next question' : 'Sonraki soru')
                          : (english ? 'Finish story' : 'Metni tamamla'),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildComplete(bool english) => Scaffold(
    backgroundColor: StudioVisuals.canvas,
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                  color: Color(0xFFEDEBF8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: Color(0xFF6F63C8),
                  size: 42,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                english ? 'Story remembered' : 'Metin akılda kaldı',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: StudioVisuals.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                english
                    ? 'You completed both evidence-based questions. Your progress is saved on this device.'
                    : 'Kanıta dayalı iki soruyu da tamamladın. İlerlemen bu cihaza kaydedildi.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: StudioVisuals.muted,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(english ? 'Back to stories' : 'Metinlere dön'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class ReadListenRecallReviewPage extends StatefulWidget {
  const ReadListenRecallReviewPage({
    super.key,
    required this.article,
    required this.progressStore,
  });

  final RecallArticle article;
  final ReaderProgressStore progressStore;

  @override
  State<ReadListenRecallReviewPage> createState() =>
      _ReadListenRecallReviewPageState();
}

class _ReadListenRecallReviewPageState
    extends State<ReadListenRecallReviewPage> {
  int _questionIndex = 0;
  int? _selected;
  bool _missedAny = false;
  bool _saving = false;
  ReaderReviewSchedule? _nextReview;

  bool get _english => context.l10n.isEnglish;
  List<RecallQuestion> get _questions => widget.article.questions(_english);
  RecallQuestion get _question => _questions[_questionIndex];

  void _answer(int index) {
    if (_selected == _question.correctIndex) return;
    setState(() {
      _selected = index;
      if (index != _question.correctIndex) _missedAny = true;
    });
  }

  Future<void> _continue() async {
    if (_selected != _question.correctIndex || _saving) return;
    if (_questionIndex + 1 < _questions.length) {
      setState(() {
        _questionIndex++;
        _selected = null;
      });
      return;
    }
    setState(() => _saving = true);
    try {
      final ReaderReviewSchedule schedule = await widget.progressStore
          .recordReview(storyId: widget.article.id, rememberedAll: !_missedAny);
      if (!mounted) return;
      setState(() {
        _nextReview = schedule;
        _saving = false;
      });
    } on StateError {
      if (!mounted) return;
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool english = _english;
    final ReaderReviewSchedule? completed = _nextReview;
    if (completed != null) return _buildComplete(english, completed);
    final bool answeredCorrectly = _selected == _question.correctIndex;
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          english ? 'Delayed recall' : 'Gecikmeli hatırlama',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          key: const ValueKey<String>('reader_delayed_recall_scroll'),
          padding: const EdgeInsets.fromLTRB(17, 8, 17, 30),
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Colors.white, Color(0xFFF2F0FC)],
                ),
                borderRadius: StudioVisuals.cardRadius,
                border: Border.all(color: const Color(0xFFE5E1F2)),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDEBF8),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.psychology_alt_rounded,
                      color: Color(0xFF6F63C8),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          widget.article.title(english),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: StudioVisuals.ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          english
                              ? 'Recall without reopening the passage'
                              : 'Metni yeniden açmadan hatırla',
                          style: const TextStyle(
                            color: StudioVisuals.muted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    '${_questionIndex + 1}/${_questions.length}',
                    style: const TextStyle(
                      color: Color(0xFF6F63C8),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: StudioVisuals.surface,
                borderRadius: StudioVisuals.cardRadius,
                border: Border.all(color: StudioVisuals.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    _question.prompt,
                    style: const TextStyle(
                      color: StudioVisuals.ink,
                      fontSize: 17,
                      height: 1.35,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 13),
                  for (int index = 0; index < _question.options.length; index++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ReaderAnswerOption(
                        keyName: 'reader_review_answer_$index',
                        text: _question.options[index],
                        selected: _selected == index,
                        correct: index == _question.correctIndex,
                        submitted: _selected != null,
                        onTap: () => _answer(index),
                      ),
                    ),
                  if (_selected != null) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      answeredCorrectly
                          ? _question.evidence
                          : (english
                                ? 'Try another answer; the passage is still hidden.'
                                : 'Başka bir yanıtı dene; metin hâlâ gizli.'),
                      style: TextStyle(
                        color: answeredCorrectly
                            ? StudioVisuals.teal
                            : StudioVisuals.muted,
                        fontSize: 11,
                        height: 1.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 9),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            const _ReaderLocalNote(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(17, 10, 17, 8),
          decoration: const BoxDecoration(
            color: StudioVisuals.surface,
            border: Border(top: BorderSide(color: StudioVisuals.line)),
          ),
          child: FilledButton(
            key: const ValueKey<String>('reader_review_continue'),
            onPressed: answeredCorrectly && !_saving ? _continue : null,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6F63C8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            child: Text(
              _saving
                  ? (english ? 'Saving…' : 'Kaydediliyor…')
                  : _questionIndex + 1 < _questions.length
                  ? (english
                        ? 'Next recall question'
                        : 'Sonraki hatırlama sorusu')
                  : (english
                        ? 'Finish recall review'
                        : 'Hatırlama turunu bitir'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComplete(bool english, ReaderReviewSchedule next) => Scaffold(
    backgroundColor: StudioVisuals.canvas,
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  color: Color(0xFFEDEBF8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  color: Color(0xFF6F63C8),
                  size: 38,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                english
                    ? 'Recall review complete'
                    : 'Hatırlama turu tamamlandı',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: StudioVisuals.ink,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                english
                    ? 'Next local review in ${next.intervalDays} day(s). Your reading passage was not shown.'
                    : 'Sonraki yerel hatırlama ${next.intervalDays} gün sonra. Okuma metni gösterilmedi.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: StudioVisuals.muted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(english ? 'Back to stories' : 'Metinlere dön'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ReaderAnswerOption extends StatelessWidget {
  const _ReaderAnswerOption({
    required this.keyName,
    required this.text,
    required this.selected,
    required this.correct,
    required this.submitted,
    required this.onTap,
  });

  final String keyName;
  final String text;
  final bool selected;
  final bool correct;
  final bool submitted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color border = selected
        ? (correct ? StudioVisuals.teal : StudioVisuals.amber)
        : StudioVisuals.line;
    return Material(
      color: selected
          ? (correct ? StudioVisuals.tealSoft : StudioVisuals.amberSoft)
          : StudioVisuals.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: ValueKey<String>(keyName),
        onTap: submitted && selected && correct ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                selected
                    ? (correct
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_checked_rounded)
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? border : StudioVisuals.muted,
                size: 18,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: StudioVisuals.ink,
                    fontSize: 12,
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
}
