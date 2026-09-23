
import 'package:isar/isar.dart';
import '../model/sales_return_model.dart';
import 'package:erp_application_1/model/inventory_model.dart';
import '../model/expense_model.dart';
import '../model/supplier_model.dart';
import '../model/ledger_model.dart';
import '../model/voucher_model.dart';
import '../model/sale_model.dart';

class ApiService {
  
  // ============================================================
  // الحسابات المحاسبية الرئيسية
  // يجب أن تتطابق الأسماء مع الحسابات الموجودة في LedgerScreen
  // ============================================================

  static const String cashAccount = 'الصندوق الرئيسي';
  static const String bankAccount = 'البنك';
  static const String inventoryAccount = 'المخزون السلعي';
  static const String customerAccount = 'العملاء';
  static const String supplierAccount = 'الموردون';
  static const String salesAccount = 'المبيعات';
  static const String purchaseAccount = 'المشتريات';
  static const String cogsAccount = 'تكلفة البضاعة المباعة';
  static const String expenseAccount = 'المصاريف العامة';

  // ============================================================
  // أدوات عامة
  // ============================================================

  Isar? get _isar => Isar.getInstance();

  String _now() {
    return DateTime.now().toIso8601String();
  }

  String _generateReference(String prefix) {
    return '$prefix-${DateTime.now().millisecondsSinceEpoch}';
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0.0;
  }

  String _string(dynamic value, [String fallback = '']) {
    if (value == null) return fallback;
    return value.toString().trim();
  }

  bool _isCashPayment(String? paymentType) {
    final value = (paymentType ?? '').trim().toLowerCase();

    return value == 'نقدي' ||
        value == 'نقد' ||
        value == 'كاش' ||
        value == 'cash';
  }

  bool _isBankPayment(String? paymentMethod) {
    final value = (paymentMethod ?? '').trim().toLowerCase();

    return value == 'بنك' ||
        value == 'البنك' ||
        value == 'تحويل بنكي' ||
        value == 'تحويل' ||
        value == 'bank' ||
        value == 'bank transfer';
  }

  String _cashOrBankAccount(String? paymentMethod) {
    return _isBankPayment(paymentMethod)
        ? bankAccount
        : cashAccount;
  }
// ============================================================
  // حذف فاتورة مشتريات (مع عكس المخزون والأثر المحاسبي)
  // ============================================================

  Future<bool> deletePurchaseInvoice(int id, String invoiceNo, List<Map<String, dynamic>> itemsList) async {
    try {
      final isar = _isar;
      if (isar == null) return false;

      final products = await isar.inventoryModels.where().findAll();

      await isar.writeTxn(() async {
        // 1. خصم الكميات المضافة سابقاً من المخزون عند إلغاء الشراء
        for (final item in itemsList) {
          final productName = _string(item['productName'] ?? item['name']);
          final qty = _toDouble(item['qty'] ?? item['quantity']);

          if (productName.isEmpty || qty <= 0) continue;

          for (final product in products) {
            if (product.name.trim() == productName) {
              product.qty -= qty;
              if (product.qty < 0) product.qty = 0; // حماية المخزون من السوالب
              await isar.inventoryModels.put(product);
              break;
            }
          }
        }

        // 2. حذف قيود دفتر الأستاذ المرتبطة برقم فاتورة المشتريات
        await _deleteLedgerByReference(isar, invoiceNo);

        // 3. حذف فاتورة المشتريات من جدولها الرئيسي (إن وجد جدول مخصص)
        // await isar.purchaseModels.delete(id); 
      });

      return true;
    } catch (e) {
      print('DELETE Purchase Error: $e');
      throw Exception('فشل حذف فاتورة المشتريات وعكس قيودها ومخزونها: $e');
    }
  }
  // ============================================================
  // حذف قيود مرتبطة بمرجع
  // ============================================================

  Future<void> _deleteLedgerByReference(
    Isar isar,
    String? referenceNo,
  ) async {
    if (referenceNo == null || referenceNo.trim().isEmpty) {
      return;
    }

    final entries = await isar.ledgerModels.where().findAll();

    final ids = entries
        .where((e) => e.referenceNo == referenceNo)
        .map((e) => e.id)
        .where((id) => id > 0)
        .toList();

    if (ids.isNotEmpty) {
      await isar.ledgerModels.deleteAll(ids);
    }
  }

  // ============================================================
  // التحقق من توازن قيد
  // ============================================================

  bool _isBalanced(List<LedgerModel> entries) {
    double debit = 0.0;
    double credit = 0.0;

    for (final entry in entries) {
      debit += entry.debit;
      credit += entry.credit;
    }

    return (debit - credit).abs() < 0.0001;
  }

  // ============================================================
  // البحث عن منتج بالاسم
  // ============================================================

  Future<InventoryModel?> _findProductByName(
    Isar isar,
    String name,
  ) async {
    final searchName = name.trim();

    if (searchName.isEmpty) {
      return null;
    }

    final products =
        await isar.inventoryModels.where().findAll();

    for (final product in products) {
      if (product.name.trim() == searchName) {
        return product;
      }
    }

    return null;
  }
// ============================================================
// حساب الكمية المسترجعة سابقاً لصنف من فاتورة معينة
// ============================================================

Future<double> _getPreviouslyReturnedQty(
  Isar isar,
  String invoiceNo,
  String productName,
) async {
  final returns =
      await isar.salesReturnModels.where().findAll();

  double returnedQty = 0.0;

  for (final salesReturn in returns) {
    if ((salesReturn.invoiceNo ?? '').trim() !=
        invoiceNo.trim()) {
      continue;
    }

    for (final item in salesReturn.items) {
      final itemName =
          (item.productName ?? '').trim();

      if (itemName == productName.trim()) {
        returnedQty += item.qty;
      }
    }
  }

  return returnedQty;
}
  // ============================================================
  // البحث عن منتج بالباركود
  // ============================================================

  Future<InventoryModel?> getProductByBarcode(
    String barcode,
  ) async {
    try {
      final isar = _isar;

      if (isar == null) return null;

      final code = barcode.trim();

      if (code.isEmpty) return null;

      final inventory =
          await isar.inventoryModels.where().findAll();

      for (final product in inventory) {
        if (product.barcode != null &&
            product.barcode!.trim() == code) {
          return product;
        }
      }

      return null;
    } catch (e) {
      print('Barcode Search Error: $e');
      return null;
    }
  }

  // ============================================================
  // 1. المخزون
  // ============================================================

  Future<List<InventoryModel>> getInventory() async {
    try {
      final isar = _isar;

      if (isar == null) return [];

      return await isar.inventoryModels.where().findAll();
    } catch (e) {
      print('GET Inventory Error: $e');
      return [];
    }
  }

  Future<bool> saveProduct(
    InventoryModel product,
  ) async {
    try {
      final isar = _isar;

      if (isar == null) return false;

      if (product.name.trim().isEmpty) {
        throw Exception('اسم المنتج مطلوب');
      }

      if (product.qty < 0) {
        throw Exception('كمية المخزون لا يمكن أن تكون سالبة');
      }

      if (product.cost < 0) {
        throw Exception('تكلفة المنتج لا يمكن أن تكون سالبة');
      }

      if (product.price < 0) {
        throw Exception('سعر البيع لا يمكن أن يكون سالباً');
      }

      await isar.writeTxn(() async {
        await isar.inventoryModels.put(product);
      });

      return true;
    } catch (e) {
      print('POST Inventory Error: $e');
      throw Exception('فشل حفظ المنتج: $e');
    }
  }

  Future<bool> updateProduct(
    int id,
    Map<String, dynamic> productData,
  ) async {
    try {
      final isar = _isar;

      if (isar == null) return false;

      final updatedProduct =
          InventoryModel.fromJson(productData);

      updatedProduct.id = id;

      if (updatedProduct.name.trim().isEmpty) {
        throw Exception('اسم المنتج مطلوب');
      }

      if (updatedProduct.qty < 0) {
        throw Exception('كمية المخزون لا يمكن أن تكون سالبة');
      }

      if (updatedProduct.cost < 0) {
        throw Exception('التكلفة لا يمكن أن تكون سالبة');
      }

      if (updatedProduct.price < 0) {
        throw Exception('السعر لا يمكن أن يكون سالباً');
      }

      await isar.writeTxn(() async {
        await isar.inventoryModels.put(updatedProduct);
      });

      return true;
    } catch (e) {
      print('PUT Inventory Error: $e');
      throw Exception('فشل تحديث المنتج: $e');
    }
  }

  Future<bool> deleteProduct(int id) async {
    try {
      final isar = _isar;

      if (isar == null) return false;

      await isar.writeTxn(() async {
        await isar.inventoryModels.delete(id);
      });

      return true;
    } catch (e) {
      print('DELETE Inventory Error: $e');
      throw Exception('فشل حذف المنتج: $e');
    }
  }

