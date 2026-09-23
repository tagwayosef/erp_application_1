import 'package:isar/isar.dart';
import '../model/inventory_model.dart';
import '../model/expense_model.dart';
import '../model/supplier_model.dart';
import '../model/ledger_model.dart';
import '../model/voucher_model.dart';
import '../model/sale_model.dart';

class ApiService {
  // ============================================================
  // 1. دوال المخزون (Inventory)
  // ============================================================
  Future<List<InventoryModel>> getInventory() async {
    try {
      final isar = Isar.getInstance();
      if (isar == null) return [];
      return await isar.inventoryModels.where().findAll();
    } catch (e) {
      print('GET Inventory Error: $e');
      return [];
    }
  }

  Future<bool> updateProduct(int id, Map<String, dynamic> productData) async {
    try {
      final isar = Isar.getInstance();
      if (isar == null) return false;

      final updatedProduct = InventoryModel.fromJson(productData)..id = id;

      await isar.writeTxn(() async {
        await isar.inventoryModels.put(updatedProduct);
      });
      return true;
    } catch (e) {
      print('PUT Inventory Error: $e');
      throw Exception('فشل تحديث المنتج في قاعدة البيانات المحلية');
    }
  }

  Future<bool> saveProduct(InventoryModel product) async {
    try {
      final isar = Isar.getInstance();
      if (isar == null) return false;

      await isar.writeTxn(() async {
        await isar.inventoryModels.put(product);
      });
      return true;
    } catch (e) {
      print('POST Inventory Error: $e');
      throw Exception('فشل حفظ المنتج في قاعدة البيانات المحلية');
    }
  }

  Future<bool> deleteProduct(int id) async {
    try {
      final isar = Isar.getInstance();
      if (isar == null) return false;

      await isar.writeTxn(() async {
        await isar.inventoryModels.delete(id);
      });
      return true;
    } catch (e) {
      print('DELETE Inventory Error: $e');
      throw Exception('فشل حذف المنتج من قاعدة البيانات المحلية');
    }
  }

  Future<List<InventoryModel>> getCriticalStockAlerts() async {
    try {
      final inventory = await getInventory();
      return inventory.where((item) => item.qty <= item.min).toList();
    } catch (e) {
      print('GET Critical Stock Alerts Error: $e');
      return [];
    }
  }

  Future<InventoryModel?> getProductByBarcode(String barcode) async {
    try {
      final code = barcode.trim();
      if (code.isEmpty) return null;

      final inventory = await getInventory();
      try {
        return inventory.firstWhere(
          (product) => product.barcode != null && product.barcode!.trim() == code,
        );
      } catch (_) {
        return null;
      }
    } catch (e) {
      print('Barcode Search Error: $e');
      return null;
    }
  }

  // ============================================================
  // 2. دوال المبيعات (Sales - مع القيد المحاسبي الآلي)
  // ============================================================
  Future<List<dynamic>> getSales() async {
    try {
      final isar = Isar.getInstance();
      if (isar == null) return [];
      final sales = await isar.saleModels.where().findAll();
      return sales.map((s) => s.toJson()).toList();
    } catch (e) {
      print('GET Sales Error: $e');
      return [];
    }
  }

  Future<bool> saveSaleInvoice(Map<String, dynamic> invoiceData) async {
    try {
      final isar = Isar.getInstance();
      if (isar == null) return false;

      final sale = SaleModel.fromJson(invoiceData);
      await isar.writeTxn(() async {
        await isar.saleModels.put(sale);

        // توليد قيد مبيعات آلي في دفتر الأستاذ العام
        final ledgerEntry = LedgerModel(
          date: sale.date ?? DateTime.now().toIso8601String(),
          description: 'قيد مبيعات آلي للفاتورة رقم: ${sale.invoiceNo ?? ''}',
          accountName: 'المبيعات / العملاء (${sale.customerName ?? "نقدي"})',
          debit: sale.totalAmount,
          credit: 0.0,
          referenceNo: sale.invoiceNo,
        );
        await isar.ledgerModels.put(ledgerEntry);
      });
      return true;
    } catch (e) {
      print('POST Sales Error: $e');
      throw Exception('حدث خطأ أثناء حفظ الفاتورة وتوليد القيد محلياً: $e');
    }
  }

