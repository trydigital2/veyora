import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../application/resume_controller.dart';
import '../../domain/resume_models.dart';

class ResumeHubScreen extends ConsumerStatefulWidget {
  const ResumeHubScreen({super.key});

  @override
  ConsumerState<ResumeHubScreen> createState() => _ResumeHubScreenState();
}

class _ResumeHubScreenState extends ConsumerState<ResumeHubScreen> {
  String? _sharingId;

  Future<void> _exportResume(Resume resume) async {
    setState(() => _sharingId = resume.id);
    try {
      final bytes = await ref
          .read(documentServiceProvider)
          .buildResumePdf(resume);
      await ref
          .read(documentServiceProvider)
          .sharePdf(
            bytes: bytes,
            filename: '${resume.fullName.replaceAll(' ', '_')}_Resume.pdf',
          );
    } catch (_) {
      if (mounted) {
        AppSnack.show(context, 'Could not export this resume.', error: true);
      }
    } finally {
      if (mounted) setState(() => _sharingId = null);
    }
  }

  Future<void> _deleteResume(Resume resume) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete resume?',
      message:
          '“${resume.title}” will be removed from this device. Analyses are kept.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await ref.read(resumeControllerProvider.notifier).deleteResume(resume.id);
    if (mounted) AppSnack.show(context, 'Resume deleted.');
  }

  Future<void> _deleteAnalysis(String id) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete analysis?',
      message: 'This report will be removed from your history.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await ref.read(resumeControllerProvider.notifier).deleteAnalysis(id);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resumeControllerProvider);
    final isDark = AppTheme.isDark(context);
    final latest = state.latestAnalysis;

    return RefreshIndicator(
      onRefresh: () => ref.read(resumeControllerProvider.notifier).load(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 30),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Resume Studio',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -.9,
                                  color: isDark ? Colors.white : AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Analyze, build, and tailor your story.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.white54
                                      : AppColors.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton.filled(
                          onPressed: () => context.push('/app/builder'),
                          icon: const Icon(Icons.add_rounded, size: 22),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(46, 46),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                  child: _ScoreCard(
                    analysis: latest,
                    onView: latest == null
                        ? () => context.push('/app/analyzer')
                        : () => context.push('/app/analysis/${latest.id}'),
                    onAnalyze: () => context.push('/app/analyzer'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        title: 'AI toolkit',
                        subtitle: 'Every tool you need to stand out',
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.42,
                        children: [
                          _ToolCard(
                            icon: Icons.analytics_outlined,
                            title: 'Resume Analyzer',
                            subtitle: 'Score & fix',
                            color: AppColors.primary,
                            onTap: () => context.push('/app/analyzer'),
                          ),
                          _ToolCard(
                            icon: Icons.edit_document,
                            title: 'Resume Builder',
                            subtitle: 'Create & export',
                            color: const Color(0xFF0EA5A4),
                            onTap: () => context.push('/app/builder'),
                          ),
                          _ToolCard(
                            icon: Icons.track_changes_rounded,
                            title: 'Job Matcher',
                            subtitle: 'Check fit',
                            color: const Color(0xFFF59E0B),
                            onTap: () => context.push('/app/job-matcher'),
                          ),
                          _ToolCard(
                            icon: Icons.auto_awesome_rounded,
                            title: 'Cover Letters',
                            subtitle: 'Write in seconds',
                            color: const Color(0xFFEC4899),
                            onTap: () => context.push('/app/cover-letter'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      SectionHeader(
                        title: 'My resumes',
                        subtitle: state.resumes.isEmpty
                            ? 'Build your first AI-assisted resume'
                            : '${state.resumes.length} saved resume${state.resumes.length == 1 ? '' : 's'}',
                        actionLabel: 'New',
                        onAction: () => context.push('/app/builder'),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                if (state.loading && state.resumes.isEmpty)
                  const SkeletonList(count: 2, height: 92)
                else if (state.resumes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: AppCard(
                      child: EmptyState(
                        icon: Icons.description_outlined,
                        title: 'No resumes yet',
                        message:
                            'Create a polished resume with AI summaries and export it as a PDF.',
                        compact: true,
                        actionLabel: 'Build resume',
                        onAction: () => context.push('/app/builder'),
                      ),
                    ),
                  )
                else
                  ...state.resumes.map(
                    (resume) => Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: _ResumeRow(
                        resume: resume,
                        sharing: _sharingId == resume.id,
                        onTap: () =>
                            context.push('/app/builder?id=${resume.id}'),
                        onExport: () => _exportResume(resume),
                        onDelete: () => _deleteResume(resume),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: 'Analysis history',
                        subtitle:
                            '${state.analyses.length} report${state.analyses.length == 1 ? '' : 's'}',
                      ),
                      const SizedBox(height: 12),
                      if (state.analyses.isEmpty)
                        AppCard(
                          child: EmptyState(
                            icon: Icons.insights_outlined,
                            title: 'No analyses yet',
                            message:
                                'Upload a PDF or DOCX resume to see your score and gaps.',
                            compact: true,
                            actionLabel: 'Analyze resume',
                            onAction: () => context.push('/app/analyzer'),
                          ),
                        )
                      else
                        ...state.analyses
                            .take(6)
                            .map(
                              (analysis) => Padding(
                                padding: const EdgeInsets.only(bottom: 9),
                                child: _AnalysisRow(
                                  analysis: analysis,
                                  onTap: () => context.push(
                                    '/app/analysis/${analysis.id}',
                                  ),
                                  onDelete: () => _deleteAnalysis(analysis.id),
                                ),
                              ),
                            ),
                      const SizedBox(height: 18),
                      SectionHeader(
                        title: 'Job matches',
                        subtitle:
                            '${state.matches.length} saved match${state.matches.length == 1 ? '' : 'es'}',
                        actionLabel: 'New match',
                        onAction: () => context.push('/app/job-matcher'),
                      ),
                      const SizedBox(height: 12),
                      if (state.matches.isEmpty)
                        AppCard(
                          child: EmptyState(
                            icon: Icons.track_changes_rounded,
                            title: 'No matches saved',
                            message:
                                'Paste a job description to see compatibility and missing skills.',
                            compact: true,
                            actionLabel: 'Check a job',
                            onAction: () => context.push('/app/job-matcher'),
                          ),
                        )
                      else
                        ...state.matches
                            .take(4)
                            .map(
                              (match) => Padding(
                                padding: const EdgeInsets.only(bottom: 9),
                                child: _MatchRow(
                                  match: match,
                                  onTap: () => _showMatch(context, match),
                                ),
                              ),
                            ),
                      const SizedBox(height: 18),
                      SectionHeader(
                        title: 'Cover letters',
                        subtitle: '${state.coverLetters.length} saved',
                        actionLabel: 'Write',
                        onAction: () => context.push('/app/cover-letter'),
                      ),
                      const SizedBox(height: 12),
                      if (state.coverLetters.isEmpty)
                        AppCard(
                          child: EmptyState(
                            icon: Icons.mail_outline_rounded,
                            title: 'No cover letters yet',
                            message:
                                'Generate a tailored letter from your resume and a job description.',
                            compact: true,
                            actionLabel: 'Write a letter',
                            onAction: () => context.push('/app/cover-letter'),
                          ),
                        )
                      else
                        ...state.coverLetters
                            .take(5)
                            .map(
                              (letter) => Padding(
                                padding: const EdgeInsets.only(bottom: 9),
                                child: _CoverLetterRow(
                                  letter: letter,
                                  onTap: () => context.push(
                                    '/app/cover-letter?id=${letter.id}',
                                  ),
                                  onCopy: () =>
                                      copyToClipboard(context, letter.content),
                                  onDelete: () async {
                                    final sure = await showConfirmDialog(
                                      context,
                                      title: 'Delete cover letter?',
                                      message: 'This letter will be removed.',
                                      confirmLabel: 'Delete',
                                      destructive: true,
                                    );
                                    if (sure) {
                                      await ref
                                          .read(
                                            resumeControllerProvider.notifier,
                                          )
                                          .deleteCoverLetter(letter.id);
                                    }
                                  },
                                ),
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

  void _showMatch(BuildContext context, JobMatchResult match) {
    showAppSheet(
      context,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ScoreRing(
                    score: match.score,
                    size: 86,
                    stroke: 8,
                    label: 'Match',
                    suffix: '%',
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          match.jobTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          match.company,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                match.summary,
                style: const TextStyle(fontSize: 13, height: 1.55),
              ),
              if (match.matchedSkills.isNotEmpty) ...[
                const SizedBox(height: 18),
                const SectionHeader(title: 'Matched skills'),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: match.matchedSkills
                      .map((s) => TagChip(label: s, selected: true))
                      .toList(),
                ),
              ],
              if (match.missingSkills.isNotEmpty) ...[
                const SizedBox(height: 18),
                const SectionHeader(title: 'Skill gaps'),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: match.missingSkills
                      .map((s) => TagChip(label: s, icon: Icons.add_rounded))
                      .toList(),
                ),
              ],
              const SizedBox(height: 18),
              const SectionHeader(title: 'Next steps'),
              const SizedBox(height: 8),
              ...match.suggestions.map(
                (suggestion) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.arrow_right_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          suggestion,
                          style: const TextStyle(fontSize: 12, height: 1.45),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({
    required this.analysis,
    required this.onView,
    required this.onAnalyze,
  });

  final ResumeAnalysis? analysis;
  final VoidCallback onView;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    if (analysis == null) {
      return AppCard(
        child: EmptyState(
          icon: Icons.analytics_outlined,
          title: 'Your resume score is waiting',
          message:
              'Upload a PDF or DOCX resume for an instant score, ATS check, and skill gaps.',
          compact: true,
          actionLabel: 'Analyze resume',
          onAction: onAnalyze,
        ),
      );
    }
    return GradientCard(
      onTap: onView,
      child: Row(
        children: [
          ScoreRing(
            score: analysis!.overallScore,
            size: 116,
            stroke: 10,
            label: 'Overall',
            color: Colors.white,
            textColor: Colors.white,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
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
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        analysis!.grade.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_outward_rounded,
                      size: 18,
                      color: Colors.white.withValues(alpha: .7),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  analysis!.targetRole.isEmpty
                      ? 'Latest resume report'
                      : analysis!.targetRole,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${analysis!.resumeName}  •  ${Formatters.timeAgo(analysis!.createdAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: .62),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _ScorePill(label: 'ATS', value: analysis!.atsScore),
                    const SizedBox(width: 8),
                    _ScorePill(label: 'Skills', value: analysis!.skillsScore),
                    const SizedBox(width: 8),
                    _ScorePill(
                      label: 'Format',
                      value: analysis!.formattingScore,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: .6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(15),
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
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isDark ? .18 : .09),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(icon, size: 19, color: color),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_outward_rounded,
                    size: 15,
                    color: isDark ? Colors.white24 : AppColors.inkMuted,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white38 : AppColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResumeRow extends StatelessWidget {
  const _ResumeRow({
    required this.resume,
    required this.sharing,
    required this.onTap,
    required this.onExport,
    required this.onDelete,
  });

  final Resume resume;
  final bool sharing;
  final VoidCallback onTap;
  final VoidCallback onExport;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return AppCard(
      padding: const EdgeInsets.all(15),
      onTap: onTap,
      child: Row(
        children: [
          IconBadge(
            icon: Icons.description_outlined,
            size: 44,
            color: AppColors.primary.withValues(alpha: isDark ? .2 : .1),
            iconColor: AppColors.primary,
            radius: 13,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resume.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${resume.template}  •  Updated ${Formatters.timeAgo(resume.updatedAt)}',
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
          if (sharing)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_horiz_rounded,
                size: 20,
                color: isDark ? Colors.white38 : AppColors.inkMuted,
              ),
              onSelected: (value) {
                if (value == 'export') onExport();
                if (value == 'edit') onTap();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'export', child: Text('Export PDF')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
        ],
      ),
    );
  }
}

class _AnalysisRow extends StatelessWidget {
  const _AnalysisRow({
    required this.analysis,
    required this.onTap,
    required this.onDelete,
  });

  final ResumeAnalysis analysis;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          ScoreRing(
            score: analysis.overallScore,
            size: 54,
            stroke: 5,
            showLabel: false,
            suffix: '',
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  analysis.resumeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${analysis.targetRole.isEmpty ? 'General' : analysis.targetRole}  •  ${Formatters.timeAgo(analysis.createdAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? Colors.white38 : AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 19,
              color: isDark ? Colors.white30 : AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchRow extends StatelessWidget {
  const _MatchRow({required this.match, required this.onTap});

  final JobMatchResult match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.scoreColors(match.score),
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '${match.score}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match.jobTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${match.company}  •  ${Formatters.timeAgo(match.createdAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? Colors.white38 : AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: isDark ? Colors.white24 : AppColors.inkMuted,
          ),
        ],
      ),
    );
  }
}

class _CoverLetterRow extends StatelessWidget {
  const _CoverLetterRow({
    required this.letter,
    required this.onTap,
    required this.onCopy,
    required this.onDelete,
  });

  final CoverLetter letter;
  final VoidCallback onTap;
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          IconBadge(
            icon: Icons.mail_outline_rounded,
            size: 44,
            color: const Color(0xFFEC4899).withValues(alpha: isDark ? .2 : .1),
            iconColor: const Color(0xFFEC4899),
            radius: 13,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  letter.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${letter.company.isEmpty ? letter.style : '${letter.company}  •  ${letter.style}'}  •  ${Formatters.timeAgo(letter.createdAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? Colors.white38 : AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCopy,
            icon: Icon(
              Icons.copy_rounded,
              size: 17,
              color: isDark ? Colors.white38 : AppColors.inkMuted,
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: isDark ? Colors.white30 : AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}
