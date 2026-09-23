import 'package:erp_application_1/DashboardScreen.dart';

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ============================================================
// نماذج Isar
// ============================================================

import 'model/inventory_model.dart';
import 'model/expense_model.dart';
import 'model/supplier_model.dart';
import 'model/voucher_model.dart';
import 'model/ledger_model.dart';
import 'model/sale_model.dart';
import 'model/sales_return_model.dart';

// ============================================================
// شاشة التفعيل
// ============================================================

import 'activation_screen.dart';

// ============================================================
// Main
// ============================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ==========================================================
  // فتح قاعدة Isar
  // ==========================================================

  final dir = await getApplicationDocumentsDirectory();
print('ISAR DIRECTORY: ${dir.path}');
  if (Isar.instanceNames.isEmpty) {
    await Isar.open(
      [
        SalesReturnModelSchema,
        InventoryModelSchema,
        ExpenseModelSchema,
        SupplierModelSchema,
        VoucherModelSchema,
        LedgerModelSchema,
        SaleModelSchema,
      ],
      directory: dir.path,
    );
  }

  // ==========================================================
  // التخزين الآمن
  //
  // يستخدم فقط للتفعيل الدائم
  // ==========================================================

  const secureStorage = FlutterSecureStorage();

  final String? activationStatus =
      await secureStorage.read(
    key: 'is_app_activated',
  );

  final bool isActivated =
      activationStatus == 'true';

  // ==========================================================
  // إذا كان التطبيق مفعلاً بشكل دائم
  // ==========================================================

  if (isActivated) {
    runApp(
      const MyApp(
        initialAccessType: AccessType.permanent,
      ),
    );

    return;
  }

  // ==========================================================
  // SharedPreferences
  //
  // يستخدم فقط لحفظ بداية الفترة التجريبية
  // ==========================================================

  final prefs =
      await SharedPreferences.getInstance();

  int? trialStartMillis =
      prefs.getInt('trial_start_millis');

  // ==========================================================
  // أول تشغيل
  // ==========================================================

  if (trialStartMillis == null) {
    trialStartMillis =
        DateTime.now().millisecondsSinceEpoch;

    await prefs.setInt(
      'trial_start_millis',
      trialStartMillis,
    );
  }

  // ==========================================================
  // حساب فترة التجربة
  // ==========================================================

  final DateTime trialStart =
      DateTime.fromMillisecondsSinceEpoch(
    trialStartMillis,
  );

  final DateTime trialEnd =
      trialStart.add(
    const Duration(days: 7),
  );

  final DateTime now =
      DateTime.now();

  final bool trialActive =
      now.isBefore(trialEnd);

  // ==========================================================
  // تشغيل التطبيق
  // ==========================================================

  if (trialActive) {
    final int remainingDays =
        trialEnd
            .difference(now)
            .inDays;

    runApp(
      MyApp(
        initialAccessType: AccessType.trial,
        initialRemainingDays:
            remainingDays < 1
                ? 1
                : remainingDays,
      ),
    );
  } else {
    runApp(
      const MyApp(
        initialAccessType: AccessType.expired,
      ),
    );
  }
}

// ============================================================
// حالات الوصول
// ============================================================

enum AccessType {
  trial,
  permanent,
  expired,
}

// ============================================================
// التطبيق الرئيسي
// ============================================================

class MyApp extends StatefulWidget {
  final AccessType initialAccessType;
  final int initialRemainingDays;

  const MyApp({
    Key? key,
    required this.initialAccessType,
    this.initialRemainingDays = 0,
  }) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

// ============================================================
// MyApp State
// ============================================================

class _MyAppState extends State<MyApp> {
  late AccessType _accessType;
  late int _remainingDays;

  @override
  void initState() {
    super.initState();

    _accessType =
        widget.initialAccessType;

    _remainingDays =
        widget.initialRemainingDays;
  }

  // ==========================================================
  // تحويل التطبيق إلى نسخة دائمة بعد نجاح التفعيل
  // ==========================================================

  void _activatePermanently() {
    if (!mounted) return;

    setState(() {
      _accessType =
          AccessType.permanent;

      _remainingDays = 0;
    });
  }

  // ==========================================================
  // فتح شاشة التفعيل أثناء النسخة التجريبية
  // ==========================================================

  Future<void> _openActivationScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) {
          return ActivationScreen(
            onActivated: () {
              // ------------------------------------------------
              // إغلاق شاشة التفعيل
              // ------------------------------------------------

              Navigator.of(context).pop();

              // ------------------------------------------------
              // تحويل التطبيق إلى نسخة دائمة
              // ------------------------------------------------

              _activatePermanently();
            },
          );
        },
      ),
    );
  }

  // ==========================================================
  // تحديد الصفحة الرئيسية حسب حالة التطبيق
  // ==========================================================

  Widget _buildHome() {
    // ----------------------------------------------------------
    // نسخة دائمة
    // ----------------------------------------------------------

    if (_accessType ==
        AccessType.permanent) {
      return const DashboardScreen();
    }

    // ----------------------------------------------------------
    // نسخة تجريبية
    // ----------------------------------------------------------

    if (_accessType ==
        AccessType.trial) {
      return TrialHomeScreen(
        remainingDays: _remainingDays,
        onActivatePressed:
            _openActivationScreen,
      );
    }

    // ----------------------------------------------------------
    // انتهت التجربة
    // ----------------------------------------------------------

    return ActivationScreen(
      onActivated:
          _activatePermanently,
    );
  }

  // ==========================================================
  // Build
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'ERP Local System',

      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),

      home: _buildHome(),
    );
  }
}

// ============================================================
// شاشة النسخة التجريبية
// ============================================================

class TrialHomeScreen extends StatelessWidget {
  final int remainingDays;
  final VoidCallback onActivatePressed;

  const TrialHomeScreen({
    Key? key,
    required this.remainingDays,
    required this.onActivatePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ======================================================
        // Dashboard
        // ======================================================

        const DashboardScreen(),

        // ======================================================
        // شريط النسخة التجريبية
        // ======================================================

        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Container(
              height: 38,

              padding:
                  const EdgeInsets.symmetric(
                horizontal: 12,
              ),

              color:
                  Colors.orange.shade700,

              child: Row(
                children: [
                  // ------------------------------------------------
                  // أيقونة
                  // ------------------------------------------------

                  const Icon(
                    Icons.timer_outlined,
                    color: Colors.white,
                    size: 17,
                  ),

                  const SizedBox(width: 6),

                  // ------------------------------------------------
                  // عدد الأيام
                  // ------------------------------------------------

                  Expanded(
                    child: Text(
                      'نسخة تجريبية • متبقي $remainingDays يوم',
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),

                  // ------------------------------------------------
                  // زر التفعيل
                  // ------------------------------------------------

                  SizedBox(
                    height: 30,

                    child: TextButton(
                      onPressed:
                          onActivatePressed,

                      style:
                          TextButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 10,
                        ),

                        minimumSize:
                            Size.zero,

                        tapTargetSize:
                            MaterialTapTargetSize
                                .shrinkWrap,
                      ),

                      child: const Text(
                        'تفعيل',
                        style:
                            TextStyle(
                          color: Colors.white,
                          fontSize: 11,
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
        ),
      ],
    );
  }
}