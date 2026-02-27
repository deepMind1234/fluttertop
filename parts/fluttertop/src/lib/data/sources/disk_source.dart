import 'dart:io';

import '../../domain/models/disk_state.dart';
import '../../core/constants/system_paths.dart';

class DiskDataSource {
  static final _whitespaceRegex = RegExp(r'\s+');
  static final _mainDiskRegex = RegExp(r'^(sd[a-z]|vd[a-z]|nvme\d+n\d+)$');

  final Map<String, DiskIoStat> _prevStats = {};
  int _prevTimestamp = 0;

  Future<SystemDiskState?> getDiskState() async {
    try {
      final file = File(SystemPaths.procDiskStats);
      if (!await file.exists()) return null;

      final content = await file.readAsString();
      final lines = content.split('\n');

      final int now = DateTime.now().millisecondsSinceEpoch;
      int deltaMs = 0;
      if (_prevTimestamp > 0) {
        deltaMs = now - _prevTimestamp;
      }

      List<DiskIoStat> disks = [];

      for (var line in lines) {
        if (line.trim().isEmpty) continue;

        final parts = line.trim().split(_whitespaceRegex);
        // format: major minor name r_io r_merges r_sectors r_ticks w_io w_merges w_sectors w_ticks ...
        if (parts.length >= 14) {
          final deviceName = parts[2];

          // Filter out loop devices, ram disks, and partitions if desired.
          // For simplicity, let's keep physical drives like sdX, nvmeXn1.
          if (deviceName.startsWith('loop') || deviceName.startsWith('ram')) {
            continue;
          }
          // Basic heuristic: check if it ends with a number (partition) vs a letter/id (disk).
          // To be safe, we capture sd[a-z], nvme[0-9]n[0-9], vd[a-z], mmcblk[0-9]
          bool isMainDisk = _mainDiskRegex.hasMatch(deviceName);
          if (!isMainDisk) continue;

          // Check if it's removable (external USB, SD card)
          bool isExternal = false;
          try {
            final removableFile = File(
              '${SystemPaths.sysBlock}/$deviceName/removable',
            );
            if (await removableFile.exists()) {
              final val = await removableFile.readAsString();
              if (val.trim() == '1') {
                isExternal = true;
              }
            }
          } catch (_) {}

          final sectorsRead = int.tryParse(parts[5]) ?? 0;
          final sectorsWritten = int.tryParse(parts[9]) ?? 0;

          int bytesReadPerSec = 0;
          int bytesWrittenPerSec = 0;

          if (deltaMs > 0 && _prevStats.containsKey(deviceName)) {
            final prev = _prevStats[deviceName]!;
            final deltaReads = sectorsRead - prev.sectorsRead;
            final deltaWrites = sectorsWritten - prev.sectorsWritten;

            // 1 sector is usually 512 bytes
            final bytesRead = deltaReads * 512;
            final bytesWritten = deltaWrites * 512;

            bytesReadPerSec = ((bytesRead / deltaMs) * 1000).round();
            bytesWrittenPerSec = ((bytesWritten / deltaMs) * 1000).round();
          }

          final stat = DiskIoStat(
            deviceName: deviceName,
            sectorsRead: sectorsRead,
            sectorsWritten: sectorsWritten,
            bytesReadPerSec: bytesReadPerSec < 0 ? 0 : bytesReadPerSec,
            bytesWrittenPerSec: bytesWrittenPerSec < 0 ? 0 : bytesWrittenPerSec,
            isExternal: isExternal,
          );

          disks.add(stat);
          _prevStats[deviceName] = stat;
        }
      }

      List<LogicalDriveCapacity> logicalDrives = [];

      try {
        final dfResult = await Process.run('df', ['-mT']);
        if (dfResult.exitCode == 0) {
          final dfLines = (dfResult.stdout as String).split('\n');
          // skip header
          for (int i = 1; i < dfLines.length; i++) {
            final line = dfLines[i].trim();
            if (line.isEmpty) continue;

            final parts = line.split(RegExp(r'\s+'));
            if (parts.length >= 7) {
              final fs = parts[0];
              if (fs.startsWith('/dev/')) {
                final type = parts[1];
                final total = int.tryParse(parts[2]) ?? 0;
                final used = int.tryParse(parts[3]) ?? 0;
                final free = int.tryParse(parts[4]) ?? 0;
                // handle mounts with spaces (though rare for basic Linux)
                final mount = parts.sublist(6).join(' ');

                logicalDrives.add(
                  LogicalDriveCapacity(
                    mountPoint: mount,
                    fileSystem: type,
                    totalMb: total,
                    usedMb: used,
                    freeMb: free,
                  ),
                );
              }
            }
          }
        }
      } catch (_) {}

      _prevTimestamp = now;
      return SystemDiskState(disks: disks, logicalDrives: logicalDrives);
    } catch (e) {
      return null;
    }
  }
}
