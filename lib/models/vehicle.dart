class Service {
  final int? id;
  final int vehicleId;
  final String name;
  final double unitPrice;
  final int quantity;
  final double discount;
  final String? notes;
  final String createdAt;

  const Service({
    this.id,
    required this.vehicleId,
    required this.name,
    required this.unitPrice,
    this.quantity = 1,
    this.discount = 0,
    this.notes,
    required this.createdAt,
  });

  double get subtotal => unitPrice * quantity;
  double get total => subtotal - discount;

  factory Service.fromMap(Map<String, dynamic> map) => Service(
        id: map['id'] as int?,
        vehicleId: map['vehicle_id'] as int,
        name: map['name'] as String,
        unitPrice: (map['unit_price'] as num).toDouble(),
        quantity: (map['quantity'] as int?) ?? 1,
        discount: (map['discount'] as num?)?.toDouble() ?? 0,
        notes: map['notes'] as String?,
        createdAt: map['created_at'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'vehicle_id': vehicleId,
        'name': name,
        'unit_price': unitPrice,
        'quantity': quantity,
        'discount': discount,
        'notes': notes,
        'created_at': createdAt,
      };
}

class Vehicle {
  final int? id;
  final String plate;
  final String entryDate;
  final String status;
  final double totalBill;
  final String? notes;
  final List<Service> services;

  const Vehicle({
    this.id,
    required this.plate,
    required this.entryDate,
    required this.status,
    required this.totalBill,
    this.notes,
    this.services = const [],
  });

  factory Vehicle.fromMap(Map<String, dynamic> map,
          {List<Service>? services}) =>
      Vehicle(
        id: map['id'] as int?,
        plate: map['plate'] as String,
        entryDate: map['entry_date'] as String,
        status: map['status'] as String,
        totalBill: (map['total_bill'] as num).toDouble(),
        notes: map['notes'] as String?,
        services: services ?? [],
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'plate': plate,
        'entry_date': entryDate,
        'status': status,
        'total_bill': totalBill,
        'notes': notes,
      };

  Vehicle copyWith({
    String? plate,
    String? status,
    String? notes,
    double? totalBill,
  }) =>
      Vehicle(
        id: id,
        plate: plate ?? this.plate,
        entryDate: entryDate,
        status: status ?? this.status,
        totalBill: totalBill ?? this.totalBill,
        notes: notes,
        services: services,
      );

  static const List<String> statuses = [
    'Not Started',
    'In Progress',
    'Completed/Pending Pickup',
    'Delivered',
  ];
}
