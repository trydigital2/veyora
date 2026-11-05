import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../application/auth_controller.dart';
import '../widgets/auth_scaffold.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _accepted = false;
  String? _termsError;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _termsError = _accepted ? null : 'Please accept the terms to continue.';
    });
    if (!_formKey.currentState!.validate() || !_accepted) return;
    await ref
        .read(authControllerProvider.notifier)
        .signUp(_name.text.trim(), _email.text.trim(), _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final isDark = AppTheme.isDark(context);
    return AuthScaffold(
      title: 'Create your account',
      subtitle:
          'One account for your resume, job matches, cover letters and interview practice.',
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Already have an account?',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white54 : AppColors.inkMuted,
            ),
          ),
          TextButton(
            onPressed: () => context.go('/login'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.only(left: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Sign in', style: TextStyle(fontSize: 12.5)),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (auth.error != null)
              AuthErrorBanner(
                message: auth.error!,
                onDismiss: () =>
                    ref.read(authControllerProvider.notifier).clearError(),
              ),
            AppTextField(
              controller: _name,
              label: 'Full name',
              hint: 'Your name',
              prefixIcon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              validator: Validators.name,
              autofillHints: const [AutofillHints.name],
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _email,
              label: 'Email address',
              hint: 'you@example.com',
              prefixIcon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: Validators.email,
              autofillHints: const [AutofillHints.newUsername],
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _password,
              label: 'Password',
              hint: 'At least 8 characters',
              prefixIcon: Icons.lock_outline_rounded,
              obscure: true,
              textInputAction: TextInputAction.next,
              validator: Validators.password,
              autofillHints: const [AutofillHints.newPassword],
              helperText:
                  'Use at least 8 characters with a letter and a number.',
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _confirm,
              label: 'Confirm password',
              hint: 'Re-enter your password',
              prefixIcon: Icons.lock_reset_rounded,
              obscure: true,
              textInputAction: TextInputAction.done,
              validator: (value) =>
                  Validators.confirmPassword(value, _password.text),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 26,
                  height: 26,
                  child: Checkbox(
                    value: _accepted,
                    onChanged: (value) => setState(() {
                      _accepted = value ?? false;
                      _termsError = null;
                    }),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    side: BorderSide(
                      color: _termsError != null
                          ? AppColors.danger
                          : AppColors.outline,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showTerms(context),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'I agree to the ',
                            style: TextStyle(
                              fontSize: 11.5,
                              height: 1.5,
                              color: isDark
                                  ? Colors.white54
                                  : AppColors.inkMuted,
                            ),
                          ),
                          const TextSpan(
                            text: 'Terms of Service',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          TextSpan(
                            text: ' and ',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark
                                  ? Colors.white54
                                  : AppColors.inkMuted,
                            ),
                          ),
                          const TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_termsError != null) ...[
              const SizedBox(height: 6),
              Text(
                _termsError!,
                style: const TextStyle(color: AppColors.danger, fontSize: 11),
              ),
            ],
            const SizedBox(height: 22),
            PrimaryButton(
              label: 'Create account',
              loading: auth.loading,
              onPressed: auth.loading ? null : _submit,
              icon: Icons.arrow_forward_rounded,
            ),
            const SizedBox(height: 18),
            const AuthDivider(label: 'or sign up with'),
            const SizedBox(height: 18),
            GoogleButton(
              loading: auth.loading,
              onPressed: auth.loading
                  ? null
                  : () => ref
                        .read(authControllerProvider.notifier)
                        .signInWithGoogle(),
            ),
          ],
        ),
      ),
    );
  }

  void _showTerms(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Terms & Privacy',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const SingleChildScrollView(
          child: Text(
            'VEYORA stores your profile, resumes, analyses and interview practice data locally on this device. '
            'Resume files are processed only when you choose to analyze them. AI requests are sent through a secure backend and never include your raw OpenAI credentials.\n\n'
            'By creating an account you agree to use the service responsibly and to keep your login details private. '
            'You can delete your data at any time from Settings.',
            style: TextStyle(fontSize: 13, height: 1.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }
}
