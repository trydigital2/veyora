import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../application/jobs_controller.dart';
import '../../widgets/job_card.dart';

class SavedJobsScreen extends ConsumerWidget {
  const SavedJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppTheme.isDark(context);
    final state = ref.watch(jobsControllerProvider);
    final saved = state.savedJobs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved jobs'),
        actions: [
          IconButton(
            onPressed: () => context.go('/app/jobs'),
            icon: const Icon(Icons.search_rounded, size: 21),
            tooltip: 'Browse jobs',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: saved.isEmpty
          ? EmptyState(
              icon: Icons.bookmark_border_rounded,
              title: 'Nothing saved yet',
              message:
                  'Tap the bookmark on any role to keep it here for later. Your saved jobs stay on this device.',
              actionLabel: 'Browse live jobs',
              onAction: () => context.go('/app/jobs'),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                  children: [
                    Row(
                      children: [
                        Text(
                          '${saved.length} saved ${saved.length == 1 ? 'role' : 'roles'}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white70 : AppColors.inkMuted,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.bookmark_rounded,
                          size: 15,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (final job in saved) ...[
                      JobCard(
                        job: job,
                        saved: true,
                        onTap: () => context.push('/app/jobs/${job.id}'),
                        onToggleSaved: () => ref
                            .read(jobsControllerProvider.notifier)
                            .toggleSaved(job),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
