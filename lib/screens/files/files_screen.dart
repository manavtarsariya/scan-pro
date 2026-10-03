import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/document_file.dart';
import '../../services/file_manager_service.dart';
import '../../services/scanner_service.dart';
import '../scan/scan_preview_screen.dart';
import 'pdf_viewer_screen.dart';

/// Screen for browsing, searching, organizing, and managing local PDF files and folders.
class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  List<DocumentFile> _allFiles = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  bool _isGridView = false;
  String _sortBy = 'Date'; // 'Date', 'Name', 'Size'

  // Multi-selection state
  bool _isSelectionMode = false;
  final Set<String> _selectedFilePaths = {};

  final List<String> _categories = const [
    'All',
    'Invoices',
    'Receipts',
    'ID Cards',
    'Notes',
    'Contracts',
    'Favorites',
  ];

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFiles() async {
    setState(() => _isLoading = true);
    final files = await FileManagerService.loadAllFiles();
    if (mounted) {
      setState(() {
        _allFiles = files;
        _isLoading = false;
      });
    }
  }

  List<DocumentFile> get _filteredFiles {
    var list = _allFiles.where((doc) {
      // 1. Search Query Filter
      final query = _searchController.text.trim().toLowerCase();
      if (query.isNotEmpty && !doc.title.toLowerCase().contains(query)) {
        return false;
      }

      // 2. Category Filter
      if (_selectedCategory == 'Favorites') {
        return doc.isFavorite;
      } else if (_selectedCategory != 'All') {
        return doc.categoryTag == _selectedCategory;
      }
      return true;
    }).toList();

    // 3. Sorting
    if (_sortBy == 'Name') {
      list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    } else if (_sortBy == 'Size') {
      list.sort((a, b) => b.sizeInBytes.compareTo(a.sizeInBytes));
    } else {
      list.sort((a, b) => b.modifiedTime.compareTo(a.modifiedTime));
    }

    return list;
  }

  List<DocumentFile> get _folders => _allFiles.where((doc) => doc.isFolder).toList();
  List<DocumentFile> get _documents => _filteredFiles.where((doc) => !doc.isFolder).toList();

  Future<void> _createNewFolder() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.create_new_folder_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('New Folder', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g. Tax_2025, Work_Docs',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await FileManagerService.createFolder(result);
      _loadFiles();
    }
  }

  Future<void> _startScan() async {
    final result = await ScannerService.startDocumentScan();
    if (result.isSuccess && result.imagePaths.isNotEmpty && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ScanPreviewScreen(
            initialImagePaths: result.imagePaths,
            initialPdfPath: result.pdfPath,
          ),
        ),
      );
      _loadFiles();
    }
  }

  void _toggleSelection(String path) {
    setState(() {
      if (_selectedFilePaths.contains(path)) {
        _selectedFilePaths.remove(path);
        if (_selectedFilePaths.isEmpty) _isSelectionMode = false;
      } else {
        _selectedFilePaths.add(path);
        _isSelectionMode = true;
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedFilePaths.length == _documents.length) {
        _selectedFilePaths.clear();
        _isSelectionMode = false;
      } else {
        _selectedFilePaths.addAll(_documents.map((d) => d.path));
        _isSelectionMode = true;
      }
    });
  }

  void _cancelSelection() {
    setState(() {
      _selectedFilePaths.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _deleteSelectedFiles() async {
    final count = _selectedFilePaths.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete $count Documents?'),
        content: const Text('Are you sure? Selected documents will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FileManagerService.deleteMultiple(_selectedFilePaths.toList());
      _cancelSelection();
      _loadFiles();
    }
  }

  Future<void> _shareSelectedFiles() async {
    await FileManagerService.shareMultiple(_selectedFilePaths.toList());
  }

  void _showItemMenu(DocumentFile doc) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoftTint,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        doc.isFolder ? Icons.folder_rounded : Icons.picture_as_pdf_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc.title,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${doc.formattedSize} • ${doc.formattedDate}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.open_in_new_rounded, color: AppColors.primary),
                title: const Text('Open / Preview', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _openDocument(doc);
                },
              ),
              ListTile(
                leading: Icon(
                  doc.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                  color: AppColors.premiumStart,
                ),
                title: Text(
                  doc.isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await FileManagerService.toggleFavorite(doc.path);
                  _loadFiles();
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_rounded, color: AppColors.aiAccent),
                title: const Text('Share Document', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  FileManagerService.shareFile(doc.path, subject: doc.title);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                title: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.error)),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      title: Text('Delete "${doc.title}"?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(dCtx).pop(false), child: const Text('Cancel')),
                        ElevatedButton(
                          onPressed: () => Navigator.of(dCtx).pop(true),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await FileManagerService.deleteItem(doc.path);
                    _loadFiles();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDocument(DocumentFile doc) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(
          document: doc,
          onFileChanged: _loadFiles,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final docs = _documents;
    final folders = _folders;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'My Files',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            tooltip: 'New Folder',
            onPressed: _createNewFolder,
          ),
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.view_module_rounded),
            tooltip: _isGridView ? 'List View' : 'Grid View',
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadFiles,
          child: Column(
            children: [
              // Search and Filter Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            hintText: 'Search files or tags...',
                            hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
                            prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Sort Filter Menu
                    PopupMenuButton<String>(
                      initialValue: _sortBy,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      onSelected: (val) => setState(() => _sortBy = val),
                      itemBuilder: (ctx) => const [
                        PopupMenuItem(value: 'Date', child: Text('Sort by Date')),
                        PopupMenuItem(value: 'Name', child: Text('Sort by Name')),
                        PopupMenuItem(value: 'Size', child: Text('Sort by Size')),
                      ],
                      child: Container(
                        height: 46,
                        width: 46,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Icon(Icons.tune_rounded, color: AppColors.textSecondary, size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              // Category Filter Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8, bottom: 8),
                      child: InkWell(
                        onTap: () => setState(() => _selectedCategory = cat),
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Multi-selection Control Strip (Active when selecting)
              if (_isSelectionMode)
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5EE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_selectedFilePaths.length}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Selected',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: _selectAll,
                            child: Text(
                              _selectedFilePaths.length == docs.length ? 'Deselect All' : 'Select All',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.primary),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                            onPressed: _cancelSelection,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // Main Content (Folders + Documents List/Grid)
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : (docs.isEmpty && folders.isEmpty)
                        ? _buildEmptyState()
                        : ListView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            children: [
                              // Folders Section (if any folders exist)
                              if (folders.isNotEmpty) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Folders (${folders.length})',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: _createNewFolder,
                                      child: const Text(
                                        '+ New',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 90,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: folders.length,
                                    separatorBuilder: (context, index) => const SizedBox(width: 10),
                                    itemBuilder: (ctx, idx) {
                                      final folder = folders[idx];
                                      return _buildFolderCard(folder);
                                    },
                                  ),
                                ),
                                const SizedBox(height: 18),
                              ],

                              // Documents Section Header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Documents (${docs.length})',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Sorted by $_sortBy',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Documents Grid or List
                              if (_isGridView)
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                    childAspectRatio: 0.85,
                                  ),
                                  itemCount: docs.length,
                                  itemBuilder: (ctx, idx) => _buildDocumentGridTile(docs[idx]),
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: docs.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                                  itemBuilder: (ctx, idx) => _buildDocumentListTile(docs[idx]),
                                ),
                              const SizedBox(height: 80),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
      // Floating Multi-select Contextual Action Bar
      bottomSheet: _isSelectionMode && _selectedFilePaths.isNotEmpty
          ? Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBottomActionButton(
                    icon: Icons.share_rounded,
                    label: 'Share',
                    onTap: _shareSelectedFiles,
                  ),
                  _buildBottomActionButton(
                    icon: Icons.call_merge_rounded,
                    label: 'Merge',
                    badge: '${_selectedFilePaths.length}',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Merge tool will activate in Step 6 (PDF Toolkit)')),
                      );
                    },
                  ),
                  _buildBottomActionButton(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete',
                    color: AppColors.error,
                    onTap: _deleteSelectedFiles,
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildFolderCard(DocumentFile folder) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opened folder "${folder.title}"')),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoftTint,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.folder_rounded, color: AppColors.primary, size: 18),
                ),
                InkWell(
                  onTap: () => _showItemMenu(folder),
                  child: const Icon(Icons.more_vert_rounded, size: 16, color: AppColors.textMuted),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  folder.title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  'Folder',
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentListTile(DocumentFile doc) {
    final isSelected = _selectedFilePaths.contains(doc.path);

    return InkWell(
      onTap: () {
        if (_isSelectionMode) {
          _toggleSelection(doc.path);
        } else {
          _openDocument(doc);
        }
      },
      onLongPress: () => _toggleSelection(doc.path),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Checkbox in selection mode or PDF Icon Thumbnail
            if (_isSelectionMode)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                  size: 22,
                ),
              ),
            // PDF Thumbnail
            Container(
              width: 44,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primarySoftTint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                color: AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),

            // Title and metadata
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${doc.formattedSize} • ${doc.formattedDate}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          doc.categoryTag,
                          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                      ),
                      if (doc.isFavorite) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.star_rounded, size: 14, color: AppColors.premiumStart),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // More Options Icon
            IconButton(
              icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted, size: 20),
              onPressed: () => _showItemMenu(doc),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentGridTile(DocumentFile doc) {
    final isSelected = _selectedFilePaths.contains(doc.path);

    return InkWell(
      onTap: () {
        if (_isSelectionMode) {
          _toggleSelection(doc.path);
        } else {
          _openDocument(doc);
        }
      },
      onLongPress: () => _toggleSelection(doc.path),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoftTint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary, size: 22),
                ),
                InkWell(
                  onTap: () => _showItemMenu(doc),
                  child: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textMuted),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  doc.formattedSize,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
    String? badge,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: color, size: 22),
              if (badge != null)
                Positioned(
                  top: -4,
                  right: -8,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: AppDimensions.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primarySoftTint,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.folder_open_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No Documents Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Scanned PDFs and imported documents will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _startScan,
              icon: const Icon(Icons.camera_alt_rounded, size: 18),
              label: const Text('Scan First Document', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
