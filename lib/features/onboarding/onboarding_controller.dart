import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinyworld_app/core/api/rest_client.dart';
import 'package:tinyworld_app/core/storage/local_storage.dart';

class OnboardingState {
  final int currentStep;
  final String? userId;
  final String? userName;
  final String gender;
  final Map<String, dynamic>? appearance;
  final List<String> hobbies;
  final String? avatarUrl;
  final bool isLoading;
  final String? error;

  const OnboardingState({
    this.currentStep = 1,
    this.userId,
    this.userName,
    this.gender = '',
    this.appearance,
    this.hobbies = const [],
    this.avatarUrl,
    this.isLoading = false,
    this.error,
  });

  OnboardingState copyWith({
    int? currentStep,
    String? userId,
    String? userName,
    String? gender,
    Map<String, dynamic>? appearance,
    List<String>? hobbies,
    String? avatarUrl,
    bool? isLoading,
    String? error,
  }) =>
      OnboardingState(
        currentStep: currentStep ?? this.currentStep,
        userId: userId ?? this.userId,
        userName: userName ?? this.userName,
        gender: gender ?? this.gender,
        appearance: appearance ?? this.appearance,
        hobbies: hobbies ?? this.hobbies,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class OnboardingController extends StateNotifier<OnboardingState> {
  OnboardingController() : super(const OnboardingState()) {
    _init();
  }

  Future<void> _init() async {
    await _refreshToken();
    final savedId = await localStorage.getUserId();
    if (savedId != null && state.userId == null) {
      state = state.copyWith(userId: savedId);
    }
  }

  Future<void> _refreshToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await user.getIdToken(true);
      if (token != null) {
        await localStorage.saveIdToken(token);
      }
    }
  }

  void setUserId(String id) => state = state.copyWith(userId: id);

  void setGender(String gender) => state = state.copyWith(gender: gender);

  Future<bool> register({
    required String name,
    required String birthDate,
    required String sexualOrientation,
    String gender = '',
  }) async {
    state = state.copyWith(isLoading: true, error: null, gender: gender);
    try {
      await _refreshToken();
      final resp = await apiClient.post('/auth/register', data: {
        'name': name,
        'birth_date': birthDate,
        'sexual_orientation': sexualOrientation,
        'gender': gender,
      });
      final userId = resp.data['user_id'] as String;
      await localStorage.saveUserId(userId);
      state = state.copyWith(
          userId: userId, userName: name, isLoading: false, currentStep: 2);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void setAppearance(Map<String, dynamic> appearance) =>
      state = state.copyWith(appearance: {...?state.appearance, ...appearance});

  Future<bool> saveAvatar(String style) async {
    state = state.copyWith(isLoading: true);
    try {
      await _refreshToken();
      final resp = await apiClient.post('/onboarding/avatar', data: {
        'style': style,
        'appearance': state.appearance,
      });
      state = state.copyWith(
        avatarUrl: resp.data['avatar_url'] as String,
        isLoading: false,
        currentStep: 3,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> saveHobbies(List<String> hobbies) async {
    state = state.copyWith(isLoading: true);
    try {
      await _refreshToken();
      await apiClient.post('/onboarding/hobbies', data: {
        'hobbies': hobbies,
      });
      state =
          state.copyWith(hobbies: hobbies, isLoading: false, currentStep: 4);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> completeOnboarding() async {
    try {
      await _refreshToken();
      await apiClient.patch('/onboarding/complete');
      await localStorage.setOnboardingDone(true);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, OnboardingState>(
  (_) => OnboardingController(),
);
