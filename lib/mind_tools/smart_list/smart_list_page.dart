import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/studio_visuals.dart';
import 'smart_list_models.dart';
import 'smart_list_recall_practice.dart';
import 'smart_list_store.dart';

class SmartListHomeCard extends StatelessWidget {
  const SmartListHomeCard({
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
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 64,
            height: 64,
            child: Image.asset(
              'assets/branding/studio_tool_shopping_assistant.png',
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
                  isEnglish
                      ? 'SHOPPING · TRAVEL · TO-DO'
                      : 'ALIŞVERİŞ · SEYAHAT · YAPILACAKLAR',
                  style: const TextStyle(
                    color: StudioVisuals.amber,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .45,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEnglish
                      ? 'Shopping & Prep Assistant'
                      : 'Alışveriş ve Hazırlık Asistanı',
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
                      ? 'Keep everyday lists together, right on your device.'
                      : 'Günlük listelerin tek yerde, bu cihazda kalsın.',
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
            key: const ValueKey<String>('smart_lists_open'),
            tooltip: isEnglish ? 'Open lists' : 'Listeleri aç',
            onPressed: onTap,
            style: IconButton.styleFrom(
              backgroundColor: StudioVisuals.amberSoft,
              foregroundColor: StudioVisuals.amber,
            ),
            icon: const Icon(Icons.arrow_forward_rounded),
          ),
        ],
      ),
    );
  }
}

class SmartListsPage extends StatefulWidget {
  const SmartListsPage({super.key, this.store});

  final SmartListStore? store;

  @override
  State<SmartListsPage> createState() => _SmartListsPageState();
}

class _SmartListsPageState extends State<SmartListsPage> {
  late final SmartListStore _store;
  List<SmartListDocument> _lists = <SmartListDocument>[];
  bool _loading = true;

  bool get _english => context.l10n.isEnglish;
  int get _openItems => _lists.fold<int>(
    0,
    (int total, SmartListDocument list) => total + list.openCount,
  );

  @override
  void initState() {
    super.initState();
    _store = widget.store ?? SmartListStore();
    _reload();
  }

  Future<void> _reload() async {
    try {
      final List<SmartListDocument> lists = await _store.loadAll();
      lists.sort(
        (SmartListDocument a, SmartListDocument b) =>
            b.createdAt.compareTo(a.createdAt),
      );
      if (!mounted) return;
      setState(() {
        _lists = lists;
        _loading = false;
      });
    } on FormatException {
      if (!mounted) return;
      setState(() => _loading = false);
      _message(
        _english
            ? 'These saved lists could not be read; their local data was left untouched.'
            : 'Kayıtlı listeler okunamadı; yerel veri silinmeden korundu.',
      );
    }
  }

  Future<void> _createList() async {
    final _SmartListDialogValue? value =
        await showDialog<_SmartListDialogValue>(
          context: context,
          builder: (_) => _SmartListDialog(isEnglish: _english),
        );
    if (value == null) return;
    try {
      final SmartListDocument list = await _store.createList(
        title: value.title,
        kind: value.kind,
      );
      await _reload();
      if (mounted) await _openList(list);
    } on StateError {
      _message(
        _english
            ? 'A list with this name already exists in that category.'
            : 'Bu kategoride aynı adlı bir liste zaten var.',
      );
    } on ArgumentError {
      _message(_english ? 'Give the list a name.' : 'Listeye bir ad ver.');
    }
  }

