import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/document_file.dart';

/// Service managing on-device files, folders, favorites, sharing and renaming.
class FileManagerService {
  static const String _favoritesPrefKey = 'favorite_documents_list';

  /// Retrieves list of favorite file paths from SharedPreferences.
  static Future<Set<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_favoritesPrefKey) ?? [];
    return list.toSet();
  }

  /// Toggles favorite status for a given file path.
  static Future<bool> toggleFavorite(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final favs = (prefs.getStringList(_favoritesPrefKey) ?? []).toSet();

    final isNowFav = !favs.contains(path);
    if (isNowFav) {
      favs.add(path);
    } else {
      favs.remove(path);
    }

    await prefs.setStringList(_favoritesPrefKey, favs.toList());
    return isNowFav;
  }

  /// Fetches all scanned PDF files and folders from the app's documents directory.
  static Future<List<DocumentFile>> loadAllFiles({String? subFolder}) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final targetDir = subFolder != null ? Directory('${appDir.path}/$subFolder') : appDir;

      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
        return [];
      }

      final favorites = await getFavorites();
      final entities = targetDir.listSync();
      final List<DocumentFile> files = [];

      for (final entity in entities) {
        final name = entity.path.split(Platform.pathSeparator).last;
        // Filter out system and hidden files
        if (name.startsWith('.') || name.startsWith('flutter_assets')) continue;

        final isDir = entity is Directory;
        final isPdf = name.toLowerCase().endsWith('.pdf');
        final isImage = name.toLowerCase().endsWith('.jpg') ||
            name.toLowerCase().endsWith('.jpeg') ||
            name.toLowerCase().endsWith('.png');

        if (isDir || isPdf || isImage) {
          final isFav = favorites.contains(entity.path);
          final doc = await DocumentFile.fromEntity(entity, isFavorite: isFav);
          files.add(doc);
        }
      }

      // Sort by modified time (most recent first)
      files.sort((a, b) => b.modifiedTime.compareTo(a.modifiedTime));
      return files;
    } catch (e) {
      debugPrint('Error loading files: $e');
      return [];
    }
  }

  /// Creates a new subfolder in app documents directory.
  static Future<Directory?> createFolder(String folderName) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final sanitized = folderName.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final newDir = Directory('${appDir.path}/$sanitized');
      if (!await newDir.exists()) {
        await newDir.create(recursive: true);
      }
      return newDir;
    } catch (e) {
      debugPrint('Error creating folder: $e');
      return null;
    }
  }

  /// Renames a file or folder.
  static Future<File?> renameFile(String oldPath, String newName) async {
    try {
      final file = File(oldPath);
      if (!await file.exists()) return null;

      final dir = file.parent.path;
      final extension = oldPath.contains('.') ? '.${oldPath.split('.').last}' : '';
      final formattedName = newName.endsWith(extension) ? newName : '$newName$extension';
      final newPath = '$dir/$formattedName';

      return await file.rename(newPath);
    } catch (e) {
      debugPrint('Error renaming file: $e');
      return null;
    }
  }

  /// Deletes a file or directory permanently.
  static Future<bool> deleteItem(String path) async {
    try {
      final type = await FileSystemEntity.type(path);
      if (type == FileSystemEntityType.file) {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } else if (type == FileSystemEntityType.directory) {
        final dir = Directory(path);
        if (await dir.exists()) await dir.delete(recursive: true);
      }
      return true;
    } catch (e) {
      debugPrint('Error deleting item: $e');
      return false;
    }
  }

  /// Deletes multiple files or folders.
  static Future<void> deleteMultiple(List<String> paths) async {
    for (final path in paths) {
      await deleteItem(path);
    }
  }

  /// Shares a single file via native system share sheet.
  static Future<void> shareFile(String path, {String? subject}) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path)],
          subject: subject ?? 'Scanned Document from ScanPro',
        ),
      );
    } catch (e) {
      debugPrint('Error sharing file: $e');
    }
  }

  /// Shares multiple files via native system share sheet.
  static Future<void> shareMultiple(List<String> paths) async {
    try {
      final xFiles = paths.map((p) => XFile(p)).toList();
      await SharePlus.instance.share(
        ShareParams(
          files: xFiles,
          subject: 'Documents from ScanPro',
        ),
      );
    } catch (e) {
      debugPrint('Error sharing multiple files: $e');
    }
  }

  /// Opens a file with the system default viewer.
  static Future<OpenResult> openWithSystemViewer(String path) async {
    return await OpenFilex.open(path);
  }
}
