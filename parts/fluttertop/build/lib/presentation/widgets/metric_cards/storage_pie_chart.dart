import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../domain/models/system_state.dart';
import 'base_metric_card.dart';

class StoragePieChartCard extends StatefulWidget {
  final SystemState state;

  const StoragePieChartCard({super.key, required this.state});

  @override
  State<StoragePieChartCard> createState() => _StoragePieChartCardState();
}

class _StoragePieChartCardState extends State<StoragePieChartCard> {
  int _selectedLogicalDriveIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.state.disk == null || widget.state.disk!.logicalDrives.isEmpty) {
      return const BaseMetricCard(
        title: 'Storage Capacity',
        value: 'N/A',
        subtitle: 'No drives detected',
      );
    }

    final drives = widget.state.disk!.logicalDrives;
    final currentIndex = _selectedLogicalDriveIndex % drives.length;
    final currentDrive = drives[currentIndex];

    return GestureDetector(
      onTap: () {
        if (drives.length > 1) {
          setState(() {
            _selectedLogicalDriveIndex =
                (_selectedLogicalDriveIndex + 1) % drives.length;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 0,
                  centerSpaceRadius: 22,
                  sections: [
                    PieChartSectionData(
                      color: Colors.deepPurpleAccent,
                      value: currentDrive.usedMb == 0
                          ? 1
                          : currentDrive.usedMb.toDouble(),
                      title: '',
                      radius: 12,
                    ),
                    PieChartSectionData(
                      color: Colors.grey.withOpacity(0.2),
                      value: currentDrive.freeMb == 0
                          ? 1
                          : currentDrive.freeMb.toDouble(),
                      title: '',
                      radius: 12,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Storage (${currentDrive.mountPoint})${drives.length > 1 ? " 🔄" : ""}',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${(currentDrive.usedMb / 1024).toStringAsFixed(1)} GB Used',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.deepPurpleAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Tot: ${(currentDrive.totalMb / 1024).toStringAsFixed(1)} GB [${currentDrive.fileSystem}]',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
