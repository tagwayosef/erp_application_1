import 'package:isar/isar.dart';
import 'sales_returnItem_model.dart';
part 'sales_return_model.g.dart';

/// نموذج مرتجع المبيعات
///
/// يمثل عملية مرتجع مستقلة عن الفاتورة الأصلية.
@collection
class SalesReturnModel {
  /// المعرف الداخلي لـ Isar
  Id id = Isar.autoIncrement;

  /// رقم فاتورة البيع الأصلية
  String? invoiceNo;

  /// المرجع المستقل للمرتجع
  ///
  /// مثال:
  /// RET-15
  ///
  /// كل مرتجع له مرجع مستقل عن الفاتورة الأصلية.
  String? returnReference;

  /// اسم العميل
  String? customerName;

  /// تاريخ المرتجع
  String? date;

  /// إجمالي قيمة المرتجع
  double totalAmount;

  /// طريقة الدفع الأصلية للفاتورة
  ///
  /// نقدي / آجل
  String? paymentType;

  /// سبب المرتجع
  String? reason;

  /// تفاصيل الأصناف المرتجعة
  List<SalesReturnItemModel> items;

  SalesReturnModel({
    this.invoiceNo,
    this.returnReference,
    this.customerName,
    this.date,
    this.totalAmount = 0.0,
    this.paymentType,
    this.reason,
    this.items = const [],
  });

  /// إنشاء النموذج من JSON
  factory SalesReturnModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final itemsList =
        <SalesReturnItemModel>[];

    if (json['items'] != null &&
        json['items'] is List) {
      for (final item in json['items']) {
        if (item is Map<String, dynamic>) {
          itemsList.add(
            SalesReturnItemModel.fromJson(item),
          );
        }
      }
    }

    final salesReturn =
        SalesReturnModel(
      invoiceNo:
          json['invoiceNo'] ??
          json['invoice'],

      // مهم: قراءة مرجع المرتجع
      returnReference:
          json['returnReference'],

      customerName:
          json['customerName'] ??
          json['customer'],

      date:
          json['date'],

      totalAmount:
          (json['totalAmount'] as num?)
                  ?.toDouble() ??
              0.0,

      paymentType:
          json['paymentType'] ??
          json['type'] ??
          'نقدي',

      reason:
          json['reason'],

      items:
          itemsList,
    );

    if (json['id'] != null) {
      salesReturn.id =
          (json['id'] as num).toInt();
    }

    return salesReturn;
  }

  /// تحويل النموذج إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,

      'invoiceNo':
          invoiceNo,

      // مهم: حفظ مرجع المرتجع
      'returnReference':
          returnReference,

      'customerName':
          customerName,

      'date':
          date,

      'totalAmount':
          totalAmount,

      'paymentType':
          paymentType,

      'reason':
          reason,

      'items':
          items
              .map(
                (item) => item.toJson(),
              )
              .toList(),
    };
  }
}

/// تفاصيل الصنف المرتجع
@embedded
class SalesReturnItemModel {
  /// اسم الصنف
  String? productName;

  /// باركود الصنف
  String? barcode;

  /// سعر بيع الوحدة وقت البيع
  double price;

  /// الكمية التي تم إرجاعها
  double qty;

  /// القيمة الإجمالية للصنف المرتجع
  double total;

  SalesReturnItemModel({
    this.productName,
    this.barcode,
    this.price = 0.0,
    this.qty = 0.0,
    this.total = 0.0,
  });

  /// إنشاء تفاصيل المرتجع من JSON
  factory SalesReturnItemModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final price =
        (json['price'] as num?)
                ?.toDouble() ??
            0.0;

    final qty =
        (json['qty'] as num?)
                ?.toDouble() ??
            0.0;

    final totalFromJson =
        (json['total'] as num?)
            ?.toDouble();

    return SalesReturnItemModel(
      productName:
          json['productName'] ??
          json['name'],

      barcode:
          json['barcode'],

      price:
          price,

      qty:
          qty,

      total:
          totalFromJson ??
          (price * qty),
    );
  }

  /// تحويل تفاصيل المرتجع إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'productName':
          productName,

      'barcode':
          barcode,

      'price':
          price,

      'qty':
          qty,

      'total':
          total,
    };
  }
}