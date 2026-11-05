import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_widgets.dart';
import '../domain/job.dart';

class JobCard extends StatelessWidget {
  const JobCard({
    super.key,
    required this.job,
    this.saved = false,
    this.onTap,
    this.onToggleSaved,
    this.compact = false,
  });

  final Job job;
  final bool saved;
  final VoidCallback? onTap;
  final VoidCallback? onToggleSaved;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return AppCard(
      padding: EdgeInsets.all(compact ? 16 : 18),
      onTap: onTap,
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
                size: compact ? 42 : 48,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 14 : 15.5,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.2,
                        color: isDark ? Colors.white : AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${job.company}  •  ${job.locationLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white54 : AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: onToggleSaved,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                icon: Icon(
                  saved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  size: 20,
                  color: saved
                      ? AppColors.primary
                      : (isDark ? Colors.white38 : AppColors.inkMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _MetaPill(icon: Icons.work_outline_rounded, label: job.jobType),
              _MetaPill(
                icon: Icons.schedule_rounded,
                label: Formatters.timeAgo(job.publishedAt).isEmpty
                    ? job.categoryLabel
                    : Formatters.timeAgo(job.publishedAt),
              ),
              if (job.salary.trim().isNotEmpty)
                _MetaPill(icon: Icons.payments_outlined, label: job.salary),
            ],
          ),
          if (compact && job.tags.isNotEmpty) ...[
            const SizedBox(height: 11),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: job.tags
                  .take(3)
                  .map((tag) => TagChip(label: tag, dense: true))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class JobMiniCard extends StatelessWidget {
  const JobMiniCard({
    super.key,
    required this.job,
    this.saved = false,
    this.onTap,
    this.onToggleSaved,
  });

  final Job job;
  final bool saved;
  final VoidCallback? onTap;
  final VoidCallback? onToggleSaved;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return SizedBox(
      width: 254,
      child: AppCard(
        padding: const EdgeInsets.all(16),
        onTap: onTap,
        shadow: true,
        border: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CompanyLogo(
                  company: job.company,
                  logoUrl: job.companyLogo,
                  size: 42,
                ),
                const Spacer(),
                InkWell(
                  onTap: onToggleSaved,
                  borderRadius: BorderRadius.circular(99),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      saved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      size: 19,
                      color: saved
                          ? AppColors.primary
                          : (isDark ? Colors.white38 : AppColors.inkMuted),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              job.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.25,
                fontWeight: FontWeight.w800,
                letterSpacing: -.2,
                color: isDark ? Colors.white : AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              job.company,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : AppColors.inkMuted,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.place_outlined,
                  size: 13,
                  color: isDark ? Colors.white38 : AppColors.inkMuted,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    job.locationLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white38 : AppColors.inkMuted,
                    ),
                  ),
                ),
                Text(
                  job.jobType,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CompanyLogo extends StatelessWidget {
  const CompanyLogo({
    super.key,
    required this.company,
    required this.logoUrl,
    this.size = 46,
  });

  final String company;
  final String logoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(size * .28),
      ),
      child: Text(
        company.isEmpty ? 'V' : company.substring(0, 1).toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * .4,
        ),
      ),
    );
    if (logoUrl.trim().isEmpty) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * .28),
      child: Image.network(
        logoUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => fallback,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: size,
            height: size,
            color: Theme.of(context).dividerColor,
          );
        },
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: .055)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: isDark ? Colors.white38 : AppColors.inkMuted,
          ),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : AppColors.inkMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
