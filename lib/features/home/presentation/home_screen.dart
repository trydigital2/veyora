import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/app_user.dart';
import '../../interview/application/interview_controller.dart';
import '../../jobs/application/jobs_controller.dart';
import '../../jobs/domain/job.dart';
import '../../jobs/widgets/job_card.dart';
import '../../resume/application/resume_controller.dart';
import '../../resume/domain/resume_models.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    await Future.wait([
      ref.read(resumeControllerProvider.notifier).load(),
      ref.read(jobsControllerProvider.notifier).refresh(),
      ref.read(interviewControllerProvider.notifier).load(),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    if (user == null) return const SizedBox.shrink();
    final resumes = ref.watch(resumeControllerProvider);
    final jobs = ref.watch(jobsControllerProvider);
    final interviews = ref.watch(interviewControllerProvider);
    final isDark = AppTheme.isDark(context);

    final analysis = resumes.latestAnalysis;
    final match = resumes.latestMatch;
    final resumeScore = analysis?.overallScore ?? 0;
    final matchScore = match?.score ?? 0;
    final readiness = analysis == null
        ? 0
        : ((resumeScore * .65) +
                  ((matchScore == 0 ? resumeScore : matchScore) * .35))
              .round();
    final interviewScore = interviews.sessions.isEmpty
        ? 0
        : (interviews.sessions
                      .map((s) => s.overallScore)
                      .reduce((a, b) => a + b) /
                  interviews.sessions.length)
              .round();
    final activities = _buildActivities(resumes, interviews);

    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: _Header(
                      user: user,
                      onAvatar: () => context.go('/app/profile'),
                      onBell: () => _showNotifications(context, activities),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ReadinessCard(
                            readiness: readiness,
                            resumeScore: resumeScore,
                            matchScore: matchScore,
                            hasAnalysis: analysis != null,
                            onTap: () {
                              if (analysis == null) {
                                context.push('/app/analyzer');
                              } else {
                                context.push('/app/analysis/${analysis.id}');
                              }
                            },
                            onPrimary: () => context.push('/app/analyzer'),
                          )
                          .animate()
                          .fadeIn(duration: 450.ms)
                          .moveY(begin: 14, end: 0, curve: Curves.easeOutCubic),
                      const SizedBox(height: 26),
                      const SectionHeader(
                        title: 'Quick actions',
                        subtitle: 'Your everyday career toolkit',
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
                SizedBox(
                  height: 112,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    children: [
                      _QuickAction(
                        icon: Icons.analytics_outlined,
                        label: 'Analyze\nResume',
                        color: AppColors.primary,
                        onTap: () => context.push('/app/analyzer'),
                      ),
                      _QuickAction(
                        icon: Icons.edit_document,
                        label: 'Build\nResume',
                        color: const Color(0xFF0EA5A4),
                        onTap: () => context.push('/app/builder'),
                      ),
                      _QuickAction(
                        icon: Icons.track_changes_rounded,
                        label: 'Job\nMatcher',
                        color: const Color(0xFFF59E0B),
                        onTap: () => context.push('/app/job-matcher'),
                      ),
                      _QuickAction(
                        icon: Icons.auto_awesome_rounded,
                        label: 'Cover\nLetter',
                        color: const Color(0xFFEC4899),
                        onTap: () => context.push('/app/cover-letter'),
                      ),
                      _QuickAction(
                        icon: Icons.record_voice_over_outlined,
                        label: 'Interview\nCoach',
                        color: const Color(0xFF3B82F6),
                        onTap: () => context.go('/app/coach'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: 'Career progress',
                        subtitle: 'Where to focus next',
                        actionLabel: 'Profile',
                        onAction: () => context.go('/app/profile'),
                      ),
                      const SizedBox(height: 13),
                      AppCard(
                        child: Column(
                          children: [
                            LinearScoreBar(
                              label: 'Profile completeness',
                              score: user.profileCompletion,
                              color: AppColors.info,
                            ),
                            const SizedBox(height: 16),
                            LinearScoreBar(
                              label: 'Resume strength',
                              score: resumeScore,
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 16),
                            LinearScoreBar(
                              label: 'Interview readiness',
                              score: interviewScore,
                              color: const Color(0xFF0EA5A4),
                            ),
                            const SizedBox(height: 16),
                            LinearScoreBar(
                              label: 'Job match potential',
                              score: matchScore,
                              color: const Color(0xFFF59E0B),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
                      _RecommendationCard(
                        analysis: analysis,
                        user: user,
                        isDark: isDark,
                        onTap: () {
                          if (analysis == null) {
                            context.push('/app/analyzer');
                          } else {
                            context.push('/app/analysis/${analysis.id}');
                          }
                        },
                      ),
                      const SizedBox(height: 26),
                      SectionHeader(
                        title: 'Recommended jobs',
                        subtitle: 'Live remote roles from Remotive',
                        actionLabel: 'See all',
                        onAction: () => context.go('/app/jobs'),
                      ),
                      const SizedBox(height: 13),
                    ],
                  ),
                ),
                _RecommendedJobs(
                  state: jobs,
                  onRetry: () =>
                      ref.read(jobsControllerProvider.notifier).refresh(),
                  onJob: (job) =>
                      context.push('/app/jobs/${job.id}', extra: job),
                  onSave: (job) => ref
                      .read(jobsControllerProvider.notifier)
                      .toggleSaved(job),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        title: 'Recent activity',
                        subtitle: 'Your latest career moves',
                      ),
                      const SizedBox(height: 13),
                      if (activities.isEmpty)
                        AppCard(
                          child: EmptyState(
                            icon: Icons.auto_awesome_outlined,
                            title: 'Your story starts here',
                            message:
                                'Run your first resume analysis or start an interview practice to see progress here.',
                            compact: true,
                            actionLabel: 'Analyze resume',
                            onAction: () => context.push('/app/analyzer'),
                          ),
                        )
                      else
                        AppCard(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Column(
                            children: [
                              for (
                                var index = 0;
                                index < activities.length;
                                index++
                              ) ...[
                                _ActivityTile(activity: activities[index]),
                                if (index != activities.length - 1)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 64),
                                    child: Divider(
                                      color: isDark
                                          ? Colors.white10
                                          : AppColors.outline,
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<_Activity> _buildActivities(
    ResumeState resumes,
    InterviewState interviews,
  ) {
    final items = <_Activity>[];
    for (final analysis in resumes.analyses.take(3)) {
      items.add(
        _Activity(
          icon: Icons.analytics_outlined,
          color: AppColors.primary,
          title: 'Resume analysis scored ${analysis.overallScore}/100',
          subtitle:
              '${analysis.resumeName}  •  ${Formatters.timeAgo(analysis.createdAt)}',
          onTap: (context) => context.push('/app/analysis/${analysis.id}'),
          createdAt: analysis.createdAt,
        ),
      );
    }
    for (final letter in resumes.coverLetters.take(2)) {
      items.add(
        _Activity(
          icon: Icons.mail_outline_rounded,
          color: const Color(0xFFEC4899),
          title: 'Cover letter created',
          subtitle:
              '${letter.title}  •  ${Formatters.timeAgo(letter.createdAt)}',
          onTap: (context) => context.push('/app/cover-letter?id=${letter.id}'),
          createdAt: letter.createdAt,
        ),
      );
    }
    for (final match in resumes.matches.take(2)) {
      items.add(
        _Activity(
          icon: Icons.track_changes_rounded,
          color: const Color(0xFFF59E0B),
          title: '${match.score}% job match with ${match.company}',
          subtitle:
              '${match.jobTitle}  •  ${Formatters.timeAgo(match.createdAt)}',
          onTap: (context) => context.push('/app/job-matcher'),
          createdAt: match.createdAt,
        ),
      );
    }
    for (final session
        in interviews.sessions.where((s) => s.completed).take(2)) {
      items.add(
        _Activity(
          icon: Icons.record_voice_over_outlined,
          color: const Color(0xFF3B82F6),
          title: 'Interview practice completed',
          subtitle:
              '${session.role}  •  ${session.overallScore}/100  •  ${Formatters.timeAgo(session.createdAt)}',
          onTap: (context) =>
              context.push('/app/interview/result/${session.id}'),
          createdAt: session.createdAt,
        ),
      );
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items.take(4).toList();
  }

  void _showNotifications(BuildContext context, List<_Activity> activities) {
    showAppSheet(
      context,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SectionHeader(
              title: 'Notifications',
              subtitle: 'Career signals worth your attention',
            ),
            const SizedBox(height: 16),
            if (activities.isEmpty)
              const EmptyState(
                icon: Icons.notifications_none_rounded,
                title: 'Nothing new yet',
                message:
                    'Your AI activity and career updates will appear here.',
                compact: true,
              )
            else
              ...activities.map(
                (activity) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: IconBadge(
                    icon: activity.icon,
                    size: 40,
                    color: activity.color,
                  ),
                  title: Text(
                    activity.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    activity.subtitle,
                    style: const TextStyle(fontSize: 11),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    activity.onTap(context);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.user,
    required this.onAvatar,
    required this.onBell,
  });

  final AppUser user;
  final VoidCallback onAvatar;
  final VoidCallback onBell;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return Row(
      children: [
        GestureDetector(
          onTap: onAvatar,
          child: UserAvatar(name: user.name, size: 46),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${Formatters.greeting()},',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : AppColors.inkMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                user.firstName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.7,
                  height: 1.1,
                  color: isDark ? Colors.white : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onBell,
          style: IconButton.styleFrom(
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: .06)
                : Colors.white,
            minimumSize: const Size(44, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: isDark ? Colors.white10 : AppColors.outline,
              ),
            ),
          ),
          icon: Stack(
            children: [
              Icon(
                Icons.notifications_none_rounded,
                size: 22,
                color: isDark ? Colors.white : AppColors.ink,
              ),
              Positioned(
                top: 1,
                right: 1,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard({
    required this.readiness,
    required this.resumeScore,
    required this.matchScore,
    required this.hasAnalysis,
    required this.onTap,
    required this.onPrimary,
  });

  final int readiness;
  final int resumeScore;
  final int matchScore;
  final bool hasAnalysis;
  final VoidCallback onTap;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(20, 20, 18, 18),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .08),
              ),
            ),
          ),
          Positioned(
            right: 14,
            bottom: -60,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .05),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .16),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Text(
                      'AI CAREER READINESS',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasAnalysis
                              ? 'You’re building real momentum.'
                              : 'Let’s find your starting point.',
                          style: const TextStyle(
                            fontSize: 19,
                            height: 1.28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.5,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          hasAnalysis
                              ? 'Your resume is score ${resumeScore >= 70 ? 'strong' : 'ready for a tune-up'}. Keep tailoring to the roles you want.'
                              : 'Analyze your resume to unlock a personalized score and next steps.',
                          style: TextStyle(
                            fontSize: 11.5,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: .72),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _MiniStat(
                              label: 'Resume',
                              value: hasAnalysis ? '$resumeScore' : '—',
                            ),
                            const SizedBox(width: 16),
                            _MiniStat(
                              label: 'Job match',
                              value: matchScore > 0 ? '$matchScore%' : '—',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  ScoreRing(
                    score: readiness,
                    size: 108,
                    stroke: 9,
                    label: 'Readiness',
                    textColor: Colors.white,
                    color: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: onPrimary,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hasAnalysis ? 'Improve my resume' : 'Analyze my resume',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 15,
                        color: AppColors.primaryDark,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: .6),
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: SizedBox(
        width: 104,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Ink(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white10 : AppColors.outline,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isDark ? .18 : .09),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const Spacer(),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.analysis,
    required this.user,
    required this.isDark,
    required this.onTap,
  });

  final ResumeAnalysis? analysis;
  final AppUser user;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final suggestions =
        analysis?.suggestions.take(3).toList() ??
        [
          'Run a resume analysis to unlock personalized AI recommendations.',
          'Add your target role and skills so job matches get sharper.',
          'Practice one interview question today to build consistency.',
        ];
    return AppCard(
      onTap: onTap,
      gradient: isDark
          ? const LinearGradient(
              colors: [Color(0xFF1E1B4B), Color(0xFF2E1D6B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : const LinearGradient(
              colors: [Color(0xFFF4F1FF), Color(0xFFFBF7FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
      border: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBadge(
                icon: Icons.auto_awesome_rounded,
                size: 38,
                radius: 12,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI career recommendations',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.ink,
                      ),
                    ),
                    Text(
                      analysis == null
                          ? 'Personalize your next step'
                          : 'Based on your latest analysis',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white54 : AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: isDark ? Colors.white38 : AppColors.inkMuted,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...suggestions.map(
            (suggestion) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      suggestion,
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : AppColors.inkMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (analysis != null && analysis!.missingSkills.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: analysis!.missingSkills
                  .take(3)
                  .map((skill) => TagChip(label: 'Learn $skill', dense: true))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecommendedJobs extends StatelessWidget {
  const _RecommendedJobs({
    required this.state,
    required this.onRetry,
    required this.onJob,
    required this.onSave,
  });

  final JobsState state;
  final VoidCallback onRetry;
  final ValueChanged<Job> onJob;
  final ValueChanged<Job> onSave;

  @override
  Widget build(BuildContext context) {
    if (state.loading && state.jobs.isEmpty) {
      return const SkeletonList(count: 1, height: 120);
    }
    if (state.error != null && state.jobs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: AppCard(
          child: ErrorState(
            message: state.error!,
            onRetry: onRetry,
            compact: true,
          ),
        ),
      );
    }
    if (state.jobs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: AppCard(
          child: EmptyState(
            icon: Icons.work_off_outlined,
            title: 'No matches yet',
            message:
                'Try a different search on the Jobs tab to discover live roles.',
            compact: true,
            actionLabel: 'Browse jobs',
            onAction: () => context.go('/app/jobs'),
          ),
        ),
      );
    }
    return SizedBox(
      height: 204,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: state.jobs.take(6).length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final job = state.jobs[index];
          return JobMiniCard(
            job: job,
            saved: state.isSaved(job.id),
            onTap: () => onJob(job),
            onToggleSaved: () => onSave(job),
          );
        },
      ),
    );
  }
}

class _Activity {
  const _Activity({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.createdAt,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final ValueChanged<BuildContext> onTap;
  final DateTime createdAt;
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity});

  final _Activity activity;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return InkWell(
      onTap: () => activity.onTap(context),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            IconBadge(
              icon: activity.icon,
              size: 40,
              color: activity.color.withValues(alpha: isDark ? .2 : .1),
              iconColor: activity.color,
              radius: 12,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    activity.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white38 : AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: isDark ? Colors.white24 : AppColors.inkMuted,
            ),
          ],
        ),
      ),
    );
  }
}
