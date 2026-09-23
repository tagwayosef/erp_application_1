import 'package:isar/isar.dart';

part 'voucher_model.g.dart';

@collection
class VoucherModel {
  // معرف محلي يتم إنشاؤه تلقائيًا بواسطة Isar
  Id id = Isar.autoIncrement;

  final String? serialNo;
  final String? type;          // 'قبض' أو 'صرف'
  final String? partyName;     // اسم العميل، المورد، أو الجهة المستفيدة من المصروف
  final int? supplierId;       // معرف المورد لربط موثوق (في حال كان سداد دين مورد)
  final String? voucherCategory; // تصنيف السند: 'مورد' أو 'مصروف' (للفصل المحاسبي الدقيق)
  final double amount;
  final String? paymentMethod;
  final String? note;
  final String? date;

  VoucherModel({
    this.serialNo,
    this.type,
    this.partyName,
    this.supplierId,
    this.voucherCategory,
    required this.amount,
    this.paymentMethod,
    this.note,
    this.date,
  });

  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    final voucher = VoucherModel(
      serialNo: json['serialNo'] ?? json['serial'],
      type: json['type'],
      partyName: json['partyName'] ?? json['party'],
      supplierId: json['supplierId'] != null ? (json['supplierId'] as num).toInt() : null,
      voucherCategory: json['voucherCategory'] ?? json['category'],
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['paymentMethod'] ?? json['paymentType'],
      note: json['note'],
      date: json['date'],
    );

    // إذا كان الـ ID قادمًا من مصدر خارجي
    if (json['id'] != null) {
      voucher.id = (json['id'] as num).toInt();
    }

    return voucher;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serialNo': serialNo,
      'type': type,
      'partyName': partyName,
      'supplierId': supplierId,
      'voucherCategory': voucherCategory,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'note': note,
      'date': date,
    };
  }
}