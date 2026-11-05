class Job {
  const Job({
    required this.id,
    required this.title,
    required this.company,
    required this.companyLogo,
    required this.location,
    required this.category,
    required this.jobType,
    required this.description,
    required this.url,
    required this.salary,
    required this.publishedAt,
    this.tags = const [],
    this.source = 'Remotive',
  });

  final String id;
  final String title;
  final String company;
  final String companyLogo;
  final String location;
  final String category;
  final String jobType;
  final String description;
  final String url;
  final String salary;
  final DateTime? publishedAt;
  final List<String> tags;
  final String source;

  String get companyInitial {
    final trimmed = company.trim();
    if (trimmed.isEmpty) return 'V';
    return trimmed.substring(0, 1).toUpperCase();
  }

  String get categoryLabel {
    if (category.isEmpty) return 'General';
    return category
        .split('-')
        .map((e) => e.isEmpty ? e : '${e[0].toUpperCase()}${e.substring(1)}')
        .join(' ');
  }

  String get locationLabel => location.isEmpty ? 'Remote' : location;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'company': company,
    'companyLogo': companyLogo,
    'location': location,
    'category': category,
    'jobType': jobType,
    'description': description,
    'url': url,
    'salary': salary,
    'publishedAt': publishedAt?.toIso8601String(),
    'tags': tags,
    'source': source,
  };

  factory Job.fromJson(Map<String, dynamic> json) => Job(
    id: json['id']?.toString() ?? '',
    title: json['title'] as String? ?? 'Untitled role',
    company: json['company'] as String? ?? 'Company',
    companyLogo: json['companyLogo'] as String? ?? '',
    location: json['location'] as String? ?? '',
    category: json['category'] as String? ?? '',
    jobType: json['jobType'] as String? ?? 'Full-time',
    description: json['description'] as String? ?? '',
    url: json['url'] as String? ?? '',
    salary: json['salary'] as String? ?? '',
    publishedAt: DateTime.tryParse(json['publishedAt'] as String? ?? ''),
    tags: (json['tags'] as List?)?.whereType<String>().toList() ?? const [],
    source: json['source'] as String? ?? 'Remotive',
  );

  factory Job.fromRemotive(Map<String, dynamic> json) {
    final rawDescription = json['description'] as String? ?? '';
    return Job(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? 'Untitled role',
      company: json['company_name'] as String? ?? 'Company',
      companyLogo: json['company_logo'] as String? ?? '',
      location: json['candidate_required_location'] as String? ?? 'Remote',
      category: json['category'] as String? ?? '',
      jobType: json['job_type'] as String? ?? 'Full-time',
      description: rawDescription,
      url: json['url'] as String? ?? '',
      salary: json['salary'] as String? ?? '',
      publishedAt: DateTime.tryParse(json['publication_date'] as String? ?? ''),
      tags: (json['tags'] as List?)?.whereType<String>().toList() ?? const [],
      source: 'Remotive',
    );
  }
}

String stripHtml(String html) {
  var text = html
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
      .replaceAll(RegExp(r'</li>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '• ')
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
  return text;
}
