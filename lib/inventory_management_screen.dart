import 'dart:io';

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'model/inventory_model.dart';
import 'model/supplier_model.dart';
import 'model/ledger_model.dart';
import 'barcode_scanner_screen.dart';

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({Key? key}) : super(key: key);

  @override
  State<InventoryManagementScreen> createState() =>
      _InventoryManagementScreenState();
}

class _InventoryManagementScreenState
    extends State<InventoryManagementScreen> {
  List<InventoryModel> inventoryList = [];
  List<InventoryModel> filteredList = [];
  List<SupplierModel> suppliersList = [];

  bool isLoading = true;
  bool isSaving = false;

  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController barcodeController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController qtyController = TextEditingController();
  final TextEditingController costController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController minController =
      TextEditingController(text: '5');

  String? selectedSupplier;
  String selectedPurchaseType = 'نقدي';

  final List<String> categoryShortcuts = const [
    'إلكترونيات',
    'ملابس',
    'غذائيات',
    'إكسسوارات',
    'أدوات',
    'خدمات طباعة وإعلان',
  ];

  @override
  void initState() {
    super.initState();
    categoryController.text = 'إلكترونيات';
    _loadInitialData();
  }

  @override
  void dispose() {
    searchController.dispose();
    nameController.dispose();
    barcodeController.dispose();
    categoryController.dispose();
    qtyController.dispose();
    costController.dispose();
    priceController.dispose();
    minController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (mounted) setState(() => isLoading = true);

    await Future.wait([
      fetchInventory(),
      fetchSuppliers(),
    ]);

    if (mounted) setState(() => isLoading = false);
  }

  Future<Isar> _getIsar() async {
    final Isar? isar = Isar.getInstance();
    if (isar == null) {
      throw Exception('قاعدة البيانات Isar غير مهيأة');
    }
    return isar;
  }

  Future<void> fetchInventory() async {
    try {
      final Isar? isar = Isar.getInstance();
      if (isar == null) return;

      final List<InventoryModel> data =
          await isar.inventoryModels.where().findAll();

      if (!mounted) return;

      setState(() {
        inventoryList = data;
        filteredList = _filterInventory(data, searchController.text);
      });
    } catch (e) {
      debugPrint('Error fetching inventory: $e');
    }
  }

  Future<void> fetchSuppliers() async {
    try {
      final Isar? isar = Isar.getInstance();
      if (isar == null) return;

      final List<SupplierModel> data =
          await isar.supplierModels.where().findAll();

      if (!mounted) return;

      setState(() {
        suppliersList = data;
        if (data.isEmpty) {
          selectedSupplier = 'عام';
        } else {
          final bool currentExists = data.any((s) => s.name == selectedSupplier);
          if (!currentExists || selectedSupplier == null) {
            selectedSupplier = data.first.name;
          }
        }
      });
    } catch (e) {
      debugPrint('Error fetching suppliers: $e');
    }
  }

  List<InventoryModel> _filterInventory(
    List<InventoryModel> source,
    String term,
  ) {
    final String query = term.trim().toLowerCase();
    if (query.isEmpty) {
      return List<InventoryModel>.from(source);
    }

    return source.where((p) {
      final String name = p.name.toLowerCase();
      final String category = (p.category ?? '').toLowerCase();
      final String barcode = (p.barcode ?? '').toLowerCase();

      return name.contains(query) ||
          category.contains(query) ||
          barcode.contains(query);
    }).toList();
  }

  void searchInventory(String term) {
    if (!mounted) return;
    setState(() {
      filteredList = _filterInventory(inventoryList, term);
    });
  }

  // 🛡️ طريقة آمنة تماماً لتنظيف وتعيين النصوص لتجنب RangeError في Windows
  void _safeClear(TextEditingController controller, {String defText = ''}) {
    controller.value = TextEditingValue(
      text: defText,
      selection: TextSelection.collapsed(offset: defText.length),
    );
  }

  void _resetFormSafely() {
    FocusManager.instance.primaryFocus?.unfocus();

    _safeClear(nameController);
    _safeClear(barcodeController);
    _safeClear(qtyController);
    _safeClear(costController);
    _safeClear(priceController);
    _safeClear(categoryController, defText: 'إلكترونيات');
    _safeClear(minController, defText: '5');

    if (mounted) {
      setState(() {
        selectedPurchaseType = 'نقدي';
        if (suppliersList.isNotEmpty) {
          selectedSupplier = suppliersList.first.name;
        } else {
          selectedSupplier = 'عام';
        }
      });
    }
  }

  Future<void> exportToExcel() async {
    if (inventoryList.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد بيانات لتصديرها ⚠️'), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      final StringBuffer csv = StringBuffer();
      csv.writeln('\ufeffاسم المنتج,الباركود,التصنيف,الكمية,سعر التكلفة,سعر البيع,المورد,نوع التعامل');

      for (final p in inventoryList) {
        csv.writeln(
          '${_csv(p.name)},'
          '${_csv(p.barcode ?? '')},'
          '${_csv(p.category ?? 'عام')},'
          '${p.qty},'
          '${p.cost},'
          '${p.price},'
          '${_csv(p.supplier ?? 'عام')},'
          '${_csv(p.purchaseType ?? 'نقدي')}',
        );
      }

      final Directory directory = await getTemporaryDirectory();
      final String path = '${directory.path}/Inventory_Report.csv';
      final File file = File(path);

      await file.writeAsString(csv.toString(), flush: true);
      await Share.shareXFiles([XFile(path)], subject: 'تقرير المخزون - Omar Soft ERP');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء تصدير الملف:\n$e'), backgroundColor: Colors.red),
      );
    }
  }

  String _csv(String value) {
    final String escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  // 🚀 حفظ صنف جديد وترحيل القيود لدفتر الأستاذ العام
  Future<void> submitNewProduct() async {
    if (isSaving) return;

    FocusManager.instance.primaryFocus?.unfocus();

    if (!formKey.currentState!.validate()) {
      return;
    }

    final String productName = nameController.text.trim();
    final String barcode = barcodeController.text.trim();
    final String category = categoryController.text.trim().isEmpty ? 'عام' : categoryController.text.trim();

    final double? qty = double.tryParse(qtyController.text.trim());
    final double? cost = double.tryParse(costController.text.trim());
    final double? price = double.tryParse(priceController.text.trim());
    final double? minQty = double.tryParse(minController.text.trim());

    if (productName.isEmpty) {
      _showError('اسم المنتج مطلوب');
      return;
    }

    if (qty == null || !qty.isFinite || qty <= 0) {
      _showError('كمية الشراء يجب أن تكون أكبر من صفر');
      return;
    }

    if (cost == null || !cost.isFinite || cost < 0) {
      _showError('سعر التكلفة غير صحيح');
      return;
    }

    if (price == null || !price.isFinite || price < 0) {
      _showError('سعر البيع غير صحيح');
      return;
    }

    if (minQty == null || !minQty.isFinite || minQty < 0) {
      _showError('حد الطلب غير صحيح');
      return;
    }

    final String purchaseType = selectedPurchaseType;
    final String supplierName = (selectedSupplier ?? '').trim().isEmpty ? 'عام' : selectedSupplier!.trim();
    final bool isCredit = purchaseType == 'آجل';

    if (isCredit && supplierName == 'عام') {
      _showError('لا يمكن تسجيل شراء آجل بدون تحديد مورد');
      return;
    }

    final double totalCost = qty * cost;
    final DateTime now = DateTime.now();
    final String refNo = 'PUR-${now.millisecondsSinceEpoch}';
    final String currentDate = now.toIso8601String();

    setState(() => isSaving = true);

    try {
      final Isar isar = await _getIsar();

      await isar.writeTxn(() async {
        SupplierModel? supplier;
        int? foundSupplierId;

        if (supplierName != 'عام') {
          final List<SupplierModel> suppliers = await isar.supplierModels.where().findAll();
          for (final s in suppliers) {
            if (s.name.trim().toLowerCase() == supplierName.trim().toLowerCase()) {
              supplier = s;
              foundSupplierId = s.id;
              break;
            }
          }

          if (supplier == null) {
            throw Exception('المورد "$supplierName" غير موجود');
          }
        }

        final List<InventoryModel> allInventory = await isar.inventoryModels.where().findAll();
        InventoryModel? existingProduct;

        if (barcode.isNotEmpty) {
          for (final item in allInventory) {
            final String itemBarcode = item.barcode?.trim() ?? '';
            if (itemBarcode.isNotEmpty && itemBarcode == barcode) {
              existingProduct = item;
              break;
            }
          }
        }

        if (existingProduct == null && barcode.isEmpty) {
          for (final item in allInventory) {
            final String itemName = item.name.trim().toLowerCase();
            final String itemCategory = (item.category ?? 'عام').trim().toLowerCase();

            if (itemName == productName.toLowerCase() && itemCategory == category.toLowerCase()) {
              existingProduct = item;
              break;
            }
          }
        }

        if (existingProduct != null) {
          final double oldQty = existingProduct.qty < 0 ? 0 : existingProduct.qty;
          final double oldCost = existingProduct.cost < 0 ? 0 : existingProduct.cost;
          final double newQty = oldQty + qty;
          final double weightedCost = newQty > 0 ? ((oldQty * oldCost) + (qty * cost)) / newQty : cost;

          existingProduct.qty = newQty;
          existingProduct.cost = weightedCost;
          if (price > 0) existingProduct.price = price;
          existingProduct.min = minQty;
          existingProduct.supplier = supplierName;
          existingProduct.supplierId = foundSupplierId;
          existingProduct.purchaseType = purchaseType;
          existingProduct.referenceNo = refNo;

          await isar.inventoryModels.put(existingProduct);
        } else {
          final InventoryModel newProduct = InventoryModel(
            name: productName,
            barcode: barcode.isEmpty ? null : barcode,
            category: category,
            qty: qty,
            cost: cost,
            price: price,
            min: minQty,
            supplier: supplierName,
            supplierId: foundSupplierId,
            purchaseType: purchaseType,
            referenceNo: refNo,
          );

          await isar.inventoryModels.put(newProduct);
        }

        if (isCredit) {
          supplier!.balance += totalCost;
          await isar.supplierModels.put(supplier);
        }

        final String description = isCredit
            ? 'مشتريات آجلة ($productName) من المورد $supplierName'
            : 'مشتريات نقدية ($productName)';

        final LedgerModel inventoryEntry = LedgerModel(
          date: currentDate,
          description: description,
          accountName: 'المخزون',
          partyName: supplierName,
          debit: totalCost,
          credit: 0.0,
          referenceNo: refNo,
          paymentType: purchaseType,
          entryType: 'مشتريات',
        );

        final LedgerModel counterEntry = LedgerModel(
          date: currentDate,
          description: description,
          accountName: isCredit ? 'الموردون' : 'الصندوق الرئيسي',
          partyName: supplierName,
          debit: 0.0,
          credit: totalCost,
          referenceNo: refNo,
          paymentType: purchaseType,
          entryType: 'مشتريات',
        );

        await isar.ledgerModels.putAll([inventoryEntry, counterEntry]);
      });

      await fetchInventory();
      await fetchSuppliers();

      if (!mounted) return;
      _resetFormSafely();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تسجيل الشراء وترحيله إلى دفتر الأستاذ بنجاح ✅\nالمرجع: $refNo'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تسجيل الشراء ❌\n$e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> editProductDialog(InventoryModel product) async {
    final TextEditingController editName = TextEditingController(text: product.name);
    final TextEditingController editBarcode = TextEditingController(text: product.barcode ?? '');
    final TextEditingController editCategory = TextEditingController(text: product.category ?? 'عام');
    final TextEditingController editQty = TextEditingController(text: product.qty.toString());
    final TextEditingController editCost = TextEditingController(text: product.cost.toString());
    final TextEditingController editPrice = TextEditingController(text: product.price.toString());
    final TextEditingController editMin = TextEditingController(text: product.min.toString());

    String supplierValue = product.supplier ?? 'عام';
    String purchaseType = product.purchaseType ?? 'نقدي';

    final List<String> supplierNames = suppliersList
        .map((s) => s.name)
        .where((name) => name.trim().isNotEmpty)
        .toSet()
        .toList();

    if (supplierNames.isEmpty) {
      supplierValue = 'عام';
    } else if (!supplierNames.contains(supplierValue)) {
      supplierValue = supplierNames.first;
    }

    if (purchaseType != 'نقدي' && purchaseType != 'آجل') {
      purchaseType = 'نقدي';
    }

    bool saving = false;

    try {
      await showDialog(
        context: context,
        barrierDismissible: !saving,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: Colors.white,
                title: const Text(
                  'تعديل الصنف',
                  style: TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.bold, fontSize: 16),
                ),
                content: SizedBox(
                  width: MediaQuery.of(context).size.width > 600 ? 600 : double.maxFinite,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _editField('اسم المنتج / الخدمة', editName, enabled: !saving),
                        _editField('الباركود', editBarcode, enabled: !saving),
                        _editField('التصنيف', editCategory, enabled: !saving),
                        _editField('الكمية', editQty, enabled: !saving, number: true),
                        _editField('سعر الشراء / التكلفة', editCost, enabled: !saving, number: true),
                        _editField('سعر البيع', editPrice, enabled: !saving, number: true),
                        _editField('حد الطلب Min', editMin, enabled: !saving, number: true),
                        const SizedBox(height: 8),
                        Align(alignment: Alignment.centerRight, child: _buildLabel('المورد المسؤول')),
                        DropdownButtonFormField<String>(
                          value: supplierNames.contains(supplierValue) ? supplierValue : (supplierNames.isNotEmpty ? supplierNames.first : 'عام'),
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          decoration: _inputDecoration('المورد'),
                          items: supplierNames.isEmpty
                              ? const [DropdownMenuItem(value: 'عام', child: Text('عام'))]
                              : supplierNames.map((name) => DropdownMenuItem(value: name, child: Text(name, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: saving ? null : (value) {
                            if (value == null) return;
                            setDialogState(() => supplierValue = value);
                          },
                        ),
                        const SizedBox(height: 12),
                        Align(alignment: Alignment.centerRight, child: _buildLabel('نوع التعامل')),
                        DropdownButtonFormField<String>(
                          value: purchaseType,
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          decoration: _inputDecoration('نوع التعامل'),
                          items: const [
                            DropdownMenuItem(value: 'نقدي', child: Text('💵 نقدي')),
                            DropdownMenuItem(value: 'آجل', child: Text('⏳ آجل - ذمم الموردين')),
                          ],
                          onChanged: saving ? null : (value) {
                            if (value == null) return;
                            setDialogState(() => purchaseType = value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: saving ? null : () => Navigator.pop(dialogContext),
                    child: const Text('إلغاء'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                    onPressed: saving ? null : () async {
                      final String newName = editName.text.trim();
                      final String newBarcode = editBarcode.text.trim();
                      final String newCategory = editCategory.text.trim();
                      final double? newQty = double.tryParse(editQty.text.trim());
                      final double? newCost = double.tryParse(editCost.text.trim());
                      final double? newPrice = double.tryParse(editPrice.text.trim());
                      final double? newMin = double.tryParse(editMin.text.trim());

                      if (newName.isEmpty) { _showError('اسم المنتج مطلوب'); return; }
                      if (newQty == null || !newQty.isFinite || newQty < 0) { _showError('الكمية غير صحيحة'); return; }
                      if (newCost == null || !newCost.isFinite || newCost < 0) { _showError('سعر الشراء غير صحيح'); return; }
                      if (newPrice == null || !newPrice.isFinite || newPrice < 0) { _showError('سعر البيع غير صحيح'); return; }
                      if (newMin == null || !newMin.isFinite || newMin < 0) { _showError('حد الطلب غير صحيح'); return; }

                      final String newSupplier = supplierValue.trim().isEmpty ? 'عام' : supplierValue.trim();
                      if (purchaseType == 'آجل' && newSupplier == 'عام') { _showError('الشراء الآجل يحتاج إلى مورد'); return; }

                      setDialogState(() => saving = true);

                      try {
                        final Isar isar = await _getIsar();
                        final String oldRef = product.referenceNo?.trim() ?? '';
                        final String refNo = oldRef.isNotEmpty ? oldRef : 'PUR-${DateTime.now().millisecondsSinceEpoch}';
                        final String date = DateTime.now().toIso8601String();
                        final bool newIsCredit = purchaseType == 'آجل';
                        final double newTotal = newQty * newCost;

                        await isar.writeTxn(() async {
                          final InventoryModel? current = await isar.inventoryModels.get(product.id);
                          if (current == null) throw Exception('الصنف غير موجود');

                          if (oldRef.isNotEmpty) {
                            final oldEntries = await isar.ledgerModels.filter().referenceNoEqualTo(oldRef).findAll();
                            for (final entry in oldEntries) {
                              await isar.ledgerModels.delete(entry.id);
                            }
                          }

                          SupplierModel? newSupplierModel;
                          int? foundNewSupId;
                          if (newSupplier != 'عام') {
                            final List<SupplierModel> suppliers = await isar.supplierModels.where().findAll();
                            for (final s in suppliers) {
                              if (s.name.trim().toLowerCase() == newSupplier.toLowerCase()) {
                                newSupplierModel = s;
                                foundNewSupId = s.id;
                                break;
                              }
                            }
                            if (newSupplierModel == null) throw Exception('المورد الجديد غير موجود');
                          }

                          current.name = newName;
                          current.barcode = newBarcode.isEmpty ? null : newBarcode;
                          current.category = newCategory.isEmpty ? null : newCategory;
                          current.qty = newQty;
                          current.cost = newCost;
                          current.price = newPrice;
                          current.min = newMin;
                          current.supplier = newSupplier;
                          current.supplierId = foundNewSupId;
                          current.purchaseType = purchaseType;
                          current.referenceNo = refNo;

                          await isar.inventoryModels.put(current);

                          if (newIsCredit && newSupplierModel != null) {
                            newSupplierModel.balance += newTotal;
                            await isar.supplierModels.put(newSupplierModel);
                          }

                          final String description = newIsCredit
                              ? 'تعديل مشتريات آجلة - $newName - المورد $newSupplier'
                              : 'تعديل مشتريات نقدية - $newName';

                          final LedgerModel inventoryEntry = LedgerModel(
                            date: date,
                            description: description,
                            accountName: 'المخزون',
                            partyName: newSupplier,
                            debit: newTotal,
                            credit: 0,
                            referenceNo: refNo,
                            paymentType: purchaseType,
                            entryType: 'مشتريات',
                          );

                          final LedgerModel counterEntry = LedgerModel(
                            date: date,
                            description: description,
                            accountName: newIsCredit ? 'الموردون' : 'الصندوق الرئيسي',
                            partyName: newSupplier,
                            debit: 0,
                            credit: newTotal,
                            referenceNo: refNo,
                            paymentType: purchaseType,
                            entryType: 'مشتريات',
                          );

                          await isar.ledgerModels.putAll([inventoryEntry, counterEntry]);
                        });

                        if (!mounted) return;
                        Navigator.pop(dialogContext);

                        await fetchInventory();
                        await fetchSuppliers();

                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم تعديل الصنف وتحديث دفتر الأستاذ بنجاح ✅'), backgroundColor: Colors.green),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        setDialogState(() => saving = false);
                        _showError('فشل تعديل الصنف:\n$e');
                      }
                    },
                    child: saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('حفظ التعديل', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      editName.dispose();
      editBarcode.dispose();
      editCategory.dispose();
      editQty.dispose();
      editCost.dispose();
      editPrice.dispose();
      editMin.dispose();
    }
  }

  Future<void> deleteProduct(int id) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('تأكيد الحذف', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('هل تريد حذف هذا الصنف?\n\nسيتم حذف الصنف والقيود المحاسبية المرتبطة به.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('نعم، حذف'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final Isar isar = await _getIsar();

      await isar.writeTxn(() async {
        final InventoryModel? product = await isar.inventoryModels.get(id);
        if (product == null) throw Exception('الصنف غير موجود');

        final String refNo = product.referenceNo?.trim() ?? '';
        List<LedgerModel> entries = [];

        if (refNo.isNotEmpty) {
          entries = await isar.ledgerModels.filter().referenceNoEqualTo(refNo).findAll();
        }

        double oldAmount = 0;
        for (final entry in entries) {
          oldAmount += entry.debit;
        }

        if (product.purchaseType == 'آجل' &&
            product.supplier != null &&
            product.supplier!.trim().isNotEmpty &&
            product.supplier!.trim() != 'عام') {
          final List<SupplierModel> suppliers = await isar.supplierModels.where().findAll();
          SupplierModel? supplier;

          for (final s in suppliers) {
            if (s.name.trim().toLowerCase() == product.supplier!.trim().toLowerCase()) {
              supplier = s;
              break;
            }
          }

          if (supplier != null) {
            supplier.balance -= oldAmount;
            if (supplier.balance.abs() < 0.0001) {
              supplier.balance = 0;
            }
            await isar.supplierModels.put(supplier);
          }
        }

        for (final entry in entries) {
          await isar.ledgerModels.delete(entry.id);
        }

        await isar.inventoryModels.delete(id);
      });

      await fetchInventory();
      await fetchSuppliers();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف الصنف والقيود المرتبطة به بنجاح 🗑️✅'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل حذف الصنف:\n$e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _editField(
    String label,
    TextEditingController controller, {
    bool enabled = true,
    bool number = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(label),
          TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: number
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            decoration: _inputDecoration(label),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, right: 2),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 11),
      filled: true,
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
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E40AF),
          elevation: 0,
          title: const Text(
            'إدارة المخزون - مرتبط بدفتر الأستاذ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF1E40AF),
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final double width = constraints.maxWidth;
                  final bool isMobile = width < 700;
                  final double padding = isMobile ? 12 : 24;

                  return SingleChildScrollView(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildFormCard(isMobile),
                        const SizedBox(height: 24),
                        _buildInventoryCard(isMobile),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildFormCard(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      decoration: _cardDecoration(),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                SizedBox(
                  width: 6,
                  height: 20,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xFF2563EB),
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '➕ تسجيل بيانات صنف جديد وترحيله للأستاذ',
                    style: TextStyle(
                      color: Color(0xFF1E40AF),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLabel('اسم المنتج / الخدمة'),
            TextFormField(
              controller: nameController,
              textInputAction: TextInputAction.next,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 13,
              ),
              decoration: _inputDecoration('مثلاً: منتج، خدمة...'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'حقل مطلوب';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildLabel('الباركود (Barcode)'),
            _buildBarcodeField(isMobile),
            const SizedBox(height: 12),
            _buildLabel('التصنيف'),
            TextFormField(
              controller: categoryController,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 13,
              ),
              decoration: _inputDecoration('اكتب التصنيف هنا...'),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: categoryShortcuts.map((cat) {
                return ActionChip(
                  label: Text(
                    cat,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF1E40AF),
                    ),
                  ),
                  backgroundColor: const Color(0xFFEFF6FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onPressed: () {
                    _setControllerTextSafely(categoryController, cat);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            _buildResponsiveRow(
              isMobile: isMobile,
              first: _numberField(
                'الكمية',
                qtyController,
                '0',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'مطلوب';
                  }
                  return null;
                },
              ),
              second: _numberField(
                'سعر الشراء / التكلفة',
                costController,
                '0.00',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'مطلوب';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 12),
            _buildResponsiveRow(
              isMobile: isMobile,
              first: _priceField(),
              second: _supplierField(),
            ),
            const SizedBox(height: 12),
            _buildResponsiveRow(
              isMobile: isMobile,
              first: _purchaseTypeField(),
              second: _numberField(
                'حد الطلب (Min)',
                minController,
                '5',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving ? null : submitNewProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  disabledBackgroundColor: Colors.blueGrey,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'حفظ وترحيل القيود للأستاذ ✅',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarcodeField(bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: barcodeController,
            textInputAction: TextInputAction.done,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 13,
            ),
            decoration: _inputDecoration('امسح الباركود أو اكتبه هنا...'),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              FocusManager.instance.primaryFocus?.unfocus();

              final dynamic scannedCode = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BarcodeScannerScreen(),
                ),
              );

              if (scannedCode != null && mounted) {
                _setControllerTextSafely(
                  barcodeController,
                  scannedCode.toString(),
                );
              }
            },
            child: const Icon(
              Icons.camera_alt,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _numberField(
    String label,
    TextEditingController controller,
    String hint, {
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 13,
          ),
          decoration: _inputDecoration(hint),
          validator: validator,
        ),
      ],
    );
  }

  Widget _priceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('سعر البيع'),
        TextFormField(
          controller: priceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(
            color: Color(0xFF16A34A),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          decoration: _inputDecoration('0.00'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'مطلوب';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _supplierField() {
    final List<String> names = suppliersList
        .map((s) => s.name)
        .where((name) => name.trim().isNotEmpty)
        .toSet()
        .toList();

    String value = selectedSupplier ?? 'عام';

    if (names.isNotEmpty && !names.contains(value)) {
      value = names.first;
    }

    if (names.isEmpty) {
      value = 'عام';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('المورد المسؤول'),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          dropdownColor: Colors.white,
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 13,
          ),
          decoration: _inputDecoration(''),
          items: names.isEmpty
              ? const [
                  DropdownMenuItem(value: 'عام', child: Text('عام')),
                ]
              : names
                  .map(
                    (name) => DropdownMenuItem<String>(
                      value: name,
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
          onChanged: isSaving
              ? null
              : (val) {
                  if (val == null) return;
                  setState(() {
                    selectedSupplier = val;
                  });
                },
        ),
      ],
    );
  }

  Widget _purchaseTypeField() {
    final String safeValue =
        selectedPurchaseType == 'آجل' ? 'آجل' : 'نقدي';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('نوع التعامل'),
        DropdownButtonFormField<String>(
          value: safeValue,
          isExpanded: true,
          dropdownColor: Colors.white,
          style: const TextStyle(
            color: Color(0xFF2563EB),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          decoration: _inputDecoration(''),
          items: const [
            DropdownMenuItem(value: 'نقدي', child: Text('💵 نقدي')),
            DropdownMenuItem(value: 'آجل', child: Text('⏳ آجل (ذمم الموردين)')),
          ],
          onChanged: isSaving
              ? null
              : (val) {
                  if (val == null) return;
                  setState(() {
                    selectedPurchaseType = val;
                  });
                },
        ),
      ],
    );
  }

  Widget _buildResponsiveRow({
    required bool isMobile,
    required Widget first,
    required Widget second,
  }) {
    if (isMobile) {
      return Column(
        children: [
          first,
          const SizedBox(height: 12),
          second,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: first),
        const SizedBox(width: 12),
        Expanded(child: second),
      ],
    );
  }

  Widget _buildInventoryCard(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSearchHeader(isMobile),
          const SizedBox(height: 16),
          if (filteredList.isEmpty)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Center(
                child: Text(
                  'لا توجد أصناف مطابقة محلياً',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
            )
          else
            _buildDataTable(),
        ],
      ),
    );
  }

  Widget _buildSearchHeader(bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: searchController,
            onChanged: searchInventory,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 13,
            ),
            decoration: _searchDecoration(),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: exportToExcel,
            icon: const Text('📑'),
            label: const Text(
              'تقرير المخزون',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: searchController,
            onChanged: searchInventory,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 13,
            ),
            decoration: _searchDecoration(),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: exportToExcel,
          icon: const Text('📑'),
          label: const Text(
            'تقرير المخزون',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF16A34A),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  InputDecoration _searchDecoration() {
    return InputDecoration(
      hintText: 'ابحث بالاسم، الفئة أو الباركود...',
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
      prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
      filled: true,
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
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
    );
  }

  Widget _buildDataTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
          const Color(0xFFEFF6FF),
        ),
        columnSpacing: 24,
        columns: const [
          DataColumn(label: Text('اسم الصنف / الخدمة', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('الباركود', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('الفئة', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('الكمية', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('سعر التكلفة', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('سعر البيع', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('الربح المتوقع', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('المورد', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('نوع التعامل', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('الإجراءات', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
        ],
        rows: filteredList.map((p) {
          final bool lowStock = p.qty <= p.min;
          final double expectedProfit = (p.price - p.cost) * p.qty;
          final bool credit = p.purchaseType == 'آجل';

          return DataRow(
            cells: [
              DataCell(Text(p.name, style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 12))),
              DataCell(Text(p.barcode ?? '-', style: const TextStyle(color: Colors.blueGrey, fontSize: 12))),
              DataCell(Text(p.category ?? 'عام', style: const TextStyle(color: Colors.grey, fontSize: 12))),
              DataCell(Text(_formatNumber(p.qty), style: TextStyle(color: lowStock ? Colors.red : const Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 12))),
              DataCell(Text('${p.cost.toStringAsFixed(0)} ر.ي', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12))),
              DataCell(Text('${p.price.toStringAsFixed(0)} ر.ي', style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 12))),
              DataCell(Text('${expectedProfit.toStringAsFixed(0)} ر.ي', style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12))),
              DataCell(Text(p.supplier ?? 'عام', style: const TextStyle(color: Colors.grey, fontSize: 12))),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: credit ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    credit ? '⏳ آجل' : '💵 نقدي',
                    style: TextStyle(
                      color: credit ? Colors.orange[800] : Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => editProductDialog(p),
                      icon: const Icon(Icons.edit, color: Colors.amber, size: 18),
                      tooltip: 'تعديل',
                    ),
                    IconButton(
                      onPressed: () => deleteProduct(p.id),
                      icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                      tooltip: 'حذف',
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _setControllerTextSafely(
    TextEditingController controller,
    String text,
  ) {
    FocusManager.instance.primaryFocus?.unfocus();
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
      composing: TextRange.empty,
    );
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.blue.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      border: Border.all(color: const Color(0xFFE2E8F0)),
    );
  }
}