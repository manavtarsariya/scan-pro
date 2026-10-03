import 'dart:io';
import 'package:intl/intl.dart';

/// Data model representing a document file or folder in local storage.
class DocumentFile {
  final String path;
  final String title;
  final int sizeInBytes;
  final DateTime modifiedTime;
  final int pageCount;
  final String categoryTag;
  final bool isFavorite;
  final bool isFolder;

  const DocumentFile({
    required this.path,
    required this.title,
    required this.sizeInBytes,
    required this.modifiedTime,
    this.pageCount = 1,
    this.categoryTag = 'General',
    this.isFavorite = false,
    this.isFolder = false,
  });

  /// Formatted human-readable file size (e.g. 1.4 MB, 890 KB).
  String get formattedSize {
    if (isFolder) return 'Folder';
    if (sizeInBytes < 1024) return '$sizeInBytes B';
    if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Formatted friendly date (e.g. "Today, 2:45 PM", "Yesterday", "Oct 1, 2025").
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(modifiedTime);

    if (difference.inDays == 0 && modifiedTime.day == now.day) {
      final timeStr = DateFormat('h:mm a').format(modifiedTime);
      return 'Today, $timeStr';
    } else if (difference.inDays <= 1 || (difference.inDays == 2 && modifiedTime.day == now.day - 1)) {
      final timeStr = DateFormat('h:mm a').format(modifiedTime);
      return 'Yesterday, $timeStr';
    } else if (difference.inDays < 7) {
      return DateFormat('EEE, h:mm a').format(modifiedTime);
    } else {
      return DateFormat('dd MMM yyyy').format(modifiedTime);
    }
  }

  /// Creates a copy with modified properties.
  DocumentFile copyWith({
    String? path,
    String? title,
    int? sizeInBytes,
    DateTime? modifiedTime,
    int? pageCount,
    String? categoryTag,
    bool? isFavorite,
    bool? isFolder,
  }) {
    return DocumentFile(
      path: path ?? this.path,
      title: title ?? this.title,
      sizeInBytes: sizeInBytes ?? this.sizeInBytes,
      modifiedTime: modifiedTime ?? this.modifiedTime,
      pageCount: pageCount ?? this.pageCount,
      categoryTag: categoryTag ?? this.categoryTag,
      isFavorite: isFavorite ?? this.isFavorite,
      isFolder: isFolder ?? this.isFolder,
    );
  }

  /// Factory helper from FileSystemEntity.
  static Future<DocumentFile> fromEntity(FileSystemEntity entity, {bool isFavorite = false}) async {
    final stat = await entity.stat();
    final isDir = entity is Directory;
    final name = entity.path.split(Platform.pathSeparator).last;

    // Detect category tag by name pattern
    String tag = 'General';
    final lowerName = name.toLowerCase();
    if (lowerName.contains('invoice') || lowerName.contains('bill') || lowerName.contains('tax')) {
      tag = 'Invoices';
    } else if (lowerName.contains('receipt') || lowerName.contains('payment')) {
      tag = 'Receipts';
    } else if (lowerName.contains('id') || lowerName.contains('card') || lowerName.contains('aadhaar') || lowerName.contains('pan')) {
      tag = 'ID Cards';
    } else if (lowerName.contains('note') || lowerName.contains('study')) {
      tag = 'Notes';
    } else if (lowerName.contains('contract') || lowerName.contains('agree') || lowerName.contains('legal')) {
      tag = 'Contracts';
    }

    return DocumentFile(
      path: entity.path,
      title: name,
      sizeInBytes: isDir ? 0 : stat.size,
      modifiedTime: stat.modified,
      categoryTag: tag,
      isFavorite: isFavorite,
      isFolder: isDir,
      pageCount: 1, // Can be augmented when scanning
    );
  }
}
