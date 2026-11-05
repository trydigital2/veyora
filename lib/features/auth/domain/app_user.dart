class EducationEntry {
  const EducationEntry({
    required this.id,
    required this.school,
    required this.degree,
    required this.field,
    this.startYear = '',
    this.endYear = '',
    this.grade = '',
  });

  final String id;
  final String school;
  final String degree;
  final String field;
  final String startYear;
  final String endYear;
  final String grade;

  String get dateRange {
    if (startYear.isEmpty && endYear.isEmpty) return '';
    if (startYear.isEmpty) return endYear;
    if (endYear.isEmpty) return startYear;
    return '$startYear – $endYear';
  }

  EducationEntry copyWith({
    String? school,
    String? degree,
    String? field,
    String? startYear,
    String? endYear,
    String? grade,
  }) {
    return EducationEntry(
      id: id,
      school: school ?? this.school,
      degree: degree ?? this.degree,
      field: field ?? this.field,
      startYear: startYear ?? this.startYear,
      endYear: endYear ?? this.endYear,
      grade: grade ?? this.grade,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'school': school,
    'degree': degree,
    'field': field,
    'startYear': startYear,
    'endYear': endYear,
    'grade': grade,
  };

  factory EducationEntry.fromJson(Map<String, dynamic> json) => EducationEntry(
    id: json['id'] as String? ?? '',
    school: json['school'] as String? ?? '',
    degree: json['degree'] as String? ?? '',
    field: json['field'] as String? ?? '',
    startYear: json['startYear'] as String? ?? '',
    endYear: json['endYear'] as String? ?? '',
    grade: json['grade'] as String? ?? '',
  );
}

class ExperienceEntry {
  const ExperienceEntry({
    required this.id,
    required this.company,
    required this.role,
    required this.startDate,
    this.endDate = '',
    this.current = false,
    this.description = '',
  });

  final String id;
  final String company;
  final String role;
  final String startDate;
  final String endDate;
  final bool current;
  final String description;

  String get dateRange {
    final end = current ? 'Present' : endDate;
    if (startDate.isEmpty && end.isEmpty) return '';
    if (startDate.isEmpty) return end;
    if (end.isEmpty) return startDate;
    return '$startDate – $end';
  }

  ExperienceEntry copyWith({
    String? company,
    String? role,
    String? startDate,
    String? endDate,
    bool? current,
    String? description,
  }) {
    return ExperienceEntry(
      id: id,
      company: company ?? this.company,
      role: role ?? this.role,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      current: current ?? this.current,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'company': company,
    'role': role,
    'startDate': startDate,
    'endDate': endDate,
    'current': current,
    'description': description,
  };

  factory ExperienceEntry.fromJson(Map<String, dynamic> json) =>
      ExperienceEntry(
        id: json['id'] as String? ?? '',
        company: json['company'] as String? ?? '',
        role: json['role'] as String? ?? '',
        startDate: json['startDate'] as String? ?? '',
        endDate: json['endDate'] as String? ?? '',
        current: json['current'] as bool? ?? false,
        description: json['description'] as String? ?? '',
      );
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.headline = '',
    this.bio = '',
    this.location = '',
    this.phone = '',
    this.targetRole = '',
    this.skills = const [],
    this.education = const [],
    this.experience = const [],
    this.profileCompleted = false,
    this.plan = 'Free',
    this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String headline;
  final String bio;
  final String location;
  final String phone;
  final String targetRole;
  final List<String> skills;
  final List<EducationEntry> education;
  final List<ExperienceEntry> experience;
  final bool profileCompleted;
  final String plan;
  final DateTime? createdAt;

  String get firstName {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'there';
    return trimmed.split(' ').first;
  }

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'V';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  int get profileCompletion {
    var filled = 0;
    const total = 8;
    if (name.trim().isNotEmpty) filled++;
    if (email.trim().isNotEmpty) filled++;
    if (headline.trim().isNotEmpty) filled++;
    if (bio.trim().isNotEmpty) filled++;
    if (location.trim().isNotEmpty) filled++;
    if (skills.isNotEmpty) filled++;
    if (education.isNotEmpty) filled++;
    if (experience.isNotEmpty) filled++;
    return ((filled / total) * 100).round();
  }

  String get experienceLevel {
    final years = _yearsOfExperience;
    if (years >= 8) return 'Senior';
    if (years >= 3) return 'Mid-level';
    if (years >= 1) return 'Early career';
    return 'Entry level';
  }

  int get _yearsOfExperience {
    var years = 0;
    for (final exp in experience) {
      final start = int.tryParse(
        RegExp(r'\d{4}').firstMatch(exp.startDate)?.group(0) ?? '',
      );
      if (start == null) continue;
      final end = exp.current
          ? DateTime.now().year
          : int.tryParse(
                  RegExp(r'\d{4}').firstMatch(exp.endDate)?.group(0) ?? '',
                ) ??
                start;
      years += (end - start).clamp(0, 60);
    }
    return years;
  }

  AppUser copyWith({
    String? name,
    String? email,
    String? headline,
    String? bio,
    String? location,
    String? phone,
    String? targetRole,
    List<String>? skills,
    List<EducationEntry>? education,
    List<ExperienceEntry>? experience,
    bool? profileCompleted,
    String? plan,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      headline: headline ?? this.headline,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      phone: phone ?? this.phone,
      targetRole: targetRole ?? this.targetRole,
      skills: skills ?? this.skills,
      education: education ?? this.education,
      experience: experience ?? this.experience,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      plan: plan ?? this.plan,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'headline': headline,
    'bio': bio,
    'location': location,
    'phone': phone,
    'targetRole': targetRole,
    'skills': skills,
    'education': education.map((e) => e.toJson()).toList(),
    'experience': experience.map((e) => e.toJson()).toList(),
    'profileCompleted': profileCompleted,
    'plan': plan,
    'createdAt': createdAt?.toIso8601String(),
  };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    headline: json['headline'] as String? ?? '',
    bio: json['bio'] as String? ?? '',
    location: json['location'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    targetRole: json['targetRole'] as String? ?? '',
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
    profileCompleted: json['profileCompleted'] as bool? ?? false,
    plan: json['plan'] as String? ?? 'Free',
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
  );
}
