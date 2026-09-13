enum AcMode { auto, cool, heat, dry, fan }

enum FanSpeed { auto, low, medium, high, turbo }

class AcControlState {
  const AcControlState({
    this.isPowered = true,
    this.temperature = 22,
    this.mode = AcMode.cool,
    this.fanSpeed = FanSpeed.auto,
    this.verticalSwing = true,
    this.horizontalSwing = false,
    this.ecoEnabled = false,
    this.sleepEnabled = false,
    this.turboEnabled = false,
    this.lightEnabled = true,
    this.quietEnabled = false,
  });

  final bool isPowered;
  final int temperature;
  final AcMode mode;
  final FanSpeed fanSpeed;
  final bool verticalSwing;
  final bool horizontalSwing;
  final bool ecoEnabled;
  final bool sleepEnabled;
  final bool turboEnabled;
  final bool lightEnabled;
  final bool quietEnabled;

  AcControlState copyWith({
    bool? isPowered,
    int? temperature,
    AcMode? mode,
    FanSpeed? fanSpeed,
    bool? verticalSwing,
    bool? horizontalSwing,
    bool? ecoEnabled,
    bool? sleepEnabled,
    bool? turboEnabled,
    bool? lightEnabled,
    bool? quietEnabled,
  }) => AcControlState(
    isPowered: isPowered ?? this.isPowered,
    temperature: temperature ?? this.temperature,
    mode: mode ?? this.mode,
    fanSpeed: fanSpeed ?? this.fanSpeed,
    verticalSwing: verticalSwing ?? this.verticalSwing,
    horizontalSwing: horizontalSwing ?? this.horizontalSwing,
    ecoEnabled: ecoEnabled ?? this.ecoEnabled,
    sleepEnabled: sleepEnabled ?? this.sleepEnabled,
    turboEnabled: turboEnabled ?? this.turboEnabled,
    lightEnabled: lightEnabled ?? this.lightEnabled,
    quietEnabled: quietEnabled ?? this.quietEnabled,
  );

  factory AcControlState.fromJson(Map<String, Object?> json) => AcControlState(
    isPowered: json['isPowered'] as bool? ?? false,
    temperature: json['temperature'] as int? ?? 22,
    mode: AcMode.values.byName(json['mode'] as String? ?? AcMode.cool.name),
    fanSpeed: FanSpeed.values.byName(
      json['fanSpeed'] as String? ?? FanSpeed.auto.name,
    ),
    verticalSwing: json['verticalSwing'] as bool? ?? false,
    horizontalSwing: json['horizontalSwing'] as bool? ?? false,
    ecoEnabled: json['ecoEnabled'] as bool? ?? false,
    sleepEnabled: json['sleepEnabled'] as bool? ?? false,
    turboEnabled: json['turboEnabled'] as bool? ?? false,
    lightEnabled: json['lightEnabled'] as bool? ?? true,
    quietEnabled: json['quietEnabled'] as bool? ?? false,
  );

  Map<String, Object?> toJson() => {
    'isPowered': isPowered,
    'temperature': temperature,
    'mode': mode.name,
    'fanSpeed': fanSpeed.name,
    'verticalSwing': verticalSwing,
    'horizontalSwing': horizontalSwing,
    'ecoEnabled': ecoEnabled,
    'sleepEnabled': sleepEnabled,
    'turboEnabled': turboEnabled,
    'lightEnabled': lightEnabled,
    'quietEnabled': quietEnabled,
  };
}
