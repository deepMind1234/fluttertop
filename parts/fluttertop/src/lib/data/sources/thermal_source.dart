import 'dart:io';

import '../../domain/models/thermal_state.dart';
import '../../core/constants/system_paths.dart';

class ThermalDataSource {
  Future<SystemThermalState> getThermalState() async {
    final List<ThermalSensor> sensors = [];

    try {
      final dir = Directory(SystemPaths.sysClassThermal);
      if (!await dir.exists()) return SystemThermalState(sensors: []);

      final entities = await dir.list().toList();
      for (var entity in entities) {
        if (entity is Directory && entity.path.contains('thermal_zone')) {
          try {
            final typeFile = File('${entity.path}/type');
            final tempFile = File('${entity.path}/temp');

            if (await typeFile.exists() && await tempFile.exists()) {
              final type = (await typeFile.readAsString()).trim();
              final tempRaw = (await tempFile.readAsString()).trim();

              final tempMilliCelsius = int.tryParse(tempRaw);
              if (tempMilliCelsius != null) {
                // Some paths report in millidegrees, others might be direct
                // Typically thermal_zone reports millicelsius.
                double tempCelsius = tempMilliCelsius / 1000.0;

                sensors.add(
                  ThermalSensor(type: type, tempCelsius: tempCelsius),
                );
              }
            }
          } catch (e) {
            // Ignore individual sensor read errors (some might require root or be disconnected)
          }
        }
      }
    } catch (e) {
      // Error parsing thermal zones
    }

    return SystemThermalState(sensors: sensors);
  }
}
