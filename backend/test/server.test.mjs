import { test, describe } from 'node:test';
import assert from 'node:assert/strict';
import {
  score,
  strings,
  truncate,
  wordCount,
  safeEqual,
  normalize,
  promptFor,
  TASKS,
} from '../server.mjs';

describe('Backend Utility Functions', () => {
  test('score bounds numbers between 0 and 100', () => {
    assert.equal(score(85), 85);
    assert.equal(score('92'), 92);
    assert.equal(score(-10), 0);
    assert.equal(score(150), 100);
    assert.equal(score('invalid', 60), 60);
    assert.equal(score(NaN, 50), 50);
  });

  test('strings sanitizes and limits array length', () => {
    assert.deepEqual(strings(['Flutter', '  Dart  ', '', null, 'Node.js'], 2), [
      'Flutter',
      'Dart',
    ]);
    assert.deepEqual(strings('not-an-array'), []);
    assert.deepEqual(strings([], 5), []);
  });

  test('truncate caps string length safely', () => {
    assert.equal(truncate('Hello World', 5), 'Hello');
    assert.equal(truncate(12345, 3), '');
    assert.equal(truncate(null, 10), '');
    assert.equal(truncate('Short', 100), 'Short');
  });

  test('wordCount accurately counts words', () => {
    assert.equal(wordCount(''), 0);
    assert.equal(wordCount('   '), 0);
    assert.equal(wordCount('AI Career Copilot'), 3);
    assert.equal(wordCount('Multiple   spaces   between   words'), 4);
  });

  test('safeEqual performs timing-safe buffer comparison', () => {
    assert.equal(safeEqual('secret-token', 'secret-token'), true);
    assert.equal(safeEqual('secret-token', 'wrong-token'), false);
    assert.equal(safeEqual('short', 'longer-string'), false);
  });
});

describe('Task Validation and Normalization', () => {
  test('TASKS set contains all expected career tasks', () => {
    const expected = [
      'resume_analysis',
      'job_match',
      'summary',
      'experience',
      'cover_letter',
      'interview_questions',
      'interview_feedback',
    ];
    for (const task of expected) {
      assert.ok(TASKS.has(task), `Expected task ${task} to be registered`);
    }
  });

  test('normalize resume_analysis outputs sanitized structure with calculated word count', () => {
    const raw = {
      overallScore: 88,
      atsScore: 92,
      skillsScore: 80,
      experienceScore: 85,
      educationScore: 90,
      formattingScore: 84,
      strengths: ['Clear metrics', 'Strong leadership'],
      weaknesses: ['Add more quantified impacts'],
      missingSkills: ['Kubernetes', 'Docker'],
      suggestions: ['Refine summary header'],
      detectedSkills: ['Flutter', 'Dart', 'Riverpod'],
    };
    const payload = { resumeText: 'Senior Flutter Engineer with 5 years experience' };
    const normalized = normalize('resume_analysis', raw, payload);

    assert.equal(normalized.overallScore, 88);
    assert.equal(normalized.atsScore, 92);
    assert.equal(normalized.wordCount, 7);
    assert.deepEqual(normalized.strengths, ['Clear metrics', 'Strong leadership']);
    assert.deepEqual(normalized.detectedSkills, ['Flutter', 'Dart', 'Riverpod']);
  });

  test('normalize job_match returns score and string lists', () => {
    const raw = {
      score: 78,
      matchedSkills: ['Flutter', 'State Management'],
      missingSkills: ['GraphQL'],
      suggestions: ['Highlight GraphQL client experience'],
      summary: 'Solid candidate match for the mobile team.',
    };
    const normalized = normalize('job_match', raw, {});

    assert.equal(normalized.score, 78);
    assert.deepEqual(normalized.matchedSkills, ['Flutter', 'State Management']);
    assert.equal(normalized.summary, 'Solid candidate match for the mobile team.');
  });

  test('normalize interview_questions processes and assigns IDs', () => {
    const raw = {
      questions: [
        {
          text: 'How do you manage complex state in Flutter?',
          category: 'Architecture',
          hint: 'Mention Riverpod / BLoC',
          idealPoints: ['Immutability', 'Reactivity'],
        },
      ],
    };
    const normalized = normalize('interview_questions', raw, { category: 'Flutter' });

    assert.equal(normalized.questions.length, 1);
    assert.equal(normalized.questions[0].id, 'q1');
    assert.equal(normalized.questions[0].category, 'Architecture');
    assert.deepEqual(normalized.questions[0].idealPoints, ['Immutability', 'Reactivity']);
  });

  test('normalize interview_feedback parses score and advice', () => {
    const raw = {
      score: 85,
      strengths: ['Concise and focused'],
      improvements: ['Give a concrete example from past projects'],
      modelAnswer: 'Here is an ideal answer.',
      deliveryTip: 'Maintain steady pacing.',
    };
    const normalized = normalize('interview_feedback', raw, {});

    assert.equal(normalized.score, 85);
    assert.deepEqual(normalized.strengths, ['Concise and focused']);
    assert.equal(normalized.modelAnswer, 'Here is an ideal answer.');
  });

  test('promptFor builds formatted user prompts for tasks', () => {
    const resumePrompt = promptFor('resume_analysis', {
      targetRole: 'Mobile Architect',
      resumeText: 'Experienced architect...',
    });
    assert.ok(resumePrompt.includes('Mobile Architect'));
    assert.ok(resumePrompt.includes('Experienced architect...'));

    const coverPrompt = promptFor('cover_letter', {
      targetRole: 'Lead Developer',
      company: 'TechCorp',
      jobDescription: 'Seeking a lead...',
      name: 'Jane Doe',
    });
    assert.ok(coverPrompt.includes('Lead Developer'));
    assert.ok(coverPrompt.includes('TechCorp'));
  });
});
