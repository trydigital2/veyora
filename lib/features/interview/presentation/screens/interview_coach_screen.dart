import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../auth/application/auth_controller.dart';
import '../../application/interview_controller.dart';
import '../../domain/interview_models.dart';

class InterviewCoachScreen extends ConsumerStatefulWidget {
  const InterviewCoachScreen({super.key});

  @override
  ConsumerState<InterviewCoachScreen> createState() =>
      _InterviewCoachScreenState();
}

class _InterviewCoachScreenState extends ConsumerState<InterviewCoachScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roleCtrl = TextEditingController();
  String _category = 'Mixed';
  String _level = 'Mid-level';
  bool _starting = false;

  static const _categories = [
    ('Mixed', Icons.shuffle_rounded),
    ('Behavioral', Icons.psychology_alt_outlined),
    ('Technical', Icons.code_rounded),
    ('HR', Icons.groups_outlined),
  ];

  static const _levels = ['Entry level', 'Mid-level', 'Senior'];

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).user;
    _roleCtrl.text = user?.targetRole ?? '';
    final level = user?.experienceLevel ?? '';
    if (_levels.contains(level)) _level = level;
  }

  @override
  void dispose() {
    _roleCtrl.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _starting = true);
    final ok = await ref
        .read(interviewControllerProvider.notifier)
        .start(role: _roleCtrl.text.trim(), category: _category, level: _level);
    if (!mounted) return;
    setState(() => _starting = false);
    if (ok) {
      context.push('/app/interview/session');
    } else {
      final error = ref.read(interviewControllerProvider).error;
      AppSnack.show(
        context,
        error ?? 'Could not start the interview. Please try again.',
        error: true,
      );
      ref.read(interviewControllerProvider.notifier).clearError();
    }
  }

  Future<void> _deleteSession(InterviewSession session) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete this session?',
      message: 'The questions and feedback from this practice will be removed.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed) {
      await ref
          .read(interviewControllerProvider.notifier)
          .deleteSession(session.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final state = ref.watch(interviewControllerProvider);
    final sessions = state.sessions;
    final completed = sessions.where((session) => session.completed).toList();
    final average = completed.isEmpty
        ? 0
        : (completed.fold<int>(0, (sum, s) => sum + s.overallScore) /
                  completed.length)
              .round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Interview coach'),
        actions: [
          IconButton(
            onPressed: () => context.go('/app/profile'),
            icon: const Icon(Icons.person_outline_rounded, size: 21),
            tooltip: 'Your profile',
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
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Practice out loud.\nImprove fast.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                height: 1.18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.6,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              completed.isEmpty
                                  ? 'Answer realistic questions and get structured feedback after every response.'
                                  : '${completed.length} practice ${completed.length == 1 ? 'session' : 'sessions'} · $average% average score',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: .65),
                                fontSize: 10.5,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 82,
                        height: 82,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .14),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  completed.isEmpty ? 'AI' : '$average',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -.7,
                                  ),
                                ),
                                Text(
                                  completed.isEmpty ? 'COACH' : 'AVG',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: .5),
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const SectionHeader(
                  title: 'Set up your session',
                  subtitle: 'Six questions tailored to your target role',
                ),
                const SizedBox(height: 12),
                Form(
                  key: _formKey,
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTextField(
                          controller: _roleCtrl,
                          label: 'Role you are interviewing for',
                          hint: 'e.g. Product Manager',
                          prefixIcon: Icons.badge_outlined,
                          textInputAction: TextInputAction.done,
                          validator: (value) =>
                              Validators.required(value, label: 'Role'),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Focus',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white70 : AppColors.inkMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: [
                            for (final category in _categories)
                              TagChip(
                                label: category.$1,
                                icon: category.$2,
                                selected: _category == category.$1,
                                onTap: () =>
                                    setState(() => _category = category.$1),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Experience level',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white70 : AppColors.inkMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: [
                            for (final level in _levels)
                              TagChip(
                                label: level,
                                selected: _level == level,
                                onTap: () => setState(() => _level = level),
                              ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        PrimaryButton(
                          label: 'Start practice',
                          icon: Icons.play_arrow_rounded,
                          loading: _starting || state.generating,
                          onPressed: _starting || state.generating
                              ? null
                              : _start,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const InfoBanner(
                  message:
                      'Use the STAR method: Situation, Task, Action, Result. Aim for 60–120 seconds per answer.',
                  icon: Icons.lightbulb_outline_rounded,
                ),
                const SizedBox(height: 24),
                SectionHeader(
                  title: 'Practice history',
                  subtitle: sessions.isEmpty
                      ? 'Your completed sessions will appear here'
                      : 'Revisit feedback and track your growth',
                ),
                const SizedBox(height: 12),
                if (sessions.isEmpty)
                  AppCard(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        IconBadge(
                          icon: Icons.history_rounded,
                          size: 40,
                          color: AppColors.primary.withValues(
                            alpha: isDark ? .16 : .07,
                          ),
                          iconColor: AppColors.primary,
                          radius: 12,
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            'No sessions yet. Your first practice is the hardest — after that it compounds.',
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.5,
                              color: isDark
                                  ? Colors.white54
                                  : AppColors.inkMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  for (final session in sessions) ...[
                    _SessionTile(
                      session: session,
                      onTap: () =>
                          context.push('/app/interview/result/${session.id}'),
                      onDelete: () => _deleteSession(session),
                    ),
                    const SizedBox(height: 9),
                  ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.onTap,
    required this.onDelete,
  });

  final InterviewSession session;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final color = AppColors.scoreColors(session.overallScore).last;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      onTap: onTap,
      child: Row(
        children: [
          ScoreRing(
            score: session.overallScore,
            size: 50,
            stroke: 4.5,
            showLabel: false,
            color: color,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.role,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${session.category} · ${session.level} · ${Formatters.shortDate(session.createdAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white54 : AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          if (session.completed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: isDark ? .16 : .09),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Completed',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, size: 17),
            color: AppColors.danger,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
