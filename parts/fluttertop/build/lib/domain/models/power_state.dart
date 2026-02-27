class PowerState {
  final double batteryPercentage; // 0.0 to 100.0
  final bool isCharging;
  final double powerDrawMw; // in milli-watts
  final double voltageNowMv; // in milli-volts
  final double currentNowMa; // in milli-amps

  PowerState({
    required this.batteryPercentage,
    required this.isCharging,
    required this.powerDrawMw,
    required this.voltageNowMv,
    required this.currentNowMa,
  });
}
