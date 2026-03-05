import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/services/system_monitor_service.dart';
import '../../domain/models/system_state.dart';
import '../../domain/models/process_info.dart';
import '../widgets/time_series_chart.dart';

class ProcessDetailView extends StatefulWidget {
  final int pid;
  final String initialName;

  const ProcessDetailView({
    super.key,
    required this.pid,
    required this.initialName,
  });

  @override
  State<ProcessDetailView> createState() => _ProcessDetailViewState();
}

class _ProcessDetailViewState extends State<ProcessDetailView> {
  final Queue<double> _cpuHistory = Queue();
  final Queue<double> _memHistory = Queue();
  final Queue<double> _ioHistory = Queue();
  final int maxHistoryLength = 60;

  ProcessInfo? _latestDetail;
  int _lastReadBytes = -1;
  int _lastWriteBytes = -1;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    final service = context.read<SystemMonitorService>();
    // Initial fetch
    service.getProcessDetail(widget.pid).then((detail) {
      if (mounted) setState(() => _latestDetail = detail);
    });

    // Periodic fetch
    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final detail = await service.getProcessDetail(widget.pid);
      if (mounted) {
        setState(() {
          _latestDetail = detail;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SystemMonitorService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Process Details: ${_latestDetail?.name ?? widget.initialName} (${widget.pid})',
        ),
      ),
      body: SingleChildScrollView(
        child: StreamBuilder<SystemState>(
          stream: service.systemStateStream,
          builder: (context, snapshot) {
            final state = snapshot.data;
            final proc = _latestDetail;

            if (proc == null) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final matchingProcess = state?.processes.firstWhere(
              (p) => p.pid == proc.pid,
              orElse: () => proc,
            );
            final double actualCpuUsage =
                matchingProcess?.cpuUsagePercentage ?? proc.cpuUsagePercentage;

            // Update histories
            _cpuHistory.addFirst(actualCpuUsage);
            if (_cpuHistory.length > maxHistoryLength) _cpuHistory.removeLast();

            _memHistory.addFirst(proc.memoryUsageBytes / (1024 * 1024)); // MB
            if (_memHistory.length > maxHistoryLength) _memHistory.removeLast();

            double ioRateMb = 0.0;
            if (_lastReadBytes != -1 && _lastWriteBytes != -1) {
              int deltaRead = proc.readBytes - _lastReadBytes;
              int deltaWrite = proc.writeBytes - _lastWriteBytes;
              if (deltaRead < 0) deltaRead = 0;
              if (deltaWrite < 0) deltaWrite = 0;
              ioRateMb = (deltaRead + deltaWrite) / (1024 * 1024.0); // MB/s
            }
            _lastReadBytes = proc.readBytes;
            _lastWriteBytes = proc.writeBytes;

            _ioHistory.addFirst(ioRateMb);
            if (_ioHistory.length > maxHistoryLength) _ioHistory.removeLast();

            // Total system memory for standardized Y-axis comparison
            final double totalSystemMemMb =
                (state?.memory?.totalMemBytes ?? (16 * 1024 * 1024 * 1024)) /
                (1024 * 1024);

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
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Wrap(
                            spacing: 48,
                            runSpacing: 16,
                            children: [
                              _StatText('Name', proc.name),
                              _StatText('User', proc.user),
                              _StatText('State', proc.state),
                              _StatText(
                                'Core Affinity',
                                proc.coreId == -1
                                    ? 'Unknown'
                                    : 'Core ${proc.coreId}',
                              ),
                            ],
                          ),
                        ),
                        if (proc.commandLine.isNotEmpty ||
                            proc.executablePath.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (proc.executablePath.isNotEmpty) ...[
                                    _StatText(
                                      'Executable Path',
                                      proc.executablePath,
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  if (proc.commandLine.isNotEmpty)
                                    _StatText('Command Line', proc.commandLine),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        // Performance Stats
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Execution Statistics',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                alignment: WrapAlignment.spaceBetween,
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
                        // Memory
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Memory Details',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 48,
                                runSpacing: 16,
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
                        // IO
                        Container(
                          width: double.infinity,
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
                              Wrap(
                                spacing: 48,
                                runSpacing: 16,
                                children: [
                                  _StatText('Threads', '${proc.threadsCount}'),
                                  _StatText(
                                    'Read Total',
                                    _formatBytes(proc.readBytes),
                                  ),
                                  _StatText(
                                    'Write Total',
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
                                  maxY: (state?.cpu?.cores.length ?? 1) * 100.0,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TimeSeriesChart(
                                  title: 'Process Memory (vs Total)',
                                  dataPoints: _memHistory.toList(),
                                  color: Colors.greenAccent,
                                  unit: 'MB',
                                  maxY: totalSystemMemMb,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TimeSeriesChart(
                                  title: 'Process Disk I/O',
                                  dataPoints: _ioHistory.toList(),
                                  color: Colors.blueAccent,
                                  unit: 'MB/s',
                                  maxY: 50.0, // Standardize to 50 MB/s scale
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
                          _ActionButton(
                            icon: Icons.stop,
                            label: 'Kill (SIGTERM)',
                            color: Colors.orange,
                            onPressed: () =>
                                _sendSignal(widget.pid, ProcessSignal.sigterm),
                          ),
                          const SizedBox(height: 8),
                          _ActionButton(
                            icon: Icons.dangerous,
                            label: 'Force Kill (SIGKILL)',
                            color: Colors.red,
                            onPressed: () =>
                                _sendSignal(widget.pid, ProcessSignal.sigkill),
                          ),
                          const SizedBox(height: 8),
                          _ActionButton(
                            icon: Icons.pause,
                            label: 'Pause (SIGSTOP)',
                            color: Colors.blue,
                            onPressed: () =>
                                _sendSignal(widget.pid, ProcessSignal.sigstop),
                          ),
                          const SizedBox(height: 8),
                          _ActionButton(
                            icon: Icons.play_arrow,
                            label: 'Resume (SIGCONT)',
                            color: Colors.green,
                            onPressed: () =>
                                _sendSignal(widget.pid, ProcessSignal.sigcont),
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
      ),
    );
  }

  void _sendSignal(int pid, ProcessSignal signal) {
    try {
      Process.killPid(pid, signal);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sent ${signal.name} to PID $pid')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send signal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final MaterialColor color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        foregroundColor: color,
        minimumSize: const Size(double.infinity, 44),
        alignment: Alignment.centerLeft,
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
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}
