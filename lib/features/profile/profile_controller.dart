import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinyworld_app/core/api/rest_client.dart';

class ProfileData {
  final String userId;
  final String name;
  final String avatarUrl;
  final List<String> hobbies;
  final bool onboardingCompleted;

  const ProfileData({
    required this.userId,
    required this.name,
    required this.avatarUrl,
    required this.hobbies,
    required this.onboardingCompleted,
  });
}

class ProfileState {
  final ProfileData? profile;
  final bool isLoading;
  final String? error;

  const ProfileState({this.profile, this.isLoading = false, this.error});

  ProfileState copyWith({ProfileData? profile, bool? isLoading, String? error}) =>
      ProfileState(
        profile: profile ?? this.profile,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class ProfileController extends StateNotifier<ProfileState> {
  ProfileController() : super(const ProfileState());

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final resp = await apiClient.get('/profile/me');
      final data = resp.data as Map<String, dynamic>;
      state = state.copyWith(
        isLoading: false,
        profile: ProfileData(
          userId: data['user_id'] as String,
          name: data['name'] as String,
          avatarUrl: data['avatar_url'] as String? ?? '',
          hobbies: (data['hobbies'] as List?)?.cast<String>() ?? [],
          onboardingCompleted: data['onboarding_completed'] as bool? ?? false,
        ),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

class TrainQuestion {
  final String questionId;
  final String questionType;
  final String question;
  final List<String>? options;

  const TrainQuestion({
    required this.questionId,
    required this.questionType,
    required this.question,
    this.options,
  });
}

class TrainState {
  final TrainQuestion? currentQuestion;
  final int totalAnswered;
  final bool isLoading;
  final String? error;
  final String? lastFeedback;

  const TrainState({
    this.currentQuestion,
    this.totalAnswered = 0,
    this.isLoading = false,
    this.error,
    this.lastFeedback,
  });

  TrainState copyWith({
    TrainQuestion? currentQuestion,
    int? totalAnswered,
    bool? isLoading,
    String? error,
    String? lastFeedback,
  }) =>
      TrainState(
        currentQuestion: currentQuestion ?? this.currentQuestion,
        totalAnswered: totalAnswered ?? this.totalAnswered,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        lastFeedback: lastFeedback,
      );
}

class TrainController extends StateNotifier<TrainState> {
  TrainController() : super(const TrainState());

  Future<void> fetchQuestion() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final resp = await apiClient.get('/profile/train/question');
      final data = resp.data as Map<String, dynamic>;
      state = state.copyWith(
        isLoading: false,
        currentQuestion: TrainQuestion(
          questionId: data['question_id'] as String,
          questionType: data['question_type'] as String,
          question: data['question'] as String,
          options: (data['options'] as List?)?.cast<String>(),
        ),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> submitAnswer(String answer) async {
    final q = state.currentQuestion;
    if (q == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final resp = await apiClient.post('/profile/train/answer', data: {
        'question_id': q.questionId,
        'question_type': q.questionType,
        'answer': answer,
      });
      final data = resp.data as Map<String, dynamic>;
      final next = data['next_question'] as Map<String, dynamic>?;
      state = state.copyWith(
        isLoading: false,
        totalAnswered: state.totalAnswered + 1,
        currentQuestion: next != null
            ? TrainQuestion(
                questionId: next['question_id'] as String,
                questionType: next['question_type'] as String,
                question: next['question'] as String,
                options: (next['options'] as List?)?.cast<String>(),
              )
            : null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileState>(
  (_) => ProfileController()..loadProfile(),
);

final trainControllerProvider =
    StateNotifierProvider<TrainController, TrainState>(
  (_) => TrainController()..fetchQuestion(),
);

class MemoryItem {
  final String fact;
  final String category;

  const MemoryItem({required this.fact, required this.category});
}

class BrainState {
  final List<MemoryItem> memories;
  final int total;
  final bool isLoading;
  final String? error;

  const BrainState({
    this.memories = const [],
    this.total = 0,
    this.isLoading = false,
    this.error,
  });

  BrainState copyWith({
    List<MemoryItem>? memories,
    int? total,
    bool? isLoading,
    String? error,
  }) =>
      BrainState(
        memories: memories ?? this.memories,
        total: total ?? this.total,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class BrainController extends StateNotifier<BrainState> {
  BrainController() : super(const BrainState());

  Future<void> loadMemories() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final resp = await apiClient.get('/profile/memories');
      final data = resp.data as Map<String, dynamic>;
      final items = (data['memories'] as List)
          .map((m) => MemoryItem(
                fact: m['fact'] as String,
                category: m['category'] as String? ?? 'outro',
              ))
          .toList();
      state = state.copyWith(memories: items, total: data['total'] as int, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final brainControllerProvider =
    StateNotifierProvider<BrainController, BrainState>(
  (_) => BrainController()..loadMemories(),
);
