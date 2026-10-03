import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/document_file.dart';
import '../../services/scanner_service.dart';
import '../files/pdf_viewer_screen.dart';

/// Screen for scanning both Front and Back sides of an ID Card and combining them on a single A4 page.
class IdCardScanScreen extends StatefulWidget {
  const IdCardScanScreen({super.key});

  @override
  State<IdCardScanScreen> createState() => _IdCardScanScreenState();
}

class _IdCardScanScreenState extends State<IdCardScanScreen> {
  String? _frontImagePath;
  String? _backImagePath;
  bool _isProcessing = false;
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: 'ID_Card_${DateTime.now().millisecondsSinceEpoch % 10000}');
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _captureSide(bool isFront) async {
    final result = await ScannerService.startDocumentScan(pageLimit: 1);
    if (result.isSuccess && result.imagePaths.isNotEmpty && mounted) {
      setState(() {
        if (isFront) {
          _frontImagePath = result.imagePaths.first;
        } else {
          _backImagePath = result.imagePaths.first;
        }
      });
    }
  }

  Future<void> _pickFromGallery(bool isFront) async {
    final picked = await ScannerService.pickImagesFromGallery();
    if (picked.isNotEmpty && mounted) {
      setState(() {
        if (isFront) {
          _frontImagePath = picked.first;
        } else {
          _backImagePath = picked.first;
        }
      });
    }
  }

  Future<void> _saveIdCardPdf() async {
    if (_frontImagePath == null || _backImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture both Front and Back sides.')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    final fileName = _titleController.text.trim();
    final outputFile = await ScannerService.createIdCardPdf(
      frontImagePath: _frontImagePath!,
      backImagePath: _backImagePath!,
      fileName: fileName.isEmpty ? 'ID_Card_Document' : fileName,
    );

    setState(() => _isProcessing = false);

    if (mounted) {
      final stat = await outputFile.stat();
      final docFile = DocumentFile(
        path: outputFile.path,
        title: outputFile.path.split(Platform.pathSeparator).last,
        sizeInBytes: stat.size,
        modifiedTime: stat.modified,
        pageCount: 1,
        categoryTag: 'ID Cards',
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PdfViewerScreen(document: docFile),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReady = _frontImagePath != null && _backImagePath != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('ID Card 2-Side Scan', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Output Document Name
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.badge_rounded, color: AppColors.primary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText: 'Document Name',
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                    const Text('.pdf', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Step 1: Front Side Card
              _buildCardSlot(
                title: 'FRONT SIDE',
                subtitle: 'Aadhaar / PAN / License (Front)',
                imagePath: _frontImagePath,
                isFront: true,
              ),
              const SizedBox(height: 16),

              // Step 2: Back Side Card
              _buildCardSlot(
                title: 'BACK SIDE',
                subtitle: 'Address / Details (Back)',
                imagePath: _backImagePath,
                isFront: false,
              ),
              const SizedBox(height: 24),

              // Helper Tip Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5EE),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Both sides will be automatically aligned and compiled onto a single standard A4 page.',
                        style: TextStyle(fontSize: 11.5, color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Save CTA Button
              SizedBox(
                width: double.infinity,
                height: AppDimensions.buttonHeightCta,
                child: ElevatedButton.icon(
                  onPressed: isReady && !_isProcessing ? _saveIdCardPdf : null,
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
                  label: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                      : const Text(
                          'Save 2-in-1 A4 PDF',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardSlot({
    required String title,
    required String subtitle,
    required String? imagePath,
    required bool isFront,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: imagePath != null ? AppColors.primary : const Color(0xFFE2E8F0),
          width: imagePath != null ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: imagePath != null ? AppColors.primary : AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                if (imagePath != null)
                  TextButton.icon(
                    onPressed: () => _captureSide(isFront),
                    icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.primary),
                    label: const Text('Retake', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Body Viewport
          if (imagePath == null)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _captureSide(isFront),
                      icon: const Icon(Icons.camera_alt_rounded, size: 18),
                      label: const Text('Scan Camera'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickFromGallery(isFront),
                      icon: const Icon(Icons.photo_library_rounded, size: 18),
                      label: const Text('Gallery'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: FileImage(File(imagePath)),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  alignment: Alignment.bottomRight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text('Captured', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
