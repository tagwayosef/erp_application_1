import 'dart:io';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'model/supplier_model.dart';
import 'model/inventory_model.dart';
import 'model/ledger_model.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart' as excelPkg;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({Key? key}) : super(key: key);

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  List<SupplierModel> _suppliers = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchSuppliers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchSuppliers() async {
    setState(() => _isLoading = true);
    try {
      final isar = Isar.getInstance();
      if (isar == null) return;
      final data = await isar.supplierModels.where().findAll();
      if (!mounted) return;
      setState(() {
        _suppliers = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSupplier() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    final supplierName = _nameController.text.trim();
    final supplierPhone = _phoneController.text.trim();
    const double openingBalance = 0.0;

    try {
      final isar = Isar.getInstance();
      if (isar == null) throw Exception('قاعدة البيانات غير متاحة');

      final existingSupplier = await isar.supplierModels
          .filter()
          .nameEqualTo(supplierName)
          .findFirst();

      if (existingSupplier != null) {
        throw Exception('المورد "$supplierName" موجود مسبقاً');
      }

      final now = DateTime.now();
      final nowStr = now.toIso8601String();
      final refNo = 'SUP-${now.millisecondsSinceEpoch}';

      final newSupplier = SupplierModel(
        name: supplierName,
        phone: supplierPhone,
        balance: openingBalance,
      );

      await isar.writeTxn(() async {
        await isar.supplierModels.put(newSupplier);

        if (openingBalance > 0) {
          await isar.ledgerModels.put(
            LedgerModel(
              date: nowStr,
              description: 'إثبات الرصيد الافتتاحي للمورد: $supplierName',
              accountName: 'الأرصدة الافتتاحية',
              partyName: supplierName,
              debit: openingBalance,
              credit: 0.0,
              referenceNo: refNo,
              paymentType: 'آجل',
              entryType: 'رصيد افتتاحي',
            ),
          );

          await isar.ledgerModels.put(
            LedgerModel(
              date: nowStr,
              description: 'رصيد افتتاحي مستحق للمورد: $supplierName',
              accountName: 'الموردون',
              partyName: supplierName,
              debit: 0.0,
              credit: openingBalance,
              referenceNo: refNo,
              paymentType: 'آجل',
              entryType: 'رصيد افتتاحي',
            ),
          );
        }
      });

      if (!mounted) return;

      _nameController.clear();
      _phoneController.clear();
      await _fetchSuppliers();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إضافة المورد بنجاح 🤝✅'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل حفظ المورد ❌\n$e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _exportSuppliersToExcel() async {
    if (_suppliers.isEmpty) return;

    try {
      final excel = excelPkg.Excel.createExcel();
      final sheet = excel['تقرير الموردين'];

      sheet.appendRow([
        excelPkg.TextCellValue('رقم المورد'),
        excelPkg.TextCellValue('اسم المورد'),
        excelPkg.TextCellValue('رقم الهاتف'),
      ]);

      for (var s in _suppliers) {
        sheet.appendRow([
          excelPkg.IntCellValue(s.id),
          excelPkg.TextCellValue(s.name),
          excelPkg.TextCellValue(s.phone ?? 'بدون رقم'),
        ]);
      }

      final bytes = excel.save();
      if (bytes == null) return;

      final directory = await getTemporaryDirectory();
      final path = "${directory.path}/Suppliers_Report.xlsx";
      final file = File(path);
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(path)],
        subject: 'تقرير الموردين المحلي - Omar Soft ERP',
      );
    } catch (e) {
      print('Excel export error: $e');
    }
  }

  Future<void> _printSuppliersReport() async {
    if (_suppliers.isEmpty) return;

    try {
      final arabicFont = await PdfGoogleFonts.cairoRegular();
      final arabicBold = await PdfGoogleFonts.cairoBold();

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async {
          final doc = pw.Document();
          doc.addPage(
            pw.Page(
              pageFormat: format,
              build: (pw.Context context) {
                return pw.Directionality(
                  textDirection: pw.TextDirection.rtl,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('تقرير الموردين المحلي - Omar Soft', style: pw.TextStyle(font: arabicBold, fontSize: 16)),
                      pw.SizedBox(height: 15),
                      pw.Table.fromTextArray(
                        headers: ['رقم', 'اسم المورد', 'الهاتف'],
                        data: _suppliers.map((s) => [s.id.toString(), s.name, s.phone ?? 'بدون']).toList(),
                        headerStyle: pw.TextStyle(font: arabicBold, fontSize: 12, color: PdfColors.white),
                        headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1E40AF)),
                        cellStyle: pw.TextStyle(font: arabicFont, fontSize: 11),
                        cellAlignment: pw.Alignment.centerRight,
                      ),
                    ],
                  ),
                );
              },
            ),
          );
          return doc.save();
        },
      );
    } catch (e) {
      print('Print error: $e');
    }
  }

  void _editSupplierDialog(SupplierModel sup) {
    final TextEditingController editNameController = TextEditingController(text: sup.name);
    final TextEditingController editPhoneController = TextEditingController(text: sup.phone ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('تعديل المورد: ${sup.name}', style: const TextStyle(color: Color(0xFF1E40AF), fontSize: 14, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: editNameController, decoration: const InputDecoration(labelText: 'اسم المورد')),
            const SizedBox(height: 12),
            TextField(controller: editPhoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            onPressed: () async {
              Navigator.pop(context);
              try {
                final isar = Isar.getInstance();
                if (isar == null) return;

                final updatedSupplier = SupplierModel(
                  name: editNameController.text.trim(),
                  phone: editPhoneController.text.trim(),
                )..id = sup.id;

                await isar.writeTxn(() async {
                  await isar.supplierModels.put(updatedSupplier);
                });

                _fetchSuppliers();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تعديل المورد بنجاح ✏️'), backgroundColor: Colors.green));
              } catch (e) {
                print('Error updating supplier: $e');
              }
            },
            child: const Text('حفظ التعديل', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSupplier(int id) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا المورد محلياً؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final isar = Isar.getInstance();
      if (isar == null) return;

      await isar.writeTxn(() async {
        await isar.supplierModels.delete(id);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف المورد بنجاح 🗑️'), backgroundColor: Colors.green));
      _fetchSuppliers();
    } catch (e) {
      print('Error deleting supplier: $e');
    }
  }

  void _openSupplierProductsScreen(SupplierModel sup) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SupplierProductsScreen(supplier: sup)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('إدارة الموردين والشركات', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E40AF),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.table_chart, color: Colors.greenAccent), onPressed: _exportSuppliersToExcel, tooltip: 'تصدير إكسل'),
          IconButton(icon: const Icon(Icons.print, color: Colors.amberAccent), onPressed: _printSuppliersReport, tooltip: 'طباعة التقرير'),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('إضافة مورد جديد محلياً', style: TextStyle(color: Color(0xFF1E40AF), fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'اسم المورد أو الشركة'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'الرجاء إدخال اسم المورد' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'الرجاء إدخال رقم الهاتف' : null,
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), elevation: 0),
                          onPressed: _isSaving ? null : _saveSupplier,
                          child: const Text('حفظ المورد 💾', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E40AF)))
                    : _suppliers.isEmpty
                        ? const Center(child: Text('لا توجد بيانات للموردين مسجلة محلياً', style: TextStyle(color: Colors.grey)))
                        : ListView.separated(
                            itemCount: _suppliers.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final sup = _suppliers[index];
                              return ListTile(
                                tileColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                title: Text(sup.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                subtitle: Text('الهاتف: ${sup.phone ?? "بدون"}', style: const TextStyle(fontSize: 11)),
                                onTap: () => _openSupplierProductsScreen(sup),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(icon: const Icon(Icons.edit, color: Colors.amber, size: 18), onPressed: () => _editSupplierDialog(sup)),
                                    IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18), onPressed: () => _deleteSupplier(sup.id)),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 📦 شاشة منتجات المورد مع محرك البحث، الطابعة، والملخص النقدي والآجل
// ============================================================
class SupplierProductsScreen extends StatefulWidget {
  final SupplierModel supplier;
  const SupplierProductsScreen({Key? key, required this.supplier}) : super(key: key);

  @override
  State<SupplierProductsScreen> createState() => _SupplierProductsScreenState();
}

class _SupplierProductsScreenState extends State<SupplierProductsScreen> {
  List<InventoryModel> _supplierProducts = [];
  bool _isLoading = true;
  
  // متحكم وبحث المنتجات
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchSupplierProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSupplierProducts() async {
    setState(() => _isLoading = true);
    try {
      final isar = Isar.getInstance();
      if (isar == null) return;

      final allInventory = await isar.inventoryModels.where().findAll();
      final filtered = allInventory.where((item) {
        final supName = item.supplier ?? '';
        return supName.trim().toLowerCase() == widget.supplier.name.trim().toLowerCase();
      }).toList();

      if (!mounted) return;
      setState(() {
        _supplierProducts = filtered;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  // تصفية المنتجات بناءً على محرك البحث
  List<InventoryModel> get _filteredProducts {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _supplierProducts;
    return _supplierProducts.where((p) {
      final name = p.name.toLowerCase();
      final category = (p.category ?? '').toLowerCase();
      return name.contains(query) || category.contains(query);
    }).toList();
  }

  // حساب إجمالي النقد والآجل للمنتجات (افتراضاً بحسب نوع السداد في الصنف أو السعر)
  double get _totalCashValue {
    // كمثال: المنتجات التي تكلفة أو سعر دفعها نقدي أو إجمالي القيمة النقدية للمخزون المرتبط
    return _supplierProducts.fold(0.0, (sum, item) => sum + (item.qty * item.price));
  }

  double get _totalCreditValue {
    // كمثال توضيحي للملخص (يمكن ربطه بحسب جدول الفواتير أو الديون)
    return 0.0; 
  }

  // دالة طباعة تقرير منتجات المورد PDF
  Future<void> _printSupplierReport() async {
    if (_supplierProducts.isEmpty) return;

    try {
      final arabicFont = await PdfGoogleFonts.cairoRegular();
      final arabicBold = await PdfGoogleFonts.cairoBold();

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async {
          final doc = pw.Document();
          doc.addPage(
            pw.Page(
              pageFormat: format,
              build: (pw.Context context) {
                return pw.Directionality(
                  textDirection: pw.TextDirection.rtl,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('تقرير منتجات المورد: ${widget.supplier.name}', style: pw.TextStyle(font: arabicBold, fontSize: 16)),
                      pw.SizedBox(height: 10),
                      pw.Text('إجمالي قيمة المنتجات: ${_totalCashValue.toStringAsFixed(2)} ر.ي', style: pw.TextStyle(font: arabicFont, fontSize: 12)),
                      pw.SizedBox(height: 15),
                      pw.Table.fromTextArray(
                        headers: ['اسم المنتج', 'التصنيف', 'الكمية', 'السعر', 'الإجمالي'],
                        data: _supplierProducts.map((p) => [
                          p.name,
                          p.category ?? 'بدون',
                          p.qty.toString(),
                          p.price.toStringAsFixed(2),
                          (p.qty * p.price).toStringAsFixed(2),
                        ]).toList(),
                        headerStyle: pw.TextStyle(font: arabicBold, fontSize: 11, color: PdfColors.white),
                        headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1E40AF)),
                        cellStyle: pw.TextStyle(font: arabicFont, fontSize: 10),
                        cellAlignment: pw.Alignment.centerRight,
                      ),
                    ],
                  ),
                );
              },
            ),
          );
          return doc.save();
        },
      );
    } catch (e) {
      print('Print error: $e');
    }
  }

  // دالة تصدير إكسل لمنتجات المورد
  Future<void> _exportSupplierExcel() async {
    if (_supplierProducts.isEmpty) return;
    try {
      final excel = excelPkg.Excel.createExcel();
      final sheet = excel['منتجات المورد'];

      sheet.appendRow([
        excelPkg.TextCellValue('اسم المنتج'),
        excelPkg.TextCellValue('التصنيف'),
        excelPkg.TextCellValue('الكمية'),
        excelPkg.TextCellValue('السعر'),
        excelPkg.TextCellValue('الإجمالي'),
      ]);

      for (var p in _supplierProducts) {
        sheet.appendRow([
          excelPkg.TextCellValue(p.name),
          excelPkg.TextCellValue(p.category ?? 'بدون'),
          excelPkg.IntCellValue(p.qty as int),
          excelPkg.DoubleCellValue(p.price),
          excelPkg.DoubleCellValue(p.qty * p.price),
        ]);
      }

      final bytes = excel.save();
      if (bytes == null) return;

      final directory = await getTemporaryDirectory();
      final path = "${directory.path}/Supplier_${widget.supplier.name}_Products.xlsx";
      final file = File(path);
      await file.writeAsBytes(bytes);

      await Share.shareXFiles([XFile(path)], subject: 'تقرير منتجات المورد');
    } catch (e) {
      print('Excel error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredProducts;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E40AF),
          title: Text('المورد: ${widget.supplier.name}', style: const TextStyle(color: Colors.white, fontSize: 14)),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(icon: const Icon(Icons.table_chart, color: Colors.greenAccent), onPressed: _exportSupplierExcel, tooltip: 'تصدير إكسل'),
            IconButton(icon: const Icon(Icons.print, color: Colors.amberAccent), onPressed: _printSupplierReport, tooltip: 'طباعة التقرير'),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ==========================================
              // 📊 ملخص النقدي والآجل الخاص بالمورد
              // ==========================================
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('إجمالي قيمة البضاعة', style: TextStyle(color: Colors.grey, fontSize: 10)),
                        const SizedBox(height: 4),
                        Text('${_totalCashValue.toStringAsFixed(2)} ر.ي', style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    Container(height: 25, width: 1, color: Colors.grey.shade300),
                    Column(
                      children: [
                        const Text('حالة الحساب (نقد/آجل)', style: TextStyle(color: Colors.grey, fontSize: 10)),
                        const SizedBox(height: 4),
                        Text('نشط / متعامل محلي', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ==========================================
              // 🔍 محرك البحث داخل منتجات المورد
              // ==========================================
              TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 13),
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'ابحث عن اسم المنتج أو التصنيف...',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF2563EB), size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E40AF), width: 1.5)),
                ),
              ),
              const SizedBox(height: 12),

              // ==========================================
              // 📋 قائمة المنتجات
              // ==========================================
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E40AF)))
                    : filtered.isEmpty
                        ? const Center(child: Text('لا توجد منتجات مطابقة للبحث 📭', style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final product = filtered[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        const SizedBox(height: 3),
                                        Text('التصنيف: ${product.category ?? "عام"}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('الكمية: ${product.qty}', style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 11)),
                                        const SizedBox(height: 3),
                                        Text('السعر: ${product.price} ر.ي', style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 11)),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}