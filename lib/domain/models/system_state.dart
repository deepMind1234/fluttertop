import 'cpu_state.dart';
import 'memory_state.dart';
import 'process_info.dart';
import 'system_identity.dart';
import 'thermal_state.dart';
import 'disk_state.dart';
import 'gpu_state.dart';

import 'network_state.dart';
import 'power_state.dart';

class SystemState {
  final SystemIdentity identity;
  final SystemCpuState? cpu;
  final SystemMemoryState? memory;
  final SystemThermalState? thermal;
  final List<ProcessInfo> processes;
  final SystemDiskState? disk;
  final List<GpuSysfsState> gpus;
  final SystemNetworkState? network;
  final PowerState? power;

  SystemState({
    required this.identity,
    this.cpu,
    this.memory,
    this.thermal,
    required this.processes,
    this.disk,
    this.gpus = const [],
    this.network,
    this.power,
  });
}
