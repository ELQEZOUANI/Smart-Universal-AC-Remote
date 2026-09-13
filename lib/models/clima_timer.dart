class ClimaTimer {
  const ClimaTimer({
    required this.id,
    required this.time,
    required this.action,
    this.detail,
    this.enabled = true,
  });

  final String id;
  final String time;
  final String action;
  final String? detail;
  final bool enabled;

  ClimaTimer copyWith({bool? enabled, String? time}) => ClimaTimer(
    id: id,
    time: time ?? this.time,
    action: action,
    detail: detail,
    enabled: enabled ?? this.enabled,
  );

  factory ClimaTimer.fromJson(Map<String, Object?> json) => ClimaTimer(
    id: json['id']! as String,
    time: json['time']! as String,
    action: json['action']! as String,
    detail: json['detail'] as String?,
    enabled: json['enabled'] as bool? ?? true,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'time': time,
    'action': action,
    'detail': detail,
    'enabled': enabled,
  };
}
