class Service {
  final int? id;
  final int vehicleId;
  final String name;
  final double price;
  final String createdAt;

  const Service({
    this.id,
    required this.vehicleId,
    required this.name,
    required this.price,
    required this.createdAt,
  });

  factory Service.fromMap(Map<String, dynamic> map) => Service(
        id: map['id'] as int?,
        vehicleId: map['vehicle_id'] as int,
        name: map['name'] as String,
        price: (map['price'] as num).toDouble(),
        createdAt: map['created_at'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'vehicle_id': vehicleId,
        'name': name,
        'price': price,
        'created_at': createdAt,
      };
}

class Vehicle {
  final int? id;
  final String plate;
  final String model;
  final String entryDate;
  final String status;
  final double totalBill;
  final String? notes;
  final List<Service> services;

  const Vehicle({
    this.id,
    required this.plate,
    required this.model,
    required this.entryDate,
    required this.status,
    required this.totalBill,
    this.notes,
    this.services = const [],
  });

  factory Vehicle.fromMap(Map<String, dynamic> map, {List<Service>? services}) =>
      Vehicle(
        id: map['id'] as int?,
        plate: map['plate'] as String,
        model: map['model'] as String,
        entryDate: map['entry_date'] as String,
        status: map['status'] as String,
        totalBill: (map['total_bill'] as num).toDouble(),
        notes: map['notes'] as String?,
        services: services ?? [],
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'plate': plate,
        'model': model,
        'entry_date': entryDate,
        'status': status,
        'total_bill': totalBill,
        'notes': notes,
      };

  static const List<String> statuses = [
    'Not Started',
    'In Progress',
    'Completed/Pending Pickup',
    'Delivered',
  ];
}
