import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'model/inventory_model.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({Key? key}) : super(key: key);

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<InventoryModel> criticalItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCriticalItems();
  }

  // 🚀 جلب الأصناف الحرجة محلياً من Isar
  Future<void> _fetchCriticalItems() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final isar = Isar.getInstance();
      if (isar == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final inventory = await isar.inventoryModels.where().findAll();

      if (!mounted) return;

      setState(() {
        criticalItems = inventory.where((item) => item.qty <= item.min).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل تحميل بيانات المخزون محلياً: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showRestockDialog(InventoryModel item) {
    final TextEditingController qtyController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        final screenWidth = MediaQuery.of(dialogContext).size.width;
        final dialogWidth = screenWidth < 600
            ? screenWidth * 0.90
            : screenWidth < 1000
                ? 500.0
                : 600.0;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: dialogWidth),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.add_shopping_cart,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'توريد وإضافة كمية',
                              style: const TextStyle(
                                color: Color(0xFF1E40AF),
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                color: Color(0xFF1E293B),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'الكمية الحالية: ${item.qty}',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            Text(
                              'الحد الأدنى: ${item.min}',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: qtyController,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'الكمية المراد توريدها وإضافتها',
                          labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                          prefixIcon: const Icon(
                            Icons.inventory_2_outlined,
                            color: Color(0xFF16A34A),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () async {
                                await _confirmRestock(
                                  dialogContext,
                                  item,
                                  qtyController,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF16A34A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'تأكيد التوريد 🚚',
                                style: TextStyle(fontWeight: FontWeight.bold),
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
          ),
        );
      },
    );
  }

  // 🚀 تنفيذ التوريد وتحديث المنتج محلياً في Isar
  Future<void> _confirmRestock(
    BuildContext dialogContext,
    InventoryModel item,
    TextEditingController qtyController,
  ) async {
    final addedQty = double.tryParse(qtyController.text.trim());

    if (addedQty == null || addedQty <= 0) {
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال كمية صحيحة ⚠️'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.pop(dialogContext);

    try {
      final isar = Isar.getInstance();
      if (isar == null) return;

      final updatedProduct = InventoryModel(
        name: item.name,
        category: item.category,
        qty: item.qty + addedQty,
        cost: item.cost,
        price: item.price,
        min: item.min,
        supplier: item.supplier,
        purchaseType: item.purchaseType,
        barcode: item.barcode,
      )..id = item.id;

      await isar.writeTxn(() async {
        await isar.inventoryModels.put(updatedProduct);
      });

      if (!mounted) return;

      await _fetchCriticalItems();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم توريد الكمية وتحديث المخزن محلياً بنجاح 🚚✅'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل عملية التوريد: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildProductCard(InventoryModel item, double screenWidth) {
    final bool isMobile = screenWidth < 600;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isMobile ? 14 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.redAccent.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: isMobile
          ? _buildMobileProductContent(item)
          : _buildDesktopProductContent(item),
    );
  }

  Widget _buildMobileProductContent(InventoryModel item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.redAccent,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'التصنيف: ${item.category ?? 'بدون'}',
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                'الحالية: ${item.qty}',
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.08),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                'الحد الأدنى: ${item.min}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showRestockDialog(item),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.add_shopping_cart, size: 17),
            label: const Text(
              'توريد 🚚',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopProductContent(InventoryModel item) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.warning_amber_rounded,
            color: Colors.redAccent,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'التصنيف: ${item.category ?? 'بدون'}',
                style: const TextStyle(color: Colors.grey, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Wrap(
          spacing: 8,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                'الحالية: ${item.qty}',
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
            Text(
              'الحد الأدنى: ${item.min}',
              style: const TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () => _showRestockDialog(item),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF16A34A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
          icon: const Icon(Icons.add_shopping_cart, size: 15),
          label: const Text(
            'توريد 🚚',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFFF8FAFC);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E40AF),
          elevation: 0,
          title: const Text(
            '🔔 مركز التحكم في النواقص (محلي)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final horizontalPadding = screenWidth < 600
                ? 12.0
                : screenWidth < 1000
                    ? 24.0
                    : 40.0;

            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 16,
              ),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF1E40AF)),
                    )
                  : Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth < 600 ? 12 : 18,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'الأصناف التي تحتاج لإعادة طلب',
                                  style: TextStyle(
                                    color: Color(0xFF1E293B),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 12),
                              _buildCounter(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: criticalItems.isEmpty
                              ? _buildEmptyState()
                              : ListView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: criticalItems.length,
                                  itemBuilder: (context, index) {
                                    return _buildProductCard(
                                      criticalItems[index],
                                      screenWidth,
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${criticalItems.length} منتج حرج',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('📦', style: TextStyle(fontSize: 60)),
            SizedBox(height: 12),
            Text(
              'المخزن متكامل!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'لا توجد أصناف تحت حد النقص حالياً.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}