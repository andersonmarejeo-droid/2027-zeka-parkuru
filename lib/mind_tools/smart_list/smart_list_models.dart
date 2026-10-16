enum SmartListKind { shopping, travel, tasks }

extension SmartListKindPresentation on SmartListKind {
  String title({required bool english}) => switch (this) {
    SmartListKind.shopping => english ? 'Shopping' : 'Alışveriş',
    SmartListKind.travel => english ? 'Travel prep' : 'Seyahat hazırlığı',
    SmartListKind.tasks => english ? 'To-do' : 'Yapılacaklar',
  };

  String suggestion({required bool english}) => switch (this) {
    SmartListKind.shopping => english ? 'Groceries' : 'Market listesi',
    SmartListKind.travel => english ? 'Trip checklist' : 'Gezi kontrol listesi',
    SmartListKind.tasks => english ? 'My tasks' : 'Günlük işlerim',
  };
}

class SmartListItem {
  const SmartListItem({
    required this.id,
    required this.text,
    required this.checked,
    this.quantity = '',
    this.section = '',
  });

  final String id;
  final String text;
  final bool checked;
  final String quantity;
  final String section;

  SmartListItem copyWith({bool? checked}) => SmartListItem(
    id: id,
    text: text,
    checked: checked ?? this.checked,
    quantity: quantity,
    section: section,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'text': text,
    'checked': checked,
    'quantity': quantity,
    'section': section,
  };

  factory SmartListItem.fromJson(Map<String, Object?> json) {
    final String id = json['id'] as String? ?? '';
    final String text = json['text'] as String? ?? '';
    if (id.isEmpty || text.trim().isEmpty) {
      throw const FormatException('Smart list item is missing required text.');
    }
    return SmartListItem(
      id: id,
      text: text,
      checked: json['checked'] == true,
      quantity: json['quantity'] as String? ?? '',
      section: json['section'] as String? ?? '',
    );
  }
}

class SmartListDocument {
  const SmartListDocument({
    required this.id,
    required this.title,
    required this.kind,
    required this.createdAt,
    required this.items,
  });

  final String id;
  final String title;
  final SmartListKind kind;
  final DateTime createdAt;
  final List<SmartListItem> items;

  int get checkedCount =>
      items.where((SmartListItem item) => item.checked).length;
  int get openCount => items.length - checkedCount;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'title': title,
    'kind': kind.name,
    'createdAt': createdAt.toIso8601String(),
    'items': items.map((SmartListItem item) => item.toJson()).toList(),
  };

  factory SmartListDocument.fromJson(Map<String, Object?> json) {
    final String id = json['id'] as String? ?? '';
    final String title = json['title'] as String? ?? '';
    final String kindName = json['kind'] as String? ?? '';
    final SmartListKind? kind = switch (kindName) {
      'shopping' => SmartListKind.shopping,
      'travel' => SmartListKind.travel,
      'tasks' => SmartListKind.tasks,
      _ => null,
    };
    final Object? rawItems = json['items'];
    if (id.isEmpty ||
        title.trim().isEmpty ||
        kind == null ||
        rawItems is! List) {
      throw const FormatException('Invalid smart list data.');
    }
    final List<SmartListItem> items = rawItems
        .map((Object? value) {
          if (value is! Map<String, Object?>) {
            throw const FormatException('Invalid smart list row.');
          }
          return SmartListItem.fromJson(value);
        })
        .toList(growable: false);
    final Set<String> ids = <String>{};
    if (items.any((SmartListItem item) => !ids.add(item.id))) {
      throw const FormatException('Duplicate smart list row identifier.');
    }
    final Object? createdAt = json['createdAt'];
    if (createdAt is! String) {
      throw const FormatException('Smart list has no creation date.');
    }
    return SmartListDocument(
      id: id,
      title: title,
      kind: kind,
      createdAt: DateTime.parse(createdAt),
      items: items,
    );
  }
}
