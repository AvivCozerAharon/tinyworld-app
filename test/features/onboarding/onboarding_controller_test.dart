import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinyworld_app/features/onboarding/onboarding_controller.dart';

void main() {
  test('OnboardingController initial state is step 1', () {
    final container = ProviderContainer();
    final state = container.read(onboardingControllerProvider);
    expect(state.currentStep, equals(1));
    expect(state.userId, isNull);
  });

  test('OnboardingController setUserId updates state', () {
    final container = ProviderContainer();
    container.read(onboardingControllerProvider.notifier).setUserId('test-uid');
    final state = container.read(onboardingControllerProvider);
    expect(state.userId, equals('test-uid'));
  });
}
