import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../auth/application/auth_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardingData(
      title: 'Build your perfect resume with AI',
      description:
          'Upload your resume and get a clear score, missing keywords, and specific fixes that make recruiters stop scrolling.',
      accent: AppColors.primary,
      gradient: AppColors.heroGradient,
      illustration: _IllustrationType.resume,
    ),
    _OnboardingData(
      title: 'Discover jobs that match your skills',
      description:
          'Paste any job description to see your compatibility, missing qualifications, and the exact skills worth learning next.',
      accent: Color(0xFF0EA5A4),
      gradient: AppColors.mintGradient,
      illustration: _IllustrationType.jobs,
    ),
    _OnboardingData(
      title: 'Prepare for interviews with your AI coach',
      description:
          'Practice role-specific questions, get instant feedback on your answers, and walk into interviews with calm confidence.',
      accent: Color(0xFFEC4899),
      gradient: AppColors.roseGradient,
      illustration: _IllustrationType.interview,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(authControllerProvider.notifier).markOnboardingSeen();
    if (!mounted) return;
    context.go('/login');
  }

  void _next() {
    if (_page == _pages.length - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 16, 0),
              child: Row(
                children: [
                  const VeyoraLogo(size: 38, compact: true),
                  const Spacer(),
                  TextButton(
                    onPressed: _finish,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : AppColors.inkMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (value) => setState(() => _page = value),
                itemBuilder: (context, index) =>
                    _OnboardingPage(data: _pages[index], index: index),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (index) {
                      final active = index == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        margin: const EdgeInsets.symmetric(horizontal: 3.5),
                        width: active ? 24 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.primary
                              : (isDark ? Colors.white24 : AppColors.outline),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 26),
                  PrimaryButton(
                    label: _page == _pages.length - 1 ? 'Get started' : 'Next',
                    onPressed: _next,
                    icon: _page == _pages.length - 1
                        ? Icons.arrow_forward_rounded
                        : Icons.arrow_forward_rounded,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your potential. Our intelligence.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white38 : AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data, required this.index});

  final _OnboardingData data;
  final int index;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Expanded(
            flex: 6,
            child: Center(
              child: _Illustration(
                type: data.illustration,
                gradient: data.gradient,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: data.accent.withValues(
                            alpha: isDark ? .16 : .08,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '0${index + 1}  •  ${['SMARTER RESUMES', 'BETTER MATCHES', 'INTERVIEW READY'][index]}',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: data.accent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                            data.title,
                            style: TextStyle(
                              fontSize: 30,
                              height: 1.18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                              color: isDark ? Colors.white : AppColors.ink,
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 450.ms)
                          .moveY(begin: 12, end: 0),
                      const SizedBox(height: 14),
                      Text(
                            data.description,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.65,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? Colors.white60
                                  : AppColors.inkMuted,
                            ),
                          )
                          .animate(delay: 80.ms)
                          .fadeIn(duration: 500.ms)
                          .moveY(begin: 10, end: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration({required this.type, required this.gradient});

  final _IllustrationType type;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360, maxHeight: 360),
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 290,
                  height: 290,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        (gradient as LinearGradient).colors.first.withValues(
                          alpha: .2,
                        ),
                        (gradient as LinearGradient).colors.first.withValues(
                          alpha: 0,
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(70),
                    boxShadow: [
                      BoxShadow(
                        color: (gradient as LinearGradient).colors.first
                            .withValues(alpha: .3),
                        blurRadius: 60,
                        offset: const Offset(0, 24),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 38,
                  child: _floatingCard(
                    context,
                    width: 150,
                    height: 94,
                    child: _resumeSnippet(context),
                  ),
                ),
                Positioned(
                  right: 6,
                  bottom: 46,
                  child: _floatingCard(
                    context,
                    width: 168,
                    height: 112,
                    child: _matchSnippet(context),
                  ),
                ),
                Positioned(
                  right: 14,
                  top: 30,
                  child: _miniBubble(
                    context,
                    icon: Icons.auto_awesome_rounded,
                    color: Colors.white,
                    background: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 600.ms)
        .scale(begin: const Offset(.92, .92), curve: Curves.easeOutBack);
  }

  Widget _floatingCard(
    BuildContext context, {
    required double width,
    required double height,
    required Widget child,
  }) {
    final isDark = AppTheme.isDark(context);
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? .3 : .1),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _resumeSnippet(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    Widget line(double width) => Container(
      width: width,
      height: 6,
      margin: const EdgeInsets.only(bottom: 7),
      decoration: BoxDecoration(
        color: isDark ? Colors.white12 : AppColors.outline,
        borderRadius: BorderRadius.circular(99),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.all(Radius.circular(7)),
              ),
              child: const Icon(
                Icons.description_outlined,
                color: Colors.white,
                size: 12,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(child: line(70)),
          ],
        ),
        line(110),
        line(84),
        const Spacer(),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Text(
                '92 ATS',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: AppColors.success,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _matchSnippet(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.mintGradient.colors.first.withValues(
                  alpha: .14,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.work_outline_rounded,
                size: 13,
                color: Color(0xFF0EA5A4),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 78,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : AppColors.ink,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: 50,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : AppColors.outline,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              '86%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0EA5A4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: const LinearProgressIndicator(
            value: .86,
            minHeight: 6,
            backgroundColor: Color(0xFFE6FBF7),
            valueColor: AlwaysStoppedAnimation(Color(0xFF0EA5A4)),
          ),
        ),
        const Spacer(),
        Row(
          children: [
            _tinyTag('Flutter', AppColors.primary),
            const SizedBox(width: 4),
            _tinyTag('Firebase', AppColors.info),
          ],
        ),
      ],
    );
  }

  Widget _tinyTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 7,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _miniBubble(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required Color background,
  }) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: background.withValues(alpha: .4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}

class _OnboardingData {
  const _OnboardingData({
    required this.title,
    required this.description,
    required this.accent,
    required this.gradient,
    required this.illustration,
  });

  final String title;
  final String description;
  final Color accent;
  final Gradient gradient;
  final _IllustrationType illustration;
}

enum _IllustrationType { resume, jobs, interview }
