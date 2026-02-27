import 'dart:io';
import 'package:flutter/foundation.dart'; // For compute

import '../../domain/models/process_info.dart';
import '../../core/constants/system_paths.dart';
import 'uptime_source.dart';

class _ProcessComputeArgs {
  final Map<int, String> uidToUserCache;
  final int prevTotalCpuTime;
  final int currentTotalCpuTime;
  final Map<int, int> prevProcessStats;
  final double sysUptime;
  final int cpuCoresCount;
  final String procDir;

  _ProcessComputeArgs({
    required this.uidToUserCache,
    required this.prevTotalCpuTime,
    required this.currentTotalCpuTime,
    required this.prevProcessStats,
    required this.sysUptime,
    required this.cpuCoresCount,
    required this.procDir,
  });
}

class _ProcessComputeResult {
  final List<ProcessInfo> processes;
  final Map<int, String> updatedUidCache;
  final Map<int, int> updatedProcessStats;
  final int newTotalCpuTime;

  _ProcessComputeResult({
    required this.processes,
    required this.updatedUidCache,
    required this.updatedProcessStats,
    required this.newTotalCpuTime,
  });
}

Future<_ProcessComputeResult> _parseProcessesInIsolate(
  _ProcessComputeArgs args,
) async {
  final whitespaceRegex = RegExp(r'\s+');
  final deltaTotal = args.currentTotalCpuTime - args.prevTotalCpuTime;

  final List<ProcessInfo> list = [];
  final Map<int, String> localUidCache = Map.of(args.uidToUserCache);
  final Map<int, int> newProcessStats = {};

  final dir = Directory(args.procDir);
  if (!dir.existsSync()) {
    return _ProcessComputeResult(
      processes: [],
      updatedUidCache: localUidCache,
      updatedProcessStats: newProcessStats,
      newTotalCpuTime: args.currentTotalCpuTime,
    );
  }

  // Pre-load /etc/passwd if cache is empty to avoid reading it for every process
  if (localUidCache.isEmpty) {
    try {
      final passwdFile = File('/etc/passwd');
      if (passwdFile.existsSync()) {
        final lines = passwdFile.readAsLinesSync();
        for (var line in lines) {
          final parts = line.split(':');
          if (parts.length >= 3) {
            final uname = parts[0];
            final uid = int.tryParse(parts[2]);
            if (uid != null) {
              localUidCache[uid] = uname;
            }
          }
        }
      }
    } catch (_) {}
  }

  final entities = dir.listSync();
  for (var entity in entities) {
    if (entity is Directory) {
      final folderName =
          entity.uri.pathSegments[entity.uri.pathSegments.length - 2];
      final pid = int.tryParse(folderName);
      if (pid != null) {
        try {
          final statFile = File('${args.procDir}/$pid/stat');
          final statusFile = File('${args.procDir}/$pid/status');

          if (statFile.existsSync() && statusFile.existsSync()) {
            final statContent = statFile.readAsStringSync();
            final nameStart = statContent.indexOf('(');
            final nameEnd = statContent.lastIndexOf(')');

            if (nameStart != -1 && nameEnd != -1) {
              final name = statContent.substring(nameStart + 1, nameEnd);
              final statParts = statContent.substring(nameEnd + 2).split(' ');
              final state = statParts[0];

              final utime = int.tryParse(statParts[11]) ?? 0;
              final stime = int.tryParse(statParts[12]) ?? 0;

              final minflt = statParts.length > 7
                  ? (int.tryParse(statParts[7]) ?? 0)
                  : 0;
              final majflt = statParts.length > 9
                  ? (int.tryParse(statParts[9]) ?? 0)
                  : 0;
              final starttime = statParts.length > 19
                  ? (int.tryParse(statParts[19]) ?? 0)
                  : 0;
              final coreId = statParts.length > 36
                  ? (int.tryParse(statParts[36]) ?? -1)
                  : -1;

              final totalTime = utime + stime;
              final double processUptimeSec =
                  args.sysUptime - (starttime / 100.0);
              final procUptime = Duration(
                milliseconds: (processUptimeSec * 1000).toInt(),
              );

              final statusLines = statusFile.readAsLinesSync();
              int vmRssKb = 0;
              String user = 'unknown';
              int volCtxtInfo = 0;
              int nonVolCtxtInfo = 0;
              int threadsCount = 0;
              int vmPeakKb = 0;
              int vmSizeKb = 0;
              int vmHwmKb = 0;
              int readBytes = 0;
              int writeBytes = 0;

              for (var line in statusLines) {
                if (line.startsWith('VmRSS:')) {
                  final parts = line.split(whitespaceRegex);
                  if (parts.length >= 2) vmRssKb = int.tryParse(parts[1]) ?? 0;
                } else if (line.startsWith('Uid:')) {
                  final parts = line.split(whitespaceRegex);
                  if (parts.length >= 2) {
                    final uid = int.tryParse(parts[1]);
                    if (uid != null) {
                      user = localUidCache[uid] ?? uid.toString();
                    }
                  }
                } else if (line.startsWith('voluntary_ctxt_switches:')) {
                  final parts = line.split(whitespaceRegex);
                  if (parts.length >= 2) {
                    volCtxtInfo = int.tryParse(parts[1]) ?? 0;
                  }
                } else if (line.startsWith('nonvoluntary_ctxt_switches:')) {
                  final parts = line.split(whitespaceRegex);
                  if (parts.length >= 2) {
                    nonVolCtxtInfo = int.tryParse(parts[1]) ?? 0;
                  }
                } else if (line.startsWith('Threads:')) {
                  final parts = line.split(whitespaceRegex);
                  if (parts.length >= 2) {
                    threadsCount = int.tryParse(parts[1]) ?? 0;
                  }
                } else if (line.startsWith('VmPeak:')) {
                  final parts = line.split(whitespaceRegex);
                  if (parts.length >= 2) vmPeakKb = int.tryParse(parts[1]) ?? 0;
                } else if (line.startsWith('VmSize:')) {
                  final parts = line.split(whitespaceRegex);
                  if (parts.length >= 2) vmSizeKb = int.tryParse(parts[1]) ?? 0;
                } else if (line.startsWith('VmHWM:')) {
                  final parts = line.split(whitespaceRegex);
                  if (parts.length >= 2) vmHwmKb = int.tryParse(parts[1]) ?? 0;
                }
              }

              try {
                final ioFile = File('${args.procDir}/$pid/io');
                if (ioFile.existsSync()) {
                  final ioLines = ioFile.readAsLinesSync();
                  for (var line in ioLines) {
                    if (line.startsWith('read_bytes:')) {
                      final parts = line.split(whitespaceRegex);
                      if (parts.length >= 2) {
                        readBytes = int.tryParse(parts[1]) ?? 0;
                      }
                    } else if (line.startsWith('write_bytes:')) {
                      final parts = line.split(whitespaceRegex);
                      if (parts.length >= 2) {
                        writeBytes = int.tryParse(parts[1]) ?? 0;
                      }
                    }
                  }
                }
              } catch (_) {}

              double cpuUsage = 0.0;
              if (args.prevProcessStats.containsKey(pid) && deltaTotal > 0) {
                final prevTime = args.prevProcessStats[pid]!;
                final deltaProc = totalTime - prevTime;
                cpuUsage =
                    100.0 * (deltaProc / deltaTotal) * args.cpuCoresCount;
              }

              newProcessStats[pid] = totalTime;

              list.add(
                ProcessInfo(
                  pid: pid,
                  user: user,
                  name: name,
                  cpuUsagePercentage: cpuUsage,
                  memoryUsageBytes: vmRssKb * 1024,
                  state: state,
                  coreId: coreId,
                  uptime: procUptime,
                  minflt: minflt,
                  majflt: majflt,
                  voluntaryCtxtSwitches: volCtxtInfo,
                  nonvoluntaryCtxtSwitches: nonVolCtxtInfo,
                  threadsCount: threadsCount,
                  vmPeakKb: vmPeakKb,
                  vmSizeKb: vmSizeKb,
                  vmHwmKb: vmHwmKb,
                  readBytes: readBytes,
                  writeBytes: writeBytes,
                ),
              );
            }
          }
        } catch (_) {}
      }
    }
  }

  return _ProcessComputeResult(
    processes: list,
    updatedUidCache: localUidCache,
    updatedProcessStats: newProcessStats,
    newTotalCpuTime: args.currentTotalCpuTime,
  );
}

