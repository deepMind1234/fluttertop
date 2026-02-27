import 'dart:io';

import '../../domain/models/memory_state.dart';
import '../../core/constants/system_paths.dart';

class MemoryDataSource {
  static final _colonWhitespaceRegex = RegExp(r':\s+');

  Future<SystemMemoryState?> getMemoryState() async {
    try {
      final file = File(SystemPaths.procMemInfo);
      if (!await file.exists()) return null;

      final content = await file.readAsString();
      final lines = content.split('\n');

      int memTotal = 0;
      int memFree = 0;
      int memAvailable = 0;
      int buffers = 0;
      int cached = 0;
      int active = 0;
      int inactive = 0;
      int swapTotal = 0;
      int swapFree = 0;

      for (var line in lines) {
        if (line.isEmpty) continue;
        final parts = line.split(_colonWhitespaceRegex);
        if (parts.length < 2) continue;

        final key = parts[0].trim();
        final valueStr = parts[1].trim().split(
          ' ',
        )[0]; // Extract number before 'kB'
        final valueKb = int.tryParse(valueStr) ?? 0;
        final valueBytes = valueKb * 1024;

        switch (key) {
          case 'MemTotal':
            memTotal = valueBytes;
            break;
          case 'MemFree':
            memFree = valueBytes;
            break;
          case 'MemAvailable':
            memAvailable = valueBytes;
            break;
          case 'Buffers':
            buffers = valueBytes;
            break;
          case 'Cached':
            cached = valueBytes;
            break;
          case 'Active':
            active = valueBytes;
            break;
          case 'Inactive':
            inactive = valueBytes;
            break;
          case 'SwapTotal':
            swapTotal = valueBytes;
            break;
          case 'SwapFree':
            swapFree = valueBytes;
            break;
        }
      }

      // Calculate used memory similar to how 'htop' does it
      // MemUsed = MemTotal - MemFree - Buffers - Cached
      // Note: MemAvailable is a better indicator of usable memory in modern kernels,
      // but 'used' is typically represented for visual charts as Total - Available.
      int memUsed = memTotal - memAvailable;
      if (memAvailable == 0) {
        memUsed = memTotal - memFree - buffers - cached;
      }

      int swapUsed = swapTotal - swapFree;

      return SystemMemoryState(
        totalMemBytes: memTotal,
        usedMemBytes: memUsed,
        freeMemBytes: memAvailable > 0 ? memAvailable : memFree,
        buffersBytes: buffers,
        cachedBytes: cached,
        activeMemBytes: active,
        inactiveMemBytes: inactive,
        totalSwapBytes: swapTotal,
        usedSwapBytes: swapUsed,
        freeSwapBytes: swapFree,
      );
    } catch (e) {
      return null;
    }
  }
}
