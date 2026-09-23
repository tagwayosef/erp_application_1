import 'dart:io';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'model/inventory_model.dart';
import 'model/sale_model.dart';
import 'model/ledger_model.dart'; // تم استيراد نموذج دفتر الأستاذ لضمان توليد القيد الآلي
import 'barcode_scanner_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart' as excelPkg;
import 'package:intl/intl.dart' as intl;
import 'model/sales_return_model.dart';
import 'Services/api_service.dart';
import 'model/ledger_model.dart';
class SalesScreen extends StatefulWidget {
  const SalesScreen({Key? key}) : super(key: key);

  @override
  _SalesScreenState createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  List<SaleModel> sessionSalesLog = [];
  List<SaleModel> filteredSalesLog = [];
  List<InventoryModel> inventoryList = [];
  final List<Map<String, dynamic>> currentInvoiceItems = [];
  
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cashierController = TextEditingController(text: 'الكاشير العام');
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _searchSalesController = TextEditingController();
  final FocusNode _barcodeFocusNode = FocusNode();

  String _paymentType = 'نقدي';
  double netTotal = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _customerController.dispose();
    _phoneController.dispose();
    _cashierController.dispose();
    _barcodeController.dispose();
    _searchSalesController.dispose();
    _barcodeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);
    await Future.wait([
      fetchInventory(),
      fetchSalesHistory(),
    ]);
  }
