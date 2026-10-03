import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/document_file.dart';
import '../../services/file_manager_service.dart';

/// Screen for previewing document metadata and performing quick actions.
class PdfViewerScreen extends StatefulWidget {
  final DocumentFile document;
  final VoidCallback? onFileChanged;

  const PdfViewerScreen({
    super.key,
    required this.document,
    this.onFileChanged,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late DocumentFile _currentDoc;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _currentDoc = widget.document;
    _isFavorite = _currentDoc.isFavorite;
  }

  Future<void> _toggleFav() async {
    final newFav = await FileManagerService.toggleFavorite(_currentDoc.path);
    setState(() {
      _isFavorite = newFav;
      _currentDoc = _currentDoc.copyWith(isFavorite: newFav);
    });
    widget.onFileChanged?.call();
  }

  Future<void> _openFile() async {
    await FileManagerService.openWithSystemViewer(_currentDoc.path);
  }

  Future<void> _shareFile() async {
    await FileManagerService.shareFile(_currentDoc.path, subject: _currentDoc.title);
  }

  Future<void> _renameFile() async {
    final controller = TextEditingController(
      text: _currentDoc.title.replaceAll('.pdf', ''),
    );

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Rename Document', style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter new document name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      final renamed = await FileManagerService.renameFile(_currentDoc.path, result);
      if (renamed != null) {
        setState(() {
          _currentDoc = _currentDoc.copyWith(
            path: renamed.path,
            title: renamed.path.split('/').last.split('\\').last,
          );
        });
        widget.onFileChanged?.call();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document renamed successfully')),
          );
        }
      }
    }
  }

  Future<void> _deleteFile() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Document?'),
        content: Text('Are you sure you want to delete "${_currentDoc.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await FileManagerService.deleteItem(_currentDoc.path);
      widget.onFileChanged?.call();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _currentDoc.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
              color: _isFavorite ? AppColors.premiumStart : AppColors.textSecondary,
            ),
            onPressed: _toggleFav,
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: _shareFile,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            onPressed: _deleteFile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Big Document Preview Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoftTint,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _currentDoc.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_currentDoc.formattedSize} • ${_currentDoc.formattedDate}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Primary Open Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _openFile,
                      icon: const Icon(Icons.open_in_new_rounded, size: 20),
                      label: const Text(
                        'Open Document',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Metadata & Actions Grid
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoftTint,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 20),
                    ),
                    title: const Text('Rename File', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Change document title', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                    onTap: _renameFile,
                  ),
                  const Divider(height: 1, indent: 64),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.share_rounded, color: AppColors.aiAccent, size: 20),
                    ),
                    title: const Text('Share File', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Send via WhatsApp, Email, Drive', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                    onTap: _shareFile,
                  ),
                  const Divider(height: 1, indent: 64),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                    ),
                    title: const Text('Delete Permanently', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.error)),
                    subtitle: const Text('Remove from device storage', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                    onTap: _deleteFile,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // File Details Tile
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Document Info',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('File Size', _currentDoc.formattedSize),
                  const SizedBox(height: 8),
                  _buildInfoRow('Modified', _currentDoc.formattedDate),
                  const SizedBox(height: 8),
                  _buildInfoRow('Category', _currentDoc.categoryTag),
                  const SizedBox(height: 8),
                  _buildInfoRow('Storage Path', _currentDoc.path, isSmall: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isSmall = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: isSmall ? 10.5 : 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
