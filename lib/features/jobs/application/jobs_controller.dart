import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../auth/application/auth_controller.dart';
import '../data/jobs_repository.dart';
import '../domain/job.dart';

final jobsRepositoryProvider = Provider<JobsRepository>((ref) {
  return JobsRepository(ref.watch(localStoreProvider));
});

class JobsState {
  const JobsState({
    this.jobs = const [],
    this.savedJobs = const [],
    this.loading = false,
    this.error,
    this.query = '',
    this.category = 'All',
    this.lastUpdated,
  });

  final List<Job> jobs;
  final List<Job> savedJobs;
  final bool loading;
  final String? error;
  final String query;
  final String category;
  final DateTime? lastUpdated;

  bool isSaved(String jobId) => savedJobs.any((job) => job.id == jobId);

  Job? jobById(String id) {
    for (final job in jobs) {
      if (job.id == id) return job;
    }
    for (final job in savedJobs) {
      if (job.id == id) return job;
    }
    return null;
  }

  JobsState copyWith({
    List<Job>? jobs,
    List<Job>? savedJobs,
    bool? loading,
    String? error,
    bool clearError = false,
    String? query,
    String? category,
    DateTime? lastUpdated,
  }) {
    return JobsState(
      jobs: jobs ?? this.jobs,
      savedJobs: savedJobs ?? this.savedJobs,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      query: query ?? this.query,
      category: category ?? this.category,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class JobsController extends StateNotifier<JobsState> {
  JobsController({required JobsRepository repository, required this.userId})
    : _repository = repository,
      super(const JobsState());

  final JobsRepository _repository;
  final String userId;
  int _request = 0;

  Future<void> load() async {
    final saved = _repository.loadSaved(userId);
    state = state.copyWith(savedJobs: saved, loading: true, clearError: true);
    await _fetch();
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true, clearError: true);
    await _fetch();
  }

  Future<void> search(String query) async {
    state = state.copyWith(
      query: query.trim(),
      loading: true,
      clearError: true,
    );
    await _fetch();
  }

  Future<void> setCategory(String category) async {
    if (state.category == category) return;
    state = state.copyWith(category: category, loading: true, clearError: true);
    await _fetch();
  }

  Future<void> clearFilters() async {
    state = state.copyWith(
      query: '',
      category: 'All',
      loading: true,
      clearError: true,
    );
    await _fetch();
  }

  Future<void> _fetch() async {
    final request = ++_request;
    try {
      final jobs = await _repository.fetchJobs(
        query: state.query,
        category: state.category,
      );
      if (!mounted || request != _request) return;
      state = state.copyWith(
        jobs: jobs,
        loading: false,
        lastUpdated: DateTime.now(),
        clearError: true,
      );
    } on JobsException catch (error) {
      if (!mounted || request != _request) return;
      state = state.copyWith(loading: false, error: error.message);
    } catch (_) {
      if (!mounted || request != _request) return;
      state = state.copyWith(
        loading: false,
        error: 'Could not load jobs. Check your connection and try again.',
      );
    }
  }

  Future<void> toggleSaved(Job job) async {
    if (userId.isEmpty) return;
    final saved = _repository.loadSaved(userId);
    if (saved.any((item) => item.id == job.id)) {
      await _repository.removeFavorite(userId, job.id);
    } else {
      await _repository.saveFavorite(userId, job);
    }
    state = state.copyWith(savedJobs: _repository.loadSaved(userId));
  }
}

final jobsControllerProvider = StateNotifierProvider<JobsController, JobsState>(
  (ref) {
    final userId =
        ref.watch(authControllerProvider.select((s) => s.user?.id)) ?? '';
    final controller = JobsController(
      repository: ref.watch(jobsRepositoryProvider),
      userId: userId,
    );
    controller.load();
    return controller;
  },
);
