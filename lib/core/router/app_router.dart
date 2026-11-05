import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/profile_setup_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/interview/presentation/screens/interview_coach_screen.dart';
import '../../features/interview/presentation/screens/interview_result_screen.dart';
import '../../features/interview/presentation/screens/interview_session_screen.dart';
import '../../features/jobs/domain/job.dart';
import '../../features/jobs/presentation/screens/job_details_screen.dart';
import '../../features/jobs/presentation/screens/jobs_screen.dart';
import '../../features/jobs/presentation/screens/saved_jobs_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/onboarding/presentation/splash_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/profile/presentation/screens/subscription_screen.dart';
import '../../features/resume/presentation/screens/analysis_result_screen.dart';
import '../../features/resume/presentation/screens/cover_letter_screen.dart';
import '../../features/resume/presentation/screens/job_matcher_screen.dart';
import '../../features/resume/presentation/screens/resume_analyzer_screen.dart';
import '../../features/resume/presentation/screens/resume_builder_screen.dart';
import '../../features/resume/presentation/screens/resume_hub_screen.dart';
import '../widgets/app_widgets.dart';
import 'main_shell.dart';

class _AuthRefresh extends ChangeNotifier {
  void refresh() => notifyListeners();
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh();
  ref.onDispose(refresh.dispose);
  ref.read(authControllerProvider);
  ref.listen<AuthState>(authControllerProvider, (_, _) => refresh.refresh());

  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      return _redirect(auth, state);
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/resume',
                builder: (context, state) => const ResumeHubScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/jobs',
                builder: (context, state) => const JobsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/coach',
                builder: (context, state) => const InterviewCoachScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/app/analyzer',
        builder: (context, state) => const ResumeAnalyzerScreen(),
      ),
      GoRoute(
        path: '/app/analysis/:id',
        builder: (context, state) =>
            AnalysisResultScreen(analysisId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/app/builder',
        builder: (context, state) =>
            ResumeBuilderScreen(resumeId: state.uri.queryParameters['id']),
      ),
      GoRoute(
        path: '/app/job-matcher',
        builder: (context, state) => JobMatcherScreen(
          prefillJob: state.extra is Job ? state.extra as Job : null,
        ),
      ),
      GoRoute(
        path: '/app/cover-letter',
        builder: (context, state) => CoverLetterScreen(
          letterId: state.uri.queryParameters['id'],
          prefill: _prefill(state.extra),
        ),
      ),
      GoRoute(
        path: '/app/jobs/:id',
        builder: (context, state) =>
            JobDetailsScreen(jobId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/app/saved-jobs',
        builder: (context, state) => const SavedJobsScreen(),
      ),
      GoRoute(
        path: '/app/interview/session',
        builder: (context, state) => const InterviewSessionScreen(),
      ),
      GoRoute(
        path: '/app/interview/result/:id',
        builder: (context, state) =>
            InterviewResultScreen(sessionId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/app/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/app/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/app/subscription',
        builder: (context, state) => const SubscriptionScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: EmptyState(
        icon: Icons.explore_off_outlined,
        title: 'Page not found',
        message:
            'That route does not exist in VEYORA. Head back to your dashboard.',
        actionLabel: 'Go to dashboard',
        onAction: () => context.go('/app/home'),
      ),
    ),
  );
  ref.onDispose(router.dispose);
  return router;
});

String? _redirect(AuthState auth, GoRouterState state) {
  final path = state.matchedLocation;
  final atSplash = path == '/splash';
  final atOnboarding = path == '/onboarding';
  final atAuthRoute =
      path == '/login' || path == '/signup' || path == '/forgot-password';
  final atProfileSetup = path == '/profile-setup';

  if (!auth.initialized) {
    return atSplash ? null : '/splash';
  }

  if (!auth.isAuthenticated) {
    if (atSplash) {
      return auth.hasSeenOnboarding ? '/login' : '/onboarding';
    }
    if (atOnboarding || atAuthRoute) return null;
    return auth.hasSeenOnboarding ? '/login' : '/onboarding';
  }

  if (!auth.profileComplete) {
    return atProfileSetup ? null : '/profile-setup';
  }

  if (atSplash || atOnboarding || atAuthRoute || atProfileSetup) {
    return '/app/home';
  }
  return null;
}

Map<String, String>? _prefill(Object? extra) {
  if (extra is Map<String, String>) return extra;
  if (extra is Map) {
    return extra.map(
      (key, value) => MapEntry(key.toString(), value.toString()),
    );
  }
  return null;
}
