// lib/screens/qr_scanner_screen.dart - ĐÃ TÍCH HỢP MOBILE_SCANNER
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/activity_provider.dart';
import '../theme/app_theme.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({Key? key}) : super(key: key);

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  String? _scanResult;
  bool _isProcessing = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    setState(() {
      _isProcessing = true;
      _scanResult = barcode!.rawValue;
    });

    // Stop camera
    await cameraController.stop();

    if (!mounted) return;

    // Call API điểm danh
    try {
      final provider = Provider.of<ActivityProvider>(context, listen: false);
      await provider.markAttendance(_scanResult!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Điểm danh thành công!'),
          backgroundColor: AppTheme.secondaryColor,
        ),
      );

      // Đợi 1.5s rồi quay lại
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${e.toString().replaceAll("Exception: ", "")}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );

      // Cho phép quét lại
      setState(() {
        _isProcessing = false;
        _scanResult = null;
      });
      cameraController.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          // App Bar
          Container(
            padding:
                const EdgeInsets.only(top: 48, left: 16, right: 16, bottom: 16),
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Quét mã QR điểm danh',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Camera View
          Expanded(
            child: Stack(
              children: [
                MobileScanner(
                  controller: cameraController,
                  onDetect: _handleBarcode,
                ),

                // Overlay
                CustomPaint(
                  painter: ScannerOverlay(),
                  child: Container(),
                ),

                // Status
                if (_scanResult != null)
                  Positioned(
                    bottom: 40,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 12,
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          const CircularProgressIndicator(color: Colors.white),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _isProcessing
                                  ? 'Đang điểm danh...'
                                  : 'Đã quét: $_scanResult',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Instructions
          Container(
            padding: const EdgeInsets.all(24),
            color: AppTheme.surfaceColor,
            child: Column(
              children: const [
                Icon(Icons.qr_code_scanner,
                    size: 48, color: AppTheme.primaryColor),
                SizedBox(height: 12),
                Text(
                  'Hướng camera vào mã QR do BTC cung cấp',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Mã QR sẽ tự động được quét khi vào khung hình',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter cho overlay scanner
class ScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Dark overlay
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()
          ..addRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(size.width / 2, size.height / 2),
              width: 280,
              height: 280,
            ),
            const Radius.circular(20),
          ))
          ..close(),
      ),
      paint,
    );

    // Corner borders
    final borderPaint = Paint()
      ..color = AppTheme.secondaryColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final cornerSize = 30.0;
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final halfSize = 140.0;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(centerX - halfSize, centerY - halfSize + cornerSize)
        ..lineTo(centerX - halfSize, centerY - halfSize)
        ..lineTo(centerX - halfSize + cornerSize, centerY - halfSize),
      borderPaint,
    );

    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(centerX + halfSize - cornerSize, centerY - halfSize)
        ..lineTo(centerX + halfSize, centerY - halfSize)
        ..lineTo(centerX + halfSize, centerY - halfSize + cornerSize),
      borderPaint,
    );

    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(centerX - halfSize, centerY + halfSize - cornerSize)
        ..lineTo(centerX - halfSize, centerY + halfSize)
        ..lineTo(centerX - halfSize + cornerSize, centerY + halfSize),
      borderPaint,
    );

    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(centerX + halfSize - cornerSize, centerY + halfSize)
        ..lineTo(centerX + halfSize, centerY + halfSize)
        ..lineTo(centerX + halfSize, centerY + halfSize - cornerSize),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
