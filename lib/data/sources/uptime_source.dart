import 'dart:io';
import '../../core/constants/system_paths.dart';

class SystemUptimeSource {
  Future<double> getUptimeSeconds() async {
    try {
      final file = File('${SystemPaths.procDir}/uptime');
      if (!await file.exists()) return 0.0;

      final content = await file.readAsString();
      final parts = content.split(' ');
      if (parts.isNotEmpty) {
        return double.tryParse(parts[0]) ?? 0.0;
      }
    } catch (_) {}
    return 0.0;
  }
}
