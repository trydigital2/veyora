import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../application/resume_controller.dart';
import '../../domain/resume_models.dart';

class AnalysisResultScreen extends ConsumerWidget {
  const AnalysisResultScreen({super.key, required this.analysisId});

  final String analysisId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(resumeControllerProvider);
    final analysis = state.analysisById(analysisId);
    if (analysis == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analysis report')),
        body: state.loading
            ? const LoadingView(label: 'Loading your report')
            : EmptyState(
                icon: Icons.search_off_rounded,
                title: 'Report not found',
                message: 'This analysis may have been deleted.',
                actionLabel: 'Analyze a resume',
                onAction: () => context.push('/app/analyzer'),
              ),
      );
    }

    final isDark = AppTheme.isDark(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis report'),
        actions: [
          IconButton(
            onPressed: () => context.push('/app/analyzer'),
            icon: const Icon(Icons.refresh_rounded, size: 21),
            tooltip: 'Analyze again',
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
                _Hero(analysis: analysis),
                const SizedBox(height: 22),
                const SectionHeader(
                  title: 'Score breakdown',
                  subtitle: 'Five signals that shape your result',
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: SizedBox(
                    height: 176,
                    child: _BreakdownChart(analysis: analysis),
                  ),
                ),
                const SizedBox(height: 22),
                _InsightCard(
                  title: 'Strengths',
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.success,
                  items: analysis.strengths,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _InsightCard(
                  title: 'What to fix',
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  items: analysis.weaknesses,
                  isDark: isDark,
                ),
                if (analysis.missingSkills.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  const SectionHeader(
                    title: 'Missing skills',
                    subtitle: 'High-signal keywords for your target role',
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: analysis.missingSkills
                          .map(
                            (skill) => TagChip(
                              label: skill,
                              icon: Icons.add_rounded,
                              onTap: () => AppSnack.show(
                                context,
                                'Add “$skill” to your resume with a concrete example.',
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                const SectionHeader(
                  title: 'AI improvement plan',
                  subtitle: 'Prioritized, specific next steps',
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    children: [
                      for (
                        var index = 0;
                        index < analysis.suggestions.length;
                        index++
                      )
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: index == analysis.suggestions.length - 1
                                ? 0
                                : 14,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: isDark ? .18 : .08,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  analysis.suggestions[index],
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.55,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.white70
                                        : AppColors.ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (analysis.detectedSkills.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  const SectionHeader(
                    title: 'Skills detected',
                    subtitle: 'Keywords our engine found in your resume',
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    child: Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: analysis.detectedSkills
                          .map((skill) => TagChip(label: skill, dense: true))
                          .toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 26),
                PrimaryButton(
                  label: 'Improve in Resume Builder',
                  icon: Icons.edit_document,
                  onPressed: () => context.push('/app/builder'),
                ),
                const SizedBox(height: 10),
                SecondaryButton(
                  label: 'Check a job match',
                  icon: Icons.track_changes_rounded,
                  onPressed: () => context.push('/app/job-matcher'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.analysis});

  final ResumeAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      child: Column(
        children: [
          Row(
            children: [
              ScoreRing(
                score: analysis.overallScore,
                size: 124,
                stroke: 10,
                label: analysis.grade,
                color: Colors.white,
                textColor: Colors.white,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      analysis.targetRole.isEmpty
                          ? 'General resume'
                          : analysis.targetRole,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.5,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      analysis.resumeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: .65),
                      ),
                    ),
                    const SizedBox(height: 13),
                    Row(
                      children: [
                        _HeroStat(label: 'ATS', value: '${analysis.atsScore}'),
                        const SizedBox(width: 14),
                        _HeroStat(
                          label: 'Words',
                          value: '${analysis.wordCount}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      Formatters.timeAgo(analysis.createdAt),
                      style: TextStyle(
                        fontSize: 9.5,
                        color: Colors.white.withValues(alpha: .5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Text(
              analysis.overallScore >= 80
                  ? 'Strong foundation. Tailor keywords for each role and keep the momentum.'
                  : analysis.overallScore >= 60
                  ? 'A solid base with clear upside. Focus on the high-impact fixes below.'
                  : 'There is meaningful room to improve. Start with the score breakdown and missing skills.',
              style: TextStyle(
                fontSize: 11,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: .85),
              ),
            ),
          ),
        ],
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
    return Row(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: .6),
          ),
        ),
      ],
    );
  }
}

class _BreakdownChart extends StatelessWidget {
  const _BreakdownChart({required this.analysis});

  final ResumeAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final values = [
      ('Skills', analysis.skillsScore, AppColors.primary),
      ('Experience', analysis.experienceScore, const Color(0xFF0EA5A4)),
      ('Education', analysis.educationScore, const Color(0xFF3B82F6)),
      ('Format', analysis.formattingScore, const Color(0xFFF59E0B)),
      ('ATS', analysis.atsScore, const Color(0xFFEC4899)),
    ];
    return BarChart(
      BarChartData(
        maxY: 100,
        minY: 0,
        alignment: BarChartAlignment.spaceAround,
        barGroups: [
          for (var index = 0; index < values.length; index++)
            BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: values[index].$2.toDouble(),
                  width: 20,
                  borderRadius: BorderRadius.circular(6),
                  color: values[index].$3,
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: 100,
                    color: isDark
                        ? Colors.white.withValues(alpha: .05)
                        : AppColors.primary.withValues(alpha: .055),
                  ),
                ),
              ],
            ),
        ],
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= values.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    values[index].$1,
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : AppColors.inkMuted,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => isDark ? AppColors.darkCard : AppColors.ink,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${values[group.x].$1}\n${rod.toY.round()}/100',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
    required this.isDark,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(
                icon: icon,
                size: 34,
                color: color.withValues(alpha: isDark ? .18 : .1),
                iconColor: color,
                radius: 10,
              ),
              const SizedBox(width: 9),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Icon(icon, size: 13, color: color),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : AppColors.inkMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
