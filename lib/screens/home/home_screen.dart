import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/document_file.dart';
import '../../services/file_manager_service.dart';
import '../../services/scanner_service.dart';
import '../files/pdf_viewer_screen.dart';
import '../paywall/paywall_screen.dart';
import '../scan/id_card_scan_screen.dart';
import '../scan/scan_preview_screen.dart';

/// Home Screen for ScanPro featuring Quick Actions, Search & Filters, and Recent Documents.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  List<DocumentFile> _recentFiles = [];

  final List<String> _categories = const [
    'All',
    'Invoices',
    'Receipts',
    'ID Cards',
    'Notes',
    'Contracts',
  ];

  @override
  void initState() {
    super.initState();
    _loadRecentDocuments();
  }

  Future<void> _loadRecentDocuments() async {
    final files = await FileManagerService.loadAllFiles();
    if (mounted) {
      setState(() {
        _recentFiles = files.where((f) => !f.isFolder).toList();
      });
    }
  }

  void _openPaywall() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PaywallScreen(isFromOnboarding: false),
      ),
    );
  }

  Future<void> _onScanTapped(String mode) async {
    if (mode == 'Gallery Import') {
      final picked = await ScannerService.pickImagesFromGallery();
      if (picked.isNotEmpty && mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ScanPreviewScreen(
              initialImagePaths: picked,
            ),
          ),
        );
        _loadRecentDocuments();
      }
      return;
    }

    if (mode == 'ID Card Scan') {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const IdCardScanScreen()),
      );
      _loadRecentDocuments();
      return;
    }

    final result = await ScannerService.startDocumentScan(pageLimit: 50);
    if (result.isSuccess && result.imagePaths.isNotEmpty && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ScanPreviewScreen(
            initialImagePaths: result.imagePaths,
            initialPdfPath: result.pdfPath,
          ),
        ),
      );
      _loadRecentDocuments();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filteredDocs = _recentFiles.where((doc) {
      if (query.isNotEmpty && !doc.title.toLowerCase().contains(query)) {
        return false;
      }
      if (_selectedCategory != 'All' && doc.categoryTag != _selectedCategory) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6FBF8),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar: Brand Logo & Pro Crown Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.document_scanner_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ScanPro',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Document Toolkit',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Pro Upgrade Pill
                  InkWell(
                    onTap: _openPaywall,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: AppColors.premiumGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.premiumStart.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'PRO',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // Search Bar
                    Container(
                      height: AppDimensions.searchBarHeight,
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
                        decoration: const InputDecoration(
                          hintText: 'Search documents, receipts, IDs...',
                          hintStyle: TextStyle(fontSize: 13.5, color: AppColors.textMuted),
                          prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Category Filter Pills
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: _categories.map((category) {
                          final isSelected = _selectedCategory == category;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedCategory = category;
                                });
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                                  ),
                                  boxShadow: [
                                    if (isSelected)
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                  ],
                                ),
                                child: Text(
                                  category,
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
                    const SizedBox(height: 18),

                    // Quick Actions Banner (Hero Grid)
                    Row(
                      children: [
                        // Primary Scan Card
                        Expanded(
                          flex: 12,
                          child: InkWell(
                            onTap: () => _onScanTapped('Camera Scan'),
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              height: 125,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.25),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 22),
                                  ),
                                  const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Scan Document',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Smart Edge & Crop',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Secondary Quick Actions (Gallery & ID Card)
                        Expanded(
                          flex: 11,
                          child: Column(
                            children: [
                              // Import from Gallery
                              InkWell(
                                onTap: () => _onScanTapped('Gallery Import'),
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  height: 58,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppColors.primarySoftTint,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.photo_library_rounded, size: 16, color: AppColors.primary),
                                      ),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text(
                                          'Import Gallery',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 9),

                              // ID Card Scan
                              InkWell(
                                onTap: () => _onScanTapped('ID Card Scan'),
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  height: 58,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF3E8FF),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.badge_rounded, size: 16, color: AppColors.aiAccent),
                                      ),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text(
                                          'ID Card Scan',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Daily Free Scans Quota Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoftTint,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFD4ECE0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.offline_bolt_rounded, size: 18, color: AppColors.primary),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Daily Free Limit: 3 / 5 Scans Left',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                                ),
                                Text(
                                  'Watch ad for +1 extra scan or upgrade to Pro',
                                  style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: _openPaywall,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Upgrade',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Section Title: Recent Documents
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Scans',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          '${filteredDocs.length} files',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Recent Docs List or Empty State
                    if (filteredDocs.isEmpty)
                      _buildEmptyState()
                    else
                      Column(
                        children: filteredDocs.map((doc) => _buildDocCard(doc)).toList(),
                      ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocCard(DocumentFile doc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PdfViewerScreen(
                document: doc,
                onFileChanged: _loadRecentDocuments,
              ),
            ),
          );
          _loadRecentDocuments();
        },
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primarySoftTint,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary, size: 22),
          ),
        ),
        title: Text(
          doc.title,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(
              doc.formattedDate,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
            Text(
              doc.formattedSize,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary, size: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          onSelected: (value) async {
            if (value == 'Share') {
              FileManagerService.shareFile(doc.path, subject: doc.title);
            } else if (value == 'Delete') {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  title: Text('Delete "${doc.title}"?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                    ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await FileManagerService.deleteItem(doc.path);
                _loadRecentDocuments();
              }
            } else if (value == 'Favorite') {
              await FileManagerService.toggleFavorite(doc.path);
              _loadRecentDocuments();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'Share', child: Row(children: [Icon(Icons.share_rounded, size: 18), SizedBox(width: 10), Text('Share PDF')])),
            PopupMenuItem(value: 'Favorite', child: Row(children: [Icon(doc.isFavorite ? Icons.star_rounded : Icons.star_border_rounded, size: 18, color: AppColors.premiumStart), const SizedBox(width: 10), Text(doc.isFavorite ? 'Unfavorite' : 'Favorite')])),
            const PopupMenuItem(value: 'Delete', child: Row(children: [Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red), SizedBox(width: 10), Text('Delete', style: TextStyle(color: Colors.red))])),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primarySoftTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.folder_open_rounded, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 14),
            const Text(
              'No documents found',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tap the Scan button below to scan your first file',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
