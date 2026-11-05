import 'dart:math';

import 'package:uuid/uuid.dart';

import '../../features/interview/domain/interview_models.dart';
import '../../features/resume/domain/resume_models.dart';
import 'skill_dictionary.dart';

class AiException implements Exception {
  AiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class LocalAiEngine {
  const LocalAiEngine();

  static const _uuid = Uuid();

  static const _actionVerbs = [
    'led',
    'built',
    'designed',
    'launched',
    'improved',
    'increased',
    'reduced',
    'delivered',
    'managed',
    'created',
    'developed',
    'implemented',
    'optimized',
    'architected',
    'drove',
    'collaborated',
    'streamlined',
    'automated',
    'mentored',
    'scaled',
    'owned',
    'shipped',
    'spearheaded',
  ];

  static const _sectionWords = {
    'summary': ['summary', 'profile', 'objective', 'about me'],
    'experience': [
      'experience',
      'employment',
      'work history',
      'professional background',
    ],
    'education': ['education', 'academic', 'qualification'],
    'skills': ['skills', 'technologies', 'competencies', 'technical skills'],
    'projects': ['projects', 'portfolio'],
    'certifications': [
      'certification',
      'certificate',
      'licensed',
      'credential',
    ],
  };

  ResumeAnalysis analyzeResume({
    required String text,
    required String targetRole,
    String resumeName = 'Resume',
  }) {
    final clean = text.trim();
    if (clean.length < 80) {
      throw AiException(
        'The resume text is too short to analyze. Add more detail and try again.',
      );
    }

    final lower = clean.toLowerCase();
    final words = clean
        .split(RegExp(r'\s+'))
        .where((word) => RegExp(r'[A-Za-z0-9]').hasMatch(word))
        .toList();
    final detected = SkillDictionary.extractSkills(clean);
    final required = SkillDictionary.requiredForRole(targetRole);
    final matched = required.where(detected.contains).toList();
    final missing = required
        .where((skill) => !detected.contains(skill))
        .toList();

    final sections = <String, bool>{
      for (final entry in _sectionWords.entries)
        entry.key: entry.value.any(lower.contains),
    };

    final hasEmail = RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+').hasMatch(clean);
    final hasPhone = RegExp(r'(\+?\d[\d\s\-()]{7,})').hasMatch(clean);
    final hasLinkedIn = lower.contains('linkedin');
    final hasPortfolio =
        lower.contains('github') || lower.contains('portfolio');
    final hasMetrics = RegExp(r'\b\d+%|\$\d|\b\d{2,}\b').hasMatch(clean);
    final actionVerbCount = _actionVerbs
        .where((verb) => lower.contains(verb))
        .length;
    final bulletLines = clean
        .split('\n')
        .where((line) => RegExp(r'^\s*[-•*]').hasMatch(line))
        .length;
    final wordCount = words.length;
    final degrees = [
      'bachelor',
      'master',
      'b.tech',
      'b.e.',
      'mba',
      'phd',
      'degree',
      'b.sc',
      'm.sc',
    ];
    final hasDegree = degrees.any(lower.contains);
    final hasCertification = sections['certifications'] == true;
    final hasYears = RegExp(r'\b\d{1,2}\+?\s*(years|yrs)').hasMatch(lower);

    final skillsScore = _clamp(
      42 + detected.length * 4 + matched.length * 7 - missing.length * 2,
      18,
      99,
    );
    final experienceScore = _clamp(
      32 +
          (sections['experience'] == true ? 22 : 0) +
          (hasMetrics ? 16 : 0) +
          min(actionVerbCount * 3, 18) +
          (hasYears ? 8 : 0) +
          (sections['projects'] == true ? 6 : 0),
      16,
      99,
    );
    final educationScore = _clamp(
      40 +
          (sections['education'] == true ? 28 : 0) +
          (hasDegree ? 20 : 0) +
          (hasCertification ? 10 : 0),
      20,
      99,
    );
    final formattingScore = _clamp(
      44 +
          (hasEmail ? 12 : 0) +
          (hasPhone ? 8 : 0) +
          (hasLinkedIn ? 6 : 0) +
          (hasPortfolio ? 5 : 0) +
          (wordCount >= 250 && wordCount <= 900 ? 14 : -10) +
          (bulletLines >= 4 ? 9 : 0) +
          (clean.length - clean.replaceAll(RegExp(r'[A-Z]{6,}'), '').length < 80
              ? 4
              : 0),
      20,
      99,
    );
    final atsScore = _clamp(
      38 +
          (matched.length * 7) +
          (sections['skills'] == true ? 10 : 0) +
          (sections['experience'] == true ? 8 : 0) +
          (hasEmail ? 5 : 0) +
          (wordCount <= 1000 ? 8 : -8),
      20,
      99,
    );

    final overall = _clamp(
      (skillsScore * .28 +
              experienceScore * .26 +
              educationScore * .14 +
              formattingScore * .16 +
              atsScore * .16)
          .round(),
      15,
      99,
    );

    final strengths = <String>[];
    final weaknesses = <String>[];
    final suggestions = <String>[];

    if (matched.isNotEmpty) {
      strengths.add(
        'Strong alignment with ${_displayList(SkillDictionary.displayNames(matched.take(4)))} for $targetRole roles.',
      );
    }
    if (hasMetrics) {
      strengths.add(
        'Uses quantified results, which makes your impact easier for recruiters to trust.',
      );
    }
    if (bulletLines >= 4) {
      strengths.add(
        'Readable bullet structure helps hiring managers scan key achievements quickly.',
      );
    }
    if (hasEmail && hasPhone) {
      strengths.add(
        'Contact details are complete, so recruiters can reach you without friction.',
      );
    }
    if (actionVerbCount >= 4) {
      strengths.add(
        'Strong action verbs give your experience a confident, results-oriented tone.',
      );
    }
    if (detected.length >= 8) {
      strengths.add(
        'A broad technical vocabulary helps your resume pass keyword-based screening.',
      );
    }
    if (strengths.isEmpty) {
      strengths.add(
        'Your resume has a solid foundation that can be sharpened with more specific detail.',
      );
    }

    if (missing.isNotEmpty) {
      weaknesses.add(
        'Missing role-relevant keywords: ${_displayList(SkillDictionary.displayNames(missing.take(5)))}.',
      );
    }
    if (!hasMetrics) {
      weaknesses.add(
        'Achievements are not quantified. Add numbers for revenue, users, time saved, or scale.',
      );
    }
    if (sections['summary'] != true) {
      weaknesses.add(
        'No professional summary, so your positioning is not immediately clear.',
      );
    }
    if (bulletLines < 3) {
      weaknesses.add(
        'Dense paragraphs make the resume harder to skim. Use concise bullet points.',
      );
    }
    if (wordCount < 220) {
      weaknesses.add(
        'The resume is light on detail. Expand your most relevant experience.',
      );
    }
    if (wordCount > 1000) {
      weaknesses.add(
        'The resume is long. Tighten older or less relevant experience.',
      );
    }
    if (!hasLinkedIn && !hasPortfolio) {
      weaknesses.add(
        'Add a LinkedIn or portfolio link to strengthen credibility.',
      );
    }
    if (weaknesses.isEmpty) {
      weaknesses.add(
        'Minor polish opportunities remain in tailoring keywords to each application.',
      );
    }

    suggestions.add(
      'Tailor the summary and top skills to $targetRole, mirroring the language used in job descriptions.',
    );
    if (missing.isNotEmpty) {
      suggestions.add(
        'Add evidence for ${_displayList(SkillDictionary.displayNames(missing.take(3)))} through projects, coursework, or measurable outcomes.',
      );
    }
    if (!hasMetrics) {
      suggestions.add(
        'Rewrite two bullets using this structure: action + what you built + measurable result.',
      );
    }
    if (sections['summary'] != true) {
      suggestions.add(
        'Open with a 2–3 sentence summary that states your role, years of experience, and strongest skills.',
      );
    }
    suggestions.add(
      'Keep formatting simple: standard section headings, consistent dates, and no tables or graphics.',
    );
    if (suggestions.length < 4) {
      suggestions.add(
        'Ask a peer to review your resume for clarity and remove any outdated or duplicate content.',
      );
    }

    return ResumeAnalysis(
      id: _uuid.v4(),
      resumeName: resumeName,
      targetRole: targetRole,
      overallScore: overall,
      atsScore: atsScore,
      skillsScore: skillsScore,
      experienceScore: experienceScore,
      educationScore: educationScore,
      formattingScore: formattingScore,
      strengths: strengths.take(5).toList(),
      weaknesses: weaknesses.take(5).toList(),
      missingSkills: SkillDictionary.displayNames(missing.take(8)),
      suggestions: suggestions.take(5).toList(),
      detectedSkills: SkillDictionary.displayNames(detected.take(14)),
      wordCount: wordCount,
      createdAt: DateTime.now(),
    );
  }

  JobMatchResult matchJob({
    required String resumeText,
    required String jobDescription,
    String jobTitle = 'Target role',
    String company = 'Company',
  }) {
    if (resumeText.trim().length < 60) {
      throw AiException('Add more resume detail before running a match.');
    }
    if (jobDescription.trim().length < 60) {
      throw AiException(
        'Paste a fuller job description to get an accurate match.',
      );
    }

    final resumeSkills = SkillDictionary.extractSkills(resumeText);
    final jobSkills = SkillDictionary.extractSkills(jobDescription);
    final matched = jobSkills.where(resumeSkills.contains).toList();
    final missing = jobSkills
        .where((skill) => !resumeSkills.contains(skill))
        .toList();
    final jobWords = _keywords(jobDescription);
    final resumeWords = _keywords(resumeText);
    final overlap = jobWords.where(resumeWords.contains).length;
    final keywordCoverage = jobWords.isEmpty ? 0.0 : overlap / jobWords.length;
    final skillCoverage = jobSkills.isEmpty
        ? 0.6
        : matched.length / jobSkills.length;

    final score = _clamp(
      (skillCoverage * 58 +
              keywordCoverage * 27 +
              (matched.isNotEmpty ? 10 : 0) +
              5)
          .round(),
      12,
      98,
    );

    final suggestions = <String>[];
    if (missing.isNotEmpty) {
      suggestions.add(
        'Add concrete evidence of ${_displayList(SkillDictionary.displayNames(missing.take(4)))} to your resume.',
      );
    }
    suggestions.add(
      'Mirror the job description’s exact terminology in your skills and experience bullets.',
    );
    suggestions.add(
      'Move the most relevant achievements into the top third of your resume.',
    );
    if (score < 70) {
      suggestions.add(
        'Build a small project or certification that demonstrates the missing requirements.',
      );
    }
    suggestions.add(
      'Use a tailored summary that names the role and highlights your closest matching outcomes.',
    );

    final summary = score >= 80
        ? 'Excellent fit. Your background covers most of the core requirements for this role.'
        : score >= 60
        ? 'Promising fit. You meet the fundamentals, but a few targeted additions will make you a stronger candidate.'
        : 'Stretch fit. Tailor your resume and close the most important skill gaps before applying.';

    return JobMatchResult(
      id: _uuid.v4(),
      jobTitle: jobTitle.trim().isEmpty ? 'Target role' : jobTitle.trim(),
      company: company.trim().isEmpty ? 'Company' : company.trim(),
      score: score,
      matchedSkills: SkillDictionary.displayNames(matched.take(12)),
      missingSkills: SkillDictionary.displayNames(missing.take(8)),
      suggestions: suggestions,
      summary: summary,
      createdAt: DateTime.now(),
    );
  }

  String generateSummary({
    required String name,
    required String role,
    required List<String> skills,
    String experienceLevel = 'Professional',
  }) {
    final displaySkills = SkillDictionary.displayNames(skills.take(4));
    final skillText = displaySkills.isEmpty
        ? 'a track record of delivering high-quality work'
        : 'expertise in ${_displayList(displaySkills)}';
    final target = role.trim().isEmpty ? 'a high-impact team' : 'a $role role';
    final first = name.trim().isEmpty
        ? 'A results-driven professional'
        : name.trim().split(' ').first;
    return '$first is a $experienceLevel professional with $skillText. '
        'Known for turning ambiguous problems into clear, measurable outcomes, $first is seeking $target '
        'where thoughtful execution and collaboration drive real impact.';
  }

  String generateExperienceDescription({
    required String role,
    required String company,
    required List<String> skills,
  }) {
    final top = skills.isEmpty
        ? ['communication', 'problem solving']
        : skills.take(3).toList();
    final skillText = _displayList(SkillDictionary.displayNames(top));
    final employer = company.trim().isEmpty
        ? 'the organization'
        : company.trim();
    final jobTitle = role.trim().isEmpty ? 'the role' : role.trim();
    return '• Led cross-functional initiatives as $jobTitle at $employer, aligning stakeholders around clear goals and measurable outcomes.\n'
        '• Applied $skillText to improve delivery quality, reduce cycle time, and create repeatable processes.\n'
        '• Partnered with product and business teams to translate requirements into shipped solutions, documenting decisions and tracking impact.';
  }

  String generateCoverLetter({
    required String name,
    required String targetRole,
    required String company,
    required String jobDescription,
    required List<String> resumeSkills,
    required String style,
    String experienceLevel = 'Professional',
    String email = '',
    String phone = '',
  }) {
    final jobSkills = SkillDictionary.extractSkills(jobDescription);
    final shared = resumeSkills.where(jobSkills.contains).toList();
    final highlights = SkillDictionary.displayNames(
      (shared.isEmpty ? resumeSkills : shared).take(3),
    );
    final skillText = highlights.isEmpty
        ? 'thoughtful execution and collaboration'
        : _displayList(highlights);
    final employer = company.trim().isEmpty ? 'your team' : company.trim();
    final role = targetRole.trim().isEmpty ? 'this role' : targetRole.trim();
    final firstName = name.trim().isEmpty
        ? 'there'
        : name.trim().split(' ').first;
    final closingName = name.trim().isEmpty
        ? 'Your next teammate'
        : name.trim();
    final contact = [
      email,
      phone,
    ].where((e) => e.trim().isNotEmpty).join(' • ');

    final opening = switch (style) {
      'Friendly' =>
        'Hi $firstName,\n\nI was genuinely excited when I saw the $role opening at $employer. '
            'The mission and the problems you are solving feel like a natural next chapter for me.',
      'Confident' =>
        'Dear Hiring Manager,\n\nI am applying for the $role at $employer because it sits exactly where my strengths create the most value. '
            'I do not just meet the brief — I can raise the bar.',
      'Concise' =>
        'Dear Hiring Manager,\n\nI am writing to apply for the $role at $employer. My background in $skillText maps directly to what the role needs.',
      _ =>
        'Dear Hiring Manager,\n\nI am writing to express my interest in the $role at $employer. '
            'After reading the job description, I am confident that my experience and approach would let me contribute quickly and thoughtfully.',
    };

    final body =
        '\n\nAs a $experienceLevel professional, I bring $skillText and a habit of turning complex requirements into clear, measurable outcomes. '
        'In previous work, I have partnered with cross-functional teams to ship work that improved quality and reduced friction for users and internal teams. '
        'I care about the details, but I stay anchored to the outcome: does this make the product, the customer, or the team meaningfully better?\n\n'
        'What draws me to $employer is the opportunity to apply that mindset to work that matters. '
        'I would welcome the chance to discuss how my background can support your goals and where I can grow fastest with your team.';

    final closing = switch (style) {
      'Concise' =>
        '\n\nThank you for your time. I would be glad to share more in a brief conversation.\n\nSincerely,\n$closingName',
      'Friendly' =>
        '\n\nI would love to chat about how I can help. Thank you for considering my application — I look forward to hearing from you.\n\nWarmly,\n$closingName',
      'Confident' =>
        '\n\nI would welcome a conversation about the impact I can create at $employer. Thank you for your time and consideration.\n\nSincerely,\n$closingName',
      _ =>
        '\n\nThank you for your time and consideration. I look forward to the opportunity to speak with you.\n\nSincerely,\n$closingName',
    };

    final signature = contact.isEmpty ? '' : '\n$contact';
    return '$opening$body$closing$signature';
  }

  List<InterviewQuestion> generateInterviewQuestions({
    required String role,
    required String category,
    required String level,
    int count = 6,
  }) {
    final cleanRole = role.trim().isEmpty ? 'the target role' : role.trim();
    final technical = _technicalQuestions(cleanRole);
    final hr = _hrQuestions(cleanRole);
    final behavioral = _behavioralQuestions(cleanRole);

    final selected = <InterviewQuestion>[];
    if (category == 'Technical') {
      selected.addAll(technical);
    } else if (category == 'HR') {
      selected.addAll(hr);
    } else if (category == 'Behavioral') {
      selected.addAll(behavioral);
    } else {
      selected
        ..addAll(hr.take(2))
        ..addAll(behavioral.take(2))
        ..addAll(technical.take(2));
    }
    if (selected.length < count) {
      for (final item in [...hr, ...behavioral, ...technical]) {
        if (selected.length >= count) break;
        if (!selected.any((q) => q.text == item.text)) selected.add(item);
      }
    }
    return selected.take(count).map((q) => q).toList();
  }

  AnswerFeedback evaluateInterviewAnswer({
    required InterviewQuestion question,
    required String answer,
    required String role,
  }) {
    final clean = answer.trim();
    if (clean.length < 20) {
      throw AiException(
        'Add a little more detail so the coach can give useful feedback.',
      );
    }
    final lower = clean.toLowerCase();
    final words = clean.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).length;
    final sentences = clean
        .split(RegExp(r'[.!?]+'))
        .where((e) => e.trim().isNotEmpty)
        .length;
    final hasStar =
        [
          'situation',
          'task',
          'action',
          'result',
          'challenge',
          'outcome',
        ].where(lower.contains).length >=
        2;
    final hasNumbers = RegExp(r'\b\d+([.,]\d+)?%?').hasMatch(clean);
    final fillerCount =
        ['um', 'uh', 'like', 'basically', 'you know', 'kind of', 'sort of']
            .where(
              (filler) =>
                  RegExp(r'\b${RegExp.escape(filler)}\b').hasMatch(lower),
            )
            .length;
    final teamWords = [
      'team',
      'collaborat',
      'stakeholder',
      'partner',
      'cross-functional',
    ];
    final hasTeam = teamWords.any(lower.contains);
    final idealMatches = question.idealPoints
        .where((point) => _importantWords(point).any(lower.contains))
        .length;

    var score = 38;
    if (words >= 60) score += 14;
    if (words >= 120) score += 6;
    if (sentences >= 3) score += 7;
    if (hasStar) score += 13;
    if (hasNumbers) score += 9;
    if (hasTeam) score += 5;
    score += min(idealMatches * 3, 9);
    score -= fillerCount * 4;
    score = _clamp(score, 20, 98);

    final strengths = <String>[];
    final improvements = <String>[];

    if (hasStar) {
      strengths.add(
        'You used a structured story, which makes your answer easy to follow.',
      );
    }
    if (hasNumbers) {
      strengths.add('Concrete numbers give your answer credibility and scale.');
    }
    if (words >= 80) {
      strengths.add(
        'You provided enough context for the interviewer to understand your contribution.',
      );
    }
    if (hasTeam) {
      strengths.add('You highlighted collaboration and awareness of others.');
    }
    if (strengths.isEmpty) {
      strengths.add(
        'You addressed the question directly and kept the response focused.',
      );
    }

    if (!hasStar) {
      improvements.add('Use the STAR method: Situation, Task, Action, Result.');
    }
    if (!hasNumbers) {
      improvements.add(
        'Add one measurable result — time saved, revenue, users, quality, or speed.',
      );
    }
    if (words < 60) {
      improvements.add(
        'Expand the action and result portion so your specific contribution is clear.',
      );
    }
    if (words > 260) {
      improvements.add(
        'Tighten the story. Aim for 90–150 seconds for most answers.',
      );
    }
    if (fillerCount > 0) {
      improvements.add(
        'Reduce filler words like “like” or “basically” — pause instead.',
      );
    }
    if (!hasTeam && question.category != 'Technical') {
      improvements.add(
        'Mention how you worked with others, not just what you did alone.',
      );
    }
    if (improvements.isEmpty) {
      improvements.add(
        'End with a crisp result and connect it to the value you would bring in this role.',
      );
    }

    final points = question.idealPoints.isEmpty
        ? ['your specific role', 'the action you took', 'the measurable result']
        : question.idealPoints;
    final modelAnswer =
        'A strong answer for “${question.text}” would briefly set the scene, '
        'explain your responsibility, describe the actions you personally took, and finish with a measurable result. '
        'Cover ${_displayList(points.take(3).toList())}. Keep it to 90–150 seconds and connect the outcome to $role.';

    final deliveryTip = words < 60
        ? 'Speak for 60–90 seconds. Add one concrete example and one result.'
        : hasNumbers
        ? 'Good length. Land the result clearly, then stop — do not dilute a strong answer.'
        : 'Your length is good. Practice saying the result out loud with a specific number.';

    return AnswerFeedback(
      score: score,
      strengths: strengths.take(3).toList(),
      improvements: improvements.take(4).toList(),
      modelAnswer: modelAnswer,
      deliveryTip: deliveryTip,
    );
  }

