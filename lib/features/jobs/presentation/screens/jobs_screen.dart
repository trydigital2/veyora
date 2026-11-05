import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../application/jobs_controller.dart';
import '../../domain/job.dart';
import '../../widgets/job_card.dart';

class JobsScreen extends ConsumerStatefulWidget {
  const JobsScreen({super.key});

  @override
  ConsumerState<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends ConsumerState<JobsScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  static const _categories = [
    'All',
    'Software Development',
    'Design',
    'Marketing',
    'Sales',
    'Product',
    'Data',
    'Customer Support',
    'Finance',
  ];

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = ref.read(jobsControllerProvider).query;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    setState(() {});
    _debounce = Timer(const Duration(milliseconds: 550), () {
      if (mounted) ref.read(jobsControllerProvider.notifier).search(value);
    });
  }

  void _submit(String value) {
    _debounce?.cancel();
    ref.read(jobsControllerProvider.notifier).search(value);
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchCtrl.clear();
    ref.read(jobsControllerProvider.notifier).search('');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final state = ref.watch(jobsControllerProvider);
    final jobs = state.jobs;
    final savedCount = state.savedJobs.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live jobs'),
        actions: [
          Badge.count(
            count: savedCount,
            isLabelVisible: savedCount > 0,
            backgroundColor: AppColors.primary,
            child: IconButton(
              onPressed: () => context.push('/app/saved-jobs'),
              icon: const Icon(Icons.bookmark_border_rounded, size: 21),
              tooltip: 'Saved jobs',
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 10),
            child: Column(
              children: [
                AppTextField(
                  controller: _searchCtrl,
                  hint: 'Search role, company, or skill',
                  prefixIcon: Icons.search_rounded,
                  textInputAction: TextInputAction.search,
                  onChanged: _onQueryChanged,
                  onSubmitted: _submit,
                  suffix: _searchCtrl.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: _clearSearch,
                          icon: const Icon(Icons.close_rounded, size: 18),
                        ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return TagChip(
                        label: category,
                        selected: state.category == category,
                        dense: true,
                        onTap: () => ref
                            .read(jobsControllerProvider.notifier)
                            .setCategory(category),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (state.loading && jobs.isNotEmpty)
            const LinearProgressIndicator(
              minHeight: 2.4,
              color: AppColors.primary,
            ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: _body(context, isDark, state, jobs),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(
    BuildContext context,
    bool isDark,
    JobsState state,
    List<Job> jobs,
  ) {
    if (state.loading && jobs.isEmpty) {
      return const SkeletonList(
        count: 4,
        height: 152,
        padding: EdgeInsets.all(20),
      );
    }
    if (state.error != null && jobs.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ErrorState(
          message: state.error!,
          onRetry: () => ref.read(jobsControllerProvider.notifier).refresh(),
        ),
      );
    }
    if (jobs.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: EmptyState(
          icon: Icons.work_off_outlined,
          title: 'No roles matched that search',
          message: 'Try a broader keyword or switch to a different category.',
          actionLabel: 'Clear filters',
          onAction: () =>
              ref.read(jobsControllerProvider.notifier).clearFilters(),
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(jobsControllerProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          Row(
            children: [
              Text(
                '${jobs.length} ${jobs.length == 1 ? 'role' : 'roles'} found',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : AppColors.inkMuted,
                ),
              ),
              const Spacer(),
              if (state.lastUpdated != null)
                Text(
                  'Updated ${Formatters.timeAgo(state.lastUpdated)}',
                  style: TextStyle(
                    fontSize: 9.5,
                    color: isDark ? Colors.white38 : AppColors.inkMuted,
                  ),
                ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: state.loading
                    ? null
                    : () => ref.read(jobsControllerProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (final job in jobs) ...[
            JobCard(
              job: job,
              saved: state.isSaved(job.id),
              onTap: () => context.push('/app/jobs/${job.id}'),
              onToggleSaved: () =>
                  ref.read(jobsControllerProvider.notifier).toggleSaved(job),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Live remote roles from Remotive · updated continuously',
              style: TextStyle(
                fontSize: 9,
                color: isDark
                    ? Colors.white30
                    : AppColors.inkMuted.withValues(alpha: .7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
