import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../auth/domain/app_user.dart';
import '../../application/resume_controller.dart';
import '../../domain/resume_models.dart';
import '../widgets/resume_preview.dart';

class ResumeBuilderScreen extends ConsumerStatefulWidget {
  const ResumeBuilderScreen({super.key, this.resumeId});

  final String? resumeId;

  @override
  ConsumerState<ResumeBuilderScreen> createState() =>
      _ResumeBuilderScreenState();
}

class _ResumeBuilderScreenState extends ConsumerState<ResumeBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _linkedinCtrl = TextEditingController();
  final _summaryCtrl = TextEditingController();
  final _skillCtrl = TextEditingController();

  final _uuid = const Uuid();
  String? _resumeId;
  DateTime? _createdAt;
  String _template = 'Modern';
  List<String> _skills = [];
  List<ExperienceEntry> _experience = [];
  List<EducationEntry> _education = [];
  bool _preview = false;
  bool _saving = false;
  bool _exporting = false;
  bool _generatingSummary = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).user;
    final existing = widget.resumeId == null
        ? null
        : ref.read(resumeControllerProvider).resumeById(widget.resumeId!);
    _resumeId = existing?.id;
    _createdAt = existing?.createdAt;
    _template = existing?.template ?? 'Modern';
    _skills = [...(existing?.skills ?? user?.skills ?? const <String>[])];
    _experience = [
      ...(existing?.experience ??
          user?.experience ??
          const <ExperienceEntry>[]),
    ];
    _education = [
      ...(existing?.education ?? user?.education ?? const <EducationEntry>[]),
    ];
    _titleCtrl.text = existing?.title ?? '';
    _nameCtrl.text = existing?.fullName ?? user?.name ?? '';
    _roleCtrl.text = existing?.targetRole ?? user?.targetRole ?? '';
    _emailCtrl.text = existing?.email ?? user?.email ?? '';
    _phoneCtrl.text = existing?.phone ?? user?.phone ?? '';
    _locationCtrl.text = existing?.location ?? user?.location ?? '';
    _linkedinCtrl.text = existing?.linkedin ?? '';
    _summaryCtrl.text = existing?.summary ?? '';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _nameCtrl.dispose();
    _roleCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _linkedinCtrl.dispose();
    _summaryCtrl.dispose();
    _skillCtrl.dispose();
    super.dispose();
  }

  Resume _compose() {
    final now = DateTime.now();
    final role = _roleCtrl.text.trim();
    return Resume(
      id: _resumeId ?? _uuid.v4(),
      title: _titleCtrl.text.trim().isEmpty
          ? (role.isEmpty ? 'My Resume' : '$role Resume')
          : _titleCtrl.text.trim(),
      fullName: _nameCtrl.text.trim(),
      targetRole: role,
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      linkedin: _linkedinCtrl.text.trim(),
      summary: _summaryCtrl.text.trim(),
      template: _template,
      skills: List.unmodifiable(_skills),
      education: List.unmodifiable(_education),
      experience: List.unmodifiable(_experience),
      createdAt: _createdAt ?? now,
      updatedAt: now,
    );
  }

  Future<Resume?> _persist({bool showFeedback = true}) async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _preview = false);
      return null;
    }
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      final resume = _compose();
      await ref.read(resumeControllerProvider.notifier).saveResume(resume);
      if (!mounted) return resume;
      setState(() {
        _resumeId = resume.id;
        _createdAt = resume.createdAt;
        _saving = false;
      });
      if (showFeedback) {
        AppSnack.show(context, 'Resume saved to your workspace.');
      }
      return resume;
    } catch (_) {
      if (!mounted) return null;
      setState(() => _saving = false);
      AppSnack.show(
        context,
        'Could not save your resume. Please try again.',
        error: true,
      );
      return null;
    }
  }

  Future<void> _export() async {
    final resume = await _persist(showFeedback: false);
    if (resume == null || !mounted) return;
    setState(() => _exporting = true);
    try {
      final bytes = await ref
          .read(documentServiceProvider)
          .buildResumePdf(resume);
      await ref
          .read(documentServiceProvider)
          .sharePdf(bytes: bytes, filename: '${_safeName(resume.title)}.pdf');
    } catch (_) {
      if (mounted) {
        AppSnack.show(
          context,
          'Could not export this resume. Please try again.',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  String _safeName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[^A-Za-z0-9 _-]'), '').trim();
    return cleaned.isEmpty ? 'Veyora_Resume' : cleaned.replaceAll(' ', '_');
  }

  void _addSkill() {
    final value = _skillCtrl.text.trim();
    if (value.isEmpty) return;
    final exists = _skills.any(
      (skill) => skill.toLowerCase() == value.toLowerCase(),
    );
    if (exists) {
      _skillCtrl.clear();
      return;
    }
    if (_skills.length >= 30) {
      AppSnack.show(context, 'You can add up to 30 skills.');
      return;
    }
    setState(() {
      _skills = [..._skills, value];
      _skillCtrl.clear();
    });
  }

  Future<void> _generateSummary() async {
    final role = _roleCtrl.text.trim();
    if (role.isEmpty) {
      AppSnack.show(
        context,
        'Add a target role first so the summary has direction.',
      );
      return;
    }
    setState(() => _generatingSummary = true);
    try {
      final user = ref.read(authControllerProvider).user;
      final summary = await ref
          .read(aiServiceProvider)
          .generateSummary(
            name: _nameCtrl.text.trim().isEmpty
                ? (user?.name ?? '')
                : _nameCtrl.text.trim(),
            role: role,
            skills: _skills,
            experienceLevel: user?.experienceLevel ?? 'Professional',
          );
      if (!mounted) return;
      setState(() => _summaryCtrl.text = summary);
    } catch (_) {
      if (mounted) {
        AppSnack.show(
          context,
          'Could not generate a summary right now.',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _generatingSummary = false);
    }
  }

  Future<void> _openExperienceSheet({ExperienceEntry? entry}) async {
    final result = await showAppSheet<ExperienceEntry>(
      context,
      child: _ExperienceSheet(entry: entry, skills: _skills),
    );
    if (result == null || !mounted) return;
    setState(() {
      if (entry == null) {
        _experience = [..._experience, result];
      } else {
        _experience = [
          for (final item in _experience)
            if (item.id == entry.id) result else item,
        ];
      }
    });
  }

  Future<void> _openEducationSheet({EducationEntry? entry}) async {
    final result = await showAppSheet<EducationEntry>(
      context,
      child: _EducationSheet(entry: entry),
    );
    if (result == null || !mounted) return;
    setState(() {
      if (entry == null) {
        _education = [..._education, result];
      } else {
        _education = [
          for (final item in _education)
            if (item.id == entry.id) result else item,
        ];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_resumeId == null ? 'New resume' : 'Edit resume'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _preview = !_preview),
            icon: Icon(
              _preview ? Icons.edit_outlined : Icons.visibility_outlined,
              size: 21,
            ),
            tooltip: _preview ? 'Edit' : 'Preview',
          ),
          IconButton(
            onPressed: _exporting ? null : _export,
            icon: _exporting
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.ios_share_rounded, size: 20),
            tooltip: 'Export PDF',
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                  child: _ModeSwitch(
                    preview: _preview,
                    onChanged: (value) => setState(() => _preview = value),
                  ),
                ),
                Expanded(
                  child: _preview
                      ? _buildPreview(isDark)
                      : Form(key: _formKey, child: _buildEditor(isDark)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: .035)
                  : AppColors.primary.withValues(alpha: .04),
              borderRadius: BorderRadius.circular(22),
            ),
            child: ResumePreview(resume: _compose()),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Keep editing',
                  icon: Icons.edit_outlined,
                  onPressed: () => setState(() => _preview = false),
                  height: 50,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(
                  label: 'Export PDF',
                  icon: Icons.ios_share_rounded,
                  onPressed: _exporting ? null : _export,
                  loading: _exporting,
                  height: 50,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditor(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Resume details',
            subtitle: 'Name this version so you can find it later',
          ),
          const SizedBox(height: 12),
          AppCard(
            child: AppTextField(
              controller: _titleCtrl,
              label: 'Resume name',
              hint: 'e.g. Product Designer · 2026',
              prefixIcon: Icons.description_outlined,
              textInputAction: TextInputAction.next,
              validator: (value) =>
                  Validators.required(value, label: 'Resume name'),
            ),
          ),
          const SizedBox(height: 22),
          const SectionHeader(
            title: 'Template',
            subtitle: 'Switch anytime — content stays the same',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final option in _templates) ...[
                Expanded(
                  child: _TemplateOption(
                    name: option.$1,
                    accent: option.$2,
                    selected: _template == option.$1,
                    onTap: () => setState(() => _template = option.$1),
                  ),
                ),
                if (option != _templates.last) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 22),
          const SectionHeader(
            title: 'Personal information',
            subtitle: 'Keep your contact details current and easy to scan',
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              children: [
                AppTextField(
                  controller: _nameCtrl,
                  label: 'Full name',
                  hint: 'Your full name',
                  prefixIcon: Icons.person_outline_rounded,
                  textInputAction: TextInputAction.next,
                  validator: (value) =>
                      Validators.required(value, label: 'Full name'),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _roleCtrl,
                  label: 'Target role',
                  hint: 'e.g. Senior Flutter Developer',
                  prefixIcon: Icons.work_outline_rounded,
                  textInputAction: TextInputAction.next,
                  validator: (value) =>
                      Validators.required(value, label: 'Target role'),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _emailCtrl,
                  label: 'Email',
                  hint: 'you@example.com',
                  prefixIcon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _phoneCtrl,
                  label: 'Phone',
                  hint: '+1 555 000 1234',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _locationCtrl,
                  label: 'Location',
                  hint: 'City, Country',
                  prefixIcon: Icons.location_on_outlined,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _linkedinCtrl,
                  label: 'LinkedIn or portfolio',
                  hint: 'linkedin.com/in/your-name',
                  prefixIcon: Icons.link_rounded,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SectionHeader(
            title: 'Professional summary',
            subtitle: '3–4 lines that frame your value',
            actionLabel: 'Generate',
            onAction: () => _generateSummary(),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  controller: _summaryCtrl,
                  label: 'Summary',
                  hint:
                      'A concise overview of who you are and the impact you create.',
                  maxLines: 5,
                  helperText:
                      'Tip: mention your role, strongest skills, and a measurable win.',
                ),
                const SizedBox(height: 12),
                _AiDraftButton(
                  label: 'Draft with AI',
                  loading: _generatingSummary,
                  onTap: _generateSummary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionHeader(
            title: 'Skills',
            subtitle: 'Tap a skill to remove it',
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_skills.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Add 6–10 role-relevant skills for the best ATS match.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.white54 : AppColors.inkMuted,
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: _skills
                        .map(
                          (skill) => TagChip(
                            label: skill,
                            selected: true,
                            icon: Icons.close_rounded,
                            onTap: () => setState(
                              () => _skills = [..._skills]..remove(skill),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _skillCtrl,
                        hint: 'Add a skill',
                        prefixIcon: Icons.add_rounded,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _addSkill(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _addSkill,
                      icon: const Icon(Icons.add_rounded, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(48, 48),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SectionHeader(
            title: 'Experience',
            subtitle: 'Show outcomes, not just responsibilities',
            actionLabel: 'Add role',
            onAction: () => _openExperienceSheet(),
          ),
          const SizedBox(height: 12),
          if (_experience.isEmpty)
            _EmptySection(
              icon: Icons.work_history_outlined,
              message:
                  'Add your most relevant roles. Two to four entries is plenty.',
              onAdd: () => _openExperienceSheet(),
            )
          else
            ..._experience.map(
              (exp) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _EntryCard(
                  icon: Icons.work_history_outlined,
                  title: exp.role,
                  subtitle: [
                    exp.company,
                    exp.dateRange,
                  ].where((e) => e.isNotEmpty).join(' · '),
                  body: exp.description,
                  onEdit: () => _openExperienceSheet(entry: exp),
                  onDelete: () => setState(
                    () => _experience = _experience
                        .where((e) => e.id != exp.id)
                        .toList(),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 22),
          SectionHeader(
            title: 'Education',
            subtitle: 'Your highest relevant qualification',
            actionLabel: 'Add education',
            onAction: () => _openEducationSheet(),
          ),
          const SizedBox(height: 12),
          if (_education.isEmpty)
            _EmptySection(
              icon: Icons.school_outlined,
              message:
                  'Add a degree, bootcamp, or certification that supports your target role.',
              onAdd: () => _openEducationSheet(),
            )
          else
            ..._education.map(
              (edu) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _EntryCard(
                  icon: Icons.school_outlined,
                  title:
                      '${edu.degree}${edu.field.isEmpty ? '' : ' in ${edu.field}'}',
                  subtitle: [
                    edu.school,
                    edu.dateRange,
                    edu.grade,
                  ].where((e) => e.isNotEmpty).join(' · '),
                  body: '',
                  onEdit: () => _openEducationSheet(entry: edu),
                  onDelete: () => setState(
                    () => _education = _education
                        .where((e) => e.id != edu.id)
                        .toList(),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 28),
          PrimaryButton(
            label: _resumeId == null ? 'Save resume' : 'Save changes',
            icon: Icons.save_outlined,
            onPressed: _saving ? null : () => _persist(),
            loading: _saving,
          ),
          const SizedBox(height: 10),
          SecondaryButton(
            label: 'Preview & export',
            icon: Icons.visibility_outlined,
            onPressed: () => setState(() => _preview = true),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: () => context.go('/app/resume'),
              icon: const Icon(Icons.grid_view_rounded, size: 17),
              label: const Text('Back to resume studio'),
            ),
          ),
        ],
      ),
    );
  }

  static const _templates = [
    ('Modern', AppColors.primary),
    ('Minimal', Color(0xFF111827)),
    ('Executive', Color(0xFF1E3A5F)),
  ];
}

class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.preview, required this.onChanged});

  final bool preview;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: .05)
            : AppColors.primary.withValues(alpha: .05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _segment(
            context,
            label: 'Editor',
            icon: Icons.tune_rounded,
            selected: !preview,
            onTap: () => onChanged(false),
          ),
          _segment(
            context,
            label: 'Live preview',
            icon: Icons.visibility_outlined,
            selected: preview,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }

  Widget _segment(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final isDark = AppTheme.isDark(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? (isDark ? Colors.white.withValues(alpha: .1) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? .15 : .05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected
                    ? AppColors.primary
                    : (isDark ? Colors.white54 : AppColors.inkMuted),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? (isDark ? Colors.white : AppColors.ink)
                      : (isDark ? Colors.white54 : AppColors.inkMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplateOption extends StatelessWidget {
  const _TemplateOption({
    required this.name,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : (isDark ? Colors.white12 : AppColors.outline),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 54,
              width: double.infinity,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: name == 'Modern' ? 6 : 2,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: name == 'Modern' ? accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 4,
                    width: 38,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 2,
                    width: double.infinity,
                    color: const Color(0xFFD1D5DB),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    height: 2,
                    width: 46,
                    color: const Color(0xFFD1D5DB),
                  ),
                  const Spacer(),
                  Container(
                    height: 2,
                    width: 30,
                    color: accent.withValues(alpha: .5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 7),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (selected) ...[
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 12,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 3),
                ],
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? AppColors.primary
                        : (isDark ? Colors.white70 : AppColors.inkMuted),
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

class _AiDraftButton extends StatelessWidget {
  const _AiDraftButton({
    required this.label,
    required this.loading,
    required this.onTap,
  });

  final String label;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: AppColors.heroGradient,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              const Icon(
                Icons.auto_awesome_rounded,
                size: 14,
                color: Colors.white,
              ),
            const SizedBox(width: 7),
            Text(
              loading ? 'Drafting…' : label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({
    required this.icon,
    required this.message,
    required this.onAdd,
  });

  final IconData icon;
  final String message;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconBadge(
            icon: icon,
            size: 38,
            color: AppColors.primary.withValues(alpha: isDark ? .16 : .07),
            iconColor: AppColors.primary,
            radius: 11,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 11,
                height: 1.45,
                color: isDark ? Colors.white54 : AppColors.inkMuted,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onAdd,
            icon: const Icon(Icons.add_circle_outline_rounded, size: 22),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.onEdit,
    required this.onDelete,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String body;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
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
                  title.isEmpty ? 'Untitled role' : title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9.5,
                      height: 1.4,
                      color: isDark ? Colors.white38 : AppColors.inkMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 17),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 17),
                color: AppColors.danger,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExperienceSheet extends ConsumerStatefulWidget {
  const _ExperienceSheet({this.entry, required this.skills});

  final ExperienceEntry? entry;
  final List<String> skills;

  @override
  ConsumerState<_ExperienceSheet> createState() => _ExperienceSheetState();
}

class _ExperienceSheetState extends ConsumerState<_ExperienceSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _role;
  late final TextEditingController _company;
  late final TextEditingController _start;
  late final TextEditingController _end;
  late final TextEditingController _description;
  late bool _current;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _role = TextEditingController(text: entry?.role ?? '');
    _company = TextEditingController(text: entry?.company ?? '');
    _start = TextEditingController(text: entry?.startDate ?? '');
    _end = TextEditingController(text: entry?.endDate ?? '');
    _description = TextEditingController(text: entry?.description ?? '');
    _current = entry?.current ?? false;
  }

  @override
  void dispose() {
    _role.dispose();
    _company.dispose();
    _start.dispose();
    _end.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (_role.text.trim().isEmpty) {
      AppSnack.show(context, 'Add a role title first.');
      return;
    }
    setState(() => _generating = true);
    try {
      final result = await ref
          .read(aiServiceProvider)
          .generateExperienceDescription(
            role: _role.text.trim(),
            company: _company.text.trim(),
            skills: widget.skills,
          );
      if (!mounted) return;
      setState(() => _description.text = result);
    } catch (_) {
      if (mounted) {
        AppSnack.show(
          context,
          'Could not draft this role right now.',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      ExperienceEntry(
        id: widget.entry?.id ?? const Uuid().v4(),
        company: _company.text.trim(),
        role: _role.text.trim(),
        startDate: _start.text.trim(),
        endDate: _current ? '' : _end.text.trim(),
        current: _current,
        description: _description.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  widget.entry == null ? 'Add experience' : 'Edit experience',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.ink,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AppTextField(
              controller: _role,
              label: 'Role title',
              hint: 'e.g. Product Designer',
              prefixIcon: Icons.badge_outlined,
              validator: (value) =>
                  Validators.required(value, label: 'Role title'),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _company,
              label: 'Company',
              hint: 'e.g. Northwind Labs',
              prefixIcon: Icons.business_outlined,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _start,
                    label: 'Start',
                    hint: 'Jan 2023',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppTextField(
                    controller: _end,
                    label: 'End',
                    hint: _current ? 'Present' : 'Dec 2025',
                    enabled: !_current,
                  ),
                ),
              ],
            ),
            SwitchListTile.adaptive(
              value: _current,
              onChanged: (value) => setState(() => _current = value),
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Currently working here',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
            AppTextField(
              controller: _description,
              label: 'Achievements',
              hint: 'Use 2–4 bullets with action verbs and measurable results.',
              maxLines: 6,
              helperText: 'Start lines with “Led”, “Built”, or “Improved”.',
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: _AiDraftButton(
                label: 'Draft bullets with AI',
                loading: _generating,
                onTap: _generate,
              ),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Save role',
              icon: Icons.check_rounded,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _EducationSheet extends StatefulWidget {
  const _EducationSheet({this.entry});

  final EducationEntry? entry;

  @override
  State<_EducationSheet> createState() => _EducationSheetState();
}

class _EducationSheetState extends State<_EducationSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _school;
  late final TextEditingController _degree;
  late final TextEditingController _field;
  late final TextEditingController _start;
  late final TextEditingController _end;
  late final TextEditingController _grade;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _school = TextEditingController(text: entry?.school ?? '');
    _degree = TextEditingController(text: entry?.degree ?? '');
    _field = TextEditingController(text: entry?.field ?? '');
    _start = TextEditingController(text: entry?.startYear ?? '');
    _end = TextEditingController(text: entry?.endYear ?? '');
    _grade = TextEditingController(text: entry?.grade ?? '');
  }

  @override
  void dispose() {
    _school.dispose();
    _degree.dispose();
    _field.dispose();
    _start.dispose();
    _end.dispose();
    _grade.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      EducationEntry(
        id: widget.entry?.id ?? const Uuid().v4(),
        school: _school.text.trim(),
        degree: _degree.text.trim(),
        field: _field.text.trim(),
        startYear: _start.text.trim(),
        endYear: _end.text.trim(),
        grade: _grade.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  widget.entry == null ? 'Add education' : 'Edit education',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.ink,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AppTextField(
              controller: _school,
              label: 'School or program',
              hint: 'e.g. University of Toronto',
              prefixIcon: Icons.account_balance_outlined,
              validator: (value) => Validators.required(value, label: 'School'),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _degree,
              label: 'Degree',
              hint: 'e.g. Bachelor of Science',
              prefixIcon: Icons.school_outlined,
              validator: (value) => Validators.required(value, label: 'Degree'),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _field,
              label: 'Field of study',
              hint: 'e.g. Computer Science',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _start,
                    label: 'Start year',
                    hint: '2018',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppTextField(
                    controller: _end,
                    label: 'End year',
                    hint: '2022',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _grade,
              label: 'Grade (optional)',
              hint: 'e.g. 3.8 GPA or First Class',
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Save education',
              icon: Icons.check_rounded,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
