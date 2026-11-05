import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../application/auth_controller.dart';
import '../widgets/auth_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authControllerProvider.notifier)
        .signIn(_email.text.trim(), _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final isDark = AppTheme.isDark(context);
    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Sign in to keep building momentum toward the career you want.',
      showBack: false,
      footer: _FooterPrompt(
        question: 'New to VEYORA?',
        action: 'Create an account',
        onTap: () => context.go('/signup'),
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
              controller: _email,
              label: 'Email address',
              hint: 'you@example.com',
              prefixIcon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: Validators.email,
              autofillHints: const [AutofillHints.email],
            ),
            const SizedBox(height: 18),
            AppTextField(
              controller: _password,
              label: 'Password',
              hint: 'Enter your password',
              prefixIcon: Icons.lock_outline_rounded,
              obscure: _obscure,
              validator: (value) =>
                  Validators.required(value, label: 'Password'),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              autofillHints: const [AutofillHints.password],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push('/forgot-password'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Sign in',
              loading: auth.loading,
              onPressed: auth.loading ? null : _submit,
              icon: Icons.arrow_forward_rounded,
            ),
            const SizedBox(height: 18),
            const AuthDivider(),
            const SizedBox(height: 18),
            GoogleButton(
              loading: auth.loading,
              onPressed: auth.loading
                  ? null
                  : () => ref
                        .read(authControllerProvider.notifier)
                        .signInWithGoogle(),
            ),
            const SizedBox(height: 14),
            Center(
              child: TextButton.icon(
                onPressed: auth.loading
                    ? null
                    : () => ref
                          .read(authControllerProvider.notifier)
                          .signInAsDemo(),
                icon: const Icon(Icons.explore_outlined, size: 17),
                label: const Text('Explore a demo account'),
                style: TextButton.styleFrom(
                  foregroundColor: isDark ? Colors.white60 : AppColors.inkMuted,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterPrompt extends StatelessWidget {
  const _FooterPrompt({
    required this.question,
    required this.action,
    required this.onTap,
  });

  final String question;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            question,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white54 : AppColors.inkMuted,
            ),
          ),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.only(left: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(action, style: const TextStyle(fontSize: 12.5)),
          ),
        ],
      ),
    );
  }
}