  Future<void> _openList(SmartListDocument list) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SmartListDetailPage(list: list, store: _store),
      ),
    );
    await _reload();
  }

  Future<void> _rename(SmartListDocument list) async {
    final String? title = await _titleDialog(initial: list.title);
    if (title == null || title.trim().isEmpty) return;
    try {
      await _store.renameList(listId: list.id, title: title);
      await _reload();
    } on StateError {
      _message(
        _english
            ? 'A list with this name already exists.'
            : 'Bu adla bir liste zaten var.',
      );
    }
  }

  Future<String?> _titleDialog({String initial = ''}) async {
    final TextEditingController controller = TextEditingController(
      text: initial,
    );
    try {
      return await showDialog<String>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text(_english ? 'Rename list' : 'Liste adını değiştir'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (String value) => Navigator.pop(context, value),
            decoration: InputDecoration(
              labelText: _english ? 'List name' : 'Liste adı',
              border: const OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_english ? 'Cancel' : 'Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text(_english ? 'Save' : 'Kaydet'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _deleteList(SmartListDocument list) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(_english ? 'Delete list?' : 'Liste silinsin mi?'),
        content: Text(
          _english
              ? '“${list.title}” and its ${list.items.length} item(s) will be removed from this device.'
              : '“${list.title}” ve içindeki ${list.items.length} kayıt bu cihazdan silinecek.',
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
    await _store.deleteList(list.id);
    await _reload();
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: Text(text)),
      );
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
          english ? 'My lists' : 'Listelerim',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _reload,
                color: StudioVisuals.teal,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
                  children: <Widget>[
                    _SmartListsOverview(
                      isEnglish: english,
                      listCount: _lists.length,
                      openCount: _openItems,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            english ? 'Your checklists' : 'Kontrol listelerin',
                            style: const TextStyle(
                              color: StudioVisuals.ink,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Text(
                          '${_lists.length} ${english ? 'lists' : 'liste'}',
                          style: const TextStyle(
                            color: StudioVisuals.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 11),
                    if (_lists.isEmpty)
                      _SmartListEmptyState(
                        isEnglish: english,
                        onCreate: _createList,
                      )
                    else
                      for (final SmartListDocument list in _lists) ...<Widget>[
                        _SmartListTile(
                          list: list,
                          isEnglish: english,
                          onOpen: () => _openList(list),
                          onRename: () => _rename(list),
                          onDelete: () => _deleteList(list),
                        ),
                        const SizedBox(height: 10),
                      ],
                    const SizedBox(height: 12),
                    const _SmartListPrivacyNote(),
                  ],
                ),
              ),
      ),
      floatingActionButton: _loading
          ? null
          : FloatingActionButton.extended(
              key: const ValueKey<String>('smart_list_create'),
              onPressed: _createList,
              backgroundColor: StudioVisuals.teal,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text(english ? 'New list' : 'Yeni liste'),
            ),
    );
  }
}

class _SmartListsOverview extends StatelessWidget {
  const _SmartListsOverview({
    required this.isEnglish,
    required this.listCount,
    required this.openCount,
  });