  Future<bool> updateSaleInvoice(int id, Map<String, dynamic> invoiceData) async {
    try {
      final isar = Isar.getInstance();
      if (isar == null) return false;

      final sale = SaleModel.fromJson(invoiceData)..id = id;
      await isar.writeTxn(() async {
        await isar.saleModels.put(sale);
      });
      return true;
    } catch (e) {
      print('PUT Sales Error: $e');
      throw Exception('فشل تعديل الفاتورة محلياً');
    }
  }

  Future<bool> deleteSaleInvoice(int id) async {
    try {
      final isar = Isar.getInstance();
      if (isar == null) return false;

      await isar.writeTxn(() async {
        await isar.saleModels.delete(id);
      });
      return true;
    } catch (e) {
      print('DELETE Sales Error: $e');
      throw Exception('فشل حذف الفاتورة محلياً');
    }
  }

  // ============================================================
  // دوال المشتريات (Purchases - مع القيد المحاسبي الآلي)
  // ============================================================
  Future<bool> savePurchaseInvoice(Map<String, dynamic> purchaseData) async {
    try {
      final isar = Isar.getInstance();
      if (isar == null) return false;

      await isar.writeTxn(() async {
        final totalAmount = (purchaseData['totalAmount'] as num?)?.toDouble() ?? 0.0;
        final invoiceNo = purchaseData['invoiceNo'] ?? 'PUR-${DateTime.now().millisecondsSinceEpoch}';
        final supplierName = purchaseData['supplierName'] ?? 'نقدي';

        // توليد قيد مشتريات آلي في دفتر الأستاذ العام
        final ledgerEntry = LedgerModel(
          date: DateTime.now().toIso8601String(),
          description: 'قيد مشتريات آلي للفاتورة رقم: $invoiceNo',
          accountName: 'المشتريات / الموردين ($supplierName)',
          debit: 0.0,
          credit: totalAmount,
          referenceNo: invoiceNo,
        );
        await isar.ledgerModels.put(ledgerEntry);
      });
      return true;
    } catch (e) {
      print('Purchase Ledger Error: $e');
      return false;
    }
  }

  // ============================================================
  // 3. دوال التقارير المالية والإحصائيات
  // ============================================================
  Future<Map<String, dynamic>> getFinancialReports() async {
    try {
      final isar = Isar.getInstance();
      if (isar == null) return {'totalCost': 0.0, 'totalSales': 0.0, 'netProfit': 0.0, 'totalExpenses': 0.0};

      final inventory = await isar.inventoryModels.where().findAll();
      final sales = await isar.saleModels.where().findAll();
      final expenses = await isar.expenseModels.where().findAll();

      double totalInventoryCost = 0.0;
      for (var item in inventory) {
        totalInventoryCost += (item.qty * item.cost);
      }

      final Map<String, double> productCosts = {};
      final Map<String, double> productPrices = {};
      for (var item in inventory) {
        if (item.name != null) {
          productCosts[item.name!.trim()] = item.cost;
          productPrices[item.name!.trim()] = item.price;
        }
        if (item.barcode != null) {
          productCosts[item.barcode!.trim()] = item.cost;
          productPrices[item.barcode!.trim()] = item.price;
        }
      }

      double totalSales = 0.0;
      double totalCogs = 0.0; 

      for (var sale in sales) {
        totalSales += sale.totalAmount;

        if (sale.items.isNotEmpty) {
          for (var saleItem in sale.items) {
            double unitCost = productCosts[saleItem.productName?.trim()] ?? 0.0;
            totalCogs += (unitCost * saleItem.qty);
          }
        } else {
          for (var detail in sale.itemsDetails) {
            double unitCost = 0.0;
            for (var entry in productCosts.entries) {
              if (detail.contains(entry.key)) {
                unitCost = entry.value;
                break;
              }
            }
            totalCogs += unitCost * 1.0;
          }
        }
      }

      double totalExpenses = 0.0;
      for (var expense in expenses) {
        totalExpenses += expense.amount;
      }

      double grossProfit = totalSales - totalCogs;
      double netProfit = grossProfit - totalExpenses;

      if (sales.isEmpty) {
        netProfit = 0.0;
      }

      return {
        'totalCost': totalInventoryCost,   
        'totalSales': totalSales,          
        'totalExpenses': totalExpenses,    
        'netProfit': netProfit,            
      };
    } catch (e) {
      print('GET Reports Error: $e');
      return {'totalCost': 0.0, 'totalSales': 0.0, 'netProfit': 0.0, 'totalExpenses': 0.0};
    }
  }

