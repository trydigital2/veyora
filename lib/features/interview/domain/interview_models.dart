class InterviewQuestion {
  const InterviewQuestion({
    required this.id,
    required this.text,
    required this.category,
    this.hint = '',
    this.idealPoints = const [],
  });

  final String id;
  final String text;
  final String category;
  final String hint;
  final List<String> idealPoints;

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'category': category,
    'hint': hint,
    'idealPoints': idealPoints,
  };

  factory InterviewQuestion.fromJson(Map<String, dynamic> json) =>
      InterviewQuestion(
        id: json['id'] as String? ?? '',
        text: json['text'] as String? ?? '',
        category: json['category'] as String? ?? 'General',
        hint: json['hint'] as String? ?? '',
        idealPoints:
            (json['idealPoints'] as List?)?.whereType<String>().toList() ??
            const [],
      );
}

class AnswerFeedback {
  const AnswerFeedback({
    required this.score,
    required this.strengths,
    required this.improvements,
    required this.modelAnswer,
    required this.deliveryTip,
  });

  final int score;
  final List<String> strengths;
  final List<String> improvements;
  final String modelAnswer;
  final String deliveryTip;

  Map<String, dynamic> toJson() => {
    'score': score,
    'strengths': strengths,
    'improvements': improvements,
    'modelAnswer': modelAnswer,
    'deliveryTip': deliveryTip,
  };

  factory AnswerFeedback.fromJson(Map<String, dynamic> json) => AnswerFeedback(
    score: (json['score'] as num?)?.round() ?? 0,
    strengths:
        (json['strengths'] as List?)?.whereType<String>().toList() ?? const [],
    improvements:
        (json['improvements'] as List?)?.whereType<String>().toList() ??
        const [],
    modelAnswer: json['modelAnswer'] as String? ?? '',
    deliveryTip: json['deliveryTip'] as String? ?? '',
  );
}

class InterviewAnswer {
  const InterviewAnswer({
    required this.question,
    required this.answer,
    required this.feedback,
  });

  final InterviewQuestion question;
  final String answer;
  final AnswerFeedback feedback;

  Map<String, dynamic> toJson() => {
    'question': question.toJson(),
    'answer': answer,
    'feedback': feedback.toJson(),
  };

  factory InterviewAnswer.fromJson(Map<String, dynamic> json) =>
      InterviewAnswer(
        question: InterviewQuestion.fromJson(
          Map<String, dynamic>.from(json['question'] as Map? ?? const {}),
        ),
        answer: json['answer'] as String? ?? '',
        feedback: AnswerFeedback.fromJson(
          Map<String, dynamic>.from(json['feedback'] as Map? ?? const {}),
        ),
      );
}

class InterviewSession {
  const InterviewSession({
    required this.id,
    required this.role,
    required this.category,
    required this.level,
    required this.questions,
    required this.answers,
    required this.createdAt,
    this.completed = false,
  });

  final String id;
  final String role;
  final String category;
  final String level;
  final List<InterviewQuestion> questions;
  final List<InterviewAnswer> answers;
  final DateTime createdAt;
  final bool completed;

  int get overallScore {
    if (answers.isEmpty) return 0;
    final total = answers.fold<int>(
      0,
      (sum, item) => sum + item.feedback.score,
    );
    return (total / answers.length).round();
  }

  bool get isFinished =>
      answers.length >= questions.length && questions.isNotEmpty;

  InterviewSession copyWith({
    List<InterviewQuestion>? questions,
    List<InterviewAnswer>? answers,
    bool? completed,
  }) {
    return InterviewSession(
      id: id,
      role: role,
      category: category,
      level: level,
      questions: questions ?? this.questions,
      answers: answers ?? this.answers,
      createdAt: createdAt,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role,
    'category': category,
    'level': level,
    'questions': questions.map((e) => e.toJson()).toList(),
    'answers': answers.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'completed': completed,
  };

  factory InterviewSession.fromJson(
    Map<String, dynamic> json,
  ) => InterviewSession(
    id: json['id'] as String? ?? '',
    role: json['role'] as String? ?? 'General',
    category: json['category'] as String? ?? 'Mixed',
    level: json['level'] as String? ?? 'Mid-level',
    questions:
        (json['questions'] as List?)
            ?.whereType<Map>()
            .map(
              (e) => InterviewQuestion.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList() ??
        const [],
    answers:
        (json['answers'] as List?)
            ?.whereType<Map>()
            .map((e) => InterviewAnswer.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        const [],
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    completed: json['completed'] as bool? ?? false,
  );
}
