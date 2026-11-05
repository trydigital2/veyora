import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../application/jobs_controller.dart';
import '../../domain/job.dart';
import '../../widgets/job_card.dart';

class JobDetailsScreen extends ConsumerWidget {
  const JobDetailsScreen({super.key, required this.jobId});

  final String jobId;

  Future<void> _open(Job job) async {
    final uri = Uri.tryParse(job.url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppTheme.isDark(context);
    final state = ref.watch(jobsControllerProvider);
    final job = state.jobById(jobId);
    if (job == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Job details')),
        body: EmptyState(
          icon: Icons.work_off_outlined,
          title: 'This role is no longer available',
          message:
              'Browse the live feed for other opportunities that fit your goals.',
          actionLabel: 'Browse jobs',
          onAction: () => context.go('/app/jobs'),
        ),
      );
    }
    final saved = state.isSaved(job.id);
    final description = stripHtml(job.description);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job details'),
        actions: [
          IconButton(
            onPressed: () =>
                ref.read(jobsControllerProvider.notifier).toggleSaved(job),
            icon: Icon(
              saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              size: 21,
              color: saved ? AppColors.primary : null,
            ),
            tooltip: saved ? 'Remove from saved' : 'Save job',
          ),
          IconButton(
            onPressed: () =>
                copyToClipboard(context, job.url, label: 'Job link copied'),
            icon: const Icon(Icons.link_rounded, size: 20),
            tooltip: 'Copy link',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 120),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCard(
                  padding: const EdgeInsets.all(18),
                  shadow: true,
                  border: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CompanyLogo(
                            company: job.company,
                            logoUrl: job.companyLogo,
                            size: 58,
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  job.title,
                                  style: TextStyle(
                                    fontSize: 20,
                                    height: 1.2,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -.5,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  job.company,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white70
                                        : AppColors.inkMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _MetaPill(
                            icon: Icons.place_outlined,
                            label: job.locationLabel,
                          ),
                          _MetaPill(
                            icon: Icons.work_outline_rounded,
                            label: job.jobType,
                          ),
                          if (job.category.isNotEmpty)
                            _MetaPill(
                              icon: Icons.category_outlined,
                              label: job.categoryLabel,
                            ),
                          if (job.salary.trim().isNotEmpty)
                            _MetaPill(
                              icon: Icons.payments_outlined,
                              label: job.salary,
                              color: AppColors.success,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: 'Check my match',
                        icon: Icons.track_changes_rounded,
                        onPressed: () =>
                            context.push('/app/job-matcher', extra: job),
                        height: 50,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: SecondaryButton(
                        label: saved ? 'Saved' : 'Save',
                        icon: saved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        onPressed: () => ref
                            .read(jobsControllerProvider.notifier)
                            .toggleSaved(job),
                        height: 50,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  'About the role',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.3,
                    color: isDark ? Colors.white : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                AppCard(
                  child: Text(
                    description.isEmpty
                        ? 'No description was provided.'
                        : description,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.75,
                      color: isDark ? Colors.white70 : AppColors.inkMuted,
                    ),
                  ),
                ),
                if (job.tags.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Skills & tags',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.3,
                      color: isDark ? Colors.white : AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: job.tags
                        .map((tag) => TagChip(label: tag, dense: true))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 20),
                InfoBanner(
                  icon: Icons.verified_outlined,
                  message:
                      'Live listing from Remotive — posted ${Formatters.timeAgo(job.publishedAt).isEmpty ? 'recently' : Formatters.timeAgo(job.publishedAt)}. Applications open on the original site.',
                  color: AppColors.info,
                ),
                const SizedBox(height: 14),
                TextButton.icon(
                  onPressed: () => _open(job),
                  icon: const Icon(Icons.open_in_new_rounded, size: 17),
                  label: const Text('Open original listing'),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.white10 : AppColors.outline,
              ),
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: PrimaryButton(
                label: 'Apply on Remotive',
                icon: Icons.open_in_new_rounded,
                onPressed: () => _open(job),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final tone = color ?? (isDark ? Colors.white54 : AppColors.inkMuted);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: .06) : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.5, color: tone),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: tone,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
