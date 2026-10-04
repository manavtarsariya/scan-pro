import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/document_file.dart';
import '../../services/file_manager_service.dart';
import '../../services/pdf_toolkit_service.dart';
import '../../services/scanner_service.dart';
import '../files/pdf_viewer_screen.dart';
import '../paywall/paywall_screen.dart';

/// Screen for reordering, rotating, deleting, duplicating, and inserting pages in a PDF.
/// Matches the Stitch "Organize Pages" design system with real drag-and-drop.
class OrganizePagesScreen extends StatefulWidget {
  const OrganizePagesScreen({super.key});

  @override
  State<OrganizePagesScreen> createState() => _OrganizePagesScreenState();
}

class _OrganizePagesScreenState extends State<OrganizePagesScreen> {
  DocumentFile? _selectedPdf;
  List<OrganizePageModel> _pages = [];
  bool _isProcessing = false;
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: PdfToolkitService.generateToolOutputName('Organized').replaceAll('.pdf', ''),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  List<OrganizePageModel> get _selectedPages => _pages.where((p) => p.isSelected).toList();

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
            const Text('Choose PDF to Organize', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: pdfFiles.length,
                itemBuilder: (c, i) {
                  final f = pdfFiles[i];
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.primarySoftTint, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary, size: 22),
                    ),
                    title: Text(f.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                    subtitle: Text('${f.formattedSize} • ${f.formattedDate}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
      final total = await PdfToolkitService.getPdfPageCount(picked.path);
      final count = total > 0 ? total : 1;
      setState(() {
        _selectedPdf = picked;
        _pages = List.generate(
          count,
          (i) => OrganizePageModel(
            id: 'page_${i + 1}_${DateTime.now().millisecondsSinceEpoch}',
            originalPageIndex: i + 1,
            title: 'Page ${i + 1}',
            rotation: 0,
            isSelected: false,
          ),
        );
      });
      _loadThumbnails(picked.path);
    }
  }

  Future<void> _loadThumbnails(String pdfPath) async {
    for (int i = 0; i < _pages.length; i++) {
      if (!_pages[i].isInsertedImage && !_pages[i].isBlankPage) {
        final pageNum = _pages[i].originalPageIndex;
        final bytes = await PdfToolkitService.renderPdfPageThumbnail(pdfPath, pageNum);
        if (bytes != null && mounted) {
          setState(() {
            _pages[i].thumbnailBytes = bytes;
          });
        }
      }
    }
  }

