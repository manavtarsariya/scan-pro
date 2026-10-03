import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

/// Result data holder for a scan operation.
class ScanResult {
  final List<String> imagePaths;
  final String? pdfPath;
  final bool isSuccess;
  final String? errorMessage;

  ScanResult({
    required this.imagePaths,
    this.pdfPath,
    this.isSuccess = true,
    this.errorMessage,
  });
}

/// Core Scanning & PDF generation service.
/// Uses Google ML Kit Document Scanner for native on-device edge detection, crop & scan.
class ScannerService {
  /// Launches native Google ML Kit Document Scanner.
  static Future<ScanResult> startDocumentScan({int pageLimit = 50}) async {
    try {
      final options = DocumentScannerOptions(
        documentFormats: {
          DocumentFormat.pdf,
          DocumentFormat.jpeg,
        },
        mode: ScannerMode.full, // Includes edge detection, auto-crop & filters
        pageLimit: pageLimit,
        isGalleryImport: true,
      );

      final documentScanner = DocumentScanner(options: options);
      final documents = await documentScanner.scanDocument();

      if (documents.pdf != null || (documents.images != null && documents.images!.isNotEmpty)) {
        return ScanResult(
          imagePaths: documents.images ?? [],
          pdfPath: documents.pdf?.uri,
          isSuccess: true,
        );
      } else {
        return ScanResult(imagePaths: [], isSuccess: false, errorMessage: 'Scan cancelled');
      }
    } catch (e) {
      debugPrint('Scanner error: $e');
      return ScanResult(imagePaths: [], isSuccess: false, errorMessage: e.toString());
    }
  }

  /// Imports multiple images from gallery and returns their paths.
  static Future<List<String>> pickImagesFromGallery() async {
    try {
      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage();
      return pickedFiles.map((file) => file.path).toList();
    } catch (e) {
      debugPrint('Gallery pick error: $e');
      return [];
    }
  }

  /// Converts a list of image paths into a clean single PDF file.
  static Future<File> createPdfFromImages({
    required List<String> imagePaths,
    required String fileName,
  }) async {
    final pdf = pw.Document();

    for (final path in imagePaths) {
      final imageBytes = await File(path).readAsBytes();
      final image = pw.MemoryImage(imageBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (pw.Context context) {
            return pw.FullPage(
              ignoreMargins: true,
              child: pw.Image(image, fit: pw.BoxFit.contain),
            );
          },
        ),
      );
    }

    final outputDir = await getApplicationDocumentsDirectory();
    final formattedName = fileName.endsWith('.pdf') ? fileName : '$fileName.pdf';
    final outputFile = File('${outputDir.path}/$formattedName');

    await outputFile.writeAsBytes(await pdf.save());
    return outputFile;
  }

  /// Creates a single-page A4 PDF containing both Front and Back sides of an ID Card.
  static Future<File> createIdCardPdf({
    required String frontImagePath,
    required String backImagePath,
    required String fileName,
  }) async {
    final pdf = pw.Document();

    final frontBytes = await File(frontImagePath).readAsBytes();
    final backBytes = await File(backImagePath).readAsBytes();

    final frontImage = pw.MemoryImage(frontBytes);
    final backImage = pw.MemoryImage(backBytes);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Front Side Label & Card
              pw.Container(
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'FRONT SIDE',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Container(
                height: 230,
                width: 360,
                decoration: pw.BoxDecoration(
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                  border: pw.Border.all(color: PdfColors.grey400, width: 1),
                ),
                child: pw.ClipRRect(
                  horizontalRadius: 10,
                  verticalRadius: 10,
                  child: pw.Center(
                    child: pw.Image(frontImage, fit: pw.BoxFit.contain),
                  ),
                ),
              ),

              pw.SizedBox(height: 40),

              // Back Side Label & Card
              pw.Container(
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'BACK SIDE',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Container(
                height: 230,
                width: 360,
                decoration: pw.BoxDecoration(
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                  border: pw.Border.all(color: PdfColors.grey400, width: 1),
                ),
                child: pw.ClipRRect(
                  horizontalRadius: 10,
                  verticalRadius: 10,
                  child: pw.Center(
                    child: pw.Image(backImage, fit: pw.BoxFit.contain),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    final outputDir = await getApplicationDocumentsDirectory();
    final formattedName = fileName.endsWith('.pdf') ? fileName : '$fileName.pdf';
    final outputFile = File('${outputDir.path}/$formattedName');

    await outputFile.writeAsBytes(await pdf.save());
    return outputFile;
  }

  /// Generates a default timestamped file name (e.g. Scan_20251003_1822.pdf).
  static String generateDefaultFileName() {
    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMdd_HHmm');
    return 'Scan_${formatter.format(now)}.pdf';
  }
}
