class ThermalSensor {
  final String type;
  final double tempCelsius;

  ThermalSensor({
    required this.type,
    required this.tempCelsius,
  });
}

class SystemThermalState {
  final List<ThermalSensor> sensors;

  SystemThermalState({required this.sensors});

  double? get packageTemp {
    try {
      return sensors.firstWhere((s) => s.type.toLowerCase().contains('x86_pkg_temp') || s.type.toLowerCase().contains('coretemp')).tempCelsius;
    } catch (_) {
      return sensors.isNotEmpty ? sensors.first.tempCelsius : null;
    }
  }
}
