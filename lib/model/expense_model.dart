import 'package:isar/isar.dart';

part 'expense_model.g.dart';

@collection
class ExpenseModel {
  /// المعرف المحلي
  Id id = Isar.autoIncrement;

  /// عنوان المصروف
  String? title;

  /// تصنيف المصروف
  String? category;

  /// إجمالي قيمة المصروف
  double amount;

  /// تاريخ المصروف
  String? date;

  /// ملاحظات
  String? notes;

  /// نوع السداد:
  /// نقدي / آجل
  String? paymentType;

  /// طريقة الدفع:
  /// نقدي / شبكة / تحويل
  String? paymentMethod;

  /// اسم الدائن في حالة المصروف الآجل
  ///
  /// لا علاقة له بالموردين.
  String? creditorName;

  /// المبلغ الذي تم دفعه فعلياً
  ///
  /// في المصروف النقدي = amount
  /// في المصروف الآجل الجديد = 0
  double paidAmount;

  /// المبلغ المتبقي للدائن
  ///
  /// في المصروف النقدي = 0
  /// في المصروف الآجل = amount - paidAmount
  double remainingAmount;

  ExpenseModel({
    this.title,
    this.category,
    required this.amount,
    this.date,
    this.notes,
    this.paymentType,
    this.paymentMethod,
    this.creditorName,
    this.paidAmount = 0.0,
    this.remainingAmount = 0.0,
  });

  /// هل المصروف آجل؟
  bool get isCredit {
    final type = (paymentType ?? '').trim().toLowerCase();

    return type == 'آجل' ||
        type == 'اجل' ||
        type == 'credit';
  }

  /// هل المصروف نقدي؟
  bool get isCash {
    return !isCredit;
  }

  /// الوصف
  String? get description {
    if (notes != null && notes!.trim().isNotEmpty) {
      return notes!.trim();
    }

    return title;
  }

  /// JSON → ExpenseModel
  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    final amount = json['amount'] is num
        ? (json['amount'] as num).toDouble()
        : double.tryParse(
              json['amount']?.toString() ?? '',
            ) ??
            0.0;

    final paymentType =
        json['paymentType']?.toString() ??
        json['payment_type']?.toString();

    final isCredit =
        paymentType?.trim().toLowerCase() == 'آجل' ||
        paymentType?.trim().toLowerCase() == 'اجل' ||
        paymentType?.trim().toLowerCase() == 'credit';

    final paidAmount = json['paidAmount'] is num
        ? (json['paidAmount'] as num).toDouble()
        : double.tryParse(
              json['paidAmount']?.toString() ?? '',
            ) ??
            (isCredit ? 0.0 : amount);

    final remainingAmount = json['remainingAmount'] is num
        ? (json['remainingAmount'] as num).toDouble()
        : double.tryParse(
              json['remainingAmount']?.toString() ?? '',
            ) ??
            (isCredit
                ? (amount - paidAmount).clamp(0.0, double.infinity)
                : 0.0);

    final expense = ExpenseModel(
      title: json['title']?.toString() ??
          json['name']?.toString(),
      category: json['category']?.toString(),
      amount: amount,
      date: json['date']?.toString(),
      notes: json['notes']?.toString(),
      paymentType: paymentType,
      paymentMethod: json['paymentMethod']?.toString() ??
          json['payment_method']?.toString(),
      creditorName: json['creditorName']?.toString() ??
          json['creditor_name']?.toString(),
      paidAmount: paidAmount,
      remainingAmount: remainingAmount,
    );

    final jsonId = json['id'];

    if (jsonId is num) {
      expense.id = jsonId.toInt();
    } else if (jsonId != null) {
      expense.id =
          int.tryParse(jsonId.toString()) ??
          Isar.autoIncrement;
    }

    return expense;
  }

  /// ExpenseModel → JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      'date': date,
      'notes': notes,
      'paymentType': paymentType,
      'paymentMethod': paymentMethod,
      'creditorName': creditorName,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
    };
  }

  /// نسخة معدلة
  ExpenseModel copyWith({
    String? title,
    String? category,
    double? amount,
    String? date,
    String? notes,
    String? paymentType,
    String? paymentMethod,
    String? creditorName,
    double? paidAmount,
    double? remainingAmount,
  }) {
    final expense = ExpenseModel(
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      paymentType: paymentType ?? this.paymentType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      creditorName: creditorName ?? this.creditorName,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount:
          remainingAmount ?? this.remainingAmount,
    );

    expense.id = id;

    return expense;
  }
}