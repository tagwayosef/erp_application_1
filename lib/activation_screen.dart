import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ActivationScreen extends StatefulWidget {
  final VoidCallback onActivated;

  const ActivationScreen({
    super.key,
    required this.onActivated,
  });

  @override
  State<ActivationScreen> createState() =>
      _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  // ==========================================================
  // Controller
  // ==========================================================

  final TextEditingController _keyController =
      TextEditingController();

  // ==========================================================
  // التخزين الآمن
  //
  // flutter_secure_storage يستخدم التخزين الآمن للنظام.
  // Android: Keystore / Encrypted storage
  // ==========================================================

  static const FlutterSecureStorage _secureStorage =
      FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // ==========================================================
  // حالات الشاشة
  // ==========================================================

  bool _isLoading = true;
  bool _isVerifying = false;

  String _deviceFingerprint = '';

  // ==========================================================
  // الألوان
  // ==========================================================

  static const Color primaryBlue =
      Color(0xFF1E40AF);

  static const Color backgroundColor =
      Color(0xFFF8FAFC);

  static const Color cardColor =
      Colors.white;

  // ==========================================================
  // Init
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _initDeviceFingerprint();
  }

  // ==========================================================
  // Dispose
  // ==========================================================

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  // ==========================================================
  // إنشاء معرف الجهاز
  // ==========================================================

  Future<void> _initDeviceFingerprint() async {
    try {
      final DeviceInfoPlugin deviceInfo =
          DeviceInfoPlugin();

      String rawId = '';

      // --------------------------------------------------------
      // Android
      // --------------------------------------------------------

      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo =
            await deviceInfo.androidInfo;

        rawId =
            '${androidInfo.id}-'
            '${androidInfo.hardware}-'
            '${androidInfo.brand}-'
            '${androidInfo.device}';
      }

      // --------------------------------------------------------
      // Windows
      // --------------------------------------------------------

      else if (Platform.isWindows) {
        final WindowsDeviceInfo windowsInfo =
            await deviceInfo.windowsInfo;

        rawId = windowsInfo.computerName;
      }

      // --------------------------------------------------------
      // أنظمة أخرى
      // --------------------------------------------------------

      else {
        rawId = 'DEFAULT-DEVICE-ID';
      }

      if (rawId.trim().isEmpty) {
        throw Exception(
          'Device identifier is empty',
        );
      }

      // ========================================================
      // تحويل معرف الجهاز إلى رقم
      // ========================================================

      final int deviceHash =
          rawId.hashCode.abs();

      String formattedId =
          deviceHash.toString();

      // ========================================================
      // ضمان وجود رقم صالح
      // ========================================================

      if (formattedId.isEmpty) {
        throw Exception(
          'Invalid device identifier',
        );
      }

      // ========================================================
      // تنسيق المعرف
      //
      // مثال:
      // 123456789012
      //
      // يصبح:
      // 1234-5678-9012
      // ========================================================

      if (formattedId.length >= 12) {
        formattedId =
            '${formattedId.substring(0, 4)}-'
            '${formattedId.substring(4, 8)}-'
            '${formattedId.substring(8, 12)}';
      }

      if (!mounted) return;

      setState(() {
        _deviceFingerprint = formattedId;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _deviceFingerprint =
            'ERR-DEVICE-ID';

        _isLoading = false;
      });

      _showMessage(
        'تعذر إنشاء معرف الجهاز',
        Colors.red,
      );
    }
  }

  // ==========================================================
  // التحقق من مفتاح التفعيل
  // ==========================================================

  Future<void> _verifyLicenseKey() async {
    if (_isVerifying) {
      return;
    }

    final String enteredKey =
        _keyController.text.trim().toUpperCase();

    // ========================================================
    // التحقق من المفتاح
    // ========================================================

    if (enteredKey.isEmpty) {
      _showMessage(
        'الرجاء إدخال مفتاح التفعيل',
        Colors.orange,
      );

      return;
    }

    // ========================================================
    // التأكد من أن المفتاح يبدأ بـ OMAR-
    // ========================================================

    if (!enteredKey.startsWith('OMAR-')) {
      _showMessage(
        'صيغة مفتاح التفعيل غير صحيحة',
        Colors.red,
      );

      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      // ======================================================
      // استخراج رقم الجهاز
      // ======================================================

      final String cleanDevicePin =
          _deviceFingerprint.replaceAll('-', '');

      final int? parsedDeviceNumber =
          int.tryParse(cleanDevicePin);

      if (parsedDeviceNumber == null) {
        _showMessage(
          'تعذر قراءة معرف الجهاز',
          Colors.red,
        );

        return;
      }

      final int deviceNumber =
          parsedDeviceNumber;

      // ======================================================
      // معادلة التفعيل
      //
      // رقم الجهاز × 5 + 9933
      // ======================================================

      final int calculatedKeyNumber =
          (deviceNumber * 5) + 9933;

      final String expectedKey =
          'OMAR-$calculatedKeyNumber';

      // ======================================================
      // التحقق النهائي
      // ======================================================

      if (enteredKey != expectedKey) {
        _showMessage(
          'مفتاح التفعيل غير صحيح لهذا الجهاز',
          Colors.red,
        );

        return;
      }

      // ======================================================
      // المفتاح صحيح
      //
      // حفظ حالة التفعيل في التخزين الآمن
      // ======================================================

      await _secureStorage.write(
        key: 'is_app_activated',
        value: 'true',
      );

      // ======================================================
      // حفظ مفتاح الترخيص
      // ======================================================

      await _secureStorage.write(
        key: 'saved_license_key',
        value: enteredKey,
      );

      // ======================================================
      // حفظ معرف الجهاز الذي تم التفعيل عليه
      //
      // هذا يعطي طبقة إضافية من التحقق.
      // ======================================================

      await _secureStorage.write(
        key: 'activated_device_id',
        value: _deviceFingerprint,
      );

      // ======================================================
      // التأكد من نجاح الحفظ
      // ======================================================

      final String? savedActivation =
          await _secureStorage.read(
        key: 'is_app_activated',
      );

      final String? savedKey =
          await _secureStorage.read(
        key: 'saved_license_key',
      );

      final String? savedDevice =
          await _secureStorage.read(
        key: 'activated_device_id',
      );

      if (savedActivation != 'true' ||
          savedKey != enteredKey ||
          savedDevice != _deviceFingerprint) {
        _showMessage(
          'تعذر حفظ بيانات التفعيل بشكل صحيح',
          Colors.red,
        );

        return;
      }

      if (!mounted) {
        return;
      }

      // ======================================================
      // رسالة نجاح
      // ======================================================

      _showMessage(
        'تم تفعيل التطبيق بنجاح ✅',
        Colors.green,
      );

      // ======================================================
      // الانتقال للنظام
      // ======================================================

      widget.onActivated();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'حدث خطأ أثناء التفعيل',
        Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  // ==========================================================
  // قراءة حالة التفعيل
  //
  // يمكن استخدامها لاحقًا عند الحاجة.
  // ==========================================================

  static Future<bool> isActivated() async {
    try {
      const FlutterSecureStorage storage =
          FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
        ),
      );

      final String? status =
          await storage.read(
        key: 'is_app_activated',
      );

      return status == 'true';
    } catch (_) {
      return false;
    }
  }

  // ==========================================================
  // التحقق من الجهاز المحفوظ
  // ==========================================================

  static Future<bool> isActivatedForDevice(
    String currentDeviceId,
  ) async {
    try {
      const FlutterSecureStorage storage =
          FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
        ),
      );

      final String? status =
          await storage.read(
        key: 'is_app_activated',
      );

      final String? savedDevice =
          await storage.read(
        key: 'activated_device_id',
      );

      return status == 'true' &&
          savedDevice == currentDeviceId;
    } catch (_) {
      return false;
    }
  }

  // ==========================================================
  // رسالة للمستخدم
  // ==========================================================

  void _showMessage(
    String message,
    Color color,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            textAlign: TextAlign.right,
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ==========================================================
  // نسخ معرف الجهاز
  // ==========================================================

  Future<void> _copyDeviceId() async {
    if (_deviceFingerprint.isEmpty ||
        _deviceFingerprint == 'ERR-DEVICE-ID') {
      return;
    }

    await Clipboard.setData(
      ClipboardData(
        text: _deviceFingerprint,
      ),
    );

    if (!mounted) return;

    _showMessage(
      'تم نسخ معرف الجهاز إلى الحافظة 📋',
      Colors.blue,
    );
  }

  // ==========================================================
  // واجهة الشاشة
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.all(24),
            child: Container(
              constraints:
                  const BoxConstraints(
                maxWidth: 450,
              ),
              padding:
                  const EdgeInsets.all(32),
              decoration:
                  BoxDecoration(
                color: cardColor,
                borderRadius:
                    BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.blue.withOpacity(0.06),
                    blurRadius: 20,
                    offset:
                        const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color:
                      const Color(0xFFE2E8F0),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 200,
                      child: Center(
                        child:
                            CircularProgressIndicator(
                          color: primaryBlue,
                        ),
                      ),
                    )
                  : Column(
                      mainAxisSize:
                          MainAxisSize.min,
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        // ==================================================
                        // الأيقونة
                        // ==================================================

                        const Center(
                          child:
                              CircleAvatar(
                            radius: 35,
                            backgroundColor:
                                Color(0xFFEFF6FF),
                            child: Icon(
                              Icons
                                  .lock_outline_rounded,
                              size: 35,
                              color:
                                  primaryBlue,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 20,
                        ),

                        // ==================================================
                        // العنوان
                        // ==================================================

                        const Text(
                          'تفعيل النظام المحاسبي',
                          textAlign:
                              TextAlign.center,
                          style: TextStyle(
                            color:
                                Color(0xFF1E293B),
                            fontSize: 22,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        const Text(
                          'هذا النظام محمي ومفتاح التفعيل مرتبط بهذا الجهاز.',
                          textAlign:
                              TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(
                          height: 30,
                        ),

                        // ==================================================
                        // معرف الجهاز
                        // ==================================================

                        const Text(
                          'معرف الجهاز الخاص بك:',
                          style: TextStyle(
                            color:
                                Color(0xFF475569),
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        Container(
                          padding:
                              const EdgeInsets.all(16),
                          decoration:
                              BoxDecoration(
                            color:
                                const Color(0xFFF8FAFC),
                            borderRadius:
                                BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  const Color(
                                0xFFCBD5E1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _deviceFingerprint,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  textDirection:
                                      TextDirection.ltr,
                                  style:
                                      const TextStyle(
                                    color:
                                        primaryBlue,
                                    fontWeight:
                                        FontWeight.w900,
                                    fontSize: 16,
                                    fontFamily:
                                        'monospace',
                                  ),
                                ),
                              ),

                              IconButton(
                                tooltip:
                                    'نسخ المعرف',
                                onPressed:
                                    _copyDeviceId,
                                icon:
                                    const Icon(
                                  Icons
                                      .copy_rounded,
                                  color:
                                      primaryBlue,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(
                          height: 24,
                        ),

                        // ==================================================
                        // عنوان المفتاح
                        // ==================================================

                        const Text(
                          'مفتاح التفعيل:',
                          style: TextStyle(
                            color:
                                Color(0xFF475569),
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        // ==================================================
                        // إدخال المفتاح
                        // ==================================================

                        TextField(
                          controller:
                              _keyController,
                          enabled:
                              !_isVerifying,
                          textDirection:
                              TextDirection.ltr,
                          keyboardType:
                              TextInputType.text,
                          textCapitalization:
                              TextCapitalization.characters,
                          autocorrect: false,
                          enableSuggestions: false,
                          style:
                              const TextStyle(
                            color:
                                Color(0xFF1E293B),
                            fontWeight:
                                FontWeight.bold,
                          ),
                          decoration:
                              InputDecoration(
                            hintText:
                                'OMAR-xxxxxxxx',
                            hintStyle:
                                const TextStyle(
                              color:
                                  Colors.grey,
                              fontSize: 12,
                            ),
                            filled: true,
                            fillColor:
                                const Color(
                              0xFFF8FAFC,
                            ),
                            enabledBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                16,
                              ),
                              borderSide:
                                  const BorderSide(
                                color:
                                    Color(
                                  0xFFCBD5E1,
                                ),
                              ),
                            ),
                            focusedBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                16,
                              ),
                              borderSide:
                                  const BorderSide(
                                color:
                                    primaryBlue,
                                width: 1.5,
                              ),
                            ),
                            disabledBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                16,
                              ),
                              borderSide:
                                  const BorderSide(
                                color:
                                    Color(
                                  0xFFE2E8F0,
                                ),
                              ),
                            ),
                            contentPadding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          onSubmitted: (_) {
                            if (!_isVerifying) {
                              _verifyLicenseKey();
                            }
                          },
                        ),

                        const SizedBox(
                          height: 30,
                        ),

                        // ==================================================
                        // زر التفعيل
                        // ==================================================

                        SizedBox(
                          height: 52,
                          child:
                              ElevatedButton(
                            style:
                                ElevatedButton
                                    .styleFrom(
                              backgroundColor:
                                  primaryBlue,
                              disabledBackgroundColor:
                                  primaryBlue
                                      .withOpacity(
                                0.6,
                              ),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  16,
                                ),
                              ),
                              elevation: 0,
                            ),
                            onPressed:
                                _isVerifying
                                    ? null
                                    : _verifyLicenseKey,
                            child:
                                _isVerifying
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child:
                                            CircularProgressIndicator(
                                          color:
                                              Colors.white,
                                          strokeWidth:
                                              2,
                                        ),
                                      )
                                    : const Text(
                                        'تحقق وتفعيل النظام 🔓',
                                        style:
                                            TextStyle(
                                          color:
                                              Colors.white,
                                          fontWeight:
                                              FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}