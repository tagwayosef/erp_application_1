import 'package:isar/isar.dart';

part 'ledger_model.g.dart';

@collection
class LedgerModel {
  // معرف محلي تلقائي
  Id id = Isar.autoIncrement;

  final String? date;         // تاريخ الحركة
  final String? description;  // البيان أو الوصف
  final String? accountName;  // اسم الحساب الرئيسي (مثل: الصندوق الرئيسي، المبيعات، المخزون)[cite: 1]
  final String? partyName;    // الطرف المقابل أو اسم الشخص (مثل: حازم، خالد، اسم العميل/المورد)[cite: 1]
  final double debit;         // مدين[cite: 1]
  final double credit;        // دائن[cite: 1]
  final String? referenceNo;  // رقم المرجع (رقم الفاتورة أو السند)[cite: 1]
  final String? paymentType;  // نوع الدفع: (نقدي / آجل)[cite: 1]
  final String? entryType;    // طبيعة القيد (مثل: مبيعات، مشتريات، سداد، رصيد افتتاحي)[cite: 1]

  LedgerModel({
    this.date,
    this.description,
    this.accountName,
    this.partyName,
    required this.debit,
    required this.credit,
    this.referenceNo,
    this.paymentType,
    this.entryType,
  });

  factory LedgerModel.fromJson(Map<String, dynamic> json) {
    final ledger = LedgerModel(
      date: json['date'],
      description: json['description'] ?? json['note'],
      accountName: json['accountName'] ?? json['account'],
      partyName: json['partyName'] ?? json['party'],
      debit: (json['debit'] as num?)?.toDouble() ?? 0.0,
      credit: (json['credit'] as num?)?.toDouble() ?? 0.0,
      referenceNo: json['referenceNo'] ?? json['ref'],
      paymentType: json['paymentType'],
      entryType: json['entryType'],
    );

    if (json['id'] != null) {
      ledger.id = (json['id'] as num).toInt();
    }

    return ledger;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      
      'description': description,
      'accountName': accountName,
      'partyName': partyName,
      'debit': debit,
      'credit': credit,
      'referenceNo': referenceNo,
      'paymentType': paymentType,
      'entryType': entryType,
    };
  }
}