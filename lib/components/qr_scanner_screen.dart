import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../core/app_colors.dart';

enum ScannerMode { qr, barcode }

class QRScannerScreen extends StatefulWidget {
  final bool isDarkMode;
  final ScannerMode mode;

  const QRScannerScreen({
    super.key,
    required this.isDarkMode,
    this.mode = ScannerMode.qr,
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  late MobileScannerController cameraController;
  bool _isFound = false;

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      formats: [BarcodeFormat.all], // التوجيه لقراءة كافة أنواع الأكواد (بما فيها الباركود 1D)
    );
  }

  @override
  Widget build(BuildContext context) {
    // Adjust overlay dimensions based on mode
    final double overlayWidth = widget.mode == ScannerMode.qr ? 250 : 300;
    final double overlayHeight = widget.mode == ScannerMode.qr ? 250 : 120;
    final String helperText = widget.mode == ScannerMode.qr 
        ? 'قم بتوجيه الكاميرا نحو رمز QR' 
        : 'قم بتوجيه الكاميرا نحو الباركود';
    final String titleText = widget.mode == ScannerMode.qr ? 'مسح رمز QR' : 'مسح الباركود';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          titleText,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: widget.isDarkMode ? Colors.white : Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.white),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              if (_isFound) return;
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _isFound = true;
                  Navigator.pop(context, barcode.rawValue);
                  break;
                }
              }
            },
          ),
          // Scanner Overlay
          Center(
            child: Container(
              width: overlayWidth,
              height: overlayHeight,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.accentBlue, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                   // Add a horizontal scanning line for barcode mode
                   if (widget.mode == ScannerMode.barcode)
                     Center(
                       child: Container(
                         width: overlayWidth - 20,
                         height: 2,
                         color: Colors.red.withValues(alpha: 0.5),
                       ),
                     ),
                ],
              ),
            ),
          ),
          // Helper Text
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  helperText,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}
