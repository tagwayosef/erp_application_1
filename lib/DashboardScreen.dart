
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

// ============================================================
// نماذج قاعدة البيانات المحلية
// ============================================================
import 'model/inventory_model.dart';
import 'model/sale_model.dart';
import 'model/expense_model.dart';
import 'model/voucher_model.dart';
import 'model/sales_return_model.dart';
// ============================================================
// الشاشات
// ============================================================
import 'inventory_management_screen.dart';
import 'SalesScreen.dart';
import 'SuppliersScreen.dart';
import 'VouchersScreen.dart';
import 'LedgerScreen.dart';
import 'ReportsScreen.dart';
import 'expensesscreen.dart';
import 'alertsscreen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ============================================================
  // حالة التحميل
  // ============================================================
  bool _isLoading = true;

  // ============================================================
  // بيانات لوحة التحكم
  // ============================================================

  int totalProducts = 0;

  // قيمة المخزون
  double inventoryValue = 0.0;

  // ------------------------------------------------------------
  // المبيعات النقدية
  // ------------------------------------------------------------
  double cashSalesTotal = 0.0;

  // ------------------------------------------------------------
  // المبيعات الآجلة
  // ------------------------------------------------------------
  double creditSalesTotal = 0.0;

  // ------------------------------------------------------------
  // إجمالي المبيعات = نقدي + آجل
  // ------------------------------------------------------------
  double totalRealizedSales = 0.0;

  // ------------------------------------------------------------
  // المبالغ المحصلة من العملاء
  // ------------------------------------------------------------
  double collectedFromCredit = 0.0;

  // ------------------------------------------------------------
  // المتبقي على العملاء
  // ------------------------------------------------------------
  double remainingCredit = 0.0;

  // ------------------------------------------------------------
  // صافي الربح النقدي فقط
  //
  // المبيعات الآجلة لا تدخل فيه
  // ------------------------------------------------------------
  double cashNetProfit = 0.0;

  // إجمالي المصروفات
  double totalExpenses = 0.0;

  // عدد التنبيهات
  int lowStockCount = 0;

  // أحدث المخزون
  List<InventoryModel> recentInventory = [];

  // ============================================================
  // بداية الشاشة
  // ============================================================
  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  // ============================================================
  // تحميل بيانات لوحة التحكم
  // ============================================================
 Future<void> _fetchDashboardData() async {
  if (mounted) {
    setState(() {
      _isLoading = true;
    });
  }

  try {
    // ----------------------------------------------------------
    // الحصول على قاعدة Isar
    // ----------------------------------------------------------
    final isar = Isar.getInstance();

    if (isar == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    // ----------------------------------------------------------
    // قراءة البيانات
    // ----------------------------------------------------------
    final inventory =
        await isar.inventoryModels.where().findAll();

    final sales =
        await isar.saleModels.where().findAll();

    final expenses =
        await isar.expenseModels.where().findAll();

    final vouchers =
        await isar.voucherModels.where().findAll();

    // ==========================================================
    // قراءة مرتجعات المبيعات
    // ==========================================================

    final salesReturns =
        await isar.salesReturnModels.where().findAll();

    // ==========================================================
    // 1. حساب قيمة المخزون والتنبيهات
    // ==========================================================

    double invValue = 0.0;
    int lowStock = 0;

    final Map<String, double> productCosts = {};

    for (final item in inventory) {
      // قيمة المخزون
      invValue += item.qty * item.cost;

      // التكلفة باسم المنتج
      final productName = item.name.trim();

      if (productName.isNotEmpty) {
        productCosts[productName] = item.cost;
      }

      // التكلفة بالباركود
      final barcode = item.barcode?.trim();

      if (barcode != null && barcode.isNotEmpty) {
        productCosts[barcode] = item.cost;
      }

      // التنبيهات
      if (item.qty <= item.min) {
        lowStock++;
      }
    }

    // ==========================================================
    // 2. حساب المبيعات
    // ==========================================================

    double cashSales = 0.0;
    double creditSales = 0.0;

    double cashGrossProfit = 0.0;
    double creditGrossProfit = 0.0;

    // ==========================================================
    // خريطة الفواتير الآجلة
    //
    // نستخدمها لمعرفة طريقة دفع الفاتورة الأصلية
    // عند التعامل مع المرتجعات.
    // ==========================================================

    final Map<String, String> invoicePaymentTypes = {};

    for (final sale in sales) {
    //  final invoiceNo = sale.invoiceNo.trim();
final invoiceNo = (sale.invoiceNo ?? '').trim();
      final paymentType =
          (sale.paymentType ?? 'نقدي')
              .trim()
              .toLowerCase();

      invoicePaymentTypes[invoiceNo] = paymentType;
    }

    // ==========================================================
    // المرور على المبيعات
    // ==========================================================

    for (final sale in sales) {
      final double saleRevenue =
          sale.totalAmount;

      final String paymentType =
          (sale.paymentType ?? 'نقدي')
              .trim()
              .toLowerCase();

      final bool isCredit =
          paymentType == 'آجل' ||
          paymentType == 'اجل' ||
          paymentType == 'credit';

      // ========================================================
      // حساب تكلفة البضاعة المباعة
      // ========================================================

      double saleCost = 0.0;

      // --------------------------------------------------------
      // الحالة الأولى:
      // items
      // --------------------------------------------------------

      if (sale.items.isNotEmpty) {
        for (final saleItem in sale.items) {
          double unitCost = 0.0;

          // البحث بالباركود
          final barcode =
              saleItem.barcode?.trim();

          if (barcode != null &&
              barcode.isNotEmpty) {
            unitCost =
                productCosts[barcode] ?? 0.0;
          }

          // البحث بالاسم
          if (unitCost == 0.0) {
            final productName =
                saleItem.productName?.trim();

            if (productName != null &&
                productName.isNotEmpty) {
              unitCost =
                  productCosts[productName] ?? 0.0;
            }
          }

          saleCost +=
              unitCost * saleItem.qty;
        }
      }

      // --------------------------------------------------------
      // الحالة الثانية:
      // itemsDetails القديم
      // --------------------------------------------------------

      else if (sale.itemsDetails.isNotEmpty) {
        for (final detail
            in sale.itemsDetails) {
          double unitCost = 0.0;

          for (final entry
              in productCosts.entries) {
            if (detail.contains(entry.key)) {
              unitCost = entry.value;
              break;
            }
          }

          saleCost += unitCost;
        }
      }

      // ========================================================
      // فصل النقدي عن الآجل
      // ========================================================

      if (isCredit) {
        creditSales += saleRevenue;

        creditGrossProfit +=
            saleRevenue - saleCost;
      } else {
        cashSales += saleRevenue;

        cashGrossProfit +=
            saleRevenue - saleCost;
      }
    }

    // ==========================================================
    // 3. خصم المرتجعات من المبيعات
    // ==========================================================

    double cashReturns = 0.0;
    double creditReturns = 0.0;

    // ----------------------------------------------------------
    // مهم:
    //
    // لا نخصم المرتجع من كل المبيعات بشكل عشوائي.
    //
    // نحدد أولًا طريقة دفع الفاتورة الأصلية.
    // ----------------------------------------------------------

    for (final salesReturn in salesReturns) {
      final double returnAmount =
          salesReturn.totalAmount;

      if (returnAmount <= 0) {
        continue;
      }

      final invoiceNo =
          (salesReturn.invoiceNo ?? '').trim();

      // --------------------------------------------------------
      // نحاول أخذ طريقة الدفع من المرتجع أولًا
      // --------------------------------------------------------

      String paymentType =
          (salesReturn.paymentType ?? '')
              .trim()
              .toLowerCase();

      // --------------------------------------------------------
      // إذا لم تكن موجودة في المرتجع،
      // نأخذها من الفاتورة الأصلية.
      // --------------------------------------------------------

      if (paymentType.isEmpty &&
          invoiceNo.isNotEmpty) {
        paymentType =
            invoicePaymentTypes[invoiceNo] ??
            'نقدي';
      }

      // --------------------------------------------------------
      // مرتجع آجل
      // --------------------------------------------------------

      final bool isCredit =
          paymentType == 'آجل' ||
          paymentType == 'اجل' ||
          paymentType == 'credit';

      if (isCredit) {
        creditReturns += returnAmount;
      } else {
        cashReturns += returnAmount;
      }
    }

    // ==========================================================
    // 4. صافي المبيعات بعد المرتجعات
    // ==========================================================

    // ----------------------------------------------------------
    // الآجل:
    //
    // مثال:
    // بيع آجل = 200
    // مرتجع = 200
    //
    // النتيجة = 0
    // ----------------------------------------------------------

    creditSales -= creditReturns;

    if (creditSales < 0) {
      creditSales = 0.0;
    }

    // ----------------------------------------------------------
    // النقدي:
    //
    // مثال:
    // بيع نقدي = 500
    // مرتجع = 100
    //
    // النتيجة = 400
    // ----------------------------------------------------------

    cashSales -= cashReturns;

    if (cashSales < 0) {
      cashSales = 0.0;
    }

    // ==========================================================
    // 5. حساب التحصيل من سندات القبض
    // ==========================================================

    double totalCollected = 0.0;

    for (final voucher in vouchers) {
      final String voucherType =
          (voucher.type ?? '')
              .trim()
              .toLowerCase();

      if (voucherType.contains('قبض') ||
          voucherType == 'receipt') {
        totalCollected += voucher.amount;
      }
    }

    // ==========================================================
    // 6. حساب المتبقي على العملاء
    // ==========================================================

    double remCredit =
        creditSales - totalCollected;

    if (remCredit < 0) {
      remCredit = 0.0;
    }

    // ==========================================================
    // 7. إجمالي المصروفات
    // ==========================================================

   // ==========================================================
// 7. حساب المصروفات
// ==========================================================

// إجمالي جميع المصروفات
final double expensesSum = expenses.fold(
  0.0,
  (sum, item) => sum + item.amount,
);

// المصروفات النقدية فقط
final double cashExpensesSum = expenses
    .where((item) {
      final paymentType =
          (item.paymentType ?? 'نقدي').trim().toLowerCase();

      final isCredit =
          paymentType == 'آجل' ||
          paymentType == 'اجل' ||
          paymentType == 'credit';

      return !isCredit;
    })
    .fold(
      0.0,
      (sum, item) => sum + item.amount,
    );
// ==========================================================
// 8. صافي الربح النقدي
// ==========================================================
//
// صافي الربح النقدي:
// ربح المبيعات النقدية - المصروفات النقدية فقط
//
// المصروفات الآجلة لا تدخل هنا لأنها لم تُدفع نقداً بعد.
// ==========================================================

final double calculatedCashNetProfit =
    cashGrossProfit - cashExpensesSum;
    // ==========================================================
    // 9. إجمالي المبيعات بعد المرتجعات
    // ==========================================================

    final double totalRealized =
        cashSales + creditSales;

    // ==========================================================
    // 10. تحديث الشاشة
    // ==========================================================

    if (!mounted) return;

    setState(() {
      totalProducts =
          inventory.length;

      inventoryValue =
          invValue;

      // --------------------------------------------------------
      // المبيعات النقدية بعد المرتجعات
      // --------------------------------------------------------

      cashSalesTotal =
          cashSales;

      // --------------------------------------------------------
      // المبيعات الآجلة بعد المرتجعات
      // --------------------------------------------------------

      creditSalesTotal =
          creditSales;

      // --------------------------------------------------------
      // إجمالي المبيعات بعد المرتجعات
      // --------------------------------------------------------

      totalRealizedSales =
          totalRealized;

      // --------------------------------------------------------
      // التحصيل
      // --------------------------------------------------------

      collectedFromCredit =
          totalCollected;

      // --------------------------------------------------------
      // المتبقي
      // --------------------------------------------------------

      remainingCredit =
          remCredit;

      // --------------------------------------------------------
      // المصروفات
      // --------------------------------------------------------

      totalExpenses =
          expensesSum;

      // --------------------------------------------------------
      // صافي الربح النقدي
      // --------------------------------------------------------

      cashNetProfit =
          calculatedCashNetProfit;

      // --------------------------------------------------------
      // التنبيهات
      // --------------------------------------------------------

      lowStockCount =
          lowStock;

      // --------------------------------------------------------
      // أحدث الأصناف
      // --------------------------------------------------------

      recentInventory =
          inventory.take(5).toList();

      _isLoading = false;
    });
  } catch (e, stackTrace) {
    debugPrint(
      'Error fetching local dashboard: $e',
    );

    debugPrint(
      stackTrace.toString(),
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
  }
}
  // ============================================================
  // الانتقال إلى شاشة
  // ============================================================

  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => screen,
      ),
    ).then((_) {
      _fetchDashboardData();
    });
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
            const Color(0xFFF8FAFC),

        // ======================================================
        // AppBar
        // ======================================================

        appBar: AppBar(
          backgroundColor:
              const Color(0xFF1E40AF),
          elevation: 0,

          title: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: const [
              Text(
                'لوحة المؤشرات المحاسبية (ERP)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              Text(
                'المبيعات الآجلة مستقلة عن صافي الربح النقدي',
                style: TextStyle(
                  color:
                      Color(0xFF93C5FD),
                  fontSize: 10,
                ),
              ),
            ],
          ),

          actions: [
            // --------------------------------------------------
            // تحديث
            // --------------------------------------------------

            IconButton(
              icon: const Icon(
                Icons.refresh,
                color: Colors.white,
                size: 20,
              ),
              onPressed:
                  _fetchDashboardData,
              tooltip:
                  'تحديث البيانات',
            ),

            // --------------------------------------------------
            // التقارير
            // --------------------------------------------------

            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 6.0,
                vertical: 10,
              ),
              child: ElevatedButton(
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.white,
                  foregroundColor:
                      const Color(
                          0xFF1E40AF),
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                  ),
                  elevation: 0,
                ),
                onPressed: () =>
                    _navigateTo(
                  const ReportsScreen(),
                ),
                child: const Text(
                  'التقارير',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),

        // ======================================================
        // القائمة الجانبية
        // ======================================================

        drawer: Drawer(
          backgroundColor:
              Colors.white,
          child: ListView(
            padding:
                EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration:
                    BoxDecoration(
                  color:
                      Color(0xFF1E40AF),
                ),
                child: Center(
                  child: Text(
                    'عمر سوفت ERP (محلي)',
                    style: TextStyle(
                      color:
                          Colors.white,
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              _drawerItem(
                '📊',
                'لوحة التحكم',
                () => Navigator.pop(
                  context,
                ),
              ),

              _drawerItem(
                '📦',
                'إدارة المخزون',
                () => _navigateTo(
                  const InventoryManagementScreen(),
                ),
              ),

              _drawerItem(
                '🛒',
                'فاتورة مبيعات',
                () => _navigateTo(
                  const SalesScreen(),
                ),
              ),

              _drawerItem(
                '🏢',
                'مصاريف وإيجارات',
                () => _navigateTo(
                  const ExpensesScreen(),
                ),
              ),

              _drawerItem(
                '📖',
                'دفتر الأستاذ العام',
                () => _navigateTo(
                  const LedgerScreen(),
                ),
              ),

              _drawerItem(
                '💵',
                'سندات القبض والصرف',
                () => _navigateTo(
                  const VouchersScreen(),
                ),
              ),

              _drawerItem(
                '🤝',
                'الموردين',
                () => _navigateTo(
                  const SuppliersScreen(),
                ),
              ),

              _drawerItem(
                '📈',
                'التقارير المالية',
                () => _navigateTo(
                  const ReportsScreen(),
                ),
              ),

              _drawerItem(
                '🔔',
                'التنبيهات والنواقص',
                () => _navigateTo(
                  const AlertsScreen(),
                ),
              ),
            ],
          ),
        ),

        // ======================================================
        // Body
        // ======================================================

        body: _isLoading
            ? const Center(
                child:
                    CircularProgressIndicator(
                  color:
                      Color(0xFF1E40AF),
                ),
              )
            : SingleChildScrollView(
                padding:
                    const EdgeInsets.all(
                  16.0,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // ==================================================
                    // بطاقات الإحصائيات
                    // ==================================================

                    LayoutBuilder(
                      builder:
                          (context,
                              constraints) {
                        final bool isWide =
                            constraints
                                    .maxWidth >
                                900;

                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            // ==========================================
                            // صافي الربح النقدي
                            // ==========================================

                            SizedBox(
                              width: isWide
                                  ? (constraints.maxWidth -
                                          48) /
                                      2
                                  : (constraints.maxWidth -
                                          12) /
                                      2,
                              child:
                                  _statCard(
                                '📈',
                                'Net Cash Profit',
                                '${cashNetProfit.toStringAsFixed(0)} ر.ي',
                                'صافي الربح النقدي',
                                const Color(
                                    0xFF1D4ED8),
                                'ربح المبيعات النقدية − المصروفات (الآجل لا يدخل)',
                              ),
                            ),

                            // ==========================================
                            // المبيعات الآجلة
                            // ==========================================

                            SizedBox(
                              width: isWide
                                  ? (constraints.maxWidth -
                                          48) /
                                      2
                                  : (constraints.maxWidth -
                                          12) /
                                      2,
                              child:
                                  _statCard(
                                '⏳',
                                'Credit Sales',
                                '${creditSalesTotal.toStringAsFixed(0)} ر.ي',
                                'المبيعات الآجلة',
                                const Color(
                                    0xFFD97706),
                                'مجموع الفواتير التي paymentType فيها آجل',
                              ),
                            ),

                            // ==========================================
                            // إجمالي المبيعات
                            // ==========================================

                            SizedBox(
                              width: isWide
                                  ? (constraints.maxWidth -
                                          48) /
                                      3
                                  : (constraints.maxWidth -
                                          12) /
                                      2,
                              child:
                                  _statCard(
                                '📊',
                                'Total Sales',
                                '${totalRealizedSales.toStringAsFixed(0)} ر.ي',
                                'إجمالي المبيعات',
                                const Color(
                                    0xFF16A34A),
                                'المبيعات النقدية + المبيعات الآجلة',
                              ),
                            ),

                            // ==========================================
                            // التحصيل
                            // ==========================================

                            SizedBox(
                              width: isWide
                                  ? (constraints.maxWidth -
                                          48) /
                                      3
                                  : (constraints.maxWidth -
                                          12) /
                                      2,
                              child:
                                  _statCard(
                                '💵',
                                'Collected',
                                '${collectedFromCredit.toStringAsFixed(0)} ر.ي',
                                'المحصل من العملاء',
                                const Color(
                                    0xFF0284C7),
                                'إجمالي سندات القبض المسجلة',
                              ),
                            ),

                            // ==========================================
                            // المتبقي على العملاء
                            // ==========================================

                            SizedBox(
                              width: isWide
                                  ? (constraints.maxWidth -
                                          48) /
                                      3
                                  : (constraints.maxWidth -
                                          12) /
                                      2,
                              child:
                                  _statCard(
                                '⚠️',
                                'Remaining Credit',
                                '${remainingCredit.toStringAsFixed(0)} ر.ي',
                                'المتبقي على العملاء',
                                const Color(
                                    0xFFDC2626),
                                'المبيعات الآجلة − المحصل',
                              ),
                            ),

                            // ==========================================
                            // المصروفات
                            // ==========================================

                            SizedBox(
                              width: isWide
                                  ? (constraints.maxWidth -
                                          48) /
                                      3
                                  : (constraints.maxWidth -
                                          12) /
                                      2,
                              child:
                                  _statCard(
                                '💸',
                                'Expenses',
                                '${totalExpenses.toStringAsFixed(0)} ر.ي',
                                'إجمالي المصاريف',
                                const Color(
                                    0xFF9333EA),
                                'إجمالي المصروفات المسجلة',
                              ),
                            ),

                            // ==========================================
                            // التنبيهات
                            // ==========================================

                            SizedBox(
                              width: isWide
                                  ? (constraints.maxWidth -
                                          48) /
                                      3
                                  : (constraints.maxWidth -
                                          12) /
                                      2,
                              child:
                                  InkWell(
                                onTap: () =>
                                    _navigateTo(
                                  const AlertsScreen(),
                                ),
                                child:
                                    _statCard(
                                  '🔔',
                                  'Alerts',
                                  lowStockCount
                                      .toString(),
                                  'التنبيهات والنواقص',
                                  const Color(
                                      0xFFE11D48),
                                  'الأصناف التي وصلت إلى حد الطلب',
                                ),
                              ),
                            ),

                            // ==========================================
                            // قيمة المخزون
                            // ==========================================

                            SizedBox(
                              width: isWide
                                  ? (constraints.maxWidth -
                                          48) /
                                      3
                                  : (constraints.maxWidth -
                                          12) /
                                      2,
                              child:
                                  _statCard(
                                '📦',
                                'Inventory Value',
                                '${inventoryValue.toStringAsFixed(0)} ر.ي',
                                'قيمة المخزون',
                                const Color(
                                    0xFF475569),
                                'الكمية المتبقية × سعر التكلفة',
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    // ==================================================
                    // أحدث عمليات المخزون
                    // ==================================================

                    Container(
                      padding:
                          const EdgeInsets.all(
                        16,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            Colors.white,
                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors
                                .blue
                                .withOpacity(
                              0.05,
                            ),
                            blurRadius:
                                10,
                            offset:
                                const Offset(
                              0,
                              4,
                            ),
                          ),
                        ],
                        border:
                            Border.all(
                          color:
                              const Color(
                            0xFFE2E8F0,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          // ============================================
                          // عنوان القسم
                          // ============================================

                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween,
                            children: [
                              const Text(
                                'أحدث العمليات في المخزن',
                                style:
                                    TextStyle(
                                  color:
                                      Color(
                                    0xFF1E293B,
                                  ),
                                  fontSize:
                                      14,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),

                              TextButton(
                                onPressed: () =>
                                    _navigateTo(
                                  const InventoryManagementScreen(),
                                ),
                                child:
                                    const Text(
                                  'عرض الكل ←',
                                  style:
                                      TextStyle(
                                    color:
                                        Color(
                                      0xFF2563EB,
                                    ),
                                    fontSize:
                                        11,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          // ============================================
                          // لا توجد أصناف
                          // ============================================

                          recentInventory
                                  .isEmpty
                              ? const Center(
                                  child:
                                      Padding(
                                    padding:
                                        EdgeInsets.all(
                                      20.0,
                                    ),
                                    child:
                                        Text(
                                      'لا توجد أصناف مضافة حالياً',
                                      style:
                                          TextStyle(
                                        color:
                                            Colors
                                                .grey,
                                        fontSize:
                                            12,
                                      ),
                                    ),
                                  ),
                                )

                              // ==========================================
                              // جدول المخزون
                              // ==========================================

                              : SingleChildScrollView(
                                  scrollDirection:
                                      Axis.horizontal,
                                  child:
                                      DataTable(
                                    columnSpacing:
                                        24,

                                    columns:
                                        const [
                                      DataColumn(
                                        label:
                                            Text(
                                          'المنتج',
                                          style:
                                              TextStyle(
                                            color:
                                                Colors.grey,
                                            fontSize:
                                                11,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label:
                                            Text(
                                          'التصنيف',
                                          style:
                                              TextStyle(
                                            color:
                                                Colors.grey,
                                            fontSize:
                                                11,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label:
                                            Text(
                                          'الكمية',
                                          style:
                                              TextStyle(
                                            color:
                                                Colors.grey,
                                            fontSize:
                                                11,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label:
                                            Text(
                                          'الحالة',
                                          style:
                                              TextStyle(
                                            color:
                                                Colors.grey,
                                            fontSize:
                                                11,
                                          ),
                                        ),
                                      ),
                                    ],

                                    rows:
                                        recentInventory
                                            .map(
                                      (item) {
                                        final bool
                                            isLow =
                                            item.qty <=
                                                item.min;

                                        return DataRow(
                                          cells: [
                                            // --------------------------------
                                            // المنتج
                                            // --------------------------------

                                            DataCell(
                                              Text(
                                                item.name,
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
                                              ),
                                            ),

                                            // --------------------------------
                                            // التصنيف
                                            // --------------------------------

                                            DataCell(
                                              Text(
                                                item.category ??
                                                    '---',
                                                style:
                                                    const TextStyle(
                                                  color:
                                                      Colors.grey,
                                                  fontSize:
                                                      11,
                                                ),
                                              ),
                                            ),

                                            // --------------------------------
                                            // الكمية
                                            // --------------------------------

                                            DataCell(
                                              Text(
                                                item.qty
                                                    .toString(),
                                                style:
                                                    const TextStyle(
                                                  color:
                                                      Color(
                                                    0xFF2563EB,
                                                  ),
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  fontSize:
                                                      12,
                                                ),
                                              ),
                                            ),

                                            // --------------------------------
                                            // الحالة
                                            // --------------------------------

                                            DataCell(
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal:
                                                      6,
                                                  vertical:
                                                      2,
                                                ),
                                                decoration:
                                                    BoxDecoration(
                                                  color:
                                                      isLow
                                                          ? Colors.red.withOpacity(
                                                              0.1,
                                                            )
                                                          : Colors.green.withOpacity(
                                                              0.1,
                                                            ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    6,
                                                  ),
                                                ),
                                                child:
                                                    Text(
                                                  isLow
                                                      ? 'حرج ⚠️'
                                                      : 'متوفر ✅',
                                                  style:
                                                      TextStyle(
                                                    color:
                                                        isLow
                                                            ? Colors.red
                                                            : Colors.green,
                                                    fontSize:
                                                        10,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ).toList(),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ============================================================
  // بطاقة الإحصائية
  // ============================================================

  Widget _statCard(
    String emoji,
    String tag,
    String title,
    String subtitle,
    Color color,
    String tooltipEquation,
  ) {
    return Tooltip(
      message: tooltipEquation,
      child: Container(
        padding:
            const EdgeInsets.all(12),
        decoration:
            BoxDecoration(
          color:
              Colors.white,
          borderRadius:
              BorderRadius.circular(
            16,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.blue.withOpacity(
                0.04,
              ),
              blurRadius:
                  8,
              offset:
                  const Offset(
                0,
                3,
              ),
            ),
          ],
          border:
              Border.all(
            color:
                const Color(
              0xFFE2E8F0,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            // --------------------------------------------------
            // العنوان
            // --------------------------------------------------

            Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
              children: [
                Text(
                  emoji,
                  style:
                      const TextStyle(
                    fontSize: 18,
                  ),
                ),

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        color.withOpacity(
                      0.1,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      4,
                    ),
                  ),
                  child:
                      Text(
                    tag,
                    style:
                        TextStyle(
                      color:
                          color,
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
              height: 6,
            ),

            // --------------------------------------------------
            // القيمة
            // --------------------------------------------------

            FittedBox(
              fit:
                  BoxFit.scaleDown,
              alignment:
                  Alignment.centerRight,
              child:
                  Text(
                title,
                style:
                    TextStyle(
                  color:
                      color,
                  fontSize:
                      18,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ),

            const SizedBox(
              height: 2,
            ),

            // --------------------------------------------------
            // الوصف
            // --------------------------------------------------

            Text(
              subtitle,
              style:
                  const TextStyle(
                color:
                    Color(
                  0xFF1E293B,
                ),
                fontSize:
                    11,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 2,
            ),

            // --------------------------------------------------
            // المعادلة
            // --------------------------------------------------

            Text(
              tooltipEquation,
              style:
                  const TextStyle(
                color:
                    Colors.grey,
                fontSize:
                    8,
              ),
              maxLines:
                  1,
              overflow:
                  TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // عنصر القائمة الجانبية
  // ============================================================

  Widget _drawerItem(
    String emoji,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading:
          Text(
        emoji,
        style:
            const TextStyle(
          fontSize: 16,
        ),
      ),
      title:
          Text(
        title,
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
      ),
      onTap:
          onTap,
    );
  }

  // ============================================================
  // زر إجراء سريع
  // ============================================================

  Widget _quickActionButton(
    String title,
    VoidCallback onTap,
  ) {
    return ElevatedButton(
      style:
          ElevatedButton.styleFrom(
        backgroundColor:
            const Color(
          0xFFF1F5F9,
        ),
        foregroundColor:
            const Color(
          0xFF1E293B,
        ),
        elevation:
            0,
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            10,
          ),
          side:
              const BorderSide(
            color:
                Color(
              0xFFCBD5E1,
            ),
          ),
        ),
      ),
      onPressed:
          onTap,
      child:
          Text(
        title,
        style:
            const TextStyle(
          fontSize:
              11,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }
}

