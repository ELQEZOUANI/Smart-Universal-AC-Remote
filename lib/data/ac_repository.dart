import '../models/ac_control_state.dart';

abstract interface class AcRepository {
  Future<void> powerOn();
  Future<void> powerOff();
  Future<void> setTemperature(int temperature);
  Future<void> setMode(AcMode mode);
  Future<void> setFanSpeed(FanSpeed speed);
  Future<void> setVerticalSwing(bool enabled);
  Future<void> setHorizontalSwing(bool enabled);
}

class LocalAcRepository implements AcRepository {
  const LocalAcRepository();

  Future<void> _acknowledgeCommand() =>
      Future<void>.delayed(const Duration(milliseconds: 80));

  @override
  Future<void> powerOff() => _acknowledgeCommand();
  @override
  Future<void> powerOn() => _acknowledgeCommand();
  @override
  Future<void> setFanSpeed(FanSpeed speed) => _acknowledgeCommand();
  @override
  Future<void> setHorizontalSwing(bool enabled) => _acknowledgeCommand();
  @override
  Future<void> setMode(AcMode mode) => _acknowledgeCommand();
  @override
  Future<void> setTemperature(int temperature) => _acknowledgeCommand();
  @override
  Future<void> setVerticalSwing(bool enabled) => _acknowledgeCommand();
}
