import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../paywall/paywall_screen.dart';

/// Tools Screen for ScanPro featuring categorized PDF utilities, converters, and AI tools.
class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  void _openPaywall() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PaywallScreen(isFromOnboarding: false),
      ),
    );
  }

  void _onToolTapped(ToolItem tool) {
    if (tool.isPro) {
      _openPaywall();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${tool.title} will execute in Step 6 (PDF Tools)'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBF8),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PDF Toolkit',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'All utilities & AI converters',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: _openPaywall,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: AppColors.premiumGradient,
                        borderRadius: BorderRadius.circular(20),
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

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.toLowerCase();
                    });
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search tools (Merge, Compress, OCR...)',
                    hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
                    prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            // Categorized Tool Lists
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCategorySection(
                      title: 'Core PDF Tools',
                      icon: Icons.layers_rounded,
                      tools: [
                        ToolItem(
                          title: 'Merge PDF',
                          subtitle: 'Combine multiple PDFs into one document',
                          icon: Icons.call_merge_rounded,
                          color: AppColors.primary,
                          badge: 'BATCH',
                        ),
                        ToolItem(
                          title: 'Compress PDF',
                          subtitle: 'Reduce file size while keeping high quality',
                          icon: Icons.compress_rounded,
                          color: AppColors.primary,
                          badge: 'SAVE 80%',
                        ),
                        ToolItem(
                          title: 'Split PDF',
                          subtitle: 'Extract pages or split into separate files',
                          icon: Icons.call_split_rounded,
                          color: AppColors.primary,
                        ),
                        ToolItem(
                          title: 'Organize Pages',
                          subtitle: 'Reorder, rotate, and delete selected pages',
                          icon: Icons.format_list_numbered_rounded,
                          color: AppColors.primary,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    _buildCategorySection(
                      title: 'Convert & Export',
                      icon: Icons.transform_rounded,
                      tools: [
                        ToolItem(
                          title: 'Image to PDF',
                          subtitle: 'Convert gallery photos & receipts to PDF',
                          icon: Icons.photo_library_rounded,
                          color: const Color(0xFF0284C7),
                        ),
                        ToolItem(
                          title: 'PDF to Image',
                          subtitle: 'Extract JPG / PNG images from PDF pages',
                          icon: Icons.image_rounded,
                          color: const Color(0xFF0284C7),
                        ),
                        ToolItem(
                          title: 'PDF to Word',
                          subtitle: 'Convert PDF documents to editable Word/TXT',
                          icon: Icons.description_rounded,
                          color: const Color(0xFF0284C7),
                          isPro: true,
                          badge: 'PRO',
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    _buildCategorySection(
                      title: 'Security & Signing',
                      icon: Icons.shield_rounded,
                      tools: [
                        ToolItem(
                          title: 'Lock PDF',
                          subtitle: 'Encrypt document with AES-256 password',
                          icon: Icons.lock_rounded,
                          color: const Color(0xFFD97706),
                          badge: 'AES-256',
                        ),
                        ToolItem(
                          title: 'Unlock PDF',
                          subtitle: 'Remove password restrictions permanently',
                          icon: Icons.lock_open_rounded,
                          color: const Color(0xFFD97706),
                        ),
                        ToolItem(
                          title: 'eSign Document',
                          subtitle: 'Draw signature and place legal stamp',
                          icon: Icons.draw_rounded,
                          color: const Color(0xFFD97706),
                          isPro: true,
                          badge: 'PRO',
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    _buildCategorySection(
                      title: 'AI Document Intelligence (V2)',
                      icon: Icons.psychology_rounded,
                      tools: [
                        ToolItem(
                          title: 'OCR Text Recognition',
                          subtitle: 'Extract searchable text from photos & scans',
                          icon: Icons.text_snippet_rounded,
                          color: AppColors.aiAccent,
                          badge: 'AI OCR',
                          isPro: true,
                        ),
                        ToolItem(
                          title: 'AI Summary',
                          subtitle: 'Summarize lengthy 50-page PDFs instantly',
                          icon: Icons.summarize_rounded,
                          color: AppColors.aiAccent,
                          badge: 'AI PRO',
                          isPro: true,
                        ),
                        ToolItem(
                          title: 'Chat with PDF',
                          subtitle: 'Ask questions and get instant answers from doc',
                          icon: Icons.chat_bubble_rounded,
                          color: AppColors.aiAccent,
                          badge: 'AI PRO',
                          isPro: true,
                        ),
                        ToolItem(
                          title: 'Translate Document',
                          subtitle: 'Translate scanned files to 50+ languages',
                          icon: Icons.translate_rounded,
                          color: AppColors.aiAccent,
                          badge: 'AI PRO',
                          isPro: true,
                        ),
                      ],
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

  Widget _buildCategorySection({
    required String title,
    required IconData icon,
    required List<ToolItem> tools,
  }) {
    final filtered = _searchQuery.isEmpty
        ? tools
        : tools.where((t) => t.title.toLowerCase().contains(_searchQuery) || t.subtitle.toLowerCase().contains(_searchQuery)).toList();

    if (filtered.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 108,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final tool = filtered[index];
            return _buildToolCard(tool);
          },
        ),
      ],
    );
  }

  Widget _buildToolCard(ToolItem tool) {
    return InkWell(
      onTap: () => _onToolTapped(tool),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: tool.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(tool.icon, size: 18, color: tool.color),
                ),
                if (tool.badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: tool.isPro ? AppColors.premiumStart.withValues(alpha: 0.15) : tool.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tool.badge!,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: tool.isPro ? const Color(0xFFD97706) : tool.color,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tool.title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  tool.subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ToolItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? badge;
  final bool isPro;

  const ToolItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.badge,
    this.isPro = false,
  });
}
