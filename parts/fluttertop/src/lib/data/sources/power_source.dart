import 'dart:io';

import '../../domain/models/power_state.dart';
import '../../core/constants/system_paths.dart';

class PowerDataSource {
  Future<PowerState?> getPowerState() async {
    try {
      final powerSupplyDir = Directory(SystemPaths.sysClassPowerSupply);
      if (!await powerSupplyDir.exists()) return null;

      final supplies = await powerSupplyDir.list().toList();

      for (var supply in supplies) {
        final name = supply.path.split('/').last;

        // Typically battery starts with BAT or BATT (e.g. BAT0, BAT1)
        if (name.startsWith('BAT')) {
          final capacityFile = File('${supply.path}/capacity');
          final statusFile = File('${supply.path}/status');
          final powerNowFile = File('${supply.path}/power_now');
          final voltageNowFile = File('${supply.path}/voltage_now');
          final currentNowFile = File('${supply.path}/current_now');

          double batteryPercentage = 0;
          bool isCharging = false;
          double powerDrawMw = 0;
          double voltageNowMv = 0;
          double currentNowMa = 0;

          if (await capacityFile.exists()) {
            final capacityStr = (await capacityFile.readAsString()).trim();
            batteryPercentage = double.tryParse(capacityStr) ?? 0.0;
          }

          if (await statusFile.exists()) {
            final statusStr = (await statusFile.readAsString()).trim();
            isCharging = statusStr == 'Charging';
          }

          // power_now is in micro-watts (uW), convert to milli-watts (mW)
          if (await powerNowFile.exists()) {
            final powerNowStr = (await powerNowFile.readAsString()).trim();
            final powerNowUw = double.tryParse(powerNowStr) ?? 0.0;
            powerDrawMw = powerNowUw / 1000.0;
          }

          // voltage_now is in micro-volts (uV), convert to volts
          if (await voltageNowFile.exists()) {
            final voltageNowStr = (await voltageNowFile.readAsString()).trim();
            final voltageNowUv = double.tryParse(voltageNowStr) ?? 0.0;
            voltageNowMv = voltageNowUv / 1000.0; // keep as mv for state
          }

          // current_now is in micro-amps (uA), convert to amps
          if (await currentNowFile.exists()) {
            final currentNowStr = (await currentNowFile.readAsString()).trim();
            final currentNowUa = double.tryParse(currentNowStr) ?? 0.0;
            currentNowMa = currentNowUa / 1000.0; // keep as ma for state
          }

          // Calculate power from voltage and current if power_now is unavailable
          if (powerDrawMw == 0 && voltageNowMv > 0 && currentNowMa > 0) {
            // Power (mW) = Voltage (V) * Current (mA)
            // Voltage (V) = voltageNowMv / 1000.0
            powerDrawMw = (voltageNowMv / 1000.0) * currentNowMa;
          }

          // The UI currently treats powerDrawMw as Watts (e.g. prints "W"),
          // so we should convert our mW calculation to Watts before returning it.
          // Or if the original intention was to return Watts, let's just make it return Watts.
          // Since the field is called `powerDrawMw`, it implies mW. But UI prints W.
          // To fix the 0W issue and the unit scale issue simultaneously, we divide by 1000 here
          // to make it Watts, so it says "15.2 W" instead of "15200.0 W" in the UI.
          powerDrawMw = powerDrawMw / 1000.0;

          // Ensure positive power draw on some systems
          if (powerDrawMw < 0) powerDrawMw = powerDrawMw * -1.0;

          return PowerState(
            batteryPercentage: batteryPercentage,
            isCharging: isCharging,
            powerDrawMw: powerDrawMw,
            voltageNowMv: voltageNowMv,
            currentNowMa: currentNowMa,
          );
        }
      }

      return null;
    } catch (e) {
      // Ignore parsing errors for unavailable files
      return null;
    }
  }
}
