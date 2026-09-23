import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'model/inventory_model.dart';
import 'model/sale_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = true;

  double totalCost = 0;
  double totalSales = 0;
  double netProfit = 0;
  List<InventoryModel> topProducts = [];

  @override
  void initState() {
    super.initState();
    _fetchReportData();
  }

  // 🚀 جلب البيانات وإعداد التقارير مباشرة محلياً من Isar
  Future<void> _fetchReportData() async {
    setState(() => _isLoading = true);
    try {
      final isar = Isar.getInstance();
      if (isar == null) {
        setState(() => _isLoading = false);
        return;
      }

      // جلب المخزون وحساب إجمالي التكلفة/رأس المال
      final inventory = await isar.inventoryModels.where().findAll();
      double cost = 0;
      for (var item in inventory) {
        cost += (item.qty * item.cost); // الاعتماد على التكلفة الفعلية Cost بدلاً من سعر البيع
      }

      // جلب المبيعات وحساب إجمالي المبيعات
      final sales = await isar.saleModels.where().findAll();
      double salesSum = 0;
      for (var sale in sales) {
        salesSum += sale.totalAmount;
      }

      setState(() {
        totalCost = cost;
        totalSales = salesSum;
        netProfit = totalSales - totalCost;
        // ترتيب المنتجات حسب القيمة المخزنية الأعلى
        topProducts = List.from(inventory)
          ..sort((a, b) => (b.qty * b.price).compareTo(a.qty * a.price));
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading local reports: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFFF8FAFC);
    const Color cardBg = Colors.white;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E40AF),
          elevation: 0,
          title: const Text('📊 التقارير المالية والأداء (محلي)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E40AF)))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // كارد الأداء المالي والسيولة
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Colors.blue.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('📊 كشف الأداء المالي والسيولة المحلية', 
                            style: TextStyle(color: Color(0xFF1E40AF), fontSize: 15, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                          const SizedBox(height: 14),
                          _buildReportRow('إجمالي رأس المال (Cost)', '${totalCost.toStringAsFixed(2)} ر.ي', const Color(0xFF2563EB)),
                          const SizedBox(height: 10),
                          _buildReportRow('إجمالي المبيعات (Sales)', '${totalSales.toStringAsFixed(2)} ر.ي', const Color(0xFF16A34A)),
                          const SizedBox(height: 12),
                          
                          // كارد صافي الأرباح المحسن
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text('صافي الأرباح التقديرية (Profit)', 
                                    style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w900, fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('${netProfit.toStringAsFixed(2)} ر.ي', 
                                    style: const TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.w900, fontSize: 20)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // أفضل المنتجات من حيث القيمة المخزنية
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Colors.blue.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🥇 أفضل المنتجات من حيث القيمة المخزنية', 
                            style: TextStyle(color: Color(0xFF1E293B), fontSize: 15, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 12),
                          topProducts.isEmpty
                              ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('لا توجد بيانات متاحة محلياً', style: TextStyle(color: Colors.grey))))
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: topProducts.length > 5 ? 5 : topProducts.length,
                                  separatorBuilder: (context, index) => const Divider(color: Color(0xFFE2E8F0)),
                                  itemBuilder: (context, index) {
                                    final item = topProducts[index];
                                    double totalVal = item.qty * item.price;
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(item.name, style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 13)),
                                      subtitle: Text('الكمية: ${item.qty} | السعر: ${item.price}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                      trailing: Text('${totalVal.toStringAsFixed(2)} ر.ي', 
                                        style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12)),
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
  }

  Widget _buildReportRow(String title, String value, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border(right: BorderSide(color: borderColor, width: 4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(title, 
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w900, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}