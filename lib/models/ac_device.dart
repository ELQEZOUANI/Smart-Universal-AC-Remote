class AcDevice {
  const AcDevice({
    required this.id,
    required this.name,
    required this.room,
    required this.brand,
    required this.model,
    required this.ipAddress,
    required this.port,
    required this.isOnline,
    this.roomTemperature,
  });

  final String id;
  final String name;
  final String room;
  final String brand;
  final String model;
  final String ipAddress;
  final int port;
  final bool isOnline;
  final double? roomTemperature;

  AcDevice copyWith({
    String? name,
    String? room,
    bool? isOnline,
    double? roomTemperature,
  }) => AcDevice(
    id: id,
    name: name ?? this.name,
    room: room ?? this.room,
    brand: brand,
    model: model,
    ipAddress: ipAddress,
    port: port,
    isOnline: isOnline ?? this.isOnline,
    roomTemperature: roomTemperature ?? this.roomTemperature,
  );

  factory AcDevice.fromJson(Map<String, Object?> json) => AcDevice(
    id: json['id']! as String,
    name: json['name']! as String,
    room: json['room']! as String,
    brand: json['brand']! as String,
    model: json['model']! as String,
    ipAddress: json['ipAddress']! as String,
    port: json['port']! as int,
    isOnline: json['isOnline']! as bool,
    roomTemperature: (json['roomTemperature'] as num?)?.toDouble(),
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'room': room,
    'brand': brand,
    'model': model,
    'ipAddress': ipAddress,
    'port': port,
    'isOnline': isOnline,
    'roomTemperature': roomTemperature,
  };
}
