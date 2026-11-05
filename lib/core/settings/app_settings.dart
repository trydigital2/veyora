import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../storage/local_store.dart';

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.light,
    this.notifications = true,
    this.haptics = true,
  });

  final ThemeMode themeMode;
  final bool notifications;
  final bool haptics;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? notifications,
    bool? haptics,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      notifications: notifications ?? this.notifications,
      haptics: haptics ?? this.haptics,
    );
  }

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.name,
    'notifications': notifications,
    'haptics': haptics,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    themeMode: ThemeMode.values.firstWhere(
      (mode) => mode.name == json['themeMode'],
      orElse: () => ThemeMode.light,
    ),
    notifications: json['notifications'] as bool? ?? true,
    haptics: json['haptics'] as bool? ?? true,
  );
}

class SettingsController extends StateNotifier<AppSettings> {
  SettingsController(this._store) : super(_load(_store));

  final LocalStore _store;

  static AppSettings _load(LocalStore store) {
    final json = store.getJson(LocalStore.settingsKey);
    if (json == null) return const AppSettings();
    return AppSettings.fromJson(json);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _store.setJson(LocalStore.settingsKey, state.toJson());
  }

  Future<void> toggleTheme() async {
    await setThemeMode(
      state.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }

  Future<void> setNotifications(bool enabled) async {
    state = state.copyWith(notifications: enabled);
    await _store.setJson(LocalStore.settingsKey, state.toJson());
  }

  Future<void> setHaptics(bool enabled) async {
    state = state.copyWith(haptics: enabled);
    await _store.setJson(LocalStore.settingsKey, state.toJson());
  }
}

final settingsProvider = StateNotifierProvider<SettingsController, AppSettings>(
  (ref) {
    return SettingsController(ref.watch(localStoreProvider));
  },
);
