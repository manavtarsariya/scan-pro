import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/document_file.dart';
import '../../services/file_manager_service.dart';
import '../../services/pdf_toolkit_service.dart';
import '../files/pdf_viewer_screen.dart';

/// Screen for selecting and combining multiple PDF files into one.
class MergePdfScreen extends StatefulWidget {
  const MergePdfScreen({super.key});

  @override
  State<MergePdfScreen> createState() => _MergePdfScreenState();
}

class _MergePdfScreenState extends State<MergePdfScreen> {
  final List<DocumentFile> _selectedFiles = [];
  bool _isProcessing = false;
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: PdfToolkitService.generateToolOutputName('Merged').replaceAll('.pdf', ''),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final allFiles = await FileManagerService.loadAllFiles();
    final pdfFiles = allFiles.where((f) => !f.isFolder && f.title.toLowerCase().endsWith('.pdf')).toList();

    if (!mounted) return;

    if (pdfFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No PDF files found in My Files. Scan or import documents first.')),
      );
      return;
    }

    final result = await showModalBottomSheet<List<DocumentFile>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _FilePickerSheet(availableFiles: pdfFiles, initiallySelected: _selectedFiles),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedFiles.clear();
        _selectedFiles.addAll(result);
      });
    }
  }

  Future<void> _mergePdfs() async {
    if (_selectedFiles.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least 2 PDF files to merge.')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    final fileName = _titleController.text.trim();
    final outputFile = await PdfToolkitService.mergePdfs(
      inputPdfPaths: _selectedFiles.map((f) => f.path).toList(),
      outputFileName: fileName.isEmpty ? 'Merged_Document' : fileName,
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
        title: const Text('Merge PDF', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.note_add_rounded),
            tooltip: 'Add PDF',
            onPressed: _pickFiles,
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
                    const Icon(Icons.call_merge_rounded, color: AppColors.primary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText: 'Merged File Name',
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

            // Files Queue or Empty State
            Expanded(
              child: _selectedFiles.isEmpty
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
                              child: const Icon(Icons.call_merge_rounded, size: 48, color: AppColors.primary),
                            ),
                            const SizedBox(height: 16),
                            const Text('No PDFs Selected', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                            const SizedBox(height: 6),
                            const Text('Select 2 or more PDFs from My Files to merge into a single document', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(height: 18),
                            ElevatedButton.icon(
                              onPressed: _pickFiles,
                              icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                              label: const Text('Select PDF Files'),
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
                  : ReorderableListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      itemCount: _selectedFiles.length,
                      onReorderItem: (oldIdx, newIdx) {
                        setState(() {
                          final item = _selectedFiles.removeAt(oldIdx);
                          _selectedFiles.insert(newIdx, item);
                        });
                      },
                      itemBuilder: (ctx, idx) {
                        final file = _selectedFiles[idx];
                        return Container(
                          key: ValueKey(file.path),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoftTint,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${idx + 1}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      file.title,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${file.formattedSize} • ${file.formattedDate}',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
                                onPressed: () => setState(() => _selectedFiles.removeAt(idx)),
                              ),
                              const Icon(Icons.drag_handle_rounded, color: AppColors.textMuted, size: 20),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // Bottom CTA Merge Button
            if (_selectedFiles.isNotEmpty)
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
                    onPressed: _isProcessing ? null : _mergePdfs,
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
                            'Merge ${_selectedFiles.length} PDFs',
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

class _FilePickerSheet extends StatefulWidget {
  final List<DocumentFile> availableFiles;
  final List<DocumentFile> initiallySelected;

  const _FilePickerSheet({required this.availableFiles, required this.initiallySelected});

  @override
  State<_FilePickerSheet> createState() => _FilePickerSheetState();
}

class _FilePickerSheetState extends State<_FilePickerSheet> {
  final List<DocumentFile> _selected = [];

  @override
  void initState() {
    super.initState();
    _selected.addAll(widget.initiallySelected);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Select PDF Documents', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              TextButton(
                onPressed: () => Navigator.of(context).pop(_selected),
                child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: widget.availableFiles.length,
              itemBuilder: (ctx, idx) {
                final file = widget.availableFiles[idx];
                final isPicked = _selected.any((f) => f.path == file.path);
                return CheckboxListTile(
                  value: isPicked,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selected.add(file);
                      } else {
                        _selected.removeWhere((f) => f.path == file.path);
                      }
                    });
                  },
                  title: Text(file.title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                  subtitle: Text('${file.formattedSize} • ${file.formattedDate}', style: const TextStyle(fontSize: 11)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
