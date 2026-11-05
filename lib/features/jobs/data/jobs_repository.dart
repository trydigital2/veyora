import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/storage/local_store.dart';
import '../domain/job.dart';

class JobsException implements Exception {
  JobsException(this.message);
  final String message;

  @override
  String toString() => message;
}

class JobsRepository {
  JobsRepository(this._store, {http.Client? client})
    : _client = client ?? http.Client();

  final LocalStore _store;
  final http.Client _client;

  static const _categoryMap = {
    'All': '',
    'Software Development': 'software-dev',
    'Design': 'design',
    'Marketing': 'marketing',
    'Sales': 'sales',
    'Product': 'product',
    'Data': 'data',
    'Customer Support': 'customer-support',
    'Finance': 'finance',
  };

  Future<List<Job>> fetchJobs({
    String query = '',
    String category = 'All',
  }) async {
    final params = <String, String>{'limit': '50'};
    if (query.trim().isNotEmpty) params['search'] = query.trim();
    final slug = _categoryMap[category] ?? '';
    if (slug.isNotEmpty) params['category'] = slug;
    final uri = Uri.parse(
      AppConfig.jobsEndpoint,
    ).replace(queryParameters: params);

    try {
      final response = await _client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw JobsException(
          'The job feed is unavailable right now (${response.statusCode}). Please try again.',
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['jobs'] is! List) {
        throw JobsException(
          'We could not read the job feed. Please try again.',
        );
      }
      final jobs = (decoded['jobs'] as List)
          .whereType<Map>()
          .map((e) => Job.fromRemotive(Map<String, dynamic>.from(e)))
          .where((job) => job.title.isNotEmpty && job.url.isNotEmpty)
          .toList();
      jobs.sort((a, b) {
        final aDate = a.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return _filter(jobs, query);
    } on JobsException {
      rethrow;
    } catch (_) {
      throw JobsException(
        'Could not reach the job feed. Check your connection and try again.',
      );
    }
  }

  List<Job> _filter(List<Job> jobs, String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return jobs;
    return jobs.where((job) {
      final haystack =
          '${job.title} ${job.company} ${job.location} ${job.tags.join(' ')}'
              .toLowerCase();
      return haystack.contains(needle);
    }).toList();
  }

  List<Job> loadSaved(String userId) {
    if (userId.isEmpty) return const [];
    return _store
        .getJsonList('${LocalStore.savedJobsKeyPrefix}$userId')
        .map(Job.fromJson)
        .toList();
  }

  Future<void> saveFavorite(String userId, Job job) async {
    if (userId.isEmpty) return;
    final items = loadSaved(userId);
    if (items.any((j) => j.id == job.id)) return;
    items.insert(0, job);
    await _store.setJsonList(
      '${LocalStore.savedJobsKeyPrefix}$userId',
      items.map((e) => e.toJson()).toList(),
    );
  }

  Future<void> removeFavorite(String userId, String jobId) async {
    if (userId.isEmpty) return;
    final items = loadSaved(userId)..removeWhere((j) => j.id == jobId);
    await _store.setJsonList(
      '${LocalStore.savedJobsKeyPrefix}$userId',
      items.map((e) => e.toJson()).toList(),
    );
  }
}
