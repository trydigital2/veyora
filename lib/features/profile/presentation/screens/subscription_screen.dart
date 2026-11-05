import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../auth/application/auth_controller.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _annual = true;
  bool _updating = false;

  Future<void> _choose(String plan) async {
    final controller = ref.read(authControllerProvider.notifier);
    setState(() => _updating = true);
    final ok = await controller.updatePlan(plan);
    if (!mounted) return;
    setState(() => _updating = false);
    if (!ok) {
      AppSnack.show(
        context,
        'Could not update your plan. Please try again.',
        error: true,
      );
      return;
    }
    AppSnack.show(
      context,
      plan == 'Pro'
          ? 'Pro unlocked on this device. Billing is not connected in this demo.'
          : 'You are now on the Free plan.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final user = ref.watch(currentUserProvider);
    final plan = user?.plan ?? 'Free';
    final isPro = plan.toLowerCase() == 'pro';

    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GradientCard(
                  gradient: isPro
                      ? AppColors.heroGradient
                      : AppColors.deepGradient,
                  child: Row(
                    children: [
                      IconBadge(
                        icon: isPro
                            ? Icons.workspace_premium_rounded
                            : Icons.person_outline_rounded,
                        size: 48,
                        color: Colors.white24,
                        iconColor: Colors.white,
                        radius: 15,
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPro ? 'You are on Pro' : 'You are on Free',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.4,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              isPro
                                  ? 'Unlimited AI drafts and deeper career intelligence are active.'
                                  : 'Upgrade for unlimited drafting and deeper career signal.',
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
                const SizedBox(height: 22),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: .05)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _BillingToggle(
                          label: 'Monthly',
                          selected: !_annual,
                          onTap: () => setState(() => _annual = false),
                        ),
                        _BillingToggle(
                          label: 'Annual · save 33%',
                          selected: _annual,
                          onTap: () => setState(() => _annual = true),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _PlanCard(
                  title: 'Free',
                  price: r'$0',
                  period: 'forever',
                  description: 'The essentials for a sharper job search.',
                  features: const [
                    'AI resume analysis and builder',
                    'Job matching and live roles',
                    'Interview practice sessions',
                    'Local-first privacy',
                  ],
                  current: !isPro,
                  onSelect: isPro && !_updating ? () => _choose('Free') : null,
                  actionLabel: isPro ? 'Switch to Free' : 'Current plan',
                ),
                const SizedBox(height: 12),
                _PlanCard(
                  title: 'Pro',
                  price: _annual ? r'$8' : r'$12',
                  period: _annual ? 'per month, billed annually' : 'per month',
                  description:
                      'For people who want every edge in their next move.',
                  features: const [
                    'Everything in Free',
                    'Unlimited AI resume and letter drafts',
                    'Advanced role matching insights',
                    'Priority AI proxy when configured',
                    'Unlimited practice history',
                  ],
                  current: isPro,
                  highlighted: true,
                  onSelect: isPro || _updating ? null : () => _choose('Pro'),
                  actionLabel: isPro ? 'Current plan' : 'Upgrade to Pro',
                  badge: 'Most popular',
                ),
                const SizedBox(height: 18),
                const InfoBanner(
                  message:
                      'Demo checkout: plans update instantly on this device and no payment is processed. Connect a billing provider before publishing.',
                  icon: Icons.info_outline_rounded,
                  color: AppColors.info,
                ),
                const SizedBox(height: 22),
                const SectionHeader(
                  title: 'Everything in one place',
                  subtitle: 'One subscription across every VEYORA tool',
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    children: const [
                      _FeatureRow(
                        icon: Icons.analytics_outlined,
                        title: 'Resume intelligence',
                        body:
                            'Score, ATS check, strengths, gaps, and a prioritized plan.',
                      ),
                      _FeatureRow(
                        icon: Icons.track_changes_rounded,
                        title: 'Job matching',
                        body:
                            'See matched and missing skills before you apply.',
                      ),
                      _FeatureRow(
                        icon: Icons.edit_note_rounded,
                        title: 'Cover letters',
                        body:
                            'Tailored letters in your voice, export-ready in seconds.',
                      ),
                      _FeatureRow(
                        icon: Icons.record_voice_over_outlined,
                        title: 'Interview coach',
                        body:
                            'Real questions, structured feedback, and model answers.',
                        last: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: Text(
                    'Cancel anytime · Your data stays on your device',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: isDark ? Colors.white38 : AppColors.inkMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BillingToggle extends StatelessWidget {
  const _BillingToggle({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? Colors.white.withValues(alpha: .1) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? .16 : .05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: selected
                ? (isDark ? Colors.white : AppColors.ink)
                : (isDark ? Colors.white54 : AppColors.inkMuted),
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.description,
    required this.features,
    required this.current,
    required this.onSelect,
    required this.actionLabel,
    this.highlighted = false,
    this.badge,
  });

  final String title;
  final String price;
  final String period;
  final String description;
  final List<String> features;
  final bool current;
  final VoidCallback? onSelect;
  final String actionLabel;
  final bool highlighted;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final borderColor = highlighted ? AppColors.primary : AppColors.outline;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark && highlighted
              ? AppColors.primary.withValues(alpha: .55)
              : borderColor,
          width: highlighted ? 1.6 : 1,
        ),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: isDark ? .18 : .1),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.2,
                  color: isDark ? Colors.white : AppColors.ink,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.heroGradient,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge!.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .7,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (current)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(
                      alpha: isDark ? .16 : .09,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'CURRENT',
                    style: TextStyle(
                      fontSize: 7.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .6,
                      color: AppColors.success,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: TextStyle(
                  fontSize: 32,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                  color: isDark ? Colors.white : AppColors.ink,
                ),
              ),
              const SizedBox(width: 5),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  period,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: isDark ? Colors.white38 : AppColors.inkMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(
              fontSize: 10.5,
              height: 1.5,
              color: isDark ? Colors.white54 : AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: 14),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: highlighted ? AppColors.primary : AppColors.success,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      feature,
                      style: TextStyle(
                        fontSize: 10.5,
                        height: 1.4,
                        color: isDark ? Colors.white70 : AppColors.inkMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          PrimaryButton(
            label: actionLabel,
            icon: current ? Icons.check_rounded : Icons.arrow_forward_rounded,
            onPressed: onSelect,
            height: 46,
            gradient: AppColors.heroGradient,
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.body,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(
            icon: icon,
            size: 34,
            color: AppColors.primary.withValues(alpha: isDark ? .16 : .07),
            iconColor: AppColors.primary,
            radius: 10,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.45,
                    color: isDark ? Colors.white54 : AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