  // ============================================================
  // 4. دوال الموردين (Suppliers)
  // ============================================================
  Future<List<SupplierModel>> getSuppliers() async {
    try {
      final isar = Isar.getInstance();
      if (isar == null) return [];
      return await isar.supplierModels.where().findAll();
    } catch (e) {
      print('GET Suppliers Error: $e');
      return [];
    }
  }

  Future<List<dynamic>> getSupplierLedger(dynamic supplierIdentifier) async {
    try {
      final isar = Isar.getInstance();
      if (isar == null) return [];
      final entries = await isar.ledgerModels.where().findAll();
      return entries
          .where((e) => e.accountName != null && e.accountName!.contains(supplierIdentifier.toString()))
          .toList();
    } catch (e) {
      print('Supplier Ledger Error: $e');
      return [];
    }
  }

  Future<bool> createSupplier(SupplierModel supplier) async {
    try {
      final isar = Isar.getInstance();
      if (isar == null) return false;

      await isar.writeTxn(() async {
        await isar.supplierModels.put(supplier);
      });
      return true;
    } catch (e) {
      print('POST Supplier Error: $e');
      throw Exception('فشل حفظ المورد محلياً');
    }
  }

  Future<bool> updateSupplier(int id, SupplierModel supplier) async {
    try {
      final isar = Isar.getInstance();
      if (isar == null) return false;

      supplier.id = id;
      await isar.writeTxn(() async {
        await isar.supplierModels.put(supplier);
      });
      return true;
    } catch (e) {
      print('PUT Supplier Error: $e');
      throw Exception('فشل تعديل بيانات المورد محلياً');
    }
  }

  Future<bool> deleteSupplier(int id) async {
    try {
      final isar = Isar.getInstance();
      if (isar == null) return false;

      await isar.writeTxn(() async {
        await isar.supplierModels.delete(id);
      });
      return true;
    } catch (e) {
      print('DELETE Supplier Error: $e');
      throw Exception('فشل حذف المورد محلياً');
    }
  }

  // ============================================================
  // 5. دوال السندات (Vouchers - مع قيد محاسبي آلي)
  // ============================================================
  Future<List<VoucherModel>> getVouchers({String? type}) async {
    try {
      final isar = Isar.getInstance();
      if (isar == null) return [];

      final vouchers = await isar.voucherModels.where().findAll();
      if (type != null) {
        return vouchers.where((v) => v.type == type).toList();
      }
      return vouchers;
    } catch (e) {
      print('GET Vouchers Error: $e');
      return [];
    }
  }

  Future<bool> createVoucher(VoucherModel voucher) async {
    try {
      final isar = Isar.getInstance();
      if (isar == null) return false;

      await isar.writeTxn(() async {
        await isar.voucherModels.put(voucher);

        // توليد قيد آلي للسند في دفتر الأستاذ العام
        final ledgerEntry = LedgerModel(
          date: voucher.date ?? DateTime.now().toIso8601String(),
          description: voucher.note ?? 'سند ${voucher.type ?? "عام"}',
          accountName: voucher.partyName ?? 'الصندوق / البنك',
          debit: voucher.type == 'قبض' ? voucher.amount : 0.0,
          credit: voucher.type == 'صرف' ? voucher.amount : 0.0,
          referenceNo: 'VCH-${DateTime.now().millisecondsSinceEpoch}',
        );
        await isar.ledgerModels.put(ledgerEntry);
      });
      return true;
    } catch (e) {
      print('POST Voucher Error: $e');
      throw Exception('فشل حفظ السند محلياً');
    }
  }

  Future<bool> updateVoucher(int id, VoucherModel voucher) async {
    try {
      final isar = Isar.getInstance();
      if (isar == null) return false;

      voucher.id = id;
      await isar.writeTxn(() async {
        await isar.voucherModels.put(voucher);
      });
      return true;
    } catch (e) {
      print('PUT Voucher Error: $e');
      throw Exception('فشل تعديل السند محلياً');
    }
  }

