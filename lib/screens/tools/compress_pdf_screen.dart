import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/document_file.dart';
import '../../services/file_manager_service.dart';
import '../../services/pdf_toolkit_service.dart';
import '../files/pdf_viewer_screen.dart';

/// Screen for reducing PDF file size using compression levels.
class CompressPdfScreen extends StatefulWidget {
  const CompressPdfScreen({super.key});

  @override
  State<CompressPdfScreen> createState() => _CompressPdfScreenState();
}

class _CompressPdfScreenState extends State<CompressPdfScreen> {
  DocumentFile? _selectedPdf;
  int _compressionLevel = 2; // 1 = Basic, 2 = Recommended, 3 = Extreme
  bool _isProcessing = false;
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: PdfToolkitService.generateToolOutputName('Compressed').replaceAll('.pdf', ''),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickSourcePdf() async {
    final allFiles = await FileManagerService.loadAllFiles();
    final pdfFiles = allFiles.where((f) => !f.isFolder && f.title.toLowerCase().endsWith('.pdf')).toList();

    if (!mounted) return;

    if (pdfFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No PDF files found in My Files. Scan or import documents first.')),
      );
      return;
    }

    final picked = await showModalBottomSheet<DocumentFile>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            const Text('Choose PDF to Compress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: pdfFiles.length,
                itemBuilder: (c, i) {
                  final f = pdfFiles[i];
                  return ListTile(
                    leading: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary),
                    title: Text(f.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                    subtitle: Text('${f.formattedSize} • ${f.formattedDate}', style: const TextStyle(fontSize: 11)),
                    onTap: () => Navigator.of(c).pop(f),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (picked != null) {
      setState(() {
        _selectedPdf = picked;
      });
    }
  }

  Future<void> _compressPdf() async {
    if (_selectedPdf == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a PDF document.')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    final fileName = _titleController.text.trim();
    final outputFile = await PdfToolkitService.compressPdf(
      sourcePdfPath: _selectedPdf!.path,
      compressionLevel: _compressionLevel,
      outputFileName: fileName.isEmpty ? 'Compressed_Doc' : fileName,
    );

    setState(() => _isProcessing = false);

    if (outputFile != null && mounted) {
      final stat = await outputFile.stat();
      final docFile = DocumentFile(
        path: outputFile.path,
        title: outputFile.path.split(Platform.pathSeparator).last,
        sizeInBytes: stat.size,
        modifiedTime: stat.modified,
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
        title: const Text('Compress PDF', style: TextStyle(fontWeight: FontWeight.w700)),
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
                    const Icon(Icons.compress_rounded, color: AppColors.primary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText: 'Compressed File Name',
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

            // Main Source PDF and Level Selector
            Expanded(
              child: _selectedPdf == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.primarySoftTint,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.compress_rounded, size: 48, color: AppColors.primary),
                            ),
                            const SizedBox(height: 16),
                            const Text('No PDF Selected', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                            const SizedBox(height: 6),
                            const Text('Select a PDF to reduce its file size without losing readability', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(height: 18),
                            ElevatedButton.icon(
                              onPressed: _pickSourcePdf,
                              icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                              label: const Text('Choose PDF Document'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      children: [
                        // Selected File Info Card
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoftTint,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedPdf!.title,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Original Size: ${_selectedPdf!.formattedSize}',
                                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: _pickSourcePdf,
                                child: const Text('Change', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Compression Level Header
                        const Text(
                          'Select Compression Level',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 12),

                        // Compression Level Radio Tiles
                        _buildCompressionOption(
                          level: 1,
                          title: 'Basic Compression',
                          subtitle: 'High quality, mild reduction (approx ~20-30% smaller)',
                          tag: 'Quality',
                        ),
                        const SizedBox(height: 10),
                        _buildCompressionOption(
                          level: 2,
                          title: 'Recommended (Balanced)',
                          subtitle: 'Good quality, medium file size (approx ~50% smaller)',
                          tag: 'Best',
                        ),
                        const SizedBox(height: 10),
                        _buildCompressionOption(
                          level: 3,
                          title: 'Extreme Compression',
                          subtitle: 'Smallest file size, standard quality (approx ~70% smaller)',
                          tag: 'Smallest',
                        ),
                      ],
                    ),
            ),

            // Bottom CTA Compress Button
            if (_selectedPdf != null)
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
                    onPressed: _isProcessing ? null : _compressPdf,
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
                        : const Text(
                            'Compress PDF Now',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompressionOption({
    required int level,
    required String title,
    required String subtitle,
    required String tag,
  }) {
    final isSelected = _compressionLevel == level;

    return InkWell(
      onTap: () => setState(() => _compressionLevel = level),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primarySoftTint : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
