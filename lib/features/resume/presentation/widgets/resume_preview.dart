import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/app_user.dart';
import '../../domain/resume_models.dart';

class ResumePreview extends StatelessWidget {
  const ResumePreview({super.key, required this.resume});

  final Resume resume;

  Color get _accent {
    return switch (resume.template) {
      'Minimal' => const Color(0xFF111827),
      'Executive' => const Color(0xFF1E3A5F),
      _ => AppColors.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .12),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (resume.template == 'Modern')
              Container(
                height: 8,
                decoration: const BoxDecoration(
                  gradient: AppColors.heroGradient,
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 26, 26, 34),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(),
                  const SizedBox(height: 18),
                  Container(height: 1.2, color: _accent.withValues(alpha: .25)),
                  if (resume.summary.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _sectionTitle('Professional Summary'),
                    const SizedBox(height: 7),
                    Text(
                      resume.summary,
                      style: const TextStyle(
                        color: Color(0xFF374151),
                        fontSize: 11,
                        height: 1.6,
                      ),
                    ),
                  ],
                  if (resume.skills.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _sectionTitle('Skills'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: resume.skills
                          .map(
                            (skill) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _accent.withValues(alpha: .07),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                skill,
                                style: TextStyle(
                                  color: _accent,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  if (resume.experience.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _sectionTitle('Experience'),
                    const SizedBox(height: 9),
                    ...resume.experience.map(_experience),
                  ],
                  if (resume.education.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _sectionTitle('Education'),
                    const SizedBox(height: 9),
                    ...resume.education.map(_education),
                  ],
                  if (resume.fullName.isEmpty &&
                      resume.summary.isEmpty &&
                      resume.skills.isEmpty &&
                      resume.experience.isEmpty &&
                      resume.education.isEmpty) ...[
                    const SizedBox(height: 40),
                    Center(
                      child: Text(
                        'Your resume preview will appear here.',
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: .3),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    if (resume.template == 'Minimal') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            resume.fullName.isEmpty ? 'Your Name' : resume.fullName,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 26,
              height: 1.05,
              fontWeight: FontWeight.w800,
              letterSpacing: -.8,
            ),
          ),
          if (resume.targetRole.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              resume.targetRole,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 8),
          _contactLine(),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resume.fullName.isEmpty ? 'Your Name' : resume.fullName,
                    style: TextStyle(
                      color: _accent,
                      fontSize: 26,
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.8,
                    ),
                  ),
                  if (resume.targetRole.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      resume.targetRole,
                      style: const TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (resume.template == 'Executive')
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.workspace_premium_outlined,
                  color: Colors.white,
                  size: 18,
                ),
              ),
          ],
        ),
        const SizedBox(height: 9),
        _contactLine(),
      ],
    );
  }

  Widget _contactLine() {
    final items = [
      resume.email,
      resume.phone,
      resume.location,
      resume.linkedin,
    ].where((item) => item.trim().isNotEmpty).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 3,
      children: [
        for (final item in items)
          Text(
            item,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 8.5,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 11,
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: _accent,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(height: 1, color: _accent.withValues(alpha: .12)),
        ),
      ],
    );
  }

  Widget _experience(ExperienceEntry exp) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${exp.role}${exp.company.isEmpty ? '' : ' · ${exp.company}'}',
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                exp.dateRange,
                style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (exp.description.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            ...exp.description
                .split('\n')
                .where((line) => line.trim().isNotEmpty)
                .map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: _accent.withValues(alpha: .6),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            line.replaceFirst(RegExp(r'^[•*-]\s*'), ''),
                            style: const TextStyle(
                              color: Color(0xFF4B5563),
                              fontSize: 9.5,
                              height: 1.5,
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
    );
  }

  Widget _education(EducationEntry edu) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              '${edu.degree}${edu.field.isEmpty ? '' : ' in ${edu.field}'}${edu.school.isEmpty ? '' : ' · ${edu.school}'}',
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            edu.dateRange,
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 8.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
