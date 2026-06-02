/// Represents the CURRENT active borrow of one item by one employee.
/// quantity = how many are still out (not yet returned).
class Borrow {
  final int? id;
  final int employeeId;
  final int itemId;
  final String itemName; // joined from items table
  final String employeeName; // joined from employees table
  int quantity; // mutable for UI editing
  final String borrowedAt;

  Borrow({
    this.id,
    required this.employeeId,
    required this.itemId,
    required this.itemName,
    required this.employeeName,
    required this.quantity,
    required this.borrowedAt,
  });

  factory Borrow.fromMap(Map<String, dynamic> m) => Borrow(
        id: m['id'] as int?,
        employeeId: m['employee_id'] as int,
        itemId: m['item_id'] as int,
        itemName: m['item_name'] as String? ?? '',
        employeeName: m['employee_name'] as String? ?? '',
        quantity: m['quantity'] as int,
        borrowedAt: m['borrowed_at'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'employee_id': employeeId,
        'item_id': itemId,
        'quantity': quantity,
        'borrowed_at': borrowedAt,
      };
}
