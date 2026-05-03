class ToolTransaction {
  final int? id;
  final String employee;
  final String toolName;
  final int quantity;
  final String status; // 'Borrowed' | 'Returned'
  final String timestamp;
  final String? notes;

  const ToolTransaction({
    this.id,
    required this.employee,
    required this.toolName,
    required this.quantity,
    required this.status,
    required this.timestamp,
    this.notes,
  });

  factory ToolTransaction.fromMap(Map<String, dynamic> map) => ToolTransaction(
        id: map['id'] as int?,
        employee: map['employee'] as String,
        toolName: map['tool_name'] as String,
        quantity: map['quantity'] as int,
        status: map['status'] as String,
        timestamp: map['timestamp'] as String,
        notes: map['notes'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'employee': employee,
        'tool_name': toolName,
        'quantity': quantity,
        'status': status,
        'timestamp': timestamp,
        'notes': notes,
      };

  ToolTransaction copyWith({String? status}) => ToolTransaction(
        id: id,
        employee: employee,
        toolName: toolName,
        quantity: quantity,
        status: status ?? this.status,
        timestamp: timestamp,
        notes: notes,
      );
}