  Future<List<InventoryModel>>
      getCriticalStockAlerts() async {
    try {
      final inventory = await getInventory();

      return inventory
          .where((item) => item.qty <= item.min)
          .toList();
    } catch (e) {
      print('GET Critical Stock Alerts Error: $e');
      return [];
    }
  }

  // ============================================================
  // 2. المبيعات
  //
  // نقدي:
  // مدين الصندوق
  // دائن المبيعات
  //
  // آجل:
  // مدين العملاء
  // دائن المبيعات
  //
  // تكلفة البضاعة:
  // مدين تكلفة البضاعة المباعة
  // دائن المخزون
  // ============================================================

  Future<List<dynamic>> getSales() async {
    try {
      final isar = _isar;

      if (isar == null) return [];

      final sales =
          await isar.saleModels.where().findAll();

      return sales
          .map((sale) => sale.toJson())
          .toList();
    } catch (e) {
      print('GET Sales Error: $e');
      return [];
    }
  }
// ============================================================
// مرتجع مبيعات
//
// عند اعتماد المرتجع:
//
// 1. التأكد من وجود الفاتورة الأصلية
// 2. التأكد من وجود الأصناف في الفاتورة
// 3. منع تجاوز الكمية المباعة
// 4. حساب المرتجعات السابقة
// 5. إعادة الكمية للمخزون
// 6. إنشاء سجل المرتجع
// 7. عكس قيد المبيعات
// 8. عكس تكلفة البضاعة
//
// القيد المالي:
//
// مرتجع نقدي:
// مدين المبيعات
// دائن الصندوق
//
// مرتجع آجل:
// مدين المبيعات
// دائن العملاء
//
// عكس تكلفة البضاعة:
// مدين المخزون
// دائن تكلفة البضاعة المباعة
// ============================================================

Future<bool> saveSalesReturn(
  Map<String, dynamic> returnData,
) async {
  try {
    final isar = _isar;

    if (isar == null) {
      return false;
    }

    // ============================================================
    // 1) قراءة رقم الفاتورة الأصلية
    // ============================================================

    final invoiceNo = _string(
      returnData['invoiceNo'] ??
          returnData['invoice'],
    );

    if (invoiceNo.isEmpty) {
      throw Exception(
        'رقم فاتورة البيع مطلوب لإجراء المرتجع',
      );
    }

    // ============================================================
    // 2) البحث عن الفاتورة الأصلية
    // ============================================================

    final sales = await isar.saleModels
        .where()
        .findAll();

    SaleModel? originalSale;

    for (final sale in sales) {
      if ((sale.invoiceNo ?? '').trim() ==
          invoiceNo.trim()) {
        originalSale = sale;
        break;
      }
    }

    if (originalSale == null) {
      throw Exception(
        'فاتورة البيع غير موجودة: $invoiceNo',
      );
    }

    // ============================================================
    // 3) بيانات المرتجع
    // ============================================================

    final customerName = _string(
      returnData['customerName'] ??
          returnData['customer'],
      originalSale.customerName ?? 'عميل نقدي',
    );

    final paymentType = _string(
      returnData['paymentType'],
      originalSale.paymentType ?? 'نقدي',
    );

    final date = _string(
      returnData['date'],
      _now(),
    );

    final reason = _string(
      returnData['reason'],
    );

    // ============================================================
    // 4) قراءة الأصناف المرتجعة
    // ============================================================

    final rawItems = returnData['items'];

    if (rawItems is! List ||
        rawItems.isEmpty) {
      throw Exception(
        'يجب اختيار صنف واحد على الأقل للمرتجع',
      );
    }

    final returnItems =
        <SalesReturnItemModel>[];

    // ============================================================
    // 5) جلب المخزون
    // ============================================================

    final products = await isar.inventoryModels
        .where()
        .findAll();

    double totalCogs = 0.0;
    double totalReturnAmount = 0.0;

    // ============================================================
    // 6) التحقق من كل صنف مرتجع
    // ============================================================

    for (final rawItem in rawItems) {
      if (rawItem is! Map) {
        continue;
      }

      final productName = _string(
        rawItem['productName'] ??
            rawItem['name'],
      );

      final barcode = _string(
        rawItem['barcode'],
      );

      final returnQty = _toDouble(
        rawItem['qty'] ??
            rawItem['quantity'],
      );

      final price = _toDouble(
        rawItem['price'] ??
            rawItem['salePrice'],
      );

      // ----------------------------------------------------------
      // التحقق من اسم الصنف
      // ----------------------------------------------------------

      if (productName.isEmpty) {
        throw Exception(
          'يوجد صنف مرتجع بدون اسم',
        );
      }

      // ----------------------------------------------------------
      // التحقق من الكمية
      // ----------------------------------------------------------

      if (returnQty <= 0) {
        throw Exception(
          'كمية المرتجع يجب أن تكون أكبر من صفر: $productName',
        );
      }

      // ==========================================================
      // البحث عن الصنف داخل الفاتورة الأصلية
      // ==========================================================

      SaleItem? originalItem;

      for (final item in originalSale!.items) {
        final originalName =
            (item.productName ?? '').trim();

        final originalBarcode =
            (item.barcode ?? '').trim();

        final sameName =
            originalName == productName.trim();

        final sameBarcode =
            barcode.isNotEmpty &&
            originalBarcode.isNotEmpty &&
            originalBarcode == barcode.trim();

        if (sameName || sameBarcode) {
          originalItem = item;
          break;
        }
      }

      if (originalItem == null) {
        throw Exception(
          'الصنف "$productName" غير موجود في الفاتورة $invoiceNo',
        );
      }

      // ==========================================================
      // الكمية المباعة
      // ==========================================================

      final soldQty = originalItem.qty;

      if (soldQty <= 0) {
        throw Exception(
          'الكمية المباعة غير صحيحة للصنف: $productName',
        );
      }

      // ==========================================================
      // الكمية المرتجعة سابقاً
      // ==========================================================

      final previousReturnedQty =
          await _getPreviouslyReturnedQty(
        isar,
        invoiceNo,
        productName,
      );

      // ==========================================================
      // الكمية المتبقية المسموح بإرجاعها
      // ==========================================================

      final availableReturnQty =
          soldQty - previousReturnedQty;

      if (availableReturnQty <= 0) {
        throw Exception(
          'تم إرجاع كامل كمية "$productName" مسبقاً',
        );
      }

      // ==========================================================
      // منع تجاوز الكمية المباعة
      // ==========================================================

      if (returnQty > availableReturnQty) {
        throw Exception(
          'الكمية المطلوبة للمرتجع من "$productName" '
          'أكبر من الكمية المتاحة. '
          'المباع: $soldQty، '
          'المرتجع سابقاً: $previousReturnedQty، '
          'المتاح للمرتجع: $availableReturnQty، '
          'المطلوب: $returnQty',
        );
      }

      // ==========================================================
      // البحث عن المنتج في المخزون
      // ==========================================================

      InventoryModel? product;

      for (final inventoryItem in products) {
        final inventoryName =
            inventoryItem.name.trim();

        final inventoryBarcode =
            (inventoryItem.barcode ?? '').trim();

        final sameName =
            inventoryName == productName.trim();

        final sameBarcode =
            barcode.isNotEmpty &&
            inventoryBarcode.isNotEmpty &&
            inventoryBarcode == barcode.trim();

        if (sameName || sameBarcode) {
          product = inventoryItem;
          break;
        }
      }

      if (product == null) {
        throw Exception(
          'المنتج غير موجود في المخزون: $productName',
        );
      }

      // ==========================================================
      // تحديد سعر المرتجع
      // ==========================================================

      final finalPrice =
          price > 0
              ? price
              : originalItem.price;

      if (finalPrice < 0) {
        throw Exception(
          'سعر المرتجع غير صحيح: $productName',
        );
      }

      // ==========================================================
      // إجمالي الصنف
      // ==========================================================

      final itemTotal =
          finalPrice * returnQty;

      // ==========================================================
      // تكلفة البضاعة المرتجعة
      // ==========================================================

      totalCogs +=
          product.cost * returnQty;

      // ==========================================================
      // إجمالي المرتجع
      // ==========================================================

      totalReturnAmount +=
          itemTotal;

      // ==========================================================
      // إضافة الصنف إلى المرتجع
      // ==========================================================

      returnItems.add(
        SalesReturnItemModel(
          productName: productName,
          barcode: barcode.isNotEmpty
              ? barcode
              : originalItem.barcode,
          price: finalPrice,
          qty: returnQty,
          total: itemTotal,
        ),
      );
    }

    // ============================================================
    // 7) التحقق من إجمالي المرتجع
    // ============================================================

    if (totalReturnAmount <= 0) {
      throw Exception(
        'إجمالي المرتجع يجب أن يكون أكبر من صفر',
      );
    }

    // ============================================================
    // 8) تنفيذ العملية كاملة داخل Transaction
    // ============================================================

    await isar.writeTxn(() async {

      // ==========================================================
      // إنشاء سجل المرتجع
      // ==========================================================

      final salesReturn =
          SalesReturnModel(
        invoiceNo: invoiceNo,
        customerName: customerName,
        date: date,
        totalAmount: totalReturnAmount,
        paymentType: paymentType,
        reason: reason.isEmpty
            ? null
            : reason,
        items: returnItems,
      );

      // ----------------------------------------------------------
      // حفظ المرتجع أولاً للحصول على ID
      // ----------------------------------------------------------

      await isar.salesReturnModels.put(
        salesReturn,
      );

      // ==========================================================
      // إنشاء رقم مستقل للمرتجع
      //
      // مثال:
      // RET-15
      // RET-16
      // RET-17
      // ==========================================================

      final returnReference =
          'RET-${salesReturn.id}';

      salesReturn.returnReference =
          returnReference;

      // ----------------------------------------------------------
      // إعادة حفظ المرتجع بعد إضافة المرجع
      // ----------------------------------------------------------

      await isar.salesReturnModels.put(
        salesReturn,
      );

      // ==========================================================
      // 9) إعادة الكمية إلى المخزون
      // ==========================================================

      for (final returnItem in returnItems) {

        final productName =
            (returnItem.productName ?? '')
                .trim();

        if (productName.isEmpty) {
          continue;
        }

        InventoryModel? product;

        // --------------------------------------------------------
        // البحث بالباركود أولاً
        // --------------------------------------------------------

        final returnBarcode =
            (returnItem.barcode ?? '').trim();

        if (returnBarcode.isNotEmpty) {
          for (final inventoryItem in products) {
            final inventoryBarcode =
                (inventoryItem.barcode ?? '').trim();

            if (inventoryBarcode.isNotEmpty &&
                inventoryBarcode ==
                    returnBarcode) {
              product = inventoryItem;
              break;
            }
          }
        }

        // --------------------------------------------------------
        // إذا لم نجد بالباركود نبحث بالاسم
        // --------------------------------------------------------

        product ??= products.cast<InventoryModel?>().firstWhere(
          (inventoryItem) =>
              inventoryItem != null &&
              inventoryItem.name.trim() ==
                  productName,
          orElse: () => null,
        );

        if (product == null) {
          throw Exception(
            'تعذر العثور على المنتج لإعادة الكمية: $productName',
          );
        }

        // --------------------------------------------------------
        // إعادة الكمية للمخزون
        // --------------------------------------------------------

        product.qty +=
            returnItem.qty;

        await isar.inventoryModels.put(
          product,
        );
      }

      // ==========================================================
      // 10) تحديد الحساب المقابل
      //
      // نقدي  => الصندوق الرئيسي
      // آجل   => العملاء
      // ==========================================================

      final creditAccount =
          _isCashPayment(paymentType)
              ? cashAccount
              : customerAccount;

      // ==========================================================
      // 11) قيد قيمة مرتجع المبيعات
      //
      // مدين: المبيعات
      // دائن: الصندوق / العملاء
      // ==========================================================

      final salesReturnDebit =
          LedgerModel(
        date: date,
        description:
            'مرتجع مبيعات من الفاتورة $invoiceNo',
        accountName:
            salesAccount,
        partyName:
            customerName,
        debit:
            totalReturnAmount,
        credit:
            0.0,
        referenceNo:
            returnReference,
        paymentType:
            paymentType,
        entryType:
            'مرتجع مبيعات',
      );

      final salesReturnCredit =
          LedgerModel(
        date: date,
        description:
            'مرتجع مبيعات من الفاتورة $invoiceNo',
        accountName:
            creditAccount,
        partyName:
            customerName,
        debit:
            0.0,
        credit:
            totalReturnAmount,
        referenceNo:
            returnReference,
        paymentType:
            paymentType,
        entryType:
            'مرتجع مبيعات',
      );

      await isar.ledgerModels.putAll([
        salesReturnDebit,
        salesReturnCredit,
      ]);

      // ==========================================================
      // 12) عكس تكلفة البضاعة المباعة
      //
      // مدين: المخزون
      // دائن: تكلفة البضاعة المباعة
      // ==========================================================

      if (totalCogs > 0) {

        final inventoryDebit =
            LedgerModel(
          date: date,
          description:
              'إرجاع مخزون - مرتجع $returnReference',
          accountName:
              inventoryAccount,
          partyName:
              customerName,
          debit:
              totalCogs,
          credit:
              0.0,
          referenceNo:
              returnReference,
          paymentType:
              paymentType,
          entryType:
              'مرتجع مبيعات',
        );

        final cogsCredit =
            LedgerModel(
          date: date,
          description:
              'عكس تكلفة مبيعات - مرتجع $returnReference',
          accountName:
              cogsAccount,
          partyName:
              customerName,
          debit:
              0.0,
          credit:
              totalCogs,
          referenceNo:
              returnReference,
          paymentType:
              paymentType,
          entryType:
              'مرتجع مبيعات',
        );

        await isar.ledgerModels.putAll([
          inventoryDebit,
          cogsCredit,
        ]);
      }

      // ==========================================================
      // 13) التحقق من توازن قيد المرتجع
      // ==========================================================

      final allLedger =
          await isar.ledgerModels
              .where()
              .findAll();

      final returnEntries =
          allLedger.where(
        (entry) =>
            entry.referenceNo ==
            returnReference,
      ).toList();

      if (!_isBalanced(returnEntries)) {
        throw Exception(
          'قيد مرتجع المبيعات غير متوازن',
        );
      }
    });

    // ============================================================
    // 14) نجاح العملية
    // ============================================================

    return true;

  } catch (e) {

    print(
      'POST Sales Return Error: $e',
    );

    throw Exception(
      'فشل اعتماد مرتجع المبيعات: $e',
    );
  }
}
  Future<bool> saveSaleInvoice(
    Map<String, dynamic> invoiceData,
  ) async {
    try {
      final isar = _isar;

      if (isar == null) return false;

      final sale =
          SaleModel.fromJson(invoiceData);

      final invoiceNo =
          _string(
            invoiceData['invoiceNo'] ??
                invoiceData['invoice'],
          ).isNotEmpty
              ? _string(
                  invoiceData['invoiceNo'] ??
                      invoiceData['invoice'],
                )
              : _generateReference('INV');

      final paymentType =
          _string(
            invoiceData['paymentType'],
            'نقدي',
          );

      final customerName =
          _string(
            invoiceData['customerName'] ??
                invoiceData['customer'],
            'عميل نقدي',
          );

      final totalAmount =
          sale.totalAmount;

      if (totalAmount <= 0) {
        throw Exception(
          'إجمالي الفاتورة يجب أن يكون أكبر من صفر',
        );
      }

      // ----------------------------------------------------------
      // منع تكرار رقم الفاتورة
      // ----------------------------------------------------------

      final existingSales =
          await isar.saleModels.where().findAll();

      final duplicate = existingSales.any(
        (item) =>
            item.invoiceNo != null &&
            item.invoiceNo!.trim() == invoiceNo,
      );

      if (duplicate) {
        throw Exception(
          'رقم الفاتورة موجود مسبقاً: $invoiceNo',
        );
      }

      // ----------------------------------------------------------
      // حساب تكلفة البضاعة من تكلفة المنتج وقت البيع
      // ----------------------------------------------------------

      double totalCogs = 0.0;

      final products =
          await isar.inventoryModels.where().findAll();

      for (final saleItem in sale.items) {
        final productName =
            saleItem.productName?.trim() ?? '';

        final qty =
            saleItem.qty;

        if (productName.isEmpty) {
          throw Exception(
            'يوجد صنف في الفاتورة بدون اسم',
          );
        }

        if (qty <= 0) {
          throw Exception(
            'كمية المنتج يجب أن تكون أكبر من صفر: $productName',
          );
        }

        InventoryModel? product;

        for (final item in products) {
          if (item.name.trim() == productName) {
            product = item;
            break;
          }
        }

        if (product == null) {
          throw Exception(
            'المنتج غير موجود في المخزون: $productName',
          );
        }

        if (product.qty < qty) {
          throw Exception(
            'الكمية غير كافية للمنتج "$productName". '
            'المتوفر: ${product.qty}، المطلوب: $qty',
          );
        }

        totalCogs +=
            product.cost * qty;
      }

      await isar.writeTxn(() async {
        // --------------------------------------------------------
        // حفظ الفاتورة
        // --------------------------------------------------------

        sale.invoiceNo = invoiceNo;
        sale.customerName = customerName;

        await isar.saleModels.put(sale);

        // --------------------------------------------------------
        // القيد الأول: المبيعات
        // --------------------------------------------------------

        final debitAccount =
            _isCashPayment(paymentType)
                ? cashAccount
                : customerAccount;

        final saleDebit =
            LedgerModel(
          date: sale.date ?? _now(),
          description:
              'فاتورة مبيعات رقم $invoiceNo',
          accountName: debitAccount,
          partyName: customerName,
          debit: totalAmount,
          credit: 0.0,
          referenceNo: invoiceNo,
          paymentType: paymentType,
          entryType: 'مبيعات',
        );

        final saleCredit =
            LedgerModel(
          date: sale.date ?? _now(),
          description:
              'فاتورة مبيعات رقم $invoiceNo',
          accountName: salesAccount,
          partyName: customerName,
          debit: 0.0,
          credit: totalAmount,
          referenceNo: invoiceNo,
          paymentType: paymentType,
          entryType: 'مبيعات',
        );

        await isar.ledgerModels.putAll([
          saleDebit,
          saleCredit,
        ]);

        // --------------------------------------------------------
        // القيد الثاني: تكلفة البضاعة المباعة
        // --------------------------------------------------------

        if (totalCogs > 0) {
          final cogsDebit =
              LedgerModel(
            date: sale.date ?? _now(),
            description:
                'تكلفة البضاعة - فاتورة $invoiceNo',
            accountName: cogsAccount,
            partyName: customerName,
            debit: totalCogs,
            credit: 0.0,
            referenceNo: invoiceNo,
            paymentType: paymentType,
            entryType: 'تكلفة مبيعات',
          );

          final inventoryCredit =
              LedgerModel(
            date: sale.date ?? _now(),
            description:
                'خروج مخزون - فاتورة $invoiceNo',
            accountName: inventoryAccount,
            partyName: customerName,
            debit: 0.0,
            credit: totalCogs,
            referenceNo: invoiceNo,
            paymentType: paymentType,
            entryType: 'تكلفة مبيعات',
          );

          await isar.ledgerModels.putAll([
            cogsDebit,
            inventoryCredit,
          ]);
        }

        // --------------------------------------------------------
        // خصم المخزون
        // --------------------------------------------------------

        for (final saleItem in sale.items) {
          final productName =
              saleItem.productName?.trim() ?? '';

          if (productName.isEmpty) continue;

          final qty =
              saleItem.qty;

          for (final product in products) {
            if (product.name.trim() == productName) {
              product.qty -= qty;

              await isar.inventoryModels.put(
                product,
              );

              break;
            }
          }
        }

        // --------------------------------------------------------
        // التأكد من توازن الفاتورة
        // --------------------------------------------------------

        final ledgerEntries =
            await isar.ledgerModels
                .where()
                .findAll();

        final invoiceEntries =
            ledgerEntries
                .where(
                  (e) =>
                      e.referenceNo ==
                      invoiceNo,
                )
                .toList();

        if (!_isBalanced(invoiceEntries)) {
          throw Exception(
            'القيد المحاسبي للفاتورة غير متوازن',
          );
        }
      });

      return true;
    } catch (e) {
      print('POST Sales Error: $e');

      throw Exception(
        'حدث خطأ أثناء حفظ الفاتورة وترحيلها محاسبياً: $e',
      );
    }
  }

