import 'dart:io';

import '../../domain/models/network_state.dart';
import '../../core/constants/system_paths.dart';

class NetworkDataSource {
  static final _whitespaceRegex = RegExp(r'\s+');

  final Map<String, _NetworkStats> _prevStats = {};
  int _prevTimestamp = 0;

  Future<SystemNetworkState?> getNetworkState() async {
    try {
      final file = File(SystemPaths.procNetDev);
      if (!await file.exists()) return null;

      final content = await file.readAsString();
      final lines = content.split('\n');

      final int now = DateTime.now().millisecondsSinceEpoch;
      int deltaMs = 0;
      if (_prevTimestamp > 0) {
        deltaMs = now - _prevTimestamp;
      }

      List<NetworkInterfaceState> interfaces = [];

      // Skip the first two headers
      for (int i = 2; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final parts = line.split(':');
        if (parts.length != 2) continue;

        final interfaceName = parts[0].trim();
        final statParts = parts[1].trim().split(_whitespaceRegex);

        // Typical /proc/net/dev has: Face | bytes packets errs drop fifo frame compressed multicast | bytes packets errs drop fifo colls carrier compressed
        if (statParts.length >= 16) {
          final bytesReceived = int.tryParse(statParts[0]) ?? 0;
          final bytesSent = int.tryParse(statParts[8]) ?? 0;

          int bytesReceivedPerSec = 0;
          int bytesSentPerSec = 0;

          if (deltaMs > 0 && _prevStats.containsKey(interfaceName)) {
            final prev = _prevStats[interfaceName]!;
            final deltaRx = bytesReceived - prev.bytesReceived;
            final deltaTx = bytesSent - prev.bytesSent;

            bytesReceivedPerSec = ((deltaRx / deltaMs) * 1000).round();
            bytesSentPerSec = ((deltaTx / deltaMs) * 1000).round();
          }

          final interfaceState = NetworkInterfaceState(
            name: interfaceName,
            macAddress:
                'Unknown', // Getting real MAC from Dart without ffi is hard, skip for now.
            isUp:
                bytesReceived > 0 ||
                bytesSent > 0, // Heuristic if not reading sysfs strictly
            bytesReceivedPerSec: bytesReceivedPerSec < 0
                ? 0
                : bytesReceivedPerSec,
            bytesSentPerSec: bytesSentPerSec < 0 ? 0 : bytesSentPerSec,
          );

          interfaces.add(interfaceState);
          _prevStats[interfaceName] = _NetworkStats(
            bytesReceived: bytesReceived,
            bytesSent: bytesSent,
          );
        }
      }

      _prevTimestamp = now;
      return SystemNetworkState(interfaces: interfaces);
    } catch (e) {
      // Ignore parsing errors for unavailable files
      return null;
    }
  }
}

class _NetworkStats {
  final int bytesReceived;
  final int bytesSent;

  _NetworkStats({required this.bytesReceived, required this.bytesSent});
}
