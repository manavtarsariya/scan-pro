import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/document_file.dart';
import '../../services/file_manager_service.dart';
import '../../services/pdf_toolkit_service.dart';
import '../files/pdf_viewer_screen.dart';

/// Screen for selecting specific pages from a PDF and extracting them into a new document.
class SplitPdfScreen extends StatefulWidget {
  const SplitPdfScreen({super.key});

  @override
  State<SplitPdfScreen> createState() => _SplitPdfScreenState();
}

class _SplitPdfScreenState extends State<SplitPdfScreen> {
  DocumentFile? _selectedPdf;
  int _totalPages = 0;
  final Set<int> _selectedPageNumbers = {}; // 1-indexed
  bool _isProcessing = false;
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: PdfToolkitService.generateToolOutputName('Split').replaceAll('.pdf', ''),
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
            const Text('Choose PDF to Split', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
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
      final pageCount = await PdfToolkitService.getPdfPageCount(picked.path);
      setState(() {
        _selectedPdf = picked;
        _totalPages = pageCount > 0 ? pageCount : 1;
        _selectedPageNumbers.clear();
        _selectedPageNumbers.add(1); // Default select page 1
      });
    }
  }

  Future<void> _splitPdf() async {
    if (_selectedPdf == null || _selectedPageNumbers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one page to extract.')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    final sortedPages = _selectedPageNumbers.toList()..sort();
    final fileName = _titleController.text.trim();
    final outputFile = await PdfToolkitService.splitPdf(
      sourcePdfPath: _selectedPdf!.path,
      selectedPages: sortedPages,
      outputFileName: fileName.isEmpty ? 'Extracted_Doc' : fileName,
    );

    setState(() => _isProcessing = false);

    if (outputFile != null && mounted) {
      final stat = await outputFile.stat();
      final docFile = DocumentFile(
        path: outputFile.path,
        title: outputFile.path.split(Platform.pathSeparator).last,
        sizeInBytes: stat.size,
        modifiedTime: stat.modified,
        pageCount: sortedPages.length,
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
        title: const Text('Split PDF', style: TextStyle(fontWeight: FontWeight.w700)),
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
                    const Icon(Icons.call_split_rounded, color: AppColors.primary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText: 'Output File Name',
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

            // Main Source PDF and Page Picker
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
                              child: const Icon(Icons.call_split_rounded, size: 48, color: AppColors.primary),
                            ),
                            const SizedBox(height: 16),
                            const Text('No PDF Selected', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                            const SizedBox(height: 6),
                            const Text('Pick a multi-page PDF document to extract specific pages', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
                                      '$_totalPages pages total • ${_selectedPdf!.formattedSize}',
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
                        const SizedBox(height: 20),

                        // Pages Grid Selector Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Select Pages to Extract (${_selectedPageNumbers.length} / $_totalPages)',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  if (_selectedPageNumbers.length == _totalPages) {
                                    _selectedPageNumbers.clear();
                                  } else {
                                    _selectedPageNumbers.addAll(List.generate(_totalPages, (i) => i + 1));
                                  }
                                });
                              },
                              child: Text(
                                _selectedPageNumbers.length == _totalPages ? 'Deselect All' : 'Select All',
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Page Badges Grid
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: _totalPages,
                          itemBuilder: (ctx, idx) {
                            final pageNum = idx + 1;
                            final isSelected = _selectedPageNumbers.contains(pageNum);
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedPageNumbers.remove(pageNum);
                                  } else {
                                    _selectedPageNumbers.add(pageNum);
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isSelected ? Icons.check_circle_rounded : Icons.article_rounded,
                                      color: isSelected ? Colors.white : AppColors.textSecondary,
                                      size: 22,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Page $pageNum',
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
            ),

            // Bottom CTA Split Button
            if (_selectedPdf != null && _selectedPageNumbers.isNotEmpty)
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
                    onPressed: _isProcessing ? null : _splitPdf,
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
                            'Extract ${_selectedPageNumbers.length} Pages to New PDF',
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