  List<InterviewQuestion> _technicalQuestions(String role) {
    final lower = role.toLowerCase();
    if (lower.contains('flutter') ||
        lower.contains('mobile') ||
        lower.contains('android') ||
        lower.contains('ios')) {
      return [
        _q(
          'Walk me through how you structure a Flutter app for maintainability and testability.',
          'Technical',
          idealPoints: [
            'layered architecture',
            'state management',
            'testing',
            'Separation of concerns',
          ],
        ),
        _q(
          'How do you diagnose and fix jank in a Flutter application?',
          'Technical',
          idealPoints: [
            'profiling',
            'rebuilds',
            'const widgets',
            'DevTools',
            'frame budget',
          ],
        ),
        _q(
          'Explain how you would implement secure authentication in a mobile app.',
          'Technical',
          idealPoints: [
            'secure storage',
            'token lifecycle',
            'refresh tokens',
            'backend validation',
          ],
        ),
        _q(
          'How do you approach offline support and synchronization?',
          'Technical',
          idealPoints: [
            'cache',
            'conflict resolution',
            'queue',
            'connectivity',
            'retry',
          ],
        ),
      ];
    }
    if (lower.contains('data') ||
        lower.contains('scientist') ||
        lower.contains('analyst')) {
      return [
        _q(
          'How would you design an analysis to answer a vague business question?',
          'Technical',
          idealPoints: [
            'clarify metric',
            'data sources',
            'hypothesis',
            'validation',
            'stakeholders',
          ],
        ),
        _q(
          'Explain a time you improved a model or analysis after finding a data quality issue.',
          'Technical',
          idealPoints: [
            'data validation',
            'root cause',
            'impact',
            'communication',
          ],
        ),
        _q(
          'How do you choose between precision and recall for a real project?',
          'Technical',
          idealPoints: [
            'business cost',
            'threshold',
            'false positives',
            'false negatives',
            'evaluation',
          ],
        ),
        _q(
          'Describe how you would communicate an uncertain result to a non-technical stakeholder.',
          'Technical',
          idealPoints: [
            'confidence interval',
            'plain language',
            'assumptions',
            'recommendation',
          ],
        ),
      ];
    }
    if (lower.contains('design') ||
        lower.contains('ux') ||
        lower.contains('product')) {
      return [
        _q(
          'Walk me through your process for turning a problem into a designed solution.',
          'Technical',
          idealPoints: [
            'research',
            'problem framing',
            'prototyping',
            'testing',
            'iteration',
          ],
        ),
        _q(
          'How do you balance user needs with business constraints?',
          'Technical',
          idealPoints: [
            'trade-offs',
            'evidence',
            'stakeholders',
            'prioritization',
            'metrics',
          ],
        ),
        _q(
          'Tell me about a design decision you changed after user feedback.',
          'Technical',
          idealPoints: [
            'feedback',
            'synthesis',
            'iteration',
            'impact',
            'collaboration',
          ],
        ),
        _q(
          'How do you measure whether a product experience is successful?',
          'Technical',
          idealPoints: [
            'success metrics',
            'qualitative',
            'quantitative',
            'baseline',
            'experiment',
          ],
        ),
      ];
    }
    if (lower.contains('market') ||
        lower.contains('sales') ||
        lower.contains('customer')) {
      return [
        _q(
          'How do you build a pipeline and prioritize accounts?',
          'Technical',
          idealPoints: [
            'segmentation',
            'qualification',
            'CRM',
            'prioritization',
            'follow-up',
          ],
        ),
        _q(
          'Walk me through how you handle a customer who is at risk of churning.',
          'Technical',
          idealPoints: [
            'discovery',
            'root cause',
            'plan',
            'communication',
            'retention',
          ],
        ),
        _q(
          'How do you measure the success of a campaign or customer program?',
          'Technical',
          idealPoints: [
            'KPIs',
            'attribution',
            'conversion',
            'retention',
            'reporting',
          ],
        ),
        _q(
          'Describe how you would position a product against a stronger competitor.',
          'Technical',
          idealPoints: [
            'audience',
            'differentiation',
            'evidence',
            'messaging',
            'objections',
          ],
        ),
      ];
    }
    return [
      _q(
        'Describe a technically complex project you delivered and the architecture behind it.',
        'Technical',
        idealPoints: [
          'requirements',
          'trade-offs',
          'architecture',
          'delivery',
          'outcome',
        ],
      ),
      _q(
        'How do you ensure quality when shipping quickly?',
        'Technical',
        idealPoints: [
          'testing',
          'review',
          'automation',
          'monitoring',
          'prioritization',
        ],
      ),
      _q(
        'Tell me about a production issue you resolved. What was your process?',
        'Technical',
        idealPoints: [
          'diagnosis',
          'mitigation',
          'root cause',
          'communication',
          'prevention',
        ],
      ),
      _q(
        'How do you decide when to build versus buy or reuse a solution?',
        'Technical',
        idealPoints: ['cost', 'maintenance', 'time', 'risk', 'core competency'],
      ),
    ];
  }

