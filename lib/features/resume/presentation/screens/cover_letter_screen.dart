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
import '../../application/resume_controller.dart';
import '../../domain/resume_models.dart';

class CoverLetterScreen extends ConsumerStatefulWidget {
  const CoverLetterScreen({super.key, this.prefill, this.letterId});

  final Map<String, String>? prefill;
  final String? letterId;

  @override
  ConsumerState<CoverLetterScreen> createState() => _CoverLetterScreenState();
}

class _CoverLetterScreenState extends ConsumerState<CoverLetterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _uuid = const Uuid();
  String? _resumeId;
  String _style = 'Professional';
  String? _letterId;
  DateTime? _createdAt;
  bool _generating = false;
  bool _saving = false;
  bool _exporting = false;

  static const _styles = [
    ('Professional', Icons.work_outline_rounded),
    ('Friendly', Icons.waving_hand_outlined),
    ('Confident', Icons.bolt_rounded),
    ('Concise', Icons.short_text_rounded),
  ];

  @override
  void initState() {
    super.initState();
    final prefill = widget.prefill;
    if (prefill != null) {
      _titleCtrl.text = prefill['title'] ?? '';
      _companyCtrl.text = prefill['company'] ?? '';
      _descriptionCtrl.text = prefill['description'] ?? '';
    }
    _resumeId = ref.read(resumeControllerProvider).primaryResume?.id;
    final existing = widget.letterId == null
        ? null
        : ref.read(resumeControllerProvider).coverLetterById(widget.letterId!);
    if (existing != null) {
      _letterId = existing.id;
      _createdAt = existing.createdAt;
      _titleCtrl.text = existing.title;
      _companyCtrl.text = existing.company;
      _contentCtrl.text = existing.content;
      _style = existing.style;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _companyCtrl.dispose();
    _descriptionCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate(Resume resume) async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _generating = true);
    try {
      final user = ref.read(authControllerProvider).user;
      final content = await ref
          .read(aiServiceProvider)
          .generateCoverLetter(
            name: user?.name ?? resume.fullName,
            targetRole: _titleCtrl.text.trim(),
            company: _companyCtrl.text.trim(),
            jobDescription: _descriptionCtrl.text.trim(),
            resumeSkills: resume.skills,
            style: _style,
            experienceLevel: user?.experienceLevel ?? 'Professional',
            email: user?.email ?? resume.email,
            phone: user?.phone ?? resume.phone,
          );
      if (!mounted) return;
      setState(() => _contentCtrl.text = content);
      await _save(feedback: false);
      if (mounted) AppSnack.show(context, 'Cover letter drafted and saved.');
    } catch (_) {
      if (mounted) {
        AppSnack.show(
          context,
          'Could not generate the letter. Please try again.',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  CoverLetter _composeLetter() {
    return CoverLetter(
      id: _letterId ?? _uuid.v4(),
      title: _titleCtrl.text.trim().isEmpty
          ? 'Target role'
          : _titleCtrl.text.trim(),
      company: _companyCtrl.text.trim(),
      style: _style,
      content: _contentCtrl.text.trim(),
      createdAt: _createdAt ?? DateTime.now(),
    );
  }

  Future<CoverLetter?> _save({bool feedback = true}) async {
    if (_contentCtrl.text.trim().isEmpty) {
      if (feedback) {
        AppSnack.show(context, 'Generate or write your letter first.');
      }
      return null;
    }
    setState(() => _saving = true);
    try {
      final letter = _composeLetter();
      await ref.read(resumeControllerProvider.notifier).saveCoverLetter(letter);
      if (!mounted) return letter;
      setState(() {
        _letterId = letter.id;
        _createdAt = letter.createdAt;
        _saving = false;
      });
      if (feedback) AppSnack.show(context, 'Cover letter saved.');
      return letter;
    } catch (_) {
      if (!mounted) return null;
      setState(() => _saving = false);
      if (feedback) {
        AppSnack.show(
          context,
          'Could not save the letter. Please try again.',
          error: true,
        );
      }
      return null;
    }
  }

  Future<void> _export() async {
    final letter = await _save(feedback: false);
    if (letter == null || !mounted) return;
    final user = ref.read(authControllerProvider).user;
    setState(() => _exporting = true);
    try {
      final bytes = await ref
          .read(documentServiceProvider)
          .buildCoverLetterPdf(
            title: letter.title,
            company: letter.company,
            content: letter.content,
            fullName: user?.name ?? 'Your Name',
            email: user?.email ?? '',
            phone: user?.phone ?? '',
          );
      await ref
          .read(documentServiceProvider)
          .sharePdf(
            bytes: bytes,
            filename: '${_safeName(letter.title)}_Cover_Letter.pdf',
          );
    } catch (_) {
      if (mounted) {
        AppSnack.show(
          context,
          'Could not export the letter. Please try again.',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  String _safeName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[^A-Za-z0-9 _-]'), '').trim();
    return cleaned.isEmpty ? 'Veyora' : cleaned.replaceAll(' ', '_');
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
    final hasContent = _contentCtrl.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cover letter studio'),
        actions: [
          if (hasContent)
            IconButton(
              onPressed: () {
                copyToClipboard(context, _contentCtrl.text);
              },
              icon: const Icon(Icons.copy_rounded, size: 19),
              tooltip: 'Copy letter',
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
                  child: Row(
                    children: [
                      const IconBadge(
                        icon: Icons.edit_note_rounded,
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
                              'Say it in your voice',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.4,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'A sharp, tailored letter designed around your resume and the role.',
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
                          'A resume unlocks better letters',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Create a resume so the letter can cite your real skills and experience.',
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
                    title: 'Letter settings',
                    subtitle: 'Choose the resume, role, and tone',
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
                  const SizedBox(height: 12),
                  Form(
                    key: _formKey,
                    child: AppCard(
                      child: Column(
                        children: [
                          AppTextField(
                            controller: _titleCtrl,
                            label: 'Role you are applying for',
                            hint: 'e.g. Senior Product Designer',
                            prefixIcon: Icons.badge_outlined,
                            textInputAction: TextInputAction.next,
                            validator: (value) =>
                                Validators.required(value, label: 'Role title'),
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: _companyCtrl,
                            label: 'Company',
                            hint: 'e.g. Northwind Labs',
                            prefixIcon: Icons.business_outlined,
                            textInputAction: TextInputAction.next,
                            validator: (value) =>
                                Validators.required(value, label: 'Company'),
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: _descriptionCtrl,
                            label: 'Job description',
                            hint:
                                'Paste the role details so the letter mirrors their language.',
                            maxLines: 8,
                            validator: Validators.jobDescription,
                          ),
                          const SizedBox(height: 14),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Tone',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white70
                                    : AppColors.inkMuted,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 7,
                            runSpacing: 7,
                            children: [
                              for (final style in _styles)
                                TagChip(
                                  label: style.$1,
                                  icon: style.$2,
                                  selected: _style == style.$1,
                                  onTap: () =>
                                      setState(() => _style = style.$1),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          PrimaryButton(
                            label: hasContent
                                ? 'Regenerate letter'
                                : 'Generate cover letter',
                            icon: Icons.auto_awesome_rounded,
                            loading: _generating,
                            onPressed: selectedResume == null || _generating
                                ? null
                                : () => _generate(selectedResume),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (hasContent) ...[
                  const SizedBox(height: 24),
                  SectionHeader(
                    title: 'Your letter',
                    subtitle: 'Edit freely — your changes are saved',
                    actionLabel: 'Export',
                    onAction: _exporting ? null : _export,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .08),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 3,
                              height: 22,
                              decoration: BoxDecoration(
                                gradient: AppColors.heroGradient,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${_titleCtrl.text.trim().isEmpty ? 'Cover letter' : _titleCtrl.text.trim()}'
                                '${_companyCtrl.text.trim().isEmpty ? '' : ' · ${_companyCtrl.text.trim()}'}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.ink,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _contentCtrl,
                          onChanged: (_) => setState(() {}),
                          maxLines: null,
                          minLines: 14,
                          style: const TextStyle(
                            color: Color(0xFF374151),
                            fontSize: 12.5,
                            height: 1.75,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            hintText: 'Your letter will appear here.',
                            hintStyle: TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${_contentCtrl.text.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).length} words',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.white38 : AppColors.inkMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          label: 'Save',
                          icon: Icons.save_outlined,
                          loading: _saving,
                          onPressed: _saving ? null : () => _save(),
                          height: 50,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: PrimaryButton(
                          label: 'Export PDF',
                          icon: Icons.ios_share_rounded,
                          loading: _exporting,
                          onPressed: _exporting ? null : _export,
                          height: 50,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => context.go('/app/resume'),
                      icon: const Icon(Icons.grid_view_rounded, size: 17),
                      label: const Text('Back to resume studio'),
                    ),
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
