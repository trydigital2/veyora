import '../../auth/domain/app_user.dart';

class Resume {
  const Resume({
    required this.id,
    required this.title,
    required this.fullName,
    this.targetRole = '',
    this.email = '',
    this.phone = '',
    this.location = '',
    this.linkedin = '',
    this.summary = '',
    this.template = 'Modern',
    this.skills = const [],
    this.education = const [],
    this.experience = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String fullName;
  final String targetRole;
  final String email;
  final String phone;
  final String location;
  final String linkedin;
  final String summary;
  final String template;
  final List<String> skills;
  final List<EducationEntry> education;
  final List<ExperienceEntry> experience;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get plainText {
    final buffer = StringBuffer()
      ..writeln(fullName)
      ..writeln(targetRole)
      ..writeln('$email | $phone | $location | $linkedin')
      ..writeln()
      ..writeln('SUMMARY')
      ..writeln(summary)
      ..writeln()
      ..writeln('SKILLS')
      ..writeln(skills.join(', '))
      ..writeln()
      ..writeln('EXPERIENCE');
    for (final exp in experience) {
      buffer
        ..writeln('${exp.role} at ${exp.company} (${exp.dateRange})')
        ..writeln(exp.description)
        ..writeln();
    }
    buffer.writeln('EDUCATION');
    for (final edu in education) {
      buffer.writeln(
        '${edu.degree} in ${edu.field}, ${edu.school} (${edu.dateRange})',
      );
    }
    return buffer.toString();
  }

  Resume copyWith({
    String? title,
    String? fullName,
    String? targetRole,
    String? email,
    String? phone,
    String? location,
    String? linkedin,
    String? summary,
    String? template,
    List<String>? skills,
    List<EducationEntry>? education,
    List<ExperienceEntry>? experience,
    DateTime? updatedAt,
  }) {
    return Resume(
      id: id,
      title: title ?? this.title,
      fullName: fullName ?? this.fullName,
      targetRole: targetRole ?? this.targetRole,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      linkedin: linkedin ?? this.linkedin,
      summary: summary ?? this.summary,
      template: template ?? this.template,
      skills: skills ?? this.skills,
      education: education ?? this.education,
      experience: experience ?? this.experience,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'fullName': fullName,
    'targetRole': targetRole,
    'email': email,
    'phone': phone,
    'location': location,
    'linkedin': linkedin,
    'summary': summary,
    'template': template,
    'skills': skills,
    'education': education.map((e) => e.toJson()).toList(),
    'experience': experience.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Resume.fromJson(Map<String, dynamic> json) => Resume(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? 'My Resume',
    fullName: json['fullName'] as String? ?? '',
    targetRole: json['targetRole'] as String? ?? '',
    email: json['email'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    location: json['location'] as String? ?? '',
    linkedin: json['linkedin'] as String? ?? '',
    summary: json['summary'] as String? ?? '',
    template: json['template'] as String? ?? 'Modern',
    skills: (json['skills'] as List?)?.whereType<String>().toList() ?? const [],
    education:
        (json['education'] as List?)
            ?.whereType<Map>()
            .map((e) => EducationEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        const [],
    experience:
        (json['experience'] as List?)
            ?.whereType<Map>()
            .map((e) => ExperienceEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        const [],
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    updatedAt:
        DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
  );
}

class ResumeAnalysis {
  const ResumeAnalysis({
    required this.id,
    required this.resumeName,
    required this.targetRole,
    required this.overallScore,
    required this.atsScore,
    required this.skillsScore,
    required this.experienceScore,
    required this.educationScore,
    required this.formattingScore,
    required this.strengths,
    required this.weaknesses,
    required this.missingSkills,
    required this.suggestions,
    required this.detectedSkills,
    required this.wordCount,
    required this.createdAt,
  });

  final String id;
  final String resumeName;
  final String targetRole;
  final int overallScore;
  final int atsScore;
  final int skillsScore;
  final int experienceScore;
  final int educationScore;
  final int formattingScore;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> missingSkills;
  final List<String> suggestions;
  final List<String> detectedSkills;
  final int wordCount;
  final DateTime createdAt;

  String get grade {
    if (overallScore >= 85) return 'Outstanding';
    if (overallScore >= 70) return 'Strong';
    if (overallScore >= 55) return 'Developing';
    return 'Needs work';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'resumeName': resumeName,
    'targetRole': targetRole,
    'overallScore': overallScore,
    'atsScore': atsScore,
    'skillsScore': skillsScore,
    'experienceScore': experienceScore,
    'educationScore': educationScore,
    'formattingScore': formattingScore,
    'strengths': strengths,
    'weaknesses': weaknesses,
    'missingSkills': missingSkills,
    'suggestions': suggestions,
    'detectedSkills': detectedSkills,
    'wordCount': wordCount,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ResumeAnalysis.fromJson(Map<String, dynamic> json) => ResumeAnalysis(
    id: json['id'] as String? ?? '',
    resumeName: json['resumeName'] as String? ?? 'Resume',
    targetRole: json['targetRole'] as String? ?? '',
    overallScore: (json['overallScore'] as num?)?.round() ?? 0,
    atsScore: (json['atsScore'] as num?)?.round() ?? 0,
    skillsScore: (json['skillsScore'] as num?)?.round() ?? 0,
    experienceScore: (json['experienceScore'] as num?)?.round() ?? 0,
    educationScore: (json['educationScore'] as num?)?.round() ?? 0,
    formattingScore: (json['formattingScore'] as num?)?.round() ?? 0,
    strengths:
        (json['strengths'] as List?)?.whereType<String>().toList() ?? const [],
    weaknesses:
        (json['weaknesses'] as List?)?.whereType<String>().toList() ?? const [],
    missingSkills:
        (json['missingSkills'] as List?)?.whereType<String>().toList() ??
        const [],
    suggestions:
        (json['suggestions'] as List?)?.whereType<String>().toList() ??
        const [],
    detectedSkills:
        (json['detectedSkills'] as List?)?.whereType<String>().toList() ??
        const [],
    wordCount: (json['wordCount'] as num?)?.round() ?? 0,
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
  );
}

class JobMatchResult {
  const JobMatchResult({
    required this.id,
    required this.jobTitle,
    required this.company,
    required this.score,
    required this.matchedSkills,
    required this.missingSkills,
    required this.suggestions,
    required this.summary,
    required this.createdAt,
  });

  final String id;
  final String jobTitle;
  final String company;
  final int score;
  final List<String> matchedSkills;
  final List<String> missingSkills;
  final List<String> suggestions;
  final String summary;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'jobTitle': jobTitle,
    'company': company,
    'score': score,
    'matchedSkills': matchedSkills,
    'missingSkills': missingSkills,
    'suggestions': suggestions,
    'summary': summary,
    'createdAt': createdAt.toIso8601String(),
  };

  factory JobMatchResult.fromJson(Map<String, dynamic> json) => JobMatchResult(
    id: json['id'] as String? ?? '',
    jobTitle: json['jobTitle'] as String? ?? 'Role',
    company: json['company'] as String? ?? 'Company',
    score: (json['score'] as num?)?.round() ?? 0,
    matchedSkills:
        (json['matchedSkills'] as List?)?.whereType<String>().toList() ??
        const [],
    missingSkills:
        (json['missingSkills'] as List?)?.whereType<String>().toList() ??
        const [],
    suggestions:
        (json['suggestions'] as List?)?.whereType<String>().toList() ??
        const [],
    summary: json['summary'] as String? ?? '',
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
  );
}

class CoverLetter {
  const CoverLetter({
    required this.id,
    required this.title,
    required this.company,
    required this.style,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String company;
  final String style;
  final String content;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'company': company,
    'style': style,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
  };

  factory CoverLetter.fromJson(Map<String, dynamic> json) => CoverLetter(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? 'Cover Letter',
    company: json['company'] as String? ?? '',
    style: json['style'] as String? ?? 'Professional',
    content: json['content'] as String? ?? '',
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
  );
}

class JobDraft {
  const JobDraft({
    required this.title,
    required this.company,
    required this.description,
  });

  final String title;
  final String company;
  final String description;
}
