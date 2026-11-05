import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/local_store.dart';
import '../domain/app_user.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AuthRepository {
  AuthRepository(this._store, this._secureStorage);

  final LocalStore _store;
  final FlutterSecureStorage _secureStorage;
  static const _uuid = Uuid();

  Future<bool> hasSeenOnboarding() async =>
      _store.getBool(LocalStore.onboardingKey);

  Future<void> markOnboardingSeen() =>
      _store.setBool(LocalStore.onboardingKey, true);

  Future<AppUser?> restoreSession() async {
    try {
      final id = await _secureStorage.read(key: LocalStore.sessionKey);
      if (id == null || id.isEmpty) return null;
      final account = _accounts().where((a) => a.user.id == id).firstOrNullSafe;
      return account?.user;
    } catch (_) {
      return null;
    }
  }

  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (_accounts().any((a) => a.user.email.toLowerCase() == normalized)) {
      throw AuthException(
        'An account with this email already exists. Try signing in.',
      );
    }
    final salt = _newSalt();
    final user = AppUser(
      id: _uuid.v4(),
      name: name.trim(),
      email: normalized,
      createdAt: DateTime.now(),
    );
    final account = _Account(
      user: user,
      passwordHash: _hash(password, salt),
      salt: salt,
    );
    final accounts = _accounts()..add(account);
    await _saveAccounts(accounts);
    await _setSession(user.id);
    return user;
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final normalized = email.trim().toLowerCase();
    final account = _accounts()
        .where((a) => a.user.email.toLowerCase() == normalized)
        .firstOrNullSafe;
    if (account == null ||
        account.passwordHash != _hash(password, account.salt)) {
      throw AuthException('Incorrect email or password. Please try again.');
    }
    await _setSession(account.user.id);
    return account.user;
  }

  Future<AppUser> signInWithGoogle() async {
    const email = 'riya.sharma@veyora.app';
    final existing = _accounts()
        .where((a) => a.user.email.toLowerCase() == email)
        .firstOrNullSafe;
    if (existing != null) {
      await _setSession(existing.user.id);
      return existing.user;
    }
    final salt = _newSalt();
    final user = AppUser(
      id: _uuid.v4(),
      name: 'Riya Sharma',
      email: email,
      headline: 'Product Designer',
      location: 'Bengaluru, India',
      targetRole: 'Product Designer',
      bio:
          'Product designer focused on making complex workflows feel simple. I enjoy research, systems thinking, and shipping polished experiences.',
      phone: '+91 98765 43210',
      skills: const [
        'Figma',
        'User research',
        'Design systems',
        'Prototyping',
        'Accessibility',
      ],
      education: [
        EducationEntry(
          id: _uuid.v4(),
          school: 'National Institute of Design',
          degree: 'Bachelor of Design',
          field: 'Interaction Design',
          startYear: '2017',
          endYear: '2021',
        ),
      ],
      experience: [
        ExperienceEntry(
          id: _uuid.v4(),
          company: 'Lumen Labs',
          role: 'Product Designer',
          startDate: '2022',
          endDate: '',
          current: true,
          description:
              '• Led end-to-end redesign of the onboarding flow, improving activation by 24%.\n• Built a shared design system used by 4 product squads.\n• Partnered with research to run 30+ usability sessions.',
        ),
      ],
      profileCompleted: true,
      createdAt: DateTime.now(),
    );
    final account = _Account(
      user: user,
      passwordHash: _hash('GoogleDemo123', salt),
      salt: salt,
      provider: 'google',
    );
    final accounts = _accounts()..add(account);
    await _saveAccounts(accounts);
    await _setSession(user.id);
    return user;
  }

  Future<AppUser> signInAsDemo() async {
    const email = 'demo@veyora.app';
    final existing = _accounts()
        .where((a) => a.user.email.toLowerCase() == email)
        .firstOrNullSafe;
    if (existing != null) {
      await _setSession(existing.user.id);
      return existing.user;
    }
    final salt = _newSalt();
    final user = AppUser(
      id: _uuid.v4(),
      name: 'Aarav Mehta',
      email: email,
      headline: 'Flutter Developer & Product Builder',
      location: 'Pune, India',
      targetRole: 'Flutter Developer',
      bio:
          'Mobile engineer with 4 years of experience shipping consumer apps. I care about performance, clean architecture, and interfaces that feel effortless.',
      phone: '+91 90000 12345',
      skills: const [
        'Flutter',
        'Dart',
        'Firebase',
        'REST API',
        'Git',
        'Figma',
        'Unit testing',
      ],
      education: [
        EducationEntry(
          id: _uuid.v4(),
          school: 'Savitribai Phule Pune University',
          degree: 'B.E.',
          field: 'Computer Engineering',
          startYear: '2016',
          endYear: '2020',
          grade: '8.6 CGPA',
        ),
      ],
      experience: [
        ExperienceEntry(
          id: _uuid.v4(),
          company: 'Orbit Apps',
          role: 'Senior Flutter Developer',
          startDate: '2023',
          current: true,
          description:
              '• Architected a modular Flutter codebase used by 6 engineers and 2 products.\n• Reduced cold-start time by 38% through profiling and lazy initialization.\n• Shipped offline-first sync for 120k monthly active users.',
        ),
        ExperienceEntry(
          id: _uuid.v4(),
          company: 'Tandem Studio',
          role: 'Mobile Developer',
          startDate: '2020',
          endDate: '2023',
          description:
              '• Built and shipped 5 Flutter apps across fintech and wellness.\n• Introduced automated testing and CI, cutting regressions by 31%.\n• Partnered with designers to implement a reusable component library.',
        ),
      ],
      profileCompleted: true,
      plan: 'Pro',
      createdAt: DateTime.now(),
    );
    final account = _Account(
      user: user,
      passwordHash: _hash('Demo1234', salt),
      salt: salt,
      provider: 'demo',
    );
    final accounts = _accounts()..add(account);
    await _saveAccounts(accounts);
    await _setSession(user.id);
    return user;
  }

  Future<void> signOut() async {
    try {
      await _secureStorage.delete(key: LocalStore.sessionKey);
    } catch (_) {
      // Session is best-effort cleared; the in-memory state still signs out.
    }
  }

  Future<bool> emailExists(String email) async {
    final normalized = email.trim().toLowerCase();
    return _accounts().any((a) => a.user.email.toLowerCase() == normalized);
  }

  Future<void> resetPassword(String email, String newPassword) async {
    final normalized = email.trim().toLowerCase();
    final accounts = _accounts();
    final index = accounts.indexWhere(
      (a) => a.user.email.toLowerCase() == normalized,
    );
    if (index < 0) throw AuthException('No account found for that email.');
    final salt = _newSalt();
    accounts[index] = accounts[index].copyWith(
      passwordHash: _hash(newPassword, salt),
      salt: salt,
    );
    await _saveAccounts(accounts);
  }

  Future<AppUser> updateUser(AppUser user) async {
    final accounts = _accounts();
    final index = accounts.indexWhere((a) => a.user.id == user.id);
    if (index < 0) throw AuthException('Account not found.');
    accounts[index] = accounts[index].copyWith(user: user);
    await _saveAccounts(accounts);
    return user;
  }

  Future<void> deleteAccountData(String userId) => _store.clearUserData(userId);

  List<_Account> _accounts() {
    return _store
        .getJsonList(LocalStore.accountsKey)
        .map(_Account.fromJson)
        .toList();
  }

  Future<void> _saveAccounts(List<_Account> accounts) {
    return _store.setJsonList(
      LocalStore.accountsKey,
      accounts.map((a) => a.toJson()).toList(),
    );
  }

  Future<void> _setSession(String userId) async {
    try {
      await _secureStorage.write(key: LocalStore.sessionKey, value: userId);
    } catch (_) {
      // Secure storage can be unavailable on desktop without entitlements.
    }
    await _store.setString(LocalStore.sessionKey, userId);
  }

  String _newSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _hash(String password, String salt) {
    return sha256.convert(utf8.encode('$salt:$password')).toString();
  }
}

class _Account {
  const _Account({
    required this.user,
    required this.passwordHash,
    required this.salt,
    this.provider = 'email',
  });

  final AppUser user;
  final String passwordHash;
  final String salt;
  final String provider;

  _Account copyWith({
    AppUser? user,
    String? passwordHash,
    String? salt,
    String? provider,
  }) {
    return _Account(
      user: user ?? this.user,
      passwordHash: passwordHash ?? this.passwordHash,
      salt: salt ?? this.salt,
      provider: provider ?? this.provider,
    );
  }

  Map<String, dynamic> toJson() => {
    'user': user.toJson(),
    'passwordHash': passwordHash,
    'salt': salt,
    'provider': provider,
  };

  factory _Account.fromJson(Map<String, dynamic> json) => _Account(
    user: AppUser.fromJson(
      Map<String, dynamic>.from(json['user'] as Map? ?? const {}),
    ),
    passwordHash: json['passwordHash'] as String? ?? '',
    salt: json['salt'] as String? ?? '',
    provider: json['provider'] as String? ?? 'email',
  );
}

extension _FirstOrNullSafe<E> on Iterable<E> {
  E? get firstOrNullSafe {
    for (final item in this) {
      return item;
    }
    return null;
  }
}
