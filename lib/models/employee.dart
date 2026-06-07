class Employee {
  final int? id;
  final String name;
  final String? phone;
  final String entryDate;
  final String? notes;

  const Employee({
    this.id,
    required this.name,
    this.phone,
    required this.entryDate,
    this.notes,
  });

  factory Employee.fromMap(Map<String, dynamic> m) => Employee(
        id: m['id'] as int?,
        name: m['name'] as String,
        phone: m['phone'] as String?,
        entryDate: m['entry_date'] as String,
        notes: m['notes'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'phone': phone,
        'entry_date': entryDate,
        'notes': notes,
      };

  Employee copyWith({String? name, String? phone, String? entryDate, String? notes}) => Employee(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        entryDate: entryDate ?? this.entryDate,
        notes: notes ?? this.notes,
      );
}
