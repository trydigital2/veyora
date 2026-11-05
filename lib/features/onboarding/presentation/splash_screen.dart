import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(gradient: AppColors.deepGradient),
            ),
          ),
          Positioned(
            top: -90,
            right: -70,
            child: _Orb(
              size: 260,
              color: AppColors.secondary.withValues(alpha: .32),
            ),
          ),
          Positioned(
            bottom: -110,
            left: -80,
            child: _Orb(
              size: 300,
              color: AppColors.primary.withValues(alpha: .3),
            ),
          ),
          Positioned(
            top: 190,
            left: -30,
            child: _Orb(size: 120, color: Colors.white.withValues(alpha: .07)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  const VeyoraLogo(size: 86, showWordmark: false)
                      .animate()
                      .fadeIn(duration: 800.ms, curve: Curves.easeOut)
                      .scale(
                        begin: const Offset(.55, .55),
                        end: const Offset(1, 1),
                        duration: 900.ms,
                        curve: Curves.easeOutBack,
                      ),
                  const SizedBox(height: 32),
                  const Text(
                        AppConfig.appName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 12,
                          height: 1,
                        ),
                      )
                      .animate(delay: 350.ms)
                      .fadeIn(duration: 700.ms)
                      .moveY(begin: 14, end: 0, curve: Curves.easeOutCubic),
                  const SizedBox(height: 12),
                  Text(
                    'AI CAREER COPILOT',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .55),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4.2,
                    ),
                  ).animate(delay: 500.ms).fadeIn(duration: 700.ms),
                  const Spacer(flex: 2),
                  Text(
                        AppConfig.tagline,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .92),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -.2,
                        ),
                      )
                      .animate(delay: 850.ms)
                      .fadeIn(duration: 700.ms)
                      .moveY(begin: 10, end: 0),
                  const SizedBox(height: 10),
                  Text(
                    'Resumes, matching, interviews and career momentum — in one place.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .48),
                      fontSize: 12.5,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ).animate(delay: 1000.ms).fadeIn(duration: 700.ms),
                  const Spacer(flex: 3),
                  const _LoadingDots()
                      .animate(delay: 1200.ms)
                      .fadeIn(duration: 500.ms),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final phase = (_controller.value - index * .18) % 1;
            final alpha = .3 + (1 - (phase - .5).abs() * 2) * .7;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3.5),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: alpha.clamp(0.0, 1.0)),
              ),
            );
          }),
        );
      },
    );
  }
}
