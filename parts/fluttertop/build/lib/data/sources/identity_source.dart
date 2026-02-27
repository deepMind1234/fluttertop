import 'dart:io';

import '../../domain/models/system_identity.dart';
import '../../domain/models/network_state.dart';
import '../../core/constants/system_paths.dart';

class SystemIdentitySource {
  Future<SystemIdentity> getIdentity() async {
    String osName = 'Unknown Linux';
    String kernelVersion = 'Unknown Kernel';
    String architecture = 'Unknown Arch';

    // CPU fingerprint
    String cpuModelName = 'Unknown CPU';
    int cpuLogicalCores = 0;
    String cpuCacheSize = 'Unknown';

    // NIC fingerprint
    List<NetworkInterfaceState> networkInterfaces = [];

    try {
      // 1. OS Release
      final osReleaseFile = File('/etc/os-release');
      if (await osReleaseFile.exists()) {
        final content = await osReleaseFile.readAsString();
        final lines = content.split('\n');
        for (var line in lines) {
          if (line.startsWith('PRETTY_NAME=')) {
            osName = line.substring(12).replaceAll('"', '');
            break;
          }
        }
      }

      // 2. Kernel Version
      final procVersionFile = File('${SystemPaths.procDir}/version');
      if (await procVersionFile.exists()) {
        final content = await procVersionFile.readAsString();
        final parts = content.split(' ');
        if (parts.length > 2) {
          kernelVersion = parts[2];
        }
      }

      // 3. Architecture
      final result = await Process.run('uname', ['-m']);
      if (result.exitCode == 0) {
        architecture = result.stdout.toString().trim();
      }

      // 4. CPU Info (/proc/cpuinfo)
      final cpuInfoFile = File(SystemPaths.procCpuInfo);
      if (await cpuInfoFile.exists()) {
        final content = await cpuInfoFile.readAsString();
        final lines = content.split('\n');

        for (var line in lines) {
          if (line.isEmpty) continue;
          final parts = line.split(RegExp(r':\s*'));
          if (parts.length < 2) continue;
          final key = parts[0].trim();
          final value = parts[1].trim();

          if (key == 'model name' || key == 'Hardware') {
            // Hardware is often used on ARM
            cpuModelName = value;
          } else if (key == 'processor') {
            cpuLogicalCores++;
          } else if (key == 'cache size') {
            cpuCacheSize = value;
          }
        }
      }

      // 5. Network Interfaces (/sys/class/net/)
      final netDir = Directory(SystemPaths.sysClassNet);
      if (await netDir.exists()) {
        final entities = await netDir.list().toList();
        for (var entity in entities) {
          if (entity is Directory) {
            final name =
                entity.uri.pathSegments[entity.uri.pathSegments.length - 2];

            // Skip loopback usually, or keep it depending on preference. Let's skip lo.
            if (name == 'lo') continue;

            bool isUp = false;
            String mac = '';

            try {
              final operstateFile = File('${entity.path}/operstate');
              if (await operstateFile.exists()) {
                final state = (await operstateFile.readAsString()).trim();
                isUp = state == 'up';
              }

              final addressFile = File('${entity.path}/address');
              if (await addressFile.exists()) {
                mac = (await addressFile.readAsString()).trim();
              }
            } catch (_) {}

            networkInterfaces.add(
              NetworkInterfaceState(name: name, macAddress: mac, isUp: isUp),
            );
          }
        }
      }
    } catch (e) {
      print('Error fetching system identity: $e');
    }

    return SystemIdentity(
      osName: osName,
      kernelVersion: kernelVersion,
      architecture: architecture,
      cpuModelName: cpuModelName,
      cpuLogicalCores: cpuLogicalCores == 0 ? 1 : cpuLogicalCores,
      cpuCacheSize: cpuCacheSize,
      networkInterfaces: networkInterfaces,
    );
  }
}
