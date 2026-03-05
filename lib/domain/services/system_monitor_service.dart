import 'dart:async';
import 'dart:isolate';

import '../models/system_state.dart';
import '../models/system_identity.dart';
import '../models/process_info.dart';
import '../../data/sources/cpu_source.dart';
import '../../data/sources/memory_source.dart';
import '../../data/sources/identity_source.dart';
import '../../data/sources/thermal_source.dart';
import '../../data/sources/process_source.dart';
import '../../data/sources/disk_source.dart';
import '../../data/sources/gpu_source.dart';
import '../../data/sources/network_source.dart';
import '../../data/sources/power_source.dart';

class SystemMonitorService {
  Isolate? _isolate;
  ReceivePort? _receivePort;
  final StreamController<SystemState> _stateController =
      StreamController<SystemState>.broadcast();

  SystemIdentity? _cachedIdentity;
  final ProcessDataSource _processSource = ProcessDataSource();

  Stream<SystemState> get systemStateStream => _stateController.stream;

  Future<void> start(Duration pollInterval) async {
    if (_isolate != null) return;

    _cachedIdentity = await SystemIdentitySource().getIdentity();
    _receivePort = ReceivePort();

    _isolate = await Isolate.spawn(
      _isolateEntryPoint,
      _IsolateConfig(
        sendPort: _receivePort!.sendPort,
        interval: pollInterval,
        identity: _cachedIdentity!,
      ),
    );

    _receivePort!.listen((message) {
      if (message is SystemState) {
        _stateController.add(message);
      }
    });
  }

  Future<ProcessInfo?> getProcessDetail(int pid) async {
    return _processSource.getProcessDetail(pid);
  }

  void stop() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _receivePort?.close();
    _receivePort = null;
  }

  static void _isolateEntryPoint(_IsolateConfig config) async {
    final cpuSource = CpuDataSource();
    final memSource = MemoryDataSource();
    final thermalSource = ThermalDataSource();
    final processSource = ProcessDataSource();
    final diskSource = DiskDataSource();
    final gpuSource = GpuSysfsSource();
    final networkSource = NetworkDataSource();
    final powerSource = PowerDataSource();

    // Initial warmup for percentage deltas
    await cpuSource.getCpuState();

    Timer.periodic(config.interval, (timer) async {
      // Fetch in parallel as they read different files
      final results = await Future.wait([
        cpuSource.getCpuState(),
        memSource.getMemoryState(),
        thermalSource.getThermalState(),
        processSource.getProcessList(),
        diskSource.getDiskState(),
        gpuSource.getGpuState(),
        networkSource.getNetworkState(),
        powerSource.getPowerState(),
      ]);

      final state = SystemState(
        identity: config.identity,
        cpu: results[0] as dynamic,
        memory: results[1] as dynamic,
        thermal: results[2] as dynamic,
        processes: results[3] as dynamic,
        disk: results[4] as dynamic,
        gpus: (results[5] as dynamic) ?? [],
        network: results[6] as dynamic,
        power: results[7] as dynamic,
      );

      config.sendPort.send(state);
    });
  }
}

class _IsolateConfig {
  final SendPort sendPort;
  final Duration interval;
  final SystemIdentity identity;

  _IsolateConfig({
    required this.sendPort,
    required this.interval,
    required this.identity,
  });
}