  Future<bool> deleteVoucher(int id) async {
    try {
      final isar = Isar.getInstance();
      if (isar == null) return false;

      await isar.writeTxn(() async {
        await isar.voucherModels.delete(id);
      });
      return true;
    } catch (e) {
      print('DELETE Voucher Error: $e');
      throw Exception('فشل حذف السند محلياً');
    }
  }

  // ============================================================
  // 6. دوال المصاريف (Expenses - مع قيد محاسبي آلي)
  // ============================================================
  Future<List<ExpenseModel>> getExpenses() async {
    try {
      final isar = Isar.getInstance();
      if (isar == null) return [];
      return await isar.expenseModels.where().findAll();
    } catch (e) {
      print('GET Expenses Error: $e');
      return [];
    }
  }

  Future<bool> createExpense(ExpenseModel expense) async {
    try {
      final isar = Isar.getInstance();
      if (isar == null) return false;

      await isar.writeTxn(() async {
        await isar.expenseModels.put(expense);

        // توليد قيد مصروفات آلي في دفتر الأستاذ العام
        final ledgerEntry = LedgerModel(
          date: expense.date ?? DateTime.now().toIso8601String(),
          description: expense.description ?? 'مصروف: ${expense.category}',
          accountName: 'حساب المصاريف (${expense.category})',
          debit: expense.amount,
          credit: 0.0,
          referenceNo: 'EXP-${DateTime.now().millisecondsSinceEpoch}',
        );
        await isar.ledgerModels.put(ledgerEntry);
      });
      return true;
    } catch (e) {
      print('POST Expense Error: $e');
      throw Exception('فشل حفظ المصروف محلياً');
    }
  }

  Future<bool> updateExpense(int id, ExpenseModel updatedExpense) async {
    try {
      final isar = Isar.getInstance();
      if (isar == null) return false;

      updatedExpense.id = id;
      await isar.writeTxn(() async {
        await isar.expenseModels.put(updatedExpense);
      });
      return true;
    } catch (e) {
      print('PUT Expense Error: $e');
      throw Exception('فشل تعديل المصروف محلياً');
    }
  }

  Future<bool> deleteExpense(int id) async {
    try {
      final isar = Isar.getInstance();
      if (isar == null) return false;

      await isar.writeTxn(() async {
        await isar.expenseModels.delete(id);
      });
      return true;
    } catch (e) {
      print('DELETE Expense Error: $e');
      throw Exception('فشل حذف المصروف محلياً');
    }
  }

  // ============================================================
  // 7. دوال دفتر الأستاذ العام (General Ledger)
  // ============================================================
  Future<List<LedgerModel>> getLedgerEntries() async {
    try {
      final isar = Isar.getInstance();
      if (isar == null) return [];
      return await isar.ledgerModels.where().findAll();
    } catch (e) {
      print('GET Ledger Error: $e');
      return [];
    }
  }

  Future<bool> createLedgerEntry(LedgerModel ledger) async {
    try {
      final isar = Isar.getInstance();
      if (isar == null) return false;

      await isar.writeTxn(() async {
        await isar.ledgerModels.put(ledger);
      });
      return true;
    } catch (e) {
      print('POST Ledger Error: $e');
      throw Exception('فشل حفظ القيد في دفتر الأستاذ المحلي');
    }
  }

  Future<bool> updateLedgerEntry(int id, LedgerModel ledger) async {
    try {
      final isar = Isar.getInstance();
      if (isar == null) return false;

      ledger.id = id;
      await isar.writeTxn(() async {
        await isar.ledgerModels.put(ledger);
      });
      return true;
    } catch (e) {
      print('PUT Ledger Error: $e');
      throw Exception('فشل تعديل القيد المحاسبي محلياً');
    }
  }

  Future<bool> deleteLedgerEntry(int id) async {
    try {
      final isar = Isar.getInstance();
      if (isar == null) return false;

      await isar.writeTxn(() async {
        await isar.ledgerModels.delete(id);
      });
      return true;
    } catch (e) {
      print('DELETE Ledger Error: $e');
      throw Exception('فشل حذف القيد المحاسبي محلياً');
    }
  }
}