  final bool isEnglish;
  final int listCount;
  final int openCount;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[Colors.white, Color(0xFFFFF8EC)],
      ),
      borderRadius: StudioVisuals.cardRadius,
      border: Border.all(color: const Color(0xFFF1E5D0)),
      boxShadow: StudioVisuals.softShadow,
    ),
    child: Row(
      children: <Widget>[
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: StudioVisuals.amberSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.checklist_rounded,
            color: StudioVisuals.amber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                isEnglish
                    ? 'Plan clearly. Do one thing at a time.'
                    : 'Planını netleştir. Bir işi bir seferde tamamla.',
                style: const TextStyle(
                  color: StudioVisuals.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                isEnglish
                    ? '$listCount lists · $openCount open items'
                    : '$listCount liste · $openCount tamamlanmamış iş',
                style: const TextStyle(
                  color: StudioVisuals.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SmartListTile extends StatelessWidget {
  const _SmartListTile({
    required this.list,
    required this.isEnglish,
    required this.onOpen,
    required this.onRename,
    required this.onDelete,
  });

  final SmartListDocument list;
  final bool isEnglish;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final Color color = _kindColor(list.kind);
    final int total = list.items.length;
    final double progress = total == 0 ? 0 : list.checkedCount / total;
    return Material(
      color: StudioVisuals.surface,
      borderRadius: StudioVisuals.compactRadius,
      child: InkWell(
        key: ValueKey<String>('smart_list_open_${list.id}'),
        onTap: onOpen,
        borderRadius: StudioVisuals.compactRadius,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 13, 7, 13),
          decoration: BoxDecoration(
            borderRadius: StudioVisuals.compactRadius,
            border: Border.all(color: StudioVisuals.line),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_kindIcon(list.kind), color: color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      list.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: StudioVisuals.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${list.kind.title(english: isEnglish)} · ${list.openCount} ${isEnglish ? 'left' : 'kaldı'} · ${list.checkedCount}/${list.items.length}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: StudioVisuals.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor: StudioVisuals.line,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: isEnglish ? 'List actions' : 'Liste işlemleri',
                onSelected: (String action) {
                  if (action == 'rename') onRename();
                  if (action == 'delete') onDelete();
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'rename',
                    child: Text(isEnglish ? 'Rename' : 'Yeniden adlandır'),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Text(isEnglish ? 'Delete' : 'Sil'),
                  ),
                ],
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: StudioVisuals.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmartListEmptyState extends StatelessWidget {
  const _SmartListEmptyState({required this.isEnglish, required this.onCreate});

  final bool isEnglish;
  final VoidCallback onCreate;

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
        const Icon(
          Icons.playlist_add_rounded,
          color: StudioVisuals.amber,
          size: 36,
        ),
        const SizedBox(height: 9),
        Text(
          isEnglish
              ? 'Start with one useful list'
              : 'İşe yarayan tek bir listeyle başla',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: StudioVisuals.ink,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isEnglish
              ? 'Keep shopping, packing and everyday tasks separate.'
              : 'Alışverişi, seyahat hazırlığını ve günlük işleri ayrı tut.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: StudioVisuals.muted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add_rounded),
          label: Text(isEnglish ? 'Create a list' : 'Liste oluştur'),
        ),
      ],
    ),
  );
}

class _SmartListPrivacyNote extends StatelessWidget {
  const _SmartListPrivacyNote();

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
                  ? 'Lists stay on this device. No sign-in, score or network is needed.'
                  : 'Listeler bu cihazda kalır; hesap, puan veya internet gerekmez.',
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

class _SmartListDialogValue {
  const _SmartListDialogValue(this.title, this.kind);
  final String title;
  final SmartListKind kind;
}

class _SmartListDialog extends StatefulWidget {
  const _SmartListDialog({required this.isEnglish});

  final bool isEnglish;

  @override
  State<_SmartListDialog> createState() => _SmartListDialogState();
}

class _SmartListDialogState extends State<_SmartListDialog> {
  final TextEditingController _title = TextEditingController();
  SmartListKind _kind = SmartListKind.shopping;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool english = widget.isEnglish;
    return AlertDialog(
      scrollable: true,
      title: Text(english ? 'Create a list' : 'Liste oluştur'),
      content: SizedBox(
        width: 430,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              key: const ValueKey<String>('smart_list_title'),
              controller: _title,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: english ? 'List name' : 'Liste adı',
                hintText: _kind.suggestion(english: english),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              english ? 'What is it for?' : 'Ne için kullanacaksın?',
              style: const TextStyle(
                color: StudioVisuals.ink,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Wrap(
              spacing: 7,
              runSpacing: 5,
              children: SmartListKind.values
                  .map(
                    (SmartListKind kind) => ChoiceChip(
                      key: ValueKey<String>('smart_list_kind_${kind.name}'),
                      selected: _kind == kind,
                      label: Text(kind.title(english: english)),
                      onSelected: (_) => setState(() => _kind = kind),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(english ? 'Cancel' : 'Vazgeç'),
        ),
        FilledButton(
          key: const ValueKey<String>('smart_list_save'),
          onPressed: () {
            final String value = _title.text.trim().isEmpty
                ? _kind.suggestion(english: english)
                : _title.text.trim();
            Navigator.pop(context, _SmartListDialogValue(value, _kind));
          },
          child: Text(english ? 'Create' : 'Oluştur'),
        ),
      ],
    );
  }
}

class SmartListDetailPage extends StatefulWidget {
  const SmartListDetailPage({
    super.key,
    required this.list,
    required this.store,
  });

  final SmartListDocument list;
  final SmartListStore store;

  @override
  State<SmartListDetailPage> createState() => _SmartListDetailPageState();
}

class _SmartListDetailPageState extends State<SmartListDetailPage> {
  late SmartListDocument _list = widget.list;
  bool _loading = false;

  bool get _english => context.l10n.isEnglish;

  Future<void> _reload() async {
    final List<SmartListDocument> lists = await widget.store.loadAll();
    final Iterable<SmartListDocument> match = lists.where(
      (SmartListDocument value) => value.id == _list.id,
    );
    if (!mounted) return;
    if (match.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _list = match.first);
  }

  Future<void> _addItem() async {
    final _SmartListItemValue? value = await showDialog<_SmartListItemValue>(
      context: context,
      builder: (_) => _SmartListItemDialog(isEnglish: _english),
    );
    if (value == null) return;
    try {
      setState(() => _loading = true);
      await widget.store.addItem(
        listId: _list.id,
        text: value.text,
        quantity: value.quantity,
        section: value.section,
      );
      await _reload();
    } on StateError {
      _message(
        _english
            ? 'That item is already on this list.'
            : 'Bu kayıt listede zaten var.',
      );
    } on ArgumentError {
      _message(_english ? 'Enter an item name.' : 'Bir kayıt adı yaz.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(SmartListItem item) async {
    await widget.store.toggleItem(listId: _list.id, itemId: item.id);
    await _reload();
  }

  Future<bool> _confirmItemDelete(SmartListItem item) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text(_english ? 'Remove item?' : 'Kayıt kaldırılsın mı?'),
            content: Text(item.text),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(_english ? 'Keep' : 'Vazgeç'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(_english ? 'Remove' : 'Kaldır'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _remove(SmartListItem item) async {
    await widget.store.removeItem(listId: _list.id, itemId: item.id);
    await _reload();
  }

  Future<void> _clearCompleted() async {
    if (_list.checkedCount == 0) return;
    await widget.store.clearCompleted(_list.id);
    await _reload();
  }

  Future<void> _startRecallPractice(List<SmartListItem> openItems) async {
    if (openItems.length < 2) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SmartListRecallPracticePage(
          listTitle: _list.title,
          items: List<SmartListItem>.unmodifiable(openItems),
          isEnglish: _english,
        ),
      ),
    );
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: Text(text)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final bool english = _english;
    final Color color = _kindColor(_list.kind);
    final List<SmartListItem> open = _list.items
        .where((SmartListItem item) => !item.checked)
        .toList(growable: false);
    final List<SmartListItem> checked = _list.items
        .where((SmartListItem item) => item.checked)
        .toList(growable: false);
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _list.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('smart_list_clear_completed'),
            tooltip: english ? 'Clear completed' : 'Tamamlananları temizle',
            onPressed: checked.isEmpty ? null : _clearCompleted,
            icon: const Icon(Icons.cleaning_services_outlined),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(17, 8, 17, 100),
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: StudioVisuals.surface,
                      borderRadius: StudioVisuals.cardRadius,
                      border: Border.all(color: StudioVisuals.line),
                    ),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(_kindIcon(_list.kind), color: color),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                _list.kind
                                    .title(english: english)
                                    .toUpperCase(),
                                style: TextStyle(
                                  color: color,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: .6,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                english
                                    ? '${_list.checkedCount} of ${_list.items.length} completed'
                                    : '${_list.items.length} kayıttan ${_list.checkedCount} tamamlandı',
                                style: const TextStyle(
                                  color: StudioVisuals.ink,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${_list.openCount}',
                          style: TextStyle(
                            color: color,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _RecallPracticeEntry(
                    isEnglish: english,
                    itemCount: open.length,
                    onTap: open.length < 2
                        ? null
                        : () => _startRecallPractice(open),
                  ),
                  const SizedBox(height: 18),
                  if (open.isEmpty && checked.isEmpty)
                    _ListDetailEmptyState(isEnglish: english, onAdd: _addItem)
                  else ...<Widget>[
                    if (open.isNotEmpty) ...<Widget>[
                      _ListSectionLabel(
                        text: english
                            ? 'TO DO · ${open.length}'
                            : 'YAPILACAK · ${open.length}',
                        color: color,
                      ),
                      const SizedBox(height: 8),
                      for (final SmartListItem item in open) ...<Widget>[
                        _ListItemRow(
                          item: item,
                          color: color,
                          isEnglish: english,
                          onToggle: () => _toggle(item),
                          onRemove: () => _remove(item),
                          confirmDelete: () => _confirmItemDelete(item),
                        ),
                        const SizedBox(height: 7),
                      ],
                    ],
                    if (checked.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 10),
                      _ListSectionLabel(
                        text: english
                            ? 'DONE · ${checked.length}'
                            : 'TAMAMLANDI · ${checked.length}',
                        color: StudioVisuals.muted,
                      ),
                      const SizedBox(height: 8),
                      for (final SmartListItem item in checked) ...<Widget>[
                        _ListItemRow(
                          item: item,
                          color: StudioVisuals.teal,
                          isEnglish: english,
                          onToggle: () => _toggle(item),
                          onRemove: () => _remove(item),
                          confirmDelete: () => _confirmItemDelete(item),
                        ),
                        const SizedBox(height: 7),
                      ],
                    ],
                  ],
                  const SizedBox(height: 12),
                  const _SmartListPrivacyNote(),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey<String>('smart_list_add_item'),
        onPressed: _loading ? null : _addItem,
        backgroundColor: color,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(english ? 'Add item' : 'Kayıt ekle'),
      ),
    );
  }
}

class _RecallPracticeEntry extends StatelessWidget {
  const _RecallPracticeEntry({
    required this.isEnglish,
    required this.itemCount,
    required this.onTap,
  });

  final bool isEnglish;
  final int itemCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: StudioVisuals.tealSoft,
    borderRadius: StudioVisuals.compactRadius,
    child: InkWell(
      key: const ValueKey<String>('smart_list_recall_entry'),
      onTap: onTap,
      borderRadius: StudioVisuals.compactRadius,
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                Icons.psychology_alt_rounded,
                color: onTap == null ? StudioVisuals.muted : StudioVisuals.teal,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    isEnglish
                        ? 'Optional recall practice'
                        : 'İsteğe bağlı hafıza pratiği',
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
                    itemCount < 2
                        ? (isEnglish
                              ? 'Add at least two open items to try it.'
                              : 'Denemek için en az iki tamamlanmamış kayıt ekle.')
                        : (isEnglish
                              ? 'Study $itemCount items, then recall them without looking.'
                              : '$itemCount kaydı incele, sonra bakmadan hatırlamayı dene.'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: StudioVisuals.muted,
                      fontSize: 10,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.arrow_forward_rounded,
              color: onTap == null ? StudioVisuals.muted : StudioVisuals.teal,
            ),
          ],
        ),
      ),
    ),
  );
}

enum _RecallPracticePhase { study, recall, result }

class SmartListRecallPracticePage extends StatefulWidget {
  const SmartListRecallPracticePage({
    super.key,
    required this.listTitle,
    required this.items,
    required this.isEnglish,
  });

  final String listTitle;
  final List<SmartListItem> items;
  final bool isEnglish;

  @override
  State<SmartListRecallPracticePage> createState() =>
      _SmartListRecallPracticePageState();
}

class _SmartListRecallPracticePageState
    extends State<SmartListRecallPracticePage> {
  final TextEditingController _answerController = TextEditingController();
  _RecallPracticePhase _phase = _RecallPracticePhase.study;
  SmartListRecallResult? _result;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _beginRecall() => setState(() {
    _phase = _RecallPracticePhase.recall;
    _answerController.clear();
  });

  void _checkRecall() => setState(() {
    _result = evaluateSmartListRecall(
      expectedItems: widget.items,
      response: _answerController.text,
      turkishCaseRules: !widget.isEnglish,
    );
    _phase = _RecallPracticePhase.result;
  });

  void _tryAgain() => setState(() {
    _result = null;
    _answerController.clear();
    _phase = _RecallPracticePhase.study;
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: StudioVisuals.canvas,
    appBar: AppBar(
      backgroundColor: StudioVisuals.canvas,
      foregroundColor: StudioVisuals.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: Text(
        widget.isEnglish ? 'Recall practice' : 'Hafıza pratiği',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
      ),
    ),
    body: SafeArea(
      top: false,
      child: ListView(
        key: const ValueKey<String>('smart_list_recall_scroll'),
        padding: const EdgeInsets.fromLTRB(17, 8, 17, 28),
        children: <Widget>[
          _RecallPracticeHeader(
            isEnglish: widget.isEnglish,
            listTitle: widget.listTitle,
            phase: _phase,
            itemCount: widget.items.length,
          ),
          const SizedBox(height: 14),
          switch (_phase) {
            _RecallPracticePhase.study => _buildStudyCard(),
            _RecallPracticePhase.recall => _buildRecallCard(),
            _RecallPracticePhase.result => _buildResultCard(),
          },
          const SizedBox(height: 12),
          _RecallPrivacyNote(isEnglish: widget.isEnglish),
        ],
      ),
    ),
  );

  Widget _buildStudyCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: StudioVisuals.surface,
      borderRadius: StudioVisuals.cardRadius,
      border: Border.all(color: StudioVisuals.line),
      boxShadow: StudioVisuals.softShadow,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          widget.isEnglish
              ? 'Take a moment to review'
              : 'Kayıtları gözden geçir',
          style: const TextStyle(
            color: StudioVisuals.ink,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          widget.isEnglish
              ? 'When you feel ready, hide the list and recall what you can. There is no timer.'
              : 'Hazır olduğunda listeyi gizleyip aklında kalanları yaz. Süre sınırı yok.',
          style: const TextStyle(
            color: StudioVisuals.muted,
            fontSize: 12,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 13),
        for (int index = 0; index < widget.items.length; index++) ...<Widget>[
          _RecallStudyRow(index: index + 1, item: widget.items[index]),
          if (index < widget.items.length - 1)
            const Divider(height: 1, color: StudioVisuals.line),
        ],
        const SizedBox(height: 14),
        FilledButton.icon(
          key: const ValueKey<String>('smart_list_recall_begin'),
          onPressed: _beginRecall,
          style: FilledButton.styleFrom(
            backgroundColor: StudioVisuals.teal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 13),
          ),
          icon: const Icon(Icons.visibility_off_rounded),
          label: Text(
            widget.isEnglish
                ? 'Hide list and recall'
                : 'Listeyi gizle, hatırla',
          ),
        ),
      ],
    ),
  );

  Widget _buildRecallCard() => Container(
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
          widget.isEnglish ? 'What do you remember?' : 'Neleri hatırlıyorsun?',
          style: const TextStyle(
            color: StudioVisuals.ink,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          widget.isEnglish
              ? 'Write one item on each line. Names are checked locally; quantities are optional.'
              : 'Her satıra bir kayıt yaz. Yanıtlar cihazda kontrol edilir; miktar yazmak zorunlu değil.',
          style: const TextStyle(
            color: StudioVisuals.muted,
            fontSize: 12,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 13),
        TextField(
          key: const ValueKey<String>('smart_list_recall_input'),
          controller: _answerController,
          minLines: 5,
          maxLines: 9,
          maxLength: 4000,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            hintText: widget.isEnglish
                ? 'Milk\nPassport\nCall the hotel'
                : 'Süt\nPasaport\nOteli ara',
            alignLabelWithHint: true,
            filled: true,
            fillColor: StudioVisuals.canvas,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: StudioVisuals.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: StudioVisuals.line),
            ),
          ),
        ),
        const SizedBox(height: 6),
        FilledButton.icon(
          key: const ValueKey<String>('smart_list_recall_check'),
          onPressed: _checkRecall,
          style: FilledButton.styleFrom(
            backgroundColor: StudioVisuals.teal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 13),
          ),
          icon: const Icon(Icons.check_rounded),
          label: Text(
            widget.isEnglish ? 'Review recall' : 'Hatırladıklarımı gör',
          ),
        ),
      ],
    ),
  );

  Widget _buildResultCard() {
    final SmartListRecallResult result = _result!;
    return Container(
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
            widget.isEnglish
                ? 'You recalled ${result.rememberedCount} of ${widget.items.length} items'
                : '${widget.items.length} kayıttan ${result.rememberedCount} tanesini hatırladın',
            style: const TextStyle(
              color: StudioVisuals.ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (result.rememberedItems.isNotEmpty) ...<Widget>[
            _RecallResultLabel(
              text: widget.isEnglish ? 'REMEMBERED' : 'HATIRLANAN',
              color: StudioVisuals.teal,
            ),
            const SizedBox(height: 5),
            for (final SmartListItem item in result.rememberedItems)
              _RecallResultRow(item: item, icon: Icons.check_circle_rounded),
          ],
          if (result.missedItems.isNotEmpty) ...<Widget>[
            if (result.rememberedItems.isNotEmpty) const SizedBox(height: 12),
            _RecallResultLabel(
              text: widget.isEnglish
                  ? 'NOT RECALLED THIS TIME'
                  : 'BU KEZ HATIRLANMAYAN',
              color: StudioVisuals.amber,
            ),
            const SizedBox(height: 5),
            for (final SmartListItem item in result.missedItems)
              _RecallResultRow(
                item: item,
                icon: Icons.lightbulb_outline_rounded,
              ),
          ],
          if (result.extraAnswerCount > 0) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              widget.isEnglish
                  ? '${result.extraAnswerCount} answer(s) were not on this list.'
                  : 'Listede olmayan ${result.extraAnswerCount} yanıt vardı.',
              style: const TextStyle(color: StudioVisuals.muted, fontSize: 11),
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            key: const ValueKey<String>('smart_list_recall_retry'),
            onPressed: _tryAgain,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(
              widget.isEnglish
                  ? 'Review list and try again'
                  : 'Listeyi gör, yeniden dene',
            ),
          ),
          const SizedBox(height: 5),
          TextButton(
            key: const ValueKey<String>('smart_list_recall_done'),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(widget.isEnglish ? 'Return to my list' : 'Listeye dön'),
          ),
        ],
      ),
    );
  }
}