  List<InterviewQuestion> _hrQuestions(String role) {
    return [
      _q(
        'Tell me about yourself and why you are interested in this role.',
        'HR',
        hint:
            'Keep it to 90 seconds. Connect your background to this specific role.',
        idealPoints: [
          'current role',
          'relevant strengths',
          'motivation',
          'fit',
        ],
      ),
      _q(
        'What are your greatest strengths and how have they created impact?',
        'HR',
        hint: 'Choose two strengths and prove each with a short example.',
        idealPoints: ['strength', 'example', 'impact', 'relevance'],
      ),
      _q(
        'What is a meaningful weakness you are actively working on?',
        'HR',
        hint: 'Be honest, then show the system you use to improve.',
        idealPoints: [
          'self-awareness',
          'specific weakness',
          'action',
          'progress',
        ],
      ),
      _q(
        'Why do you want to work here, and what do you know about the company?',
        'HR',
        hint:
            'Reference the mission, product, or recent work — not only the perks.',
        idealPoints: [
          'company knowledge',
          'mission fit',
          'role fit',
          'long-term interest',
        ],
      ),
      _q(
        'Where do you see yourself in three to five years?',
        'HR',
        hint:
            'Show ambition that fits the role without sounding like a flight risk.',
        idealPoints: ['growth', 'skills', 'scope', 'commitment'],
      ),
      _q(
        'How do you handle competing priorities and pressure?',
        'HR',
        hint: 'Describe a real situation and the framework you used.',
        idealPoints: [
          'prioritization',
          'communication',
          'trade-offs',
          'result',
        ],
      ),
      _q(
        'Tell me about a time you disagreed with a manager or teammate.',
        'HR',
        hint: 'Focus on the conversation, not the conflict.',
        idealPoints: ['listen', 'evidence', 'respect', 'resolution', 'outcome'],
      ),
    ];
  }

