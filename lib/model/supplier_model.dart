import 'package:isar/isar.dart';

part 'supplier_model.g.dart';

@collection
class SupplierModel {
  Id id = Isar.autoIncrement;

  String name;           // اسم المورد
  String? phone;         // رقم الهاتف
  String? address;       // العنوان
  double balance;        // 👈 تم إزالة final لكي يُصبح قابلاً للتعديل وتحديث الرصيد
  String? notes;         // ملاحظات

  SupplierModel({
    required this.name,
    this.phone,
    this.address,
    this.balance = 0.0,
    this.notes,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    final supplier = SupplierModel(
      name: json['name'] ?? '',
      phone: json['phone'],
      address: json['address'],
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'],
    );

    if (json['id'] != null) {
      supplier.id = (json['id'] as num).toInt();
    }

    return supplier;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'balance': balance,
      'notes': notes,
    };
  }
}