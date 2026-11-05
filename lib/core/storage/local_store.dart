import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalStore {
  LocalStore(this._prefs);

  final SharedPreferences _prefs;

  static const onboardingKey = 'veyora.onboarding.seen';
  static const settingsKey = 'veyora.settings';
  static const sessionKey = 'veyora.session.user';
  static const accountsKey = 'veyora.accounts';
  static const resumeKeyPrefix = 'veyora.resumes.';
  static const analysisKeyPrefix = 'veyora.analyses.';
  static const coverLetterKeyPrefix = 'veyora.coverletters.';
  static const matchKeyPrefix = 'veyora.matches.';
  static const interviewKeyPrefix = 'veyora.interviews.';
  static const savedJobsKeyPrefix = 'veyora.savedjobs.';

  bool getBool(String key, {bool fallback = false}) =>
      _prefs.getBool(key) ?? fallback;

  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  String? getString(String key) => _prefs.getString(key);

  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  Future<void> remove(String key) => _prefs.remove(key);

  Map<String, dynamic>? getJson(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> setJson(String key, Map<String, dynamic> value) =>
      _prefs.setString(key, jsonEncode(value));

  List<Map<String, dynamic>> getJsonList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  Future<void> setJsonList(String key, List<Map<String, dynamic>> value) =>
      _prefs.setString(key, jsonEncode(value));

  Future<void> clearUserData(String userId) async {
    for (final prefix in [
      resumeKeyPrefix,
      analysisKeyPrefix,
      coverLetterKeyPrefix,
      matchKeyPrefix,
      interviewKeyPrefix,
      savedJobsKeyPrefix,
    ]) {
      await _prefs.remove('$prefix$userId');
    }
  }
}