  // ============================================================
  // تعديل فاتورة مبيعات
  //
  // 1- إعادة المخزون القديم
  // 2- حذف القيود القديمة
  // 3- حفظ الفاتورة الجديدة
  // 4- إنشاء القيود الجديدة
  // 5- خصم المخزون الجديد
  // ============================================================

  Future<bool> updateSaleInvoice(
    int id,
    Map<String, dynamic> invoiceData,
  ) async {
    try {
      final isar = _isar;

      if (isar == null) return false;

      final oldSale =
          await isar.saleModels.get(id);

      if (oldSale == null) {
        throw Exception(
          'الفاتورة غير موجودة',
        );
      }

      final sale =
          SaleModel.fromJson(invoiceData);

      sale.id = id;

      final oldInvoiceNo =
          oldSale.invoiceNo;

      final invoiceNo =
          _string(
            invoiceData['invoiceNo'] ??
                invoiceData['invoice'],
          ).isNotEmpty
              ? _string(
                  invoiceData['invoiceNo'] ??
                      invoiceData['invoice'],
                )
              : oldInvoiceNo ??
                  _generateReference('INV');

      final paymentType =
          _string(
            invoiceData['paymentType'],
            'نقدي',
          );

      final customerName =
          _string(
            invoiceData['customerName'] ??
                invoiceData['customer'],
            'عميل نقدي',
          );

      if (sale.totalAmount <= 0) {
        throw Exception(
          'إجمالي الفاتورة يجب أن يكون أكبر من صفر',
        );
      }

      final products =
          await isar.inventoryModels.where().findAll();

      await isar.writeTxn(() async {
        // --------------------------------------------------------
        // 1. إعادة مخزون الفاتورة القديمة
        // --------------------------------------------------------

        for (final oldItem in oldSale.items) {
          final productName =
              oldItem.productName?.trim() ?? '';

          if (productName.isEmpty) continue;

          for (final product in products) {
            if (product.name.trim() == productName) {
              product.qty += oldItem.qty;

              await isar.inventoryModels.put(
                product,
              );

              break;
            }
          }
        }

        // --------------------------------------------------------
        // 2. حذف القيود القديمة
        // --------------------------------------------------------

        await _deleteLedgerByReference(
          isar,
          oldInvoiceNo,
        );

        // --------------------------------------------------------
        // 3. حساب تكلفة الفاتورة الجديدة
        // --------------------------------------------------------

        double totalCogs = 0.0;

        for (final item in sale.items) {
          final productName =
              item.productName?.trim() ?? '';

          if (productName.isEmpty) {
            throw Exception(
              'يوجد صنف بدون اسم',
            );
          }

          if (item.qty <= 0) {
            throw Exception(
              'كمية المنتج غير صحيحة: $productName',
            );
          }

          InventoryModel? product;

          for (final p in products) {
            if (p.name.trim() == productName) {
              product = p;
              break;
            }
          }

          if (product == null) {
            throw Exception(
              'المنتج غير موجود: $productName',
            );
          }

          if (product.qty < item.qty) {
            throw Exception(
              'الكمية غير كافية للمنتج: $productName',
            );
          }

          totalCogs +=
              product.cost * item.qty;
        }

        // --------------------------------------------------------
        // 4. حفظ الفاتورة
        // --------------------------------------------------------

        sale.invoiceNo = invoiceNo;
        sale.customerName = customerName;

        await isar.saleModels.put(sale);

        // --------------------------------------------------------
        // 5. قيد المبيعات
        // --------------------------------------------------------

        final debitAccount =
            _isCashPayment(paymentType)
                ? cashAccount
                : customerAccount;

        final saleDebit =
            LedgerModel(
          date: sale.date ?? _now(),
          description:
              'تعديل فاتورة مبيعات رقم $invoiceNo',
          accountName: debitAccount,
          partyName: customerName,
          debit: sale.totalAmount,
          credit: 0.0,
          referenceNo: invoiceNo,
          paymentType: paymentType,
          entryType: 'مبيعات',
        );

        final saleCredit =
            LedgerModel(
          date: sale.date ?? _now(),
          description:
              'تعديل فاتورة مبيعات رقم $invoiceNo',
          accountName: salesAccount,
          partyName: customerName,
          debit: 0.0,
          credit: sale.totalAmount,
          referenceNo: invoiceNo,
          paymentType: paymentType,
          entryType: 'مبيعات',
        );

        await isar.ledgerModels.putAll([
          saleDebit,
          saleCredit,
        ]);

        // --------------------------------------------------------
        // 6. قيد تكلفة البضاعة
        // --------------------------------------------------------

        if (totalCogs > 0) {
          final cogsDebit =
              LedgerModel(
            date: sale.date ?? _now(),
            description:
                'تكلفة البضاعة - فاتورة $invoiceNo',
            accountName: cogsAccount,
            partyName: customerName,
            debit: totalCogs,
            credit: 0.0,
            referenceNo: invoiceNo,
            paymentType: paymentType,
            entryType: 'تكلفة مبيعات',
          );

          final inventoryCredit =
              LedgerModel(
            date: sale.date ?? _now(),
            description:
                'خروج مخزون - فاتورة $invoiceNo',
            accountName: inventoryAccount,
            partyName: customerName,
            debit: 0.0,
            credit: totalCogs,
            referenceNo: invoiceNo,
            paymentType: paymentType,
            entryType: 'تكلفة مبيعات',
          );

          await isar.ledgerModels.putAll([
            cogsDebit,
            inventoryCredit,
          ]);
        }

        // --------------------------------------------------------
        // 7. خصم المخزون الجديد
        // --------------------------------------------------------

        for (final item in sale.items) {
          final productName =
              item.productName?.trim() ?? '';

          if (productName.isEmpty) continue;

          for (final product in products) {
            if (product.name.trim() == productName) {
              product.qty -= item.qty;

              await isar.inventoryModels.put(
                product,
              );

              break;
            }
          }
        }

        // --------------------------------------------------------
        // 8. التحقق من التوازن
        // --------------------------------------------------------

        final allLedger =
            await isar.ledgerModels
                .where()
                .findAll();

        final invoiceEntries =
            allLedger
                .where(
                  (e) =>
                      e.referenceNo ==
                      invoiceNo,
                )
                .toList();

        if (!_isBalanced(invoiceEntries)) {
          throw Exception(
            'القيد بعد تعديل الفاتورة غير متوازن',
          );
        }
      });

      return true;
    } catch (e) {
      print('PUT Sales Error: $e');

      throw Exception(
        'فشل تعديل الفاتورة وترحيلها محاسبياً: $e',
      );
    }
  }

