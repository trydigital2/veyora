import '../../../core/storage/local_store.dart';
import '../domain/interview_models.dart';

class InterviewRepository {
  InterviewRepository(this._store);

  final LocalStore _store;

  List<InterviewSession> loadSessions(String userId) {
    final items = _store
        .getJsonList('${LocalStore.interviewKeyPrefix}$userId')
        .map(InterviewSession.fromJson)
        .toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<void> saveSession(String userId, InterviewSession session) async {
    final items = loadSessions(userId);
    final index = items.indexWhere((s) => s.id == session.id);
    if (index >= 0) {
      items[index] = session;
    } else {
      items.insert(0, session);
    }
    await _store.setJsonList(
      '${LocalStore.interviewKeyPrefix}$userId',
      items.take(40).map((e) => e.toJson()).toList(),
    );
  }

  Future<void> deleteSession(String userId, String id) async {
    final items = loadSessions(userId)..removeWhere((s) => s.id == id);
    await _store.setJsonList(
      '${LocalStore.interviewKeyPrefix}$userId',
      items.map((e) => e.toJson()).toList(),
    );
  }
}
