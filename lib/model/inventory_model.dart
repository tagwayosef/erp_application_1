import 'package:isar/isar.dart';

part 'inventory_model.g.dart';

@collection
class InventoryModel {
  Id id = Isar.autoIncrement;

  late String name;
  String? category;
  late double qty;
  late double cost;
  late double price;
  late double min;
  String? supplier;
  int? supplierId; // حقل معرف المورد المتوافق
  String? purchaseType;
  String? barcode;
  String? referenceNo; // حقل رقم المرجع لربط الصنف بقيود دفتر الأستاذ بدقة

  InventoryModel({
    required this.name,
    this.category,
    required this.qty,
    required this.cost,
    required this.price,
    required this.min,
    this.supplier,
    this.supplierId,
    this.purchaseType,
    this.barcode,
    this.referenceNo,
  });

  factory InventoryModel.fromJson(Map<String, dynamic> json) {
    final model = InventoryModel(
      name: json['name'] ?? '',
      category: json['category'],
      qty: (json['qty'] as num?)?.toDouble() ?? 0.0,
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      min: (json['min'] as num?)?.toDouble() ?? 0.0,
      supplier: json['supplier'],
      supplierId: json['supplierId'] != null ? (json['supplierId'] as num).toInt() : null,
      purchaseType: json['purchaseType'],
      barcode: json['barcode']?.toString(),
      referenceNo: json['referenceNo']?.toString(),
    );

    if (json['id'] != null) {
      model.id = (json['id'] as num).toInt();
    }

    return model;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'qty': qty,
      'cost': cost,
      'price': price,
      'min': min,
      'supplier': supplier,
      'supplierId': supplierId,
      'purchaseType': purchaseType,
      'barcode': barcode,
      'referenceNo': referenceNo,
    };
  }

  InventoryModel copyWith({
    Id? id,
    String? name,
    String? category,
    double? qty,
    double? cost,
    double? price,
    double? min,
    String? supplier,
    int? supplierId,
    String? purchaseType,
    String? barcode,
    String? referenceNo,
  }) {
    final newModel = InventoryModel(
      name: name ?? this.name,
      category: category ?? this.category,
      qty: qty ?? this.qty,
      cost: cost ?? this.cost,
      price: price ?? this.price,
      min: min ?? this.min,
      supplier: supplier ?? this.supplier,
      supplierId: supplierId ?? this.supplierId,
      purchaseType: purchaseType ?? this.purchaseType,
      barcode: barcode ?? this.barcode,
      referenceNo: referenceNo ?? this.referenceNo,
    );
    newModel.id = id ?? this.id;
    return newModel;
  }
}