class _RecallPracticeHeader extends StatelessWidget {
  const _RecallPracticeHeader({
    required this.isEnglish,
    required this.listTitle,
    required this.phase,
    required this.itemCount,
  });

  final bool isEnglish;
  final String listTitle;
  final _RecallPracticePhase phase;
  final int itemCount;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[Colors.white, StudioVisuals.tealSoft],
      ),
      borderRadius: StudioVisuals.cardRadius,
      border: Border.all(color: StudioVisuals.line),
    ),
    child: Row(
      children: <Widget>[
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.psychology_alt_rounded,
            color: StudioVisuals.teal,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                listTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: StudioVisuals.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                switch (phase) {
                  _RecallPracticePhase.study =>
                    isEnglish
                        ? '$itemCount items · review at your pace'
                        : '$itemCount kayıt · kendi hızında incele',
                  _RecallPracticePhase.recall =>
                    isEnglish
                        ? 'Recall · list hidden'
                        : 'Hatırlama · liste gizli',
                  _RecallPracticePhase.result =>
                    isEnglish
                        ? 'Reflection · no score is saved'
                        : 'Gözden geçirme · puan kaydedilmez',
                },
                style: const TextStyle(
                  color: StudioVisuals.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _RecallStudyRow extends StatelessWidget {
  const _RecallStudyRow({required this.index, required this.item});

  final int index;
  final SmartListItem item;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 25,
          height: 25,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: StudioVisuals.tealSoft,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$index',
            style: const TextStyle(
              color: StudioVisuals.teal,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                item.text,
                style: const TextStyle(
                  color: StudioVisuals.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (item.quantity.isNotEmpty ||
                  item.section.isNotEmpty) ...<Widget>[
                const SizedBox(height: 3),
                Text(
                  <String>[
                    if (item.quantity.isNotEmpty) item.quantity,
                    if (item.section.isNotEmpty) item.section,
                  ].join(' · '),
                  style: const TextStyle(
                    color: StudioVisuals.muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _RecallResultLabel extends StatelessWidget {
  const _RecallResultLabel({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: color,
      fontSize: 9,
      fontWeight: FontWeight.w900,
      letterSpacing: .65,
    ),
  );
}

class _RecallResultRow extends StatelessWidget {
  const _RecallResultRow({required this.item, required this.icon});
  final SmartListItem item;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: <Widget>[
        Icon(icon, color: StudioVisuals.teal, size: 17),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            item.text,
            style: const TextStyle(
              color: StudioVisuals.ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (item.quantity.isNotEmpty)
          Text(
            item.quantity,
            style: const TextStyle(color: StudioVisuals.muted, fontSize: 10),
          ),
      ],
    ),
  );
}

class _RecallPrivacyNote extends StatelessWidget {
  const _RecallPrivacyNote({required this.isEnglish});
  final bool isEnglish;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: StudioVisuals.surfaceSoft,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: <Widget>[
        const Icon(
          Icons.phonelink_lock_rounded,
          size: 17,
          color: StudioVisuals.muted,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            isEnglish
                ? 'This is optional practice. Your answers are checked temporarily on this device and are not saved or shared.'
                : 'Bu çalışma isteğe bağlıdır. Yanıtların yalnızca bu cihazda geçici olarak kontrol edilir; kaydedilmez ve paylaşılmaz.',
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

class _ListSectionLabel extends StatelessWidget {
  const _ListSectionLabel({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: color,
      fontSize: 10,
      fontWeight: FontWeight.w900,
      letterSpacing: .7,
    ),
  );
}

class _ListItemRow extends StatelessWidget {
  const _ListItemRow({
    required this.item,
    required this.color,
    required this.isEnglish,
    required this.onToggle,
    required this.onRemove,
    required this.confirmDelete,
  });

  final SmartListItem item;
  final Color color;
  final bool isEnglish;
  final VoidCallback onToggle;
  final VoidCallback onRemove;
  final Future<bool> Function() confirmDelete;

  @override
  Widget build(BuildContext context) => Dismissible(
    key: ValueKey<String>('smart_list_item_${item.id}'),
    direction: DismissDirection.endToStart,
    confirmDismiss: (_) => confirmDelete(),
    onDismissed: (_) => onRemove(),
    background: Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 18),
      decoration: BoxDecoration(
        color: StudioVisuals.danger.withValues(alpha: .12),
        borderRadius: StudioVisuals.compactRadius,
      ),
      child: const Icon(
        Icons.delete_outline_rounded,
        color: StudioVisuals.danger,
      ),
    ),
    child: Container(
      padding: const EdgeInsets.fromLTRB(8, 7, 12, 7),
      decoration: BoxDecoration(
        color: StudioVisuals.surface,
        borderRadius: StudioVisuals.compactRadius,
        border: Border.all(color: StudioVisuals.line),
      ),
      child: Row(
        children: <Widget>[
          Checkbox(
            key: ValueKey<String>('smart_list_check_${item.id}'),
            value: item.checked,
            activeColor: color,
            onChanged: (_) => onToggle(),
          ),
          Expanded(
            child: InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: item.checked
                            ? StudioVisuals.muted
                            : StudioVisuals.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        decoration: item.checked
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (item.quantity.isNotEmpty ||
                        item.section.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 3),
                      Text(
                        <String>[
                          if (item.quantity.isNotEmpty) item.quantity,
                          if (item.section.isNotEmpty) item.section,
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: StudioVisuals.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Icon(
            Icons.drag_handle_rounded,
            color: StudioVisuals.muted.withValues(alpha: .7),
            size: 19,
          ),
        ],
      ),
    ),
  );
}

class _ListDetailEmptyState extends StatelessWidget {
  const _ListDetailEmptyState({required this.isEnglish, required this.onAdd});
  final bool isEnglish;
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
        const Icon(
          Icons.playlist_add_rounded,
          color: StudioVisuals.teal,
          size: 35,
        ),
        const SizedBox(height: 9),
        Text(
          isEnglish ? 'Add the first item' : 'İlk kaydı ekle',
          style: const TextStyle(
            color: StudioVisuals.ink,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isEnglish
              ? 'Add quantities or a section when they help.'
              : 'Gerekiyorsa miktar veya bölüm bilgisi de ekleyebilirsin.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: StudioVisuals.muted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded),
          label: Text(isEnglish ? 'Add item' : 'Kayıt ekle'),
        ),
      ],
    ),
  );
}

class _SmartListItemValue {
  const _SmartListItemValue(this.text, this.quantity, this.section);
  final String text;
  final String quantity;
  final String section;
}

class _SmartListItemDialog extends StatefulWidget {
  const _SmartListItemDialog({required this.isEnglish});
  final bool isEnglish;

  @override
  State<_SmartListItemDialog> createState() => _SmartListItemDialogState();
}

class _SmartListItemDialogState extends State<_SmartListItemDialog> {
  final TextEditingController _text = TextEditingController();
  final TextEditingController _quantity = TextEditingController();
  final TextEditingController _section = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    _quantity.dispose();
    _section.dispose();
    super.dispose();
  }

  void _save() {
    if (_text.text.trim().isEmpty) return;
    Navigator.pop(
      context,
      _SmartListItemValue(
        _text.text.trim(),
        _quantity.text.trim(),
        _section.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool english = widget.isEnglish;
    return AlertDialog(
      scrollable: true,
      title: Text(english ? 'Add an item' : 'Kayıt ekle'),
      content: SizedBox(
        width: 430,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              key: const ValueKey<String>('smart_list_item_text'),
              controller: _text,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: english ? 'Item *' : 'Kayıt *',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey<String>('smart_list_item_quantity'),
              controller: _quantity,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: english
                    ? 'Quantity (optional)'
                    : 'Miktar (isteğe bağlı)',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey<String>('smart_list_item_section'),
              controller: _section,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              decoration: InputDecoration(
                labelText: english
                    ? 'Section or note (optional)'
                    : 'Bölüm veya not (isteğe bağlı)',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(english ? 'Cancel' : 'Vazgeç'),
        ),
        FilledButton(
          key: const ValueKey<String>('smart_list_item_save'),
          onPressed: _save,
          child: Text(english ? 'Add' : 'Ekle'),
        ),
      ],
    );
  }
}

Color _kindColor(SmartListKind kind) => switch (kind) {
  SmartListKind.shopping => StudioVisuals.teal,
  SmartListKind.travel => const Color(0xFF6079B4),
  SmartListKind.tasks => StudioVisuals.amber,
};

IconData _kindIcon(SmartListKind kind) => switch (kind) {
  SmartListKind.shopping => Icons.shopping_basket_outlined,
  SmartListKind.travel => Icons.luggage_outlined,
  SmartListKind.tasks => Icons.task_alt_rounded,
};