// ============================================================
// 🗑️ حذف الفاتورة + حذف قيودها من دفتر الأستاذ
// ============================================================
Future<void> deleteSale(SaleModel sale) async {
  final String refNo = sale.invoiceNo?.trim() ?? '';

  if (refNo.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('رقم الفاتورة غير موجود'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text(
          'هل تريد حذف الفاتورة $refNo؟\n\n'
          'سيتم إعادة الكميات المتبقية للمخزون وحذف جميع قيودها من دفتر الأستاذ.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      );
    },
  );

  if (confirmed != true) return;

  try {
    final Isar? isar = Isar.getInstance();
    if (isar == null) {
      throw Exception('قاعدة البيانات غير متاحة');
    }

    await isar.writeTxn(() async {
      final SaleModel? currentSale = await isar.saleModels.get(sale.id);
      if (currentSale == null) {
        throw Exception('الفاتورة غير موجودة');
      }

      // 1. جلب المرتجعات السابقة لهذه الفاتورة لمعرفة كم تم استرجاعه فعلياً
      final returns = await isar.salesReturnModels.where().findAll();
      final invoiceReturns = returns.where((r) => (r.invoiceNo ?? '').trim() == refNo).toList();

      final Map<String, double> alreadyReturnedMap = {};
      for (final salesReturn in invoiceReturns) {
        for (final item in salesReturn.items) {
          final key = item.barcode?.trim().isNotEmpty == true
              ? 'B:${item.barcode!.trim()}'
              : 'N:${item.productName?.trim() ?? ''}';
          alreadyReturnedMap[key] = (alreadyReturnedMap[key] ?? 0) + item.qty;
        }
      }

      // 2. إرجاع الكميات المتبقية فقط (المباع ناقص ما تم استرجاعه مسبقاً) إلى المخزون
      for (final soldItem in currentSale.items) {
        final key = soldItem.barcode?.trim().isNotEmpty == true
            ? 'B:${soldItem.barcode!.trim()}'
            : 'N:${soldItem.productName?.trim() ?? ''}';
        
        final double returnedQty = alreadyReturnedMap[key] ?? 0.0;
        final double netQtyToRestore = soldItem.qty - returnedQty; // الكمية التي لم تُسترْجَع بعد

        if (netQtyToRestore > 0) {
          InventoryModel? product;
          final String barcode = soldItem.barcode?.trim() ?? '';
          final String productName = soldItem.productName?.trim() ?? '';

          if (barcode.isNotEmpty) {
            product = await isar.inventoryModels.filter().barcodeEqualTo(barcode).findFirst();
          }
          product ??= await isar.inventoryModels.filter().nameEqualTo(productName).findFirst();

          if (product != null) {
            product.qty += netQtyToRestore; // إرجاع المتبقي فقط للمخزون
            await isar.inventoryModels.put(product);
          }
        }
      }

      // 3. حذف قيود المبيعات وقيود المرتجعات المرتبطة بهذه الفاتورة من دفتر الأستاذ
      final List<LedgerModel> ledgerEntries = await isar.ledgerModels
          .filter()
          .referenceNoEqualTo(refNo)
          .findAll();

      for (final ledger in ledgerEntries) {
        await isar.ledgerModels.delete(ledger.id);
      }

      // 4. حذف مستندات المرتجعات الخاصة بهذه الفاتورة وقيودها من دفتر الأستاذ
      for (final salesReturn in invoiceReturns) {
        // البحث عن أي قيود أستاذ مسجلة برقم المرجع الخاص بالمرتجع (مثل RET-...) وحذفها
       // final String returnRef = salesReturn.invoiceNo?.trim() ?? ''; 
       final String returnRef = salesReturn.returnReference?.trim() ?? '';
        if (returnRef.isNotEmpty) {
          final List<LedgerModel> returnLedgers = await isar.ledgerModels
              .filter()
              .referenceNoEqualTo(returnRef)
              .findAll();
              
          for (final rLedger in returnLedgers) {
            await isar.ledgerModels.delete(rLedger.id);
          }
        }

        // حذف سند المرتجع نفسه
        await isar.salesReturnModels.delete(salesReturn.id);
      }
      // 5. حذف الفاتورة نفسها
      final bool deleted = await isar.saleModels.delete(currentSale.id);
      if (!deleted) {
        throw Exception('تعذر حذف الفاتورة');
      }
    });

    if (!mounted) return;

    await fetchInventory();
    await fetchSalesHistory();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم حذف الفاتورة $refNo وتسوية المخزون والأستاذ بنجاح 🗑️✅'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('فشل حذف الفاتورة:\n$e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
  Future<void> fetchInventory() async {
    try {
      final isar = Isar.getInstance();
      if (isar == null) return;
      final data = await isar.inventoryModels.where().findAll();
      if (!mounted) return;
      setState(() {
        inventoryList = data;
      });
    } catch (e) {
      print('Error fetching inventory: $e');
    }
  }
Future<void> returnSaleDialog(SaleModel sale) async {
  final invoiceNo = sale.invoiceNo?.trim() ?? '';
  if (invoiceNo.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('رقم الفاتورة غير موجود'), backgroundColor: Colors.red),
    );
    return;
  }

  final isar = Isar.getInstance();
  if (isar == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('قاعدة البيانات غير متاحة'), backgroundColor: Colors.red),
    );
    return;
  }

  final returns = await isar.salesReturnModels.where().findAll();
  final invoiceReturns = returns.where((r) => (r.invoiceNo ?? '').trim() == invoiceNo).toList();

  final Map<String, double> returnedMap = {};
  for (final salesReturn in invoiceReturns) {
    for (final item in salesReturn.items) {
      final key = item.barcode?.trim().isNotEmpty == true
          ? 'B:${item.barcode!.trim()}'
          : 'N:${item.productName?.trim() ?? ''}';
      returnedMap[key] = (returnedMap[key] ?? 0) + item.qty;
    }
  }

  final List<SaleItem> availableItems = [];
  for (final item in sale.items) {
    final key = item.barcode?.trim().isNotEmpty == true
        ? 'B:${item.barcode!.trim()}'
        : 'N:${item.productName?.trim() ?? ''}';
    final returned = returnedMap[key] ?? 0.0;
    final remaining = item.qty - returned;
    if (remaining > 0) {
      availableItems.add(
        SaleItem(
          productName: item.productName,
          barcode: item.barcode,
          price: item.price,
          qty: remaining,
        ),
      );
    }
  }

  if (availableItems.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('هذه الفاتورة تم استرجاع جميع كمياتها مسبقًا ✅'), backgroundColor: Colors.orange),
    );
    return;
  }

  final Map<String, double> returnQty = {};
  for (final item in availableItems) {
    final key = item.barcode?.trim().isNotEmpty == true
        ? 'B:${item.barcode!.trim()}'
        : 'N:${item.productName?.trim() ?? ''}';
    returnQty[key] = 0.0;
  }

  final TextEditingController reasonController = TextEditingController();

  await showDialog(
    context: context,
    builder: (dialogContext) {
      bool isSaving = false;
      return StatefulBuilder(
        builder: (context, setDialogState) {
          double totalReturn = 0.0;
          for (final item in availableItems) {
            final key = item.barcode?.trim().isNotEmpty == true
                ? 'B:${item.barcode!.trim()}'
                : 'N:${item.productName?.trim() ?? ''}';
            totalReturn += (returnQty[key] ?? 0) * item.price;
          }

          return AlertDialog(
            backgroundColor: Colors.white,
            title: Text(
              '↩️ استرجاع من الفاتورة $invoiceNo',
              style: const TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.bold, fontSize: 15),
            ),
            content: SizedBox(
              width: 650,
              height: 500,
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      'العميل: ${sale.customerName ?? 'عميل نقدي'}\nرقم الفاتورة: $invoiceNo',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: availableItems.length,
                      itemBuilder: (context, index) {
                        final item = availableItems[index];
                        final key = item.barcode?.trim().isNotEmpty == true
                            ? 'B:${item.barcode!.trim()}'
                            : 'N:${item.productName?.trim() ?? ''}';
                        final maxQty = item.qty;
                        final selectedQty = returnQty[key] ?? 0.0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.productName ?? 'بدون اسم', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    Text('المباع: ${item.qty.toStringAsFixed(2)}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                    Text('المتبقي للاسترجاع: ${maxQty.toStringAsFixed(2)}', style: const TextStyle(fontSize: 10, color: Colors.blue)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.orange),
                                onPressed: selectedQty <= 0
                                    ? null
                                    : () => setDialogState(() => returnQty[key] = selectedQty - 1),
                              ),
                              SizedBox(
                                width: 55,
                                child: Text(
                                  selectedQty.toStringAsFixed(selectedQty == selectedQty.roundToDouble() ? 0 : 2),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                onPressed: selectedQty >= maxQty
                                    ? null
                                    : () => setDialogState(() => returnQty[key] = selectedQty + 1),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${(selectedQty * item.price).toStringAsFixed(2)} ر.ي',
                                style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(labelText: 'سبب الاسترجاع', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('إجمالي المرتجع:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${totalReturn.toStringAsFixed(2)} ر.ي', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                child: const Text('إلغاء'),
              ),
              ElevatedButton.icon(
                icon: isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.assignment_return, color: Colors.white),
                label: Text(isSaving ? 'جاري الاعتماد...' : 'اعتماد الاسترجاع'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700, foregroundColor: Colors.white),
                onPressed: isSaving
                    ? null
                    : () async {
                        if (totalReturn <= 0) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(content: Text('حدد كمية واحدة على الأقل للاسترجاع'), backgroundColor: Colors.orange),
                          );
                          return;
                        }

                        final List<Map<String, dynamic>> returnItems = [];
                        for (final item in availableItems) {
                          final key = item.barcode?.trim().isNotEmpty == true
                              ? 'B:${item.barcode!.trim()}'
                              : 'N:${item.productName?.trim() ?? ''}';
                          final qty = returnQty[key] ?? 0.0;
                          if (qty <= 0) continue;

                          returnItems.add({
                            'productName': item.productName,
                            'barcode': item.barcode,
                            'price': item.price,
                            'qty': qty,
                            'total': qty * item.price,
                          });
                        }

                        if (returnItems.isEmpty) return;

                        setDialogState(() => isSaving = true);

           try {
  // 1. حفظ المرتجع عبر الـ API
  await ApiService().saveSalesReturn({
    'invoiceNo': invoiceNo,
    'customerName': sale.customerName ?? 'عميل نقدي',
    'paymentType': sale.paymentType ?? 'نقدي',
    'date': DateTime.now().toIso8601String(),
    'reason': reasonController.text.trim(),
    'items': returnItems,
  });

  // 2. إذا كانت الفاتورة آجلة، نسجل قيد عكسي في دفتر الأستاذ لتخفيض مديونية العميل
  final String pType = (sale.paymentType ?? 'نقدي').trim().toLowerCase();
  if (pType == 'آجل' || pType == 'اجل' || pType == 'credit') {
    await isar.writeTxn(() async {
      final String currentDate = DateTime.now().toIso8601String();
      
      // قيد تخفيض مديونية العميل (دائن)
      await isar.ledgerModels.put(
        LedgerModel(
          date: currentDate,
          description: 'مرتجع مبيعات آجلة - فاتورة رقم: $invoiceNo',
          accountName: 'العملاء',
          partyName: sale.customerName ?? 'عميل نقدي',
          debit: 0.0,
          credit: totalReturn, // تخفيض رصيد المتبقي على العميل
          referenceNo: invoiceNo,
          paymentType: sale.paymentType ?? 'آجل',
          entryType: 'مرتجع مبيعات',
        ),
      );

      // قيد إثبات مرتجع المبيعات (مدين) لكي يظل القيد متوازناً
      await isar.ledgerModels.put(
        LedgerModel(
          date: currentDate,
          description: 'إثبات مرتجع مبيعات - فاتورة رقم: $invoiceNo',
          accountName: 'مرتجع المبيعات',
          partyName: sale.customerName ?? 'عميل نقدي',
          debit: totalReturn,
          credit: 0.0,
          referenceNo: invoiceNo,
          paymentType: sale.paymentType ?? 'آجل',
          entryType: 'مرتجع مبيعات',
        ),
      );
    });
  }

  if (dialogContext.mounted) {
    Navigator.of(dialogContext).pop();
  }

  await fetchInventory();
  await fetchSalesHistory();

  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('تم اعتماد الاسترجاع وتحديث حسابات العميل والمخزون بنجاح ✅'), backgroundColor: Colors.green),
  );
} catch (e) {
  if (!dialogContext.mounted) return;
  setDialogState(() => isSaving = false);
  ScaffoldMessenger.of(dialogContext).showSnackBar(
    SnackBar(content: Text('فشل اعتماد الاسترجاع:\n$e'), backgroundColor: Colors.red),
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
  reasonController.dispose();
} Future<void> printSaleInvoice(SaleModel sale) async {
    try {
      final invoiceNo = sale.invoiceNo?.trim() ?? '';
      if (invoiceNo.isEmpty) {
        throw Exception('رقم الفاتورة غير موجود');
      }

      final isar = Isar.getInstance();
      if (isar == null) {
        throw Exception('قاعدة البيانات غير متاحة');
      }

      final returns = await isar.salesReturnModels.where().findAll();
      final invoiceReturns = returns.where((r) => (r.invoiceNo ?? '').trim() == invoiceNo).toList();

      final Map<String, double> returnedQtyMap = {};
      for (final salesReturn in invoiceReturns) {
        for (final item in salesReturn.items) {
          final key = item.barcode?.trim().isNotEmpty == true
              ? 'B:${item.barcode!.trim()}'
              : 'N:${item.productName?.trim() ?? ''}';
          returnedQtyMap[key] = (returnedQtyMap[key] ?? 0) + item.qty;
        }
      }

      double totalReturnedAmount = 0.0;
      for (final salesReturn in invoiceReturns) {
        totalReturnedAmount += salesReturn.totalAmount;
      }

      final double netAmount = sale.totalAmount - totalReturnedAmount;
      final arabicFont = await PdfGoogleFonts.cairoRegular();
      final arabicBold = await PdfGoogleFonts.cairoBold();
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('عمر سوفت ERP', style: pw.TextStyle(font: arabicBold, fontSize: 20)),
                  pw.SizedBox(height: 4),
                  pw.Text('فاتورة مبيعات', style: pw.TextStyle(font: arabicBold, fontSize: 16)),
                  pw.Divider(),
                  pw.Text('رقم الفاتورة: $invoiceNo', style: pw.TextStyle(font: arabicFont, fontSize: 11)),
                  pw.Text('العميل: ${sale.customerName ?? 'عميل نقدي'}', style: pw.TextStyle(font: arabicFont, fontSize: 11)),
                  pw.Text('طريقة الدفع: ${sale.paymentType ?? 'نقدي'}', style: pw.TextStyle(font: arabicFont, fontSize: 11)),
                  pw.Text('التاريخ: ${sale.date ?? ''}', style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                  pw.SizedBox(height: 15),
                  pw.Table.fromTextArray(
                    headers: ['الصنف', 'المباع', 'المسترجع', 'الصافي', 'السعر'],
                    data: sale.items.map((item) {
                      final key = item.barcode?.trim().isNotEmpty == true
                          ? 'B:${item.barcode!.trim()}'
                          : 'N:${item.productName?.trim() ?? ''}';
                      final returned = returnedQtyMap[key] ?? 0.0;
                      final remaining = item.qty - returned;
                      return [
                        item.productName ?? '',
                        item.qty.toStringAsFixed(2),
                        returned.toStringAsFixed(2),
                        remaining.toStringAsFixed(2),
                        '${item.price.toStringAsFixed(2)} ر.ي',
                      ];
                    }).toList(),
                    headerStyle: pw.TextStyle(font: arabicBold, fontSize: 10, color: PdfColors.white),
                    headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1E40AF)),
                    cellStyle: pw.TextStyle(font: arabicFont, fontSize: 9),
                    cellAlignment: pw.Alignment.centerRight,
                  ),
                  pw.SizedBox(height: 15),
                  pw.Divider(),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('إجمالي المبيعات:', style: pw.TextStyle(font: arabicBold, fontSize: 12)),
                      pw.Text('${sale.totalAmount.toStringAsFixed(2)} ر.ي', style: pw.TextStyle(font: arabicBold, fontSize: 12)),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('إجمالي المرتجع:', style: pw.TextStyle(font: arabicBold, fontSize: 12)),
                      pw.Text('${totalReturnedAmount.toStringAsFixed(2)} ر.ي', style: pw.TextStyle(font: arabicBold, fontSize: 12)),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('صافي الفاتورة:', style: pw.TextStyle(font: arabicBold, fontSize: 15)),
                      pw.Text('${netAmount.toStringAsFixed(2)} ر.ي', style: pw.TextStyle(font: arabicBold, fontSize: 15)),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );

      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل طباعة الفاتورة:\n$e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> fetchSalesHistory() async {
    try {
      final isar = Isar.getInstance();
      if (isar == null) return;
      final sales = await isar.saleModels.where().findAll();
      if (!mounted) return;
      setState(() {
        sessionSalesLog = sales;
        _filterSalesLog(_searchSalesController.text);
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching sales history: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  void _filterSalesLog(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredSalesLog = List.from(sessionSalesLog);
      } else {
        filteredSalesLog = sessionSalesLog.where((log) {
          final invoiceNo = log.invoiceNo?.toLowerCase() ?? '';
          final customer = log.customerName?.toLowerCase() ?? '';
          final phone = log.itemsDetails.join(' ').toLowerCase(); 
          final searchLower = query.toLowerCase();
          
          return invoiceNo.contains(searchLower) || 
                 customer.contains(searchLower) || 
                 phone.contains(searchLower);
        }).toList();
      }
    });
  }

  void handleBarcodeScanned(String value) {
    final scannedCode = value.trim();
    if (scannedCode.isEmpty) {
      _barcodeFocusNode.requestFocus();
      return;
    }

    InventoryModel? matchedProduct;
    for (final product in inventoryList) {
      if (product.barcode?.trim() == scannedCode) {
        matchedProduct = product;
        break;
      }
    }

    if (matchedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('المنتج غير موجود بالباركود: $scannedCode'), backgroundColor: Colors.orange, duration: const Duration(seconds: 2)),
      );
    } else {
      if (matchedProduct.qty <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${matchedProduct.name} غير متوفر في المخزون ❌'), backgroundColor: Colors.red, duration: const Duration(seconds: 2)),
        );
      } else {
        addItemToInvoice(matchedProduct);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تمت إضافة ${matchedProduct.name} 🛒'), backgroundColor: Colors.green, duration: const Duration(milliseconds: 700)),
        );
      }
    }

    _barcodeController.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _barcodeFocusNode.requestFocus();
    });
  }

  void addItemToInvoice(InventoryModel product) {
    setState(() {
      final existingIndex = currentInvoiceItems.indexWhere((item) => item['id'] == product.id);

      if (existingIndex >= 0) {
        final currentQty = (currentInvoiceItems[existingIndex]['qty'] as num).toDouble();
        if (currentQty + 1 > product.qty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('لا يمكن إضافة كمية أكبر من المتوفر من ${product.name}'), backgroundColor: Colors.orange),
          );
          return;
        }
        currentInvoiceItems[existingIndex]['qty'] = currentQty + 1;
        currentInvoiceItems[existingIndex]['total'] = currentInvoiceItems[existingIndex]['qty'] * currentInvoiceItems[existingIndex]['price'];
      } else {
        if (product.qty <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${product.name} غير متوفر في المخزون'), backgroundColor: Colors.red),
          );
          return;
        }
        currentInvoiceItems.add({
          'id': product.id,
          'name': product.name,
          'category': product.category ?? 'عام',
          'barcode': product.barcode ?? '',
          'qty': 1.0,
          'price': product.price,
          'total': product.price,
        });
      }
      _calculateTotal();
    });
  }

  void cancelCurrentInvoice() {
    if (currentInvoiceItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الفاتورة فارغة أساساً! ⚠️'), backgroundColor: Colors.orange),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('إلغاء الفاتورة', style: TextStyle(color: Color(0xFF1E40AF), fontSize: 14)),
        content: const Text('هل أنت متأكد من إلغاء وتفريغ هذه الفاتورة؟', style: TextStyle(color: Colors.grey, fontSize: 12)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('تراجع', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(dialogContext);
              setState(() {
                currentInvoiceItems.clear();
                netTotal = 0;
                _customerController.clear();
                _phoneController.clear();
                _paymentType = 'نقدي';
              });
            },
            child: const Text('نعم، إلغاء', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openProductSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filteredProducts = inventoryList.where((p) =>
              p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
              (p.category != null && p.category!.toLowerCase().contains(searchQuery.toLowerCase())) ||
              (p.barcode != null && p.barcode!.toLowerCase().contains(searchQuery.toLowerCase()))
            ).toList();

            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('بحث واختيار منتج من المخزون', style: TextStyle(color: Color(0xFF1E40AF), fontSize: 14, fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: 400,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(hintText: 'ابحث باسم المنتج أو الباركود...', prefixIcon: Icon(Icons.search)),
                      onChanged: (val) => setDialogState(() => searchQuery = val),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: filteredProducts.isEmpty
                          ? const Center(child: Text('لا توجد منتجات مطابقة', style: TextStyle(color: Colors.grey)))
                          : ListView.builder(
                              itemCount: filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product = filteredProducts[index];
                                return ListTile(
                                  title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  subtitle: Text('السعر: ${product.price} ر.ي | المتوفر: ${product.qty}', style: const TextStyle(fontSize: 10)),
                                  trailing: ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                                    onPressed: () {
                                      addItemToInvoice(product);
                                      Navigator.pop(context);
                                    },
                                    child: const Text('إضافة', style: TextStyle(color: Colors.white, fontSize: 10)),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق', style: TextStyle(color: Colors.grey))),
              ],
            );
          },
        );
      },
    );
  }

  void _editInvoiceItemDialog(int index) {
    final item = currentInvoiceItems[index];
    final TextEditingController qtyController = TextEditingController(text: item['qty'].toString());
    final TextEditingController priceController = TextEditingController(text: item['price'].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('تعديل الصنف: ${item['name']}', style: const TextStyle(color: Color(0xFF1E40AF), fontSize: 13, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: qtyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الكمية', labelStyle: TextStyle(fontSize: 11))),
            const SizedBox(height: 10),
            TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سعر البيع', labelStyle: TextStyle(fontSize: 11))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            onPressed: () {
              final newQty = double.tryParse(qtyController.text) ?? item['qty'];
              final newPrice = double.tryParse(priceController.text) ?? item['price'];
              setState(() {
                currentInvoiceItems[index]['qty'] = newQty;
                currentInvoiceItems[index]['price'] = newPrice;
                currentInvoiceItems[index]['total'] = newQty * newPrice;
                _calculateTotal();
              });
              Navigator.pop(context);
            },
            child: const Text('حفظ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void removeItemFromInvoice(int index) {
    setState(() {
      currentInvoiceItems.removeAt(index);
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    netTotal = currentInvoiceItems.fold(0, (sum, item) => sum + ((item['total'] as num).toDouble()));
  }

  Future<void> printCurrentInvoice() async {
    if (currentInvoiceItems.isEmpty) return;

    final pdf = pw.Document();
    final customerName = _customerController.text.trim().isEmpty ? 'عميل نقدي' : _customerController.text.trim();
    final phoneNum = _phoneController.text.trim();
    final cashierName = _cashierController.text.trim().isEmpty ? 'الكاشير العام' : _cashierController.text.trim();
    
    final arabicFont = await PdfGoogleFonts.cairoRegular();
    final arabicBold = await PdfGoogleFonts.cairoBold();
    
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('نظام نقاط البيع المحلي - فاتورة مبيعات', style: pw.TextStyle(font: arabicBold, fontSize: 16)),
                    pw.Text('التاريخ: ${DateTime.now().toString().substring(0, 16)}', style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Text('الكاشير: $cashierName', style: pw.TextStyle(font: arabicFont, fontSize: 11)),
                pw.Divider(),
                pw.Text('العميل: $customerName ${phoneNum.isNotEmpty ? " - هاتف: $phoneNum" : ""}', style: pw.TextStyle(font: arabicFont, fontSize: 12)),
                pw.Text('طريقة الدفع: $_paymentType', style: pw.TextStyle(font: arabicFont, fontSize: 12)),
                pw.SizedBox(height: 10),
                pw.Table.fromTextArray(
                  headers: ['الصنف', 'الكمية', 'السعر', 'الإجمالي'],
                  data: currentInvoiceItems.map((item) => [
                    item['name'].toString(),
                    item['qty'].toString(),
                    '${item['price']} ر.ي',
                    '${item['total']} ر.ي',
                  ]).toList(),
                  headerStyle: pw.TextStyle(font: arabicBold, fontSize: 12, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1E40AF)),
                  cellStyle: pw.TextStyle(font: arabicFont, fontSize: 11),
                  cellAlignment: pw.Alignment.centerRight,
                ),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('الإجمالي الكلي:', style: pw.TextStyle(font: arabicBold, fontSize: 14)),
                    pw.Text('${netTotal.toStringAsFixed(2)} ر.ي', style: pw.TextStyle(font: arabicBold, fontSize: 14, color: PdfColor.fromInt(0xFF16A34A))),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  Future<void> saveInvoice() async {
  if (currentInvoiceItems.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('الفاتورة فارغة! أضف أصنافاً أولاً ⚠️'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  try {
    final isar = Isar.getInstance();

    if (isar == null) {
      throw Exception('قاعدة البيانات المحلية غير متاحة');
    }

    // ============================================================
    // 1) البيانات الأساسية
    // ============================================================

    final customerName = _customerController.text.trim().isEmpty
        ? 'عميل نقدي'
        : _customerController.text.trim();

    final paymentType = _paymentType.trim() == 'آجل'
        ? 'آجل'
        : 'نقدي';

    final now = DateTime.now();
    final date = now.toIso8601String();

    final serialNumber =
        'INV-${now.millisecondsSinceEpoch.toString().substring(8)}';

    // ============================================================
    // 2) تجهيز الأصناف + التحقق من المخزون + حساب التكلفة
    // ============================================================

    final List<String> itemsDetailsList = [];

    double totalCostOfGoods = 0;

    // نخزن المنتجات التي سيتم تعديلها حتى لا نكرر البحث
    final List<InventoryModel> productsToUpdate = [];

    for (final item in currentInvoiceItems) {
      final int productId = (item['id'] as num).toInt();

      final double saleQty = (item['qty'] as num).toDouble();
      final double salePrice = (item['price'] as num).toDouble();

      final product = await isar.inventoryModels.get(productId);

      if (product == null) {
        throw Exception(
          'الصنف "${item['name']}" غير موجود في المخزون',
        );
      }

      // ------------------------------------------------------------
      // التحقق من الكمية
      // ------------------------------------------------------------

      if (saleQty <= 0) {
        throw Exception(
          'كمية الصنف "${product.name}" غير صحيحة',
        );
      }

      if (product.qty < saleQty) {
        throw Exception(
          'الكمية غير كافية للصنف "${product.name}"\n'
          'المتوفر: ${product.qty}\n'
          'المطلوب: $saleQty',
        );
      }

      // ------------------------------------------------------------
      // حساب تكلفة البضاعة المباعة
      // ------------------------------------------------------------

      final double itemCost = product.cost * saleQty;

      totalCostOfGoods += itemCost;

      // ------------------------------------------------------------
      // تفاصيل الفاتورة
      // ------------------------------------------------------------

      itemsDetailsList.add(
        '${product.name} '
        '(كمية: $saleQty, '
        'سعر: $salePrice, '
        'التكلفة: ${product.cost})',
      );

      productsToUpdate.add(product);
    }

    // ============================================================
    // 3) التحقق من إجمالي الفاتورة
    // ============================================================

    final double invoiceTotal = netTotal;

    if (invoiceTotal <= 0) {
      throw Exception('إجمالي الفاتورة يجب أن يكون أكبر من صفر');
    }

    if (totalCostOfGoods < 0) {
      throw Exception('تكلفة البضاعة غير صحيحة');
    }

    // ============================================================
    // 4) إنشاء SaleModel
    // ============================================================

    final newSale = SaleModel(
      invoiceNo: serialNumber,
      customerName: customerName,
      totalAmount: invoiceTotal,
      paymentType: paymentType,
      date: date,
      itemsDetails: itemsDetailsList,

      // مهم:
      // إذا كان currentInvoiceItems يحتوي على البيانات المناسبة
      // نحفظها أيضاً داخل items.
      items: currentInvoiceItems.map((item) {
        return SaleItem(
          productName: item['name']?.toString(),
          barcode: item['barcode']?.toString(),
          price: (item['price'] as num?)?.toDouble() ?? 0,
          qty: (item['qty'] as num?)?.toDouble() ?? 0,
        );
      }).toList(),
    );

    // ============================================================
    // 5) تنفيذ العملية كاملة داخل Transaction واحدة
    // ============================================================

    await isar.writeTxn(() async {

      // ==========================================================
      // A) حفظ الفاتورة
      // ==========================================================

      await isar.saleModels.put(newSale);

      // ==========================================================
      // B) خصم الكميات من المخزون
      // ==========================================================

      for (final product in productsToUpdate) {
        final item = currentInvoiceItems.firstWhere(
          (x) => (x['id'] as num).toInt() == product.id,
        );

        final double saleQty =
            (item['qty'] as num).toDouble();

        product.qty -= saleQty;

        // حماية إضافية
        if (product.qty < 0) {
          throw Exception(
            'حدث خطأ في كمية المخزون للصنف "${product.name}"',
          );
        }

        await isar.inventoryModels.put(product);
      }

      // ==========================================================
      // C) قيد المبيعات
      // ==========================================================

      // ----------------------------------------------------------
      // البيع الآجل:
      //
      // العملاء       مدين
      // المبيعات       دائن
      // ----------------------------------------------------------

      if (paymentType == 'آجل') {

        // مدين العملاء
        await isar.ledgerModels.put(
          LedgerModel(
            date: date,
            description:
                'بيع آجل - فاتورة رقم: $serialNumber',
            accountName: 'العملاء',
            partyName: customerName,
            debit: invoiceTotal,
            credit: 0,
            referenceNo: serialNumber,
            paymentType: paymentType,
            entryType: 'مبيعات',
          ),
        );

        // دائن المبيعات
        await isar.ledgerModels.put(
          LedgerModel(
            date: date,
            description:
                'إثبات مبيعات - فاتورة رقم: $serialNumber',
            accountName: 'المبيعات',
            partyName: customerName,
            debit: 0,
            credit: invoiceTotal,
            referenceNo: serialNumber,
            paymentType: paymentType,
            entryType: 'مبيعات',
          ),
        );
      }

      // ==========================================================
      // D) البيع النقدي
      // ==========================================================

      else {

        // مدين الصندوق
        await isar.ledgerModels.put(
          LedgerModel(
            date: date,
            description:
                'بيع نقدي - فاتورة رقم: $serialNumber',
            accountName: 'الصندوق الرئيسي',
            partyName: customerName,
            debit: invoiceTotal,
            credit: 0,
            referenceNo: serialNumber,
            paymentType: paymentType,
            entryType: 'مبيعات',
          ),
        );

        // دائن المبيعات
        await isar.ledgerModels.put(
          LedgerModel(
            date: date,
            description:
                'إثبات مبيعات - فاتورة رقم: $serialNumber',
            accountName: 'المبيعات',
            partyName: customerName,
            debit: 0,
            credit: invoiceTotal,
            referenceNo: serialNumber,
            paymentType: paymentType,
            entryType: 'مبيعات',
          ),
        );
      }

      // ==========================================================
      // E) قيد تكلفة البضاعة المباعة COGS
      // ==========================================================

      if (totalCostOfGoods > 0) {

        // مدين تكلفة المبيعات
        await isar.ledgerModels.put(
          LedgerModel(
            date: date,
            description:
                'تكلفة البضاعة المباعة - فاتورة رقم: $serialNumber',
            accountName: 'تكلفة المبيعات',
            partyName: customerName,
            debit: totalCostOfGoods,
            credit: 0,
            referenceNo: serialNumber,
            paymentType: paymentType,
            entryType: 'تكلفة مبيعات',
          ),
        );

        // دائن المخزون
        await isar.ledgerModels.put(
          LedgerModel(
            date: date,
            description:
                'تخفيض المخزون - فاتورة رقم: $serialNumber',
            accountName: 'المخزون',
            partyName: customerName,
            debit: 0,
            credit: totalCostOfGoods,
            referenceNo: serialNumber,
            paymentType: paymentType,
            entryType: 'تكلفة مبيعات',
          ),
        );
      }

      // ==========================================================
      // F) التحقق النهائي من توازن القيد
      // ==========================================================

      final double salesDebit = invoiceTotal;
      final double salesCredit = invoiceTotal;

      final double costDebit = totalCostOfGoods;
      final double costCredit = totalCostOfGoods;

      final double totalDebit =
          salesDebit + costDebit;

      final double totalCredit =
          salesCredit + costCredit;

      if ((totalDebit - totalCredit).abs() > 0.0001) {
        throw Exception(
          'القيد المحاسبي غير متوازن\n'
          'المدين: $totalDebit\n'
          'الدائن: $totalCredit',
        );
      }
    });

    // ============================================================
    // 6) تحديث الواجهة
    // ============================================================

    if (!mounted) return;

    setState(() {
      currentInvoiceItems.clear();
      netTotal = 0;

      _customerController.clear();
      _phoneController.clear();

      _paymentType = 'نقدي';
    });

    // تحديث المخزون والمبيعات
    await fetchInventory();
    await fetchSalesHistory();

    if (!mounted) return;

    // ============================================================
    // 7) رسالة نجاح
    // ============================================================

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          paymentType == 'آجل'
              ? 'تم حفظ البيع الآجل وتسجيله على العميل بنجاح ✅'
              : 'تم حفظ البيع النقدي وتسجيله في الصندوق بنجاح ✅',
        ),
        backgroundColor: Colors.green,
      ),
    );

  } catch (e) {

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'فشل حفظ الفاتورة ❌\n$e',
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}

 // 🗑️ استرجاع / حذف الفاتورة وعكس أثرها من المخزون ودفتر الأستاذ بدقة
// ============================================================
// ✏️ تعديل الفاتورة + تحديث دفتر الأستاذ بالكامل بأمان
// ============================================================

/*void editSaleDialog(SaleModel sale) {
  final TextEditingController editCustomerController =
      TextEditingController(
    text: sale.customerName ?? '',
  );

  final TextEditingController editTotalController =
      TextEditingController(
    text: sale.totalAmount.toStringAsFixed(2),
  );

  showDialog(
    context: context,
    builder: (dialogContext) {
      bool isSaving = false;

      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,

            title: Text(
              'تعديل الفاتورة: ${sale.invoiceNo ?? ''}',
              style: const TextStyle(
                color: Color(0xFF1E40AF),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // ==================================================
                  // العميل
                  // ==================================================

                  TextField(
                    controller: editCustomerController,
                    enabled: !isSaving,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'اسم العميل',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ==================================================
                  // الإجمالي
                  // ==================================================

                  TextField(
                    controller: editTotalController,
                    enabled: !isSaving,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'الإجمالي الجديد',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ==================================================
                  // طريقة الدفع
                  // ==================================================

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius:
                          BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.payment,
                          size: 18,
                          color: Color(0xFF1E40AF),
                        ),

                        const SizedBox(width: 8),

                        const Text(
                          'طريقة الدفع:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(width: 5),

                      Expanded(
  child: Text(
    sale.paymentType ?? 'غير محدد',
    overflow: TextOverflow.ellipsis,
    style: const TextStyle(
      color: Color(0xFF1E40AF),
      fontWeight: FontWeight.bold,
    ),
  ),
),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ========================================================
            // الأزرار
            // ========================================================

            actions: [

              // إلغاء
              TextButton(
                onPressed: isSaving
                    ? null
                    : () {
                        Navigator.pop(dialogContext);
                      },
                child: const Text(
                  'إلغاء',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ),

              // حفظ
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                ),

                onPressed: isSaving
                    ? null
                    : () async {

                        // ==================================================
                        // 1. قراءة البيانات
                        // ==================================================

                        final String customer =
                            editCustomerController.text
                                .trim();

                        final String totalText =
                            editTotalController.text
                                .trim();

                        // ==================================================
                        // 2. التحقق من العميل
                        // ==================================================

                        if (customer.isEmpty) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            const SnackBar(
                              content: Text(
                                'اسم العميل لا يمكن أن يكون فارغًا',
                              ),
                              backgroundColor:
                                  Colors.red,
                            ),
                          );
                          return;
                        }

                        // ==================================================
                        // 3. التحقق من الإجمالي
                        // ==================================================

                        final double? parsedTotal =
                            double.tryParse(
                          totalText,
                        );

                        if (parsedTotal == null ||
                            !parsedTotal.isFinite ||
                            parsedTotal < 0) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            const SnackBar(
                              content: Text(
                                'أدخل إجماليًا صحيحًا',
                              ),
                              backgroundColor:
                                  Colors.red,
                            ),
                          );
                          return;
                        }

                        // ==================================================
                        // 4. رقم الفاتورة = المرجع المحاسبي
                        // ==================================================

                        final String refNo =
                            sale.invoiceNo
                                    ?.trim() ??
                                '';

                        if (refNo.isEmpty) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            const SnackBar(
                              content: Text(
                                'رقم الفاتورة غير موجود',
                              ),
                              backgroundColor:
                                  Colors.red,
                            ),
                          );
                          return;
                        }

                        // ==================================================
                        // 5. الإجمالي الجديد
                        // ==================================================

                        final double oldTotal =
                            sale.totalAmount;

                        final double newTotal =
                            parsedTotal;

                        final String oldCustomer =
                            sale.customerName
                                    ?.trim() ??
                                '';

                        // ==================================================
                        // 6. لا توجد تغييرات
                        // ==================================================

                        if (oldTotal == newTotal &&
                            oldCustomer == customer) {
                          Navigator.pop(
                            dialogContext,
                          );

                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            const SnackBar(
                              content: Text(
                                'لا توجد تغييرات لحفظها',
                              ),
                            ),
                          );

                          return;
                        }

                        // ==================================================
                        // 7. الحصول على Isar
                        // ==================================================

                        final Isar? isar =
                            Isar.getInstance();

                        if (isar == null) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            const SnackBar(
                              content: Text(
                                'قاعدة البيانات غير متاحة',
                              ),
                              backgroundColor:
                                  Colors.red,
                            ),
                          );
                          return;
                        }

                        setDialogState(() {
                          isSaving = true;
                        });

                        try {

                          // ==================================================
                          // 8. تنفيذ العملية بالكامل داخل Transaction
                          // ==================================================

                          await isar.writeTxn(
                            () async {

                              // ==============================================
                              // جلب الفاتورة الحالية من قاعدة البيانات
                              // ==============================================

                              final SaleModel? currentSale =
                                  await isar.saleModels.get(
                                sale.id,
                              );

                              if (currentSale == null) {
                                throw Exception(
                                  'الفاتورة غير موجودة في قاعدة البيانات',
                                );
                              }

                              // ==============================================
                              // جلب جميع قيود الفاتورة القديمة
                              // ==============================================

                              final List<LedgerModel>
                                  oldLedgerEntries =
                                  await isar.ledgerModels
                                      .filter()
                                      .referenceNoEqualTo(
                                        refNo,
                                      )
                                      .findAll();

                              // ==============================================
                              // الاحتفاظ بتاريخ القيد القديم
                              // ==============================================
String ledgerDate = DateTime.now().toIso8601String();

if (oldLedgerEntries.isNotEmpty) {
  ledgerDate =
      oldLedgerEntries.first.date ??
      DateTime.now().toIso8601String();
}

                              // ==============================================
                              // حذف جميع القيود القديمة
                              // ==============================================

                              for (final ledger
                                  in oldLedgerEntries) {
                                await isar.ledgerModels
                                    .delete(
                                  ledger.id,
                                );
                              }

                              // ==============================================
                              // تحديث الفاتورة
                              // ==============================================

                              currentSale.customerName =
                                  customer;

                              currentSale.totalAmount =
                                  newTotal;

                              await isar.saleModels.put(
                                currentSale,
                              );

                              // ==============================================
                              // تحديد نوع الدفع
                              // ==============================================

                              final String paymentType =
    (sale.paymentType ?? 'نقدي').trim();

                              final bool isCash =
                                  paymentType == 'نقدي' ||
                                  paymentType
                                          .toLowerCase() ==
                                      'cash';

                              final bool isCredit =
                                  paymentType == 'آجل' ||
                                  paymentType
                                          .toLowerCase() ==
                                      'credit';

                              // ==============================================
                              // حماية من نوع دفع غير معروف
                              // ==============================================

                              if (!isCash && !isCredit) {
                                throw Exception(
                                  'طريقة الدفع غير معروفة: $paymentType',
                                );
                              }

                              // ==============================================
                              // القيد الأول:
                              //
                              // المبيعات دائنة
                              // ==============================================

                              final LedgerModel salesEntry =
                                  LedgerModel(
                                date: ledgerDate,

                                description:
                                    isCredit
                                        ? 'مبيعات آجلة - '
                                            'الفاتورة $refNo'
                                        : 'مبيعات نقدية - '
                                            'الفاتورة $refNo',

                                accountName:
                                    'المبيعات',

                                partyName:
                                    customer,

                                debit: 0.0,

                                credit: newTotal,

                                referenceNo:
                                    refNo,

                                paymentType:
                                    paymentType,

                                entryType:
                                    'مبيعات',
                              );

                              // ==============================================
                              // القيد الثاني:
                              //
                              // النقدية:
                              // الصندوق مدين
                              //
                              // الآجل:
                              // العملاء مدين
                              // ==============================================

                              final LedgerModel
                                  counterEntry =
                                  LedgerModel(
                                date: ledgerDate,

                                description:
                                    isCash
                                        ? 'تحصيل مبيعات نقدية - '
                                            'الفاتورة $refNo'
                                        : 'مبيعات آجلة - '
                                            'الفاتورة $refNo',

                                accountName:
                                    isCash
                                        ? 'الصندوق الرئيسي'
                                        : 'العملاء',

                                partyName:
                                    customer,

                                debit: newTotal,

                                credit: 0.0,

                                referenceNo:
                                    refNo,

                                paymentType:
                                    paymentType,

                                entryType:
                                    'مبيعات',
                              );

                              // ==============================================
                              // حفظ القيدين
                              // ==============================================

                              await isar.ledgerModels.putAll([
                                salesEntry,
                                counterEntry,
                              ]);

                              // ==============================================
                              // التحقق من أن الفاتورة متوازنة
                              // ==============================================

                              final List<LedgerModel>
                                  newLedgerEntries =
                                  await isar.ledgerModels
                                      .filter()
                                      .referenceNoEqualTo(
                                        refNo,
                                      )
                                      .findAll();

                              double totalDebit = 0.0;
                              double totalCredit = 0.0;

                              for (final entry
                                  in newLedgerEntries) {
                                totalDebit +=
                                    entry.debit;

                                totalCredit +=
                                    entry.credit;
                              }

                              // ==============================================
                              // يجب أن يكون:
                              //
                              // المدين = الدائن
                              // ==============================================

                              if ((totalDebit -
                                          totalCredit)
                                      .abs() >
                                  0.01) {
                                throw Exception(
                                  'القيد غير متوازن.\n'
                                  'المدين: $totalDebit\n'
                                  'الدائن: $totalCredit',
                                );
                              }
                            },
                          );

                          // ==================================================
                          // 9. نجاح العملية
                          // ==================================================

                          if (!mounted) return;

                          Navigator.pop(
                            dialogContext,
                          );

                          // ==================================================
                          // 10. تحديث شاشة المبيعات
                          // ==================================================

                          await fetchSalesHistory();

                          if (!mounted) return;

                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            SnackBar(
                              content: Text(
                                'تم تعديل الفاتورة $refNo '
                                'وتحديث دفتر الأستاذ بنجاح ✅',
                              ),
                              backgroundColor:
                                  Colors.green,
                            ),
                          );
                        } catch (e) {

                          // ==================================================
                          // 11. في حالة الخطأ
                          // ==================================================

                          if (!mounted) return;

                          setDialogState(() {
                            isSaving = false;
                          });

                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            SnackBar(
                              content: Text(
                                'فشل تعديل الفاتورة:\n$e',
                              ),
                              backgroundColor:
                                  Colors.red,
                            ),
                          );
                        }
                      },

                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'حفظ التعديل',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          );
        },
      );
    },
  );
}*/
  // ============================================================
  // 🖨️ دالة طباعة تقرير فواتير اليوم
  // ============================================================
 // ============================================================
  // 🖨️ دالة طباعة تقرير فواتير اليوم (مفصلة ومنسقة)
  // ============================================================
  Future<void> _printTodayInvoicesReport(List<SaleModel> todaySales) async {
    try {
      final arabicFont = await PdfGoogleFonts.cairoRegular();
      final arabicBold = await PdfGoogleFonts.cairoBold();
      final pdf = pw.Document();

      double totalTodayAmount = 0.0;
      for (var sale in todaySales) {
        totalTodayAmount += sale.totalAmount;
      }

      final tableData = todaySales.map((sale) {
        final detailsText = sale.itemsDetails.isNotEmpty 
            ? sale.itemsDetails.join("\n") 
            : '-';

        return [
          sale.invoiceNo ?? '-',
          sale.customerName ?? 'نقدي',
          detailsText,
          '${sale.totalAmount.toStringAsFixed(2)} ر.ي',
          sale.date?.substring(0, 16) ?? '-',
        ];
      }).toList();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          header: (context) {
            return pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Text(
                    'تقرير فواتير اليوم (${intl.DateFormat('yyyy-MM-dd').format(DateTime.now())})',
                    style: pw.TextStyle(font: arabicBold, fontSize: 18),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'عمر سوفت ERP - نظام نقاط البيع المحلي',
                    style: pw.TextStyle(font: arabicFont, fontSize: 10),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 12),
                ],
              ),
            );
          },
          footer: (context) {
            return pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Container(
                alignment: pw.Alignment.centerLeft,
                margin: const pw.EdgeInsets.only(top: 10),
                child: pw.Text(
                  'صفحة ${context.pageNumber} من ${context.pagesCount}',
                  style: pw.TextStyle(font: arabicFont, fontSize: 8),
                ),
              ),
            );
          },
          build: (context) {
            return [
              pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.TableHelper.fromTextArray(
                      headers: const ['رقم الفاتورة', 'اسم العميل', 'تفاصيل الأصناف', 'الإجمالي', 'التاريخ والوقت'],
                      data: tableData,
                      headerStyle: pw.TextStyle(font: arabicBold, fontSize: 10, color: PdfColors.white),
                      headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1E40AF)),
                      cellStyle: pw.TextStyle(font: arabicFont, fontSize: 9),
                      cellAlignment: pw.Alignment.centerRight,
                      headerAlignment: pw.Alignment.centerRight,
                      border: pw.TableBorder.all(width: 0.5),
                      cellPadding: const pw.EdgeInsets.all(6),
                    ),
                    pw.SizedBox(height: 15),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'إجمالي مبيعات اليوم (${todaySales.length} فاتورة):',
                            style: pw.TextStyle(font: arabicBold, fontSize: 12),
                          ),
                          pw.Text(
                            '${totalTodayAmount.toStringAsFixed(2)} ر.ي',
                            style: pw.TextStyle(font: arabicBold, fontSize: 12, color: PdfColor.fromInt(0xFF16A34A)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ];
          },
        ),
      );

      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
    } catch (e) {
      print('Error printing today report: $e');
    }
  }

  // ============================================================
  // 📊 نافذة تقرير فواتير اليوم (مرتبة ومنسقة للأصناف)
  // ============================================================
  void _showTodayInvoicesReport(List<SaleModel> todaySales) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('تقرير فواتير اليوم', style: TextStyle(color: Color(0xFF1E40AF), fontSize: 15, fontWeight: FontWeight.bold)),
            if (todaySales.isNotEmpty)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(0, 32),
                ),
                icon: const Icon(Icons.print, size: 14),
                label: const Text('طباعة التقرير', style: TextStyle(fontSize: 11)),
                onPressed: () => _printTodayInvoicesReport(todaySales),
              ),
          ],
        ),
        content: SizedBox(
          width: 550,
          height: 400,
          child: todaySales.isEmpty
              ? const Center(child: Text('لا توجد فواتير مسجلة اليوم', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: todaySales.length,
                  itemBuilder: (context, index) {
                    final sale = todaySales[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(sale.invoiceNo ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB), fontSize: 11)),
                              Text('${sale.totalAmount} ر.ي', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16A34A), fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('العميل: ${sale.customerName ?? "نقدي"}', style: const TextStyle(fontSize: 10, color: Colors.black87, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          const Text('الأصناف والكميات:', style: TextStyle(fontSize: 9, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          ...sale.itemsDetails.map((detail) => Padding(
                            padding: const EdgeInsets.only(right: 6.0, bottom: 2),
                            child: Text('• $detail', style: const TextStyle(fontSize: 9, color: Colors.grey)),
                          )),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
 
  void exportToExcel() async {
    if (sessionSalesLog.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا توجد مبيعات لتصديرها! ⚠️'), backgroundColor: Colors.orange));
      return;
    }

    try {
      final excel = excelPkg.Excel.createExcel();
      final sheet = excel['سجل المبيعات'];

      sheet.appendRow([
        excelPkg.TextCellValue('رقم الفاتورة'),
        excelPkg.TextCellValue('العميل'),
        excelPkg.TextCellValue('الإجمالي (ر.ي)'),
        excelPkg.TextCellValue('التاريخ والوقت'),
      ]);

      for (var log in sessionSalesLog) {
        sheet.appendRow([
          excelPkg.TextCellValue(log.invoiceNo ?? ''),
          excelPkg.TextCellValue(log.customerName ?? ''),
          excelPkg.DoubleCellValue(log.totalAmount),
          excelPkg.TextCellValue(log.date ?? ''),
        ]);
      }

      final bytes = excel.save();
      if (bytes == null) return;

      final directory = await getTemporaryDirectory();
      final path = "${directory.path}/Sales_Report.xlsx";
      final file = File(path);
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(path)],
        subject: 'تقرير المبيعات المحلي - Omar Soft ERP',
      );
    } catch (e) {
      print('Excel export error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFFF8FAFC);
    const Color cardBg = Colors.white;

    final int totalInvoicesCount = filteredSalesLog.length;
    final todayStr = intl.DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    final todaySalesList = sessionSalesLog.where((log) {
      if (log.date == null) return false;
      return log.date!.startsWith(todayStr);
    }).toList();
    
    final int todayInvoicesCount = todaySalesList.length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E40AF),
          elevation: 0,
          title: const Text('نظام نقاط البيع المحلي (POS)', style: TextStyle(color: Colors.white, fontSize: 16)),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.table_chart, color: Colors.greenAccent),
              onPressed: exportToExcel,
              tooltip: 'تصدير إكسل',
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E40AF)))
            : LayoutBuilder(
                builder: (context, constraints) {
                  bool isWideScreen = constraints.maxWidth > 850;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(12.0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Column(
                          children: [
                            isWideScreen
                                ? Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 5,
                                        child: Column(
                                          children: [
                                            _buildBarcodeScannerSection(),
                                            const SizedBox(height: 12),
                                            _buildCurrentInvoiceSection(isWideScreen),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        flex: 5,
                                        child: Column(
                                          children: [
                                            _buildStatisticsCard(totalInvoicesCount, todayInvoicesCount, todaySalesList),
                                            const SizedBox(height: 12),
                                            _buildSalesHistorySection(cardBg),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      _buildBarcodeScannerSection(),
                                      const SizedBox(height: 12),
                                      _buildStatisticsCard(totalInvoicesCount, todayInvoicesCount, todaySalesList),
                                      const SizedBox(height: 12),
                                      _buildCurrentInvoiceSection(isWideScreen),
                                      const SizedBox(height: 12),
                                      _buildSalesHistorySection(cardBg),
                                    ],
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

  Widget _buildStatisticsCard(int totalCount, int todayCount, List<SaleModel> todaySales) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(child: _statItem('إجمالي الفواتير', '$totalCount', Icons.receipt_long, const Color(0xFF2563EB), null)),
          Container(height: 30, width: 1, color: Colors.grey.shade300),
          Expanded(
            child: InkWell(
              onTap: () => _showTodayInvoicesReport(todaySales),
              child: _statItem('فواتير اليوم', '$todayCount', Icons.today, const Color(0xFF16A34A), Colors.amber.shade100),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String title, String value, IconData icon, Color color, Color? bgHighlight) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: bgHighlight ?? Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 4),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 9), overflow: TextOverflow.ellipsis),
                Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarcodeScannerSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              const Text(
                '⚡ مسح سريع أو بحث',
                style: TextStyle(color: Color(0xFF1E40AF), fontSize: 11, fontWeight: FontWeight.bold),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: _openProductSearchDialog,
                    icon: const Icon(Icons.search, size: 12, color: Colors.white),
                    label: const Text('بحث بالاسم', style: TextStyle(color: Colors.white, fontSize: 9)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB), 
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      minimumSize: const Size(0, 30),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                    icon: const Icon(Icons.camera_alt, color: Color(0xFF2563EB), size: 20),
                    onPressed: () async {
                      final scannedCode = await Navigator.push(context, MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()));
                      if (scannedCode != null && scannedCode is String) {
                        handleBarcodeScanned(scannedCode);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _barcodeController,
            focusNode: _barcodeFocusNode,
            autofocus: true,
            onSubmitted: handleBarcodeScanned,
            decoration: InputDecoration(
              hintText: 'امسح الباركود أو اضغط Enter...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentInvoiceSection(bool isWideScreen) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('📄 الفاتورة الحالية', style: TextStyle(color: Color(0xFF1E40AF), fontSize: 12, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: cancelCurrentInvoice,
                    icon: const Icon(Icons.cancel, size: 12, color: Colors.white),
                    label: const Text('إلغاء', style: TextStyle(color: Colors.white, fontSize: 9)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, elevation: 0),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton.icon(
                    onPressed: printCurrentInvoice,
                    icon: const Icon(Icons.print, size: 12, color: Colors.white),
                    label: const Text('طباعة', style: TextStyle(color: Colors.white, fontSize: 9)),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), elevation: 0),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          isWideScreen
              ? Row(
                  children: [
                    Expanded(child: TextField(controller: _customerController, decoration: _inputDeco('اسم العميل'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: _inputDeco('رقم الهاتف'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: _cashierController, decoration: _inputDeco('اسم الكاشير'))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _paymentType,
                        dropdownColor: Colors.white,
                        style: const TextStyle(color: Color(0xFF1E293B), fontSize: 11),
                        decoration: _inputDeco('الدفع'),
                        items: ['نقدي', 'آجل'].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                        onChanged: (val) => setState(() => _paymentType = val!),
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _customerController, decoration: _inputDeco('اسم العميل'))),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: _inputDeco('الهاتف'))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _cashierController, decoration: _inputDeco('اسم الكاشير'))),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _paymentType,
                            dropdownColor: Colors.white,
                            style: const TextStyle(color: Color(0xFF1E293B), fontSize: 11),
                            decoration: _inputDeco('الدفع'),
                            items: ['نقدي', 'آجل'].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                            onChanged: (val) => setState(() => _paymentType = val!),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
          const SizedBox(height: 12),
          currentInvoiceItems.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Center(child: Text('لم يتم اختيار أصناف بعد', style: TextStyle(color: Colors.grey, fontSize: 11))),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: currentInvoiceItems.length,
                  itemBuilder: (context, index) {
                    final item = currentInvoiceItems[index];
                    return GestureDetector(
                      onTap: () => _editInvoiceItemDialog(index),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                  Text('السعر: ${item['price']} | الكمية: ${item['qty']}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                ],
                              ),
                            ),
                            Text('${item['total']} ر.ي', style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 11)),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent, size: 16), onPressed: () => removeItemFromInvoice(index)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('الإجمالي الكلي', style: TextStyle(color: Colors.grey, fontSize: 10)),
                  Text('${netTotal.toStringAsFixed(2)} ر.ي', style: const TextStyle(color: Color(0xFF16A34A), fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
              ElevatedButton(
                onPressed: saveInvoice,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A), elevation: 0),
                child: const Text('اعتماد وحفظ 💾', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }

Widget _buildSalesHistorySection(Color cardBg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg, 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📜 سجل مبيعات الجلسة المحلية', style: TextStyle(color: Color(0xFF1E40AF), fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(
            controller: _searchSalesController,
            onChanged: _filterSalesLog,
            decoration: InputDecoration(
              hintText: 'ابحث برقم الفاتورة أو العميل...',
              prefixIcon: const Icon(Icons.search, size: 18),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            ),
          ),
          const SizedBox(height: 10),
          filteredSalesLog.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Center(child: Text('لا توجد فواتير مسجلة محلياً', style: TextStyle(color: Colors.grey, fontSize: 11))),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredSalesLog.length,
                  itemBuilder: (context, index) {
                    final log = filteredSalesLog[index];
                    
                    String formattedDate = '';
                    String formattedTime = '';
                    String dayName = '';
                    if (log.date != null) {
                      try {
                        final parsedDate = DateTime.parse(log.date!);
                        formattedDate = intl.DateFormat('yyyy-MM-dd').format(parsedDate);
                        formattedTime = intl.DateFormat('hh:mm a').format(parsedDate);
                        dayName = intl.DateFormat('EEEE', 'ar').format(parsedDate);
                      } catch (_) {
                        formattedDate = log.date!;
                      }
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // القسم الأيمن: تفاصيل الفاتورة (مغلف بـ Expanded لتجنب الضغط)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        log.invoiceNo ?? 'INV',
                                        style: const TextStyle(color: Color(0xFF2563EB), fontSize: 10, fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${log.totalAmount} ر.ي',
                                      style: const TextStyle(color: Color(0xFF16A34A), fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'العميل: ${log.customerName ?? "نقدي"}',
                                  style: const TextStyle(color: Color(0xFF1E293B), fontSize: 9),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${dayName.isNotEmpty ? "$dayName - " : ""}$formattedDate | $formattedTime',
                                  style: const TextStyle(color: Colors.grey, fontSize: 8),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          // القسم الأيسر: الأيقونات بحجم مرن وصغير ليتناسب مع الجوال واللابتوب
                          Wrap(
                            spacing: 2,
                            runSpacing: 2,
                            alignment: WrapAlignment.end,
                            children: [
                            /*  IconButton(
                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.edit, color: Colors.amber, size: 15),
                                onPressed: () => editSaleDialog(log),
                                tooltip: 'تعديل',
                              ),*/
                              IconButton(
                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.print, color: Color(0xFF2563EB), size: 15),
                                onPressed: () => printSaleInvoice(log),
                                tooltip: 'طباعة الفاتورة',
                              ),
                              IconButton(
                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.assignment_return, color: Colors.orange, size: 15),
                                onPressed: () => returnSaleDialog(log),
                                tooltip: 'استرجاع من الفاتورة',
                              ),
                              IconButton(
                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 15),
                                onPressed: () => deleteSale(log),
                                tooltip: 'استرجاع وحذف',
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 10, color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    );
  }
}