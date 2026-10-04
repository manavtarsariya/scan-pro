import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../paywall/paywall_screen.dart';

/// Complete Settings & App Preferences Screen for ScanPro.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Preference States
  String _pdfQuality = 'High (300 DPI)';
  String _pageSize = 'A4';
  bool _autoEdgeDetection = true;
  bool _autoSaveToGallery = false;
  String _selectedLanguage = 'English';

  // Storage calculation state
  String _cacheSize = 'Calculating...';
  String _documentsSize = 'Calculating...';
  int _documentCount = 0;
  bool _isClearingCache = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _calculateStorageUsage();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _pdfQuality = prefs.getString('pref_pdf_quality') ?? 'High (300 DPI)';
        _pageSize = prefs.getString('pref_page_size') ?? 'A4';
        _autoEdgeDetection = prefs.getBool('pref_auto_edge') ?? true;
        _autoSaveToGallery = prefs.getBool('pref_auto_save_gallery') ?? false;
        _selectedLanguage = prefs.getString('pref_language') ?? 'English';
      });
    }
  }

  Future<void> _calculateStorageUsage() async {
    try {
      // 1. Calc Cache Directory Size
      final tempDir = await getTemporaryDirectory();
      int tempBytes = await _getDirSize(tempDir);

      // 2. Calc App Documents Directory Size & Count
      final appDocDir = await getApplicationDocumentsDirectory();
      final docsDir = Directory('${appDocDir.path}/ScanPro_Documents');
      int docBytes = 0;
      int docCount = 0;

      if (await docsDir.exists()) {
        final list = docsDir.listSync(recursive: true);
        for (var file in list) {
          if (file is File) {
            docBytes += await file.length();
            if (file.path.endsWith('.pdf')) {
              docCount++;
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _cacheSize = _formatBytes(tempBytes);
          _documentsSize = _formatBytes(docBytes);
          _documentCount = docCount;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _cacheSize = '0.0 MB';
          _documentsSize = '0.0 MB';
        });
      }
    }
  }

  Future<int> _getDirSize(Directory dir) async {
    int totalSize = 0;
    try {
      if (await dir.exists()) {
        final files = dir.listSync(recursive: true, followLinks: false);
        for (var file in files) {
          if (file is File) {
            totalSize += await file.length();
          }
        }
      }
    } catch (_) {}
    return totalSize;
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0.0 MB';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _clearCache() async {
    setState(() => _isClearingCache = true);
    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        final files = tempDir.listSync(recursive: true);
        for (var file in files) {
          try {
            if (file is File) {
              await file.delete();
            }
          } catch (_) {}
        }
      }
      await _calculateStorageUsage();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Temporary cache cleared successfully!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not clear cache: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isClearingCache = false);
    }
  }

  Future<void> _savePreference(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    }
  }

  void _openPaywall() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PaywallScreen(isFromOnboarding: false),
      ),
    );
  }

  void _showQualityPicker() {
    final qualities = [
      'High (300 DPI)',
      'Medium (150 DPI)',
      'Standard (72 DPI)',
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Default PDF Quality',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              ...qualities.map((q) => ListTile(
                    title: Text(q, style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: _pdfQuality == q
                        ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                        : null,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: () {
                      setState(() => _pdfQuality = q);
                      _savePreference('pref_pdf_quality', q);
                      Navigator.pop(ctx);
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }

  void _showPageSizePicker() {
    final sizes = ['A4', 'US Letter', 'Legal', 'Auto Fit'];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Default Page Size',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              ...sizes.map((s) => ListTile(
                    title: Text(s, style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: _pageSize == s
                        ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                        : null,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: () {
                      setState(() => _pageSize = s);
                      _savePreference('pref_page_size', s);
                      Navigator.pop(ctx);
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguagePicker() {
    final languages = [
      {'name': 'English', 'native': 'English'},
      {'name': 'Gujarati', 'native': 'ગુજરાતી'},
      {'name': 'Hindi', 'native': 'हिन्दी'},
      {'name': 'Spanish', 'native': 'Español'},
      {'name': 'French', 'native': 'Français'},
      {'name': 'Arabic', 'native': 'العربية'},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select App Language',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              ...languages.map((lang) {
                final isSelected = _selectedLanguage == lang['name'];
                return ListTile(
                  title: Text(lang['name']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    lang['native']!,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                      : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () {
                    setState(() => _selectedLanguage = lang['name']!);
                    _savePreference('pref_language', lang['name']!);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Language changed to ${lang['name']}'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.privacy_tip_outlined, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        content: const SingleChildScrollView(
          child: Text(
            '100% Offline & Private\n\n'
            '• ScanPro operates completely on your local device.\n'
            '• None of your documents, scans, or photos are ever uploaded to cloud servers without your explicit consent.\n'
            '• PDF modifications, compression, password encryption, watermarks, and e-signatures are processed locally using your phone\'s processing power.\n'
            '• We do not track personal identifying information.\n\n'
            'Your privacy is our utmost priority.',
            style: TextStyle(height: 1.4, fontSize: 13.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.gavel_outlined, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Terms of Service', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        content: const SingleChildScrollView(
          child: Text(
            'ScanPro License Agreement\n\n'
            '• ScanPro is provided "as is" for scanning, viewing, and modifying documents.\n'
            '• You retain full ownership and intellectual property rights of all files created or modified within the app.\n'
            '• Password protected PDFs are secured with industry standard AES/Standard encryption. Please remember your passwords as they cannot be recovered.\n'
            '• ScanPro is not liable for data loss caused by device hardware failures or OS clears.',
            style: TextStyle(height: 1.4, fontSize: 13.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Agree & Close', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _shareApp() {
    SharePlus.instance.share(
      ShareParams(
        text:
            'Check out ScanPro: The ultimate Offline Document Scanner & PDF Toolkit! Download now: https://play.google.com/store/apps/details?id=com.example.scan_pro',
      ),
    );
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
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Preferences & app management',
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
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: AppColors.premiumGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.premiumStart.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'PRO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main Scrollable List
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                children: [
                  // 1. VIP / Pro Subscription Banner
                  _buildProBanner(),

                  const SizedBox(height: 20),

                  // 2. Scan & PDF Preferences
                  _buildSectionHeader('SCAN & PDF PREFERENCES'),
                  _buildCard([
                    _buildListTile(
                      icon: Icons.high_quality_outlined,
                      title: 'Default PDF Quality',
                      subtitle: _pdfQuality,
                      onTap: _showQualityPicker,
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildListTile(
                      icon: Icons.aspect_ratio_outlined,
                      title: 'Default Page Size',
                      subtitle: _pageSize,
                      onTap: _showPageSizePicker,
                    ),
                    const Divider(height: 1, indent: 56),
                    SwitchListTile(
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoftTint,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.crop_outlined, color: AppColors.primary, size: 20),
                      ),
                      title: const Text('Auto-Edge Detection', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text('Detect page borders automatically during scan', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      value: _autoEdgeDetection,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() => _autoEdgeDetection = val);
                        _savePreference('pref_auto_edge', val);
                      },
                    ),
                    const Divider(height: 1, indent: 56),
                    SwitchListTile(
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoftTint,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.photo_library_outlined, color: AppColors.primary, size: 20),
                      ),
                      title: const Text('Auto-Save Scans to Gallery', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text('Save scanned image copies to photo gallery', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      value: _autoSaveToGallery,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() => _autoSaveToGallery = val);
                        _savePreference('pref_auto_save_gallery', val);
                      },
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // 3. Storage & Cache
                  _buildSectionHeader('STORAGE & CACHE'),
                  _buildCard([
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoftTint,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.folder_open_outlined, color: AppColors.primary, size: 20),
                      ),
                      title: const Text('My Scanned Documents', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text('$_documentCount PDFs stored locally ($_documentsSize)', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoftTint,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.cleaning_services_outlined, color: AppColors.primary, size: 20),
                      ),
                      title: const Text('Temporary Cache', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text('$_cacheSize cached files', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      trailing: _isClearingCache
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.primary),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _clearCache,
                              child: const Text('Clear', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // 4. App Preferences
                  _buildSectionHeader('APP PREFERENCES'),
                  _buildCard([
                    _buildListTile(
                      icon: Icons.language_outlined,
                      title: 'App Language',
                      subtitle: _selectedLanguage,
                      onTap: _showLanguagePicker,
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // 5. About & Support
                  _buildSectionHeader('ABOUT & SUPPORT'),
                  _buildCard([
                    _buildListTile(
                      icon: Icons.share_outlined,
                      title: 'Share ScanPro',
                      subtitle: 'Tell your friends & colleagues',
                      onTap: _shareApp,
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildListTile(
                      icon: Icons.star_border_rounded,
                      title: 'Rate on Google Play',
                      subtitle: 'Support us with a 5-star review',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Thank you for supporting ScanPro!'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildListTile(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      subtitle: '100% offline & local processing',
                      onTap: _showPrivacyPolicyDialog,
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildListTile(
                      icon: Icons.gavel_outlined,
                      title: 'Terms of Service',
                      subtitle: 'End user license terms',
                      onTap: _showTermsDialog,
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoftTint,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                      ),
                      title: const Text('Version', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'v1.0.0 (Build 1)',
                          style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ),
                    ),
                  ]),

                  // Bottom Spacing for floating button & bottom navigation bar
                  const SizedBox(height: 110),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: AppColors.textMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primarySoftTint,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
      onTap: onTap,
    );
  }

  Widget _buildProBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF064E3B), // Emerald
            Color(0xFF0F766E), // Teal-emerald
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.workspace_premium, color: Colors.amber, size: 30),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'ScanPro VIP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 6),
                    Chip(
                      label: Text(
                        'PRO',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                      backgroundColor: Colors.amber,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                SizedBox(height: 3),
                Text(
                  'Unlimited scans, HD export & no ads',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              elevation: 0,
            ),
            onPressed: _openPaywall,
            child: const Text(
              'Upgrade',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