  // ============================================================
  // حذف فاتورة مبيعات
  // ============================================================

  Future<bool> deleteSaleInvoice(
    int id,
  ) async {
    try {
      final isar = _isar;

      if (isar == null) return false;

      final sale =
          await isar.saleModels.get(id);

      if (sale == null) {
        return false;
      }

      await isar.writeTxn(() async {
        // إعادة الكميات للمخزون.
        for (final item in sale.items) {
          final productName =
              item.productName?.trim() ?? '';

          if (productName.isEmpty) continue;

          final product =
              await _findProductByName(
            isar,
            productName,
          );

          if (product != null) {
            product.qty += item.qty;

            await isar.inventoryModels.put(
              product,
            );
          }
        }

        // حذف جميع القيود المرتبطة بالفاتورة.
        await _deleteLedgerByReference(
          isar,
          sale.invoiceNo,
        );

        // حذف الفاتورة.
        await isar.saleModels.delete(id);
      });

      return true;
    } catch (e) {
      print('DELETE Sales Error: $e');

      throw Exception(
        'فشل حذف الفاتورة وعكس قيودها ومخزونها: $e',
      );
    }
  }

  // ============================================================
  // 3. المشتريات
  //
  // شراء نقدي:
  // مدين المخزون
  // دائن الصندوق
  //
  // شراء آجل:
  // مدين المخزون
  // دائن الموردين
  // ============================================================

