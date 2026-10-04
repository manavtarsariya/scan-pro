import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../services/scanner_service.dart';

/// Screen for reviewing, renaming, reordering, and saving scanned documents.
class ScanPreviewScreen extends StatefulWidget {
  final List<String> initialImagePaths;
  final String? initialPdfPath;

  const ScanPreviewScreen({
    super.key,
    required this.initialImagePaths,
    this.initialPdfPath,
  });

  @override
  State<ScanPreviewScreen> createState() => _ScanPreviewScreenState();
}

class _ScanPreviewScreenState extends State<ScanPreviewScreen> {
  late List<String> _imagePaths;
  late TextEditingController _titleController;
  int _currentPageIndex = 0;
  bool _isSaving = false;
  String _selectedFilter = 'Magic Color';

  final List<String> _filterPresets = const [
    'Original',
    'Magic Color',
    'B&W',
    'Grayscale',
    'Lighten',
    'Sharpen',
  ];

  @override
  void initState() {
    super.initState();
    _imagePaths = List.from(widget.initialImagePaths);
    _titleController = TextEditingController(
      text: ScannerService.generateDefaultFileName().replaceAll('.pdf', ''),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _deleteCurrentPage() {
    if (_imagePaths.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A document must have at least one page.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _imagePaths.removeAt(_currentPageIndex);
      if (_currentPageIndex >= _imagePaths.length) {
        _currentPageIndex = _imagePaths.length - 1;
      }
    });
  }

  Future<void> _addMorePages() async {
    final picked = await ScannerService.pickImagesFromGallery();
    if (picked.isNotEmpty) {
      setState(() {
        _imagePaths.addAll(picked);
      });
    }
  }

  Future<void> _saveDocument() async {
    if (_imagePaths.isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final fileName = _titleController.text.trim();
      final savedFile = await ScannerService.createPdfFromImages(
        imagePaths: _imagePaths,
        fileName: fileName.isEmpty ? 'Scan_Document' : fileName,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Saved successfully to My Files! (${savedFile.path.split(Platform.pathSeparator).last})',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save PDF: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = _imagePaths.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark studio preview canvas
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        title: Text(
          'Page ${_currentPageIndex + 1} of $totalPages',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
            tooltip: 'Add Page',
            onPressed: _addMorePages,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFF87171)),
            tooltip: 'Delete Current Page',
            onPressed: _deleteCurrentPage,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Editable File Name Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFDC2626), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _titleController,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        suffixText: '.pdf',
                        suffixStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                    ),
                  ),
                  const Icon(Icons.edit_rounded, color: AppColors.textMuted, size: 16),
                ],
              ),
            ),

            // Middle: Image PageView (A4 Ratio Sheet + Centered Image)
            Expanded(
              child: _imagePaths.isEmpty
                  ? const Center(child: Text('No pages scanned', style: TextStyle(color: Colors.white70)))
                  : PageView.builder(
                      itemCount: _imagePaths.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPageIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final imageFile = File(_imagePaths[index]);
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            child: AspectRatio(
                              aspectRatio: 1 / 1.4142, // Standard A4 Paper Ratio
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.45),
                                      blurRadius: 20,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: InteractiveViewer(
                                  minScale: 1.0,
                                  maxScale: 3.5,
                                  child: Center(
                                    child: Image.file(
                                      imageFile,
                                      fit: BoxFit.contain,
                                      alignment: Alignment.center,
                                      errorBuilder: (context, error, stackTrace) => const Center(
                                        child: Icon(Icons.broken_image_rounded, color: Colors.black38, size: 48),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Bottom Filter Presets & Save Container
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Filter Chips Bar
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: _filterPresets.map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedFilter = filter;
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : const Color(0xFF334155),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                filter,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                  color: isSelected ? Colors.white : Colors.white70,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Save to PDF Button
                  SizedBox(
                    width: double.infinity,
                    height: AppDimensions.buttonHeightCta,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveDocument,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textOnPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save_rounded, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Save PDF to My Files',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
