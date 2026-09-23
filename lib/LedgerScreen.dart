import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart' hide Border;

import 'model/ledger_model.dart';

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({Key? key}) : super(key: key);

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  // ============================================================
  // البيانات
  // ============================================================

  List<LedgerModel> _allEntries = [];
  List<LedgerModel> _filteredEntries = [];

  bool _isLoading = true;

  // ============================================================
  // البحث
  // ============================================================

  final TextEditingController _searchController =
      TextEditingController();

  final TextEditingController _accountSearchController =
      TextEditingController();

  final TextEditingController _typeSearchController =
      TextEditingController();

  // ============================================================
  // الفلاتر
  // ============================================================

  String _selectedAccount = 'الكل';
  String _selectedType = 'الكل';

  int _pageSize = 100;

  String _sortOrder = 'DESC';

  // هامش السماح في التوازن المحاسبي
  static const double _moneyTolerance = 0.01;

  // ============================================================
  // الحسابات الرئيسية حسب طبيعتها المحاسبية
  // ============================================================

  static const Set<String> _debitNatureAccounts = {
    'الصندوق الرئيسي',
    'البنك',
    'المخزون السلعي',
    'المخزون',
    'العملاء الذمم',
    'العملاء',
    'المصاريف العامة',
    'المصروفات',
    'تكلفة البضاعة المباعة',
    'الأصول',
    'الأصول الثابتة',
    'المشتريات',
  };

  static const Set<String> _creditNatureAccounts = {
    'الموردون الذمم',
    'الموردون',
    'المبيعات',
    'الإيرادات',
    'رأس المال',
    'الأرباح',
    'الخصوم',
    'الالتزامات',
  };

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _fetchLedgerData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _accountSearchController.dispose();
    _typeSearchController.dispose();
    super.dispose();
  }

  // ============================================================
  // تحميل دفتر الأستاذ
  // ============================================================

  Future<void> _fetchLedgerData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final isar = Isar.getInstance();

      if (isar == null) {
        if (!mounted) return;

        setState(() {
          _allEntries = [];
          _filteredEntries = [];
          _isLoading = false;
        });

        _showMessage(
          'قاعدة البيانات المحلية غير مفتوحة.',
          Colors.orange,
        );

        return;
      }

      final data =
          await isar.ledgerModels.where().findAll();

      data.sort(_compareEntriesChronologically);

      if (!mounted) return;

      setState(() {
        _allEntries = data;
        _isLoading = false;
      });

      _applyFilters();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _allEntries = [];
        _filteredEntries = [];
        _isLoading = false;
      });

      _showMessage(
        'خطأ في جلب بيانات دفتر الأستاذ:\n$e',
        Colors.red,
      );
    }
  }

  // ============================================================
  // الحسابات المتاحة
  // ============================================================

  List<String> get _availableAccounts {
    final Set<String> accounts = {'الكل'};

    for (final entry in _allEntries) {
      final account = entry.accountName?.trim();

      if (account != null && account.isNotEmpty) {
        accounts.add(account);
      }
    }

    final query =
        _accountSearchController.text.trim().toLowerCase();

    final result = accounts.where((account) {
      if (account == 'الكل') {
        return true;
      }

      if (query.isEmpty) {
        return true;
      }

      return account.toLowerCase().contains(query);
    }).toList();

    result.sort((a, b) {
      if (a == 'الكل') return -1;
      if (b == 'الكل') return 1;

      return a.compareTo(b);
    });

    return result;
  }

  // ============================================================
  // أنواع العمليات المتاحة
  // ============================================================

  List<String> get _availableTypes {
    final Set<String> types = {'الكل'};

    for (final entry in _allEntries) {
      final type = entry.entryType?.trim();

      if (type != null && type.isNotEmpty) {
        types.add(type);
      }
    }

    final query =
        _typeSearchController.text.trim().toLowerCase();

    final result = types.where((type) {
      if (type == 'الكل') {
        return true;
      }

      if (query.isEmpty) {
        return true;
      }

      return type.toLowerCase().contains(query);
    }).toList();

    result.sort((a, b) {
      if (a == 'الكل') return -1;
      if (b == 'الكل') return 1;

      return a.compareTo(b);
    });

    return result;
  }

  // ============================================================
  // تطبيق الفلاتر
  // ============================================================

  void _applyFilters() {
    final query =
        _searchController.text.trim().toLowerCase();

    final selectedAccount =
        _selectedAccount.trim().toLowerCase();

    final selectedType =
        _selectedType.trim().toLowerCase();

    List<LedgerModel> results =
        _allEntries.where((entry) {
      final reference =
          entry.referenceNo?.trim().toLowerCase() ?? '';

      final account =
          entry.accountName?.trim().toLowerCase() ?? '';

      final party =
          entry.partyName?.trim().toLowerCase() ?? '';

      final description =
          entry.description?.trim().toLowerCase() ?? '';

      final entryType =
          entry.entryType?.trim().toLowerCase() ?? '';

      final matchesSearch =
          query.isEmpty ||
          reference.contains(query) ||
          account.contains(query) ||
          party.contains(query) ||
          description.contains(query) ||
          entryType.contains(query);

      final matchesAccount =
          selectedAccount == 'الكل' ||
          account == selectedAccount;

      final matchesType =
          selectedType == 'الكل' ||
          entryType == selectedType;

      return matchesSearch &&
          matchesAccount &&
          matchesType;
    }).toList();

    results.sort(_compareEntriesChronologically);

    if (_sortOrder == 'DESC') {
      results = results.reversed.toList();
    }

    if (results.length > _pageSize) {
      results = results.sublist(0, _pageSize);
    }

    if (!mounted) return;

    setState(() {
      _filteredEntries = results;
    });
  }

  // ============================================================
  // ترتيب القيود حسب التاريخ
  // ============================================================

  int _compareEntriesChronologically(
    LedgerModel a,
    LedgerModel b,
  ) {
    final dateA = _parseDate(a.date);
    final dateB = _parseDate(b.date);

    if (dateA != null && dateB != null) {
      final result = dateA.compareTo(dateB);

      if (result != 0) {
        return result;
      }
    } else if (dateA != null) {
      return -1;
    } else if (dateB != null) {
      return 1;
    }

    return a.id.compareTo(b.id);
  }

  // ============================================================
  // تحليل التاريخ
  // ============================================================

  DateTime? _parseDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(value.trim());
  }

  // ============================================================
  // إعادة تعيين الفلاتر
  // ============================================================

  void _clearFilters() {
    _searchController.clear();
    _accountSearchController.clear();
    _typeSearchController.clear();

    setState(() {
      _selectedAccount = 'الكل';
      _selectedType = 'الكل';
      _pageSize = 100;
      _sortOrder = 'DESC';
    });

    _applyFilters();
  }

  // ============================================================
  // هل تم اختيار حساب محدد؟
  // ============================================================

  bool get _isSingleAccount =>
      _selectedAccount != 'الكل';

  // ============================================================
  // إجمالي المدين
  // ============================================================

  double get _totalDebit {
    return _filteredEntries.fold(
      0.0,
      (sum, item) =>
          sum + _safeAmount(item.debit),
    );
  }

  // ============================================================
  // إجمالي الدائن
  // ============================================================

  double get _totalCredit {
    return _filteredEntries.fold(
      0.0,
      (sum, item) =>
          sum + _safeAmount(item.credit),
    );
  }

  // ============================================================
  // صافي الحركة
  // ============================================================

  double get _netMovement {
    return _roundMoney(
      _totalDebit - _totalCredit,
    );
  }

  // ============================================================
  // تحديد طبيعة الحساب
  // ============================================================

  bool? _getAccountNature(String accountName) {
    final account = accountName.trim();

    if (_debitNatureAccounts.contains(account)) {
      return true;
    }

    if (_creditNatureAccounts.contains(account)) {
      return false;
    }

    final lower = account.toLowerCase();

    if (lower.contains('مصروف') ||
        lower.contains('مخزون') ||
        lower.contains('عميل') ||
        lower.contains('صندوق') ||
        lower.contains('بنك') ||
        lower.contains('مشتريات') ||
        lower.contains('تكلفة')) {
      return true;
    }

    if (lower.contains('مورد') ||
        lower.contains('مبيعات') ||
        lower.contains('إيراد') ||
        lower.contains('رأس مال') ||
        lower.contains('التزام') ||
        lower.contains('خصم')) {
      return false;
    }

    return null;
  }

  // ============================================================
  // حساب رصيد حساب معين
  // ============================================================

  double get _accountBalance {
    if (!_isSingleAccount) {
      return 0.0;
    }

    final selected =
        _selectedAccount.trim().toLowerCase();

    double debit = 0.0;
    double credit = 0.0;

    for (final entry in _allEntries) {
      final account =
          entry.accountName?.trim().toLowerCase() ?? '';

      if (account == selected) {
        debit += _safeAmount(entry.debit);
        credit += _safeAmount(entry.credit);
      }
    }

    final rawBalance = debit - credit;

    return _roundMoney(rawBalance);
  }

  // ============================================================
  // هل رصيد الحساب مدين أم دائن؟
  // ============================================================

  String get _accountBalanceSide {
    if (!_isSingleAccount) {
      return '';
    }

    final nature =
        _getAccountNature(_selectedAccount);

    final balance = _accountBalance;

    if (balance.abs() <= _moneyTolerance) {
      return 'متزن';
    }

    if (nature == null) {
      return balance >= 0 ? 'مدين' : 'دائن';
    }

    if (nature) {
      return balance >= 0 ? 'مدين' : 'دائن';
    }

    return balance >= 0 ? 'دائن' : 'مدين';
  }

  // ============================================================
  // كل القيود المطابقة للفلاتر بدون page limit
  // ============================================================

  List<LedgerModel> get _allFilteredWithoutPageLimit {
    final query =
        _searchController.text.trim().toLowerCase();

    final selectedAccount =
        _selectedAccount.trim().toLowerCase();

    final selectedType =
        _selectedType.trim().toLowerCase();

    return _allEntries.where((entry) {
      final reference =
          entry.referenceNo?.trim().toLowerCase() ?? '';

      final account =
          entry.accountName?.trim().toLowerCase() ?? '';

      final party =
          entry.partyName?.trim().toLowerCase() ?? '';

      final description =
          entry.description?.trim().toLowerCase() ?? '';

      final entryType =
          entry.entryType?.trim().toLowerCase() ?? '';

      final matchesSearch =
          query.isEmpty ||
          reference.contains(query) ||
          account.contains(query) ||
          party.contains(query) ||
          description.contains(query) ||
          entryType.contains(query);

      final matchesAccount =
          selectedAccount == 'الكل' ||
          account == selectedAccount;

      final matchesType =
          selectedType == 'الكل' ||
          entryType == selectedType;

      return matchesSearch &&
          matchesAccount &&
          matchesType;
    }).toList();
  }

  // ============================================================
  // الرصيد الجاري لحساب واحد
  // ============================================================

  Map<int, double> _calculateRunningBalances() {
    final Map<int, double> balances = {};

    if (!_isSingleAccount) {
      return balances;
    }

    final selected =
        _selectedAccount.trim().toLowerCase();

    final accountEntries =
        _allEntries.where((entry) {
      final account =
          entry.accountName?.trim().toLowerCase() ?? '';

      return account == selected;
    }).toList();

    accountEntries.sort(
      _compareEntriesChronologically,
    );

    double runningBalance = 0.0;

    for (final entry in accountEntries) {
      runningBalance +=
          _safeAmount(entry.debit);

      runningBalance -=
          _safeAmount(entry.credit);

      runningBalance =
          _roundMoney(runningBalance);

      balances[entry.id] = runningBalance;
    }

    return balances;
  }

  // ============================================================
  // حماية المبالغ
  // ============================================================

  double _safeAmount(double value) {
    if (value.isNaN || value.isInfinite) {
      return 0.0;
    }

    return value;
  }

  // ============================================================
  // تقريب المبالغ
  // ============================================================

  double _roundMoney(double value) {
    return (value * 100).roundToDouble() / 100;
  }

  // ============================================================
  // بناء خريطة توازن القيود حسب المرجع
  // ============================================================

  Map<String, bool> _buildEntryBalanceMap(
    List<LedgerModel> entries,
  ) {
    final Map<String, double> debitTotals = {};
    final Map<String, double> creditTotals = {};

    for (final entry in _allEntries) {
      final reference =
          entry.referenceNo?.trim() ?? '';

      if (reference.isEmpty) {
        continue;
      }

      debitTotals[reference] =
          (debitTotals[reference] ?? 0.0) +
              _safeAmount(entry.debit);

      creditTotals[reference] =
          (creditTotals[reference] ?? 0.0) +
              _safeAmount(entry.credit);
    }

    final Map<String, bool> result = {};

    final references = {
      ...debitTotals.keys,
      ...creditTotals.keys,
    };

    for (final reference in references) {
      final debit =
          _roundMoney(
        debitTotals[reference] ?? 0.0,
      );

      final credit =
          _roundMoney(
        creditTotals[reference] ?? 0.0,
      );

      final balanced =
          (debit - credit).abs() <=
              _moneyTolerance &&
          (debit > 0 || credit > 0);

      result[reference] = balanced;
    }

    return result;
  }

  // ============================================================
  // حالة القيد
  // ============================================================

  bool _isReferenceBalanced(
    LedgerModel entry,
    Map<String, bool> balanceMap,
  ) {
    final reference =
        entry.referenceNo?.trim() ?? '';

    if (reference.isEmpty) {
      return (
            _safeAmount(entry.debit) -
                _safeAmount(entry.credit)
          ).abs() <=
          _moneyTolerance;
    }

    return balanceMap[reference] ?? false;
  }

  // ============================================================
  // إجمالي المرجع
  // ============================================================

  Map<String, double> _referenceTotals(
    String reference,
  ) {
    double debit = 0.0;
    double credit = 0.0;

    for (final entry in _allEntries) {
      if ((entry.referenceNo?.trim() ?? '') ==
          reference.trim()) {
        debit += _safeAmount(entry.debit);
        credit += _safeAmount(entry.credit);
      }
    }

    return {
      'debit': _roundMoney(debit),
      'credit': _roundMoney(credit),
      'difference':
          _roundMoney(debit - credit),
    };
  }

  // ============================================================
  // شارة حالة القيد
  // ============================================================

  Widget _entryStatusBadge(
    LedgerModel entry,
    Map<String, bool> balanceMap,
  ) {
    final balanced =
        _isReferenceBalanced(
      entry,
      balanceMap,
    );

    if (balanced) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 7,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: const Color(0xFF86EFAC),
          ),
        ),
        child: const Text(
          'متوازن',
          style: TextStyle(
            color: Color(0xFF15803D),
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFFFCA5A5),
        ),
      ),
      child: const Text(
        'غير متوازن',
        style: TextStyle(
          color: Color(0xFFB91C1C),
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // تفاصيل القيد
  // ============================================================

  void _showEntryDetails(
    LedgerModel entry,
  ) {
    final reference =
        entry.referenceNo?.trim() ?? '';

    final totals = reference.isEmpty
        ? {
            'debit': _safeAmount(entry.debit),
            'credit': _safeAmount(entry.credit),
            'difference':
                _safeAmount(entry.debit) -
                    _safeAmount(entry.credit),
          }
        : _referenceTotals(reference);

    final difference =
        _roundMoney(
      totals['difference'] ?? 0.0,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.receipt_long_outlined,
                          color: Color(0xFF1E40AF),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'تفاصيل القيد المحاسبي',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                        
                      ],
                    ),

                    const Divider(),

                    _detailRow(
                      'رقم المرجع',
                      reference.isEmpty
                          ? '-'
                          : reference,
                    ),

                    _detailRow(
                      'التاريخ',
                      _formatDate(entry.date),
                    ),

                    _detailRow(
                      'نوع العملية',
                      entry.entryType ?? '-',
                    ),

                    _detailRow(
                      'الحساب',
                      entry.accountName ?? '-',
                    ),

                    _detailRow(
                      'الطرف',
                      entry.partyName ?? '-',
                    ),

                    _detailRow(
                      'مدين',
                      '${_safeAmount(entry.debit).toStringAsFixed(2)} ر.ي',
                    ),

                    _detailRow(
                      'دائن',
                      '${_safeAmount(entry.credit).toStringAsFixed(2)} ر.ي',
                    ),

                    _detailRow(
                      'فرق القيد',
                      '${difference.toStringAsFixed(2)} ر.ي',
                    ),

                    _detailRow(
                      'البيان',
                      entry.description ?? '-',
                    ),

                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: difference.abs() <=
                                _moneyTolerance
                            ? const Color(0xFFF0FDF4)
                            : const Color(0xFFFEF2F2),
                        borderRadius:
                            BorderRadius.circular(10),
                        border: Border.all(
                          color: difference.abs() <=
                                  _moneyTolerance
                              ? const Color(0xFFBBF7D0)
                              : const Color(0xFFFECACA),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            difference.abs() <=
                                    _moneyTolerance
                                ? Icons.check_circle
                                : Icons.warning_amber_rounded,
                            size: 20,
                            color: difference.abs() <=
                                    _moneyTolerance
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              difference.abs() <=
                                      _moneyTolerance
                                  ? 'القيد متوازن محاسبيًا'
                                  : 'تنبيه: القيد غير متوازن',
                              style: TextStyle(
                                color: difference.abs() <=
                                        _moneyTolerance
                                    ? const Color(0xFF15803D)
                                    : const Color(0xFFB91C1C),
                                fontWeight:
                                    FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // صف تفاصيل
  // ============================================================

  Widget _detailRow(
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 95,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PDF (مع دعم اللغة العربية عبر خط Cairo)
  // ============================================================

 Future<void> _printLedger() async {
  try {
    if (_filteredEntries.isEmpty) {
      if (!mounted) return;

      _showMessage(
        'لا توجد قيود لطباعة دفتر الأستاذ.',
        Colors.orange,
      );

      return;
    }

    // ============================================================
    // إنشاء PDF
    // ============================================================

    final doc = pw.Document();

    // الخط العربي
    final arabicFont =
        await PdfGoogleFonts.cairoRegular();

    final arabicBold =
        await PdfGoogleFonts.cairoBold();

    // ============================================================
    // الأرصدة
    // ============================================================

    final balances =
        _calculateRunningBalances();

    final balanceMap =
        _buildEntryBalanceMap(
      _allFilteredWithoutPageLimit,
    );

    // ============================================================
    // دالة اختصار النصوص الطويلة
    // ============================================================

    String shortText(
      String? value, {
      int max = 35,
    }) {
      final text =
          value?.trim() ?? '';

      if (text.isEmpty) {
        return '-';
      }

      if (text.length <= max) {
        return text;
      }

      return '${text.substring(0, max)}...';
    }

    // ============================================================
    // تنسيق المبلغ
    // ============================================================

    String money(double value) {
      return value.toStringAsFixed(2);
    }

    // ============================================================
    // الخطوط
    // ============================================================

    final textStyle = pw.TextStyle(
      font: arabicFont,
      fontSize: 6.5,
    );

    final boldStyle = pw.TextStyle(
      font: arabicBold,
      fontSize: 7,
      fontWeight: pw.FontWeight.bold,
    );

    final titleStyle = pw.TextStyle(
      font: arabicBold,
      fontSize: 16,
      fontWeight: pw.FontWeight.bold,
    );

    // ============================================================
    // عدد القيود في الصفحة
    //
    // 20 قيد آمن جدًا مع A4 Landscape
    // ============================================================

    const int rowsPerPage = 20;

    final totalEntries =
        _filteredEntries.length;

    final totalDataPages =
        (totalEntries / rowsPerPage).ceil();

    // ============================================================
    // إنشاء صفحات البيانات يدويًا
    // ============================================================

    for (
      int pageIndex = 0;
      pageIndex < totalDataPages;
      pageIndex++
    ) {
      final start =
          pageIndex * rowsPerPage;

      final end =
          (start + rowsPerPage)
              .clamp(
        0,
        totalEntries,
      );

      final pageEntries =
          _filteredEntries.sublist(
        start,
        end,
      );

      // ==========================================================
      // بيانات الصفحة الحالية
      // ==========================================================

      final pageTableData =
          pageEntries.map((entry) {
        final balance =
            balances[entry.id] ?? 0.0;

        final balanced =
            _isReferenceBalanced(
          entry,
          balanceMap,
        );

        final debit =
            _safeAmount(entry.debit);

        final credit =
            _safeAmount(entry.credit);

        return <String>[
          shortText(
            entry.referenceNo,
            max: 18,
          ),

          shortText(
            entry.date,
            max: 16,
          ),

          shortText(
            entry.entryType,
            max: 15,
          ),

          shortText(
            entry.accountName,
            max: 22,
          ),

          debit > 0
              ? money(debit)
              : '-',

          credit > 0
              ? money(credit)
              : '-',

          _isSingleAccount
              ? money(balance)
              : '-',

          balanced
              ? 'متوازن'
              : 'غير متوازن',

          shortText(
            entry.description,
            max: 35,
          ),
        ];
      }).toList();

      // ==========================================================
      // صفحة واحدة فقط
      //
      // لا MultiPage
      // ==========================================================

      doc.addPage(
        pw.Page(
          pageFormat:
              PdfPageFormat.a4.landscape,

          margin:
              const pw.EdgeInsets.fromLTRB(
            18,
            18,
            18,
            18,
          ),

          build: (context) {
            return pw.Directionality(
              textDirection:
                  pw.TextDirection.rtl,

              child: pw.Column(
                crossAxisAlignment:
                    pw.CrossAxisAlignment
                        .stretch,

                children: [
                  // =================================================
                  // العنوان
                  // =================================================

                  pw.Text(
                    'دفتر الأستاذ العام',
                    style: titleStyle,
                    textAlign:
                        pw.TextAlign.center,
                  ),

                  pw.SizedBox(
                    height: 2,
                  ),

                  pw.Text(
                    'عمر سوفت ERP',
                    style:
                        pw.TextStyle(
                      font: arabicFont,
                      fontSize: 8,
                    ),
                    textAlign:
                        pw.TextAlign.center,
                  ),

                  pw.SizedBox(
                    height: 5,
                  ),

                  // =================================================
                  // معلومات الصفحة
                  // =================================================

                  pw.Row(
                    mainAxisAlignment:
                        pw.MainAxisAlignment
                            .spaceBetween,

                    children: [
                      pw.Text(
                        'عدد القيود: $totalEntries',
                        style: textStyle,
                      ),

                      pw.Text(
                        'صفحة ${pageIndex + 1} من $totalDataPages',
                        style: textStyle,
                      ),
                    ],
                  ),

                  pw.SizedBox(
                    height: 5,
                  ),

                  // =================================================
                  // الفلاتر
                  // =================================================

                  if (_selectedAccount !=
                          'الكل' ||
                      _selectedType !=
                          'الكل')
                    pw.Container(
                      margin:
                          const pw.EdgeInsets
                              .only(
                        bottom: 5,
                      ),

                      padding:
                          const pw.EdgeInsets
                              .all(4),

                      decoration:
                          pw.BoxDecoration(
                        border:
                            pw.Border.all(
                          width: 0.4,
                        ),
                      ),

                      child: pw.Row(
                        children: [
                          if (_selectedAccount !=
                              'الكل')
                            pw.Expanded(
                              child:
                                  pw.Text(
                                'الحساب: $_selectedAccount',
                                style:
                                    boldStyle,
                              ),
                            ),

                          if (_selectedType !=
                              'الكل')
                            pw.Expanded(
                              child:
                                  pw.Text(
                                'نوع العملية: $_selectedType',
                                style:
                                    boldStyle,
                              ),
                            ),
                        ],
                      ),
                    ),

                  // =================================================
                  // الجدول
                  // =================================================

                  pw.Expanded(
                    child:
                        pw.TableHelper
                            .fromTextArray(
                      headers: const [
                        'المرجع',
                        'التاريخ',
                        'نوع العملية',
                        'الحساب',
                        'مدين',
                        'دائن',
                        'الرصيد',
                        'الحالة',
                        'البيان',
                      ],

                      data:
                          pageTableData,

                      headerStyle:
                          boldStyle,

                      cellStyle:
                          textStyle,

                      headerAlignment:
                          pw.Alignment
                              .center,

                      cellAlignment:
                          pw.Alignment
                              .center,

                      border:
                          pw.TableBorder.all(
                        width: 0.35,
                      ),

                      cellPadding:
                          const pw.EdgeInsets
                              .symmetric(
                        horizontal: 2,
                        vertical: 2,
                      ),

                      columnWidths: {
                        // المرجع
                        0: const pw.FixedColumnWidth(
                          55,
                        ),

                        // التاريخ
                        1: const pw.FixedColumnWidth(
                          65,
                        ),

                        // النوع
                        2: const pw.FixedColumnWidth(
                          65,
                        ),

                        // الحساب
                        3: const pw.FixedColumnWidth(
                          90,
                        ),

                        // مدين
                        4: const pw.FixedColumnWidth(
                          55,
                        ),

                        // دائن
                        5: const pw.FixedColumnWidth(
                          55,
                        ),

                        // الرصيد
                        6: const pw.FixedColumnWidth(
                          60,
                        ),

                        // الحالة
                        7: const pw.FixedColumnWidth(
                          60,
                        ),

                        // البيان
                        8: const pw.FlexColumnWidth(
                          2,
                        ),
                      },
                    ),
                  ),

                  // =================================================
                  // أسفل الصفحة
                  // =================================================

                  pw.SizedBox(
                    height: 5,
                  ),

                  pw.Row(
                    mainAxisAlignment:
                        pw.MainAxisAlignment
                            .spaceBetween,

                    children: [
                      pw.Text(
                        'عمر سوفت ERP',
                        style:
                            pw.TextStyle(
                          font: arabicFont,
                          fontSize: 6.5,
                        ),
                      ),

                      pw.Text(
                        'دفتر الأستاذ العام',
                        style:
                            pw.TextStyle(
                          font: arabicFont,
                          fontSize: 6.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    // ============================================================
    // صفحة الملخص النهائية
    // ============================================================

    doc.addPage(
      pw.Page(
        pageFormat:
            PdfPageFormat.a4.landscape,

        margin:
            const pw.EdgeInsets.all(30),

        build: (context) {
          return pw.Directionality(
            textDirection:
                pw.TextDirection.rtl,

            child: pw.Column(
              crossAxisAlignment:
                  pw.CrossAxisAlignment
                      .stretch,

              children: [
                pw.Text(
                  'ملخص دفتر الأستاذ',
                  style: pw.TextStyle(
                    font: arabicBold,
                    fontSize: 20,
                    fontWeight:
                        pw.FontWeight.bold,
                  ),
                  textAlign:
                      pw.TextAlign.center,
                ),

                pw.SizedBox(
                  height: 5,
                ),

                pw.Text(
                  'عمر سوفت ERP',
                  style: pw.TextStyle(
                    font: arabicFont,
                    fontSize: 10,
                  ),
                  textAlign:
                      pw.TextAlign.center,
                ),

                pw.SizedBox(
                  height: 25,
                ),

                // ==================================================
                // الحساب
                // ==================================================

                if (_selectedAccount !=
                    'الكل')
                  pw.Container(
                    padding:
                        const pw.EdgeInsets
                            .all(12),

                    margin:
                        const pw.EdgeInsets
                            .only(
                      bottom: 10,
                    ),

                    decoration:
                        pw.BoxDecoration(
                      border:
                          pw.Border.all(
                        width: 0.5,
                      ),
                    ),

                    child: pw.Text(
                      'الحساب: $_selectedAccount',
                      style:
                          boldStyle,
                    ),
                  ),

                // ==================================================
                // النوع
                // ==================================================

                if (_selectedType !=
                    'الكل')
                  pw.Container(
                    padding:
                        const pw.EdgeInsets
                            .all(12),

                    margin:
                        const pw.EdgeInsets
                            .only(
                      bottom: 10,
                    ),

                    decoration:
                        pw.BoxDecoration(
                      border:
                          pw.Border.all(
                        width: 0.5,
                      ),
                    ),

                    child: pw.Text(
                      'نوع العملية: $_selectedType',
                      style:
                          boldStyle,
                    ),
                  ),

                // ==================================================
                // إجمالي المدين
                // ==================================================

                pw.Container(
                  padding:
                      const pw.EdgeInsets
                          .all(14),

                  margin:
                      const pw.EdgeInsets
                          .only(
                    bottom: 8,
                  ),

                  decoration:
                      pw.BoxDecoration(
                    border:
                        pw.Border.all(
                      width: 0.5,
                    ),
                  ),

                  child: pw.Row(
                    mainAxisAlignment:
                        pw.MainAxisAlignment
                            .spaceBetween,

                    children: [
                      pw.Text(
                        'إجمالي المدين',
                        style:
                            boldStyle,
                      ),

                      pw.Text(
                        '${_totalDebit.toStringAsFixed(2)} ر.ي',
                        style:
                            boldStyle,
                      ),
                    ],
                  ),
                ),

                // ==================================================
                // إجمالي الدائن
                // ==================================================

                pw.Container(
                  padding:
                      const pw.EdgeInsets
                          .all(14),

                  margin:
                      const pw.EdgeInsets
                          .only(
                    bottom: 8,
                  ),

                  decoration:
                      pw.BoxDecoration(
                    border:
                        pw.Border.all(
                      width: 0.5,
                    ),
                  ),

                  child: pw.Row(
                    mainAxisAlignment:
                        pw.MainAxisAlignment
                            .spaceBetween,

                    children: [
                      pw.Text(
                        'إجمالي الدائن',
                        style:
                            boldStyle,
                      ),

                      pw.Text(
                        '${_totalCredit.toStringAsFixed(2)} ر.ي',
                        style:
                            boldStyle,
                      ),
                    ],
                  ),
                ),

                // ==================================================
                // صافي الحركة
                // ==================================================

                pw.Container(
                  padding:
                      const pw.EdgeInsets
                          .all(14),

                  margin:
                      const pw.EdgeInsets
                          .only(
                    bottom: 8,
                  ),

                  decoration:
                      pw.BoxDecoration(
                    border:
                        pw.Border.all(
                      width: 0.5,
                    ),
                  ),

                  child: pw.Row(
                    mainAxisAlignment:
                        pw.MainAxisAlignment
                            .spaceBetween,

                    children: [
                      pw.Text(
                        'صافي الحركة',
                        style:
                            boldStyle,
                      ),

                      pw.Text(
                        '${_netMovement.toStringAsFixed(2)} ر.ي',
                        style:
                            boldStyle,
                      ),
                    ],
                  ),
                ),

                // ==================================================
                // رصيد الحساب
                // ==================================================

                if (_isSingleAccount) ...[
                  pw.Container(
                    padding:
                        const pw.EdgeInsets
                            .all(14),

                    margin:
                        const pw.EdgeInsets
                            .only(
                      bottom: 8,
                    ),

                    decoration:
                        pw.BoxDecoration(
                      border:
                          pw.Border.all(
                        width: 0.5,
                      ),
                    ),

                    child: pw.Row(
                      mainAxisAlignment:
                          pw.MainAxisAlignment
                              .spaceBetween,

                      children: [
                        pw.Text(
                          'الرصيد النهائي',
                          style:
                              boldStyle,
                        ),

                        pw.Text(
                          '${_accountBalance.toStringAsFixed(2)} ر.ي',
                          style:
                              boldStyle,
                        ),
                      ],
                    ),
                  ),

                  pw.Container(
                    padding:
                        const pw.EdgeInsets
                            .all(14),

                    decoration:
                        pw.BoxDecoration(
                      border:
                          pw.Border.all(
                        width: 0.5,
                      ),
                    ),

                    child: pw.Row(
                      mainAxisAlignment:
                          pw.MainAxisAlignment
                              .spaceBetween,

                      children: [
                        pw.Text(
                          'طبيعة الرصيد',
                          style:
                              boldStyle,
                        ),

                        pw.Text(
                          _accountBalanceSide,
                          style:
                              boldStyle,
                        ),
                      ],
                    ),
                  ),
                ],

                pw.Spacer(),

                pw.Text(
                  'إجمالي القيود المطبوعة: $totalEntries',
                  style: textStyle,
                  textAlign:
                      pw.TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );

    // ============================================================
    // إرسال PDF للطابعة
    // ============================================================

    final pdfBytes =
        await doc.save();

    await Printing.layoutPdf(
      onLayout:
          (PdfPageFormat format) async {
        return pdfBytes;
      },
    );
  } catch (e, stackTrace) {
    debugPrint(
      '====================================',
    );

    debugPrint(
      'PDF ERROR:',
    );

    debugPrint(
      e.toString(),
    );

    debugPrint(
      stackTrace.toString(),
    );

    debugPrint(
      '====================================',
    );

    if (!mounted) return;

    _showMessage(
      'خطأ في إنشاء PDF:\n$e',
      Colors.red,
    );
  }
}

  // ============================================================
  // النسخة الاحتياطية الفعلية لقاعدة Isar
  // ============================================================
// ============================================================
// 🗑️ زر وتصفير وحذف جميع القيود المحاسبية من دفتر الأستاذ
// ============================================================
/*Future<void> _deleteAllLedgerEntries() async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text(
          '⚠️ تحذير: حذف جميع القيود',
          textDirection: TextDirection.rtl,
          style: TextStyle(color: Colors.red),
        ),
        content: const Text(
          'هل أنت متأكد تماماً من رغبتك في حذف جميع قيود دفتر الأستاذ؟\n\n'
          '• سيتم مسح كافة القيود المحاسبية نهائياً.\n'
          '• لن يتم المساس بالفواتير، المخزون، أو حسابات العملاء.\n'
          '• هذه الخطوة لا يمكن التراجع عنها!',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('تراجع'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('نعم، احذف الكل'),
          ),
        ],
      );
    },
  );

  if (confirmed != true) return;

  try {
    final isar = Isar.getInstance();

    if (isar == null || !isar.isOpen) {
      throw Exception('قاعدة البيانات غير مفتوحة');
    }

    int deletedCount = 0;

    // تنفيذ الحذف بمعاملة (Transaction) واحدة صحيحة ومباشرة
    await isar.writeTxn(() async {
      deletedCount = await isar.ledgerModels.count();
      await isar.ledgerModels.clear();
    });

    await _fetchLedgerData();

    if (!mounted) return;

    _showMessage(
      'تم تصفير دفتر الأستاذ بنجاح ✅\n'
      'عدد القيود المحذوفة: $deletedCount',
      Colors.green,
    );
  } catch (e) {
    if (!mounted) return;

    _showMessage(
      'فشل حذف القيود:\n$e',
      Colors.red,
    );
  }
}*/
  Future<void> _backupDatabase() async {
    try {
      final isar = Isar.getInstance();

      if (isar == null || !isar.isOpen) {
        throw Exception('قاعدة البيانات غير مفتوحة');
      }

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');

      final path =
          '${directory.path}/OmarSoft_ERP_Backup_$timestamp.isar';

      final backupFile = File(path);

      if (await backupFile.exists()) {
        await backupFile.delete();
      }

      await isar.copyToFile(path);

      if (!await backupFile.exists()) {
        throw Exception('لم يتم إنشاء ملف النسخة الاحتياطية');
      }

      final size = await backupFile.length();

      if (size <= 0) {
        throw Exception('ملف النسخة الاحتياطية فارغ');
      }

      await Share.shareXFiles(
        [XFile(path)],
        subject: 'نسخة احتياطية - عمر سوفت ERP',
        text: 'نسخة احتياطية كاملة لقاعدة بيانات عمر سوفت ERP.\n'
            'احتفظ بالملف لاستعادة بيانات النظام عند الحاجة.',
      );

      if (!mounted) return;

      _showMessage(
        'تم إنشاء النسخة الاحتياطية الكاملة بنجاح ✅',
        Colors.green,
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'خطأ أثناء إنشاء النسخة الاحتياطية:\n$e',
        Colors.red,
      );
    }
  }

  // ============================================================
  // Excel
  // ============================================================

  Future<void> _exportToExcel() async {
    try {
      final excel =
          Excel.createExcel();

      final defaultSheet =
          excel.getDefaultSheet();

      if (defaultSheet != null &&
          defaultSheet != 'دفتر الأستاذ') {
        excel.delete(defaultSheet);
      }

      final sheet =
          excel['دفتر الأستاذ'];

      sheet.appendRow([
        TextCellValue(
          'دفتر الأستاذ العام',
        ),
      ]);

      sheet.appendRow([
        TextCellValue(
          'عمر سوفت ERP',
        ),
      ]);

      sheet.appendRow([
        TextCellValue(
          'تاريخ التصدير',
        ),
        TextCellValue(
          DateTime.now()
              .toIso8601String(),
        ),
      ]);

      if (_selectedAccount !=
          'الكل') {
        sheet.appendRow([
          TextCellValue('الحساب'),
          TextCellValue(
            _selectedAccount,
          ),
        ]);
      }

      if (_selectedType != 'الكل') {
        sheet.appendRow([
          TextCellValue(
            'نوع العملية',
          ),
          TextCellValue(
            _selectedType,
          ),
        ]);
      }

      sheet.appendRow([]);

      sheet.appendRow([
        TextCellValue('المرجع'),
        TextCellValue('التاريخ'),
        TextCellValue('نوع العملية'),
        TextCellValue('الحساب'),
        TextCellValue('الطرف'),
        TextCellValue('مدين'),
        TextCellValue('دائن'),
        TextCellValue('الرصيد'),
        TextCellValue('الحالة'),
        TextCellValue('البيان'),
      ]);

      final balances =
          _calculateRunningBalances();

      final balanceMap =
          _buildEntryBalanceMap(
        _allFilteredWithoutPageLimit,
      );

      for (final entry
          in _filteredEntries) {
        final balance =
            balances[entry.id] ?? 0.0;

        final balanced =
            _isReferenceBalanced(
          entry,
          balanceMap,
        );

        sheet.appendRow([
          TextCellValue(
            entry.referenceNo ?? '',
          ),
          TextCellValue(
            entry.date ?? '',
          ),
          TextCellValue(
            entry.entryType ?? '',
          ),
          TextCellValue(
            entry.accountName ?? '',
          ),
          TextCellValue(
            entry.partyName ?? '',
          ),
          DoubleCellValue(
            _safeAmount(entry.debit),
          ),
          DoubleCellValue(
            _safeAmount(entry.credit),
          ),
          DoubleCellValue(
            _isSingleAccount
                ? balance
                : 0.0,
          ),
          TextCellValue(
            balanced
                ? 'متوازن'
                : 'غير متوازن',
          ),
          TextCellValue(
            entry.description ?? '',
          ),
        ]);
      }

      sheet.appendRow([]);

      sheet.appendRow([
        TextCellValue(
          'إجمالي المدين',
        ),
        DoubleCellValue(
          _totalDebit,
        ),
      ]);

      sheet.appendRow([
        TextCellValue(
          'إجمالي الدائن',
        ),
        DoubleCellValue(
          _totalCredit,
        ),
      ]);

      sheet.appendRow([
        TextCellValue(
          'صافي الحركة',
        ),
        DoubleCellValue(
          _netMovement,
        ),
      ]);

      if (_isSingleAccount) {
        sheet.appendRow([
          TextCellValue(
            'الرصيد النهائي',
          ),
          DoubleCellValue(
            _accountBalance,
          ),
        ]);

        sheet.appendRow([
          TextCellValue(
            'طبيعة الرصيد',
          ),
          TextCellValue(
            _accountBalanceSide,
          ),
        ]);
      }

      final bytes =
          excel.encode();

      if (bytes == null) {
        throw Exception(
          'تعذر إنشاء ملف Excel.',
        );
      }

      final directory =
          await getTemporaryDirectory();

      final fileName =
          'general_ledger_${DateTime.now().millisecondsSinceEpoch}.xlsx';

      final path =
          '${directory.path}/$fileName';

      final file = File(path);

      await file.writeAsBytes(
        bytes,
        flush: true,
      );

      await Share.shareXFiles(
        [XFile(path)],
        text:
            'دفتر الأستاذ العام - عمر سوفت ERP',
      );

      if (!mounted) return;

      _showMessage(
        'تم إنشاء ملف Excel بنجاح.',
        Colors.green,
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'خطأ أثناء تصدير Excel:\n$e',
        Colors.red,
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
            const Color(0xFFF8FAFC),

        appBar: AppBar(
          backgroundColor:
              const Color(0xFF1E40AF),
          elevation: 0,

          title: const Text(
            '📖 دفتر الأستاذ العام',
            style: TextStyle(
              color: Colors.white,
              fontWeight:
                  FontWeight.bold,
              fontSize: 16,
            ),
          ),

          actions: [
      /*      IconButton(
  icon: const Icon(
    Icons.delete_sweep,
    color: Colors.white,
  ),
  tooltip: 'حذف جميع القيود',
  onPressed: _isLoading
      ? null
      : _deleteAllLedgerEntries,
),*/
            IconButton(
              icon: const Icon(
                Icons.refresh,
                color: Colors.white,
              ),
              tooltip: 'تحديث',

              onPressed: _isLoading
                  ? null
                  : _fetchLedgerData,
            ),
          ],
        ),

        body: _isLoading
            ? const Center(
                child:
                    CircularProgressIndicator(
                  color:
                      Color(0xFF1E40AF),
                ),
              )
            : RefreshIndicator(
                color:
                    const Color(
                  0xFF1E40AF,
                ),

                onRefresh:
                    _fetchLedgerData,

                child:
                    SingleChildScrollView(
                  physics:
                      const AlwaysScrollableScrollPhysics(),

                  padding:
                      const EdgeInsets.all(
                    12,
                  ),

                  child: Column(
                    children: [
                      _buildFilters(),

                      const SizedBox(
                        height: 16,
                      ),

                      _buildLedgerCard(),

                      const SizedBox(
                        height: 16,
                      ),

                      _buildSummary(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ============================================================
  // الفلاتر
  // ============================================================

  Widget _buildFilters() {
    final accountsList =
        _availableAccounts;

    final typesList =
        _availableTypes;

    if (!accountsList.contains(
      _selectedAccount,
    )) {
      _selectedAccount = 'الكل';
    }

    if (!typesList.contains(
      _selectedType,
    )) {
      _selectedType = 'الكل';
    }

    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color:
                Colors.blue.withOpacity(
              0.04,
            ),
            blurRadius: 10,
            offset:
                const Offset(0, 4),
          ),
        ],

        border: Border.all(
          color:
              const Color(0xFFE2E8F0),
        ),
      ),

      child: Column(
        children: [
          _buildFilterField(
            'البحث الحر',

            TextField(
              controller:
                  _searchController,

              onChanged: (_) =>
                  _applyFilters(),

              style: const TextStyle(
                color:
                    Color(0xFF1E293B),
                fontSize: 12,
              ),

              decoration:
                  const InputDecoration(
                hintText:
                    'ابحث بالمرجع أو الحساب أو العميل أو المورد أو البيان...',

                hintStyle:
                    TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                ),

                border:
                    InputBorder.none,

                isDense: true,

                prefixIcon:
                    Icon(
                  Icons.search,
                  color:
                      Color(0xFF2563EB),
                  size: 18,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Row(
            children: [
              Expanded(
                child:
                    _buildFilterField(
                  'الحساب الرئيسي',

                  DropdownButtonHideUnderline(
                    child:
                        DropdownButton<String>(
                      value:
                          _selectedAccount,

                      isExpanded: true,

                      dropdownColor:
                          Colors.white,

                      style:
                          const TextStyle(
                        color:
                            Color(0xFF1E293B),
                        fontSize: 12,
                        fontWeight:
                            FontWeight.bold,
                      ),

                      items: accountsList
                          .map(
                            (account) =>
                                DropdownMenuItem<
                                    String>(
                              value:
                                  account,

                              child:
                                  Text(
                              account,
                              overflow:
                                  TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),

                      onChanged:
                          (value) {
                        if (value ==
                            null) {
                          return;
                        }

                        setState(() {
                          _selectedAccount =
                              value;
                        });

                        _applyFilters();
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              SizedBox(
                width: 125,

                child: TextField(
                  controller:
                      _accountSearchController,

                  onChanged: (_) =>
                      setState(() {}),

                  style:
                      const TextStyle(
                    fontSize: 11,
                  ),

                  decoration:
                      InputDecoration(
                    hintText:
                        'بحث الحساب...',

                    hintStyle:
                        const TextStyle(
                      fontSize: 9,
                    ),

                    isDense: true,

                    filled: true,

                    fillColor:
                        const Color(
                      0xFFF8FAFC,
                    ),

                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        8,
                      ),

                      borderSide:
                          const BorderSide(
                        color:
                            Color(
                          0xFFE2E8F0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 8,
          ),

          Row(
            children: [
              Expanded(
                child:
                    _buildFilterField(
                  'نوع العملية',

                  DropdownButtonHideUnderline(
                    child:
                        DropdownButton<String>(
                      value:
                          _selectedType,

                      isExpanded: true,

                      dropdownColor:
                          Colors.white,

                      style:
                          const TextStyle(
                        color:
                            Color(0xFF1E293B),
                        fontSize: 12,
                        fontWeight:
                            FontWeight.bold,
                      ),

                      items: typesList
                          .map(
                            (type) =>
                                DropdownMenuItem<
                                    String>(
                              value: type,

                              child:
                                  Text(
                              type,
                              overflow:
                                  TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),

                      onChanged:
                          (value) {
                        if (value ==
                            null) {
                          return;
                        }

                        setState(() {
                          _selectedType =
                              value;
                        });

                        _applyFilters();
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              SizedBox(
                width: 125,

                child: TextField(
                  controller:
                      _typeSearchController,

                  onChanged: (_) =>
                      setState(() {}),

                  style:
                      const TextStyle(
                    fontSize: 11,
                  ),

                  decoration:
                      InputDecoration(
                    hintText:
                        'بحث النوع...',

                    hintStyle:
                        const TextStyle(
                      fontSize: 9,
                    ),

                    isDense: true,

                    filled: true,

                    fillColor:
                        const Color(
                      0xFFF8FAFC,
                    ),

                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        8,
                      ),

                      borderSide:
                          const BorderSide(
                        color:
                            Color(
                          0xFFE2E8F0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          const Divider(
            color:
                Color(0xFFE2E8F0),
          ),

          const SizedBox(
            height: 8,
          ),

          Wrap(
            spacing: 8,
            runSpacing: 8,

            children: [
              _smallDropdownContainer(
                'عرض:',
                const [
                  50,
                  100,
                  250,
                  500,
                ],
                _pageSize,
                (value) {
                  setState(() {
                    _pageSize =
                        value;
                  });

                  _applyFilters();
                },
              ),

              _smallOrderDropdown(
                'ترتيب:',
                _sortOrder,
                (value) {
                  setState(() {
                    _sortOrder =
                        value;
                  });

                  _applyFilters();
                },
              ),

              _actionButton(
                '🖨️ طباعة',
                const Color(
                  0xFF0284C7,
                ),
                _printLedger,
              ),

              _actionButton(
                '💾 نسخة احتياطية',
                const Color(
                  0x7C3AED,
                ),
                _backupDatabase,
              ),

              _actionButton(
                '📊 Excel',
                const Color(
                  0xFF16A34A,
                ),
                _exportToExcel,
              ),

              _actionButton(
                '🔄 إعادة تعيين',
                Colors.grey,
                _clearFilters,
                isSecondary:
                    true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // بطاقة دفتر الأستاذ
  // ============================================================

  Widget _buildLedgerCard() {
    final totalFiltered =
        _allFilteredWithoutPageLimit
            .length;

    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(24),

        boxShadow: [
          BoxShadow(
            color:
                Colors.blue.withOpacity(
              0.04,
            ),
            blurRadius: 10,
            offset:
                const Offset(0, 4),
          ),
        ],

        border: Border.all(
          color:
              const Color(0xFFE2E8F0),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      '📖 دفتر الأستاذ العام المحلي',
                      style:
                          TextStyle(
                        color:
                            Color(0xFF1E293B),
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    SizedBox(
                      height: 3,
                    ),

                    Text(
                      'السجل المركزي لجميع القيود المحاسبية المرتبطة بالعمليات.',
                      style:
                          TextStyle(
                        color:
                            Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFEFF6FF,
                  ),

                  borderRadius:
                      BorderRadius
                          .circular(
                    8,
                  ),

                  border:
                      Border.all(
                    color:
                        const Color(
                      0xFFBFDBFE,
                    ),
                  ),
                ),

                child: Text(
                  '$totalFiltered قيد',
                  style:
                      const TextStyle(
                    color:
                        Color(0xFF1E40AF),
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 16,
          ),

          if (_filteredEntries.isEmpty)
            _buildEmptyState()
          else
            _buildLedgerTable(),
        ],
      ),
    );
  }

  // ============================================================
  // جدول الأستاذ
  // ============================================================

  Widget _buildLedgerTable() {
    final balances =
        _calculateRunningBalances();

    final balanceMap =
        _buildEntryBalanceMap(
      _allFilteredWithoutPageLimit,
    );

    return Container(
      constraints:
          const BoxConstraints(
        maxHeight: 500,
      ),

      decoration:
          BoxDecoration(
        color:
            const Color(0xFFF8FAFC),

        borderRadius:
            BorderRadius.circular(12),

        border: Border.all(
          color:
              const Color(0xFFE2E8F0),
        ),
      ),

      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(12),

        child: SingleChildScrollView(
          scrollDirection:
              Axis.horizontal,

          child:
              SingleChildScrollView(
            child: DataTable(
              headingRowColor:
                  WidgetStateProperty.all(
                const Color(
                  0xFFEFF6FF,
                ),
              ),

              dataRowMinHeight:
                  46,

              dataRowMaxHeight:
                  70,

              horizontalMargin:
                  12,

              columnSpacing:
                  22,

              columns: const [
                DataColumn(
                  label: Text(
                    'المرجع',
                    style: TextStyle(
                      color:
                          Color(0xFF475569),
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),

                DataColumn(
                  label: Text(
                    'التاريخ',
                    style: TextStyle(
                      color:
                          Color(0xFF475569),
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),

                DataColumn(
                  label: Text(
                    'نوع العملية',
                    style: TextStyle(
                      color:
                          Color(0xFF475569),
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),

                DataColumn(
                  label: Text(
                    'الحساب',
                    style: TextStyle(
                      color:
                          Color(0xFF475569),
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),

                DataColumn(
                  numeric: true,
                  label: Text(
                    'مدين',
                    style: TextStyle(
                      color:
                          Color(0xFF16A34A),
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),

                DataColumn(
                  numeric: true,
                  label: Text(
                    'دائن',
                    style: TextStyle(
                      color:
                          Color(0xFFDC2626),
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),

                DataColumn(
                  numeric: true,
                  label: Text(
                    'الرصيد',
                    style: TextStyle(
                      color:
                          Color(0xFF2563EB),
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),

                DataColumn(
                  label: Text(
                    'الحالة',
                    style: TextStyle(
                      color:
                          Color(0xFF475569),
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),

                DataColumn(
                  label: Text(
                    'البيان',
                    style: TextStyle(
                      color:
                          Color(0xFF475569),
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],

              rows:
                  _filteredEntries.map(
                (entry) {
                  final balance =
                      balances[
                              entry.id] ??
                          0.0;

                  final movement =
                      _roundMoney(
                    _safeAmount(
                          entry.debit,
                        ) -
                        _safeAmount(
                          entry.credit,
                        ),
                  );

                  final opType =
                      entry.entryType ??
                          'حركة عامة';

                  final balanced =
                      _isReferenceBalanced(
                    entry,
                    balanceMap,
                  );

                  return DataRow(
                    color: !balanced
                        ? WidgetStateProperty
                            .all(
                            const Color(
                              0xFFFFF7F7,
                            ),
                          )
                        : null,

                    cells: [
                      DataCell(
                        InkWell(
                          onTap: () =>
                              _showEntryDetails(
                            entry,
                          ),

                          child: Text(
                            entry.referenceNo ??
                                '-',

                            style:
                                const TextStyle(
                              color:
                                  Color(
                                0xFF2563EB,
                              ),
                              fontWeight:
                                  FontWeight
                                      .bold,
                              fontFamily:
                                  'monospace',
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),

                      DataCell(
                        Text(
                          _formatDate(
                            entry.date,
                          ),
                          style:
                              const TextStyle(
                            color:
                                Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                      ),

                      DataCell(
                        _operationBadge(
                          opType,
                        ),
                      ),

                      DataCell(
                        SizedBox(
                          width: 150,

                          child: Text(
                            entry.accountName ??
                                '-',

                            maxLines: 2,

                            overflow:
                                TextOverflow
                                    .ellipsis,

                            style:
                                const TextStyle(
                              color:
                                  Color(
                                0xFF1E293B,
                              ),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),

                      DataCell(
                        Text(
                          _safeAmount(
                                    entry.debit,
                                  ) >
                                  0
                              ? _safeAmount(
                                  entry.debit,
                                ).toStringAsFixed(
                                  2,
                                )
                              : '-',

                          style:
                              const TextStyle(
                            color:
                                Color(
                              0xFF16A34A,
                            ),
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),

                      DataCell(
                        Text(
                          _safeAmount(
                                    entry.credit,
                                  ) >
                                  0
                              ? _safeAmount(
                                  entry.credit,
                                ).toStringAsFixed(
                                  2,
                                )
                              : '-',

                          style:
                              const TextStyle(
                            color:
                                Color(
                              0xFFDC2626,
                            ),
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),

                      DataCell(
                        Text(
                          _isSingleAccount
                              ? balance
                                  .toStringAsFixed(
                                  2,
                                )
                              : movement
                                  .toStringAsFixed(
                                  2,
                                ),

                          style:
                              TextStyle(
                            color:
                                _isSingleAccount
                                    ? (balance >=
                                            0
                                        ? const Color(
                                            0xFF2563EB,
                                          )
                                        : const Color(
                                            0xFFDC2626,
                                          ))
                                    : (movement >=
                                            0
                                        ? const Color(
                                            0xFF2563EB,
                                          )
                                        : const Color(
                                            0xFFDC2626,
                                          )),

                            fontWeight:
                                FontWeight.bold,

                            fontSize: 11,
                          ),
                        ),
                      ),

                      DataCell(
                        _entryStatusBadge(
                          entry,
                          balanceMap,
                        ),
                      ),

                      DataCell(
                        SizedBox(
                          width: 260,

                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            mainAxisAlignment:
                                MainAxisAlignment
                                    .center,

                            children: [
                              Text(
                                entry.description ??
                                    '---',

                                maxLines: 2,

                                overflow:
                                    TextOverflow
                                        .ellipsis,

                                style:
                                    const TextStyle(
                                  color:
                                      Colors.grey,
                                  fontSize: 10,
                                ),
                              ),

                              if (entry.partyName !=
                                      null &&
                                  entry.partyName!
                                      .trim()
                                      .isNotEmpty)
                                Text(
                                  'الطرف: ${entry.partyName}',

                                  maxLines: 1,

                                  overflow:
                                      TextOverflow
                                          .ellipsis,

                                  style:
                                      const TextStyle(
                                    color:
                                        Color(
                                      0xFF64748B,
                                    ),
                                    fontSize: 9,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // تنسيق التاريخ
  // ============================================================

  String _formatDate(String? value) {
    if (value == null ||
        value.trim().isEmpty) {
      return '-';
    }

    final date =
        DateTime.tryParse(
      value.trim(),
    );

    if (date == null) {
      return value;
    }

    final day =
        date.day.toString().padLeft(
              2,
              '0',
            );

    final month =
        date.month.toString().padLeft(
              2,
              '0',
            );

    final year =
        date.year.toString();

    final hour =
        date.hour.toString().padLeft(
              2,
              '0',
            );

    final minute =
        date.minute.toString().padLeft(
              2,
              '0',
            );

    return '$year/$month/$day $hour:$minute';
  }

  // ============================================================
  // لا توجد بيانات
  // ============================================================

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(40),

      child: const Column(
        children: [
          Icon(
            Icons
                .account_balance_wallet_outlined,
            color: Colors.grey,
            size: 45,
          ),

          SizedBox(
            height: 10,
          ),

          Text(
            'لا توجد قيود مالية مطابقة',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          SizedBox(
            height: 5,
          ),

          Text(
            'قم بإضافة مبيعات أو مشتريات أو مصروفات أو سندات لتظهر القيود هنا.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // الملخص
  // ============================================================

  Widget _buildSummary() {
    final balance =
        _isSingleAccount
            ? _accountBalance
            : _netMovement;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                'إجمالي المدين',
                '${_totalDebit.toStringAsFixed(2)} ر.ي',
                const Color(
                  0xFF16A34A,
                ),
              ),
            ),

            const SizedBox(
              width: 8,
            ),

            Expanded(
              child: _summaryCard(
                'إجمالي الدائن',
                '${_totalCredit.toStringAsFixed(2)} ر.ي',
                const Color(
                  0xFFDC2626,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 8,
        ),

        Container(
          width: double.infinity,

          padding:
              const EdgeInsets.all(14),

          decoration:
              BoxDecoration(
            color: Colors.white,

            borderRadius:
                BorderRadius.circular(
              12,
            ),

            boxShadow: [
              BoxShadow(
                color:
                    Colors.blue
                        .withOpacity(
                  0.04,
                ),
                blurRadius: 10,
                offset:
                    const Offset(0, 4),
              ),
            ],

            border: Border.all(
              color:
                  const Color(
                0xFFE2E8F0,
              ),
            ),
          ),

          child: Column(
            children: [
              Text(
                _isSingleAccount
                    ? 'الرصيد النهائي للحساب: $_selectedAccount'
                    : 'صافي الحركة لجميع القيود المعروضة',

                textAlign:
                    TextAlign.center,

                style:
                    const TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                ),
              ),

              const SizedBox(
                height: 5,
              ),

              Text(
                '${balance.toStringAsFixed(2)} ر.ي',

                style:
                    TextStyle(
                  color: balance >= 0
                      ? const Color(
                          0xFF2563EB,
                        )
                      : const Color(
                          0xFFDC2626,
                        ),

                  fontWeight:
                      FontWeight.bold,

                  fontSize: 16,
                ),
              ),

              if (_isSingleAccount) ...[
                const SizedBox(
                  height: 5,
                ),

                Text(
                  _accountBalanceSide,

                  style:
                      TextStyle(
                    color:
                        _accountBalanceSide ==
                                'متزن'
                            ? const Color(
                                0xFF16A34A,
                              )
                            : (_accountBalanceSide ==
                                    'مدين'
                                ? const Color(
                                    0xFF16A34A,
                                  )
                                : const Color(
                                    0xFFDC2626,
                                  )),

                    fontSize: 9,

                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // زر
  // ============================================================

  Widget _actionButton(
    String text,
    Color color,
    VoidCallback? onPressed, {
    bool isSecondary = false,
  }) {
    return SizedBox(
      height: 36,

      child: ElevatedButton(
        onPressed: onPressed,

        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              isSecondary
                  ? const Color(
                      0xFFF1F5F9,
                    )
                  : color.withOpacity(
                      0.10,
                    ),

          foregroundColor:
              isSecondary
                  ? const Color(
                      0xFF1E293B,
                    )
                  : color,

          elevation: 0,

          padding:
              const EdgeInsets
                  .symmetric(
            horizontal: 10,
          ),

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              8,
            ),

            side: BorderSide(
              color: isSecondary
                  ? const Color(
                      0xFFCBD5E1,
                    )
                  : color.withOpacity(
                      0.30,
                    ),
            ),
          ),
        ),

        child: Text(
          text,
          style:
              const TextStyle(
            fontSize: 10,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // بطاقة الملخص
  // ============================================================

  Widget _summaryCard(
    String title,
    String value,
    Color textColor,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(12),

      decoration:
          BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(12),

        boxShadow: [
          BoxShadow(
            color:
                Colors.blue.withOpacity(
              0.04,
            ),
            blurRadius: 10,
            offset:
                const Offset(0, 4),
          ),
        ],

        border: Border.all(
          color:
              const Color(0xFFE2E8F0),
        ),
      ),

      child: Column(
        children: [
          Text(
            title,
            style:
                const TextStyle(
              color: Colors.grey,
              fontSize: 9,
            ),
          ),

          const SizedBox(
            height: 3,
          ),

          Text(
            value,
            textAlign:
                TextAlign.center,

            style:
                TextStyle(
              color: textColor,
              fontWeight:
                  FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // نوع العملية
  // ============================================================

  Widget _operationBadge(
    String type,
  ) {
    Color color;

    switch (type.trim()) {
      case 'مبيعات':
      case 'بيع':
        color =
            const Color(0xFF16A34A);
        break;

      case 'مشتريات':
      case 'شراء':
        color =
            const Color(0xFF2563EB);
        break;

      case 'مصروفات':
      case 'مصروف':
        color =
            const Color(0xFFD97706);
        break;

      case 'سند قبض':
      case 'قبض':
        color =
            const Color(0xFF0284C7);
        break;

      case 'سند دفع':
      case 'سند صرف':
      case 'صرف':
      case 'دفع':
        color =
            const Color(0xFFDC2626);
        break;

      case 'رصيد افتتاحي':
        color =
            const Color(0xFF7C3AED);
        break;

      default:
        color = Colors.grey;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),

      decoration:
          BoxDecoration(
        color:
            color.withOpacity(0.10),

        borderRadius:
            BorderRadius.circular(6),

        border: Border.all(
          color:
              color.withOpacity(0.25),
        ),
      ),

      child: Text(
        type,
        style:
            TextStyle(
          color: color,
          fontSize: 10,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // حقل الفلتر
  // ============================================================

  Widget _buildFilterField(
    String label,
    Widget child,
  ) {
    return Container(
      height: 54,

      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 2,
      ),

      decoration:
          BoxDecoration(
        color:
            const Color(0xFFF8FAFC),

        borderRadius:
            BorderRadius.circular(10),

        border: Border.all(
          color:
              const Color(0xFFE2E8F0),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [
          Text(
            label,

            style:
                const TextStyle(
              color: Colors.grey,
              fontSize: 9,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          Expanded(
            child: Center(
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // اختيار عدد القيود
  // ============================================================

  Widget _smallDropdownContainer(
    String label,
    List<int> items,
    int selectedValue,
    Function(int) onChanged,
  ) {
    return Container(
      height: 36,

      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
      ),

      decoration:
          BoxDecoration(
        color:
            const Color(0xFFF8FAFC),

        borderRadius:
            BorderRadius.circular(8),

        border: Border.all(
          color:
              const Color(0xFFE2E8F0),
        ),
      ),

      child: Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          Text(
            label,
            style:
                const TextStyle(
              color: Colors.grey,
              fontSize: 10,
            ),
          ),

          const SizedBox(
            width: 4,
          ),

          DropdownButton<int>(
            value: selectedValue,

            dropdownColor:
                Colors.white,

            style:
                const TextStyle(
              color:
                  Color(0xFF1E293B),
              fontSize: 10,
            ),

            underline:
                const SizedBox(),

            items: items
                .map(
                  (value) =>
                      DropdownMenuItem<
                          int>(
                    value: value,
                    child:
                        Text(
                      '$value قيد',
                    ),
                  ),
                )
                .toList(),

            onChanged: (value) {
              if (value != null) {
                onChanged(value);
              }
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // اختيار الترتيب
  // ============================================================

  Widget _smallOrderDropdown(
    String label,
    String selectedValue,
    Function(String) onChanged,
  ) {
    return Container(
      height: 36,

      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
      ),

      decoration:
          BoxDecoration(
        color:
            const Color(0xFFF8FAFC),

        borderRadius:
            BorderRadius.circular(8),

        border: Border.all(
          color:
              const Color(0xFFE2E8F0),
        ),
      ),

      child: Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          Text(
            label,
            style:
                const TextStyle(
              color: Colors.grey,
              fontSize: 10,
            ),
          ),

          const SizedBox(
            width: 4,
          ),

          DropdownButton<String>(
            value: selectedValue,

            dropdownColor:
                Colors.white,

            style:
                const TextStyle(
              color:
                  Color(0xFF1E293B),
              fontSize: 10,
            ),

            underline:
                const SizedBox(),

            items: const [
              DropdownMenuItem(
                value: 'DESC',
                child:
                    Text('الأحدث ↓'),
              ),
              DropdownMenuItem(
                value: 'ASC',
                child:
                    Text('الأقدم ↑'),
              ),
            ],

            onChanged: (value) {
              if (value != null) {
                onChanged(value);
              }
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // رسالة
  // ============================================================

  void _showMessage(
    String message,
    Color color,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign:
              TextAlign.right,
        ),

        backgroundColor: color,

        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }
}