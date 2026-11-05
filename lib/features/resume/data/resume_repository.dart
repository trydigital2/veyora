import '../../../core/storage/local_store.dart';
import '../domain/resume_models.dart';

class ResumeRepository {
  ResumeRepository(this._store);

  final LocalStore _store;

  List<Resume> loadResumes(String userId) {
    final items = _store
        .getJsonList('${LocalStore.resumeKeyPrefix}$userId')
        .map(Resume.fromJson)
        .toList();
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  Future<void> saveResume(String userId, Resume resume) async {
    final items = loadResumes(userId);
    final index = items.indexWhere((r) => r.id == resume.id);
    if (index >= 0) {
      items[index] = resume;
    } else {
      items.insert(0, resume);
    }
    await _store.setJsonList(
      '${LocalStore.resumeKeyPrefix}$userId',
      items.map((e) => e.toJson()).toList(),
    );
  }

  Future<void> deleteResume(String userId, String resumeId) async {
    final items = loadResumes(userId)..removeWhere((r) => r.id == resumeId);
    await _store.setJsonList(
      '${LocalStore.resumeKeyPrefix}$userId',
      items.map((e) => e.toJson()).toList(),
    );
  }

  List<ResumeAnalysis> loadAnalyses(String userId) {
    final items = _store
        .getJsonList('${LocalStore.analysisKeyPrefix}$userId')
        .map(ResumeAnalysis.fromJson)
        .toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<void> saveAnalysis(String userId, ResumeAnalysis analysis) async {
    final items = loadAnalyses(userId);
    items.insert(0, analysis);
    final trimmed = items.take(40).toList();
    await _store.setJsonList(
      '${LocalStore.analysisKeyPrefix}$userId',
      trimmed.map((e) => e.toJson()).toList(),
    );
  }

  Future<void> deleteAnalysis(String userId, String id) async {
    final items = loadAnalyses(userId)..removeWhere((a) => a.id == id);
    await _store.setJsonList(
      '${LocalStore.analysisKeyPrefix}$userId',
      items.map((e) => e.toJson()).toList(),
    );
  }

  List<CoverLetter> loadCoverLetters(String userId) {
    final items = _store
        .getJsonList('${LocalStore.coverLetterKeyPrefix}$userId')
        .map(CoverLetter.fromJson)
        .toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<void> saveCoverLetter(String userId, CoverLetter letter) async {
    final items = loadCoverLetters(userId);
    final index = items.indexWhere((l) => l.id == letter.id);
    if (index >= 0) {
      items[index] = letter;
    } else {
      items.insert(0, letter);
    }
    await _store.setJsonList(
      '${LocalStore.coverLetterKeyPrefix}$userId',
      items.map((e) => e.toJson()).toList(),
    );
  }

  Future<void> deleteCoverLetter(String userId, String id) async {
    final items = loadCoverLetters(userId)..removeWhere((l) => l.id == id);
    await _store.setJsonList(
      '${LocalStore.coverLetterKeyPrefix}$userId',
      items.map((e) => e.toJson()).toList(),
    );
  }

  List<JobMatchResult> loadMatches(String userId) {
    final items = _store
        .getJsonList('${LocalStore.matchKeyPrefix}$userId')
        .map(JobMatchResult.fromJson)
        .toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<void> saveMatch(String userId, JobMatchResult match) async {
    final items = loadMatches(userId)..insert(0, match);
    await _store.setJsonList(
      '${LocalStore.matchKeyPrefix}$userId',
      items.take(30).map((e) => e.toJson()).toList(),
    );
  }

  Future<void> deleteMatch(String userId, String id) async {
    final items = loadMatches(userId)..removeWhere((m) => m.id == id);
    await _store.setJsonList(
      '${LocalStore.matchKeyPrefix}$userId',
      items.map((e) => e.toJson()).toList(),
    );
  }
}
