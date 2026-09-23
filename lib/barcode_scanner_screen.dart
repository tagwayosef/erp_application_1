import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({Key? key}) : super(key: key);

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  bool _isScanned = false;
  final MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E40AF),
          title: const Text('مسح باركود المنتج أو QR', style: TextStyle(color: Colors.white, fontSize: 16)),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            // زر الفلاش الآمن والمتوافق مع الإصدارات الحديثة
            IconButton(
              icon: const Icon(Icons.flash_on, color: Colors.white),
              onPressed: () => cameraController.toggleTorch(),
            ),
            // زر تبديل الكاميرا الآمن
            IconButton(
              icon: const Icon(Icons.camera_rear, color: Colors.white),
              onPressed: () => cameraController.switchCamera(),
            ),
          ],
        ),
        body: MobileScanner(
          controller: cameraController,
          onDetect: (capture) {
            if (_isScanned) return;
            
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              if (barcode.rawValue != null) {
                _isScanned = true;
                final String code = barcode.rawValue!;
                
                Navigator.pop(context, code);
                break;
              }
            }
          },
        ),
      ),
    );
  }
}