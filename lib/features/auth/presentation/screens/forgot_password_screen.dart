import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../application/auth_controller.dart';
import '../widgets/auth_scaffold.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailForm = GlobalKey<FormState>();
  final _passwordForm = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  int _step = 0;
  bool _checking = false;
  String? _lookupError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _checkEmail() async {
    FocusScope.of(context).unfocus();
    if (!_emailForm.currentState!.validate()) return;
    setState(() {
      _checking = true;
      _lookupError = null;
    });
    final exists = await ref
        .read(authControllerProvider.notifier)
        .emailExists(_email.text);
    if (!mounted) return;
    setState(() {
      _checking = false;
      if (exists) {
        _step = 1;
      } else {
        _lookupError = 'No VEYORA account was found for that email.';
      }
    });
  }

  Future<void> _reset() async {
    FocusScope.of(context).unfocus();
    if (!_passwordForm.currentState!.validate()) return;
    final success = await ref
        .read(authControllerProvider.notifier)
        .resetPassword(_email.text.trim(), _password.text);
    if (!mounted) return;
    if (success) setState(() => _step = 2);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final isDark = AppTheme.isDark(context);

    if (_step == 2) {
      return AuthScaffold(
        title: 'Password updated',
        subtitle:
            'Your password has been changed. Sign in with your new credentials.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: .2),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 44,
                    color: AppColors.success,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You are all set',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Use ${_email.text.trim()} to sign in.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? Colors.white54 : AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Back to sign in',
              onPressed: () => context.go('/login'),
              icon: Icons.login_rounded,
            ),
          ],
        ),
      );
    }

    return AuthScaffold(
      title: _step == 0 ? 'Reset your password' : 'Choose a new password',
      subtitle: _step == 0
          ? 'Enter the email linked to your account and we will verify it before you set a new password.'
          : 'Your email is verified. Set a new password for ${_email.text.trim()}.',
      child: _step == 0
          ? Form(
              key: _emailForm,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_lookupError != null)
                    AuthErrorBanner(message: _lookupError!),
                  AppTextField(
                    controller: _email,
                    label: 'Email address',
                    hint: 'you@example.com',
                    prefixIcon: Icons.alternate_email_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    validator: Validators.email,
                    onSubmitted: (_) => _checkEmail(),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Verify email',
                    loading: _checking,
                    onPressed: _checking ? null : _checkEmail,
                    icon: Icons.verified_user_outlined,
                  ),
                  const SizedBox(height: 18),
                  InfoBanner(
                    message:
                        'In local mode your account is stored on this device. A production backend would email a secure reset link instead.',
                    icon: Icons.info_outline_rounded,
                    color: AppColors.info,
                  ),
                ],
              ),
            )
          : Form(
              key: _passwordForm,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (auth.error != null)
                    AuthErrorBanner(
                      message: auth.error!,
                      onDismiss: () => ref
                          .read(authControllerProvider.notifier)
                          .clearError(),
                    ),
                  AppTextField(
                    controller: _password,
                    label: 'New password',
                    hint: 'At least 8 characters',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscure: true,
                    textInputAction: TextInputAction.next,
                    validator: Validators.password,
                    helperText:
                        'Use at least 8 characters with a letter and a number.',
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _confirm,
                    label: 'Confirm new password',
                    hint: 'Re-enter your password',
                    prefixIcon: Icons.lock_reset_rounded,
                    obscure: true,
                    textInputAction: TextInputAction.done,
                    validator: (value) =>
                        Validators.confirmPassword(value, _password.text),
                    onSubmitted: (_) => _reset(),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Update password',
                    loading: auth.loading,
                    onPressed: auth.loading ? null : _reset,
                    icon: Icons.check_rounded,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => setState(() => _step = 0),
                    child: const Text('Use a different email'),
                  ),
                ],
              ),
            ),
    );
  }
}
