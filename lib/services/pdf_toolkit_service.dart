import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' as pw_pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:intl/intl.dart';
import 'package:pdfx/pdfx.dart' as pdfx;

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

  /// Locks a PDF document with AES-256 user password protection.
  static Future<File?> lockPdf({
    required String sourcePdfPath,
    required String userPassword,
    required String outputFileName,
  }) async {
    try {
      final sourceFile = File(sourcePdfPath);
      if (!await sourceFile.exists()) return null;

      final sourceBytes = await sourceFile.readAsBytes();
      final document = PdfDocument(inputBytes: sourceBytes);

      final security = document.security;
      security.userPassword = userPassword;
      security.ownerPassword = userPassword;

      final appDir = await getApplicationDocumentsDirectory();
      final formattedName = outputFileName.endsWith('.pdf') ? outputFileName : '$outputFileName.pdf';
      final outputFile = File('${appDir.path}/$formattedName');

      final savedBytes = await document.save();
      await outputFile.writeAsBytes(savedBytes);
      document.dispose();

      return outputFile;
    } catch (e) {
      debugPrint('Error locking PDF: $e');
      return null;
    }
  }

  /// Unlocks a password-protected PDF document.
  static Future<File?> unlockPdf({
    required String sourcePdfPath,
    required String currentPassword,
    required String outputFileName,
  }) async {
    try {
      final sourceFile = File(sourcePdfPath);
      if (!await sourceFile.exists()) return null;

      final sourceBytes = await sourceFile.readAsBytes();
      final document = PdfDocument(inputBytes: sourceBytes, password: currentPassword);

      document.security.userPassword = '';
      document.security.ownerPassword = '';

      final appDir = await getApplicationDocumentsDirectory();
      final formattedName = outputFileName.endsWith('.pdf') ? outputFileName : '$outputFileName.pdf';
      final outputFile = File('${appDir.path}/$formattedName');

      final savedBytes = await document.save();
      await outputFile.writeAsBytes(savedBytes);
      document.dispose();

      return outputFile;
    } catch (e) {
      debugPrint('Error unlocking PDF: $e');
      return null;
    }
  }

  /// Adds a custom watermark and bottom page numbers to a PDF.
  static Future<File?> addWatermarkAndPageNumbers({
    required String sourcePdfPath,
    String? watermarkText,
    bool addPageNumbers = true,
    required String outputFileName,
  }) async {
    try {
      final sourceFile = File(sourcePdfPath);
      if (!await sourceFile.exists()) return null;

      final sourceBytes = await sourceFile.readAsBytes();
      final document = PdfDocument(inputBytes: sourceBytes);
      final font = PdfStandardFont(PdfFontFamily.helvetica, 28, style: PdfFontStyle.bold);
      final smallFont = PdfStandardFont(PdfFontFamily.helvetica, 10);
      final brush = PdfSolidBrush(PdfColor(150, 150, 150, 70));
      final pageNumberBrush = PdfSolidBrush(PdfColor(100, 100, 100));

      final totalPages = document.pages.count;

      for (int i = 0; i < totalPages; i++) {
        final page = document.pages[i];
        final pageSize = page.size;

        if (watermarkText != null && watermarkText.trim().isNotEmpty) {
          final textSize = font.measureString(watermarkText);
          final g = page.graphics;
          final state = g.save();
          g.translateTransform(pageSize.width / 2, pageSize.height / 2);
          g.rotateTransform(-45);
          g.drawString(
            watermarkText,
            font,
            brush: brush,
            bounds: Rect.fromLTWH(-textSize.width / 2, -textSize.height / 2, textSize.width, textSize.height),
          );
          g.restore(state);
        }

        if (addPageNumbers) {
          final pageStr = 'Page ${i + 1} of $totalPages';
          final numSize = smallFont.measureString(pageStr);
          page.graphics.drawString(
            pageStr,
            smallFont,
            brush: pageNumberBrush,
            bounds: Rect.fromLTWH((pageSize.width - numSize.width) / 2, pageSize.height - 24, numSize.width, numSize.height),
          );
        }
      }

      final appDir = await getApplicationDocumentsDirectory();
      final formattedName = outputFileName.endsWith('.pdf') ? outputFileName : '$outputFileName.pdf';
      final outputFile = File('${appDir.path}/$formattedName');

      final savedBytes = await document.save();
      await outputFile.writeAsBytes(savedBytes);
      document.dispose();

      return outputFile;
    } catch (e) {
      debugPrint('Error applying watermark: $e');
      return null;
    }
  }

  /// Places a signature bitmap onto a designated page of a PDF.
  static Future<File?> addSignatureToPdf({
    required String sourcePdfPath,
    required Uint8List signatureImageBytes,
    required int targetPageNumber,
    required Rect placementRect,
    required String outputFileName,
  }) async {
    try {
      final sourceFile = File(sourcePdfPath);
      if (!await sourceFile.exists()) return null;

      final sourceBytes = await sourceFile.readAsBytes();
      final document = PdfDocument(inputBytes: sourceBytes);

      final zeroIndex = targetPageNumber - 1;
      if (zeroIndex >= 0 && zeroIndex < document.pages.count) {
        final page = document.pages[zeroIndex];
        final image = PdfBitmap(signatureImageBytes);
        page.graphics.drawImage(
          image,
          placementRect,
        );
      }

      final appDir = await getApplicationDocumentsDirectory();
      final formattedName = outputFileName.endsWith('.pdf') ? outputFileName : '$outputFileName.pdf';
      final outputFile = File('${appDir.path}/$formattedName');

      final savedBytes = await document.save();
      await outputFile.writeAsBytes(savedBytes);
      document.dispose();

      return outputFile;
    } catch (e) {
      debugPrint('Error applying signature: $e');
      return null;
    }
  }

  /// Reorganizes page sequence and rotates individual pages of a PDF with pixel-perfect alignment.
  static Future<File?> organizePages({
    required String sourcePdfPath,
    required List<int> newPageOrder,
    required Map<int, int> pageRotations,
    required String outputFileName,
    List<OrganizePageModel>? detailedPages,
  }) async {
    try {
      final sourceFile = File(sourcePdfPath);
      PdfDocument? loadedDoc;
      if (await sourceFile.exists()) {
        final sourceBytes = await sourceFile.readAsBytes();
        loadedDoc = PdfDocument(inputBytes: sourceBytes);
      }

      final outputDoc = PdfDocument();
      outputDoc.pageSettings.margins.all = 0;

      if (detailedPages != null && detailedPages.isNotEmpty) {
        for (final item in detailedPages) {
          final rot = (item.rotation % 360 + 360) % 360;

          if (item.isInsertedImage && item.imagePath != null) {
            final imgFile = File(item.imagePath!);
            if (await imgFile.exists()) {
              final imgBytes = await imgFile.readAsBytes();
              final bitmap = PdfBitmap(imgBytes);

              final newPage = outputDoc.pages.add();
              final pW = newPage.size.width;
              final pH = newPage.size.height;

              final imgW = bitmap.width.toDouble();
              final imgH = bitmap.height.toDouble();

              final isQuarterTurn = (rot == 90 || rot == 270);
              final boundingW = isQuarterTurn ? imgH : imgW;
              final boundingH = isQuarterTurn ? imgW : imgH;

              // Proportional scale ensuring photo is NEVER cut off and fits available bounds
              final scale = math.min(pW / boundingW, pH / boundingH);
              final drawW = imgW * scale;
              final drawH = imgH * scale;

              final g = newPage.graphics;
              final state = g.save();
              // 1. Move pivot to exact center of page
              g.translateTransform(pW / 2, pH / 2);
              // 2. Rotate around center
              if (rot != 0) {
                g.rotateTransform(rot.toDouble());
              }
              // 3. Center image at pivot
              g.translateTransform(-drawW / 2, -drawH / 2);
              // 4. Draw image with preserved aspect ratio
              g.drawImage(bitmap, Rect.fromLTWH(0, 0, drawW, drawH));
              g.restore(state);
            }
          } else if (item.isBlankPage) {
            outputDoc.pages.add();
          } else if (loadedDoc != null) {
            final zeroIndex = item.originalPageIndex - 1;
            if (zeroIndex >= 0 && zeroIndex < loadedDoc.pages.count) {
              final srcPage = loadedDoc.pages[zeroIndex];
              final srcSize = srcPage.size;
              final template = srcPage.createTemplate();

              final newPage = outputDoc.pages.add();
              final pW = newPage.size.width;
              final pH = newPage.size.height;

              final isQuarterTurn = (rot == 90 || rot == 270);
              final boundingW = isQuarterTurn ? srcSize.height : srcSize.width;
              final boundingH = isQuarterTurn ? srcSize.width : srcSize.height;

              // Proportional scale ensuring template is NEVER cut off and fits available bounds
              final scale = math.min(pW / boundingW, pH / boundingH);
              final drawW = srcSize.width * scale;
              final drawH = srcSize.height * scale;

              final g = newPage.graphics;
              final state = g.save();
              // 1. Move pivot to exact center of page
              g.translateTransform(pW / 2, pH / 2);
              // 2. Rotate around center
              if (rot != 0) {
                g.rotateTransform(rot.toDouble());
              }
              // 3. Center template at pivot
              g.translateTransform(-drawW / 2, -drawH / 2);
              // 4. Draw template with preserved aspect ratio
              g.drawPdfTemplate(template, Offset.zero, Size(drawW, drawH));
              g.restore(state);
            }
          }
        }
      } else if (loadedDoc != null) {
        for (final pageNum in newPageOrder) {
          final zeroIndex = pageNum - 1;
          if (zeroIndex >= 0 && zeroIndex < loadedDoc.pages.count) {
            final srcPage = loadedDoc.pages[zeroIndex];
            final srcSize = srcPage.size;
            final template = srcPage.createTemplate();
            final rot = ((pageRotations[pageNum] ?? 0) % 360 + 360) % 360;

            final newPage = outputDoc.pages.add();
            final pW = newPage.size.width;
            final pH = newPage.size.height;

            final isQuarterTurn = (rot == 90 || rot == 270);
            final boundingW = isQuarterTurn ? srcSize.height : srcSize.width;
            final boundingH = isQuarterTurn ? srcSize.width : srcSize.height;

            final scale = math.min(pW / boundingW, pH / boundingH);
            final drawW = srcSize.width * scale;
            final drawH = srcSize.height * scale;

            final g = newPage.graphics;
            final state = g.save();
            g.translateTransform(pW / 2, pH / 2);
            if (rot != 0) {
              g.rotateTransform(rot.toDouble());
            }
            g.translateTransform(-drawW / 2, -drawH / 2);
            g.drawPdfTemplate(template, Offset.zero, Size(drawW, drawH));
            g.restore(state);
          }
        }
      }

      final appDir = await getApplicationDocumentsDirectory();
      final formattedName = outputFileName.endsWith('.pdf') ? outputFileName : '$outputFileName.pdf';
      final outputFile = File('${appDir.path}/$formattedName');

      final savedBytes = await outputDoc.save();
      await outputFile.writeAsBytes(savedBytes);

      loadedDoc?.dispose();
      outputDoc.dispose();

      return outputFile;
    } catch (e) {
      debugPrint('Error organizing pages: $e');
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

  /// Renders a real image thumbnail of a specific 1-indexed PDF page.
  static Future<Uint8List?> renderPdfPageThumbnail(String pdfPath, int pageNumber) async {
    try {
      final doc = await pdfx.PdfDocument.openFile(pdfPath);
      final page = await doc.getPage(pageNumber);
      final pageImage = await page.render(
        width: page.width / 1.5,
        height: page.height / 1.5,
        format: pdfx.PdfPageImageFormat.jpeg,
      );
      await page.close();
      await doc.close();
      return pageImage?.bytes;
    } catch (e) {
      debugPrint('Error rendering PDF thumbnail: $e');
      return null;
    }
  }
}

/// Model representing a single page in the Organize Pages tool.
class OrganizePageModel {
  final String id;
  final int originalPageIndex; // 1-based original index
  final String? imagePath; // Path if it's an inserted camera/gallery image
  final bool isBlankPage;
  final bool isInsertedImage;
  Uint8List? thumbnailBytes;
  String title;
  int rotation; // 0, 90, 180, 270
  bool isSelected;

  OrganizePageModel({
    required this.id,
    required this.originalPageIndex,
    this.imagePath,
    this.isBlankPage = false,
    this.isInsertedImage = false,
    this.thumbnailBytes,
    required this.title,
    this.rotation = 0,
    this.isSelected = false,
  });

  OrganizePageModel copyWith({
    String? id,
    int? originalPageIndex,
    String? imagePath,
    bool? isBlankPage,
    bool? isInsertedImage,
    Uint8List? thumbnailBytes,
    String? title,
    int? rotation,
    bool? isSelected,
  }) {
    return OrganizePageModel(
      id: id ?? this.id,
      originalPageIndex: originalPageIndex ?? this.originalPageIndex,
      imagePath: imagePath ?? this.imagePath,
      isBlankPage: isBlankPage ?? this.isBlankPage,
      isInsertedImage: isInsertedImage ?? this.isInsertedImage,
      thumbnailBytes: thumbnailBytes ?? this.thumbnailBytes,
      title: title ?? this.title,
      rotation: rotation ?? this.rotation,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

