import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

import 'model/voucher_model.dart';
import 'model/sale_model.dart';
import 'model/supplier_model.dart';
import 'model/ledger_model.dart';

import 'package:excel/excel.dart' as excelPkg;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class VouchersScreen extends StatefulWidget {
  const VouchersScreen({Key? key}) : super(key: key);

  @override
  State<VouchersScreen> createState() => _VouchersScreenState();
}

class _VouchersScreenState extends State<VouchersScreen> {
  final GlobalKey<FormState> _receiptFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _paymentFormKey = GlobalKey<FormState>();

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // ============================================================
  // سند القبض
  // ============================================================

  final TextEditingController _receiptNameController =
      TextEditingController();

  final TextEditingController _receiptAmountController =
      TextEditingController();

  final TextEditingController _receiptPaymentMethodController =
      TextEditingController();

  final TextEditingController _receiptNoteController =
      TextEditingController();

  // ============================================================
  // سند الصرف
  // ============================================================

  final TextEditingController _paymentNameController =
      TextEditingController();

  final TextEditingController _paymentAmountController =
      TextEditingController();

  final TextEditingController _paymentPaymentMethodController =
      TextEditingController();

  final TextEditingController _paymentNoteController =
      TextEditingController();

  int? _selectedSupplierId;

  // ============================================================
  // البيانات
  // ============================================================

  List<VoucherModel> _receipts = [];
  List<VoucherModel> _payments = [];

  List<Map<String, dynamic>> _creditCustomersList = [];
  List<Map<String, dynamic>> _suppliersList = [];
  List<Map<String, dynamic>> _creditorsList = [];

  bool _isLoading = true;
  bool _isSavingReceipt = false;
  bool _isSavingPayment = false;

  int? _editingReceiptId;
  int? _editingPaymentId;

  // ============================================================
  // الألوان
  // ============================================================

  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardColor = Colors.white;

  static const Color emeraldColor = Color(0xFF16A34A);
  static const Color orangeColor = Color(0xFFD97706);

  static const Color primaryBlue = Color(0xFF1E40AF);
  static const Color primaryBlueLight = Color(0xFF2563EB);

  // ============================================================
  // دورة الحياة
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  @override
  void dispose() {
    _searchController.dispose();

    _receiptNameController.dispose();
    _receiptAmountController.dispose();
    _receiptPaymentMethodController.dispose();
    _receiptNoteController.dispose();

    _paymentNameController.dispose();
    _paymentAmountController.dispose();
    _paymentPaymentMethodController.dispose();
    _paymentNoteController.dispose();

    super.dispose();
  }

  // ============================================================
  // أدوات محاسبية داخلية
  // ============================================================

  String _newReference(String prefix) {
    return '$prefix-${DateTime.now().millisecondsSinceEpoch}';
  }

  bool _isBankPayment(String paymentMethod) {
    final value = paymentMethod.trim().toLowerCase();

    return value.contains('بنك') ||
        value.contains('شيك') ||
        value.contains('تحويل') ||
        value.contains('bank') ||
        value.contains('check') ||
        value.contains('transfer');
  }

  String _cashOrBankAccount(String paymentMethod) {
    return _isBankPayment(paymentMethod)
        ? 'البنك'
        : 'الصندوق الرئيسي';
  }

  Future<void> _deleteLedgerByReference(
    Isar isar,
    String? referenceNo,
  ) async {
    final reference = referenceNo?.trim() ?? '';

    if (reference.isEmpty) {
      return;
    }

    final ledgers = await isar.ledgerModels
        .filter()
        .referenceNoEqualTo(reference)
        .findAll();

    if (ledgers.isEmpty) {
      return;
    }

    for (final ledger in ledgers) {
      await isar.ledgerModels.delete(ledger.id);
    }
  }

  // ============================================================
  // تحميل البيانات
  // ============================================================

  Future<void> _loadVouchers() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final isar = Isar.getInstance();

      if (isar == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final allVouchers =
          await isar.voucherModels.where().findAll();

      final allSales =
          await isar.saleModels.where().findAll();

      final allSuppliers =
          await isar.supplierModels.where().findAll();


      final allLedgers =
          await isar.ledgerModels.where().findAll();

      // ========================================================
      // فصل سندات القبض والصرف
      // ========================================================

      final allReceiptVouchers = allVouchers.where((v) {
        final type = (v.type ?? '').trim().toLowerCase();

        return type.contains('قبض') || type == 'receipt';
      }).toList();

      final allPaymentVouchers = allVouchers.where((v) {
        final type = (v.type ?? '').trim().toLowerCase();

        final isPayment =
            type.contains('صرف') || type == 'payment';

        // سند الصرف في النظام مخصص للموردين فقط.
        // نستبعد أي سند صرف قديم كان مسجلاً كمصروف مباشر.
        final isSupplierPayment =
            v.supplierId != null ||
            (v.voucherCategory ?? '').trim() == 'مورد';

        return isPayment && isSupplierPayment;
      }).toList();

      // ========================================================
      // مديونية العملاء
      //
      // المصدر:
      // SaleModel.paymentType == آجل
      // ========================================================

      final Map<String, double> customerDebts = {};

      for (final sale in allSales) {
        final paymentType = sale.paymentType?.trim() ?? '';

        if (paymentType == 'آجل') {
          final customerName =
              sale.customerName?.trim() ?? '';

          if (customerName.isEmpty) {
            continue;
          }

          customerDebts[customerName] =
              (customerDebts[customerName] ?? 0.0) +
                  sale.totalAmount;
        }
      }

      // طرح سندات القبض من مديونية العملاء

      for (final voucher in allReceiptVouchers) {
        final partyName =
            voucher.partyName?.trim() ?? '';

        if (partyName.isEmpty) {
          continue;
        }

        if (customerDebts.containsKey(partyName)) {
          customerDebts[partyName] =
              customerDebts[partyName]! - voucher.amount;
        }
      }

      final List<Map<String, dynamic>> creditList = [];

      customerDebts.forEach((name, debt) {
        if (debt > 0.001) {
          creditList.add({
            'name': name,
            'remaining': debt,
          });
        }
      });

      // ========================================================
      // الموردون
      // ========================================================

      final Map<String, int> supplierIds = {};

      for (final supplier in allSuppliers) {
        final name = supplier.name.trim();

        if (name.isNotEmpty) {
          supplierIds[name] = supplier.id;
        }
      }

      // ========================================================
      // حساب أرصدة الموردين من دفتر الأستاذ
      //
      // الرصيد الدائن = credit - debit
      // ========================================================

      final Map<String, double> ledgerSupplierBalances = {};

      for (final ledger in allLedgers) {
        final partyName =
            ledger.partyName?.trim() ?? '';

        if (partyName.isEmpty) {
          continue;
        }

        final accountName =
            ledger.accountName?.trim() ?? '';

        final isSupplierLedger =
            accountName.contains('الموردون') ||
            ledger.entryType == 'سند صرف مورد' ||
            ledger.entryType == 'مشتريات';

        if (!isSupplierLedger) {
          continue;
        }

        ledgerSupplierBalances[partyName] =
            (ledgerSupplierBalances[partyName] ?? 0.0) +
                (ledger.credit - ledger.debit);
      }

      final List<Map<String, dynamic>> suppliersList = [];
      final List<Map<String, dynamic>> creditorsList = [];

      ledgerSupplierBalances.forEach((name, balance) {
        if (balance.abs() <= 0.001) {
          return;
        }

        suppliersList.add({
          'id': supplierIds[name],
          'name': name,
          'balance': balance,
        });

        if (balance > 0.001) {
          creditorsList.add({
            'id': supplierIds[name],
            'name': name,
            'balance': balance,
          });
        }
      });

      // إضافة الموردين الذين ليس لديهم قيود بعد

      for (final supplier in allSuppliers) {
        final name = supplier.name.trim();

        if (name.isEmpty) {
          continue;
        }

        final exists = suppliersList.any(
          (item) =>
              item['name']
                  .toString()
                  .trim()
                  .toLowerCase() ==
              name.toLowerCase(),
        );

        if (!exists) {
          suppliersList.add({
            'id': supplier.id,
            'name': name,
            'balance': supplier.balance,
          });

          if (supplier.balance > 0.001) {
            creditorsList.add({
              'id': supplier.id,
              'name': name,
              'balance': supplier.balance,
            });
          }
        }
      }

      // ========================================================
      // تحديث الواجهة
      // ========================================================

      if (!mounted) {
        return;
      }

      setState(() {
        _receipts = allReceiptVouchers;
        _payments = allPaymentVouchers;

        _creditCustomersList = creditList;
        _suppliersList = suppliersList;
        _creditorsList = creditorsList;

        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading vouchers: $e');

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showMessage(
        'فشل تحميل السندات: $e',
        Colors.red,
      );
    }
  }

  // ============================================================
  // البحث
  // ============================================================

  List<VoucherModel> _filterVouchers(
    List<VoucherModel> vouchers,
  ) {
    final query =
        _searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return vouchers;
    }

    return vouchers.where((voucher) {
      final serial =
          (voucher.serialNo ?? '').toLowerCase();

      final partyName =
          (voucher.partyName ?? '').toLowerCase();

      final paymentMethod =
          (voucher.paymentMethod ?? '').toLowerCase();

      final note =
          (voucher.note ?? '').toLowerCase();

      final amount =
          voucher.amount.toString().toLowerCase();

      final id =
          voucher.id.toString();

      return serial.contains(query) ||
          partyName.contains(query) ||
          paymentMethod.contains(query) ||
          note.contains(query) ||
          amount.contains(query) ||
          id.contains(query);
    }).toList();
  }

