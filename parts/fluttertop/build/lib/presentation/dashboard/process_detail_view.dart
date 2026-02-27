import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/services/system_monitor_service.dart';
import '../../domain/models/system_state.dart';
import '../widgets/time_series_chart.dart';

class ProcessDetailView extends StatefulWidget {
  final int pid;

  const ProcessDetailView({super.key, required this.pid});

  @override
  State<ProcessDetailView> createState() => _ProcessDetailViewState();
}

class _ProcessDetailViewState extends State<ProcessDetailView> {
  final Queue<double> _cpuHistory = Queue();
  final Queue<double> _memHistory = Queue();
  final Queue<double> _coreHistory = Queue();
  final int maxHistoryLength = 60;

  @override
  Widget build(BuildContext context) {
    final service = context.read<SystemMonitorService>();

    return Scaffold(
      appBar: AppBar(title: Text('Process Details: ${widget.pid}')),
      body: StreamBuilder<SystemState>(
        stream: service.systemStateStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final state = snapshot.data!;
          final procIndex = state.processes.indexWhere(
            (p) => p.pid == widget.pid,
          );

          if (procIndex == -1) {
            return const Center(child: Text('Process ended or not found.'));
          }

          final proc = state.processes[procIndex];

          _cpuHistory.addFirst(proc.cpuUsagePercentage);
          if (_cpuHistory.length > maxHistoryLength) _cpuHistory.removeLast();

          _memHistory.addFirst(proc.memoryUsageBytes / (1024 * 1024)); // MB
          if (_memHistory.length > maxHistoryLength) _memHistory.removeLast();

          if (proc.coreId >= 0 &&
              state.cpu != null &&
              proc.coreId < state.cpu!.cores.length) {
            _coreHistory.addFirst(
              state.cpu!.cores[proc.coreId].usagePercentage,
            );
            if (_coreHistory.length > maxHistoryLength)
              _coreHistory.removeLast();
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatText('Name', proc.name),
                            _StatText('User', proc.user),
                            _StatText('State', proc.state),
                            _StatText(
                              'Core Affinity (Scheduled Core)',
                              proc.coreId == -1
                                  ? 'Unknown'
                                  : 'Core ${proc.coreId}',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Deep Profiling
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Deep Profiling',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _StatText(
                                  'Uptime',
                                  _formatDuration(proc.uptime),
                                ),
                                _StatText(
                                  'Hardware Events',
                                  '${proc.majflt} (Major Faults)',
                                ),
                                _StatText(
                                  'Software Events',
                                  '${proc.minflt} (Minor Faults)',
                                ),
                                _StatText(
                                  'Context Switches',
                                  '${proc.voluntaryCtxtSwitches} (Vol) / ${proc.nonvoluntaryCtxtSwitches} (Non-Vol)',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Memory Profiling
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Memory Profiling',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _StatText('VmPeak', '${proc.vmPeakKb} KB'),
                                _StatText('VmSize', '${proc.vmSizeKb} KB'),
                                _StatText('VmHWM', '${proc.vmHwmKb} KB'),
                                _StatText(
                                  'VmRSS',
                                  '${proc.memoryUsageBytes ~/ 1024} KB',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // I/O & Threads
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'I/O & Threads',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _StatText('Threads', '${proc.threadsCount}'),
                                _StatText(
                                  'Read Bytes',
                                  _formatBytes(proc.readBytes),
                                ),
                                _StatText(
                                  'Write Bytes',
                                  _formatBytes(proc.writeBytes),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 250,
                        child: Row(
                          children: [
                            Expanded(
                              child: TimeSeriesChart(
                                title: 'Process CPU History',
                                dataPoints: _cpuHistory.toList(),
                                color: Colors.orangeAccent,
                                maxY: (state.cpu?.cores.length ?? 1) * 100.0,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TimeSeriesChart(
                                title: 'Process Memory History',
                                dataPoints: _memHistory.toList(),
                                color: Colors.greenAccent,
                                unit: 'MB',
                                maxY:
                                    (_memHistory.isEmpty
                                        ? 100
                                        : _memHistory.reduce(
                                            (value, element) => value > element
                                                ? value
                                                : element,
                                          )) *
                                    1.5,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TimeSeriesChart(
                                title: 'Core ${proc.coreId} Total Burden',
                                dataPoints: _coreHistory.toList(),
                                color: Colors.redAccent,
                                maxY: 100.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Actions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Implement Kill Signal
                          },
                          icon: const Icon(Icons.stop),
                          label: const Text('Kill Process (SIGTERM)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.2),
                            foregroundColor: Colors.red,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatText extends StatelessWidget {
  final String label;
  final String value;
  const _StatText(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }
}

String _formatDuration(Duration d) {
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
  return "${d.inHours}:$twoDigitMinutes:$twoDigitSeconds";
}

String _formatBytes(int bytes) {
  if (bytes == 0) return '0 B';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024)
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}
