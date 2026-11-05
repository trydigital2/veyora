import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../auth/application/auth_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Sign out of VEYORA?',
      message:
          'Your saved resumes, analyses, and practice history stay on this device.',
      confirmLabel: 'Sign out',
      destructive: true,
    );
    if (!confirmed) return;
    await ref.read(authControllerProvider.notifier).signOut();
    if (context.mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppTheme.isDark(context);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Appearance',
                  subtitle: 'Choose how VEYORA looks on this device',
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          for (final mode in _themes()) ...[
                            Expanded(
                              child: _ThemeOption(
                                label: mode.$1,
                                icon: mode.$2,
                                selected: settings.themeMode == mode.$3,
                                onTap: () => controller.setThemeMode(mode.$3),
                              ),
                            ),
                            if (mode != _themes().last)
                              const SizedBox(width: 8),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Dark mode is easy on the eyes for evening practice sessions.',
                        style: TextStyle(
                          fontSize: 9.5,
                          height: 1.45,
                          color: isDark ? Colors.white38 : AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const SectionHeader(
                  title: 'Preferences',
                  subtitle: 'Tune the experience to your habits',
                ),
                const SizedBox(height: 12),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        value: settings.notifications,
                        onChanged: controller.setNotifications,
                        title: const Text(
                          'In-app nudges',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Tips for practice streaks and resume refreshes',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isDark ? Colors.white38 : AppColors.inkMuted,
                          ),
                        ),
                        activeThumbColor: AppColors.primary,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: isDark ? Colors.white10 : AppColors.outline,
                      ),
                      SwitchListTile.adaptive(
                        value: settings.haptics,
                        onChanged: controller.setHaptics,
                        title: const Text(
                          'Haptic feedback',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Subtle taps on key actions',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isDark ? Colors.white38 : AppColors.inkMuted,
                          ),
                        ),
                        activeThumbColor: AppColors.primary,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const SectionHeader(title: 'Account'),
                const SizedBox(height: 12),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: Icons.person_outline_rounded,
                        title: 'Edit profile',
                        subtitle: user?.email ?? '',
                        onTap: () => context.push('/app/edit-profile'),
                      ),
                      _Divider(isDark: isDark),
                      _SettingsTile(
                        icon: Icons.workspace_premium_outlined,
                        title: 'Subscription',
                        subtitle: '${user?.plan ?? 'Free'} plan',
                        onTap: () => context.push('/app/subscription'),
                      ),
                      _Divider(isDark: isDark),
                      _SettingsTile(
                        icon: Icons.logout_rounded,
                        title: 'Sign out',
                        tone: AppColors.danger,
                        onTap: () => _signOut(context, ref),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const SectionHeader(
                  title: 'Privacy & data',
                  subtitle: 'Built to keep your career data yours',
                ),
                const SizedBox(height: 12),
                const InfoBanner(
                  message:
                      'Your resumes, analyses, and practice history are stored locally on this device. Resume text is only sent to the AI proxy when a secure backend is configured.',
                  icon: Icons.lock_outline_rounded,
                  color: AppColors.success,
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Row(
                    children: [
                      const IconBadge(
                        icon: Icons.memory_rounded,
                        size: 38,
                        color: AppColors.lavender,
                        iconColor: AppColors.primary,
                        radius: 11,
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI engine',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              AppConfig.hasSecureAiBackend
                                  ? 'Secure proxy connected · local fallback ready'
                                  : 'On-device engine · no API key in the app',
                              style: TextStyle(
                                fontSize: 9.5,
                                height: 1.4,
                                color: isDark
                                    ? Colors.white38
                                    : AppColors.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const SectionHeader(title: 'About'),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const VeyoraLogo(size: 34, compact: true),
                          const SizedBox(width: 9),
                          Text(
                            'VEYORA',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.6,
                              color: isDark ? Colors.white : AppColors.ink,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Version ${AppConfig.version}',
                            style: TextStyle(
                              fontSize: 9.5,
                              color: isDark
                                  ? Colors.white38
                                  : AppColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Your Potential. Our Intelligence.\nAn AI career copilot for sharper resumes, smarter matches, and confident interviews.',
                        style: TextStyle(
                          fontSize: 10.5,
                          height: 1.55,
                          color: isDark ? Colors.white54 : AppColors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Built for Android & iOS · Local-first architecture',
                        style: TextStyle(
                          fontSize: 9,
                          color: isDark
                              ? Colors.white30
                              : AppColors.inkMuted.withValues(alpha: .7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static List<(String, IconData, ThemeMode)> _themes() => const [
    ('Light', Icons.light_mode_outlined, ThemeMode.light),
    ('Dark', Icons.dark_mode_outlined, ThemeMode.dark),
    ('System', Icons.brightness_auto_outlined, ThemeMode.system),
  ];
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.heroGradient : null,
          color: selected
              ? null
              : (isDark
                    ? Colors.white.withValues(alpha: .04)
                    : AppColors.surface),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : (isDark ? Colors.white10 : AppColors.outline),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected
                  ? Colors.white
                  : (isDark ? Colors.white54 : AppColors.inkMuted),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: selected
                    ? Colors.white
                    : (isDark ? Colors.white54 : AppColors.inkMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle = '',
    this.tone,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color? tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 19, color: tone ?? AppColors.primary),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: tone ?? (isDark ? Colors.white : AppColors.ink),
                    ),
                  ),
                  if (subtitle.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.5,
                        color: isDark ? Colors.white38 : AppColors.inkMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 19,
              color: isDark ? Colors.white24 : AppColors.inkMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 46,
      color: isDark ? Colors.white10 : AppColors.outline,
    );
  }
}
