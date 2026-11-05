import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers.dart';
import '../../../core/services/ai_service.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/app_user.dart';
import '../data/resume_repository.dart';
import '../domain/resume_models.dart';

final resumeRepositoryProvider = Provider<ResumeRepository>((ref) {
  return ResumeRepository(ref.watch(localStoreProvider));
});

class ResumeState {
  const ResumeState({
    this.loading = false,
    this.resumes = const [],
    this.analyses = const [],
    this.coverLetters = const [],
    this.matches = const [],
    this.error,
  });

  final bool loading;
  final List<Resume> resumes;
  final List<ResumeAnalysis> analyses;
  final List<CoverLetter> coverLetters;
  final List<JobMatchResult> matches;
  final String? error;

  ResumeAnalysis? get latestAnalysis =>
      analyses.isEmpty ? null : analyses.first;

  JobMatchResult? get latestMatch => matches.isEmpty ? null : matches.first;

  Resume? get primaryResume {
    if (resumes.isEmpty) return null;
    return resumes.first;
  }

  ResumeAnalysis? analysisById(String id) {
    for (final analysis in analyses) {
      if (analysis.id == id) return analysis;
    }
    return null;
  }

  Resume? resumeById(String id) {
    for (final resume in resumes) {
      if (resume.id == id) return resume;
    }
    return null;
  }

  CoverLetter? coverLetterById(String id) {
    for (final letter in coverLetters) {
      if (letter.id == id) return letter;
    }
    return null;
  }