  // ============================================================
  // حفظ سند القبض
  // ============================================================

  Future<void> _saveReceipt() async {
    if (!_receiptFormKey.currentState!.validate()) {
      return;
    }

    final amountText =
        _receiptAmountController.text
            .trim()
            .replaceAll(',', '');

    final amount =
        double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      _showMessage(
        'أدخل مبلغًا صحيحًا',
        Colors.orange,
      );
      return;
    }

    final party =
        _receiptNameController.text.trim();

    if (party.isEmpty) {
      _showMessage(
        'اسم العميل مطلوب',
        Colors.orange,
      );
      return;
    }

    if (mounted) {
      setState(() {
        _isSavingReceipt = true;
      });
    }

    try {
      final isar = Isar.getInstance();

      if (isar == null) {
        throw Exception('قاعدة البيانات غير متاحة');
      }

      final isEditing =
          _editingReceiptId != null;

      VoucherModel? oldVoucher;

      if (isEditing) {
        try {
          oldVoucher = _receipts.firstWhere(
            (v) => v.id == _editingReceiptId,
          );
        } catch (_) {
          oldVoucher =
              await isar.voucherModels.get(
            _editingReceiptId!,
          );
        }
      }

      // ========================================================
      // المرجع ثابت في حالة التعديل
      // ========================================================

      final serial =
          oldVoucher?.serialNo?.trim().isNotEmpty == true
              ? oldVoucher!.serialNo!.trim()
              : _newReference('REC');

      final currentDate =
          DateTime.now()
              .toIso8601String()
              .substring(0, 16);

      final paymentMethod =
          _receiptPaymentMethodController.text
                  .trim()
                  .isEmpty
              ? 'نقدي'
              : _receiptPaymentMethodController.text
                  .trim();

      final note =
          _receiptNoteController.text.trim();

      await isar.writeTxn(() async {
        // ======================================================
        // 1. حذف القيود القديمة للسند عند التعديل
        // ======================================================

        if (isEditing && oldVoucher != null) {
          await _deleteLedgerByReference(
            isar,
            oldVoucher!.serialNo,
          );
        }

        // ======================================================
        // 2. إنشاء / تحديث السند
        // ======================================================

        final voucher = VoucherModel(
          serialNo: serial,
          type: 'قبض',
          partyName: party,
          amount: amount!,
          paymentMethod: paymentMethod,
          note: note,
          date: oldVoucher?.date ?? currentDate,
        );

        if (isEditing) {
          voucher.id = _editingReceiptId!;
        }

        await isar.voucherModels.put(voucher);

        // ======================================================
        // 3. القيد المحاسبي
        //
        // سند قبض:
        //
        // مدين  الصندوق / البنك
        // دائن  العملاء
        // ======================================================

        final cashAccount =
            _cashOrBankAccount(paymentMethod);

        final description =
            note.isNotEmpty
                ? 'سند قبض - العميل: $party - $note'
                : 'سند قبض - العميل: $party';

        final debitEntry = LedgerModel(
          date: voucher.date ?? currentDate,
          description: description,
          accountName: cashAccount,
          partyName: party,
          debit: amount,
          credit: 0.0,
          referenceNo: serial,
          paymentType: paymentMethod,
          entryType: 'سند قبض',
        );

        final creditEntry = LedgerModel(
          date: voucher.date ?? currentDate,
          description: description,
          accountName: 'العملاء',
          partyName: party,
          debit: 0.0,
          credit: amount,
          referenceNo: serial,
          paymentType: paymentMethod,
          entryType: 'سند قبض',
        );

        await isar.ledgerModels.putAll([
          debitEntry,
          creditEntry,
        ]);
      });

      if (!mounted) {
        return;
      }

      _clearReceiptForm();

      _showMessage(
        isEditing
            ? 'تم تعديل سند القبض وتحديث دفتر الأستاذ بنجاح ✅'
            : 'تم حفظ سند القبض وترحيل القيد بنجاح ✅',
        Colors.green,
      );

      await _loadVouchers();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'خطأ في حفظ سند القبض: $e',
        Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingReceipt = false;
        });
      }
    }
  }

  // ============================================================
  // حفظ سند الصرف
  // ============================================================

