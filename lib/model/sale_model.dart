import 'package:isar/isar.dart';

part 'sale_model.g.dart';

@collection
class SaleModel {
  Id id = Isar.autoIncrement;

  String? invoiceNo;
  String? customerName;

  double totalAmount;

  String? date;

  // نقدي / آجل
  String? paymentType;

  // الحقل القديم المستخدم في الشاشة
  List<String> itemsDetails;

  // الأصناف الفعلية للفاتورة
  List<SaleItem> items;

  SaleModel({
    this.invoiceNo,
    this.customerName,
    required this.totalAmount,
    this.date,
    this.paymentType,
    required this.itemsDetails,
    this.items = const [],
  });

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    var detailsList = <String>[];

    if (json['itemsDetails'] != null) {
      detailsList = List<String>.from(json['itemsDetails']);
    } else if (json['items'] != null) {
      detailsList = (json['items'] as List)
          .map((e) => e.toString())
          .toList();
    }

    var itemsList = <SaleItem>[];

    if (json['items'] != null && json['items'] is List) {
      itemsList = (json['items'] as List).map((x) {
        if (x is Map<String, dynamic>) {
          return SaleItem.fromJson(x);
        }

        return SaleItem(
          productName: x.toString(),
        );
      }).toList();
    }

    final sale = SaleModel(
      invoiceNo: json['invoiceNo'] ?? json['invoice'],
      customerName: json['customerName'] ?? json['customer'],
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      date: json['date'],
      paymentType:
          json['paymentType'] ?? json['type'] ?? 'نقدي',
      itemsDetails: detailsList,
      items: itemsList,
    );

    if (json['id'] != null) {
      sale.id = (json['id'] as num).toInt();
    }

    return sale;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceNo': invoiceNo,
      'customerName': customerName,
      'totalAmount': totalAmount,
      'date': date,
      'paymentType': paymentType,
      'itemsDetails': itemsDetails,
      'items': items.map((x) => x.toJson()).toList(),
    };
  }
}

@embedded
class SaleItem {
  String? productName;
  String? barcode;

  // سعر بيع الوحدة
  double price;

  // الكمية الأصلية المباعة
  double qty;

  SaleItem({
    this.productName,
    this.barcode,
    this.price = 0.0,
    this.qty = 1.0,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      productName: json['productName'],
      barcode: json['barcode'],
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      qty: (json['qty'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productName': productName,
      'barcode': barcode,
      'price': price,
      'qty': qty,
    };
  }
}