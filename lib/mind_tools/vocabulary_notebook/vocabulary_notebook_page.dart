import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/studio_visuals.dart';
import 'vocabulary_card.dart';
import 'vocabulary_notebook_store.dart';

class VocabularyNotebookHomeCard extends StatelessWidget {
  const VocabularyNotebookHomeCard({
    super.key,
    required this.isEnglish,
    required this.onTap,
  });

  final bool isEnglish;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: StudioVisuals.surface,
        borderRadius: StudioVisuals.cardRadius,
        border: Border.all(color: StudioVisuals.line),
        boxShadow: StudioVisuals.softShadow,
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 64,
            height: 64,
            child: Image.asset(
              'assets/branding/studio_tool_vocabulary_notebook.png',
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
                  isEnglish ? 'Mind tools' : 'Zihin araçları',
                  style: const TextStyle(
                    color: StudioVisuals.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .55,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isEnglish
                      ? 'Smart Vocabulary Notebook'
                      : 'Akıllı Kelime Defteri',
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
                      ? 'Save your own words and review them on time.'
                      : 'Kendi kelimelerini kaydet, zamanı gelince geri çağır.',
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
          const SizedBox(width: 8),
          IconButton.filledTonal(
            key: const ValueKey<String>('vocabulary_notebook_open'),
            tooltip: isEnglish ? 'Open notebook' : 'Defteri aç',
            onPressed: onTap,
            style: IconButton.styleFrom(
              backgroundColor: StudioVisuals.tealSoft,
              foregroundColor: StudioVisuals.teal,
            ),
            icon: const Icon(Icons.arrow_forward_rounded),
          ),
        ],
      ),
    );
  }
}

class VocabularyNotebookPage extends StatefulWidget {
  const VocabularyNotebookPage({super.key, this.store});

  final VocabularyNotebookStore? store;

  @override
  State<VocabularyNotebookPage> createState() => _VocabularyNotebookPageState();
}

class _VocabularyNotebookPageState extends State<VocabularyNotebookPage> {
  late final VocabularyNotebookStore _store;
  final TextEditingController _searchController = TextEditingController();
  List<VocabularyCard> _cards = <VocabularyCard>[];
  bool _loading = true;
  String _query = '';

