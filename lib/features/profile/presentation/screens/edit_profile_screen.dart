import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/skill_dictionary.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../auth/application/auth_controller.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _headline = TextEditingController();
  final _location = TextEditingController();
  final _phone = TextEditingController();
  final _targetRole = TextEditingController();
  final _bio = TextEditingController();
  final _skillInput = TextEditingController();
  final List<String> _skills = [];
  bool _initialized = false;
  bool _saving = false;
  String? _skillError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final user = ref.read(authControllerProvider).user;
    if (user != null) {
      _name.text = user.name;
      _headline.text = user.headline;
      _location.text = user.location;
      _phone.text = user.phone;
      _targetRole.text = user.targetRole;
      _bio.text = user.bio;
      _skills.addAll(user.skills);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _headline.dispose();
    _location.dispose();
    _phone.dispose();
    _targetRole.dispose();
    _bio.dispose();
    _skillInput.dispose();
    super.dispose();
  }

  void _addSkill([String? value]) {
    final raw = (value ?? _skillInput.text).trim();
    if (raw.isEmpty) return;
    if (_skills.any((skill) => skill.toLowerCase() == raw.toLowerCase())) {
      setState(() => _skillError = 'That skill is already added.');
      return;
    }
    if (_skills.length >= 30) {
      setState(() => _skillError = 'You can add up to 30 skills.');
      return;
    }
    setState(() {
      _skills.add(raw);
      _skillInput.clear();
      _skillError = null;
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_skills.isEmpty) {
      setState(() => _skillError = 'Add at least one skill.');
      return;
    }
    final user = ref.read(authControllerProvider).user;
    if (user == null) return;
    setState(() => _saving = true);
    final success = await ref
        .read(authControllerProvider.notifier)
        .updateProfile(
          user.copyWith(
            name: _name.text.trim(),
            headline: _headline.text.trim(),
            location: _location.text.trim(),
            phone: _phone.text.trim(),
            targetRole: _targetRole.text.trim(),
            bio: _bio.text.trim(),
            skills: List.unmodifiable(_skills),
            profileCompleted: true,
          ),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (success) {
      AppSnack.show(context, 'Profile updated.');
      context.pop();
    } else {
      AppSnack.show(
        context,
        ref.read(authControllerProvider).error ??
            'Could not save your profile.',
        error: true,
      );
      ref.read(authControllerProvider.notifier).clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final roleSuggestions = SkillDictionary.requiredForRole(_targetRole.text);
    final suggestions = SkillDictionary.displayNames(
      roleSuggestions
          .where((skill) => !_skills.any((item) => item.toLowerCase() == skill))
          .take(8),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    title: 'Personal details',
                    subtitle: 'This powers your resume drafts and job matches',
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    child: Column(
                      children: [
                        AppTextField(
                          controller: _name,
                          label: 'Full name',
                          hint: 'Your name',
                          prefixIcon: Icons.person_outline_rounded,
                          validator: Validators.name,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: _headline,
                          label: 'Professional headline',
                          hint: 'e.g. Flutter Developer & Product Builder',
                          prefixIcon: Icons.badge_outlined,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: _targetRole,
                          label: 'Target role',
                          hint: 'e.g. Product Designer',
                          prefixIcon: Icons.flag_outlined,
                          validator: (value) =>
                              Validators.required(value, label: 'Target role'),
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: _location,
                          label: 'Location',
                          hint: 'City, Country',
                          prefixIcon: Icons.location_on_outlined,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: _phone,
                          label: 'Phone (optional)',
                          hint: '+1 555 000 0000',
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          validator: Validators.phone,
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: _bio,
                          label: 'Short bio',
                          hint: 'What do you do, and what are you looking for?',
                          maxLines: 5,
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
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: _skills
                              .map(
                                (skill) => TagChip(
                                  label: skill,
                                  selected: true,
                                  icon: Icons.close_rounded,
                                  onTap: () =>
                                      setState(() => _skills.remove(skill)),
                                ),
                              )
                              .toList(),
                        ),
                        if (_skills.isNotEmpty) const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: _skillInput,
                                hint: 'Add a skill',
                                prefixIcon: Icons.bolt_rounded,
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
                        if (_skillError != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            _skillError!,
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontSize: 11,
                            ),
                          ),
                        ],
                        if (suggestions.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Suggested for your role',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white38
                                  : AppColors.inkMuted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 7,
                            runSpacing: 7,
                            children: suggestions
                                .map(
                                  (skill) => TagChip(
                                    label: skill,
                                    icon: Icons.add_rounded,
                                    onTap: () => _addSkill(skill),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const InfoBanner(
                    message:
                        'Your resume studio and job matcher read from this profile. Keep it current for the sharpest recommendations.',
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: 'Save changes',
                    icon: Icons.check_rounded,
                    loading: _saving,
                    onPressed: _saving ? null : _save,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
