import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers.dart';
import '../../../core/services/ai_service.dart';
import '../../auth/application/auth_controller.dart';
import '../data/interview_repository.dart';
import '../domain/interview_models.dart';

final interviewRepositoryProvider = Provider<InterviewRepository>((ref) {
  return InterviewRepository(ref.watch(localStoreProvider));
});

class InterviewState {
  const InterviewState({
    this.loading = false,
    this.generating = false,
    this.evaluating = false,
    this.sessions = const [],
    this.current,
    this.error,
  });

  final bool loading;
  final bool generating;
  final bool evaluating;
  final List<InterviewSession> sessions;
  final InterviewSession? current;
  final String? error;

  InterviewQuestion? get currentQuestion {
    final session = current;
    if (session == null) return null;
    if (session.answers.length >= session.questions.length) return null;
    return session.questions[session.answers.length];
  }

  bool get isFinished {
    final session = current;
    if (session == null) return false;
    return session.answers.length >= session.questions.length;
  }

  InterviewSession? sessionById(String id) {
    for (final session in sessions) {
      if (session.id == id) return session;
    }
    if (current?.id == id) return current;
    return null;
  }

  InterviewState copyWith({
    bool? loading,
    bool? generating,
    bool? evaluating,
    List<InterviewSession>? sessions,
    InterviewSession? current,
    bool clearCurrent = false,
    String? error,
    bool clearError = false,
  }) {
    return InterviewState(
      loading: loading ?? this.loading,
      generating: generating ?? this.generating,
      evaluating: evaluating ?? this.evaluating,
      sessions: sessions ?? this.sessions,
      current: clearCurrent ? null : (current ?? this.current),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class InterviewController extends StateNotifier<InterviewState> {
  InterviewController({
    required InterviewRepository repository,
    required AiService ai,
    required this.userId,
  }) : _repository = repository,
       _ai = ai,
       super(const InterviewState());

  final InterviewRepository _repository;
  final AiService _ai;
  final String userId;
  static const _uuid = Uuid();

  Future<void> load() async {
    if (userId.isEmpty) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final sessions = _repository.loadSessions(userId);
      if (!mounted) return;
      state = state.copyWith(sessions: sessions, loading: false);
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        loading: false,
        error: 'Could not load your interview history.',
      );
    }
  }

  Future<bool> start({
    required String role,
    required String category,
    required String level,
  }) async {
    if (userId.isEmpty) return false;
    state = state.copyWith(
      generating: true,
      clearError: true,
      clearCurrent: true,
    );
    try {
      final questions = await _ai.generateInterviewQuestions(
        role: role,
        category: category,
        level: level,
      );
      if (!mounted) return false;
      state = state.copyWith(
        current: InterviewSession(
          id: _uuid.v4(),
          role: role,
          category: category,
          level: level,
          questions: questions,
          answers: const [],
          createdAt: DateTime.now(),
        ),
        generating: false,
      );
      return true;
    } catch (_) {
      if (!mounted) return false;
      state = state.copyWith(
        generating: false,
        error: 'Could not start the interview. Please try again.',
      );
      return false;
    }
  }

  Future<bool> submitAnswer(String answer) async {
    final session = state.current;
    final question = state.currentQuestion;
    if (session == null || question == null) return false;
    if (answer.trim().length < 12) {
      state = state.copyWith(
        error: 'Give a little more detail before submitting your answer.',
      );
      return false;
    }
    state = state.copyWith(evaluating: true, clearError: true);
    try {
      final feedback = await _ai.evaluateInterviewAnswer(
        question: question,
        answer: answer.trim(),
        role: session.role,
      );
      if (!mounted) return false;
      final answers = [
        ...session.answers,
        InterviewAnswer(
          question: question,
          answer: answer.trim(),
          feedback: feedback,
        ),
      ];
      state = state.copyWith(
        current: session.copyWith(answers: answers),
        evaluating: false,
      );
      return true;
    } catch (_) {
      if (!mounted) return false;
      state = state.copyWith(
        evaluating: false,
        error: 'We could not evaluate that answer. Please try again.',
      );
      return false;
    }
  }

  Future<InterviewSession?> finish() async {
    final session = state.current;
    if (session == null) return null;
    final completed = session.copyWith(completed: true);
    await _repository.saveSession(userId, completed);
    if (!mounted) return completed;
    state = state.copyWith(
      sessions: _repository.loadSessions(userId),
      current: completed,
    );
    return completed;
  }

  void reset() {
    state = state.copyWith(clearCurrent: true, clearError: true);
  }

  Future<void> deleteSession(String id) async {
    await _repository.deleteSession(userId, id);
    state = state.copyWith(sessions: _repository.loadSessions(userId));
  }

  InterviewSession? sessionById(String id) {
    for (final session in state.sessions) {
      if (session.id == id) return session;
    }
    if (state.current?.id == id) return state.current;
    return null;
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final interviewControllerProvider =
    StateNotifierProvider<InterviewController, InterviewState>((ref) {
      final userId =
          ref.watch(authControllerProvider.select((s) => s.user?.id)) ?? '';
      final controller = InterviewController(
        repository: ref.watch(interviewRepositoryProvider),
        ai: ref.watch(aiServiceProvider),
        userId: userId,
      );
      if (userId.isNotEmpty) {
        controller.load();
      }
      return controller;
    });
