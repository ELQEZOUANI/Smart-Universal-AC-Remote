import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/ac_repository.dart';
import '../../../models/ac_control_state.dart';
import '../../../models/ac_device.dart';
import '../../../models/clima_timer.dart';

class ClimaAppState {
  const ClimaAppState({
    required this.devices,
    required this.selectedDeviceId,
    required this.control,
    required this.timers,
    required this.remoteUnlocked,
  });

  final List<AcDevice> devices;
  final String? selectedDeviceId;
  final AcControlState control;
  final List<ClimaTimer> timers;
  final bool remoteUnlocked;

  AcDevice? get selectedDevice {
    for (final device in devices) {
      if (device.id == selectedDeviceId) return device;
    }
    return devices.isEmpty ? null : devices.first;
  }

  ClimaAppState copyWith({
    List<AcDevice>? devices,
    String? selectedDeviceId,
    bool clearSelectedDevice = false,
    AcControlState? control,
    List<ClimaTimer>? timers,
    bool? remoteUnlocked,
  }) => ClimaAppState(
    devices: devices ?? this.devices,
    selectedDeviceId: clearSelectedDevice
        ? null
        : selectedDeviceId ?? this.selectedDeviceId,
    control: control ?? this.control,
    timers: timers ?? this.timers,
    remoteUnlocked: remoteUnlocked ?? this.remoteUnlocked,
  );

  factory ClimaAppState.fromJson(Map<String, Object?> json) {
    final devices = (json['devices'] as List<Object?>? ?? const [])
        .map(
          (item) => AcDevice.fromJson(Map<String, Object?>.from(item! as Map)),
        )
        .toList();
    final selectedId = json['selectedDeviceId'] as String?;
    return ClimaAppState(
      devices: devices,
      selectedDeviceId: devices.any((device) => device.id == selectedId)
          ? selectedId
          : devices.firstOrNull?.id,
      control: json['control'] is Map
          ? AcControlState.fromJson(
              Map<String, Object?>.from(json['control']! as Map),
            )
          : const AcControlState(isPowered: false),
      timers: (json['timers'] as List<Object?>? ?? const [])
          .map(
            (item) =>
                ClimaTimer.fromJson(Map<String, Object?>.from(item! as Map)),
          )
          .toList(),
      remoteUnlocked: json['remoteUnlocked'] as bool? ?? false,
    );
  }

  Map<String, Object?> toJson() => {
    'devices': devices.map((device) => device.toJson()).toList(),
    'selectedDeviceId': selectedDeviceId,
    'control': control.toJson(),
    'timers': timers.map((timer) => timer.toJson()).toList(),
    'remoteUnlocked': remoteUnlocked,
  };
}

class AcController extends Notifier<ClimaAppState> {
  // V6 begins with a clean production state for the first store submission.
  static const _storageKey = 'climalink.app_state.v6';
  final AcRepository _repository = const LocalAcRepository();

  @override
  ClimaAppState build() {
    unawaited(_restore());
    return const ClimaAppState(
      selectedDeviceId: null,
      devices: [],
      control: AcControlState(isPowered: false),
      timers: [],
      remoteUnlocked: false,
    );
  }

