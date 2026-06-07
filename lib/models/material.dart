class WorkshopMaterial {
  final int? id;
  final String name;
  final String category;
  final String unit; // mm, cm, piece, pensa, etc.
  final double quantity; // Stock quantity
  final String? description;
  final DateTime? createdAt;

  const WorkshopMaterial({
    this.id,
    required this.name,
    this.category = '',
    this.unit = 'piece',
    this.quantity = 0,
    this.description,
    this.createdAt,
  });

  factory WorkshopMaterial.fromMap(Map<String, dynamic> m) => WorkshopMaterial(
        id: m['id'] as int?,
        name: m['name'] as String,
        category: (m['category'] as String?) ?? '',
        unit: (m['unit'] as String?) ?? 'piece',
        quantity: (m['quantity'] as num?)?.toDouble() ?? 0,
        description: m['description'] as String?,
        createdAt: m['created_at'] != null 
            ? DateTime.parse(m['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'category': category,
        'unit': unit,
        'quantity': quantity,
        'description': description,
        'created_at': createdAt?.toIso8601String(),
      };

  WorkshopMaterial copyWith({
    int? id,
    String? name,
    String? category,
    String? unit,
    double? quantity,
    String? description,
    DateTime? createdAt,
  }) =>
      WorkshopMaterial(
        id: id ?? this.id,
        name: name ?? this.name,
        category: category ?? this.category,
        unit: unit ?? this.unit,
        quantity: quantity ?? this.quantity,
        description: description ?? this.description,
        createdAt: createdAt ?? this.createdAt,
      );
}