  bool get _english => context.l10n.isEnglish;
  List<VocabularyCard> get _dueCards => _cards
      .where((VocabularyCard card) => card.isDueAt(DateTime.now()))
      .toList(growable: false);
  List<VocabularyCard> get _visibleCards {
    final String query = _query.trim().toLowerCase();
    if (query.isEmpty) return _cards;
    return _cards
        .where(
          (VocabularyCard card) =>
              card.word.toLowerCase().contains(query) ||
              card.meaning.toLowerCase().contains(query) ||
              card.example.toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _store = widget.store ?? VocabularyNotebookStore();
    _reload();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    try {
      final List<VocabularyCard> cards = await _store.loadAll();
      cards.sort((VocabularyCard a, VocabularyCard b) {
        final int dueOrder = a.dueAt.compareTo(b.dueAt);
        return dueOrder != 0
            ? dueOrder
            : a.word.toLowerCase().compareTo(b.word.toLowerCase());
      });
      if (!mounted) return;
      setState(() {
        _cards = cards;
        _loading = false;
      });
    } on FormatException {
      if (!mounted) return;
      setState(() => _loading = false);
      _message(
        _english
            ? 'The notebook data could not be read. Your local data was kept safe.'
            : 'Defter verisi okunamadı. Cihazdaki kayıt silinmeden korundu.',
      );
    }
  }

  Future<void> _editCard({VocabularyCard? card}) async {
    final _VocabularyEditorValue? value =
        await showDialog<_VocabularyEditorValue>(
          context: context,
          builder: (BuildContext context) =>
              _VocabularyEditorDialog(isEnglish: _english, initial: card),
        );
    if (value == null) return;
    try {
      if (card == null) {
        await _store.add(
          word: value.word,
          meaning: value.meaning,
          example: value.example,
        );
      } else {
        await _store.update(
          id: card.id,
          word: value.word,
          meaning: value.meaning,
          example: value.example,
        );
      }
      await _reload();
      if (mounted) {
        _message(
          _english
              ? (card == null ? 'Word saved on this device.' : 'Word updated.')
              : (card == null
                    ? 'Kelime bu cihaza kaydedildi.'
                    : 'Kelime güncellendi.'),
        );
      }
    } on StateError catch (error) {
      _message(
        error.message.toString().contains('already')
            ? (_english
                  ? 'That word is already in your notebook.'
                  : 'Bu kelime defterinde zaten var.')
            : (_english
                  ? 'The word could not be saved.'
                  : 'Kelime kaydedilemedi.'),
      );
    } on ArgumentError {
      _message(
        _english
            ? 'Enter both the word and its meaning.'
            : 'Kelimeyi ve anlamını birlikte gir.',
      );
    }
  }

  Future<void> _deleteCard(VocabularyCard card) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(_english ? 'Delete this word?' : 'Bu kelime silinsin mi?'),
        content: Text(
          _english
              ? '“${card.word}” will be removed from this device.'
              : '“${card.word}” bu cihazdaki defterden kaldırılacak.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_english ? 'Keep' : 'Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_english ? 'Delete' : 'Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _store.delete(card.id);
    await _reload();
  }

  Future<void> _startReview() async {
    final List<VocabularyCard> due = await _store.dueCards();
    if (!mounted) return;
    if (due.isEmpty) {
      _message(
        _english
            ? 'Nothing is due right now. Your next review stays on schedule.'
            : 'Şu anda tekrar zamanı gelen kelime yok. Sonraki tekrar planlandığı gibi kalacak.',
      );
      return;
    }
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => VocabularyReviewSessionPage(
          cards: due,
          store: _store,
          isEnglish: _english,
        ),
      ),
    );
    await _reload();
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final bool english = _english;
    final List<VocabularyCard> due = _dueCards;
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          english ? 'Vocabulary notebook' : 'Kelime defteri',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                color: StudioVisuals.teal,
                onRefresh: _reload,
                child: ListView(
                  key: const ValueKey<String>('vocabulary_notebook_scroll'),
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 112),
                  children: <Widget>[
                    _NotebookHero(
                      isEnglish: english,
                      cardCount: _cards.length,
                      dueCount: due.length,
                      onReview: _startReview,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            english ? 'Your words' : 'Kelimelerin',
                            style: const TextStyle(
                              color: StudioVisuals.ink,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -.25,
                            ),
                          ),
                        ),
                        Text(
                          '${_cards.length} ${english ? 'saved' : 'kayıt'}',
                          style: const TextStyle(
                            color: StudioVisuals.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      key: const ValueKey<String>('vocabulary_search'),
                      controller: _searchController,
                      onChanged: (String value) =>
                          setState(() => _query = value),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: english
                            ? 'Search word, meaning or example'
                            : 'Kelime, anlam veya örnek ara',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: StudioVisuals.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: StudioVisuals.line,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: StudioVisuals.line,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_visibleCards.isEmpty)
                      _NotebookEmptyState(
                        isEnglish: english,
                        hasSearch: _query.trim().isNotEmpty,
                        onAdd: () => _editCard(),
                      )
                    else
                      for (final VocabularyCard card
                          in _visibleCards) ...<Widget>[
                        _VocabularyWordTile(
                          card: card,
                          isEnglish: english,
                          onEdit: () => _editCard(card: card),
                          onDelete: () => _deleteCard(card),
                        ),
                        const SizedBox(height: 9),
                      ],
                    const SizedBox(height: 16),
                    const _PrivacyNote(),
                  ],
                ),
              ),
      ),
      floatingActionButton: _loading
          ? null
          : FloatingActionButton.extended(
              key: const ValueKey<String>('vocabulary_add'),
              onPressed: () => _editCard(),
              backgroundColor: StudioVisuals.teal,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text(english ? 'Add a word' : 'Kelime ekle'),
            ),
    );
  }
}

class _NotebookHero extends StatelessWidget {
  const _NotebookHero({
    required this.isEnglish,
    required this.cardCount,
    required this.dueCount,
    required this.onReview,
  });

