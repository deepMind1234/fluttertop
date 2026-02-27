import 'network_state.dart';

class SystemIdentity {
  final String osName;
  final String kernelVersion;
  final String architecture;
  final String cpuModelName;
  final int cpuLogicalCores;
  final String cpuCacheSize;
  final List<NetworkInterfaceState> networkInterfaces;

  SystemIdentity({
    required this.osName,
    required this.kernelVersion,
    required this.architecture,
    required this.cpuModelName,
    required this.cpuLogicalCores,
    required this.cpuCacheSize,
    required this.networkInterfaces,
  });

  @override
  String toString() {
    return 'SystemIdentity(os: $osName, kernel: $kernelVersion, arch: $architecture, CPU: $cpuModelName)';
  }
}
