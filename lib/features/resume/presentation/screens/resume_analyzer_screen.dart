import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers.dart';
import '../../../../core/services/document_service.dart';
import '../../../../core/services/local_ai_engine.dart';
import '../../../../core/services/skill_dictionary.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../auth/application/auth_controller.dart';
import '../../application/resume_controller.dart';

class ResumeAnalyzerScreen extends ConsumerStatefulWidget {
  const ResumeAnalyzerScreen({super.key});

  @override
  ConsumerState<ResumeAnalyzerScreen> createState() =>
      _ResumeAnalyzerScreenState();
}

class _ResumeAnalyzerScreenState extends ConsumerState<ResumeAnalyzerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _targetRole = TextEditingController();
  final _resumeText = TextEditingController();
  String? _fileName;
  int _fileSize = 0;
  bool _extracting = false;
  bool _analyzing = false;
  String? _localError;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).user;
    _targetRole.text = user?.targetRole ?? '';
  }

  @override
  void dispose() {
    _targetRole.dispose();
    _resumeText.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    setState(() => _localError = null);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'docx'],
      );
      if (result.isEmpty) return;
      final file = result.single;
      setState(() => _extracting = true);
      final Uint8List bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        setState(() {
          _extracting = false;
          _localError = 'That file appears to be empty. Please try another.';
        });
        return;
      }
      final text = await ref
          .read(documentServiceProvider)
          .extractText(bytes: bytes, fileName: file.name);
      if (!mounted) return;
      setState(() {
        _resumeText.text = text;
        _fileName = file.name;
        _fileSize = bytes.length;
        _extracting = false;
      });
    } on DocumentException catch (error) {
      if (!mounted) return;
      setState(() {
        _extracting = false;
        _localError = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _extracting = false;
        _localError = error.toString().replaceFirst('DocumentException: ', '');
      });
    }
  }

  Future<void> _analyze() async {
    FocusScope.of(context).unfocus();
    setState(() => _localError = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _analyzing = true);
    try {
      final analysis = await ref
          .read(resumeControllerProvider.notifier)
          .analyze(
            text: _resumeText.text.trim(),
            targetRole: _targetRole.text.trim(),
            resumeName: _fileName ?? 'Pasted resume',
          );
      if (!mounted) return;
      setState(() => _analyzing = false);
      context.push('/app/analysis/${analysis.id}');
    } on AiException catch (error) {
      if (!mounted) return;
      setState(() {
        _analyzing = false;
        _localError = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _analyzing = false;
        _localError = 'The analysis could not be completed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final user = ref.watch(authControllerProvider).user;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume Analyzer'),
        actions: [
          IconButton(
            onPressed: () => context.go('/app/resume'),
            icon: const Icon(Icons.history_rounded, size: 21),
            tooltip: 'History',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'See your resume like a recruiter does.',
                    style: TextStyle(
                      fontSize: 24,
                      height: 1.18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.9,
                      color: isDark ? Colors.white : AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Upload a PDF or DOCX, pick your target role, and get an ATS-aware score with concrete fixes.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.55,
                      color: isDark ? Colors.white54 : AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (_localError != null) ...[
                    InfoBanner(
                      message: _localError!,
                      icon: Icons.error_outline_rounded,
                      color: AppColors.danger,
                    ),
                    const SizedBox(height: 14),
                  ],
                  _UploadCard(
                    fileName: _fileName,
                    fileSize: _fileSize,
                    extracting: _extracting,
                    onTap: _extracting ? null : _pickFile,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: isDark ? Colors.white10 : AppColors.outline,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'OR PASTE TEXT',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: isDark ? Colors.white38 : AppColors.inkMuted,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: isDark ? Colors.white10 : AppColors.outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  AppTextField(
                    controller: _targetRole,
                    label: 'Target role',
                    hint: 'e.g. Senior Flutter Developer',
                    prefixIcon: Icons.flag_outlined,
                    validator: (value) =>
                        Validators.required(value, label: 'Target role'),
                  ),
                  if (user != null && user.targetRole.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        TagChip(
                          label: 'My goal: ${user.targetRole}',
                          dense: true,
                          onTap: () => setState(
                            () => _targetRole.text = user.targetRole,
                          ),
                        ),
                        ...SkillDictionary.roleSuggestions
                            .where((role) => role != user.targetRole)
                            .take(2)
                            .map(
                              (role) => TagChip(
                                label: role,
                                dense: true,
                                onTap: () =>
                                    setState(() => _targetRole.text = role),
                              ),
                            ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 18),
                  AppTextField(
                    controller: _resumeText,
                    label: 'Resume text',
                    hint:
                        'Paste your full resume here, or upload a file above. Include experience, education, and skills.',
                    maxLines: 12,
                    textInputAction: TextInputAction.newline,
                    validator: Validators.resumeText,
                    helperText:
                        'We analyze structure, keywords, measurable impact, and ATS readiness.',
                  ),
                  const SizedBox(height: 20),
                  InfoBanner(
                    message:
                        'Your resume is processed through a secure AI layer. API keys never live in the app.',
                    icon: Icons.shield_outlined,
                    color: AppColors.info,
                  ),
                  const SizedBox(height: 22),
                  PrimaryButton(
                    label: 'Analyze resume',
                    icon: Icons.auto_awesome_rounded,
                    loading: _analyzing,
                    onPressed: _analyzing ? null : _analyze,
                  ),
                  if (_analyzing) ...[
                    const SizedBox(height: 18),
                    const _AnalyzingCard(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UploadCard extends StatelessWidget {
  const _UploadCard({
    required this.fileName,
    required this.fileSize,
    required this.extracting,
    required this.onTap,
  });

  final String? fileName;
  final int fileSize;
  final bool extracting;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final hasFile = fileName != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: hasFile
                ? AppColors.primary.withValues(alpha: isDark ? .12 : .045)
                : (isDark ? AppColors.darkCard : Colors.white),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: hasFile
                  ? AppColors.primary.withValues(alpha: .4)
                  : AppColors.primary.withValues(alpha: isDark ? .3 : .2),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: extracting
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.upload_file_rounded,
                        color: Colors.white,
                        size: 25,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      extracting
                          ? 'Reading your resume...'
                          : hasFile
                          ? fileName!
                          : 'Upload PDF or DOCX',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      extracting
                          ? 'Extracting text from your document'
                          : hasFile
                          ? '${(fileSize / 1024).toStringAsFixed(0)} KB  •  Tap to replace'
                          : 'Tap to browse your files',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white38 : AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                hasFile
                    ? Icons.check_circle_rounded
                    : Icons.arrow_forward_rounded,
                size: 20,
                color: hasFile ? AppColors.success : AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalyzingCard extends StatefulWidget {
  const _AnalyzingCard();

  @override
  State<_AnalyzingCard> createState() => _AnalyzingCardState();
}

class _AnalyzingCardState extends State<_AnalyzingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const steps = [
      'Reading structure',
      'Checking ATS keywords',
      'Scoring experience',
      'Building recommendations',
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analyzing your resume',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'This usually takes a few seconds.',
            style: TextStyle(fontSize: 11, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 14),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final active =
                  (_controller.value * steps.length).floor() % steps.length;
              return Column(
                children: List.generate(steps.length, (index) {
                  final done = index < active;
                  final current = index == active;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Row(
                      children: [
                        Icon(
                          done
                              ? Icons.check_circle_rounded
                              : current
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 16,
                          color: done || current
                              ? AppColors.primary
                              : AppColors.outline,
                        ),
                        const SizedBox(width: 9),
                        Text(
                          steps[index],
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: done || current
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: done || current
                                ? AppColors.ink
                                : AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}
