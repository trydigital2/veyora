import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../interview/application/interview_controller.dart';
import '../../../jobs/application/jobs_controller.dart';
import '../../../resume/application/resume_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Sign out of VEYORA?',
      message:
          'Your saved resumes, analyses, and practice history stay on this device.',
      confirmLabel: 'Sign out',
      destructive: true,
    );
    if (!confirmed) return;
    await ref.read(authControllerProvider.notifier).signOut();
    if (context.mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppTheme.isDark(context);
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: EmptyState(
          icon: Icons.person_off_outlined,
          title: 'You are signed out',
          message: 'Sign in to view your profile.',
          actionLabel: 'Sign in',
          onAction: () => context.go('/login'),
        ),
      );
    }
    final resumeState = ref.watch(resumeControllerProvider);
    final interviewState = ref.watch(interviewControllerProvider);
    final jobsState = ref.watch(jobsControllerProvider);
    final completedSessions = interviewState.sessions
        .where((s) => s.completed)
        .length;
    final isPro = user.plan.toLowerCase() == 'pro';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: () => context.push('/app/settings'),
            icon: const Icon(Icons.settings_outlined, size: 21),
            tooltip: 'Settings',
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
                AppCard(
                  padding: const EdgeInsets.all(20),
                  shadow: true,
                  border: false,
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          UserAvatar(name: user.name, size: 64),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        user.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -.5,
                                          color: isDark
                                              ? Colors.white
                                              : AppColors.ink,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 7),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: isPro
                                            ? AppColors.heroGradient
                                            : null,
                                        color: isPro
                                            ? null
                                            : (isDark
                                                  ? Colors.white.withValues(
                                                      alpha: .07,
                                                    )
                                                  : AppColors.primary
                                                        .withValues(
                                                          alpha: .07,
                                                        )),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        user.plan,
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: .4,
                                          color: isPro
                                              ? Colors.white
                                              : (isDark
                                                    ? Colors.white60
                                                    : AppColors.primary),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  user.headline.isEmpty
                                      ? 'Add a headline'
                                      : user.headline,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    height: 1.4,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.white54
                                        : AppColors.inkMuted,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.mail_outline_rounded,
                                      size: 12,
                                      color: isDark
                                          ? Colors.white38
                                          : AppColors.inkMuted,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        user.email,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isDark
                                              ? Colors.white38
                                              : AppColors.inkMuted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (user.location.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.place_outlined,
                                        size: 12,
                                        color: isDark
                                            ? Colors.white38
                                            : AppColors.inkMuted,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          user.location,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isDark
                                                ? Colors.white38
                                                : AppColors.inkMuted,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              label: 'Edit profile',
                              icon: Icons.edit_outlined,
                              onPressed: () =>
                                  context.push('/app/edit-profile'),
                              height: 46,
                            ),
                          ),
                          const SizedBox(width: 9),
                          SizedBox(
                            width: 50,
                            height: 46,
                            child: OutlinedButton(
                              onPressed: () => context.push('/app/settings'),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(13),
                                ),
                              ),
                              child: const Icon(
                                Icons.settings_outlined,
                                size: 19,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LinearScoreBar(
                        label: 'Profile strength',
                        score: user.profileCompletion,
                        showValue: true,
                      ),
                      if (user.profileCompletion < 100) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            user.profileCompletion < 50
                                ? 'Add a headline, skills, and experience to unlock better AI results.'
                                : 'A little more detail will sharpen your recommendations.',
                            style: TextStyle(
                              fontSize: 9.5,
                              height: 1.45,
                              color: isDark
                                  ? Colors.white38
                                  : AppColors.inkMuted,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        value: '${resumeState.resumes.length}',
                        label: 'Resumes',
                        icon: Icons.description_outlined,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: StatTile(
                        value: '${resumeState.analyses.length}',
                        label: 'Analyses',
                        icon: Icons.analytics_outlined,
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        value: '${resumeState.matches.length}',
                        label: 'Job matches',
                        icon: Icons.track_changes_rounded,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: StatTile(
                        value: '$completedSessions',
                        label: 'Interviews',
                        icon: Icons.record_voice_over_outlined,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                if (user.bio.trim().isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const SectionHeader(title: 'About'),
                  const SizedBox(height: 10),
                  AppCard(
                    child: Text(
                      user.bio,
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.65,
                        color: isDark ? Colors.white60 : AppColors.inkMuted,
                      ),
                    ),
                  ),
                ],
                if (user.skills.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  SectionHeader(
                    title: 'Skills',
                    subtitle: '${user.skills.length} skills on your profile',
                  ),
                  const SizedBox(height: 10),
                  AppCard(
                    child: Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: user.skills
                          .map((skill) => TagChip(label: skill, dense: true))
                          .toList(),
                    ),
                  ),
                ],
                if (user.experience.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const SectionHeader(title: 'Experience'),
                  const SizedBox(height: 10),
                  ...user.experience.map(
                    (exp) => Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: _EntryTile(
                        icon: Icons.work_history_outlined,
                        title: exp.role,
                        subtitle: [
                          exp.company,
                          exp.dateRange,
                        ].where((item) => item.isNotEmpty).join(' · '),
                        body: exp.description,
                      ),
                    ),
                  ),
                ],
                if (user.education.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const SectionHeader(title: 'Education'),
                  const SizedBox(height: 10),
                  ...user.education.map(
                    (edu) => Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: _EntryTile(
                        icon: Icons.school_outlined,
                        title:
                            '${edu.degree}${edu.field.isEmpty ? '' : ' in ${edu.field}'}',
                        subtitle: [
                          edu.school,
                          edu.dateRange,
                        ].where((item) => item.isNotEmpty).join(' · '),
                        body: '',
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                const SectionHeader(title: 'Account'),
                const SizedBox(height: 10),
                AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    children: [
                      _MenuTile(
                        icon: Icons.bookmark_border_rounded,
                        label: 'Saved jobs',
                        trailing: jobsState.savedJobs.isEmpty
                            ? null
                            : '${jobsState.savedJobs.length}',
                        onTap: () => context.push('/app/saved-jobs'),
                      ),
                      _MenuTile(
                        icon: Icons.workspace_premium_outlined,
                        label: 'Subscription',
                        trailing: user.plan,
                        onTap: () => context.push('/app/subscription'),
                      ),
                      _MenuTile(
                        icon: Icons.settings_outlined,
                        label: 'Settings',
                        onTap: () => context.push('/app/settings'),
                      ),
                      _MenuTile(
                        icon: Icons.logout_rounded,
                        label: 'Sign out',
                        color: AppColors.danger,
                        onTap: () => _signOut(context, ref),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      const VeyoraLogo(size: 30, compact: true),
                      const SizedBox(height: 8),
                      Text(
                        'VEYORA · Your Potential. Our Intelligence.',
                        style: TextStyle(
                          fontSize: 8.5,
                          color: isDark ? Colors.white30 : AppColors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Member since ${Formatters.date(user.createdAt)}',
                        style: TextStyle(
                          fontSize: 8,
                          color: isDark
                              ? Colors.white24
                              : AppColors.inkMuted.withValues(alpha: .7),
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
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String body;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(
            icon: icon,
            size: 36,
            color: AppColors.primary.withValues(alpha: isDark ? .16 : .07),
            iconColor: AppColors.primary,
            radius: 10,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.ink,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white54 : AppColors.inkMuted,
                    ),
                  ),
                ],
                if (body.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9.5,
                      height: 1.45,
                      color: isDark ? Colors.white38 : AppColors.inkMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? trailing;
  final Color? color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final tone = color ?? (isDark ? Colors.white : AppColors.ink);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 19, color: color ?? AppColors.primary),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: tone,
                ),
              ),
            ),
            if (trailing != null && trailing!.trim().isNotEmpty) ...[
              Text(
                trailing!,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white38 : AppColors.inkMuted,
                ),
              ),
              const SizedBox(width: 5),
            ],
            Icon(
              Icons.chevron_right_rounded,
              size: 19,
              color: isDark ? Colors.white24 : AppColors.inkMuted,
            ),
          ],
        ),
      ),
    );
  }
}
