class Item {
  final int? id;
  final String name;
  final String category; // group name e.g. 'ስቴላ'
  final bool isParent;   // true = category header row

  const Item({
    this.id,
    required this.name,
    this.category = '',
    this.isParent = false,
  });

  factory Item.fromMap(Map<String, dynamic> m) => Item(
        id: m['id'] as int?,
        name: m['name'] as String,
        category: (m['category'] as String?) ?? '',
        isParent: ((m['is_parent'] as int?) ?? 0) == 1,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'category': category,
        'is_parent': isParent ? 1 : 0,
      };
}
