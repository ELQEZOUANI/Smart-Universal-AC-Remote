import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TemperatureUnit { celsius, fahrenheit }

class SettingsState {
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.temperatureUnit = TemperatureUnit.celsius,
    this.haptics = true,
    this.autoConnect = true,
  });

  final ThemeMode themeMode;
  final TemperatureUnit temperatureUnit;
  final bool haptics;
  final bool autoConnect;

  SettingsState copyWith({
    ThemeMode? themeMode,
    TemperatureUnit? temperatureUnit,
    bool? haptics,
    bool? autoConnect,
  }) => SettingsState(
    themeMode: themeMode ?? this.themeMode,
    temperatureUnit: temperatureUnit ?? this.temperatureUnit,
    haptics: haptics ?? this.haptics,
    autoConnect: autoConnect ?? this.autoConnect,
  );
}

class SettingsController extends Notifier<SettingsState> {
  static const _themeKey = 'climalink.theme_mode';
  static const _unitKey = 'climalink.temperature_unit';
  static const _hapticsKey = 'climalink.haptics';
  static const _autoConnectKey = 'climalink.auto_connect';

  @override
  SettingsState build() {
    unawaited(_restore());
    return const SettingsState();
  }

  Future<void> _restore() async {
    final preferences = await SharedPreferences.getInstance();
    if (!ref.mounted) return;
    final themeName = preferences.getString(_themeKey);
    final unitName = preferences.getString(_unitKey);
    state = SettingsState(
      themeMode: themeName == null
          ? ThemeMode.system
          : ThemeMode.values.byName(themeName),
      temperatureUnit: unitName == null
          ? TemperatureUnit.celsius
          : TemperatureUnit.values.byName(unitName),
      haptics: preferences.getBool(_hapticsKey) ?? true,
      autoConnect: preferences.getBool(_autoConnectKey) ?? true,
    );
  }

  void _commit(SettingsState nextState) {
    state = nextState;
    unawaited(_persist());
  }

  Future<void> _persist() async {
    final snapshot = state;
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.setString(_themeKey, snapshot.themeMode.name),
      preferences.setString(_unitKey, snapshot.temperatureUnit.name),
      preferences.setBool(_hapticsKey, snapshot.haptics),
      preferences.setBool(_autoConnectKey, snapshot.autoConnect),
    ]);
  }

  void setTheme(ThemeMode value) => _commit(state.copyWith(themeMode: value));
  void setUnit(TemperatureUnit value) =>
      _commit(state.copyWith(temperatureUnit: value));
  void toggleHaptics() => _commit(state.copyWith(haptics: !state.haptics));
  void toggleAutoConnect() =>
      _commit(state.copyWith(autoConnect: !state.autoConnect));
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(SettingsController.new);
