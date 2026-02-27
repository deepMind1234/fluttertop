import 'dart:io';

import '../../domain/models/cpu_state.dart';
import '../../core/constants/system_paths.dart';

class ProcStatParser {
  static final _whitespaceRegex = RegExp(r'\s+');

  /// Parses the /proc/stat file into a CpuCoreStat.
  /// Needs two readings to calculate the percentage since it's cumulative time.
  static List<List<int>> parseRawTickData(String procStatContent) {
    final lines = procStatContent.split('\n');

    final result = <List<int>>[];

    for (var line in lines) {
      if (line.startsWith('cpu')) {
        final parts = line.split(_whitespaceRegex);
        if (parts.length > 4) {
          final isTotal = parts[0] == 'cpu';
          final name = parts[0];

          final user = int.tryParse(parts[1]) ?? 0;
          final nice = int.tryParse(parts[2]) ?? 0;
          final system = int.tryParse(parts[3]) ?? 0;
          final idle = int.tryParse(parts[4]) ?? 0;
          final iowait = parts.length > 5 ? (int.tryParse(parts[5]) ?? 0) : 0;
          final irq = parts.length > 6 ? (int.tryParse(parts[6]) ?? 0) : 0;
          final softirq = parts.length > 7 ? (int.tryParse(parts[7]) ?? 0) : 0;
          final steal = parts.length > 8 ? (int.tryParse(parts[8]) ?? 0) : 0;

          final idleAll = idle + iowait;
          final systemAll = system + irq + softirq;
          final virtAll = steal;
          final total = user + nice + systemAll + idleAll + virtAll;

          result.add([
            isTotal
                ? -1
                : int.parse(
                    name.substring(3),
                  ), // identifier (-1 for total, 0, 1, etc for cores)
            user + nice, // total user time
            systemAll, // total system time
            idleAll, // total idle time
            total, // absolute total time
          ]);
        }
      }
    }
    return result;
  }
}

class CpuDataSource {
  List<List<int>>? _previousData;

  Future<SystemCpuState?> getCpuState() async {
    try {
      final file = File(SystemPaths.procStat);
      if (!await file.exists()) return null;

      final content = await file.readAsString();
      final currentData = ProcStatParser.parseRawTickData(content);

      if (_previousData == null) {
        _previousData = currentData;
        return null; // Need delta for percentage calculation
      }

      CpuCoreStat? totalStat;
      final List<CpuCoreStat> cores = [];

      for (int i = 0; i < currentData.length; i++) {
        final current = currentData[i];

        // Find matching prev core
        final prevIndex = _previousData!.indexWhere((p) => p[0] == current[0]);
        if (prevIndex == -1) continue;

        final prev = _previousData![prevIndex];

        final double deltaTotal = (current[4] - prev[4]).toDouble();
        if (deltaTotal == 0) continue; // Avoid division by zero

        final double deltaUser = (current[1] - prev[1]).toDouble();
        final double deltaSystem = (current[2] - prev[2]).toDouble();
        final double deltaIdle = (current[3] - prev[3]).toDouble();

        final double userPerc = (deltaUser / deltaTotal) * 100.0;
        final double sysPerc = (deltaSystem / deltaTotal) * 100.0;
        final double idlePerc = (deltaIdle / deltaTotal) * 100.0;
        final double usagePerc =
            ((deltaTotal - deltaIdle) / deltaTotal) * 100.0;

        final stat = CpuCoreStat(
          name: current[0] == -1 ? 'Total' : 'Core ${current[0]}',
          user: userPerc,
          system: sysPerc,
          idle: idlePerc,
          usagePercentage: usagePerc,
        );

        if (current[0] == -1) {
          totalStat = stat;
        } else {
          cores.add(stat);
        }
      }

      _previousData = currentData;

      int contextSwitches = 0;
      for (var line in content.split('\n')) {
        if (line.startsWith('ctxt ')) {
          final parts = line.split(ProcStatParser._whitespaceRegex);
          if (parts.length >= 2) {
            contextSwitches = int.tryParse(parts[1]) ?? 0;
            break;
          }
        }
      }

      double globalClockMhz = 0.0;
      try {
        final cpuInfoFile = File(SystemPaths.procCpuInfo);
        if (await cpuInfoFile.exists()) {
          final infoLines = await cpuInfoFile.readAsLines();
          for (var line in infoLines) {
            if (line.startsWith('cpu MHz')) {
              final parts = line.split(':');
              if (parts.length >= 2) {
                globalClockMhz = double.tryParse(parts[1].trim()) ?? 0.0;
                break; // Just take the first reported core's speed as a global proxy
              }
            }
          }
        }
      } catch (_) {}

      if (totalStat != null) {
        return SystemCpuState(
          total: totalStat,
          cores: cores,
          globalClockSpeedMhz: globalClockMhz,
          contextSwitches: contextSwitches,
        );
      }
      return null;
    } catch (e) {
      print('Error parsing ${SystemPaths.procStat}: $e');
      return null;
    }
  }
}
