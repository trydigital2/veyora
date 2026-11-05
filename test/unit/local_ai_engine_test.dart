import 'package:flutter_test/flutter_test.dart';
import 'package:veyors/core/services/local_ai_engine.dart';

const _resume = '''
AARAV MEHTA
Flutter Developer
aarav@example.com | +91 90000 12345 | Pune, India | linkedin.com/in/aarav

SUMMARY
Flutter developer with 4 years of experience building consumer mobile products.

SKILLS
Flutter, Dart, Firebase, REST API, Git, Figma, unit testing

EXPERIENCE
Senior Flutter Developer at Orbit Apps (2023 - Present)
- Reduced cold-start time by 38% through profiling and lazy initialization.
- Shipped offline-first sync for 120k monthly active users.
- Led a team of 4 engineers and mentored 2 interns.

Mobile Developer at Tandem Studio (2020 - 2023)
- Built and shipped 5 Flutter apps across fintech and wellness.
- Introduced automated testing and CI, cutting regressions by 31%.

EDUCATION
B.E. in Computer Engineering, Savitribai Phule Pune University (2016 - 2020)
''';

const _job = '''
We are hiring a Senior Flutter Developer to build a consumer app.
Requirements: Flutter, Dart, REST API, Firebase, Git, unit testing.
You will ship features, improve performance, and partner with designers using Figma.
Experience with CI and automated testing is a plus.
''';

void main() {
  const engine = LocalAiEngine();

  test('analyzes a resume into a realistic scorecard', () {
    final analysis = engine.analyzeResume(
      text: _resume,
      targetRole: 'Flutter Developer',
    );

    expect(analysis.overallScore, inInclusiveRange(0, 100));
    expect(analysis.atsScore, inInclusiveRange(0, 100));
    expect(analysis.detectedSkills, contains('Flutter'));
    expect(analysis.strengths, isNotEmpty);
    expect(analysis.suggestions, isNotEmpty);
  });

  test('matches a resume against a job description', () {
    final match = engine.matchJob(
      resumeText: _resume,
      jobDescription: _job,
      jobTitle: 'Senior Flutter Developer',
      company: 'Acme',
    );

    expect(match.score, inInclusiveRange(0, 100));
    expect(match.matchedSkills, contains('Flutter'));
    expect(match.summary, isNotEmpty);
  });

  test('generates a summary that mentions the target role', () {
    final summary = engine.generateSummary(
      name: 'Aarav Mehta',
      role: 'Flutter Developer',
      skills: const ['Flutter', 'Dart'],
    );

    expect(summary, contains('Flutter Developer'));
    expect(summary.length, greaterThan(80));
  });

  test('generates interview questions and evaluates an answer', () {
    final questions = engine.generateInterviewQuestions(
      role: 'Flutter Developer',
      category: 'Mixed',
      level: 'Mid-level',
    );
    expect(questions, hasLength(6));

    final feedback = engine.evaluateInterviewAnswer(
      question: questions.first,
      answer:
          'In my last role I owned the checkout flow. I reduced load time by 40 percent by profiling rebuilds, moving work off the main isolate, and adding regression tests. I partnered with design and QA to ship the change safely.',
      role: 'Flutter Developer',
    );

    expect(feedback.score, inInclusiveRange(0, 100));
    expect(feedback.modelAnswer, isNotEmpty);
    expect(feedback.deliveryTip, isNotEmpty);
  });

  test('rejects an overly short resume', () {
    expect(
      () => engine.analyzeResume(text: 'Too short', targetRole: 'Designer'),
      throwsA(isA<AiException>()),
    );
  });
}