  Future<void> _restore() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_storageKey);
    if (encoded == null || !ref.mounted) return;
    try {
      final restored = ClimaAppState.fromJson(
        Map<String, Object?>.from(jsonDecode(encoded) as Map),
      );
      state = restored;
    } on FormatException {
      await preferences.remove(_storageKey);
    }
  }

  void _commit(ClimaAppState nextState) {
    state = nextState;
    unawaited(_persist());
  }

  Future<void> _persist() async {
    final encoded = jsonEncode(state.toJson());
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, encoded);
  }

  void selectDevice(String id) => _commit(state.copyWith(selectedDeviceId: id));

  /// Persists the one-time rewarded-ad entitlement for remote access.
  Future<void> unlockRemote() async {
    state = state.copyWith(remoteUnlocked: true);
    await _persist();
  }

  Future<void> togglePower() async {
    final enabled = !state.control.isPowered;
    _commit(
      state.copyWith(control: state.control.copyWith(isPowered: enabled)),
    );
    enabled ? await _repository.powerOn() : await _repository.powerOff();
  }

  Future<void> setTemperature(int value) async {
    final temperature = value.clamp(16, 30);
    _commit(
      state.copyWith(control: state.control.copyWith(temperature: temperature)),
    );
    await _repository.setTemperature(temperature);
  }

  Future<void> setMode(AcMode mode) async {
    _commit(state.copyWith(control: state.control.copyWith(mode: mode)));
    await _repository.setMode(mode);
  }

  Future<void> setFanSpeed(FanSpeed speed) async {
    _commit(state.copyWith(control: state.control.copyWith(fanSpeed: speed)));
    await _repository.setFanSpeed(speed);
  }

  Future<void> toggleVerticalSwing() async {
    final value = !state.control.verticalSwing;
    _commit(
      state.copyWith(control: state.control.copyWith(verticalSwing: value)),
    );
    await _repository.setVerticalSwing(value);
  }

  Future<void> toggleHorizontalSwing() async {
    final value = !state.control.horizontalSwing;
    _commit(
      state.copyWith(control: state.control.copyWith(horizontalSwing: value)),
    );
    await _repository.setHorizontalSwing(value);
  }

  void toggleFunction(String function) {
    final control = state.control;
    _commit(
      state.copyWith(
        control: switch (function) {
          'eco' => control.copyWith(ecoEnabled: !control.ecoEnabled),
          'sleep' => control.copyWith(sleepEnabled: !control.sleepEnabled),
          'turbo' => control.copyWith(turboEnabled: !control.turboEnabled),
          'light' => control.copyWith(lightEnabled: !control.lightEnabled),
          'quiet' => control.copyWith(quietEnabled: !control.quietEnabled),
          _ => control,
        },
      ),
    );
  }

  void addDevice(AcDevice device) {
    final devices = [
      for (final savedDevice in state.devices)
        if (savedDevice.id != device.id &&
            savedDevice.ipAddress != device.ipAddress)
          savedDevice,
      device,
    ];
    _commit(state.copyWith(devices: devices, selectedDeviceId: device.id));
  }

  void renameDevice(String id, String name) => _commit(
    state.copyWith(
      devices: [
        for (final device in state.devices)
          if (device.id == id) device.copyWith(name: name) else device,
      ],
    ),
  );

  void changeRoom(String id, String room) => _commit(
    state.copyWith(
      devices: [
        for (final device in state.devices)
          if (device.id == id) device.copyWith(room: room) else device,
      ],
    ),
  );

  void reconnect(String id) => _commit(
    state.copyWith(
      devices: [
        for (final device in state.devices)
          if (device.id == id) device.copyWith(isOnline: true) else device,
      ],
    ),
  );

  void removeDevice(String id) {
    final devices = state.devices.where((device) => device.id != id).toList();
    final selectedId = state.selectedDeviceId == id
        ? devices.firstOrNull?.id
        : state.selectedDeviceId;
    _commit(
      state.copyWith(
        devices: devices,
        selectedDeviceId: selectedId,
        clearSelectedDevice: selectedId == null,
      ),
    );
  }

  void toggleTimer(String id) => _commit(
    state.copyWith(
      timers: [
        for (final timer in state.timers)
          if (timer.id == id)
            timer.copyWith(enabled: !timer.enabled)
          else
            timer,
      ],
    ),
  );

  void removeTimer(String id) => _commit(
    state.copyWith(
      timers: state.timers.where((timer) => timer.id != id).toList(),
    ),
  );

  void addTimer(ClimaTimer timer) =>
      _commit(state.copyWith(timers: [...state.timers, timer]));
}

final acControllerProvider = NotifierProvider<AcController, ClimaAppState>(
  AcController.new,
);
