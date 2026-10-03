import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'controllers/onboarding_controller.dart';
import 'screens/main_nav_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isComplete = await OnboardingController.isOnboardingComplete();
  runApp(ScanProApp(isOnboardingComplete: isComplete));
}

class ScanProApp extends StatelessWidget {
  final bool isOnboardingComplete;

  const ScanProApp({
    super.key,
    required this.isOnboardingComplete,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScanPro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: isOnboardingComplete ? const MainNavScreen() : const OnboardingScreen(),
    );
  }
}
