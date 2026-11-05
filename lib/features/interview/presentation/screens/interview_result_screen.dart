import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../application/interview_controller.dart';
import '../../domain/interview_models.dart';

class InterviewResultScreen extends ConsumerWidget {
  const InterviewResultScreen({super.key, required this.sessionId});

  final String sessionId;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete this session?',
      message: 'The questions and feedback from this practice will be removed.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) return;
    await ref
        .read(interviewControllerProvider.notifier)
        .deleteSession(sessionId);
    if (context.mounted) context.go('/app/coach');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppTheme.isDark(context);
    final state = ref.watch(interviewControllerProvider);
    final session = state.sessionById(sessionId);
    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Session results')),
        body: state.loading
            ? const LoadingView(label: 'Loading your results')
            : EmptyState(
                icon: Icons.insights_outlined,
                title: 'Session not found',
                message: 'This practice session may have been deleted.',
                actionLabel: 'Open interview coach',
                onAction: () => context.go('/app/coach'),
              ),
      );
    }

    final color = AppColors.scoreColors(session.overallScore).last;
    final best = session.answers.isEmpty
        ? 0
        : session.answers
              .map((answer) => answer.feedback.score)
              .reduce((value, element) => value > element ? value : element);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session results'),
        actions: [
          IconButton(
            onPressed: () => _delete(context, ref),
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            tooltip: 'Delete session',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GradientCard(
                  gradient: AppColors.deepGradient,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          ScoreRing(
                            score: session.overallScore,
                            size: 124,
                            stroke: 10,
                            label: 'Overall',
                            color: Colors.white,
                            textColor: Colors.white,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  session.role,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    height: 1.2,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -.5,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '${session.category} · ${session.level}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: .65),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  Formatters.date(session.createdAt),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: .45),
                                    fontSize: 9.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _HeroStat(
                            label: 'Questions',
                            value: '${session.answers.length}',
                          ),
                          const SizedBox(width: 10),
                          _HeroStat(label: 'Best answer', value: '$best'),
                          const SizedBox(width: 10),
                          _HeroStat(
                            label: 'Band',
                            value: Formatters.scoreLabel(session.overallScore),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? .13 : .07),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates_outlined,
                        size: 19,
                        color: color,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          session.overallScore >= 80
                              ? 'Interview-ready. Keep rehearsing the weaker answers so your delivery stays consistent.'
                              : session.overallScore >= 60
                              ? 'Strong foundation. Tighten structure and add measurable results to the answers below.'
                              : 'Good practice rep. Focus on one improvement per answer and run this session again.',
                          style: TextStyle(
                            fontSize: 10.5,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white70 : AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                SectionHeader(
                  title: 'Question breakdown',
                  subtitle: 'Tap any question to review the full feedback',
                  actionLabel: 'Practice again',
                  onAction: () {
                    ref.read(interviewControllerProvider.notifier).reset();
                    context.go('/app/coach');
                  },
                ),
                const SizedBox(height: 12),
                if (session.answers.isEmpty)
                  AppCard(
                    child: Text(
                      'No answers were recorded in this session.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.white54 : AppColors.inkMuted,
                      ),
                    ),
                  )
                else
                  for (
                    var index = 0;
                    index < session.answers.length;
                    index++
                  ) ...[
                    _ReviewCard(answer: session.answers[index], index: index),
                    const SizedBox(height: 9),
                  ],
                const SizedBox(height: 14),
                PrimaryButton(
                  label: 'Practice another role',
                  icon: Icons.replay_rounded,
                  onPressed: () {
                    ref.read(interviewControllerProvider.notifier).reset();
                    context.go('/app/coach');
                  },
                ),
                const SizedBox(height: 9),
                SecondaryButton(
                  label: 'Back to dashboard',
                  icon: Icons.home_outlined,
                  onPressed: () => context.go('/app/home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .5),
                fontSize: 8.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatefulWidget {
  const _ReviewCard({required this.answer, required this.index});

  final InterviewAnswer answer;
  final int index;

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final feedback = widget.answer.feedback;
    final color = AppColors.scoreColors(feedback.score).last;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? .18 : .1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${widget.index + 1}',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.answer.question.text,
                        maxLines: _expanded ? 5 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${feedback.score}/100 · ${Formatters.scoreLabel(feedback.score)}',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns: _expanded ? .5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: isDark ? Colors.white38 : AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: .04)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'YOUR ANSWER',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .8,
                      color: isDark ? Colors.white38 : AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    widget.answer.answer,
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.55,
                      color: isDark ? Colors.white60 : AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (feedback.strengths.isNotEmpty) ...[
              const SizedBox(height: 12),
              _MiniList(
                title: 'Worked well',
                color: AppColors.success,
                items: feedback.strengths,
                icon: Icons.check_circle_rounded,
              ),
            ],
            if (feedback.improvements.isNotEmpty) ...[
              const SizedBox(height: 10),
              _MiniList(
                title: 'Improve next time',
                color: AppColors.warning,
                items: feedback.improvements,
                icon: Icons.trending_up_rounded,
              ),
            ],
            if (feedback.modelAnswer.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              _MiniList(
                title: 'Model answer',
                color: AppColors.primary,
                items: [feedback.modelAnswer],
                icon: Icons.auto_awesome_rounded,
              ),
            ],
            if (feedback.deliveryTip.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              _MiniList(
                title: 'Delivery tip',
                color: AppColors.info,
                items: [feedback.deliveryTip],
                icon: Icons.record_voice_over_outlined,
              ),
            ],
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _MiniList extends StatelessWidget {
  const _MiniList({
    required this.title,
    required this.color,
    required this.items,
    required this.icon,
  });

  final String title;
  final Color color;
  final List<String> items;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              title,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white70 : AppColors.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '• $item',
              style: TextStyle(
                fontSize: 10,
                height: 1.5,
                color: isDark ? Colors.white60 : AppColors.inkMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
