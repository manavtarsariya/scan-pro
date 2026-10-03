import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_dimensions.dart';
import '../services/scanner_service.dart';
import 'scan/scan_preview_screen.dart';
import 'home/home_screen.dart';
import 'tools/tools_screen.dart';
import 'files/files_screen.dart';
import 'settings/settings_screen.dart';

/// Main navigation wrapper holding the 4 bottom tabs and the central elevated Scan button.
class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ToolsScreen(),
    FilesScreen(),
    SettingsScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _onScanTapped() async {
    final result = await ScannerService.startDocumentScan();
    if (result.isSuccess && result.imagePaths.isNotEmpty && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ScanPreviewScreen(
            initialImagePaths: result.imagePaths,
            initialPdfPath: result.pdfPath,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        width: AppDimensions.scanButtonSize,
        height: AppDimensions.scanButtonSize,
        margin: const EdgeInsets.only(top: 10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _onScanTapped,
            child: const Icon(
              Icons.camera_alt_rounded,
              color: AppColors.textOnPrimary,
              size: 30,
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: AppDimensions.bottomNavHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.home_rounded,
                  label: 'Home',
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.grid_view_rounded,
                  label: 'Tools',
                ),
                // Spacer for the center floating Scan button
                const SizedBox(width: AppDimensions.scanButtonSize),
                _buildNavItem(
                  index: 2,
                  icon: Icons.folder_rounded,
                  label: 'Files',
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppColors.primary : AppColors.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primarySoftTint : Colors.transparent,
                borderRadius: AppDimensions.roundedFull,
              ),
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