  Future<bool> savePurchaseInvoice(
    Map<String, dynamic> purchaseData,
  ) async {
    try {
      final isar = _isar;

      if (isar == null) return false;

      final totalAmount =
          _toDouble(
        purchaseData['totalAmount'],
      );

      if (totalAmount <= 0) {
        throw Exception(
          'إجمالي المشتريات يجب أن يكون أكبر من صفر',
        );
      }

      final invoiceNo =
          _string(
            purchaseData['invoiceNo'],
          ).isNotEmpty
              ? _string(
                  purchaseData['invoiceNo'],
                )
              : _generateReference('PUR');

      final supplierName =
          _string(
            purchaseData['supplierName'],
            'مورد عام',
          );

      final paymentType =
          _string(
            purchaseData['paymentType'],
            'نقدي',
          );

      final date =
          _string(
            purchaseData['date'],
            _now(),
          );

      // ----------------------------------------------------------
      // منع تكرار رقم الفاتورة
      // ----------------------------------------------------------

      final existingLedger =
          await isar.ledgerModels.where().findAll();

      final duplicate =
          existingLedger.any(
        (e) =>
            e.referenceNo == invoiceNo,
      );

      if (duplicate) {
        throw Exception(
          'رقم فاتورة المشتريات مستخدم مسبقاً: $invoiceNo',
        );
      }

      // ----------------------------------------------------------
      // إضافة المخزون من items إن كانت موجودة
      // ----------------------------------------------------------

      final rawItems =
          purchaseData['items'];

      final products =
          await isar.inventoryModels.where().findAll();

      await isar.writeTxn(() async {
        // --------------------------------------------------------
        // المخزون - المتوسط المرجح
        // --------------------------------------------------------

        if (rawItems is List) {
          for (final rawItem in rawItems) {
            if (rawItem is! Map) continue;

            final productName =
                _string(
              rawItem['productName'] ??
                  rawItem['name'],
            );

            final qty =
                _toDouble(
              rawItem['qty'] ??
                  rawItem['quantity'],
            );

            final incomingCost =
                _toDouble(
              rawItem['cost'] ??
                  rawItem['unitCost'] ??
                  rawItem['purchasePrice'],
            );

            if (productName.isEmpty) {
              throw Exception(
                'يوجد صنف مشتريات بدون اسم',
              );
            }

            if (qty <= 0) {
              throw Exception(
                'كمية المشتريات يجب أن تكون أكبر من صفر: $productName',
              );
            }

            if (incomingCost < 0) {
              throw Exception(
                'تكلفة الشراء غير صحيحة: $productName',
              );
            }

            InventoryModel? product;

            for (final p in products) {
              if (p.name.trim() == productName) {
                product = p;
                break;
              }
            }

            if (product == null) {
              throw Exception(
                'المنتج غير موجود في المخزون: $productName',
              );
            }

            final oldQty =
                product.qty;

            final oldCost =
                product.cost;

            final newQty =
                oldQty + qty;

            final weightedCost =
                newQty > 0
                    ? ((oldQty * oldCost) +
                            (qty * incomingCost)) /
                        newQty
                    : incomingCost;

            product.qty = newQty;
            product.cost = weightedCost;

            await isar.inventoryModels.put(
              product,
            );
          }
        }

        // --------------------------------------------------------
        // تحديد الحساب الدائن
        // --------------------------------------------------------

        final creditAccount =
            _isCashPayment(paymentType)
                ? cashAccount
                : supplierAccount;

        // --------------------------------------------------------
        // قيد المشتريات
        // --------------------------------------------------------

        final debitEntry =
            LedgerModel(
          date: date,
          description:
              'فاتورة مشتريات رقم $invoiceNo',
          accountName: inventoryAccount,
          partyName: supplierName,
          debit: totalAmount,
          credit: 0.0,
          referenceNo: invoiceNo,
          paymentType: paymentType,
          entryType: 'مشتريات',
        );

        final creditEntry =
            LedgerModel(
          date: date,
          description:
              'فاتورة مشتريات رقم $invoiceNo',
          accountName: creditAccount,
          partyName: supplierName,
          debit: 0.0,
          credit: totalAmount,
          referenceNo: invoiceNo,
          paymentType: paymentType,
          entryType: 'مشتريات',
        );

        await isar.ledgerModels.putAll([
          debitEntry,
          creditEntry,
        ]);

        final allLedger =
            await isar.ledgerModels
                .where()
                .findAll();

        final purchaseEntries =
            allLedger
                .where(
                  (e) =>
                      e.referenceNo ==
                      invoiceNo,
                )
                .toList();

        if (!_isBalanced(purchaseEntries)) {
          throw Exception(
            'قيد المشتريات غير متوازن',
          );
        }
      });

      return true;
    } catch (e) {
      print('Purchase Ledger Error: $e');

      throw Exception(
        'فشل حفظ المشتريات وترحيلها محاسبياً: $e',
      );
    }
  }

  // ============================================================
  // 4. التقارير المالية
  //
  // الربح:
  // المبيعات - تكلفة المبيعات - المصروفات
  //
  // لا نحسب تكلفة المبيعات من تكلفة المخزون الحالية.
  // نعتمد على قيود COGS التي تم ترحيلها وقت البيع.
  // ============================================================

