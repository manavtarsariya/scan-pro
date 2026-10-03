import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/document_file.dart';
import '../../services/pdf_toolkit_service.dart';
import '../../services/scanner_service.dart';
import '../files/pdf_viewer_screen.dart';

/// Screen for converting multiple gallery images into a single A4 PDF document.
class ImageToPdfScreen extends StatefulWidget {
  const ImageToPdfScreen({super.key});

  @override
  State<ImageToPdfScreen> createState() => _ImageToPdfScreenState();
}

class _ImageToPdfScreenState extends State<ImageToPdfScreen> {
  final List<String> _imagePaths = [];
  bool _isProcessing = false;
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: PdfToolkitService.generateToolOutputName('Images').replaceAll('.pdf', ''),
    );
    _pickImages();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await ScannerService.pickImagesFromGallery();
    if (picked.isNotEmpty) {
      setState(() {
        _imagePaths.addAll(picked);
      });
    }
  }

  Future<void> _convertToPdf() async {
    if (_imagePaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one image.')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    final fileName = _titleController.text.trim();
    final outputFile = await PdfToolkitService.convertImagesToPdf(
      imagePaths: _imagePaths,
      outputFileName: fileName.isEmpty ? 'Images_Doc' : fileName,
    );

    setState(() => _isProcessing = false);

    if (outputFile != null && mounted) {
      final stat = await outputFile.stat();
      final docFile = DocumentFile(
        path: outputFile.path,
        title: outputFile.path.split(Platform.pathSeparator).last,
        sizeInBytes: stat.size,
        modifiedTime: stat.modified,
        pageCount: _imagePaths.length,
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Image to PDF', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_rounded),
            tooltip: 'Add Images',
            onPressed: _pickImages,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Title Input Card
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 24),
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
            ),

            // Image Grid or Empty State
            Expanded(
              child: _imagePaths.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoftTint,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.photo_library_rounded, size: 48, color: AppColors.primary),
                          ),
                          const SizedBox(height: 16),
                          const Text('No Images Selected', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          const SizedBox(height: 6),
                          const Text('Select images from your gallery to create a PDF', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(height: 18),
                          ElevatedButton.icon(
                            onPressed: _pickImages,
                            icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                            label: const Text('Pick Images'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: _imagePaths.length + 1,
                      itemBuilder: (ctx, idx) {
                        if (idx == _imagePaths.length) {
                          return InkWell(
                            onTap: _pickImages,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.primary, width: 1.5, strokeAlign: BorderSide.strokeAlignCenter),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_rounded, color: AppColors.primary, size: 30),
                                  SizedBox(height: 4),
                                  Text('Add More', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          );
                        }

                        final path = _imagePaths[idx];
                        return Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                image: DecorationImage(image: FileImage(File(path)), fit: BoxFit.cover),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                            ),
                            // Page Number Badge
                            Positioned(
                              top: 6,
                              left: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${idx + 1}',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            // Delete Button
                            Positioned(
                              top: 6,
                              right: 6,
                              child: InkWell(
                                onTap: () => setState(() => _imagePaths.removeAt(idx)),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),

            // Bottom CTA Convert Button
            if (_imagePaths.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: AppDimensions.buttonHeightCta,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _convertToPdf,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text(
                            'Generate PDF (${_imagePaths.length} Pages)',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