  List<InterviewQuestion> _behavioralQuestions(String role) {
    return [
      _q(
        'Tell me about a time you solved a difficult problem with limited information.',
        'Behavioral',
        idealPoints: [
          'situation',
          'constraints',
          'action',
          'judgment',
          'result',
        ],
      ),
      _q(
        'Describe a situation where you had to influence without authority.',
        'Behavioral',
        idealPoints: [
          'stakeholders',
          'evidence',
          'communication',
          'alignment',
          'outcome',
        ],
      ),
      _q(
        'Tell me about a time you missed a deadline or fell short of a goal.',
        'Behavioral',
        idealPoints: [
          'ownership',
          'root cause',
          'recovery',
          'learning',
          'change',
        ],
      ),
      _q(
        'Give me an example of how you handled conflict in a team.',
        'Behavioral',
        idealPoints: [
          'empathy',
          'listening',
          'facts',
          'resolution',
          'relationship',
        ],
      ),
      _q(
        'Tell me about a time you received tough feedback. What changed?',
        'Behavioral',
        idealPoints: [
          'self-awareness',
          'feedback',
          'action',
          'growth',
          'impact',
        ],
      ),
      _q(
        'Describe a project where you had to learn something quickly.',
        'Behavioral',
        idealPoints: [
          'learning plan',
          'constraints',
          'application',
          'result',
          'reflection',
        ],
      ),
      _q(
        'Tell me about a time you took initiative beyond your role.',
        'Behavioral',
        idealPoints: ['opportunity', 'action', 'risk', 'impact', 'ownership'],
      ),
    ];
  }