  Future<Map<String, dynamic>>
      getFinancialReports() async {
    try {
      final isar = _isar;

      if (isar == null) {
        return {
          'totalCost': 0.0,
          'totalInventory': 0.0,
          'totalSales': 0.0,
          'totalCogs': 0.0,
          'totalExpenses': 0.0,
          'grossProfit': 0.0,
          'netProfit': 0.0,
          'totalReceivables': 0.0,
          'totalPayables': 0.0,
          'totalCash': 0.0,
        };
      }

      final inventory =
          await isar.inventoryModels.where().findAll();

      final ledger =
          await isar.ledgerModels.where().findAll();

      // ----------------------------------------------------------
      // قيمة المخزون الحالي
      // ----------------------------------------------------------

      double totalInventory = 0.0;

      for (final item in inventory) {
        totalInventory +=
            item.qty * item.cost;
      }

      // ----------------------------------------------------------
      // إجمالي المبيعات
      // ----------------------------------------------------------

      double totalSales = 0.0;

      for (final entry in ledger) {
        if (entry.accountName == salesAccount) {
          totalSales += entry.credit;
        }
      }

      // ----------------------------------------------------------
      // تكلفة البضاعة المباعة
      // ----------------------------------------------------------

      double totalCogs = 0.0;

      for (final entry in ledger) {
        if (entry.accountName == cogsAccount) {
          totalCogs += entry.debit;
        }
      }

      // ----------------------------------------------------------
      // المصروفات
      // ----------------------------------------------------------

      double totalExpenses = 0.0;

      for (final entry in ledger) {
        if (entry.accountName == expenseAccount &&
            entry.debit > 0) {
          totalExpenses += entry.debit;
        }
      }

      // ----------------------------------------------------------
      // مجمل الربح
      // ----------------------------------------------------------

      final grossProfit =
          totalSales - totalCogs;

      // ----------------------------------------------------------
      // صافي الربح
      // ----------------------------------------------------------

      final netProfit =
          grossProfit - totalExpenses;

      // ----------------------------------------------------------
      // العملاء - المدين ناقص الدائن
      // ----------------------------------------------------------

      double totalReceivables = 0.0;

      for (final entry in ledger) {
        if (entry.accountName ==
            customerAccount) {
          totalReceivables +=
              entry.debit -
                  entry.credit;
        }
      }

      // ----------------------------------------------------------
      // الموردون - الدائن ناقص المدين
      // ----------------------------------------------------------

      double totalPayables = 0.0;

      for (final entry in ledger) {
        if (entry.accountName ==
            supplierAccount) {
          totalPayables +=
              entry.credit -
                  entry.debit;
        }
      }

      // ----------------------------------------------------------
      // الصندوق - المدين ناقص الدائن
      // ----------------------------------------------------------

      double totalCash = 0.0;

      for (final entry in ledger) {
        if (entry.accountName ==
            cashAccount) {
          totalCash +=
              entry.debit -
                  entry.credit;
        }
      }

      return {
        'totalCost': totalInventory,
        'totalInventory': totalInventory,
        'totalSales': totalSales,
        'totalCogs': totalCogs,
        'totalExpenses': totalExpenses,
        'grossProfit': grossProfit,
        'netProfit': netProfit,
        'totalReceivables': totalReceivables,
        'totalPayables': totalPayables,
        'totalCash': totalCash,
      };
    } catch (e) {
      print('GET Financial Reports Error: $e');

      return {
        'totalCost': 0.0,
        'totalInventory': 0.0,
        'totalSales': 0.0,
        'totalCogs': 0.0,
        'totalExpenses': 0.0,
        'grossProfit': 0.0,
        'netProfit': 0.0,
        'totalReceivables': 0.0,
        'totalPayables': 0.0,
        'totalCash': 0.0,
      };
    }
  }

  // ============================================================
  // 5. الموردون
  // ============================================================

  Future<List<SupplierModel>> getSuppliers() async {
    try {
      final isar = _isar;

      if (isar == null) return [];

      return await isar.supplierModels.where().findAll();
    } catch (e) {
      print('GET Suppliers Error: $e');
      return [];
    }
  }

