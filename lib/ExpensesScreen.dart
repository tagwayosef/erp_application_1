import 'dart:io';

import 'package:excel/excel.dart' as excelPkg;
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'model/expense_model.dart';
import 'model/ledger_model.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({Key? key}) : super(key: key);

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _selectedType = 'إيجار';
  String _selectedPaymentType = 'نقدي';
  String _selectedPaymentMethod = 'نقدي';

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _creditorController = TextEditingController();
  
  // متحكم وبحث سجل المصاريف
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<ExpenseModel> _expenses = [];

  bool _isLoading = true;
  bool _isSaving = false;

  static const Color _background = Color(0xFFF8FAFC);
  static const Color _cardColor = Colors.white;
  static const Color _primaryBlue = Color(0xFF1E40AF);
  static const Color _primaryBlueLight = Color(0xFF2563EB);
  static const Color _successGreen = Color(0xFF16A34A);
  static const Color _dangerRed = Color(0xFFDC2626);
  static const Color _warningOrange = Color(0xFFD97706);

  final List<String> _expenseTypes = [
    'إيجار',
    'رواتب',
    'كهرباء/ماء',
    'صيانة',
    'نقل',
    'اتصالات',
    'تسويق وإعلان',
    'وقود',
    'مستلزمات مكتبية',
    'أخرى',
  ];

  final List<String> _paymentTypes = [
    'نقدي',
    'آجل',
  ];

  final List<String> _paymentMethods = [
    'نقدي',
    'شبكة',
    'تحويل بنكي',
    'شيك',
  ];

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _creditorController.dispose();
    _searchController.dispose(); // التخلص من متحكم البحث
    super.dispose();
  }

  // ============================================================
  // أدوات عامة
  // ============================================================

  String _normalize(String value) {
    return value.trim().toLowerCase();
  }

  bool _isCreditType(String? value) {
    final type = _normalize(value ?? 'نقدي');
    return type == 'آجل' || type == 'اجل' || type == 'credit';
  }

  String _cashOrBankAccount(String? paymentMethod) {
    final method = _normalize(paymentMethod ?? 'نقدي');

    if (method == 'شبكة' ||
        method == 'تحويل' ||
        method == 'تحويل بنكي' ||
        method == 'bank' ||
        method == 'bank transfer' ||
        method == 'شيك') {
      return 'البنك';
    }

    return 'الصندوق الرئيسي';
  }

  double _parseAmount(String value) {
    return double.tryParse(value.trim().replaceAll(',', '')) ?? 0.0;
  }

  String _expenseReference(int id) => 'EXP-$id';

  String _settlementReference(int expenseId, int timestamp) {
    return 'EXP-PAY-$expenseId-$timestamp';
  }

  Future<Isar> _requireIsar() async {
    final isar = Isar.getInstance();
    if (isar == null) {
      throw Exception('قاعدة البيانات غير متاحة');
    }
    return isar;
  }

  // ============================================================
  // تحميل المصاريف
  // ============================================================

  Future<void> _fetchExpenses() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final isar = Isar.getInstance();

      if (isar == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final data = await isar.expenseModels.where().findAll();

      data.sort((a, b) {
        final ad = DateTime.tryParse(a.date ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bd = DateTime.tryParse(b.date ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });

      if (!mounted) return;

      setState(() {
        _expenses = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحميل المصاريف: $e'),
          backgroundColor: _dangerRed,
        ),
      );
    }
  }

  // تصفية المصاريف بناءً على محرك البحث
  List<ExpenseModel> get _filteredExpenses {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return _expenses;
    }

    return _expenses.where((exp) {
      final title = (exp.title ?? '').toLowerCase();
      final creditor = (exp.creditorName ?? '').toLowerCase();
      final notes = (exp.notes ?? '').toLowerCase();
      final amount = exp.amount.toString().toLowerCase();
      final paymentType = (exp.paymentType ?? '').toLowerCase();

      return title.contains(query) ||
          creditor.contains(query) ||
          notes.contains(query) ||
          amount.contains(query) ||
          paymentType.contains(query);
    }).toList();
  }

  // ============================================================
  // حذف قيود مصروف محدد
  // ============================================================

  Future<void> _deleteExpenseLedgers(
    Isar isar,
    int expenseId,
  ) async {
    final entries = await isar.ledgerModels.where().findAll();

    final expenseRef = _expenseReference(expenseId);

    for (final entry in entries) {
      final ref = entry.referenceNo ?? '';

      final isMainExpenseEntry = ref == expenseRef;
      final isSettlementEntry =
          ref.startsWith('EXP-PAY-$expenseId-');

      if (isMainExpenseEntry || isSettlementEntry) {
        await isar.ledgerModels.delete(entry.id);
      }
    }
  }

  // ============================================================
  // إنشاء قيد المصروف
  // ============================================================

  Future<void> _createExpenseLedgers(
    Isar isar,
    ExpenseModel expense,
  ) async {
    final bool isCredit = _isCreditType(expense.paymentType);
    final String reference = _expenseReference(expense.id);

    final String description = expense.notes != null &&
            expense.notes!.trim().isNotEmpty
        ? 'مصروف ${expense.paymentType ?? 'نقدي'} '
            '(${expense.title ?? 'أخرى'}): ${expense.notes!.trim()}'
        : 'مصروف ${expense.paymentType ?? 'نقدي'} '
            '(${expense.title ?? 'أخرى'})';

    await isar.ledgerModels.put(
      LedgerModel(
        date: expense.date ?? DateTime.now().toIso8601String(),
        description: description,
        accountName: 'المصاريف العامة',
        partyName: isCredit
            ? (expense.creditorName ?? expense.title ?? 'مصروف')
            : (expense.title ?? 'مصروف'),
        debit: expense.amount,
        credit: 0.0,
        referenceNo: reference,
        paymentType: expense.paymentType ?? 'نقدي',
        entryType: 'مصروفات',
      ),
    );

    await isar.ledgerModels.put(
      LedgerModel(
        date: expense.date ?? DateTime.now().toIso8601String(),
        description: description,
        accountName: isCredit
            ? 'مصروفات مستحقة'
            : _cashOrBankAccount(expense.paymentMethod),
        partyName: isCredit
            ? (expense.creditorName ?? 'دائن مصروف')
            : (expense.paymentMethod ?? 'نقدي'),
        debit: 0.0,
        credit: expense.amount,
        referenceNo: reference,
        paymentType: expense.paymentType ?? 'نقدي',
        entryType: 'مصروفات',
      ),
    );
  }

  // ============================================================
  // حفظ مصروف جديد
  // ============================================================

  Future<void> _saveExpense() async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) return;

    final amount = _parseAmount(_amountController.text);

    if (amount <= 0) {
      _showMessage(
        'يرجى إدخال مبلغ صحيح أكبر من صفر ⚠️',
        _warningOrange,
      );
      return;
    }

    final bool isCredit = _isCreditType(_selectedPaymentType);

    final creditor = _creditorController.text.trim();

    if (isCredit && creditor.isEmpty) {
      _showMessage(
        'يجب إدخال اسم الدائن للمصروف الآجل ⚠️',
        _warningOrange,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final isar = await _requireIsar();

      final now = DateTime.now();

      final expense = ExpenseModel(
        title: _selectedType.trim().isEmpty
            ? 'أخرى'
            : _selectedType.trim(),
        category: _selectedType.trim(),
        amount: amount,
        date: now.toIso8601String(),
        notes: _noteController.text.trim(),
        paymentType: isCredit ? 'آجل' : 'نقدي',
        paymentMethod: isCredit
            ? null
            : _selectedPaymentMethod,
        creditorName: isCredit ? creditor : null,
        paidAmount: isCredit ? 0.0 : amount,
        remainingAmount: isCredit ? amount : 0.0,
      );

      await isar.writeTxn(() async {
        await isar.expenseModels.put(expense);
        await _createExpenseLedgers(isar, expense);
      });

      _clearForm();

      await _fetchExpenses();

      if (!mounted) return;

      _showMessage(
        isCredit
            ? 'تم تسجيل المصروف الآجل وإثبات المبلغ على الدائن ✅'
            : 'تم تسجيل المصروف النقدي وترحيل القيد المحاسبي ✅',
        _successGreen,
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'فشل حفظ المصروف ❌\n$e',
        _dangerRed,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // ============================================================
  // تعديل المصروف
  // ============================================================

  Future<void> _editExpenseDialog(ExpenseModel expense) async {
    final amountController = TextEditingController(
      text: expense.amount.toStringAsFixed(2),
    );

    final noteController = TextEditingController(
      text: expense.notes ?? '',
    );

    final creditorController = TextEditingController(
      text: expense.creditorName ?? '',
    );

    String editType = expense.title ?? 'أخرى';
    String editPaymentType =
        _isCreditType(expense.paymentType) ? 'آجل' : 'نقدي';
    String editPaymentMethod =
        expense.paymentMethod ?? 'نقدي';

    final bool hasSettlement =
        expense.paidAmount > 0 && _isCreditType(expense.paymentType);

    if (hasSettlement) {
      _showMessage(
        'لا يمكن تعديل مصروف آجل بعد تسجيل سداد عليه. استخدم الحذف وإعادة التسجيل عند الحاجة.',
        _warningOrange,
      );
      return;
    }

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              final bool isCredit =
                  _isCreditType(editPaymentType);

              return AlertDialog(
                backgroundColor: Colors.white,
                title: const Text(
                  'تعديل المصروف',
                  style: TextStyle(
                    color: _primaryBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: SingleChildScrollView(
                  child: SizedBox(
                    width: 430,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDialogTextField(
                          label: 'نوع المصروف',
                          initialValue: editType,
                          onChanged: (value) {
                            setDialogState(() {
                              editType = value.trim();
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: editPaymentType,
                          decoration: _inputDecoration(
                            'نوع السداد',
                            Icons.account_balance_wallet_outlined,
                          ),
                          items: _paymentTypes
                              .map(
                                (item) => DropdownMenuItem<String>(
                                  value: item,
                                  child: Text(item),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setDialogState(() {
                              editPaymentType = value;
                            });
                          },
                        ),
                        if (!isCredit) ...[
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: editPaymentMethod,
                            decoration: _inputDecoration(
                              'طريقة الدفع',
                              Icons.payments_outlined,
                            ),
                            items: _paymentMethods
                                .map(
                                  (item) => DropdownMenuItem<String>(
                                    value: item,
                                    child: Text(item),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setDialogState(() {
                                editPaymentMethod = value;
                              });
                            },
                          ),
                        ],
                        if (isCredit) ...[
                          const SizedBox(height: 10),
                          TextField(
                            controller: creditorController,
                            decoration: _inputDecoration(
                              'اسم الدائن',
                              Icons.person_outline,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        TextField(
                          controller: amountController,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: _inputDecoration(
                            'المبلغ',
                            Icons.numbers,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: noteController,
                          maxLines: 2,
                          decoration: _inputDecoration(
                            'البيان',
                            Icons.notes_outlined,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(dialogContext),
                    child: const Text('إلغاء'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryBlue,
                    ),
                    onPressed: () async {
                      final newAmount =
                          _parseAmount(amountController.text);

                      if (newAmount <= 0) {
                        _showMessage(
                          'أدخل مبلغاً صحيحاً أكبر من صفر ⚠️',
                          _warningOrange,
                        );
                        return;
                      }

                      final newCreditor =
                          creditorController.text.trim();

                      if (isCredit && newCreditor.isEmpty) {
                        _showMessage(
                          'أدخل اسم الدائن ⚠️',
                          _warningOrange,
                        );
                        return;
                      }

                      if (hasSettlement &&
                          newAmount <
                              expense.paidAmount) {
                        _showMessage(
                          'لا يمكن جعل قيمة المصروف أقل من المبلغ المسدد سابقاً.',
                          _warningOrange,
                        );
                        return;
                      }

                      Navigator.pop(dialogContext);

                      try {
                        final isar = await _requireIsar();

                        final current =
                            await isar.expenseModels.get(expense.id);

                        if (current == null) {
                          throw Exception('المصروف غير موجود');
                        }

                        final double paidAmount =
                            isCredit
                                ? current.paidAmount
                                : newAmount;

                        final double remaining =
                            isCredit
                                ? (newAmount - paidAmount)
                                    .clamp(0.0, double.infinity)
                                    .toDouble()
                                : 0.0;

                        current.title =
                            editType.trim().isEmpty
                                ? 'أخرى'
                                : editType.trim();

                        current.category = current.title;
                        current.amount = newAmount;
                        current.notes = noteController.text.trim();
                        current.paymentType =
                            isCredit ? 'آجل' : 'نقدي';
                        current.paymentMethod =
                            isCredit ? null : editPaymentMethod;
                        current.creditorName =
                            isCredit ? newCreditor : null;
                        current.paidAmount = paidAmount;
                        current.remainingAmount = remaining;

                        await isar.writeTxn(() async {
                          await _deleteExpenseLedgers(
                            isar,
                            current.id,
                          );
                          await isar.expenseModels.put(current);
                          await _createExpenseLedgers(
                            isar,
                            current,
                          );
                        });

                        await _fetchExpenses();

                        if (!mounted) return;

                        _showMessage(
                          'تم تعديل المصروف والقيد المحاسبي بنجاح ✏️✅',
                          _successGreen,
                        );
                      } catch (e) {
                        if (!mounted) return;

                        _showMessage(
                          'فشل تعديل المصروف ❌\n$e',
                          _dangerRed,
                        );
                      }
                    },
                    child: const Text(
                      'حفظ التعديل',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      amountController.dispose();
      noteController.dispose();
      creditorController.dispose();
    }
  }

  // ============================================================
  // سداد مصروف آجل
  // ============================================================

  Future<void> _settleCreditExpense(
    ExpenseModel expense,
  ) async {
    if (!_isCreditType(expense.paymentType)) {
      _showMessage(
        'هذا المصروف نقدي ولا يوجد عليه مبلغ آجل.',
        _warningOrange,
      );
      return;
    }

    final remaining = expense.remainingAmount > 0
        ? expense.remainingAmount
        : (expense.amount - expense.paidAmount)
            .clamp(0.0, double.infinity)
            .toDouble();

    if (remaining <= 0) {
      _showMessage(
        'تم سداد هذا المصروف بالكامل.',
        _successGreen,
      );
      return;
    }

    final amountController = TextEditingController(
      text: remaining.toStringAsFixed(2),
    );

    String paymentMethod = 'نقدي';
    final noteController = TextEditingController();

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: Colors.white,
                title: const Text(
                  'سداد مصروف آجل',
                  style: TextStyle(
                    color: _primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: SingleChildScrollView(
                  child: SizedBox(
                    width: 420,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'الدائن: ${expense.creditorName ?? 'غير محدد'}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'المتبقي: ${remaining.toStringAsFixed(2)} ر.ي',
                                style: const TextStyle(
                                  color: _dangerRed,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: amountController,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: _inputDecoration(
                            'مبلغ السداد',
                            Icons.payments_outlined,
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: paymentMethod,
                          decoration: _inputDecoration(
                            'طريقة السداد',
                            Icons.account_balance_outlined,
                          ),
                          items: _paymentMethods
                              .map(
                                (item) => DropdownMenuItem<String>(
                                  value: item,
                                  child: Text(item),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setDialogState(() {
                              paymentMethod = value;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: noteController,
                          maxLines: 2,
                          decoration: _inputDecoration(
                            'بيان السداد',
                            Icons.notes_outlined,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(dialogContext),
                    child: const Text('إلغاء'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _successGreen,
                    ),
                    icon: const Icon(
                      Icons.check,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'تسجيل السداد',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () async {
                      final paymentAmount =
                          _parseAmount(amountController.text);

                      if (paymentAmount <= 0) {
                        _showMessage(
                          'أدخل مبلغ سداد صحيح ⚠️',
                          _warningOrange,
                        );
                        return;
                      }

                      if (paymentAmount > remaining + 0.000001) {
                        _showMessage(
                          'مبلغ السداد أكبر من المبلغ المتبقي ⚠️',
                          _warningOrange,
                        );
                        return;
                      }

                      Navigator.pop(dialogContext);

                      try {
                        final isar = await _requireIsar();

                        final current =
                            await isar.expenseModels.get(
                          expense.id,
                        );

                        if (current == null) {
                          throw Exception(
                            'المصروف غير موجود',
                          );
                        }

                        final currentRemaining =
                            (current.amount -
                                    current.paidAmount)
                                .clamp(0.0, double.infinity)
                                .toDouble();

                        if (paymentAmount >
                            currentRemaining + 0.000001) {
                          throw Exception(
                            'المبلغ المطلوب سداده أكبر من المتبقي.',
                          );
                        }

                        final now = DateTime.now();
                        final ref = _settlementReference(
                          current.id,
                          now.millisecondsSinceEpoch,
                        );

                        final description =
                            noteController.text.trim().isNotEmpty
                                ? 'سداد مصروف آجل '
                                    '(${current.creditorName ?? 'دائن'}): '
                                    '${noteController.text.trim()}'
                                : 'سداد مصروف آجل '
                                    '(${current.creditorName ?? 'دائن'})';

                        await isar.writeTxn(() async {
                          current.paidAmount += paymentAmount;

                          current.remainingAmount =
                              (current.amount -
                                      current.paidAmount)
                                  .clamp(
                                    0.0,
                                    double.infinity,
                                  )
                                  .toDouble();

                          await isar.expenseModels.put(current);

                          await isar.ledgerModels.put(
                            LedgerModel(
                              date: now.toIso8601String(),
                              description: description,
                              accountName: 'مصروفات مستحقة',
                              partyName:
                                  current.creditorName ??
                                      'دائن مصروف',
                              debit: paymentAmount,
                              credit: 0.0,
                              referenceNo: ref,
                              paymentType: 'سداد مصروف آجل',
                              entryType: 'سداد مصروف آجل',
                            ),
                          );

                          await isar.ledgerModels.put(
                            LedgerModel(
                              date: now.toIso8601String(),
                              description: description,
                              accountName:
                                  _cashOrBankAccount(
                                paymentMethod,
                              ),
                              partyName: paymentMethod,
                              debit: 0.0,
                              credit: paymentAmount,
                              referenceNo: ref,
                              paymentType: 'سداد مصروف آجل',
                              entryType: 'سداد مصروف آجل',
                            ),
                          );
                        });

                        await _fetchExpenses();

                        if (!mounted) return;

                        _showMessage(
                          current.remainingAmount <=
                                  0.000001
                              ? 'تم سداد المصروف بالكامل ✅'
                              : 'تم تسجيل السداد وتحديث المتبقي ✅',
                          _successGreen,
                        );
                      } catch (e) {
                        if (!mounted) return;

                        _showMessage(
                          'فشل تسجيل السداد ❌\n$e',
                          _dangerRed,
                        );
                      }
                    },
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      amountController.dispose();
      noteController.dispose();
    }
  }

  // ============================================================
  // حذف مصروف
  // ============================================================

  Future<void> _deleteExpense(
    ExpenseModel expense,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final bool isCredit =
            _isCreditType(expense.paymentType);

        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'تأكيد حذف المصروف',
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            isCredit &&
                    expense.paidAmount > 0
                ? 'هذا المصروف الآجل تم سداد مبلغ ${expense.paidAmount.toStringAsFixed(2)} ر.ي منه.\n\n'
                    'سيتم حذف المصروف وجميع قيوده وقيود السداد المرتبطة به.'
                : 'هل أنت متأكد من حذف هذا المصروف؟\n\n'
                    'سيتم حذف القيد المحاسبي المرتبط به أيضاً.',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _dangerRed,
              ),
              onPressed: () =>
                  Navigator.pop(context, true),
              child: const Text(
                'حذف نهائياً',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final isar = await _requireIsar();

      await isar.writeTxn(() async {
        await _deleteExpenseLedgers(
          isar,
          expense.id,
        );

        await isar.expenseModels.delete(
          expense.id,
        );
      });

      await _fetchExpenses();

      if (!mounted) return;

      _showMessage(
        'تم حذف المصروف وجميع قيوده المرتبطة بنجاح 🗑️✅',
        _successGreen,
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'فشل حذف المصروف ❌\n$e',
        _dangerRed,
      );
    }
  }

  // ============================================================
  // مسح النموذج
  // ============================================================

  void _clearForm() {
    _amountController.clear();
    _noteController.clear();
    _creditorController.clear();

    if (mounted) {
      setState(() {
        _selectedPaymentType = 'نقدي';
        _selectedPaymentMethod = 'نقدي';
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
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 4),
        ),
      );
  }

  // ============================================================
  // Excel
  // ============================================================

  Future<void> _exportExpensesToExcel() async {
    if (_expenses.isEmpty) {
      _showMessage(
        'لا توجد مصاريف لتصديرها ⚠️',
        _warningOrange,
      );
      return;
    }

    try {
      final excel = excelPkg.Excel.createExcel();
      final sheet = excel['سجل المصاريف'];

      sheet.appendRow([
        excelPkg.TextCellValue('نوع المصروف'),
        excelPkg.TextCellValue('نوع السداد'),
        excelPkg.TextCellValue('طريقة الدفع'),
        excelPkg.TextCellValue('الدائن'),
        excelPkg.TextCellValue('المبلغ'),
        excelPkg.TextCellValue('المدفوع'),
        excelPkg.TextCellValue('المتبقي'),
        excelPkg.TextCellValue('البيان'),
        excelPkg.TextCellValue('التاريخ'),
      ]);

      for (final exp in _expenses) {
        sheet.appendRow([
          excelPkg.TextCellValue(exp.title ?? 'أخرى'),
          excelPkg.TextCellValue(
            exp.paymentType ?? 'نقدي',
          ),
          excelPkg.TextCellValue(
            exp.paymentMethod ?? '',
          ),
          excelPkg.TextCellValue(
            exp.creditorName ?? '',
          ),
          excelPkg.DoubleCellValue(exp.amount),
          excelPkg.DoubleCellValue(exp.paidAmount),
          excelPkg.DoubleCellValue(
            exp.remainingAmount,
          ),
          excelPkg.TextCellValue(exp.notes ?? ''),
          excelPkg.TextCellValue(exp.date ?? ''),
        ]);
      }

      final bytes = excel.save();

      if (bytes == null) return;

      final directory = await getTemporaryDirectory();

      final path =
          '${directory.path}/Expenses_Report.xlsx';

      final file = File(path);

      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(path)],
        subject:
            'تقرير المصاريف - Omar Soft ERP',
      );
    } catch (e) {
      _showMessage(
        'فشل تصدير التقرير ❌\n$e',
        _dangerRed,
      );
    }
  }

  // ============================================================
  // PDF
  // ============================================================

  Future<void> _printExpensesReport() async {
    if (_expenses.isEmpty) {
      _showMessage(
        'لا توجد مصاريف للطباعة ⚠️',
        _warningOrange,
      );
      return;
    }

    try {
      final arabicFont =
          await PdfGoogleFonts.cairoRegular();

      final arabicBold =
          await PdfGoogleFonts.cairoBold();

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async {
          final doc = pw.Document();

          doc.addPage(
            pw.MultiPage(
              pageFormat: format,
              textDirection: pw.TextDirection.rtl,
              build: (context) {
                return [
                  pw.Text(
                    'تقرير المصاريف - Omar Soft ERP',
                    style: pw.TextStyle(
                      font: arabicBold,
                      fontSize: 18,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'المصروفات النقدية والآجلة والسداد',
                    style: pw.TextStyle(
                      font: arabicFont,
                      fontSize: 10,
                    ),
                  ),
                  pw.SizedBox(height: 15),
                  pw.Table.fromTextArray(
                    headers: [
                      'النوع',
                      'السداد',
                      'الدائن',
                      'المبلغ',
                      'المدفوع',
                      'المتبقي',
                      'التاريخ',
                    ],
                    data: _expenses.map((e) {
                      return [
                        e.title ?? 'أخرى',
                        e.paymentType ?? 'نقدي',
                        e.creditorName ?? '-',
                        e.amount.toStringAsFixed(2),
                        e.paidAmount.toStringAsFixed(2),
                        e.remainingAmount
                            .toStringAsFixed(2),
                        e.date ?? '',
                      ];
                    }).toList(),
                    headerStyle: pw.TextStyle(
                      font: arabicBold,
                      fontSize: 9,
                      color: PdfColors.white,
                    ),
                    headerDecoration:
                        const pw.BoxDecoration(
                      color: PdfColor.fromInt(
                        0xFF1E40AF,
                      ),
                    ),
                    cellStyle: pw.TextStyle(
                      font: arabicFont,
                      fontSize: 8,
                    ),
                    cellAlignment:
                        pw.Alignment.centerRight,
                  ),
                  pw.SizedBox(height: 15),
                  pw.Text(
                    'إجمالي المصروفات: '
                    '${_totalExpenses.toStringAsFixed(2)} ر.ي',
                    style: pw.TextStyle(
                      font: arabicBold,
                      fontSize: 12,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'المصروفات النقدية: '
                    '${_cashExpenses.toStringAsFixed(2)} ر.ي',
                    style: pw.TextStyle(
                      font: arabicBold,
                      fontSize: 11,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'المصروفات الآجلة: '
                    '${_creditExpenses.toStringAsFixed(2)} ر.ي',
                    style: pw.TextStyle(
                      font: arabicBold,
                      fontSize: 11,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'المتبقي على الدائنين: '
                    '${_remainingCreditExpenses.toStringAsFixed(2)} ر.ي',
                    style: pw.TextStyle(
                      font: arabicBold,
                      fontSize: 11,
                    ),
                  ),
                ];
              },
            ),
          );

          return doc.save();
        },
      );
    } catch (e) {
      _showMessage(
        'فشل إنشاء تقرير PDF ❌\n$e',
        _dangerRed,
      );
    }
  }

  // ============================================================
  // الإحصائيات
  // ============================================================

  double get _totalExpenses {
    return _expenses.fold<double>(
      0.0,
      (sum, item) => sum + item.amount,
    );
  }

  double get _cashExpenses {
    return _expenses
        .where((e) => !_isCreditType(e.paymentType))
        .fold<double>(
          0.0,
          (sum, item) => sum + item.amount,
        );
  }

  double get _creditExpenses {
    return _expenses
        .where((e) => _isCreditType(e.paymentType))
        .fold<double>(
          0.0,
          (sum, item) => sum + item.amount,
        );
  }

  double get _remainingCreditExpenses {
    return _expenses
        .where((e) => _isCreditType(e.paymentType))
        .fold<double>(
          0.0,
          (sum, item) =>
              sum +
              (item.remainingAmount > 0
                  ? item.remainingAmount
                  : (item.amount - item.paidAmount)
                      .clamp(
                        0.0,
                        double.infinity,
                      )
                      .toDouble()),
        );
  }

  // ============================================================
  // واجهة الإدخال
  // ============================================================

  InputDecoration _inputDecoration(
    String label,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        color: _primaryBlueLight,
        size: 20,
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFCBD5E1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: _primaryBlue,
        ),
      ),
    );
  }

  Widget _buildDialogTextField({
    required String label,
    required String initialValue,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      decoration: _inputDecoration(
        label,
        Icons.category_outlined,
      ),
    );
  }

  Widget _expenseTypeField() {
    return Autocomplete<String>(
      initialValue:
          TextEditingValue(text: _selectedType),
      optionsBuilder:
          (TextEditingValue value) {
        if (value.text.trim().isEmpty) {
          return _expenseTypes;
        }

        final query =
            value.text.trim().toLowerCase();

        return _expenseTypes.where(
          (type) => type
              .toLowerCase()
              .contains(query),
        );
      },
      onSelected: (value) {
        setState(() {
          _selectedType = value;
        });
      },
      fieldViewBuilder: (
        context,
        controller,
        focusNode,
        onFieldSubmitted,
      ) {
        if (controller.text.isEmpty &&
            _selectedType.isNotEmpty) {
          controller.text = _selectedType;
          controller.selection =
              TextSelection.fromPosition(
            TextPosition(
              offset: controller.text.length,
            ),
          );
        }

        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          onChanged: (value) {
            _selectedType = value.trim();
          },
          decoration: _inputDecoration(
            'نوع المصروف (اختر أو اكتب)',
            Icons.category_outlined,
          ),
          validator: (value) {
            if (value == null ||
                value.trim().isEmpty) {
              return 'أدخل نوع المصروف';
            }
            return null;
          },
        );
      },
    );
  }

  // ============================================================
  // بطاقة مصروف
  // ============================================================

  Widget _expenseCard(ExpenseModel exp) {
    final bool isCredit =
        _isCreditType(exp.paymentType);

    final double remaining =
        isCredit
            ? (exp.remainingAmount > 0
                ? exp.remainingAmount
                : (exp.amount - exp.paidAmount)
                    .clamp(
                      0.0,
                      double.infinity,
                    )
                    .toDouble())
            : 0.0;

    final bool isFullyPaid =
        isCredit && remaining <= 0.000001;

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.symmetric(
        vertical: 5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(
          color: Color(0xFFE2E8F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: isCredit
                    ? const Color(0xFFFFF7ED)
                    : const Color(0xFFEFF6FF),
                child: Icon(
                  isCredit
                      ? Icons.schedule
                      : Icons.payments_outlined,
                  color: isCredit
                      ? _warningOrange
                      : _primaryBlue,
                  size: 20,
                ),
              ),
              title: Text(
                exp.title ?? 'أخرى',
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              subtitle: Padding(
                padding:
                    const EdgeInsets.only(top: 5),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${exp.paymentType ?? 'نقدي'}'
                      '${exp.paymentMethod != null ? ' • ${exp.paymentMethod}' : ''}',
                      style: TextStyle(
                        color: isCredit
                            ? _warningOrange
                            : _successGreen,
                        fontSize: 10,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    if (isCredit)
                      Text(
                        'الدائن: ${exp.creditorName ?? '-'}',
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 10,
                        ),
                      ),
                    Text(
                      '${exp.notes ?? ''}'
                      '${exp.date != null ? ' • ${exp.date}' : ''}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              trailing: Text(
                '${exp.amount.toStringAsFixed(2)} ر.ي',
                style: const TextStyle(
                  color: _successGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            if (isCredit)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(
                  top: 4,
                  bottom: 4,
                ),
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: isFullyPaid
                      ? const Color(0xFFF0FDF4)
                      : const Color(0xFFFFF7ED),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'المدفوع: ${exp.paidAmount.toStringAsFixed(2)} ر.ي',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569),
                      ),
                    ),
                    Text(
                      isFullyPaid
                          ? 'مسدد بالكامل ✅'
                          : 'المتبقي: ${remaining.toStringAsFixed(2)} ر.ي',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isFullyPaid
                            ? _successGreen
                            : _dangerRed,
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(height: 8),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 4,
              runSpacing: 4,
              children: [
                if (isCredit && !isFullyPaid)
                  TextButton.icon(
                    onPressed: () =>
                        _settleCreditExpense(exp),
                    icon: const Icon(
                      Icons.payments_outlined,
                      size: 16,
                    ),
                    label: const Text(
                      'سداد',
                      style: TextStyle(fontSize: 10),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: _successGreen,
                    ),
                  ),
                TextButton.icon(
                  onPressed: () =>
                      _editExpenseDialog(exp),
                  icon: const Icon(
                    Icons.edit,
                    size: 16,
                  ),
                  label: const Text(
                    'تعديل',
                    style: TextStyle(fontSize: 10),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: _warningOrange,
                  ),
                ),
                TextButton.icon(
                  onPressed: () =>
                      _deleteExpense(exp),
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 16,
                  ),
                  label: const Text(
                    'حذف',
                    style: TextStyle(fontSize: 10),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: _dangerRed,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text(
          'إدارة المصاريف',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        backgroundColor: _primaryBlue,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.table_chart,
              color: Colors.greenAccent,
            ),
            onPressed: _exportExpensesToExcel,
            tooltip: 'تصدير إكسل',
          ),
          IconButton(
            icon: const Icon(
              Icons.print,
              color: Colors.amberAccent,
            ),
            onPressed: _printExpensesReport,
            tooltip: 'طباعة التقرير',
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isMobile =
                constraints.maxWidth < 650;

            return SingleChildScrollView(
              padding: EdgeInsets.all(
                isMobile ? 12 : 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(
                    maxWidth: 950,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      // نموذج إضافة مصروف
                      Container(
                        padding: EdgeInsets.all(
                          isMobile ? 16 : 20,
                        ),
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius:
                              BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(
                              0xFFE2E8F0,
                            ),
                          ),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '🏢 تسجيل مصروف جديد',
                                style: TextStyle(
                                  color: _primaryBlue,
                                  fontSize: 17,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'المصروف مستقل عن الموردين وسند الصرف',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _expenseTypeField(),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<
                                  String>(
                                value:
                                    _selectedPaymentType,
                                decoration:
                                    _inputDecoration(
                                  'نوع السداد',
                                  Icons
                                      .account_balance_wallet_outlined,
                                ),
                                items: _paymentTypes
                                    .map(
                                      (item) =>
                                          DropdownMenuItem<
                                              String>(
                                        value: item,
                                        child:
                                            Text(
                                        item ==
                                                'نقدي'
                                            ? '💵 نقدي'
                                            : '⏳ آجل',
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value == null) {
                                    return;
                                  }

                                  setState(() {
                                    _selectedPaymentType =
                                        value;

                                    if (value ==
                                        'آجل') {
                                      _selectedPaymentMethod =
                                          'نقدي';
                                    }
                                  });
                                },
                              ),
                              if (_selectedPaymentType ==
                                  'نقدي') ...[
                                const SizedBox(
                                    height: 12),
                                DropdownButtonFormField<
                                    String>(
                                  value:
                                      _selectedPaymentMethod,
                                  decoration:
                                      _inputDecoration(
                                    'طريقة الدفع',
                                    Icons
                                        .payments_outlined,
                                  ),
                                  items: _paymentMethods
                                      .map(
                                        (item) =>
                                            DropdownMenuItem<
                                                String>(
                                          value: item,
                                          child:
                                              Text(item),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value == null) {
                                      return;
                                    }

                                    setState(() {
                                      _selectedPaymentMethod =
                                          value;
                                    });
                                  },
                                ),
                              ],
                              if (_selectedPaymentType ==
                                  'آجل') ...[
                                const SizedBox(
                                    height: 12),
                                TextFormField(
                                  controller:
                                      _creditorController,
                                  decoration:
                                      _inputDecoration(
                                    'اسم الدائن',
                                    Icons.person_outline,
                                  ),
                                  validator: (value) {
                                    if (_selectedPaymentType ==
                                            'آجل' &&
                                        (value == null ||
                                            value
                                                .trim()
                                                .isEmpty)) {
                                      return 'أدخل اسم الدائن';
                                    }

                                    return null;
                                  },
                                ),
                              ],
                              const SizedBox(height: 12),
                              TextFormField(
                                controller:
                                    _amountController,
                                keyboardType:
                                    const TextInputType
                                        .numberWithOptions(
                                  decimal: true,
                                ),
                                decoration:
                                    _inputDecoration(
                                  'المبلغ (ر.ي)',
                                  Icons
                                      .payments_outlined,
                                ),
                                validator: (value) {
                                  final amount =
                                      _parseAmount(
                                    value ?? '',
                                  );

                                  if (amount <= 0) {
                                    return 'أدخل مبلغاً صحيحاً أكبر من صفر';
                                  }

                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller:
                                    _noteController,
                                maxLines: 3,
                                decoration:
                                    _inputDecoration(
                                  'البيان والتفاصيل',
                                  Icons.notes_outlined,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style:
                                      ElevatedButton
                                          .styleFrom(
                                    backgroundColor:
                                        _primaryBlue,
                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                      vertical: 13,
                                    ),
                                  ),
                                  onPressed: _isSaving
                                      ? null
                                      : _saveExpense,
                                  icon: _isSaving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child:
                                              CircularProgressIndicator(
                                            color:
                                                Colors
                                                    .white,
                                            strokeWidth:
                                                2,
                                          ),
                                        )
                                      : const Icon(
                                            Icons
                                                .save_outlined,
                                            color:
                                                Colors.white,
                                          ),
                                  label: Text(
                                    _isSaving
                                        ? 'جاري الحفظ...'
                                        : 'حفظ وترحيل المصروف',
                                    style:
                                        const TextStyle(
                                      color: Colors.white,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // الإحصائيات
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _summaryCard(
                            'إجمالي المصاريف',
                            _totalExpenses,
                            _primaryBlue,
                            Icons
                                .account_balance_wallet,
                          ),
                          _summaryCard(
                            'المصاريف النقدية',
                            _cashExpenses,
                            _successGreen,
                            Icons.payments,
                          ),
                          _summaryCard(
                            'المصاريف الآجلة',
                            _creditExpenses,
                            _warningOrange,
                            Icons.schedule,
                          ),
                          _summaryCard(
                            'المتبقي على الدائنين',
                            _remainingCreditExpenses,
                            _dangerRed,
                            Icons
                                .pending_actions,
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // سجل المصاريف (مع محرك البحث المضاف)
                      Container(
                        padding: EdgeInsets.all(
                          isMobile ? 12 : 18,
                        ),
                        decoration: BoxDecoration(
                          color: _cardCardColorSafely(_cardColor),
                          borderRadius:
                              BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(
                              0xFFE2E8F0,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              '📋 سجل المصاريف',
                              style: TextStyle(
                                color: Color(
                                  0xFF1E293B,
                                ),
                                fontSize: 15,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'المصروف الآجل له دائن مستقل ولا يُعامل كمورد',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                            const Divider(height: 20),

                            // ==================================================
                            // محرك البحث الجديد فوق القائمة
                            // ==================================================
                            TextField(
                              controller: _searchController,
                              style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13),
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'ابحث بنوع المصروف، الدائن، أو البيان...',
                                hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                                prefixIcon: const Icon(Icons.search_rounded, color: _primaryBlueLight, size: 20),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded, color: Colors.grey, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {
                                            _searchQuery = '';
                                          });
                                        },
                                      )
                                    : null,
                                filled: true,
                                isDense: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: _primaryBlue, width: 1.5),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 12),

                            if (_isLoading)
                              const Padding(
                                padding:
                                    EdgeInsets.all(35),
                                child: Center(
                                  child:
                                      CircularProgressIndicator(
                                    color:
                                        _primaryBlue,
                                  ),
                                ),
                              )
                            else if (_filteredExpenses.isEmpty)
                              const Padding(
                                padding:
                                    EdgeInsets.all(35),
                                child: Center(
                                  child: Text(
                                    'لا توجد مصاريف مطابقة للبحث',
                                    style: TextStyle(
                                      color:
                                          Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics:
                                    const NeverScrollableScrollPhysics(),
                                itemCount:
                                    _filteredExpenses.length,
                                itemBuilder:
                                    (context, index) {
                                  return _expenseCard(
                                    _filteredExpenses[index],
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Color _cardCardColorSafely(Color color) => color;

  Widget _summaryCard(
    String title,
    double value,
    Color color,
    IconData icon,
  ) {
    return Container(
      width: 205,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor:
                color.withOpacity(0.1),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${value.toStringAsFixed(0)} ر.ي',
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}