import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/document_file.dart';
import '../../services/file_manager_service.dart';
import '../../services/pdf_toolkit_service.dart';
import '../files/pdf_viewer_screen.dart';

/// Screen for drawing signature and stamping it onto a PDF page.
class EsignScreen extends StatefulWidget {
  const EsignScreen({super.key});

  @override
  State<EsignScreen> createState() => _EsignScreenState();
}

class _EsignScreenState extends State<EsignScreen> {
  DocumentFile? _selectedPdf;
  int _targetPage = 1;
  int _totalPages = 1;
  final List<Offset?> _points = [];
  bool _isProcessing = false;
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: PdfToolkitService.generateToolOutputName('Signed').replaceAll('.pdf', ''),
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
            const Text('Choose PDF to Sign', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
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
      final pages = await PdfToolkitService.getPdfPageCount(picked.path);
      setState(() {
        _selectedPdf = picked;
        _totalPages = pages > 0 ? pages : 1;
        _targetPage = 1;
      });
    }
  }

  Future<Uint8List?> _renderSignatureToBytes() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, 300, 150),
    );

    final paint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5;

    for (int i = 0; i < _points.length - 1; i++) {
      if (_points[i] != null && _points[i + 1] != null) {
        canvas.drawLine(_points[i]!, _points[i + 1]!, paint);
      }
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(300, 150);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<void> _signAndSave() async {
    if (_selectedPdf == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a PDF document.')));
      return;
    }

    if (_points.where((p) => p != null).length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please draw your signature first.')));
      return;
    }

    setState(() => _isProcessing = true);

    final signatureBytes = await _renderSignatureToBytes();
    if (signatureBytes == null) {
      setState(() => _isProcessing = false);
      return;
    }

    final fileName = _titleController.text.trim();
    final outputFile = await PdfToolkitService.addSignatureToPdf(
      sourcePdfPath: _selectedPdf!.path,
      signatureImageBytes: signatureBytes,
      targetPageNumber: _targetPage,
      placementRect: const Rect.fromLTWH(350, 680, 180, 90), // Bottom Right placement
      outputFileName: fileName.isEmpty ? 'Signed_Doc' : fileName,
    );

    setState(() => _isProcessing = false);

    if (outputFile != null && mounted) {
      final stat = await outputFile.stat();
      final docFile = DocumentFile(
        path: outputFile.path,
        title: outputFile.path.split(Platform.pathSeparator).last,
        sizeInBytes: stat.size,
        modifiedTime: stat.modified,
        pageCount: _totalPages,
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
        title: const Text('eSign Document', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Output Name
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.draw_rounded, color: AppColors.primary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(hintText: 'Signed File Name', border: InputBorder.none),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                    const Text('.pdf', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Pick PDF Card
              if (_selectedPdf == null)
                InkWell(
                  onTap: _pickSourcePdf,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: AppColors.primarySoftTint, shape: BoxShape.circle),
                          child: const Icon(Icons.draw_rounded, size: 36, color: AppColors.primary),
                        ),
                        const SizedBox(height: 12),
                        const Text('Tap to Choose PDF Document', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 4),
                        const Text('Select contract, agreement, or form to sign', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                )
              else
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
                        decoration: BoxDecoration(color: AppColors.primarySoftTint, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_selectedPdf!.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text('$_totalPages pages • ${_selectedPdf!.formattedSize}', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      TextButton(onPressed: _pickSourcePdf, child: const Text('Change', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Page selector if multi-page
              if (_totalPages > 1) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Sign on Page', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    DropdownButton<int>(
                      value: _targetPage,
                      onChanged: (val) => setState(() => _targetPage = val ?? 1),
                      items: List.generate(_totalPages, (i) => i + 1).map((p) {
                        return DropdownMenuItem(value: p, child: Text('Page $p of $_totalPages'));
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Signature Pad Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Draw Signature Here', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  TextButton.icon(
                    onPressed: () => setState(() => _points.clear()),
                    icon: const Icon(Icons.clear_rounded, size: 16, color: AppColors.error),
                    label: const Text('Clear', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Drawing Canvas Container
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      final box = context.findRenderObject() as RenderBox?;
                      if (box != null) {
                        final point = details.localPosition;
                        setState(() => _points.add(point));
                      }
                    },
                    onPanEnd: (_) => setState(() => _points.add(null)),
                    child: CustomPaint(
                      painter: _SignaturePainter(points: _points),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // CTA Apply Signature Button
              SizedBox(
                width: double.infinity,
                height: AppDimensions.buttonHeightCta,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _signAndSave,
                  icon: const Icon(Icons.check_rounded, size: 20),
                  label: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                      : const Text('Stamp Signature & Save PDF', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
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
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  _SignaturePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw baseline guideline
    final guidePaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(20, size.height - 30), Offset(size.width - 20, size.height - 30), guidePaint);

    final paint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
