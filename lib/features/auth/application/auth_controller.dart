import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/auth_repository.dart';
import '../domain/app_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(localStoreProvider),
    ref.watch(secureStorageProvider),
  );
});

class AuthState {
  const AuthState({
    this.initialized = false,
    this.hasSeenOnboarding = false,
    this.user,
    this.loading = false,
    this.error,
  });

  final bool initialized;
  final bool hasSeenOnboarding;
  final AppUser? user;
  final bool loading;
  final String? error;

  bool get isAuthenticated => user != null;

  bool get profileComplete => user?.profileCompleted ?? false;

  AuthState copyWith({
    bool? initialized,
    bool? hasSeenOnboarding,
    AppUser? user,
    bool clearUser = false,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      initialized: initialized ?? this.initialized,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
      user: clearUser ? null : (user ?? this.user),
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository) : super(const AuthState()) {
    _initialize();
  }

  final AuthRepository _repository;

  Future<void> _initialize() async {
    final seen = await _repository.hasSeenOnboarding();
    AppUser? user;
    try {
      user = await _repository.restoreSession();
    } catch (_) {
      user = null;
    }
    await Future<void>.delayed(const Duration(milliseconds: 2100));
    if (!mounted) return;
    state = AuthState(initialized: true, hasSeenOnboarding: seen, user: user);
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final user = await _repository.signIn(email: email, password: password);
      state = state.copyWith(
        user: user,
        loading: false,
        initialized: true,
        clearError: true,
      );
      return true;
    } on AuthException catch (error) {
      state = state.copyWith(loading: false, error: error.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        loading: false,
        error: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }

  Future<bool> signUp(String name, String email, String password) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final user = await _repository.signUp(
        name: name,
        email: email,
        password: password,
      );
      state = state.copyWith(
        user: user,
        loading: false,
        initialized: true,
        clearError: true,
      );
      return true;
    } on AuthException catch (error) {
      state = state.copyWith(loading: false, error: error.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        loading: false,
        error: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final user = await _repository.signInWithGoogle();
      state = state.copyWith(
        user: user,
        loading: false,
        initialized: true,
        clearError: true,
      );
      return true;
    } catch (_) {
      state = state.copyWith(
        loading: false,
        error: 'Google sign-in could not be completed. Please try again.',
      );
      return false;
    }
  }

  Future<bool> signInAsDemo() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final user = await _repository.signInAsDemo();
      state = state.copyWith(
        user: user,
        loading: false,
        initialized: true,
        clearError: true,
      );
      return true;
    } catch (_) {
      state = state.copyWith(
        loading: false,
        error: 'The demo account could not be opened. Please try again.',
      );
      return false;
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    if (!mounted) return;
    state = state.copyWith(clearUser: true, loading: false, clearError: true);
  }

  Future<bool> updateProfile(AppUser user) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final updated = await _repository.updateUser(user);
      state = state.copyWith(user: updated, loading: false, clearError: true);
      return true;
    } catch (_) {
      state = state.copyWith(
        loading: false,
        error: 'Could not save your profile. Please try again.',
      );
      return false;
    }
  }

  Future<bool> completeProfile({
    required String name,
    required String headline,
    required String location,
    required String targetRole,
    required String bio,
    required String phone,
    required List<String> skills,
    List<EducationEntry>? education,
    List<ExperienceEntry>? experience,
  }) async {
    final current = state.user;
    if (current == null) return false;
    final updated = current.copyWith(
      name: name,
      headline: headline,
      location: location,
      targetRole: targetRole,
      bio: bio,
      phone: phone,
      skills: skills,
      education: education ?? current.education,
      experience: experience ?? current.experience,
      profileCompleted: true,
    );
    return updateProfile(updated);
  }

  Future<bool> updatePlan(String plan) async {
    final current = state.user;
    if (current == null) return false;
    return updateProfile(current.copyWith(plan: plan));
  }

  Future<bool> emailExists(String email) => _repository.emailExists(email);

  Future<bool> resetPassword(String email, String password) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      await _repository.resetPassword(email, password);
      state = state.copyWith(loading: false, clearError: true);
      return true;
    } on AuthException catch (error) {
      state = state.copyWith(loading: false, error: error.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        loading: false,
        error: 'Password reset failed. Please try again.',
      );
      return false;
    }
  }

  Future<void> markOnboardingSeen() async {
    await _repository.markOnboardingSeen();
    if (!mounted) return;
    state = state.copyWith(hasSeenOnboarding: true);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(ref.watch(authRepositoryProvider));
  },
);

final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authControllerProvider).user;
});
