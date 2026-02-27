import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/services/system_monitor_service.dart';
import '../../domain/models/system_state.dart';
import '../theme/theme_manager.dart';
import '../widgets/time_series_chart.dart';
import '../widgets/process_list_widget.dart';
import '../widgets/cpu_core_heatmap.dart';
import '../widgets/metric_cards/base_metric_card.dart';
import '../widgets/metric_cards/gpu_metric_card.dart';
import '../widgets/metric_cards/network_metric_card.dart';
import '../widgets/metric_cards/external_drive_metric_card.dart';
import '../widgets/metric_cards/storage_pie_chart.dart';
import '../settings/settings_view.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final Queue<double> _cpuHistory = Queue();
  final Queue<double> _memHistory = Queue();
  final int maxHistoryLength = 60; // 60 seconds history
  @override
  Widget build(BuildContext context) {
    final service = context.read<SystemMonitorService>();
    final themeManager = context.watch<ThemeManager>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FlutterTop',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              themeManager.themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: themeManager.toggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (ctx) => const SettingsView()));
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: StreamBuilder<SystemState>(
        stream: service.systemStateStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final state = snapshot.data!;

          // Update history
          if (state.cpu != null) {
            _cpuHistory.addFirst(state.cpu!.total.usagePercentage);
            if (_cpuHistory.length > maxHistoryLength) _cpuHistory.removeLast();
          }
          if (state.memory != null) {
            _memHistory.addFirst(state.memory!.memUsagePercentage);
            if (_memHistory.length > maxHistoryLength) _memHistory.removeLast();
          }

          // Desktop style layout
          return LayoutBuilder(
            builder: (context, constraints) {
              const double minWidth = 850.0;
              const double minHeight = 780.0;

              final double width = constraints.maxWidth < minWidth
                  ? minWidth
                  : constraints.maxWidth;
              final double height = constraints.maxHeight < minHeight
                  ? minHeight
                  : constraints.maxHeight;

              Widget content = SizedBox(
                width: width,
                height: height,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Metrics Grid & Charts
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            // Hardware Fingerprint Header
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${state.identity.osName} (${state.identity.kernelVersion}) - ${state.identity.architecture}',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (state.thermal?.packageTemp != null)
                                        Text(
                                          '${state.thermal!.packageTemp!.toStringAsFixed(1)}°C',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                color:
                                                    state
                                                            .thermal!
                                                            .packageTemp! >
                                                        80
                                                    ? Colors.red
                                                    : Colors.green,
                                              ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'CPU: ${state.identity.cpuModelName} (${state.identity.cpuLogicalCores} Threads, ${state.identity.cpuCacheSize} Cache)',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                  if (state
                                      .identity
                                      .networkInterfaces
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Network: ${state.identity.networkInterfaces.where((n) => n.isUp).map((n) => n.name).join(', ')}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: Colors.grey),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // History Charts
                            SizedBox(
                              height: 200,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TimeSeriesChart(
                                      title: 'CPU History',
                                      dataPoints: _cpuHistory.toList(),
                                      color: Colors.blueAccent,
                                      maxY: 100.0,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TimeSeriesChart(
                                      title: 'Memory History',
                                      dataPoints: _memHistory.toList(),
                                      color: Colors.purpleAccent,
                                      maxY: 100.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Current Stats Grid (Expanded Matrix Structure)
                            Expanded(
                              child: Column(
                                children: [
                                  // Row 1
                                  Expanded(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        // CPU Usage
                                        Expanded(
                                          child: BaseMetricCard(
                                            title: 'CPU Usage',
                                            value:
                                                '${state.cpu?.total.usagePercentage.toStringAsFixed(1) ?? "--"}%',
                                            subtitle: state.cpu != null
                                                ? '${state.cpu!.globalClockSpeedMhz.toStringAsFixed(0)} MHz | Ctxt: ${state.cpu!.contextSwitches}'
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Memory Usage
                                        Expanded(
                                          child: BaseMetricCard(
                                            title: 'Memory RAM',
                                            value:
                                                '${state.memory?.memUsagePercentage.toStringAsFixed(1) ?? "--"}%',
                                            subtitle:
                                                'Act: ${((state.memory?.activeMemBytes ?? 0) / (1024 * 1024 * 1024)).toStringAsFixed(1)}G | Inact: ${((state.memory?.inactiveMemBytes ?? 0) / (1024 * 1024 * 1024)).toStringAsFixed(1)}G',
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Disk I/O
                                        Expanded(
                                          child: BaseMetricCard(
                                            title: 'Disk I/O (MB/s)',
                                            value: state.disk != null
                                                ? '${(state.disk!.totalBytesReadPerSec / (1024 * 1024)).toStringAsFixed(1)} / ${(state.disk!.totalBytesWrittenPerSec / (1024 * 1024)).toStringAsFixed(1)}'
                                                : 'N/A',
                                            subtitle: state.disk != null
                                                ? 'Read / Write'
                                                : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Row 2
                                  Expanded(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        // CPU Core Heatmap
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Theme.of(
                                                context,
                                              ).cardColor,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.grey.withOpacity(
                                                  0.2,
                                                ),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Core Topography',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        color: Colors.grey,
                                                      ),
                                                ),
                                                const SizedBox(height: 8),
                                                Expanded(
                                                  child: CpuCoreHeatmap(
                                                    cores:
                                                        state.cpu?.cores ?? [],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // GPU
                                        Expanded(
                                          child: GpuMetricCard(state: state),
                                        ),
                                        const SizedBox(width: 12),
                                        // Network I/O
                                        Expanded(
                                          child: NetworkMetricCard(
                                            state: state,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Row 3
                                  Expanded(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        // Power / Battery
                                        Expanded(
                                          child: BaseMetricCard(
                                            title: 'Power Draw',
                                            value: state.power != null
                                                ? '${state.power!.powerDrawMw.toStringAsFixed(1)} W'
                                                : 'A/C Wall',
                                            subtitle: state.power != null
                                                ? '${state.power!.batteryPercentage.toStringAsFixed(1)}% ${state.power!.isCharging ? "Charging" : "Discharging"}'
                                                : 'Battery N/A',
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // External Drive I/O
                                        Expanded(
                                          child: ExternalDriveMetricCard(
                                            state: state,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Storage Capacity Breakdown
                                        Expanded(
                                          child: StoragePieChartCard(
                                            state: state,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Right Column: Top Processes
                      Expanded(
                        flex: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Top Processes',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const Divider(height: 1),
                              Expanded(
                                child: ProcessListWidget(
                                  processes: state.processes,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );

              if (constraints.maxWidth < minWidth ||
                  constraints.maxHeight < minHeight) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: content,
                  ),
                );
              }

              return content;
            },
          );
        },
      ),
    );
  }
}
