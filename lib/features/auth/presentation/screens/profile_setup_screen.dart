import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/skill_dictionary.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../application/auth_controller.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _aboutForm = GlobalKey<FormState>();
  final _goalsForm = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _headline = TextEditingController();
  final _location = TextEditingController();
  final _phone = TextEditingController();
  final _targetRole = TextEditingController();
  final _bio = TextEditingController();
  final _skillInput = TextEditingController();
  final List<String> _skills = [];
  int _step = 0;
  bool _initialized = false;
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
      _skills.addAll(user.skills.map((s) => s.toLowerCase()));
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
    final normalized = raw.toLowerCase();
    if (_skills.contains(normalized)) {
      setState(() => _skillError = 'That skill is already added.');
      return;
    }
    setState(() {
      _skills.add(normalized);
      _skillInput.clear();
      _skillError = null;
    });
  }

  Future<void> _finish() async {
    FocusScope.of(context).unfocus();
    if (!_goalsForm.currentState!.validate()) return;
    if (_skills.isEmpty) {
      setState(
        () => _skillError =
            'Add at least one skill to personalize your experience.',
      );
      return;
    }
    final success = await ref
        .read(authControllerProvider.notifier)
        .completeProfile(
          name: _name.text.trim(),
          headline: _headline.text.trim(),
          location: _location.text.trim(),
          targetRole: _targetRole.text.trim(),
          bio: _bio.text.trim(),
          phone: _phone.text.trim(),
          skills: _skills,
        );
    if (!success && mounted) {
      AppSnack.show(
        context,
        ref.read(authControllerProvider).error ??
            'Could not save your profile.',
        error: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final isDark = AppTheme.isDark(context);
    final roleSuggestions = SkillDictionary.requiredForRole(_targetRole.text);
    final suggestions = SkillDictionary.displayNames(
      roleSuggestions.where((s) => !_skills.contains(s)).take(6),
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          if (_step == 1)
                            IconButton(
                              onPressed: () => setState(() => _step = 0),
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                size: 21,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: isDark
                                    ? Colors.white.withValues(alpha: .07)
                                    : Colors.white,
                              ),
                            )
                          else
                            const SizedBox(width: 40),
                          const Spacer(),
                          const VeyoraLogo(size: 38, compact: true),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: _step == 0 ? .5 : 1,
                                minHeight: 7,
                                backgroundColor: isDark
                                    ? Colors.white12
                                    : AppColors.primary.withValues(alpha: .08),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${_step + 1} of 2',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white54
                                  : AppColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 28, 22, 26),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(.04, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: _step == 0
                          ? _buildAbout(isDark)
                          : _buildGoals(isDark, suggestions),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
                  child: PrimaryButton(
                    label: _step == 0 ? 'Continue' : 'Complete profile',
                    loading: auth.loading,
                    icon: _step == 0
                        ? Icons.arrow_forward_rounded
                        : Icons.check_rounded,
                    onPressed: auth.loading
                        ? null
                        : () {
                            if (_step == 0) {
                              FocusScope.of(context).unfocus();
                              if (_aboutForm.currentState!.validate()) {
                                setState(() => _step = 1);
                              }
                            } else {
                              _finish();
                            }
                          },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAbout(bool isDark) {
    return Form(
      key: _aboutForm,
      child: Column(
        key: const ValueKey('about'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Let’s make this yours',
            style: TextStyle(
              fontSize: 28,
              height: 1.15,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              color: isDark ? Colors.white : AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A few details help VEYORA tailor every recommendation to you.',
            style: TextStyle(
              fontSize: 13,
              height: 1.55,
              color: isDark ? Colors.white54 : AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: 26),
          AppTextField(
            controller: _name,
            label: 'Full name',
            hint: 'Your name',
            prefixIcon: Icons.person_outline_rounded,
            validator: Validators.name,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _headline,
            label: 'Professional headline',
            hint: 'e.g. Flutter Developer & Product Builder',
            prefixIcon: Icons.badge_outlined,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _location,
            label: 'Location',
            hint: 'City, Country',
            prefixIcon: Icons.location_on_outlined,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _phone,
            label: 'Phone (optional)',
            hint: '+1 555 000 0000',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            validator: Validators.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildGoals(bool isDark, List<String> suggestions) {
    return Form(
      key: _goalsForm,
      child: Column(
        key: const ValueKey('goals'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Where do you want to go?',
            style: TextStyle(
              fontSize: 28,
              height: 1.15,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              color: isDark ? Colors.white : AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We use your goal and skills to score resumes, match jobs, and build interview practice.',
            style: TextStyle(
              fontSize: 13,
              height: 1.55,
              color: isDark ? Colors.white54 : AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: 26),
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
          const SizedBox(height: 18),
          Text(
            'Your skills',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _skillInput,
                  hint: 'Add a skill and press enter',
                  prefixIcon: Icons.bolt_rounded,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addSkill(),
                ),
              ),
              const SizedBox(width: 9),
              SizedBox(
                width: 52,
                height: 54,
                child: IconButton.filled(
                  onPressed: _addSkill,
                  icon: const Icon(Icons.add_rounded, size: 22),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_skillError != null) ...[
            const SizedBox(height: 6),
            Text(
              _skillError!,
              style: const TextStyle(color: AppColors.danger, fontSize: 11),
            ),
          ],
          if (_skills.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _skills
                  .map(
                    (skill) => TagChip(
                      label: SkillDictionary.displayNames([skill]).first,
                      selected: true,
                      icon: Icons.close_rounded,
                      onTap: () => setState(() => _skills.remove(skill)),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Suggested for your role',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white38 : AppColors.inkMuted,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
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
          const SizedBox(height: 18),
          AppTextField(
            controller: _bio,
            label: 'Short bio (optional)',
            hint: 'What do you do, and what are you looking for?',
            maxLines: 4,
            textInputAction: TextInputAction.newline,
          ),
        ],
      ),
    );
  }
}