  Future<List<dynamic>> getSupplierLedger(
    dynamic supplierIdentifier,
  ) async {
    try {
      final isar = _isar;

      if (isar == null) return [];

      final search =
          supplierIdentifier.toString().trim();

      if (search.isEmpty) return [];

      final entries =
          await isar.ledgerModels.where().findAll();

      return entries.where((entry) {
        final party =
            entry.partyName?.trim() ?? '';

        return party == search ||
            party.contains(search);
      }).toList();
    } catch (e) {
      print('Supplier Ledger Error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>>
      getSupplierBalance(
    String supplierName,
  ) async {
    final entries =
        await getSupplierLedger(
      supplierName,
    );

    double debit = 0.0;
    double credit = 0.0;

    for (final item in entries) {
      debit += item.debit;
      credit += item.credit;
    }

    final balance =
        credit - debit;

    return {
      'name': supplierName,
      'totalDebit': debit,
      'totalCredit': credit,
      'balance': balance,
      'isCreditor': balance > 0,
      'isDebtor': balance < 0,
    };
  }

  Future<bool> createSupplier(
    SupplierModel supplier,
  ) async {
    try {
      final isar = _isar;

      if (isar == null) return false;

      if (supplier.name.trim().isEmpty) {
        throw Exception('اسم المورد مطلوب');
      }

      await isar.writeTxn(() async {
        await isar.supplierModels.put(
          supplier,
        );
      });

      return true;
    } catch (e) {
      print('POST Supplier Error: $e');

      throw Exception(
        'فشل حفظ المورد: $e',
      );
    }
  }

  Future<bool> updateSupplier(
    int id,
    SupplierModel supplier,
  ) async {
    try {
      final isar = _isar;

      if (isar == null) return false;

      supplier.id = id;

      await isar.writeTxn(() async {
        await isar.supplierModels.put(
          supplier,
        );
      });

      return true;
    } catch (e) {
      print('PUT Supplier Error: $e');

      throw Exception(
        'فشل تعديل المورد: $e',
      );
    }
  }

  Future<bool> deleteSupplier(
    int id,
  ) async {
    try {
      final isar = _isar;

      if (isar == null) return false;

      await isar.writeTxn(() async {
        await isar.supplierModels.delete(id);
      });

      return true;
    } catch (e) {
      print('DELETE Supplier Error: $e');

      throw Exception(
        'فشل حذف المورد: $e',
      );
    }
  }

  // ============================================================
  // 6. السندات
  //
  // سند قبض:
  // مدين الصندوق/البنك
  // دائن العملاء
  //
  // سند صرف:
  // مدين الموردين
  // دائن الصندوق/البنك
  // ============================================================

  Future<List<VoucherModel>> getVouchers({
    String? type,
  }) async {
    try {
      final isar = _isar;

      if (isar == null) return [];

      final vouchers =
          await isar.voucherModels.where().findAll();

      if (type != null &&
          type.trim().isNotEmpty) {
        return vouchers
            .where(
              (v) => v.type == type,
            )
            .toList();
      }

      return vouchers;
    } catch (e) {
      print('GET Vouchers Error: $e');
      return [];
    }
  }

  Future<bool> createVoucher(
    VoucherModel voucher,
  ) async {
    try {
      final isar = _isar;

      if (isar == null) return false;

      if (voucher.amount <= 0) {
        throw Exception(
          'مبلغ السند يجب أن يكون أكبر من صفر',
        );
      }

      final type =
          (voucher.type ?? 'قبض').trim();

      final isReceipt =
          type == 'قبض';

      final partyName =
          _string(
            voucher.partyName,
            'عام',
          );

      final paymentMethod =
          _string(
            voucher.paymentMethod,
            'نقدي',
          );

      final referenceNo =
          _string(
            voucher.serialNo,
          ).isNotEmpty
              ? _string(
                  voucher.serialNo,
                )
              : _generateReference('VCH');

      final date =
          voucher.date ?? _now();

      final cashBankAccount =
          _cashOrBankAccount(
            paymentMethod,
          );

      await isar.writeTxn(() async {
        // --------------------------------------------------------
        // منع تكرار رقم السند
        // --------------------------------------------------------

        final allVouchers =
            await isar.voucherModels
                .where()
                .findAll();

        final duplicate =
            allVouchers.any(
          (v) =>
              v.serialNo == referenceNo,
        );

        if (duplicate) {
          throw Exception(
            'رقم السند موجود مسبقاً: $referenceNo',
          );
        }

        // --------------------------------------------------------
        // حفظ السند
        // --------------------------------------------------------

        final voucherToSave =
            VoucherModel(
          serialNo: referenceNo,
          type: type,
          partyName: partyName,
          amount: voucher.amount,
          paymentMethod: paymentMethod,
          note: voucher.note,
          date: date,
        );

        await isar.voucherModels.put(
          voucherToSave,
        );

        // --------------------------------------------------------
        // قيد السند
        // --------------------------------------------------------

        final LedgerModel debitEntry;
        final LedgerModel creditEntry;

        if (isReceipt) {
          // قبض
          debitEntry =
              LedgerModel(
            date: date,
            description:
                voucher.note ??
                    'سند قبض رقم $referenceNo',
            accountName:
                cashBankAccount,
            partyName: partyName,
            debit: voucher.amount,
            credit: 0.0,
            referenceNo: referenceNo,
            paymentType: paymentMethod,
            entryType: 'سند قبض',
          );

          creditEntry =
              LedgerModel(
            date: date,
            description:
                voucher.note ??
                    'سند قبض رقم $referenceNo',
            accountName:
                customerAccount,
            partyName: partyName,
            debit: 0.0,
            credit: voucher.amount,
            referenceNo: referenceNo,
            paymentType: paymentMethod,
            entryType: 'سند قبض',
          );
        } else {
          // صرف
          debitEntry =
              LedgerModel(
            date: date,
            description:
                voucher.note ??
                    'سند صرف رقم $referenceNo',
            accountName:
                supplierAccount,
            partyName: partyName,
            debit: voucher.amount,
            credit: 0.0,
            referenceNo: referenceNo,
            paymentType: paymentMethod,
            entryType: 'سند صرف',
          );

          creditEntry =
              LedgerModel(
            date: date,
            description:
                voucher.note ??
                    'سند صرف رقم $referenceNo',
            accountName:
                cashBankAccount,
            partyName: partyName,
            debit: 0.0,
            credit: voucher.amount,
            referenceNo: referenceNo,
            paymentType: paymentMethod,
            entryType: 'سند صرف',
          );
        }

        await isar.ledgerModels.putAll([
          debitEntry,
          creditEntry,
        ]);

        // --------------------------------------------------------
        // التأكد من التوازن
        // --------------------------------------------------------

        final entries =
            await isar.ledgerModels
                .where()
                .findAll();

        final voucherEntries =
            entries
                .where(
                  (e) =>
                      e.referenceNo ==
                      referenceNo,
                )
                .toList();

        if (!_isBalanced(voucherEntries)) {
          throw Exception(
            'قيد السند غير متوازن',
          );
        }
      });

      return true;
    } catch (e) {
      print('POST Voucher Error: $e');

      throw Exception(
        'فشل حفظ السند وترحيله محاسبياً: $e',
      );
    }
  }

  // ============================================================
  // تعديل السند
  // ============================================================

  Future<bool> updateVoucher(
    int id,
    VoucherModel voucher,
  ) async {
    try {
      final isar = _isar;

      if (isar == null) return false;

      final oldVoucher =
          await isar.voucherModels.get(id);

      if (oldVoucher == null) {
        throw Exception(
          'السند المطلوب تعديله غير موجود',
        );
      }

      if (voucher.amount <= 0) {
        throw Exception(
          'مبلغ السند يجب أن يكون أكبر من صفر',
        );
      }

      final referenceNo =
          _string(
            voucher.serialNo,
          ).isNotEmpty
              ? _string(
                  voucher.serialNo,
                )
              : oldVoucher.serialNo ??
                  _generateReference('VCH');

      final type =
          (voucher.type ?? 'قبض').trim();

      final isReceipt =
          type == 'قبض';

      final partyName =
          _string(
            voucher.partyName,
            'عام',
          );

      final paymentMethod =
          _string(
            voucher.paymentMethod,
            'نقدي',
          );

      final cashBankAccount =
          _cashOrBankAccount(
            paymentMethod,
          );

      final date =
          voucher.date ?? _now();

      await isar.writeTxn(() async {
        // حذف القيد القديم.
        await _deleteLedgerByReference(
          isar,
          oldVoucher.serialNo,
        );

        // حفظ السند الجديد.
        final updatedVoucher =
            VoucherModel(
          serialNo: referenceNo,
          type: type,
          partyName: partyName,
          amount: voucher.amount,
          paymentMethod: paymentMethod,
          note: voucher.note,
          date: date,
        );

        updatedVoucher.id = id;

        await isar.voucherModels.put(
          updatedVoucher,
        );

        // إنشاء القيد الجديد.
        final LedgerModel debitEntry;
        final LedgerModel creditEntry;

        if (isReceipt) {
          debitEntry =
              LedgerModel(
            date: date,
            description:
                voucher.note ??
                    'سند قبض رقم $referenceNo',
            accountName:
                cashBankAccount,
            partyName: partyName,
            debit: voucher.amount,
            credit: 0.0,
            referenceNo: referenceNo,
            paymentType: paymentMethod,
            entryType: 'سند قبض',
          );

          creditEntry =
              LedgerModel(
            date: date,
            description:
                voucher.note ??
                    'سند قبض رقم $referenceNo',
            accountName:
                customerAccount,
            partyName: partyName,
            debit: 0.0,
            credit: voucher.amount,
            referenceNo: referenceNo,
            paymentType: paymentMethod,
            entryType: 'سند قبض',
          );
        } else {
          debitEntry =
              LedgerModel(
            date: date,
            description:
                voucher.note ??
                    'سند صرف رقم $referenceNo',
            accountName:
                supplierAccount,
            partyName: partyName,
            debit: voucher.amount,
            credit: 0.0,
            referenceNo: referenceNo,
            paymentType: paymentMethod,
            entryType: 'سند صرف',
          );

          creditEntry =
              LedgerModel(
            date: date,
            description:
                voucher.note ??
                    'سند صرف رقم $referenceNo',
            accountName:
                cashBankAccount,
            partyName: partyName,
            debit: 0.0,
            credit: voucher.amount,
            referenceNo: referenceNo,
            paymentType: paymentMethod,
            entryType: 'سند صرف',
          );
        }

        await isar.ledgerModels.putAll([
          debitEntry,
          creditEntry,
        ]);
      });

      return true;
    } catch (e) {
      print('PUT Voucher Error: $e');

      throw Exception(
        'فشل تعديل السند وترحيله محاسبياً: $e',
      );
    }
  }

  // ============================================================
  // حذف السند
  // ============================================================

  Future<bool> deleteVoucher(
    int id,
  ) async {
    try {
      final isar = _isar;

      if (isar == null) return false;

      final voucher =
          await isar.voucherModels.get(id);

      if (voucher == null) {
        return false;
      }

      await isar.writeTxn(() async {
        await _deleteLedgerByReference(
          isar,
          voucher.serialNo,
        );

        await isar.voucherModels.delete(id);
      });

      return true;
    } catch (e) {
      print('DELETE Voucher Error: $e');

      throw Exception(
        'فشل حذف السند وقيده المحاسبي: $e',
      );
    }
  }

  // ============================================================
  // 7. المصاريف
  //
  // مدين المصاريف
  // دائن الصندوق
  // ============================================================

  Future<List<ExpenseModel>> getExpenses() async {
    try {
      final isar = _isar;

      if (isar == null) return [];

      return await isar.expenseModels.where().findAll();
    } catch (e) {
      print('GET Expenses Error: $e');
      return [];
    }
  }

  Future<bool> createExpense(
    ExpenseModel expense,
  ) async {
    try {
      final isar = _isar;

      if (isar == null) return false;

      if (expense.amount <= 0) {
        throw Exception(
          'مبلغ المصروف يجب أن يكون أكبر من صفر',
        );
      }

      await isar.writeTxn(() async {
        // حفظ المصروف أولاً.
        await isar.expenseModels.put(
          expense,
        );

        // مرجع ثابت يعتمد على ID.
        final referenceNo =
            'EXP-${expense.id}';

        final title =
            _string(
              expense.title,
              'مصروف عام',
            );

        final description =
            _string(
              expense.notes,
            ).isEmpty
                ? 'مصروف: $title'
                : 'مصروف: $title - ${expense.notes}';

        final debitEntry =
            LedgerModel(
          date: expense.date ?? _now(),
          description: description,
          accountName: expenseAccount,
          partyName: title,
          debit: expense.amount,
          credit: 0.0,
          referenceNo: referenceNo,
          paymentType: 'نقدي',
          entryType: 'مصروفات',
        );

        final creditEntry =
            LedgerModel(
          date: expense.date ?? _now(),
          description: description,
          accountName: cashAccount,
          partyName: title,
          debit: 0.0,
          credit: expense.amount,
          referenceNo: referenceNo,
          paymentType: 'نقدي',
          entryType: 'مصروفات',
        );

        await isar.ledgerModels.putAll([
          debitEntry,
          creditEntry,
        ]);
      });

      return true;
    } catch (e) {
      print('POST Expense Error: $e');

      throw Exception(
        'فشل حفظ المصروف وترحيله محاسبياً: $e',
      );
    }
  }

  // ============================================================
  // تعديل المصروف
  // ============================================================

  Future<bool> updateExpense(
    int id,
    ExpenseModel updatedExpense,
  ) async {
    try {
      final isar = _isar;

      if (isar == null) return false;

      if (updatedExpense.amount <= 0) {
        throw Exception(
          'مبلغ المصروف يجب أن يكون أكبر من صفر',
        );
      }

      final referenceNo =
          'EXP-$id';

      await isar.writeTxn(() async {
        // حذف القيد القديم.
        await _deleteLedgerByReference(
          isar,
          referenceNo,
        );

        // تحديث المصروف.
        updatedExpense.id = id;

        await isar.expenseModels.put(
          updatedExpense,
        );

        final title =
            _string(
              updatedExpense.title,
              'مصروف عام',
            );

        final description =
            _string(
              updatedExpense.notes,
            ).isEmpty
                ? 'مصروف: $title'
                : 'مصروف: $title - ${updatedExpense.notes}';

        final debitEntry =
            LedgerModel(
          date:
              updatedExpense.date ?? _now(),
          description: description,
          accountName: expenseAccount,
          partyName: title,
          debit: updatedExpense.amount,
          credit: 0.0,
          referenceNo: referenceNo,
          paymentType: 'نقدي',
          entryType: 'مصروفات',
        );

        final creditEntry =
            LedgerModel(
          date:
              updatedExpense.date ?? _now(),
          description: description,
          accountName: cashAccount,
          partyName: title,
          debit: 0.0,
          credit: updatedExpense.amount,
          referenceNo: referenceNo,
          paymentType: 'نقدي',
          entryType: 'مصروفات',
        );

        await isar.ledgerModels.putAll([
          debitEntry,
          creditEntry,
        ]);
      });

      return true;
    } catch (e) {
      print('PUT Expense Error: $e');

      throw Exception(
        'فشل تعديل المصروف وقيده المحاسبي: $e',
      );
    }
  }

  // ============================================================
  // حذف المصروف
  // ============================================================

  Future<bool> deleteExpense(
    int id,
  ) async {
    try {
      final isar = _isar;

      if (isar == null) return false;

      final expense =
          await isar.expenseModels.get(id);

      if (expense == null) {
        return false;
      }

      final referenceNo =
          'EXP-$id';

      await isar.writeTxn(() async {
        await _deleteLedgerByReference(
          isar,
          referenceNo,
        );

        await isar.expenseModels.delete(id);
      });

      return true;
    } catch (e) {
      print('DELETE Expense Error: $e');

      throw Exception(
        'فشل حذف المصروف وقيده المحاسبي: $e',
      );
    }
  }

  // ============================================================
  // 8. دفتر الأستاذ
  // ============================================================

  Future<List<LedgerModel>>
      getLedgerEntries() async {
    try {
      final isar = _isar;

      if (isar == null) return [];

      final entries =
          await isar.ledgerModels.where().findAll();

      // الأحدث أولاً.
      entries.sort(
        (a, b) =>
            (b.date ?? '')
                .compareTo(a.date ?? ''),
      );

      return entries;
    } catch (e) {
      print('GET Ledger Error: $e');

      throw Exception(
        'فشل جلب دفتر الأستاذ: $e',
      );
    }
  }

  Future<bool> createLedgerEntry(
    LedgerModel ledger,
  ) async {
    try {
      final isar = _isar;

      if (isar == null) return false;

      if (ledger.debit < 0 ||
          ledger.credit < 0) {
        throw Exception(
          'القيم المدينة والدائنة لا يمكن أن تكون سالبة',
        );
      }

      if (ledger.debit == 0 &&
          ledger.credit == 0) {
        throw Exception(
          'يجب إدخال مبلغ مدين أو دائن',
        );
      }

      if (ledger.debit > 0 &&
          ledger.credit > 0) {
        throw Exception(
          'القيد يجب أن يكون مديناً أو دائناً وليس الاثنين في السطر نفسه',
        );
      }

      await isar.writeTxn(() async {
        await isar.ledgerModels.put(
          ledger,
        );
      });

      return true;
    } catch (e) {
      print('POST Ledger Error: $e');

      throw Exception(
        'فشل حفظ القيد: $e',
      );
    }
  }

  Future<bool> updateLedgerEntry(
    int id,
    LedgerModel ledger,
  ) async {
    try {
      final isar = _isar;

      if (isar == null) return false;

      if (ledger.debit < 0 ||
          ledger.credit < 0) {
        throw Exception(
          'القيم لا يمكن أن تكون سالبة',
        );
      }

      ledger.id = id;

      await isar.writeTxn(() async {
        await isar.ledgerModels.put(
          ledger,
        );
      });

      return true;
    } catch (e) {
      print('PUT Ledger Error: $e');

      throw Exception(
        'فشل تعديل القيد: $e',
      );
    }
  }

  Future<bool> deleteLedgerEntry(
    int id,
  ) async {
    try {
      final isar = _isar;

      if (isar == null) return false;

      await isar.writeTxn(() async {
        await isar.ledgerModels.delete(id);
      });

      return true;
    } catch (e) {
      print('DELETE Ledger Error: $e');

      throw Exception(
        'فشل حذف القيد: $e',
      );
    }
  }

  // ============================================================
  // البحث في دفتر الأستاذ
  // ============================================================

  Future<List<LedgerModel>> searchLedger({
    String? query,
    String? referenceNo,
    String? partyName,
    String? accountName,
  }) async {
    try {
      final isar = _isar;

      if (isar == null) return [];

      final entries =
          await isar.ledgerModels.where().findAll();

      final q =
          (query ?? '').trim().toLowerCase();

      final ref =
          (referenceNo ?? '').trim().toLowerCase();

      final party =
          (partyName ?? '').trim().toLowerCase();

      final account =
          (accountName ?? '').trim().toLowerCase();

      return entries.where((entry) {
        final description =
            (entry.description ?? '')
                .toLowerCase();

        final entryReference =
            (entry.referenceNo ?? '')
                .toLowerCase();

        final entryParty =
            (entry.partyName ?? '')
                .toLowerCase();

        final entryAccount =
            (entry.accountName ?? '')
                .toLowerCase();

        if (q.isNotEmpty) {
          final found =
              description.contains(q) ||
                  entryReference.contains(q) ||
                  entryParty.contains(q) ||
                  entryAccount.contains(q);

          if (!found) return false;
        }

        if (ref.isNotEmpty &&
            !entryReference.contains(ref)) {
          return false;
        }

        if (party.isNotEmpty &&
            !entryParty.contains(party)) {
          return false;
        }

        if (account.isNotEmpty &&
            !entryAccount.contains(account)) {
          return false;
        }

        return true;
      }).toList();
    } catch (e) {
      print('SEARCH Ledger Error: $e');
      return [];
    }
  }

  // ============================================================
  // كشف حساب عميل / مورد
  // ============================================================

  Future<Map<String, dynamic>>
      getPartyAccountStatement(
    String partyName,
  ) async {
    try {
      final isar = _isar;

      if (isar == null) {
        return {
          'entries': <LedgerModel>[],
          'totalDebit': 0.0,
          'totalCredit': 0.0,
          'balance': 0.0,
        };
      }

      final search =
          partyName.trim();

      final allEntries =
          await isar.ledgerModels.where().findAll();

      final entries =
          allEntries.where((entry) {
        return (entry.partyName ?? '').trim() ==
            search;
      }).toList();

      entries.sort(
        (a, b) =>
            (a.date ?? '')
                .compareTo(b.date ?? ''),
      );

      double totalDebit = 0.0;
      double totalCredit = 0.0;

      for (final entry in entries) {
        totalDebit += entry.debit;
        totalCredit += entry.credit;
      }

      return {
        'entries': entries,
        'totalDebit': totalDebit,
        'totalCredit': totalCredit,
        'balance':
            totalDebit - totalCredit,
      };
    } catch (e) {
      print('Party Statement Error: $e');

      return {
        'entries': <LedgerModel>[],
        'totalDebit': 0.0,
        'totalCredit': 0.0,
        'balance': 0.0,
      };
    }
  }

  // ============================================================
  // كشف حساب العميل
  // ============================================================

  Future<Map<String, dynamic>>
      getCustomerBalance(
    String customerName,
  ) async {
    final statement =
        await getPartyAccountStatement(
      customerName,
    );

    final debit =
        _toDouble(
      statement['totalDebit'],
    );

    final credit =
        _toDouble(
      statement['totalCredit'],
    );

    // العميل مدين إذا كان المدين أكبر من الدائن.
    final balance =
        debit - credit;

    return {
      'customerName': customerName,
      'totalDebit': debit,
      'totalCredit': credit,
      'balance': balance,
      'isDebtor': balance > 0,
      'isCreditor': balance < 0,
    };
  }

  // ============================================================
  // كشف حساب المورد
  // ============================================================

  Future<Map<String, dynamic>>
      getSupplierAccountStatement(
    String supplierName,
  ) async {
    final statement =
        await getPartyAccountStatement(
      supplierName,
    );

    final debit =
        _toDouble(
      statement['totalDebit'],
    );

    final credit =
        _toDouble(
      statement['totalCredit'],
    );

    // المورد دائن إذا كان الدائن أكبر من المدين.
    final balance =
        credit - debit;

    return {
      'supplierName': supplierName,
      'totalDebit': debit,
      'totalCredit': credit,
      'balance': balance,
      'isCreditor': balance > 0,
      'isDebtor': balance < 0,
    };
  }

  // ============================================================
  // التحقق من توازن دفتر الأستاذ بالكامل
  // ============================================================

  Future<Map<String, dynamic>>
      checkLedgerBalance() async {
    try {
      final isar = _isar;

      if (isar == null) {
        return {
          'isBalanced': true,
          'totalDebit': 0.0,
          'totalCredit': 0.0,
          'difference': 0.0,
        };
      }

      final entries =
          await isar.ledgerModels.where().findAll();

      double totalDebit = 0.0;
      double totalCredit = 0.0;

      for (final entry in entries) {
        totalDebit += entry.debit;
        totalCredit += entry.credit;
      }

      final difference =
          totalDebit - totalCredit;

      return {
        'isBalanced':
            difference.abs() < 0.0001,
        'totalDebit': totalDebit,
        'totalCredit': totalCredit,
        'difference': difference,
      };
    } catch (e) {
      print('Ledger Balance Error: $e');

      return {
        'isBalanced': false,
        'totalDebit': 0.0,
        'totalCredit': 0.0,
        'difference': 0.0,
      };
    }
  }
}

