import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';

/// Screen for scanning QR codes and Barcodes with strict scan window restriction and high accuracy.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> with SingleTickerProviderStateMixin {
  late final MobileScannerController _controller;
  late final AnimationController _animationController;

  bool _isTorchOn = false;
  bool _isProcessingResult = false;

  // Viewfinder Dimensions
  final double _viewfinderWidth = 280;
  final double _viewfinderHeight = 280;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
      returnImage: false,
      formats: const [
        BarcodeFormat.qrCode,
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.code93,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.dataMatrix,
        BarcodeFormat.pdf417,
        BarcodeFormat.itf14,
        BarcodeFormat.aztec,
        BarcodeFormat.codabar,
      ],
    );

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessingResult) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    for (final barcode in barcodes) {
      // Prioritize displayValue for accurate decoded barcode numbers/text, fallback to rawValue
      final rawStr = barcode.displayValue?.isNotEmpty == true
          ? barcode.displayValue!
          : (barcode.rawValue ?? '');

      final cleanValue = rawStr.trim();

      if (cleanValue.isNotEmpty) {
        setState(() => _isProcessingResult = true);
        HapticFeedback.mediumImpact();
        _showResultSheet(cleanValue, _formatBarcodeName(barcode.format));
        break;
      }
    }
  }

  String _formatBarcodeName(BarcodeFormat format) {
    switch (format) {
      case BarcodeFormat.qrCode:
        return 'QR Code';
      case BarcodeFormat.ean13:
        return 'EAN-13 Barcode';
      case BarcodeFormat.ean8:
        return 'EAN-8 Barcode';
      case BarcodeFormat.code128:
        return 'Code 128 Barcode';
      case BarcodeFormat.code39:
        return 'Code 39 Barcode';
      case BarcodeFormat.code93:
        return 'Code 93 Barcode';
      case BarcodeFormat.upcA:
        return 'UPC-A Barcode';
      case BarcodeFormat.upcE:
        return 'UPC-E Barcode';
      case BarcodeFormat.dataMatrix:
        return 'Data Matrix';
      case BarcodeFormat.pdf417:
        return 'PDF417 Barcode';
      case BarcodeFormat.aztec:
        return 'Aztec Code';
      case BarcodeFormat.itf14:
        return 'ITF-14 Barcode';
      case BarcodeFormat.codabar:
        return 'Codabar';
      default:
        return 'Barcode';
    }
  }

  void _showResultSheet(String content, String formatTitle) {
    final isUrl = content.startsWith('http://') ||
        content.startsWith('https://') ||
        content.startsWith('www.');

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoftTint,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.qr_code_scanner_rounded,
                            color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Scan Result',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          Text(
                            formatTitle,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      setState(() => _isProcessingResult = false);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Detected Content Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: SelectableText(
                  content,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: content));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard!')),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Copy'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        SharePlus.instance
                            .share(ShareParams(files: [], text: content));
                      },
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text('Share'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
              if (isUrl) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Opening $content')),
                      );
                    },
                    icon: const Icon(Icons.open_in_browser_rounded, size: 18),
                    label: const Text('Open URL in Browser',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final scanWindow = Rect.fromCenter(
      center: Offset(screenSize.width / 2, screenSize.height / 2),
      width: _viewfinderWidth,
      height: _viewfinderHeight,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('QR & Barcode Scanner',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: Icon(
                _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded),
            onPressed: () async {
              await _controller.toggleTorch();
              setState(() => _isTorchOn = !_isTorchOn);
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android_rounded),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Live Camera Stream with strict Scan Window restriction
          MobileScanner(
            controller: _controller,
            scanWindow: scanWindow,
            onDetect: _onDetect,
          ),

          // 2. Dark Translucent Cutout Overlay
          CustomPaint(
            painter: _ScannerOverlayPainter(
              scanWindow: scanWindow,
              borderRadius: 20,
            ),
          ),

          // 3. Viewfinder Frame & Animated Laser Scan line
          Center(
            child: SizedBox(
              width: _viewfinderWidth,
              height: _viewfinderHeight,
              child: Stack(
                children: [
                  // Animated laser line
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Positioned(
                        top: _animationController.value *
                            (_viewfinderHeight - 20),
                        left: 10,
                        right: 10,
                        child: Container(
                          height: 2.5,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppColors.primaryLight,
                                Colors.white,
                                AppColors.primaryLight,
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryLight
                                    .withValues(alpha: 0.6),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Corner Brackets
                  Positioned(
                      top: 0, left: 0, child: _buildCorner(true, true)),
                  Positioned(
                      top: 0, right: 0, child: _buildCorner(true, false)),
                  Positioned(
                      bottom: 0, left: 0, child: _buildCorner(false, true)),
                  Positioned(
                      bottom: 0, right: 0, child: _buildCorner(false, false)),
                ],
              ),
            ),
          ),

          // 4. Instructions Banner
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(24),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.center_focus_strong_rounded,
                        color: Colors.white70, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Place QR or Barcode inside the box',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(bool isTop, bool isLeft) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: AppColors.primaryLight, width: 4)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: AppColors.primaryLight, width: 4)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: AppColors.primaryLight, width: 4)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: AppColors.primaryLight, width: 4)
              : BorderSide.none,
        ),
      ),
    );
  }
}

/// Custom Painter that dims the outside of the scan window and leaves the center transparent.
class _ScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;
  final double borderRadius;

  _ScannerOverlayPainter({
    required this.scanWindow,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          scanWindow,
          Radius.circular(borderRadius),
        ),
      );

    final finalPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    canvas.drawPath(finalPath, backgroundPaint);
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.scanWindow != scanWindow;
  }
}
