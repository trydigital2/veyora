import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../application/interview_controller.dart';
import '../../domain/interview_models.dart';

class InterviewSessionScreen extends ConsumerStatefulWidget {
  const InterviewSessionScreen({super.key});

  @override
  ConsumerState<InterviewSessionScreen> createState() =>
      _InterviewSessionScreenState();
}

class _InterviewSessionScreenState
    extends ConsumerState<InterviewSessionScreen> {
  final _answerCtrl = TextEditingController();
  bool _showFeedback = false;
  bool _finishing = false;
  InterviewQuestion? _answeredQuestion;
  AnswerFeedback? _feedback;

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _answerCtrl.text.trim();
    if (text.length < 20) {
      AppSnack.show(
        context,
        'Add a little more detail — aim for at least 20 characters.',
        error: true,
      );
      return;
    }
    FocusScope.of(context).unfocus();
    final question = ref.read(interviewControllerProvider).currentQuestion;
    final ok = await ref
        .read(interviewControllerProvider.notifier)
        .submitAnswer(text);
    if (!mounted) return;
    if (ok) {
      final session = ref.read(interviewControllerProvider).current;
      setState(() {
        _answeredQuestion = question;
        _feedback = session?.answers.isEmpty == true
            ? null
            : session?.answers.last.feedback;
        _showFeedback = true;
        _answerCtrl.clear();
      });
    } else {
      final error = ref.read(interviewControllerProvider).error;
      AppSnack.show(
        context,
        error ?? 'Could not evaluate that answer. Please try again.',
        error: true,
      );
      ref.read(interviewControllerProvider.notifier).clearError();
    }
  }

  Future<void> _finish() async {
    setState(() => _finishing = true);
    try {
      final session = await ref
          .read(interviewControllerProvider.notifier)
          .finish();
      if (!mounted) return;
      setState(() => _finishing = false);
      if (session == null) {
        AppSnack.show(context, 'Could not finish this session.', error: true);
        return;
      }
      context.pushReplacement('/app/interview/result/${session.id}');
    } catch (_) {
      if (!mounted) return;
      setState(() => _finishing = false);
      AppSnack.show(
        context,
        'Could not finish this session. Please try again.',
        error: true,
      );
    }
  }

  Future<void> _leave() async {
    final session = ref.read(interviewControllerProvider).current;
    if (session == null || session.answers.isEmpty) {
      ref.read(interviewControllerProvider.notifier).reset();
      context.pop();
      return;
    }
    final confirmed = await showConfirmDialog(
      context,
      title: 'Leave this practice?',
      message:
          'Your answers so far have not been saved as a completed session. You can start a fresh practice anytime.',
      confirmLabel: 'Leave',
      destructive: true,
    );
    if (confirmed && mounted) {
      ref.read(interviewControllerProvider.notifier).reset();
      context.pop();
    }
  }

  void _next() {
    setState(() {
      _showFeedback = false;
      _feedback = null;
      _answeredQuestion = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final state = ref.watch(interviewControllerProvider);
    final session = state.current;

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Interview practice')),
        body: EmptyState(
          icon: Icons.mic_none_rounded,
          title: 'No active session',
          message:
              'Set up a practice session with the interview coach to get started.',
          actionLabel: 'Open coach',
          onAction: () => context.go('/app/coach'),
        ),
      );
    }

    final total = session.questions.length;
    final answered = session.answers.length;
    final progress = total == 0 ? 0.0 : answered / total;
    final finished = session.isFinished;
    final currentQuestion = state.currentQuestion;
    final displayQuestion = _showFeedback ? _answeredQuestion : currentQuestion;
    final showingCompletion = finished && !_showFeedback;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Interview practice'),
        leading: IconButton(
          onPressed: _leave,
          icon: const Icon(Icons.close_rounded, size: 21),
          tooltip: 'Leave practice',
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '$answered / $total',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white54 : AppColors.inkMuted,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: .07)
                    : AppColors.primary.withValues(alpha: .07),
                color: AppColors.primary,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: showingCompletion
                      ? _CompletionView(
                          session: session,
                          finishing: _finishing,
                          onFinish: _finish,
                          onRestart: () {
                            ref
                                .read(interviewControllerProvider.notifier)
                                .reset();
                            context.go('/app/coach');
                          },
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (displayQuestion != null) ...[
                              _QuestionCard(
                                question: displayQuestion,
                                index: answered + (_showFeedback ? 0 : 1),
                                total: total,
                              ),
                              const SizedBox(height: 14),
                            ],
                            if (_showFeedback && _feedback != null)
                              _FeedbackView(
                                feedback: _feedback!,
                                finished: finished,
                                finishing: _finishing,
                                onContinue: finished ? _finish : _next,
                              )
                            else if (currentQuestion != null)
                              _AnswerComposer(
                                controller: _answerCtrl,
                                evaluating: state.evaluating,
                                onSubmit: _submit,
                                onChanged: () => setState(() {}),
                              ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.index,
    required this.total,
  });

  final InterviewQuestion question;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return AppCard(
      color: isDark ? null : AppColors.lavender.withValues(alpha: .45),
      border: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  question.category.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .8,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Question $index of $total',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : AppColors.inkMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            question.text,
            style: TextStyle(
              fontSize: 17,
              height: 1.4,
              fontWeight: FontWeight.w800,
              letterSpacing: -.3,
              color: isDark ? Colors.white : AppColors.ink,
            ),
          ),
          if (question.hint.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: .05)
                    : Colors.white.withValues(alpha: .7),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 15,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      question.hint,
                      style: TextStyle(
                        fontSize: 10.5,
                        height: 1.5,
                        color: isDark ? Colors.white60 : AppColors.inkMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnswerComposer extends StatelessWidget {
  const _AnswerComposer({
    required this.controller,
    required this.evaluating,
    required this.onSubmit,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool evaluating;
  final VoidCallback onSubmit;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final words = controller.text.trim().isEmpty
        ? 0
        : controller.text
              .trim()
              .split(RegExp(r'\s+'))
              .where((e) => e.isNotEmpty)
              .length;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Your answer',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : AppColors.inkMuted,
                ),
              ),
              const Spacer(),
              Text(
                '$words words',
                style: TextStyle(
                  fontSize: 9.5,
                  color: isDark ? Colors.white38 : AppColors.inkMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          TextField(
            controller: controller,
            onChanged: (_) => onChanged(),
            maxLines: 10,
            minLines: 7,
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: isDark ? Colors.white : AppColors.ink,
            ),
            decoration: InputDecoration(
              hintText:
                  'Structure your answer: the situation, your task, the action you took, and the result.',
              hintStyle: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: isDark
                    ? Colors.white30
                    : AppColors.inkMuted.withValues(alpha: .7),
              ),
            ),
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: 'Get AI feedback',
            icon: Icons.auto_awesome_rounded,
            loading: evaluating,
            onPressed: evaluating ? null : onSubmit,
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Aim for 60–120 seconds of spoken content.',
              style: TextStyle(
                fontSize: 9,
                color: isDark ? Colors.white30 : AppColors.inkMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackView extends StatelessWidget {
  const _FeedbackView({
    required this.feedback,
    required this.finished,
    required this.finishing,
    required this.onContinue,
  });

  final AnswerFeedback feedback;
  final bool finished;
  final bool finishing;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final color = AppColors.scoreColors(feedback.score).last;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          child: Column(
            children: [
              Row(
                children: [
                  ScoreRing(
                    score: feedback.score,
                    size: 82,
                    stroke: 7,
                    showLabel: false,
                    color: color,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Answer feedback',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.3,
                            color: isDark ? Colors.white : AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          feedback.score >= 80
                              ? 'This answer is close to interview-ready.'
                              : feedback.score >= 60
                              ? 'Solid answer with a few sharp edges to fix.'
                              : 'A useful start. Focus on structure and outcomes.',
                          style: TextStyle(
                            fontSize: 10.5,
                            height: 1.45,
                            color: isDark ? Colors.white54 : AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (feedback.strengths.isNotEmpty) ...[
                const SizedBox(height: 16),
                _FeedbackList(
                  title: 'What worked',
                  icon: Icons.check_circle_rounded,
                  color: AppColors.success,
                  items: feedback.strengths,
                ),
              ],
              if (feedback.improvements.isNotEmpty) ...[
                const SizedBox(height: 13),
                _FeedbackList(
                  title: 'What to sharpen',
                  icon: Icons.trending_up_rounded,
                  color: AppColors.warning,
                  items: feedback.improvements,
                ),
              ],
            ],
          ),
        ),
        if (feedback.modelAnswer.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          AppCard(
            color: isDark
                ? AppColors.primary.withValues(alpha: .1)
                : AppColors.primary.withValues(alpha: .04),
            border: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 15,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Model answer',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white70 : AppColors.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  feedback.modelAnswer,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.65,
                    color: isDark ? Colors.white60 : AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (feedback.deliveryTip.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          InfoBanner(
            message: feedback.deliveryTip,
            icon: Icons.record_voice_over_outlined,
            color: AppColors.info,
          ),
        ],
        const SizedBox(height: 16),
        PrimaryButton(
          label: finished ? 'See my results' : 'Next question',
          icon: finished ? Icons.insights_rounded : Icons.arrow_forward_rounded,
          loading: finishing,
          onPressed: finishing ? null : onContinue,
        ),
      ],
    );
  }
}

class _FeedbackList extends StatelessWidget {
  const _FeedbackList({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              title,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white70 : AppColors.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Container(
                    width: 3.5,
                    height: 3.5,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.5,
                      color: isDark ? Colors.white60 : AppColors.inkMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CompletionView extends StatelessWidget {
  const _CompletionView({
    required this.session,
    required this.finishing,
    required this.onFinish,
    required this.onRestart,
  });

  final InterviewSession session;
  final bool finishing;
  final VoidCallback onFinish;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final color = AppColors.scoreColors(session.overallScore).last;
    return Column(
      children: [
        const SizedBox(height: 20),
        AppCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              ScoreRing(
                score: session.overallScore,
                size: 138,
                stroke: 11,
                label: 'Overall',
                color: color,
              ),
              const SizedBox(height: 16),
              Text(
                'Session complete',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.5,
                  color: isDark ? Colors.white : AppColors.ink,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${session.answers.length} answers · ${session.category} · ${session.level}',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white54 : AppColors.inkMuted,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Save this session to revisit the feedback and track your improvement over time.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.5,
                  color: isDark ? Colors.white54 : AppColors.inkMuted,
                ),
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                label: 'Save & view results',
                icon: Icons.insights_rounded,
                loading: finishing,
                onPressed: finishing ? null : onFinish,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SecondaryButton(
          label: 'Start a new session',
          icon: Icons.refresh_rounded,
          onPressed: finishing ? null : onRestart,
        ),
      ],
    );
  }
}