  void _toggleSelectPage(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _pages[index].isSelected = !_pages[index].isSelected;
    });
  }

  void _selectAll() {
    setState(() {
      for (var p in _pages) {
        p.isSelected = true;
      }
    });
  }

  void _deselectAll() {
    setState(() {
      for (var p in _pages) {
        p.isSelected = false;
      }
    });
  }

  void _rotateSelectedPages({required bool clockwise}) {
    HapticFeedback.lightImpact();
    setState(() {
      final targets = _selectedPages.isNotEmpty ? _selectedPages : _pages;
      for (var p in targets) {
        final change = clockwise ? 90 : -90;
        p.rotation = (p.rotation + change) % 360;
        if (p.rotation < 0) p.rotation += 360;
      }
    });
  }

  void _duplicateSelectedPages() {
    final targets = _selectedPages.isNotEmpty ? _selectedPages : [];
    if (targets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one page to duplicate.')),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      for (var p in targets) {
        final newIndex = _pages.indexOf(p) + 1;
        final duplicate = p.copyWith(
          id: 'dup_${p.id}_${DateTime.now().millisecondsSinceEpoch}',
          title: '${p.title} (Copy)',
          isSelected: false,
        );
        _pages.insert(newIndex, duplicate);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Duplicated ${targets.length} page(s)')),
    );
  }

  void _deleteSelectedPages() {
    final targets = _selectedPages.isNotEmpty ? _selectedPages : [];
    if (targets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one page to delete.')),
      );
      return;
    }

    if (_pages.length - targets.length < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A document must have at least 1 page.'), backgroundColor: AppColors.error),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _pages.removeWhere((p) => p.isSelected);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Removed ${targets.length} page(s)')),
    );
  }

  void _extractSelectedPages() async {
    final targets = _selectedPages;
    if (targets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select pages to extract into a new PDF.')),
      );
      return;
    }

    setState(() => _isProcessing = true);
    final extractFileName = 'Extract_${DateTime.now().millisecondsSinceEpoch}';
    final outputFile = await PdfToolkitService.organizePages(
      sourcePdfPath: _selectedPdf!.path,
      newPageOrder: targets.map((p) => p.originalPageIndex).toList(),
      pageRotations: {for (var p in targets) p.originalPageIndex: p.rotation},
      detailedPages: targets,
      outputFileName: extractFileName,
    );
    setState(() => _isProcessing = false);

    if (outputFile != null && mounted) {
      final stat = await outputFile.stat();
      final doc = DocumentFile(
        path: outputFile.path,
        title: outputFile.path.split(Platform.pathSeparator).last,
        sizeInBytes: stat.size,
        modifiedTime: stat.modified,
        pageCount: targets.length,
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PdfViewerScreen(document: doc)),
      );
    }
  }

  void _reorderPage(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    HapticFeedback.mediumImpact();
    setState(() {
      final item = _pages.removeAt(oldIndex);
      _pages.insert(newIndex, item);
    });
  }

  Future<int?> _askInsertPosition() async {
    final selectedIdx = _pages.indexWhere((p) => p.isSelected);
    final hasSelection = selectedIdx != -1;

    return await showModalBottomSheet<int>(
      context: context,
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
              const Text(
                'Where to insert page?',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoftTint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.last_page_rounded, color: AppColors.primary),
                ),
                title: const Text('At the End of Document', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('Insert as Page ${_pages.length + 1} (Last Page)', style: const TextStyle(fontSize: 12)),
                onTap: () => Navigator.pop(ctx, _pages.length),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoftTint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.vertical_align_center_rounded, color: AppColors.primary),
                ),
                title: Text(
                  hasSelection
                      ? 'After Selected Page (After Page ${selectedIdx + 1})'
                      : 'At the Beginning (Page 1)',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  hasSelection
                      ? 'Insert right beside/after page ${selectedIdx + 1}'
                      : 'Insert as the very first page',
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () => Navigator.pop(ctx, hasSelection ? selectedIdx + 1 : 0),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showInsertPageModal() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Insert New Page', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.primarySoftTint, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                ),
                title: const Text('Scan Page with Camera', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Take a photo to insert as a page', style: TextStyle(fontSize: 12)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final insertPosition = await _askInsertPosition();
                  if (insertPosition == null) return;

                  final result = await ScannerService.startDocumentScan(pageLimit: 1);
                  if (result.isSuccess && result.imagePaths.isNotEmpty) {
                    setState(() {
                      int pos = insertPosition;
                      for (final img in result.imagePaths) {
                        _pages.insert(
                          pos++,
                          OrganizePageModel(
                            id: 'scan_${DateTime.now().millisecondsSinceEpoch}',
                            originalPageIndex: -1,
                            imagePath: img,
                            isInsertedImage: true,
                            title: 'Scanned Page',
                          ),
                        );
                      }
                    });
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.primarySoftTint, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                ),
                title: const Text('Import from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Pick images from photo album', style: TextStyle(fontSize: 12)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final insertPosition = await _askInsertPosition();
                  if (insertPosition == null) return;

                  final picked = await ScannerService.pickImagesFromGallery();
                  if (picked.isNotEmpty) {
                    setState(() {
                      int pos = insertPosition;
                      for (final img in picked) {
                        _pages.insert(
                          pos++,
                          OrganizePageModel(
                            id: 'gallery_${DateTime.now().millisecondsSinceEpoch}',
                            originalPageIndex: -1,
                            imagePath: img,
                            isInsertedImage: true,
                            title: 'Gallery Image',
                          ),
                        );
                      }
                    });
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.primarySoftTint, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.note_add_outlined, color: AppColors.primary),
                ),
                title: const Text('Insert Blank A4 Page', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Adds an empty white page to document', style: TextStyle(fontSize: 12)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final insertPosition = await _askInsertPosition();
                  if (insertPosition == null) return;

                  setState(() {
                    _pages.insert(
                      insertPosition,
                      OrganizePageModel(
                        id: 'blank_${DateTime.now().millisecondsSinceEpoch}',
                        originalPageIndex: -1,
                        isBlankPage: true,
                        title: 'Blank Page',
                      ),
                    );
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveOrganizedPdf() async {
    if (_selectedPdf == null || _pages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a PDF document.')));
      return;
    }

    setState(() => _isProcessing = true);

    final fileName = _titleController.text.trim();
    final outputFile = await PdfToolkitService.organizePages(
      sourcePdfPath: _selectedPdf!.path,
      newPageOrder: _pages.map((p) => p.originalPageIndex).toList(),
      pageRotations: {for (var p in _pages) p.originalPageIndex: p.rotation},
      detailedPages: _pages,
      outputFileName: fileName.isEmpty ? 'Organized_Doc' : fileName,
    );

    setState(() => _isProcessing = false);

    if (outputFile != null && mounted) {
      final stat = await outputFile.stat();
      final docFile = DocumentFile(
        path: outputFile.path,
        title: outputFile.path.split(Platform.pathSeparator).last,
        sizeInBytes: stat.size,
        modifiedTime: stat.modified,
        pageCount: _pages.length,
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
    final selectedCount = _selectedPages.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFE0E7FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome_mosaic_rounded, color: Color(0xFF4338CA), size: 18),
            ),
            const SizedBox(width: 8),
            const Text(
              'Organize Pages',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.workspace_premium_rounded, color: Colors.amber),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen(isFromOnboarding: false)));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _selectedPdf == null
            ? _buildNoPdfSelectedView()
            : Column(
                children: [
                  // 1. Document Header Bar
                  _buildDocumentHeaderBar(),

                  // 2. Selection Info & Action Toolbar
                  _buildActionToolbar(selectedCount),

                  // 3. Page Grid with Drag & Drop Reorder / Rotation / Selection
                  Expanded(
                    child: _buildPagesGrid(),
                  ),

                  // 4. Bottom Action Buttons
                  _buildBottomButtons(),
                ],
              ),
      ),
    );
  }

  Widget _buildNoPdfSelectedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.primarySoftTint, shape: BoxShape.circle),
              child: const Icon(Icons.auto_awesome_mosaic_rounded, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text('No PDF Selected', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 6),
            const Text(
              'Choose a PDF to reorder, rotate, duplicate, extract, or insert pages',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _pickSourcePdf,
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
              label: const Text('Choose PDF Document', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentHeaderBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          const Icon(Icons.description_rounded, color: Color(0xFF2563EB), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _selectedPdf!.title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${_pages.length} Pages',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.primary, size: 20),
            tooltip: 'Change Document',
            onPressed: _pickSourcePdf,
          ),
        ],
      ),
    );
  }

  Widget _buildActionToolbar(int selectedCount) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        children: [
          // Subtitle info row: "• 2 Pages Selected" | Select All | Deselect
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    selectedCount > 0
                        ? '$selectedCount Pages Selected'
                        : 'Tap to select • Drag cards to reorder',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selectedCount > 0 ? FontWeight.w700 : FontWeight.w500,
                      color: selectedCount > 0 ? const Color(0xFF1E293B) : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: _selectAll,
                    child: const Text('Select All', style: TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                  ),
                  const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
                  GestureDetector(
                    onTap: _deselectAll,
                    child: const Text('Deselect', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 5 Action Buttons: [Rot L] [Rot R] [Copy] [Extract] [Delete]
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildToolbarItem(
                icon: Icons.rotate_left_rounded,
                label: 'Rot L',
                onTap: () => _rotateSelectedPages(clockwise: false),
              ),
              _buildToolbarItem(
                icon: Icons.rotate_right_rounded,
                label: 'Rot R',
                onTap: () => _rotateSelectedPages(clockwise: true),
              ),
              _buildToolbarItem(
                icon: Icons.copy_rounded,
                label: 'Copy',
                onTap: _duplicateSelectedPages,
              ),
              _buildToolbarItem(
                icon: Icons.call_split_rounded,
                label: 'Extract',
                onTap: _extractSelectedPages,
              ),
              _buildToolbarItem(
                icon: Icons.delete_outline_rounded,
                label: 'Delete',
                isDestructive: true,
                onTap: _deleteSelectedPages,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? const Color(0xFFDC2626) : const Color(0xFF334155);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagesGrid() {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.76,
      ),
      itemCount: _pages.length,
      itemBuilder: (ctx, idx) {
        final page = _pages[idx];

        return DragTarget<int>(
          onWillAcceptWithDetails: (details) => details.data != idx,
          onAcceptWithDetails: (details) {
            _reorderPage(details.data, idx);
          },
          builder: (context, candidateData, rejectedData) {
            final isHovered = candidateData.isNotEmpty;

            return LongPressDraggable<int>(
              data: idx,
              delay: const Duration(milliseconds: 150),
              hapticFeedbackOnStart: true,
              feedback: Material(
                color: Colors.transparent,
                child: SizedBox(
                  width: 170,
                  height: 224,
                  child: Opacity(
                    opacity: 0.9,
                    child: _buildPageCard(page, idx, isDragging: true),
                  ),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.25,
                child: _buildPageCard(page, idx),
              ),
              child: AnimatedScale(
                scale: isHovered ? 1.04 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: _buildPageCard(page, idx, isHovered: isHovered),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPageCard(
    OrganizePageModel page,
    int index, {
    bool isHovered = false,
    bool isDragging = false,
  }) {
    final isSelected = page.isSelected;

    return GestureDetector(
      onTap: () => _toggleSelectPage(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHovered
                ? const Color(0xFF10B981)
                : isSelected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFE2E8F0),
            width: (isHovered || isSelected) ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDragging
                  ? Colors.black.withValues(alpha: 0.3)
                  : isSelected
                      ? const Color(0xFF2563EB).withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.04),
              blurRadius: isDragging ? 18 : 10,
              offset: isDragging ? const Offset(0, 8) : const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Badge Bar: [Page #] [Rotation Tag] [Select Check]
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page Number
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),

                  // Interactive Quick Rotate Button & Badge
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        page.rotation = (page.rotation + 90) % 360;
                      });
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: page.rotation != 0 ? const Color(0xFF7C3AED) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.rotate_right_rounded,
                            size: 13,
                            color: page.rotation != 0 ? Colors.white : AppColors.textSecondary,
                          ),
                          if (page.rotation != 0) ...[
                            const SizedBox(width: 2),
                            Text(
                              '${page.rotation}°',
                              style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Selection Checkbox Circle
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 13, color: Colors.white)
                        : null,
                  ),
                ],
              ),
            ),

            // Middle Thumbnail / Document Canvas Preview
            Expanded(
              child: Center(
                child: RotatedBox(
                  quarterTurns: (page.rotation / 90).round(),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: page.thumbnailBytes != null
                        ? Image.memory(
                            page.thumbnailBytes!,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image_rounded, color: Colors.black26),
                          )
                        : (page.isInsertedImage && page.imagePath != null)
                            ? Image.file(
                                File(page.imagePath!),
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image_rounded, color: Colors.black26),
                              )
                            : page.isBlankPage
                                ? const Center(
                                    child: Text('Blank Page', style: TextStyle(color: Colors.black38, fontSize: 11, fontWeight: FontWeight.bold)),
                                  )
                                : const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                                    ),
                                  ),
                  ),
                ),
              ),
            ),

            // Bottom Footer: Label + Drag Handle icon
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      page.title,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.drag_indicator_rounded, size: 18, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Insert Blank / Scan Page Button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: _showInsertPageModal,
              icon: const Icon(Icons.add_circle_outline_rounded, size: 18, color: Color(0xFF2563EB)),
              label: const Text(
                'Insert Blank / Scan Page',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 2. Save Changes Button
          SizedBox(
            width: double.infinity,
            height: AppDimensions.buttonHeightCta,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _saveOrganizedPdf,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isProcessing
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Save Changes (${_pages.length} Pages)',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