  ResumeState copyWith({
    bool? loading,
    List<Resume>? resumes,
    List<ResumeAnalysis>? analyses,
    List<CoverLetter>? coverLetters,
    List<JobMatchResult>? matches,
    String? error,
    bool clearError = false,
  }) {
    return ResumeState(
      loading: loading ?? this.loading,
      resumes: resumes ?? this.resumes,
      analyses: analyses ?? this.analyses,
      coverLetters: coverLetters ?? this.coverLetters,
      matches: matches ?? this.matches,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ResumeController extends StateNotifier<ResumeState> {
  ResumeController({
    required ResumeRepository repository,
    required AiService ai,
    required this.userId,
    this.user,
  }) : _repository = repository,
       _ai = ai,
       super(const ResumeState());

  final ResumeRepository _repository;
  final AiService _ai;
  final String userId;
  final AppUser? user;
  static const _uuid = Uuid();
  bool _seeding = false;

  Future<void> load() async {
    if (userId.isEmpty) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final resumes = _repository.loadResumes(userId);
      final analyses = _repository.loadAnalyses(userId);
      final letters = _repository.loadCoverLetters(userId);
      final matches = _repository.loadMatches(userId);
      if (!mounted) return;
      state = ResumeState(
        resumes: resumes,
        analyses: analyses,
        coverLetters: letters,
        matches: matches,
      );
      if (resumes.isEmpty &&
          analyses.isEmpty &&
          letters.isEmpty &&
          matches.isEmpty &&
          user?.email == 'demo@veyora.app') {
        await _seedDemoData();
      }
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        loading: false,
        error: 'We could not load your resume workspace.',
      );
    }
  }

  Future<void> _seedDemoData() async {
    if (_seeding || user == null) return;
    _seeding = true;
    try {
      final targetRole = user!.targetRole.isEmpty
          ? 'Flutter Developer'
          : user!.targetRole;
      final summary = await _ai.generateSummary(
        name: user!.name,
        role: targetRole,
        skills: user!.skills,
        experienceLevel: user!.experienceLevel,
      );
      final resume = Resume(
        id: _uuid.v4(),
        title: '${targetRole.split(' ').first} Resume',
        fullName: user!.name,
        targetRole: targetRole,
        email: user!.email,
        phone: user!.phone,
        location: user!.location,
        linkedin: 'linkedin.com/in/aaravmehta',
        summary: summary,
        template: 'Modern',
        skills: user!.skills,
        education: user!.education,
        experience: user!.experience,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
      );
      await _repository.saveResume(userId, resume);

      final analysis = await _ai.analyzeResume(
        text: resume.plainText,
        targetRole: targetRole,
        resumeName: resume.title,
      );
      await _repository.saveAnalysis(userId, analysis);

      const sampleJob =
          'We are hiring a Senior Flutter Developer to build offline-first mobile experiences. '
          'You will own architecture, work with Firebase and REST APIs, write unit tests, '
          'profile performance, and partner with design to ship accessible interfaces. '
          'Experience with Dart, Flutter, Git, CI/CD and app store releases is required.';
      final match = await _ai.matchJob(
        resumeText: resume.plainText,
        jobDescription: sampleJob,
        jobTitle: 'Senior Flutter Developer',
        company: 'Nova Health',
      );
      await _repository.saveMatch(userId, match);

      final letter = CoverLetter(
        id: _uuid.v4(),
        title: 'Senior Flutter Developer',
        company: 'Nova Health',
        style: 'Professional',
        content: await _ai.generateCoverLetter(
          name: user!.name,
          targetRole: 'Senior Flutter Developer',
          company: 'Nova Health',
          jobDescription: sampleJob,
          resumeSkills: resume.skills,
          style: 'Professional',
          experienceLevel: user!.experienceLevel,
          email: resume.email,
          phone: resume.phone,
        ),
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      await _repository.saveCoverLetter(userId, letter);

      if (!mounted) return;
      state = ResumeState(
        resumes: _repository.loadResumes(userId),
        analyses: _repository.loadAnalyses(userId),
        coverLetters: _repository.loadCoverLetters(userId),
        matches: _repository.loadMatches(userId),
      );
    } catch (_) {
      // Demo seeding is best-effort; the user can still create content manually.
    } finally {
      _seeding = false;
    }
  }

  Future<void> saveResume(Resume resume) async {
    if (userId.isEmpty) return;
    await _repository.saveResume(userId, resume);
    final items = _repository.loadResumes(userId);
    state = state.copyWith(resumes: items, clearError: true);
  }

  Future<void> deleteResume(String id) async {
    await _repository.deleteResume(userId, id);
    state = state.copyWith(resumes: _repository.loadResumes(userId));
  }

  Future<ResumeAnalysis> analyze({
    required String text,
    required String targetRole,
    required String resumeName,
  }) async {
    final analysis = await _ai.analyzeResume(
      text: text,
      targetRole: targetRole,
      resumeName: resumeName,
    );
    await _repository.saveAnalysis(userId, analysis);
    state = state.copyWith(analyses: _repository.loadAnalyses(userId));
    return analysis;
  }

  Future<void> deleteAnalysis(String id) async {
    await _repository.deleteAnalysis(userId, id);
    state = state.copyWith(analyses: _repository.loadAnalyses(userId));
  }

  Future<JobMatchResult> match({
    required String resumeText,
    required String jobDescription,
    required String jobTitle,
    required String company,
  }) async {
    final result = await _ai.matchJob(
      resumeText: resumeText,
      jobDescription: jobDescription,
      jobTitle: jobTitle,
      company: company,
    );
    await _repository.saveMatch(userId, result);
    state = state.copyWith(matches: _repository.loadMatches(userId));
    return result;
  }

  Future<void> deleteMatch(String id) async {
    await _repository.deleteMatch(userId, id);
    state = state.copyWith(matches: _repository.loadMatches(userId));
  }

  Future<void> saveCoverLetter(CoverLetter letter) async {
    await _repository.saveCoverLetter(userId, letter);
    state = state.copyWith(coverLetters: _repository.loadCoverLetters(userId));
  }

  Future<void> deleteCoverLetter(String id) async {
    await _repository.deleteCoverLetter(userId, id);
    state = state.copyWith(coverLetters: _repository.loadCoverLetters(userId));
  }

  ResumeAnalysis? analysisById(String id) {
    for (final analysis in state.analyses) {
      if (analysis.id == id) return analysis;
    }
    return null;
  }

  Resume? resumeById(String id) {
    for (final resume in state.resumes) {
      if (resume.id == id) return resume;
    }
    return null;
  }

  CoverLetter? coverLetterById(String id) {
    for (final letter in state.coverLetters) {
      if (letter.id == id) return letter;
    }
    return null;
  }
}

final resumeControllerProvider =
    StateNotifierProvider<ResumeController, ResumeState>((ref) {
      final userId =
          ref.watch(authControllerProvider.select((s) => s.user?.id)) ?? '';
      final user = ref.watch(authControllerProvider.select((s) => s.user));
      final controller = ResumeController(
        repository: ref.watch(resumeRepositoryProvider),
        ai: ref.watch(aiServiceProvider),
        userId: userId,
        user: user,
      );
      if (userId.isNotEmpty) {
        controller.load();
      }
      return controller;
    });