Future<void> _savePayment() async {
    if (!_paymentFormKey.currentState!.validate()) {
      return;
    }

    final amountText =
        _paymentAmountController.text.trim().replaceAll(',', '');
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      _showMessage('أدخل مبلغًا صحيحًا', Colors.orange);
      return;
    }

    final party = _paymentNameController.text.trim();

    if (party.isEmpty) {
      _showMessage('اسم المورد مطلوب', Colors.orange);
      return;
    }

    if (_selectedSupplierId == null) {
      _showMessage(
        'يجب اختيار المورد من القائمة لربط سند الصرف بحسابه',
        Colors.orange,
      );
      return;
    }

    if (mounted) {
      setState(() {
        _isSavingPayment = true;
      });
    }

    try {
      final isar = Isar.getInstance();
      if (isar == null) {
        throw Exception('قاعدة البيانات غير متاحة');
      }

      final isEditing = _editingPaymentId != null;
      VoucherModel? oldVoucher;

      if (isEditing) {
        try {
          oldVoucher = _payments.firstWhere(
            (v) => v.id == _editingPaymentId,
          );
        } catch (_) {
          oldVoucher = await isar.voucherModels.get(_editingPaymentId!);
        }
      }

      if (oldVoucher != null && oldVoucher.supplierId == null) {
        throw Exception(
          'سند الصرف القديم غير مرتبط بمورد، ولا يمكن تعديله كسند صرف مورد.',
        );
      }

      final serial =
          oldVoucher?.serialNo?.trim().isNotEmpty == true
              ? oldVoucher!.serialNo!.trim()
              : _newReference('PAY');

      final currentDate =
          DateTime.now().toIso8601String().substring(0, 16);

      final paymentMethod =
          _paymentPaymentMethodController.text.trim().isEmpty
              ? 'نقدي'
              : _paymentPaymentMethodController.text.trim();

      final note = _paymentNoteController.text.trim();

      await isar.writeTxn(() async {
        // ======================================================
        // 1. عند التعديل: إعادة مبلغ السند القديم للمورد أولاً
        // ======================================================
        if (isEditing && oldVoucher != null) {
          final oldSupplierId = oldVoucher!.supplierId;

          if (oldSupplierId != null) {
            final oldSupplier =
                await isar.supplierModels.get(oldSupplierId);

            if (oldSupplier != null) {
              oldSupplier.balance += oldVoucher!.amount;
              await isar.supplierModels.put(oldSupplier);
            }
          }

          // حذف القيد القديم قبل إنشاء القيد الجديد
          await _deleteLedgerByReference(
            isar,
            oldVoucher!.serialNo,
          );
        }

        // ======================================================
        // 2. جلب المورد الحالي والتحقق من الرصيد
        // ======================================================
        final supplier =
            await isar.supplierModels.get(_selectedSupplierId!);

        if (supplier == null) {
          throw Exception('المورد المحدد غير موجود');
        }

        if (amount > supplier.balance + 0.001) {
          throw Exception(
            'المبلغ المدفوع (${amount.toStringAsFixed(2)}) أكبر من الرصيد المستحق للمورد (${supplier.balance.toStringAsFixed(2)})',
          );
        }

        // ======================================================
        // 3. تحديث رصيد المورد
        // ======================================================
        supplier.balance -= amount;

        if (supplier.balance.abs() < 0.001) {
          supplier.balance = 0.0;
        }

        await isar.supplierModels.put(supplier);

        // ======================================================
        // 4. إنشاء / تحديث سند الصرف
        // ======================================================
        final voucher = VoucherModel(
          serialNo: serial,
          type: 'صرف',
          partyName: supplier.name.trim().isNotEmpty
              ? supplier.name.trim()
              : party,
          supplierId: supplier.id,
          voucherCategory: 'مورد',
          amount: amount,
          paymentMethod: paymentMethod,
          note: note,
          date: oldVoucher?.date ?? currentDate,
        );

        if (isEditing) {
          voucher.id = _editingPaymentId!;
        }

        await isar.voucherModels.put(voucher);

        // ======================================================
        // 5. القيد المحاسبي
        // سند صرف المورد:
        // مدين: الموردون
        // دائن: الصندوق / البنك
        // ======================================================
        final debitAccount = 'الموردون';
        final creditAccount = _cashOrBankAccount(paymentMethod);
        const entryType = 'سند صرف مورد';

        final description = note.isNotEmpty
            ? 'سند صرف مورد - ${voucher.partyName}: $note'
            : 'سند صرف مورد - ${voucher.partyName}';

        final debitEntry = LedgerModel(
          date: voucher.date ?? currentDate,
          description: description,
          accountName: debitAccount,
          partyName: voucher.partyName,
          debit: amount,
          credit: 0.0,
          referenceNo: serial,
          paymentType: paymentMethod,
          entryType: entryType,
        );

        final creditEntry = LedgerModel(
          date: voucher.date ?? currentDate,
          description: description,
          accountName: creditAccount,
          partyName: voucher.partyName,
          debit: 0.0,
          credit: amount,
          referenceNo: serial,
          paymentType: paymentMethod,
          entryType: entryType,
        );

        await isar.ledgerModels.putAll([
          debitEntry,
          creditEntry,
        ]);
      });

      if (!mounted) return;

      _clearPaymentForm();
      _showMessage(
        isEditing
            ? 'تم تعديل سند الصرف للمورد وتحديث رصيده ودفتر الأستاذ بنجاح ✅'
            : 'تم حفظ سند الصرف للمورد وتحديث رصيده ودفتر الأستاذ بنجاح ✅',
        Colors.green,
      );

      await _loadVouchers();
    } catch (e) {
      if (!mounted) return;
      _showMessage('خطأ في حفظ سند الصرف: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isSavingPayment = false;
        });
      }
    }
  }

  // ============================================================
  // تعديل سند القبض
  // ============================================================

  void _editReceipt(VoucherModel voucher) {
    setState(() {
      _editingReceiptId = voucher.id;

      _receiptNameController.text =
          voucher.partyName ?? '';

      _receiptAmountController.text =
          voucher.amount.toString();

      _receiptPaymentMethodController.text =
          voucher.paymentMethod ?? '';

      _receiptNoteController.text =
          voucher.note ?? '';
    });

    _showMessage(
      'تم تحميل سند القبض للتعديل ✏️',
      Colors.blue,
    );
  }

  // ============================================================
  // تعديل سند الصرف
  // ============================================================

  void _editPayment(VoucherModel voucher) {
    if (voucher.supplierId == null) {
      _showMessage(
        'هذا السند غير مرتبط بمورد، ولا يمكن تعديله كسند صرف مورد.',
        Colors.red,
      );
      return;
    }

    setState(() {
      _editingPaymentId = voucher.id;
      _paymentNameController.text = voucher.partyName ?? '';
      _paymentAmountController.text = voucher.amount.toString();
      _paymentPaymentMethodController.text = voucher.paymentMethod ?? '';
      _paymentNoteController.text = voucher.note ?? '';
      _selectedSupplierId = voucher.supplierId;
    });

    _showMessage(
      'تم تحميل سند الصرف للمورد للتعديل ✏️',
      Colors.blue,
    );
  }

  // ============================================================
  // حذف سند القبض
  // ============================================================

  Future<void> _deleteReceipt(
    VoucherModel voucher,
  ) async {
    if (!await _confirmDelete(voucher)) {
      return;
    }

    try {
      final isar = Isar.getInstance();

      if (isar == null) {
        throw Exception(
          'قاعدة البيانات غير متاحة',
        );
      }

      await isar.writeTxn(() async {
        // حذف جميع قيود السند بواسطة المرجع الثابت
        await _deleteLedgerByReference(
          isar,
          voucher.serialNo,
        );

        // حذف السند نفسه
        await isar.voucherModels.delete(
          voucher.id,
        );
      });

      if (!mounted) {
        return;
      }

      if (_editingReceiptId == voucher.id) {
        _clearReceiptForm();
      }

      _showMessage(
        'تم حذف سند القبض وقيوده من دفتر الأستاذ بنجاح 🗑️✅',
        Colors.green,
      );

      await _loadVouchers();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'خطأ في حذف سند القبض: $e',
        Colors.red,
      );
    }
  }

  // ============================================================
  // حذف سند الصرف
  // ============================================================

  Future<void> _deletePayment(
    VoucherModel voucher,
  ) async {
    if (!await _confirmDelete(voucher)) {
      return;
    }

    try {
      final isar = Isar.getInstance();

      if (isar == null) {
        throw Exception(
          'قاعدة البيانات غير متاحة',
        );
      }

      await isar.writeTxn(() async {
        // ======================================================
        // 1. عكس أثر السداد على المورد
        // ======================================================

        if (voucher.supplierId != null) {
          final supplier =
              await isar.supplierModels.get(
            voucher.supplierId!,
          );

          if (supplier != null) {
            supplier.balance +=
                voucher.amount;

            await isar.supplierModels.put(
              supplier,
            );
          }
        }

        // ======================================================
        // 2. حذف القيود بواسطة رقم السند
        // ======================================================

        await _deleteLedgerByReference(
          isar,
          voucher.serialNo,
        );

        // ======================================================
        // 3. حذف السند
        // ======================================================

        await isar.voucherModels.delete(
          voucher.id,
        );
      });

      if (!mounted) {
        return;
      }

      if (_editingPaymentId == voucher.id) {
        _clearPaymentForm();
      }

      _showMessage(
        'تم حذف سند الصرف وعكس أثره في دفتر الأستاذ بنجاح 🗑️✅',
        Colors.green,
      );

      await _loadVouchers();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'خطأ في حذف سند الصرف: $e',
        Colors.red,
      );
    }
  }

  // ============================================================
  // تأكيد الحذف
  // ============================================================

  Future<bool> _confirmDelete(
    VoucherModel voucher,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final isReceipt =
            (voucher.type ?? '')
                    .trim()
                    .contains('قبض') ||
                voucher.type == 'receipt';

        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: const Text(
            'تأكيد الحذف',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'هل أنت متأكد من حذف '
            '${isReceipt ? 'سند القبض' : 'سند الصرف'} '
            '${voucher.serialNo ?? voucher.id}؟\n\n'
            'سيتم حذف جميع القيود المرتبطة بهذا السند من دفتر الأستاذ.',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF475569),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'إلغاء',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.redAccent,
                foregroundColor:
                    Colors.white,
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'حذف وعكس القيد',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  // ============================================================
  // تفاصيل السند
  // ============================================================

  void _showVoucherDetails(
    VoucherModel voucher,
    bool isReceipt,
  ) {
    final mainColor =
        isReceipt
            ? emeraldColor
            : orangeColor;

    final voucherNumber =
        voucher.serialNo != null &&
                voucher.serialNo!.trim().isNotEmpty
            ? voucher.serialNo!
            : '${isReceipt ? 'REC' : 'PAY'}-${voucher.id}';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Directionality(
          textDirection:
              TextDirection.rtl,
          child: Container(
            padding:
                const EdgeInsets.all(22),
            decoration:
                const BoxDecoration(
              color: cardColor,
              borderRadius:
                  BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              child:
                  SingleChildScrollView(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 45,
                        height: 5,
                        decoration:
                            BoxDecoration(
                          color:
                              Colors.grey[300],
                          borderRadius:
                              BorderRadius.circular(
                            20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor:
                              mainColor
                                  .withOpacity(
                            0.12,
                          ),
                          child: Icon(
                            isReceipt
                                ? Icons
                                    .arrow_downward_rounded
                                : Icons
                                    .arrow_upward_rounded,
                            color: mainColor,
                          ),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Expanded(
                          child: Text(
                            isReceipt
                                ? 'تفاصيل سند القبض'
                                : 'تفاصيل سند الصرف',
                            style:
                                const TextStyle(
                              color: Color(
                                0xFF1E293B,
                              ),
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    _detailRow(
                      'رقم السند',
                      voucherNumber,
                      mainColor,
                    ),
                    _detailRow(
                      'التصنيف',
                      voucher.voucherCategory !=
                                  null &&
                              voucher
                                  .voucherCategory!
                                  .trim()
                                  .isNotEmpty
                          ? voucher
                              .voucherCategory!
                          : isReceipt
                              ? 'قبض عميل'
                              : 'صرف',
                      mainColor,
                    ),
                    _detailRow(
                      'الاسم / الجهة',
                      voucher.partyName ??
                          '---',
                      mainColor,
                    ),
                    _detailRow(
                      'طريقة الدفع',
                      voucher.paymentMethod
                                  ?.isNotEmpty ==
                              true
                          ? voucher
                              .paymentMethod!
                          : '---',
                      mainColor,
                    ),
                    _detailRow(
                      'المبلغ',
                      '${voucher.amount.toStringAsFixed(2)} ر.ي',
                      mainColor,
                    ),
                    _detailRow(
                      'البيان',
                      voucher.note ??
                          '---',
                      mainColor,
                    ),
                    _detailRow(
                      'التاريخ',
                      voucher.date ??
                          '---',
                      mainColor,
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child:
                              ElevatedButton.icon(
                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor:
                                  primaryBlue,
                              foregroundColor:
                                  Colors.white,
                              minimumSize:
                                  const Size(
                                double.infinity,
                                52,
                              ),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  14,
                                ),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              Navigator.pop(
                                sheetContext,
                              );

                              if (isReceipt) {
                                _editReceipt(
                                  voucher,
                                );
                              } else {
                                _editPayment(
                                  voucher,
                                );
                              }
                            },
                            icon: const Icon(
                              Icons
                                  .edit_rounded,
                            ),
                            label:
                                const Text(
                              'تعديل',
                              style:
                                  TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child:
                              OutlinedButton.icon(
                            style:
                                OutlinedButton.styleFrom(
                              foregroundColor:
                                  primaryBlue,
                              side:
                                  const BorderSide(
                                color:
                                    primaryBlue,
                              ),
                              minimumSize:
                                  const Size(
                                double.infinity,
                                52,
                              ),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  14,
                                ),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(
                                sheetContext,
                              );

                              _printVoucher(
                                voucher,
                              );
                            },
                            icon: const Icon(
                              Icons
                                  .print_rounded,
                            ),
                            label:
                                const Text(
                              'طباعة',
                              style:
                                  TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(
    String title,
    String value,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      padding:
          const EdgeInsets.all(14),
      decoration:
          BoxDecoration(
        color: backgroundColor,
        borderRadius:
            BorderRadius.circular(14),
        border:
            Border.all(
          color:
              const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            '$title:',
            style: TextStyle(
              color: color,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(
            width: 8,
          ),
          Expanded(
            child: Text(
              value,
              textAlign:
                  TextAlign.left,
              style:
                  const TextStyle(
                color:
                    Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // طباعة السند
  // ============================================================

  Future<void> _printVoucher(
    VoucherModel voucher,
  ) async {
    try {
      final pdf = pw.Document();

      final arabicFont =
          await PdfGoogleFonts.cairoRegular();

      final arabicFontBold =
          await PdfGoogleFonts.cairoBold();

      final isReceipt =
          (voucher.type ?? '')
                  .trim()
                  .contains('قبض') ||
              voucher.type == 'receipt';

      final voucherNumber =
          voucher.serialNo != null &&
                  voucher.serialNo!.trim().isNotEmpty
              ? voucher.serialNo!
              : '${isReceipt ? 'REC' : 'PAY'}-${voucher.id}';

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Directionality(
              textDirection:
                  pw.TextDirection.rtl,
              child: pw.Container(
                padding:
                    const pw.EdgeInsets.all(
                  30,
                ),
                child: pw.Column(
                  crossAxisAlignment:
                      pw.CrossAxisAlignment
                          .stretch,
                  children: [
                    pw.Center(
                      child: pw.Text(
                        isReceipt
                            ? 'سند قبض'
                            : 'سند صرف',
                        style:
                            pw.TextStyle(
                          font:
                              arabicFontBold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    pw.SizedBox(
                      height: 8,
                    ),
                    pw.Center(
                      child: pw.Text(
                        voucherNumber,
                        style:
                            pw.TextStyle(
                          font:
                              arabicFontBold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    pw.SizedBox(
                      height: 25,
                    ),
                    pw.Divider(),
                    pw.SizedBox(
                      height: 15,
                    ),
                    pw.Text(
                      'رقم السند: $voucherNumber',
                      style:
                          pw.TextStyle(
                        font:
                            arabicFont,
                        fontSize: 14,
                      ),
                    ),
                    pw.SizedBox(
                      height: 10,
                    ),
                    pw.Text(
                      'الاسم / الجهة: ${voucher.partyName ?? '---'}',
                      style:
                          pw.TextStyle(
                        font:
                            arabicFont,
                        fontSize: 14,
                      ),
                    ),
                    pw.SizedBox(
                      height: 10,
                    ),
                    pw.Text(
                      'المبلغ: ${voucher.amount.toStringAsFixed(2)} ر.ي',
                      style:
                          pw.TextStyle(
                        font:
                            arabicFontBold,
                        fontSize: 16,
                      ),
                    ),
                    pw.SizedBox(
                      height: 10,
                    ),
                    pw.Text(
                      'طريقة الدفع: ${voucher.paymentMethod ?? '---'}',
                      style:
                          pw.TextStyle(
                        font:
                            arabicFont,
                        fontSize: 14,
                      ),
                    ),
                    pw.SizedBox(
                      height: 10,
                    ),
                    pw.Text(
                      'التصنيف: ${voucher.voucherCategory ?? (isReceipt ? 'قبض عميل' : 'مورد')}',
                      style:
                          pw.TextStyle(
                        font:
                            arabicFont,
                        fontSize: 14,
                      ),
                    ),
                    pw.SizedBox(
                      height: 10,
                    ),
                    pw.Text(
                      'البيان: ${voucher.note ?? '---'}',
                      style:
                          pw.TextStyle(
                        font:
                            arabicFont,
                        fontSize: 14,
                      ),
                    ),
                    pw.SizedBox(
                      height: 10,
                    ),
                    pw.Text(
                      'التاريخ: ${voucher.date ?? '---'}',
                      style:
                          pw.TextStyle(
                        font:
                            arabicFont,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async =>
            pdf.save(),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'فشل طباعة السند: $e',
        Colors.red,
      );
    }
  }

  // ============================================================
  // تصدير Excel
  // ============================================================

  Future<void> _exportToExcel() async {
    try {
      final excel =
          excelPkg.Excel.createExcel();

      final sheet =
          excel['Vouchers'];

      sheet.appendRow([
        excelPkg.TextCellValue('ID'),
        excelPkg.TextCellValue(
          'رقم السند',
        ),
        excelPkg.TextCellValue('النوع'),
        excelPkg.TextCellValue(
          'التصنيف',
        ),
        excelPkg.TextCellValue(
          'الاسم / الجهة',
        ),
        excelPkg.TextCellValue(
          'طريقة الدفع',
        ),
        excelPkg.TextCellValue(
          'المبلغ',
        ),
        excelPkg.TextCellValue(
          'البيان',
        ),
        excelPkg.TextCellValue(
          'التاريخ',
        ),
      ]);

      final allVouchers = [
        ..._receipts,
        ..._payments,
      ];

      for (final voucher in allVouchers) {
        final isReceipt =
            (voucher.type ?? '')
                    .trim()
                    .contains('قبض') ||
                voucher.type == 'receipt';

        sheet.appendRow([
          excelPkg.IntCellValue(
            voucher.id,
          ),
          excelPkg.TextCellValue(
            voucher.serialNo ?? '',
          ),
          excelPkg.TextCellValue(
            isReceipt
                ? 'قبض'
                : 'صرف',
          ),
          excelPkg.TextCellValue(
            voucher.voucherCategory ??
                (isReceipt
                    ? 'قبض عميل'
                    : 'مورد'),
          ),
          excelPkg.TextCellValue(
            voucher.partyName ?? '',
          ),
          excelPkg.TextCellValue(
            voucher.paymentMethod ?? '',
          ),
          excelPkg.DoubleCellValue(
            voucher.amount,
          ),
          excelPkg.TextCellValue(
            voucher.note ?? '',
          ),
          excelPkg.TextCellValue(
            voucher.date ?? '',
          ),
        ]);
      }

      final directory =
          await getTemporaryDirectory();

      final path =
          '${directory.path}/Vouchers_Report.xlsx';

      final bytes =
          excel.encode();

      if (bytes == null) {
        throw Exception(
          'تعذر إنشاء ملف Excel',
        );
      }

      final file = File(path);

      await file.writeAsBytes(
        bytes,
        flush: true,
      );

      await Share.shareXFiles(
        [
          XFile(path),
        ],
        text:
            'تقرير سندات القبض والصرف',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'تم تصدير ملف الإكسل بنجاح 📊',
        Colors.green,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'فشل التصدير: $e',
        Colors.red,
      );
    }
  }

  // ============================================================
  // النسخة الاحتياطية
  // ============================================================

  Future<void> _createBackup() async {
    try {
      final backupData =
          <String, dynamic>{
        'app': 'OmarStoreDB',
        'date':
            DateTime.now().toIso8601String(),
        'receipts':
            _receipts
                .map(
                  (e) => e.toJson(),
                )
                .toList(),
        'payments':
            _payments
                .map(
                  (e) => e.toJson(),
                )
                .toList(),
      };

      final jsonString =
          jsonEncode(backupData);

      final directory =
          await getTemporaryDirectory();

      final path =
          '${directory.path}/OmarStore_Vouchers_Backup.json';

      final file = File(path);

      await file.writeAsString(
        jsonString,
        flush: true,
      );

      await Share.shareXFiles(
        [
          XFile(path),
        ],
        text:
            'نسخة احتياطية لسندات القبض والصرف',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'تم إنشاء النسخة الاحتياطية بنجاح 💾',
        Colors.green,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'فشل النسخ الاحتياطي: $e',
        Colors.red,
      );
    }
  }

  // ============================================================
  // تنظيف نموذج القبض
  // ============================================================

  void _clearReceiptForm() {
    _receiptNameController.clear();
    _receiptAmountController.clear();
    _receiptPaymentMethodController.clear();
    _receiptNoteController.clear();

    if (mounted) {
      setState(() {
        _editingReceiptId = null;
      });
    }
  }

  // ============================================================
  // تنظيف نموذج الصرف
  // ============================================================

  void _clearPaymentForm() {
    _paymentNameController.clear();
    _paymentAmountController.clear();
    _paymentPaymentMethodController.clear();
    _paymentNoteController.clear();

    if (mounted) {
      setState(() {
        _editingPaymentId = null;
        _selectedSupplierId = null;
      });
    }
  }

  // ============================================================
  // رسالة
  // ============================================================

  void _showMessage(
    String message,
    Color color,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            textAlign: TextAlign.right,
          ),
          backgroundColor: color,
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // بناء الشاشة
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          backgroundColor,
      appBar: AppBar(
        backgroundColor:
            primaryBlue,
        elevation: 0,
        title: const Text(
          'إدارة سندات القبض والصرف',
          style: TextStyle(
            color: Colors.white,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        iconTheme:
            const IconThemeData(
          color: Colors.white,
        ),
        actions: [
          IconButton(
            tooltip: 'تصدير إكسل',
            onPressed:
                _exportToExcel,
            icon: const Icon(
              Icons
                  .table_chart_rounded,
              color:
                  Colors.greenAccent,
            ),
          ),
          IconButton(
            tooltip: 'نسخة احتياطية',
            onPressed:
                _createBackup,
            icon: const Icon(
              Icons
                  .backup_rounded,
              color:
                  Colors.amberAccent,
            ),
          ),
          IconButton(
            tooltip: 'تحديث',
            onPressed:
                _isLoading
                    ? null
                    : _loadVouchers,
            icon: const Icon(
              Icons
                  .refresh_rounded,
              color:
                  Colors.white,
            ),
          ),
        ],
      ),
      body: Directionality(
        textDirection:
            TextDirection.rtl,
        child:
            RefreshIndicator(
          color:
              primaryBlue,
          onRefresh:
              _loadVouchers,
          child:
              SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.all(
              20,
            ),
            child: Column(
              children: [
                TextField(
                  controller:
                      _searchController,
                  style:
                      const TextStyle(
                    color:
                        Color(0xFF1E293B),
                  ),
                  onChanged:
                      (value) {
                    setState(() {
                      _searchQuery =
                          value;
                    });
                  },
                  decoration:
                      InputDecoration(
                    hintText:
                        'ابحث برقم السند أو الاسم أو طريقة الدفع...',
                    hintStyle:
                        const TextStyle(
                      color:
                          Colors.grey,
                      fontSize: 13,
                    ),
                    prefixIcon:
                        const Icon(
                      Icons
                          .search_rounded,
                      color:
                          primaryBlueLight,
                    ),
                    suffixIcon:
                        _searchQuery
                                .isNotEmpty
                            ? IconButton(
                                icon:
                                    const Icon(
                                  Icons
                                      .clear_rounded,
                                  color:
                                      Colors.grey,
                                ),
                                onPressed:
                                    () {
                                  _searchController
                                      .clear();

                                  setState(
                                    () {
                                      _searchQuery =
                                          '';
                                    },
                                  );
                                },
                              )
                            : null,
                    filled:
                        true,
                    fillColor:
                        cardColor,
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        16,
                      ),
                      borderSide:
                          const BorderSide(
                        color:
                            Color(
                          0xFFCBD5E1,
                        ),
                      ),
                    ),
                    enabledBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        16,
                      ),
                      borderSide:
                          const BorderSide(
                        color:
                            Color(
                          0xFFCBD5E1,
                        ),
                      ),
                    ),
                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        16,
                      ),
                      borderSide:
                          const BorderSide(
                        color:
                            primaryBlue,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                LayoutBuilder(
                  builder:
                      (
                    context,
                    constraints,
                  ) {
                    final wide =
                        constraints
                                .maxWidth >=
                            900;

                    if (wide) {
                      return Row(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Expanded(
                            child:
                                _buildReceiptVoucherCard(),
                          ),
                          const SizedBox(
                            width: 20,
                          ),
                          Expanded(
                            child:
                                _buildPaymentVoucherCard(),
                          ),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        _buildReceiptVoucherCard(),
                        const SizedBox(
                          height: 20,
                        ),
                        _buildPaymentVoucherCard(),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // بطاقة سند القبض
  // ============================================================

 Widget _buildReceiptVoucherCard() {
  final editing = _editingReceiptId != null;

  final list = _filterVouchers(_receipts);

  final mainColor = emeraldColor;

  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(30),
      border: Border(
        top: BorderSide(
          color: mainColor,
          width: 4,
        ),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.blue.withOpacity(0.04),
          blurRadius: 15,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // =========================================================
        // العنوان
        // =========================================================
        Row(
          children: [
            Expanded(
              child: Text(
                editing
                    ? '✏️ تعديل سند قبض'
                    : '🟢 إصدار سند قبض (العملاء)',
                style: TextStyle(
                  color: mainColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (editing)
              IconButton(
                tooltip: 'إلغاء التعديل',
                onPressed: _clearReceiptForm,
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.redAccent,
                ),
              ),
          ],
        ),

        const SizedBox(height: 20),

        // =========================================================
        // النموذج
        // =========================================================
        Form(
          key: _receiptFormKey,
          child: Column(
            children: [
              // =====================================================
              // اختيار العميل
              // =====================================================
              Autocomplete<Map<String, dynamic>>(
                optionsBuilder: (TextEditingValue value) {
                  // -------------------------------------------------
                  // العملاء الذين لديهم رصيد مستحق فقط
                  // -------------------------------------------------
                  final customersWithDebt =
                      _creditCustomersList.where((customer) {
                    final remainingValue =
                        customer['remaining'] ?? 0.0;

                    final remaining = remainingValue is num
                        ? remainingValue.toDouble()
                        : double.tryParse(
                              remainingValue.toString(),
                            ) ??
                            0.0;

                    return remaining > 0.01;
                  });

                  // -------------------------------------------------
                  // إذا لم يكتب المستخدم شيئًا
                  // أعرض جميع العملاء الذين عليهم دين
                  // -------------------------------------------------
                  if (value.text.trim().isEmpty) {
                    return customersWithDebt;
                  }

                  // -------------------------------------------------
                  // البحث باسم العميل
                  // -------------------------------------------------
                  return customersWithDebt.where((customer) {
                    final name =
                        customer['name']?.toString() ?? '';

                    return name.toLowerCase().contains(
                          value.text.trim().toLowerCase(),
                        );
                  });
                },

                // ---------------------------------------------------
                // النص الظاهر في خانة الاختيار
                // ---------------------------------------------------
                displayStringForOption: (option) {
                  return option['name'].toString();
                },

                // ---------------------------------------------------
                // عند اختيار العميل
                // ---------------------------------------------------
                onSelected: (selection) {
                  final remainingValue =
                      selection['remaining'] ?? 0.0;

                  final remaining = remainingValue is num
                      ? remainingValue.toDouble()
                      : double.tryParse(
                            remainingValue.toString(),
                          ) ??
                          0.0;

                  setState(() {
                    // اسم العميل
                    _receiptNameController.text =
                        selection['name'].toString();

                    // وضع كامل الدين المتبقي تلقائيًا
                    _receiptAmountController.text =
                        remaining.toStringAsFixed(2);

                    // البيان
                    _receiptNoteController.text =
                        'سداد من المبيعات الآجلة '
                        '(المتبقي عليه: '
                        '${remaining.toStringAsFixed(2)} ر.ي)';
                  });
                },

                // ===================================================
                // خانة البحث والكتابة
                // ===================================================
                fieldViewBuilder: (
                  context,
                  textController,
                  focusNode,
                  onFieldSubmitted,
                ) {
                  // -------------------------------------------------
                  // المحافظة على اسم العميل عند التعديل
                  // -------------------------------------------------
                  if (_receiptNameController.text.isNotEmpty &&
                      textController.text.isEmpty) {
                    textController.text =
                        _receiptNameController.text;
                  }

                  return TextFormField(
                    controller: textController,
                    focusNode: focusNode,

                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                    ),

                    decoration: _inputDecoration(
                      '🔍 ابحث أو اكتب اسم العميل...',
                      primaryBlue,
                    ).copyWith(
                      prefixIcon: const Icon(
                        Icons.person_search_rounded,
                        color: primaryBlueLight,
                      ),
                      suffixIcon: const Icon(
                        Icons.arrow_drop_down_rounded,
                        color: primaryBlue,
                      ),
                    ),

                    // ------------------------------------------------
                    // عند الكتابة
                    // ------------------------------------------------
                    onChanged: (value) {
                      _receiptNameController.text =
                          value.trim();

                      // إذا حذف المستخدم اسم العميل
                      // نحذف المبلغ والبيان
                      if (value.trim().isEmpty) {
                        _receiptAmountController.clear();
                        _receiptNoteController.clear();
                      }
                    },

                    // ------------------------------------------------
                    // التحقق من العميل
                    // ------------------------------------------------
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'اسم العميل مطلوب';
                      }

                      final name = value.trim();

                      final customerExists =
                          _creditCustomersList.any(
                        (customer) {
                          final customerName =
                              customer['name']
                                      ?.toString()
                                      .trim() ??
                                  '';

                          final remainingValue =
                              customer['remaining'] ?? 0.0;

                          final remaining =
                              remainingValue is num
                                  ? remainingValue.toDouble()
                                  : double.tryParse(
                                        remainingValue
                                            .toString(),
                                      ) ??
                                      0.0;

                          return customerName == name &&
                              remaining > 0.01;
                        },
                      );

                      if (!customerExists) {
                        return 'هذا العميل غير موجود أو لا يوجد عليه مبلغ مستحق';
                      }

                      return null;
                    },
                  );
                },

                // ===================================================
                // قائمة العملاء
                // ===================================================
                optionsViewBuilder: (
                  context,
                  onSelected,
                  options,
                ) {
                  return Align(
                    alignment: Alignment.topRight,
                    child: Material(
                      elevation: 6,
                      borderRadius:
                          BorderRadius.circular(16),
                      child: Container(
                        width: 340,
                        constraints:
                            const BoxConstraints(
                          maxHeight: 240,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: options.length,
                          itemBuilder:
                              (context, index) {
                            final option =
                                options.elementAt(index);

                            final remainingValue =
                                option['remaining'] ??
                                    0.0;

                            final remaining =
                                remainingValue is num
                                    ? remainingValue
                                        .toDouble()
                                    : double.tryParse(
                                          remainingValue
                                              .toString(),
                                        ) ??
                                        0.0;

                            return ListTile(
                              dense: true,

                              // اسم العميل
                              title: Text(
                                option['name']
                                    .toString(),
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                  color:
                                      Color(0xFF1E293B),
                                ),
                              ),

                              // المبلغ المتبقي
                              subtitle: Text(
                                'المتبقي عليه: '
                                '${remaining.toStringAsFixed(2)} ر.ي',
                                style:
                                    const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              ),

                              trailing:
                                  const Icon(
                                Icons
                                    .check_circle_outline_rounded,
                                size: 16,
                                color:
                                    emeraldColor,
                              ),

                              onTap: () =>
                                  onSelected(option),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),

              // =====================================================
              // المبلغ + طريقة الدفع
              // =====================================================
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller:
                          _receiptAmountController,

                      keyboardType:
                          const TextInputType
                              .numberWithOptions(
                        decimal: true,
                      ),

                      style: TextStyle(
                        color: mainColor,
                        fontWeight:
                            FontWeight.bold,
                      ),

                      decoration: _inputDecoration(
                        'المبلغ المحصل (ر.ي)',
                        primaryBlue,
                      ),

                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'المبلغ مطلوب';
                        }

                        final amount =
                            double.tryParse(
                          value
                              .trim()
                              .replaceAll(',', ''),
                        );

                        if (amount == null ||
                            amount <= 0) {
                          return 'المبلغ غير صحيح';
                        }

                        return null;
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: TextFormField(
                      controller:
                          _receiptPaymentMethodController,

                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                      ),

                      decoration: _inputDecoration(
                        'طريقة الدفع (نقدي/شيك/تحويل)',
                        primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // =====================================================
              // البيان
              // =====================================================
              TextFormField(
                controller:
                    _receiptNoteController,

                maxLines: 2,

                style: const TextStyle(
                  color: Color(0xFF1E293B),
                ),

                decoration: _inputDecoration(
                  'بيان سند القبض',
                  primaryBlue,
                ),

                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'البيان مطلوب';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 18),

              // =====================================================
              // زر الحفظ
              // =====================================================
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor: mainColor,

                    disabledBackgroundColor:
                        mainColor.withOpacity(0.5),

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),

                    elevation: 0,
                  ),

                  onPressed: _isSavingReceipt
                      ? null
                      : _saveReceipt,

                  child: _isSavingReceipt
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child:
                              CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          editing
                              ? 'تحديث سند القبض ✏️'
                              : 'حفظ سند القبض ✅',
                          style:
                              const TextStyle(
                            color: Colors.white,
                            fontWeight:
                                FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 25),

        // ===========================================================
        // الخط الفاصل
        // ===========================================================
        const Divider(
          color: Color(0xFFE2E8F0),
        ),

        const SizedBox(height: 15),

        // ===========================================================
        // آخر سندات القبض
        // ===========================================================
        Row(
          children: [
            const Expanded(
              child: Text(
                'آخر سندات القبض',
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color:
                    mainColor.withOpacity(0.1),
                borderRadius:
                    BorderRadius.circular(20),
              ),
              child: Text(
                '${list.length}',
                style: TextStyle(
                  color: mainColor,
                  fontWeight:
                      FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ===========================================================
        // قائمة السندات
        // ===========================================================
        _buildVoucherList(
          list,
          true,
          mainColor,
        ),
      ],
    ),
  );
}

  Widget _buildPaymentVoucherCard() {
    final editing =
        _editingPaymentId != null;

    final list =
        _filterVouchers(
      _payments,
    );

    final mainColor =
        orangeColor;

    return Container(
      padding:
          const EdgeInsets.all(
        24,
      ),
      decoration:
          BoxDecoration(
        color: cardColor,
        borderRadius:
            BorderRadius.circular(
          30,
        ),
        border:
            Border(
          top: BorderSide(
            color: mainColor,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue
                .withOpacity(0.04),
            blurRadius: 15,
            offset:
                const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  editing
                      ? '✏️ تعديل سند صرف'
                      : '🔴 إصدار سند صرف (الموردون فقط)',
                  style: TextStyle(
                    color:
                        mainColor,
                    fontSize: 20,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ),
              if (editing)
                IconButton(
                  tooltip:
                      'إلغاء التعديل',
                  onPressed:
                      _clearPaymentForm,
                  icon:
                      const Icon(
                    Icons
                        .close_rounded,
                    color:
                        Colors.redAccent,
                  ),
                ),
            ],
          ),
          const SizedBox(
            height: 15,
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: orangeColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: orangeColor.withOpacity(0.25),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.business_rounded,
                  color: orangeColor,
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'سند الصرف مخصص لسداد ديون الموردين فقط',
                    style: TextStyle(
                      color: Color(0xFF92400E),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Form(
            key:
                _paymentFormKey,
            child:
                Column(
              children: [
                _buildSupplierAutocomplete(),
                const SizedBox(
                  height: 14,
                ),
                Row(
                  children: [
                    Expanded(
                      child:
                          TextFormField(
                        controller:
                            _paymentAmountController,
                        keyboardType:
                            const TextInputType
                                .numberWithOptions(
                          decimal:
                              true,
                        ),
                        style:
                            TextStyle(
                          color:
                              mainColor,
                          fontWeight:
                              FontWeight.bold,
                        ),
                        decoration:
                            _inputDecoration(
                          'المبلغ (ر.ي)',
                          primaryBlue,
                        ),
                        validator:
                            (value) {
                          if (value ==
                                  null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return 'المبلغ مطلوب';
                          }

                          final amount =
                              double.tryParse(
                            value
                                .trim()
                                .replaceAll(
                                  ',',
                                  '',
                                ),
                          );

                          if (amount ==
                                  null ||
                              amount <=
                                  0) {
                            return 'المبلغ غير صحيح';
                          }

                          return null;
                        },
                      ),
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    Expanded(
                      child:
                          TextFormField(
                        controller:
                            _paymentPaymentMethodController,
                        style:
                            const TextStyle(
                          color:
                              Color(
                            0xFF1E293B,
                          ),
                        ),
                        decoration:
                            _inputDecoration(
                          'طريقة الدفع (نقدي/شيك/تحويل)',
                          primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 14,
                ),
                TextFormField(
                  controller:
                      _paymentNoteController,
                  maxLines: 2,
                  style:
                      const TextStyle(
                    color:
                        Color(
                      0xFF1E293B,
                    ),
                  ),
                  decoration:
                      _inputDecoration(
                    'بيان سداد دين المورد',
                    primaryBlue,
                  ),
                  validator:
                      (value) {
                    if (value ==
                            null ||
                        value
                            .trim()
                            .isEmpty) {
                      return 'البيان مطلوب';
                    }

                    return null;
                  },
                ),
                const SizedBox(
                  height: 18,
                ),
                SizedBox(
                  width:
                      double.infinity,
                  height: 54,
                  child:
                      ElevatedButton(
                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          mainColor,
                      disabledBackgroundColor:
                          mainColor
                              .withOpacity(
                        0.5,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          16,
                        ),
                      ),
                      elevation: 0,
                    ),
                    onPressed:
                        _isSavingPayment
                            ? null
                            : _savePayment,
                    child:
                        _isSavingPayment
                            ? const SizedBox(
                                width:
                                    24,
                                height:
                                    24,
                                child:
                                    CircularProgressIndicator(
                                  color:
                                      Colors.white,
                                  strokeWidth:
                                      2,
                                ),
                              )
                            : Text(
                                editing
                                    ? 'تحديث سند الصرف ✏️'
                                    : 'حفظ سند صرف - سداد مورد ✅',
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.white,
                                  fontWeight:
                                      FontWeight.w900,
                                  fontSize:
                                      15,
                                ),
                              ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 25,
          ),
          const Divider(
            color:
                Color(0xFFE2E8F0),
          ),
          const SizedBox(
            height: 15,
          ),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'آخر سندات الصرف',
                  style:
                      TextStyle(
                    color:
                        Color(
                      0xFF1E293B,
                    ),
                    fontSize:
                        17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal:
                      10,
                  vertical:
                      5,
                ),
                decoration:
                    BoxDecoration(
                  color: mainColor
                      .withOpacity(
                    0.1,
                  ),
                  borderRadius:
                      BorderRadius
                          .circular(
                    20,
                  ),
                ),
                child: Text(
                  '${list.length}',
                  style:
                      TextStyle(
                    color:
                        mainColor,
                    fontWeight:
                        FontWeight.bold,
                    fontSize:
                        12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 12,
          ),
          _buildVoucherList(
            list,
            false,
            mainColor,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Autocomplete المورد
  // ============================================================

  Widget _buildSupplierAutocomplete() {
    return Autocomplete<
        Map<String, dynamic>>(
      optionsBuilder:
          (
        TextEditingValue value,
      ) {
        if (value.text.isEmpty) {
          return _creditorsList;
        }

        return _creditorsList.where(
          (item) =>
              item['name']
                  .toString()
                  .toLowerCase()
                  .contains(
                    value.text
                        .toLowerCase(),
                  ),
        );
      },
      displayStringForOption:
          (option) =>
              option['name']
                  .toString(),
      onSelected:
          (selection) {
        setState(() {
          _paymentNameController
                  .text =
              selection['name']
                  .toString();

          _selectedSupplierId =
              selection['id'];

          final balance =
              selection['balance'] ??
                  0.0;

          _paymentNoteController
                  .text =
              'سداد دين مورد '
              '(الرصيد المتبقي: '
              '${balance.toStringAsFixed(2)} ر.ي)';
        });
      },
      fieldViewBuilder:
          (
        context,
        textController,
        focusNode,
        onFieldSubmitted,
      ) {
        if (_paymentNameController
                .text
                .isNotEmpty &&
            textController
                .text
                .isEmpty) {
          textController.text =
              _paymentNameController
                  .text;
        }

        return TextFormField(
          controller:
              textController,
          focusNode:
              focusNode,
          style:
              const TextStyle(
            color:
                Color(0xFF1E293B),
          ),
          decoration:
              _inputDecoration(
            '🔍 اختر المورد / الدائن...',
            primaryBlue,
          ).copyWith(
            prefixIcon:
                const Icon(
              Icons
                  .person_outline_rounded,
              color:
                  primaryBlueLight,
            ),
            suffixIcon:
                const Icon(
              Icons
                  .arrow_drop_down_rounded,
              color:
                  primaryBlue,
            ),
          ),
          onChanged:
              (value) {
            final name =
                value.trim();

            _paymentNameController
                    .text =
                name;

            final match =
                _creditorsList.firstWhere(
              (supplier) =>
                  supplier['name']
                      .toString()
                      .trim()
                      .toLowerCase() ==
                  name.toLowerCase(),
              orElse: () =>
                  <String, dynamic>{},
            );

            if (match.isNotEmpty) {
              _selectedSupplierId =
                  match['id'];
            } else {
              _selectedSupplierId =
                  null;
            }
          },
          validator:
              (value) {
            if (value ==
                    null ||
                value
                    .trim()
                    .isEmpty) {
              return 'اسم المورد مطلوب';
            }

            if (_selectedSupplierId ==
                null) {
              return 'اختر المورد من القائمة';
            }

            return null;
          },
        );
      },
      optionsViewBuilder:
          (
        context,
        onSelected,
        options,
      ) {
        return Align(
          alignment:
              Alignment.topRight,
          child: Material(
            elevation: 6,
            borderRadius:
                BorderRadius.circular(
              16,
            ),
            child: Container(
              width: 340,
              constraints:
                  const BoxConstraints(
                maxHeight: 240,
              ),
              decoration:
                  BoxDecoration(
                color:
                    Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
                border:
                    Border.all(
                  color:
                      const Color(
                    0xFFCBD5E1,
                  ),
                ),
              ),
              child:
                  ListView.builder(
                padding:
                    EdgeInsets.zero,
                itemCount:
                    options.length,
                itemBuilder:
                    (
                  context,
                  index,
                ) {
                  final option =
                      options.elementAt(
                    index,
                  );

                  final balance =
                      option[
                              'balance'] ??
                          0.0;

                  return ListTile(
                    dense:
                        true,
                    title:
                        Text(
                      option[
                              'name']
                          .toString(),
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Color(
                          0xFF1E293B,
                        ),
                      ),
                    ),
                    subtitle:
                        Text(
                      'الرصيد المستحق: '
                      '${balance.toStringAsFixed(2)} ر.ي',
                      style:
                          const TextStyle(
                        color:
                            Colors.grey,
                        fontSize:
                            11,
                      ),
                    ),
                    trailing:
                        const Icon(
                      Icons
                          .check_circle_outline_rounded,
                      size:
                          16,
                      color:
                          orangeColor,
                    ),
                    onTap:
                        () =>
                            onSelected(
                      option,
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // Autocomplete المصروف المباشر
  // ============================================================


  // ============================================================
  // قائمة السندات
  // ============================================================

  Widget _buildVoucherList(
    List<VoucherModel> list,
    bool isReceipt,
    Color mainColor,
  ) {
    return SizedBox(
      height: 300,
      child: _isLoading
          ? Center(
              child:
                  CircularProgressIndicator(
                color:
                    mainColor,
              ),
            )
          : list.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,
                    children: [
                      Icon(
                        isReceipt
                            ? Icons
                                .receipt_long_outlined
                            : Icons
                                .payments_outlined,
                        color:
                            Colors.grey,
                        size: 45,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        isReceipt
                            ? 'لا توجد سندات قبض مطابقة'
                            : 'لا توجد سندات صرف مطابقة',
                        style:
                            const TextStyle(
                          color:
                              Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount:
                      list.length,
                  itemBuilder:
                      (
                    context,
                    index,
                  ) {
                    final voucher =
                        list[index];

                    final voucherNumber =
                        voucher.serialNo !=
                                    null &&
                                voucher
                                    .serialNo!
                                    .trim()
                                    .isNotEmpty
                            ? voucher
                                .serialNo!
                            : '${isReceipt ? 'REC' : 'PAY'}-${voucher.id}';

                    return Card(
                      color:
                          const Color(
                        0xFFF8FAFC,
                      ),
                      elevation: 0,
                      margin:
                          const EdgeInsets
                              .only(
                        bottom: 8,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          14,
                        ),
                        side:
                            const BorderSide(
                          color:
                              Color(
                            0xFFE2E8F0,
                          ),
                        ),
                      ),
                      child:
                          InkWell(
                        borderRadius:
                            BorderRadius
                                .circular(
                          14,
                        ),
                        onTap: () {
                          _showVoucherDetails(
                            voucher,
                            isReceipt,
                          );
                        },
                        child:
                            Padding(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal:
                                10,
                            vertical:
                                8,
                          ),
                          child:
                              Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration:
                                    BoxDecoration(
                                  color:
                                      mainColor.withOpacity(
                                    0.1,
                                  ),
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    10,
                                  ),
                                ),
                                child:
                                    Icon(
                                  isReceipt
                                      ? Icons
                                          .arrow_downward_rounded
                                      : Icons
                                          .arrow_upward_rounded,
                                  color:
                                      mainColor,
                                  size:
                                      18,
                                ),
                              ),
                              const SizedBox(
                                width: 8,
                              ),
                              Expanded(
                                child:
                                    Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child:
                                              Text(
                                            voucher.partyName ??
                                                '---',
                                            style:
                                                const TextStyle(
                                              color:
                                                  Color(
                                                0xFF1E293B,
                                              ),
                                              fontWeight:
                                                  FontWeight.bold,
                                              fontSize:
                                                  12,
                                            ),
                                            overflow:
                                                TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 4,
                                        ),
                                        Container(
                                          padding:
                                              const EdgeInsets
                                                  .symmetric(
                                            horizontal:
                                                5,
                                            vertical:
                                                2,
                                          ),
                                          decoration:
                                              BoxDecoration(
                                            color:
                                                mainColor.withOpacity(
                                              0.15,
                                            ),
                                            borderRadius:
                                                BorderRadius
                                                    .circular(
                                              6,
                                            ),
                                          ),
                                          child:
                                              Text(
                                            voucherNumber,
                                            style:
                                                TextStyle(
                                              color:
                                                  mainColor,
                                              fontSize:
                                                  8,
                                              fontWeight:
                                                  FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 4,
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child:
                                              Text(
                                            voucher.note
                                                        ?.isNotEmpty ==
                                                    true
                                                ? voucher
                                                    .note!
                                                : 'بدون بيان',
                                            maxLines:
                                                1,
                                            overflow:
                                                TextOverflow.ellipsis,
                                            style:
                                                const TextStyle(
                                              color:
                                                  Colors.grey,
                                              fontSize:
                                                  10,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 4,
                                        ),
                                        Text(
                                          '${voucher.amount.toStringAsFixed(2)} ر.ي',
                                          style:
                                              TextStyle(
                                            color:
                                                mainColor,
                                            fontWeight:
                                                FontWeight.bold,
                                            fontSize:
                                                11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<
                                  String>(
                                icon:
                                    const Icon(
                                  Icons
                                      .more_vert_rounded,
                                  color:
                                      Colors.grey,
                                  size:
                                      18,
                                ),
                                color:
                                    Colors.white,
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    12,
                                  ),
                                ),
                                padding:
                                    EdgeInsets.zero,
                                onSelected:
                                    (value) {
                                  switch (
                                      value) {
                                    case 'details':
                                      _showVoucherDetails(
                                        voucher,
                                        isReceipt,
                                      );
                                      break;

                                    case 'print':
                                      _printVoucher(
                                        voucher,
                                      );
                                      break;

                                    case 'edit':
                                      if (isReceipt) {
                                        _editReceipt(
                                          voucher,
                                        );
                                      } else {
                                        _editPayment(
                                          voucher,
                                        );
                                      }
                                      break;

                                    case 'delete':
                                      if (isReceipt) {
                                        _deleteReceipt(
                                          voucher,
                                        );
                                      } else {
                                        _deletePayment(
                                          voucher,
                                        );
                                      }
                                      break;
                                  }
                                },
                                itemBuilder:
                                    (context) =>
                                        [
                                  const PopupMenuItem(
                                    value:
                                        'details',
                                    child:
                                        Row(
                                      children: [
                                        Icon(
                                          Icons
                                              .visibility_outlined,
                                          color:
                                              primaryBlue,
                                          size:
                                              18,
                                        ),
                                        SizedBox(
                                          width:
                                              8,
                                        ),
                                        Text(
                                          'التفاصيل',
                                        ),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value:
                                        'print',
                                    child:
                                        Row(
                                      children: [
                                        Icon(
                                          Icons
                                              .print_rounded,
                                          color:
                                              Colors.amber,
                                          size:
                                              18,
                                        ),
                                        SizedBox(
                                          width:
                                              8,
                                        ),
                                        Text(
                                          'طباعة',
                                        ),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value:
                                        'edit',
                                    child:
                                        Row(
                                      children: [
                                        Icon(
                                          Icons
                                              .edit_rounded,
                                          color:
                                              Colors.blueAccent,
                                          size:
                                              18,
                                        ),
                                        SizedBox(
                                          width:
                                              8,
                                        ),
                                        Text(
                                          'تعديل',
                                        ),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value:
                                        'delete',
                                    child:
                                        Row(
                                      children: [
                                        Icon(
                                          Icons
                                              .delete_outline_rounded,
                                          color:
                                              Colors.redAccent,
                                          size:
                                              18,
                                        ),
                                        SizedBox(
                                          width:
                                              8,
                                        ),
                                        Text(
                                          'حذف',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  // ============================================================
  // تصميم الحقول
  // ============================================================

  InputDecoration _inputDecoration(
    String label,
    Color color,
  ) {
    return InputDecoration(
      labelText: label,
      labelStyle:
          const TextStyle(
        color:
            Colors.grey,
        fontSize: 12,
      ),
      filled: true,
      fillColor:
          const Color(0xFFF8FAFC),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        borderSide:
            const BorderSide(
          color:
              Color(0xFFCBD5E1),
        ),
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        borderSide:
            BorderSide(
          color: color,
          width: 1.5,
        ),
      ),
      errorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        borderSide:
            const BorderSide(
          color:
              Colors.redAccent,
        ),
      ),
      focusedErrorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        borderSide:
            const BorderSide(
          color:
              Colors.redAccent,
          width: 1.5,
        ),
      ),
      contentPadding:
          const EdgeInsets
              .symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    );
  }
}