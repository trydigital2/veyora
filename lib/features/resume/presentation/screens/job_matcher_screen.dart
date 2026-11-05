import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../jobs/domain/job.dart';
import '../../application/resume_controller.dart';
import '../../domain/resume_models.dart';

class JobMatcherScreen extends ConsumerStatefulWidget {
  const JobMatcherScreen({super.key, this.prefillJob});

  final Job? prefillJob;

  @override
  ConsumerState<JobMatcherScreen> createState() => _JobMatcherScreenState();
}

class _JobMatcherScreenState extends ConsumerState<JobMatcherScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  String? _resumeId;
  bool _matching = false;
  JobMatchResult? _result;

  @override
  void initState() {
    super.initState();
    final job = widget.prefillJob;
    if (job != null) {
      _titleCtrl.text = job.title;
      _companyCtrl.text = job.company;
      _descriptionCtrl.text = stripHtml(job.description);
    }
    _resumeId = ref.read(resumeControllerProvider).primaryResume?.id;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _companyCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _runMatch(Resume resume) async {
    FocusScope.of(context).unfocus();
    setState(() => _matching = true);
    try {
      final result = await ref
          .read(resumeControllerProvider.notifier)
          .match(
            resumeText: resume.plainText,
            jobDescription: _descriptionCtrl.text.trim(),
            jobTitle: _titleCtrl.text.trim().isEmpty
                ? 'Target role'
                : _titleCtrl.text.trim(),
            company: _companyCtrl.text.trim().isEmpty
                ? 'Company'
                : _companyCtrl.text.trim(),
          );
      if (!mounted) return;
      setState(() {
        _result = result;
        _matching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _matching = false);
      AppSnack.show(
        context,
        'Could not run the match. Please try again.',
        error: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final state = ref.watch(resumeControllerProvider);
    final resumes = state.resumes;
    final selectedResume = resumes.isEmpty
        ? null
        : resumes.firstWhere(
            (resume) => resume.id == _resumeId,
            orElse: () => resumes.first,
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job matcher'),
        actions: [
          IconButton(
            onPressed: () => context.push('/app/jobs'),
            icon: const Icon(Icons.work_outline_rounded, size: 21),
            tooltip: 'Browse live jobs',
          ),
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
                  child: Row(
                    children: [
                      const IconBadge(
                        icon: Icons.track_changes_rounded,
                        size: 46,
                        color: Colors.white24,
                        iconColor: Colors.white,
                        radius: 14,
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'See how you stack up',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.4,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'We compare your saved resume against the role and surface the gaps.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: .65),
                                fontSize: 10.5,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (resumes.isEmpty)
                  AppCard(
                    child: Column(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 34,
                          color: AppColors.primary.withValues(alpha: .7),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Build a resume first',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'The matcher compares your resume text with the job description. Create one in the resume studio to begin.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.5,
                            color: isDark ? Colors.white54 : AppColors.inkMuted,
                          ),
                        ),
                        const SizedBox(height: 14),
                        PrimaryButton(
                          label: 'Create a resume',
                          icon: Icons.add_rounded,
                          onPressed: () => context.push('/app/builder'),
                          height: 48,
                        ),
                      ],
                    ),
                  )
                else ...[
                  const SectionHeader(
                    title: 'Resume to compare',
                    subtitle: 'We use the full text of this resume',
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final resume in resumes)
                        TagChip(
                          label: resume.title,
                          selected: selectedResume?.id == resume.id,
                          icon: selectedResume?.id == resume.id
                              ? Icons.check_circle_rounded
                              : Icons.description_outlined,
                          onTap: () => setState(() => _resumeId = resume.id),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Form(
                    key: _formKey,
                    child: AppCard(
                      child: Column(
                        children: [
                          AppTextField(
                            controller: _titleCtrl,
                            label: 'Job title',
                            hint: 'e.g. Senior Product Designer',
                            prefixIcon: Icons.badge_outlined,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: _companyCtrl,
                            label: 'Company',
                            hint: 'e.g. Northwind Labs',
                            prefixIcon: Icons.business_outlined,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: _descriptionCtrl,
                            label: 'Job description',
                            hint:
                                'Paste the full job posting here. Include responsibilities and requirements.',
                            maxLines: 12,
                            validator: Validators.jobDescription,
                            helperText:
                                'At least 80 characters gives the most reliable match.',
                          ),
                          const SizedBox(height: 16),
                          PrimaryButton(
                            label: _result == null
                                ? 'Analyze match'
                                : 'Refresh match',
                            icon: Icons.track_changes_rounded,
                            loading: _matching,
                            onPressed: selectedResume == null || _matching
                                ? null
                                : () {
                                    if (_formKey.currentState!.validate()) {
                                      _runMatch(selectedResume);
                                    }
                                  },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (_result != null) ...[
                  const SizedBox(height: 24),
                  _MatchResultCard(
                    result: _result!,
                    onCoverLetter: () => context.push(
                      '/app/cover-letter',
                      extra: {
                        'title': _titleCtrl.text.trim(),
                        'company': _companyCtrl.text.trim(),
                        'description': _descriptionCtrl.text.trim(),
                      },
                    ),
                    onBrowseJobs: () => context.push('/app/jobs'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchResultCard extends StatelessWidget {
  const _MatchResultCard({
    required this.result,
    required this.onCoverLetter,
    required this.onBrowseJobs,
  });

  final JobMatchResult result;
  final VoidCallback onCoverLetter;
  final VoidCallback onBrowseJobs;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final color = AppColors.scoreColors(result.score).last;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Your match report',
          subtitle: 'Saved to your workspace automatically',
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            children: [
              Row(
                children: [
                  ScoreRing(
                    score: result.score,
                    size: 108,
                    stroke: 9,
                    label: 'Match',
                    suffix: '%',
                    color: color,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.jobTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.4,
                            color: isDark ? Colors.white : AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          result.company,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white54 : AppColors.inkMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          result.score >= 80
                              ? 'Excellent alignment'
                              : result.score >= 65
                              ? 'Strong potential'
                              : result.score >= 45
                              ? 'Worth tailoring'
                              : 'Stretch opportunity',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? .12 : .07),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  result.summary,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.55,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : AppColors.ink,
                  ),
                ),
              ),
              if (result.matchedSkills.isNotEmpty) ...[
                const SizedBox(height: 16),
                _SkillBlock(
                  title: 'Already matched',
                  icon: Icons.check_circle_rounded,
                  color: AppColors.success,
                  skills: result.matchedSkills,
                ),
              ],
              if (result.missingSkills.isNotEmpty) ...[
                const SizedBox(height: 14),
                _SkillBlock(
                  title: 'Keywords to add',
                  icon: Icons.add_circle_outline_rounded,
                  color: AppColors.warning,
                  skills: result.missingSkills,
                ),
              ],
              if (result.suggestions.isNotEmpty) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'How to improve your odds',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ...result.suggestions.map(
                  (suggestion) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            suggestion,
                            style: TextStyle(
                              fontSize: 10.5,
                              height: 1.5,
                              color: isDark
                                  ? Colors.white60
                                  : AppColors.inkMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        PrimaryButton(
          label: 'Write a tailored cover letter',
          icon: Icons.edit_note_rounded,
          onPressed: onCoverLetter,
        ),
        const SizedBox(height: 9),
        SecondaryButton(
          label: 'Browse roles you match',
          icon: Icons.work_outline_rounded,
          onPressed: onBrowseJobs,
        ),
      ],
    );
  }
}

class _SkillBlock extends StatelessWidget {
  const _SkillBlock({
    required this.title,
    required this.icon,
    required this.color,
    required this.skills,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> skills;

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
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: skills
              .map((skill) => TagChip(label: skill, dense: true, color: color))
              .toList(),
        ),
      ],
    );
  }
}
