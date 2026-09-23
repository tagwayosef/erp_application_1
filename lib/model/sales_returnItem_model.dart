
import 'package:isar/isar.dart';

part 'sales_returnItem_model.g.dart';
@embedded
class SalesReturnItemModel {
  String? productName;
  /// باركود الصنف
  String? barcode;

  /// سعر بيع الوحدة وقت البيع
  double price;

  /// الكمية التي تم إرجاعها
  double qty;

  /// إجمالي قيمة الصنف المرتجع
  /// = السعر × الكمية
  double total;

  SalesReturnItemModel({
    this.productName,
    this.barcode,
    this.price = 0.0,
    this.qty = 0.0,
    this.total = 0.0,
  });

  /// إنشاء الصنف من JSON
  factory SalesReturnItemModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final double itemPrice =
        (json['price'] as num?)?.toDouble() ?? 0.0;

    final double itemQty =
        (json['qty'] as num?)?.toDouble() ?? 0.0;

    final double itemTotal =
        (json['total'] as num?)?.toDouble() ??
        (itemPrice * itemQty);

    return SalesReturnItemModel(
      productName: json['productName'] ?? json['name'],
      barcode: json['barcode'],
      price: itemPrice,
      qty: itemQty,
      total: itemTotal,
    );
  }

  /// تحويل الصنف إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'productName': productName,
      'barcode': barcode,
      'price': price,
      'qty': qty,
      'total': total,
    };
  }
}