  InterviewQuestion _q(
    String text,
    String category, {
    String hint = '',
    List<String> idealPoints = const [],
  }) {
    return InterviewQuestion(
      id: _uuid.v4(),
      text: text,
      category: category,
      hint: hint,
      idealPoints: idealPoints,
    );
  }

  Set<String> _keywords(String text) {
    const stopWords = {
      'the',
      'and',
      'for',
      'with',
      'you',
      'your',
      'our',
      'are',
      'this',
      'that',
      'will',
      'have',
      'from',
      'they',
      'their',
      'what',
      'when',
      'where',
      'who',
      'how',
      'all',
      'can',
      'not',
      'but',
      'has',
      'its',
      'into',
      'also',
      'a',
      'an',
      'to',
      'of',
      'in',
      'on',
      'at',
      'is',
      'be',
      'as',
      'by',
      'or',
      'we',
      'us',
      'it',
      'if',
      'do',
      'so',
      'up',
      'out',
      'about',
      'more',
      'than',
    };
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9+#.\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 2 && !stopWords.contains(word))
        .toSet();
  }

  List<String> _importantWords(String text) {
    return _keywords(text).where((word) => word.length > 3).take(3).toList();
  }

  int _clamp(num value, int minValue, int maxValue) =>
      value.clamp(minValue, maxValue).toInt();

  String _displayList(List<String> items) {
    if (items.isEmpty) return '';
    if (items.length == 1) return items.first;
    if (items.length == 2) return '${items[0]} and ${items[1]}';
    return '${items.sublist(0, items.length - 1).join(', ')}, and ${items.last}';
  }
}
