import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';

part 'onboarding_provider.g.dart';

@Riverpod(keepAlive: true)
class OnboardingController extends _$OnboardingController {
  static const String _hasCompletedOnboardingKey = 'has_completed_onboarding';

  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(_hasCompletedOnboardingKey) ?? false;
  }

  Future<void> completeOnboarding() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_hasCompletedOnboardingKey, true);
    state = true;
  }

  Future<void> resetOnboarding() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_hasCompletedOnboardingKey, false);
    state = false;
  }
}
