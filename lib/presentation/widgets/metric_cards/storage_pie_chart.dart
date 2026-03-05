import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../domain/models/system_state.dart';

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
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Text('Storage: N/A')),
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
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title on Top
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Storage (${currentDrive.mountPoint})${drives.length > 1 ? " 🔄" : ""}',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                children: [
                  // Larger Pie Chart
                  Expanded(
                    flex: 3,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 0,
                        centerSpaceRadius: 28,
                        sections: [
                          PieChartSectionData(
                            color: Colors.deepPurpleAccent,
                            value: currentDrive.usedMb == 0
                                ? 1
                                : currentDrive.usedMb.toDouble(),
                            title: '',
                            radius: 16,
                          ),
                          PieChartSectionData(
                            color: Colors.grey.withOpacity(0.2),
                            value: currentDrive.freeMb == 0
                                ? 1
                                : currentDrive.freeMb.toDouble(),
                            title: '',
                            radius: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Formatted Details
                  Expanded(
                    flex: 4,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${(currentDrive.usedMb / 1024).toStringAsFixed(1)} GB Used',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.deepPurpleAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Total: ${(currentDrive.totalMb / 1024).toStringAsFixed(1)} GB',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            currentDrive.fileSystem.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
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
    );
  }
}
