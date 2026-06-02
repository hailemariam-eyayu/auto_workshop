/// Every borrow or return action is logged here.
class BorrowHistory {
  final int? id;
  final int employeeId;
  final int itemId;
  final String itemName;
  final String employeeName;
  final int quantity;
  final String action; // 'borrowed' | 'returned'
  final String timestamp;

  const BorrowHistory({
    this.id,
    required this.employeeId,
    required this.itemId,
    required this.itemName,
    required this.employeeName,
    required this.quantity,
    required this.action,
    required this.timestamp,
  });

  factory BorrowHistory.fromMap(Map<String, dynamic> m) => BorrowHistory(
        id: m['id'] as int?,
        employeeId: m['employee_id'] as int,
        itemId: m['item_id'] as int,
        itemName: m['item_name'] as String? ?? '',
        employeeName: m['employee_name'] as String? ?? '',
        quantity: m['quantity'] as int,
        action: m['action'] as String,
        timestamp: m['timestamp'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'employee_id': employeeId,
        'item_id': itemId,
        'quantity': quantity,
        'action': action,
        'timestamp': timestamp,
      };
}
