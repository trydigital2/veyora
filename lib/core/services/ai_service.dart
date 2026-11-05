import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../features/interview/domain/interview_models.dart';
import '../../features/resume/domain/resume_models.dart';
import '../config/app_config.dart';
import 'local_ai_engine.dart';

class AiService {
  AiService({http.Client? client, LocalAiEngine? local})
    : _client = client ?? http.Client(),
      _local = local ?? const LocalAiEngine();

  final http.Client _client;
  final LocalAiEngine _local;
  static const _uuid = Uuid();
  static const _timeout = Duration(seconds: 45);

  Future<ResumeAnalysis> analyzeResume({
    required String text,
    required String targetRole,
    String resumeName = 'Resume',
  }) async {
    final remote = await _call('resume_analysis', {
      'resumeText': text,
      'targetRole': targetRole,
      'resumeName': resumeName,
    });
    if (remote != null) {
      return ResumeAnalysis.fromJson({
        'id': _uuid.v4(),
        'resumeName': resumeName,
        'targetRole': targetRole,
        'createdAt': DateTime.now().toIso8601String(),
        ...remote,
      });
    }
    return _local.analyzeResume(
      text: text,
      targetRole: targetRole,
      resumeName: resumeName,
    );
  }

  Future<JobMatchResult> matchJob({
    required String resumeText,
    required String jobDescription,
    String jobTitle = 'Target role',
    String company = 'Company',
  }) async {
    final remote = await _call('job_match', {
      'resumeText': resumeText,
      'jobDescription': jobDescription,
      'jobTitle': jobTitle,
      'company': company,
    });
    if (remote != null) {
      return JobMatchResult.fromJson({
        'id': _uuid.v4(),
        'jobTitle': jobTitle,
        'company': company,
        'createdAt': DateTime.now().toIso8601String(),
        ...remote,
      });
    }
    return _local.matchJob(
      resumeText: resumeText,
      jobDescription: jobDescription,
      jobTitle: jobTitle,
      company: company,
    );
  }

  Future<String> generateSummary({
    required String name,
    required String role,
    required List<String> skills,
    String experienceLevel = 'Professional',
  }) async {
    final remote = await _call('summary', {
      'name': name,
      'role': role,
      'skills': skills,
      'experienceLevel': experienceLevel,
    });
    final content = remote?['content'];
    if (content is String && content.trim().isNotEmpty) return content.trim();
    return _local.generateSummary(
      name: name,
      role: role,
      skills: skills,
      experienceLevel: experienceLevel,
    );
  }

  Future<String> generateExperienceDescription({
    required String role,
    required String company,
    required List<String> skills,
  }) async {
    final remote = await _call('experience', {
      'role': role,
      'company': company,
      'skills': skills,
    });
    final content = remote?['content'];
    if (content is String && content.trim().isNotEmpty) return content.trim();
    return _local.generateExperienceDescription(
      role: role,
      company: company,
      skills: skills,
    );
  }

  Future<String> generateCoverLetter({
    required String name,
    required String targetRole,
    required String company,
    required String jobDescription,
    required List<String> resumeSkills,
    required String style,
    String experienceLevel = 'Professional',
    String email = '',
    String phone = '',
  }) async {
    final remote = await _call('cover_letter', {
      'name': name,
      'targetRole': targetRole,
      'company': company,
      'jobDescription': jobDescription,
      'resumeSkills': resumeSkills,
      'style': style,
      'experienceLevel': experienceLevel,
      'email': email,
      'phone': phone,
    });
    final content = remote?['content'];
    if (content is String && content.trim().isNotEmpty) return content.trim();
    return _local.generateCoverLetter(
      name: name,
      targetRole: targetRole,
      company: company,
      jobDescription: jobDescription,
      resumeSkills: resumeSkills,
      style: style,
      experienceLevel: experienceLevel,
      email: email,
      phone: phone,
    );
  }

  Future<List<InterviewQuestion>> generateInterviewQuestions({
    required String role,
    required String category,
    required String level,
    int count = 6,
  }) async {
    final remote = await _call('interview_questions', {
      'role': role,
      'category': category,
      'level': level,
      'count': count,
    });
    final questions = remote?['questions'];
    if (questions is List && questions.isNotEmpty) {
      final parsed = questions
          .whereType<Map>()
          .map((e) => InterviewQuestion.fromJson(Map<String, dynamic>.from(e)))
          .where((q) => q.text.trim().isNotEmpty)
          .toList();
      if (parsed.isNotEmpty) return parsed;
    }
    return _local.generateInterviewQuestions(
      role: role,
      category: category,
      level: level,
      count: count,
    );
  }

  Future<AnswerFeedback> evaluateInterviewAnswer({
    required InterviewQuestion question,
    required String answer,
    required String role,
  }) async {
    final remote = await _call('interview_feedback', {
      'question': question.toJson(),
      'answer': answer,
      'role': role,
    });
    if (remote != null) {
      return AnswerFeedback.fromJson(remote);
    }
    return _local.evaluateInterviewAnswer(
      question: question,
      answer: answer,
      role: role,
    );
  }

  Future<Map<String, dynamic>?> _call(
    String task,
    Map<String, dynamic> payload,
  ) async {
    if (!AppConfig.hasSecureAiBackend) return null;
    try {
      final response = await _client
          .post(
            Uri.parse('${AppConfig.aiProxyUrl}/api/ai'),
            headers: {
              'Content-Type': 'application/json',
              if (AppConfig.aiProxyToken.isNotEmpty)
                'Authorization': 'Bearer ${AppConfig.aiProxyToken}',
            },
            body: jsonEncode({'task': task, 'payload': payload}),
          )
          .timeout(_timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return null;
      final result = decoded['result'];
      if (result is Map) return Map<String, dynamic>.from(result);
      if (result is String) return {'content': result};
      return null;
    } catch (_) {
      return null;
    }
  }
}
