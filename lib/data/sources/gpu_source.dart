import 'dart:io';

import '../../domain/models/gpu_state.dart';
import '../../core/constants/system_paths.dart';

class GpuSysfsSource {
  Future<List<GpuSysfsState>> getGpuState() async {
    List<GpuSysfsState> gpus = [];
    try {
      // Trying AMD amdgpu sysfs as an example (very common for native Linux GPU stats)
      // /sys/class/hwmon/hwmon*/device/gpu_busy_percent
      // /sys/class/hwmon/hwmon*/device/mem_info_vram_used vs mem_info_vram_total

      final hwmonDir = Directory(SystemPaths.sysClassHwmon);
      if (await hwmonDir.exists()) {
        final entities = await hwmonDir.list().toList();
        for (var entity in entities) {
          if (entity is Directory) {
            final nameFile = File('${entity.path}/name');
            if (await nameFile.exists()) {
              final name = (await nameFile.readAsString()).trim();
              if (name == 'amdgpu') {
                final busyFile = File('${entity.path}/device/gpu_busy_percent');
                double busyPct = 0.0;
                if (await busyFile.exists()) {
                  busyPct =
                      double.tryParse(await busyFile.readAsString()) ?? 0.0;
                }

                final vramUsedFile = File(
                  '${entity.path}/device/mem_info_vram_used',
                );
                final vramTotalFile = File(
                  '${entity.path}/device/mem_info_vram_total',
                );

                double vramPct = 0.0;
                if (await vramUsedFile.exists() &&
                    await vramTotalFile.exists()) {
                  final used =
                      int.tryParse(await vramUsedFile.readAsString()) ?? 0;
                  final total =
                      int.tryParse(await vramTotalFile.readAsString()) ?? 1;
                  vramPct = (used / total) * 100.0;
                }

                gpus.add(
                  GpuSysfsState(
                    deviceName: 'AMD GPU',
                    gpuUsagePercentage: busyPct <= 0 ? 0 : busyPct,
                    memUsagePercentage: vramPct <= 0 ? 0 : vramPct,
                  ),
                );
              }
            }
          }
        }
      }

      // Fallback/Addition: Try nvidia-smi for discrete Nvidia cards
      try {
        final result = await Process.run('nvidia-smi', [
          '--query-gpu=name,utilization.gpu,memory.used,memory.total',
          '--format=csv,noheader,nounits',
        ]);

        if (result.exitCode == 0) {
          final lines = result.stdout.toString().trim().split('\n');
          for (var line in lines) {
            if (line.isEmpty) continue;
            final parts = line.split(',');
            if (parts.length >= 4) {
              final name = parts[0].trim();
              final util = double.tryParse(parts[1].trim()) ?? 0.0;
              final memUsed = double.tryParse(parts[2].trim()) ?? 0.0;
              final memTotal = double.tryParse(parts[3].trim()) ?? 1.0;
              final memPct = (memUsed / memTotal) * 100.0;
              gpus.add(
                GpuSysfsState(
                  deviceName: name,
                  gpuUsagePercentage: util <= 0 ? 0 : util,
                  memUsagePercentage: memPct <= 0 ? 0 : memPct,
                ),
              );
            }
          }
        }
      } catch (_) {
        // nvidia-smi not available or failed
      }

      return gpus;
    } catch (e) {
      return gpus;
    }
  }
}
