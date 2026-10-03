import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' as pw_pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:intl/intl.dart';

/// Offline Service for PDF Toolkit operations: Merge, Split, Compress, and Image-to-PDF.
class PdfToolkitService {
  /// Generates a timestamped default output name for PDF tools.
  static String generateToolOutputName(String prefix) {
    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMdd_HHmmss');
    return '${prefix}_${formatter.format(now)}.pdf';
  }

  /// Merges multiple PDF files into a single output PDF document.
  static Future<File?> mergePdfs({
    required List<String> inputPdfPaths,
    required String outputFileName,
  }) async {
    try {
      if (inputPdfPaths.isEmpty) return null;

      final outputDocument = PdfDocument();

      for (final path in inputPdfPaths) {
        final file = File(path);
        if (!await file.exists()) continue;

        final bytes = await file.readAsBytes();
        final loadedDoc = PdfDocument(inputBytes: bytes);

        // Import all pages into the output document
        for (int i = 0; i < loadedDoc.pages.count; i++) {
          final template = loadedDoc.pages[i].createTemplate();
          final newPage = outputDocument.pages.add();
          newPage.graphics.drawPdfTemplate(
            template,
            Offset.zero,
            Size(newPage.size.width, newPage.size.height),
          );
        }
        loadedDoc.dispose();
      }

      final appDir = await getApplicationDocumentsDirectory();
      final formattedName = outputFileName.endsWith('.pdf') ? outputFileName : '$outputFileName.pdf';
      final outputFile = File('${appDir.path}/$formattedName');

      final savedBytes = await outputDocument.save();
      await outputFile.writeAsBytes(savedBytes);
      outputDocument.dispose();

      return outputFile;
    } catch (e) {
      debugPrint('Error merging PDFs: $e');
      return null;
    }
  }

  /// Splits a PDF and extracts specified 1-based page numbers into a new PDF.
  static Future<File?> splitPdf({
    required String sourcePdfPath,
    required List<int> selectedPages, // 1-indexed page numbers
    required String outputFileName,
  }) async {
    try {
      final sourceFile = File(sourcePdfPath);
      if (!await sourceFile.exists()) return null;

      final sourceBytes = await sourceFile.readAsBytes();
      final loadedDoc = PdfDocument(inputBytes: sourceBytes);
      final outputDocument = PdfDocument();

      for (final pageNum in selectedPages) {
        final zeroIndex = pageNum - 1;
        if (zeroIndex >= 0 && zeroIndex < loadedDoc.pages.count) {
          final template = loadedDoc.pages[zeroIndex].createTemplate();
          final newPage = outputDocument.pages.add();
          newPage.graphics.drawPdfTemplate(
            template,
            Offset.zero,
            Size(newPage.size.width, newPage.size.height),
          );
        }
      }

      final appDir = await getApplicationDocumentsDirectory();
      final formattedName = outputFileName.endsWith('.pdf') ? outputFileName : '$outputFileName.pdf';
      final outputFile = File('${appDir.path}/$formattedName');

      final savedBytes = await outputDocument.save();
      await outputFile.writeAsBytes(savedBytes);

      loadedDoc.dispose();
      outputDocument.dispose();

      return outputFile;
    } catch (e) {
      debugPrint('Error splitting PDF: $e');
      return null;
    }
  }

  /// Compresses a PDF document by applying compression options.
  static Future<File?> compressPdf({
    required String sourcePdfPath,
    required int compressionLevel, // 1 = Low (high quality), 2 = Medium, 3 = High (small size)
    required String outputFileName,
  }) async {
    try {
      final sourceFile = File(sourcePdfPath);
      if (!await sourceFile.exists()) return null;

      final sourceBytes = await sourceFile.readAsBytes();
      final loadedDoc = PdfDocument(inputBytes: sourceBytes);

      // Set compression options
      loadedDoc.compressionLevel = PdfCompressionLevel.best;

      final appDir = await getApplicationDocumentsDirectory();
      final formattedName = outputFileName.endsWith('.pdf') ? outputFileName : '$outputFileName.pdf';
      final outputFile = File('${appDir.path}/$formattedName');

      final savedBytes = await loadedDoc.save();
      await outputFile.writeAsBytes(savedBytes);
      loadedDoc.dispose();

      return outputFile;
    } catch (e) {
      debugPrint('Error compressing PDF: $e');
      return null;
    }
  }

  /// Converts a collection of images into a high quality PDF.
  static Future<File?> convertImagesToPdf({
    required List<String> imagePaths,
    required String outputFileName,
    pw_pdf.PdfPageFormat pageFormat = pw_pdf.PdfPageFormat.a4,
  }) async {
    try {
      if (imagePaths.isEmpty) return null;

      final pdf = pw.Document();

      for (final path in imagePaths) {
        final imageFile = File(path);
        if (!await imageFile.exists()) continue;

        final imageBytes = await imageFile.readAsBytes();
        final image = pw.MemoryImage(imageBytes);

        pdf.addPage(
          pw.Page(
            pageFormat: pageFormat,
            margin: pw.EdgeInsets.zero,
            build: (pw.Context context) {
              return pw.FullPage(
                ignoreMargins: true,
                child: pw.Center(
                  child: pw.Image(image, fit: pw.BoxFit.contain),
                ),
              );
            },
          ),
        );
      }

      final appDir = await getApplicationDocumentsDirectory();
      final formattedName = outputFileName.endsWith('.pdf') ? outputFileName : '$outputFileName.pdf';
      final outputFile = File('${appDir.path}/$formattedName');

      await outputFile.writeAsBytes(await pdf.save());
      return outputFile;
    } catch (e) {
      debugPrint('Error converting images to PDF: $e');
      return null;
    }
  }

  /// Gets the total page count of a PDF file.
  static Future<int> getPdfPageCount(String pdfPath) async {
    try {
      final file = File(pdfPath);
      if (!await file.exists()) return 0;

      final bytes = await file.readAsBytes();
      final doc = PdfDocument(inputBytes: bytes);
      final count = doc.pages.count;
      doc.dispose();
      return count;
    } catch (e) {
      debugPrint('Error reading page count: $e');
      return 1;
    }
  }
}
