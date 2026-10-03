import 'package:shared_preferences/shared_preferences.dart';

/// Manages onboarding state and completion flag via SharedPreferences.
class OnboardingController {
  static const String _onboardingCompleteKey = 'onboarding_complete';

  /// Check if the user has already completed onboarding.
  static Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompleteKey) ?? false;
  }

  /// Mark onboarding flow as completed.
  static Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleteKey, true);
  }

  /// Reset onboarding flag (useful for testing or debug).
  static Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingCompleteKey);
  }
}
