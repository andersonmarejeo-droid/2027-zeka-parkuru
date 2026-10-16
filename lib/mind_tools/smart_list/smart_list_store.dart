import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

import 'smart_list_models.dart';

class SmartListStore {
  SmartListStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const String storageKey = 'mind_tool_smart_lists_v1';
  static final math.Random _random = math.Random.secure();
  static int _idSequence = 0;

  final SharedPreferencesAsync _preferences;

  Future<List<SmartListDocument>> loadAll() async {
    final String? raw = await _preferences.getString(storageKey);
    if (raw == null || raw.isEmpty) return <SmartListDocument>[];
    final Object? decoded = jsonDecode(raw);
    if (decoded is! List<Object?>) {
      throw const FormatException('Smart list data must be a list.');
    }
    final List<SmartListDocument> lists = decoded.map((Object? value) {
      if (value is! Map<String, Object?>) {
        throw const FormatException('Invalid smart list.');
      }
      return SmartListDocument.fromJson(value);
    }).toList();
    final Set<String> ids = <String>{};
    if (lists.any((SmartListDocument list) => !ids.add(list.id))) {
      throw const FormatException('Duplicate smart list identifier.');
    }
    return lists;
  }

  Future<SmartListDocument> createList({
    required String title,
    required SmartListKind kind,
    DateTime? now,
  }) async {
    final String cleanTitle = title.trim();
    if (cleanTitle.isEmpty) throw ArgumentError('A list title is required.');
    final List<SmartListDocument> lists = await loadAll();
    if (lists.any(
      (SmartListDocument list) =>
          list.kind == kind && _normalise(list.title) == _normalise(cleanTitle),
    )) {
      throw StateError('A list with this name already exists.');
    }
    final DateTime created = now ?? DateTime.now();
    final SmartListDocument list = SmartListDocument(
      id: _newId(created),
      title: cleanTitle,
      kind: kind,
      createdAt: created,
      items: const <SmartListItem>[],
    );
    await _write(<SmartListDocument>[...lists, list]);
    return list;
  }

  Future<SmartListDocument> addItem({
    required String listId,
    required String text,
    String quantity = '',
    String section = '',
  }) async {
    final List<SmartListDocument> lists = await loadAll();
    final int listIndex = _findList(lists, listId);
    final String cleanText = text.trim();
    if (cleanText.isEmpty) throw ArgumentError('An item is required.');
    final SmartListDocument old = lists[listIndex];
    if (old.items.any(
      (SmartListItem item) => _normalise(item.text) == _normalise(cleanText),
    )) {
      throw StateError('This item is already on the list.');
    }
    final DateTime now = DateTime.now();
    final SmartListItem item = SmartListItem(
      id: _newId(now),
      text: cleanText,
      quantity: quantity.trim(),
      section: section.trim(),
      checked: false,
    );
    lists[listIndex] = _copyWithItems(old, <SmartListItem>[...old.items, item]);
    await _write(lists);
    return lists[listIndex];
  }

  Future<SmartListDocument> toggleItem({
    required String listId,
    required String itemId,
  }) async {
    final List<SmartListDocument> lists = await loadAll();
    final int listIndex = _findList(lists, listId);
    final SmartListDocument old = lists[listIndex];
    final int itemIndex = old.items.indexWhere(
      (SmartListItem item) => item.id == itemId,
    );
    if (itemIndex < 0) throw StateError('List item no longer exists.');
    final List<SmartListItem> items = List<SmartListItem>.of(old.items);
    items[itemIndex] = items[itemIndex].copyWith(
      checked: !items[itemIndex].checked,
    );
    lists[listIndex] = _copyWithItems(old, items);
    await _write(lists);
    return lists[listIndex];
  }

  Future<SmartListDocument> removeItem({
    required String listId,
    required String itemId,
  }) async {
    final List<SmartListDocument> lists = await loadAll();
    final int index = _findList(lists, listId);
    final SmartListDocument old = lists[index];
    final List<SmartListItem> items = old.items
        .where((SmartListItem item) => item.id != itemId)
        .toList();
    lists[index] = _copyWithItems(old, items);
    await _write(lists);
    return lists[index];
  }

  Future<SmartListDocument> clearCompleted(String listId) async {
    final List<SmartListDocument> lists = await loadAll();
    final int index = _findList(lists, listId);
    final SmartListDocument old = lists[index];
    lists[index] = _copyWithItems(
      old,
      old.items.where((SmartListItem item) => !item.checked).toList(),
    );
    await _write(lists);
    return lists[index];
  }

  Future<SmartListDocument> renameList({
    required String listId,
    required String title,
  }) async {
    final String cleanTitle = title.trim();
    if (cleanTitle.isEmpty) throw ArgumentError('A list title is required.');
    final List<SmartListDocument> lists = await loadAll();
    final int index = _findList(lists, listId);
    final SmartListDocument old = lists[index];
    if (lists.any(
      (SmartListDocument list) =>
          list.id != listId &&
          list.kind == old.kind &&
          _normalise(list.title) == _normalise(cleanTitle),
    )) {
      throw StateError('A list with this name already exists.');
    }
    lists[index] = SmartListDocument(
      id: old.id,
      title: cleanTitle,
      kind: old.kind,
      createdAt: old.createdAt,
      items: old.items,
    );
    await _write(lists);
    return lists[index];
  }

  Future<void> deleteList(String listId) async {
    final List<SmartListDocument> lists = await loadAll();
    lists.removeWhere((SmartListDocument list) => list.id == listId);
    await _write(lists);
  }

  int _findList(List<SmartListDocument> lists, String id) {
    final int index = lists.indexWhere(
      (SmartListDocument list) => list.id == id,
    );
    if (index < 0) throw StateError('List no longer exists.');
    return index;
  }

  SmartListDocument _copyWithItems(
    SmartListDocument list,
    List<SmartListItem> items,
  ) => SmartListDocument(
    id: list.id,
    title: list.title,
    kind: list.kind,
    createdAt: list.createdAt,
    items: items,
  );

  Future<void> _write(List<SmartListDocument> lists) => _preferences.setString(
    storageKey,
    jsonEncode(lists.map((SmartListDocument list) => list.toJson()).toList()),
  );

  String _newId(DateTime now) =>
      '${now.microsecondsSinceEpoch}_${_idSequence++}_${_random.nextInt(1 << 32)}';

  String _normalise(String value) => value.trim().toLowerCase();
}