  final bool isEnglish;
  final int cardCount;
  final int dueCount;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final bool english = isEnglish;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFFFFFFF), Color(0xFFEFF7F7)],
        ),
        borderRadius: StudioVisuals.cardRadius,
        border: Border.all(color: const Color(0xFFDDEBE9)),
        boxShadow: StudioVisuals.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: StudioVisuals.tealSoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: StudioVisuals.teal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  english
                      ? 'A little, often, stays longer.'
                      : 'Azar azar, uzun süre akılda kalır.',
                  style: const TextStyle(
                    color: StudioVisuals.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '$cardCount',
                style: const TextStyle(
                  color: StudioVisuals.teal,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            english
                ? 'Recall first, reveal the meaning, then choose how well you knew it. Reviews are scheduled on this device.'
                : 'Önce hatırlamaya çalış, sonra anlamı aç ve ne kadar bildiğini seç. Tekrarlar bu cihazda planlanır.',
            style: const TextStyle(
              color: StudioVisuals.muted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  english
                      ? '$dueCount ready to review'
                      : '$dueCount kelime tekrar için hazır',
                  style: const TextStyle(
                    color: StudioVisuals.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              FilledButton.icon(
                key: const ValueKey<String>('vocabulary_review_button'),
                onPressed: dueCount == 0 ? null : onReview,
                style: FilledButton.styleFrom(
                  backgroundColor: StudioVisuals.teal,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: StudioVisuals.surfaceSoft,
                  disabledForegroundColor: StudioVisuals.muted,
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 19),
                label: Text(english ? 'Review' : 'Tekrar et'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VocabularyWordTile extends StatelessWidget {
  const _VocabularyWordTile({
    required this.card,
    required this.isEnglish,
    required this.onEdit,
    required this.onDelete,
  });

  final VocabularyCard card;
  final bool isEnglish;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final bool due = card.isDueAt(DateTime.now());
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 8, 12),
      decoration: BoxDecoration(
        color: StudioVisuals.surface,
        borderRadius: StudioVisuals.compactRadius,
        border: Border.all(color: StudioVisuals.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: due ? StudioVisuals.amberSoft : StudioVisuals.tealSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              due ? Icons.schedule_rounded : Icons.check_rounded,
              color: due ? StudioVisuals.amber : StudioVisuals.teal,
              size: 18,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  card.word,
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
                  card.meaning,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: StudioVisuals.muted,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
                if (card.example.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 5),
                  Text(
                    '“${card.example}”',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: StudioVisuals.muted,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      height: 1.25,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  due
                      ? (isEnglish ? 'DUE NOW' : 'TEKRAR ZAMANI')
                      : (isEnglish
                            ? 'NEXT · ${_relativeDue(card.dueAt, english: true)}'
                            : 'SONRAKİ · ${_relativeDue(card.dueAt, english: false)}'),
                  style: TextStyle(
                    color: due ? StudioVisuals.amber : StudioVisuals.teal,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .4,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: isEnglish ? 'Word actions' : 'Kelime işlemleri',
            onSelected: (String value) {
              if (value == 'edit') onEdit();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'edit',
                child: Text(isEnglish ? 'Edit' : 'Düzenle'),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Text(isEnglish ? 'Delete' : 'Sil'),
              ),
            ],
            icon: const Icon(
              Icons.more_horiz_rounded,
              color: StudioVisuals.muted,
            ),
          ),
        ],
      ),
    );
  }

  String _relativeDue(DateTime date, {required bool english}) {
    final Duration remaining = date.difference(DateTime.now());
    if (remaining.inMinutes < 60) {
      final int minutes = remaining.inMinutes.clamp(1, 59);
      return english ? 'in $minutes min' : '$minutes dk sonra';
    }
    if (remaining.inHours < 24) {
      final int hours = remaining.inHours.clamp(1, 23);
      return english ? 'in $hours h' : '$hours sa sonra';
    }
    final int days = (remaining.inHours / 24).ceil();
    return english ? 'in $days d' : '$days gün sonra';
  }
}

class _NotebookEmptyState extends StatelessWidget {
  const _NotebookEmptyState({
    required this.isEnglish,
    required this.hasSearch,
    required this.onAdd,
  });

  final bool isEnglish;
  final bool hasSearch;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: StudioVisuals.surface,
      borderRadius: StudioVisuals.cardRadius,
      border: Border.all(color: StudioVisuals.line),
    ),
    child: Column(
      children: <Widget>[
        Icon(
          hasSearch ? Icons.search_off_rounded : Icons.menu_book_rounded,
          size: 34,
          color: StudioVisuals.teal,
        ),
        const SizedBox(height: 10),
        Text(
          hasSearch
              ? (isEnglish ? 'No matching words' : 'Eşleşen kelime yok')
              : (isEnglish
                    ? 'Start your own word collection'
                    : 'Kendi kelime koleksiyonunu oluştur'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: StudioVisuals.ink,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          hasSearch
              ? (isEnglish ? 'Try another search.' : 'Başka bir arama dene.')
              : (isEnglish
                    ? 'Add a word you want to remember, its meaning, and a sentence that makes it stick.'
                    : 'Hatırlamak istediğin kelimeyi, anlamını ve akılda kalmasını sağlayan bir örnek cümleyi ekle.'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: StudioVisuals.muted,
            fontSize: 12,
            height: 1.4,
          ),
        ),
        if (!hasSearch) ...<Widget>[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: Text(isEnglish ? 'Add the first word' : 'İlk kelimeyi ekle'),
          ),
        ],
      ],
    ),
  );
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    final bool english = context.l10n.isEnglish;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: StudioVisuals.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.phonelink_lock_rounded,
            size: 18,
            color: StudioVisuals.muted,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              english
                  ? 'Your words stay on this device. They are not added to game scores or leaderboards.'
                  : 'Kelimelerin bu cihazda kalır; oyun puanına veya liderlik tablosuna eklenmez.',
              style: const TextStyle(
                color: StudioVisuals.muted,
                fontSize: 10,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VocabularyEditorValue {
  const _VocabularyEditorValue(this.word, this.meaning, this.example);
  final String word;
  final String meaning;
  final String example;
}

class _VocabularyEditorDialog extends StatefulWidget {
  const _VocabularyEditorDialog({required this.isEnglish, this.initial});

  final bool isEnglish;
  final VocabularyCard? initial;

  @override
  State<_VocabularyEditorDialog> createState() =>
      _VocabularyEditorDialogState();
}

class _VocabularyEditorDialogState extends State<_VocabularyEditorDialog> {
  late final TextEditingController _word = TextEditingController(
    text: widget.initial?.word ?? '',
  );
  late final TextEditingController _meaning = TextEditingController(
    text: widget.initial?.meaning ?? '',
  );
  late final TextEditingController _example = TextEditingController(
    text: widget.initial?.example ?? '',
  );

  @override
  void dispose() {
    _word.dispose();
    _meaning.dispose();
    _example.dispose();
    super.dispose();
  }

  void _save() {
    if (_word.text.trim().isEmpty || _meaning.text.trim().isEmpty) return;
    Navigator.of(context).pop(
      _VocabularyEditorValue(
        _word.text.trim(),
        _meaning.text.trim(),
        _example.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool english = widget.isEnglish;
    final bool editing = widget.initial != null;
    return AlertDialog(
      scrollable: true,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      title: Text(
        editing
            ? (english ? 'Edit word' : 'Kelimeyi düzenle')
            : (english ? 'Add a word' : 'Kelime ekle'),
        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              key: const ValueKey<String>('vocabulary_word_field'),
              controller: _word,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: english ? 'Word or phrase *' : 'Kelime veya ifade *',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 11),
            TextField(
              key: const ValueKey<String>('vocabulary_meaning_field'),
              controller: _meaning,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: english ? 'Meaning *' : 'Anlam *',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 11),
            TextField(
              key: const ValueKey<String>('vocabulary_example_field'),
              controller: _example,
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: english
                    ? 'Example (optional)'
                    : 'Örnek (isteğe bağlı)',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(english ? 'Cancel' : 'Vazgeç'),
        ),
        FilledButton(
          key: const ValueKey<String>('vocabulary_save'),
          onPressed: _save,
          child: Text(english ? 'Save' : 'Kaydet'),
        ),
      ],
    );
  }
}

class VocabularyReviewSessionPage extends StatefulWidget {
  const VocabularyReviewSessionPage({
    super.key,
    required this.cards,
    required this.store,
    required this.isEnglish,
  });

  final List<VocabularyCard> cards;
  final VocabularyNotebookStore store;
  final bool isEnglish;

  @override
  State<VocabularyReviewSessionPage> createState() =>
      _VocabularyReviewSessionPageState();
}

class _VocabularyReviewSessionPageState
    extends State<VocabularyReviewSessionPage> {
  int _index = 0;
  bool _revealed = false;
  bool _saving = false;
  bool _finished = false;

  VocabularyCard get _current => widget.cards[_index];

  Future<void> _grade(VocabularyReviewGrade grade) async {
    if (_saving) return;
    setState(() => _saving = true);
    await widget.store.recordReview(_current.id, grade);
    if (!mounted) return;
    if (_index + 1 >= widget.cards.length) {
      setState(() {
        _finished = true;
        _saving = false;
      });
      return;
    }
    setState(() {
      _index++;
      _revealed = false;
      _saving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool english = widget.isEnglish;
    if (_finished) {
      return Scaffold(
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
                      color: StudioVisuals.tealSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 46,
                      color: StudioVisuals.teal,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    english ? 'Review complete' : 'Tekrar tamamlandı',
                    style: const TextStyle(
                      color: StudioVisuals.ink,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    english
                        ? '${widget.cards.length} words rescheduled on this device.'
                        : '${widget.cards.length} kelimenin tekrar zamanı bu cihazda planlandı.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: StudioVisuals.muted),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(english ? 'Back to notebook' : 'Deftere dön'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          english ? 'Recall session' : 'Hatırlama turu',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        actions: <Widget>[
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 18),
              child: Text(
                '${_index + 1} / ${widget.cards.length}',
                style: const TextStyle(
                  color: StudioVisuals.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) =>
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 36,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          LinearProgressIndicator(
                            value: (_index + 1) / widget.cards.length,
                            minHeight: 5,
                            borderRadius: BorderRadius.circular(99),
                            backgroundColor: StudioVisuals.line,
                            color: StudioVisuals.teal,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            english
                                ? 'TRY TO RECALL'
                                : 'ÖNCE HATIRLAMAYA ÇALIŞ',
                            style: const TextStyle(
                              color: StudioVisuals.teal,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(minHeight: 175),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: StudioVisuals.surface,
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(color: StudioVisuals.line),
                              boxShadow: StudioVisuals.softShadow,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  _current.word,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: StudioVisuals.ink,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -.5,
                                  ),
                                ),
                                if (_revealed) ...<Widget>[
                                  const SizedBox(height: 12),
                                  Container(
                                    height: 1,
                                    color: StudioVisuals.line,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _current.meaning,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: StudioVisuals.teal,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if (_current.example.isNotEmpty) ...<Widget>[
                                    const SizedBox(height: 8),
                                    Text(
                                      '“${_current.example}”',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: StudioVisuals.muted,
                                        fontSize: 13,
                                        height: 1.4,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (!_revealed)
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                key: const ValueKey<String>(
                                  'vocabulary_reveal',
                                ),
                                onPressed: () =>
                                    setState(() => _revealed = true),
                                style: FilledButton.styleFrom(
                                  backgroundColor: StudioVisuals.teal,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                ),
                                icon: const Icon(Icons.visibility_rounded),
                                label: Text(
                                  english ? 'Reveal meaning' : 'Anlamı göster',
                                ),
                              ),
                            )
                          else ...<Widget>[
                            Text(
                              english
                                  ? 'How well did you recall it?'
                                  : 'Ne kadarını hatırladın?',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: StudioVisuals.ink,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 9,
                              runSpacing: 9,
                              alignment: WrapAlignment.center,
                              children: <Widget>[
                                _GradeButton(
                                  keyName: 'vocabulary_grade_again',
                                  label: english ? 'Again' : 'Tekrar',
                                  detail: english ? '10 min' : '10 dk',
                                  color: StudioVisuals.danger,
                                  onPressed: () =>
                                      _grade(VocabularyReviewGrade.again),
                                  enabled: !_saving,
                                ),
                                _GradeButton(
                                  keyName: 'vocabulary_grade_hard',
                                  label: english ? 'Hard' : 'Zor',
                                  detail: english ? '1 day' : '1 gün',
                                  color: StudioVisuals.amber,
                                  onPressed: () =>
                                      _grade(VocabularyReviewGrade.hard),
                                  enabled: !_saving,
                                ),
                                _GradeButton(
                                  keyName: 'vocabulary_grade_good',
                                  label: english ? 'Good' : 'İyi',
                                  detail: _current.intervalDays == 1
                                      ? (english ? '3 days' : '3 gün')
                                      : (english
                                            ? 'next step'
                                            : 'sonraki aralık'),
                                  color: StudioVisuals.teal,
                                  onPressed: () =>
                                      _grade(VocabularyReviewGrade.good),
                                  enabled: !_saving,
                                ),
                                _GradeButton(
                                  keyName: 'vocabulary_grade_easy',
                                  label: english ? 'Easy' : 'Kolay',
                                  detail: english ? 'longer' : 'daha uzun',
                                  color: const Color(0xFF627E9E),
                                  onPressed: () =>
                                      _grade(VocabularyReviewGrade.easy),
                                  enabled: !_saving,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
        ),
      ),
    );
  }
}

class _GradeButton extends StatelessWidget {
  const _GradeButton({
    required this.keyName,
    required this.label,
    required this.detail,
    required this.color,
    required this.onPressed,
    required this.enabled,
  });

  final String keyName;
  final String label;
  final String detail;
  final Color color;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 135,
    child: OutlinedButton(
      key: ValueKey<String>(keyName),
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: .40)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      ),
      child: Column(
        children: <Widget>[
          Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(
            detail,
            style: TextStyle(
              color: color.withValues(alpha: .8),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}