class ProcessDataSource {
  static final whitespaceRegex = RegExp(r'\s+');

  int _prevTotalCpuTime = 0;
  Map<int, int> _prevProcessStats = {};
  Map<int, String> _uidToUserCache = {};

  Future<int> _getTotalCpuTime() async {
    try {
      final file = File(SystemPaths.procStat);
      if (!await file.exists()) return 0;
      final content = await file.readAsString();
      final lines = content.split('\n');
      for (var line in lines) {
        if (line.startsWith('cpu ')) {
          final parts = line
              .split(whitespaceRegex)
              .skip(1)
              .take(8)
              .map((e) => int.tryParse(e) ?? 0);
          int total = 0;
          for (var val in parts) {
            total += val;
          }
          return total;
        }
      }
    } catch (_) {}
    return 0;
  }

  Future<List<ProcessInfo>> getProcessList() async {
    final int currentTotalCpuTime = await _getTotalCpuTime();
    final double sysUptime = await SystemUptimeSource().getUptimeSeconds();
    final cpuCoresCount = Platform.numberOfProcessors;

    final args = _ProcessComputeArgs(
      uidToUserCache: _uidToUserCache,
      prevTotalCpuTime: _prevTotalCpuTime,
      currentTotalCpuTime: currentTotalCpuTime,
      prevProcessStats: _prevProcessStats,
      sysUptime: sysUptime,
      cpuCoresCount: cpuCoresCount,
      procDir: SystemPaths.procDir,
    );

    // Offload the heavy synchronous parsing loops to a background isolate
    final result = await compute(_parseProcessesInIsolate, args);

    _uidToUserCache = result.updatedUidCache;
    _prevProcessStats = result.updatedProcessStats;
    _prevTotalCpuTime = result.newTotalCpuTime;

    return result.processes;
  }
}
