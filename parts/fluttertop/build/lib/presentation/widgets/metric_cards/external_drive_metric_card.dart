import 'package:flutter/material.dart';
import '../../../domain/models/system_state.dart';
import 'base_metric_card.dart';

class ExternalDriveMetricCard extends StatefulWidget {
  final SystemState state;

  const ExternalDriveMetricCard({super.key, required this.state});

  @override
  State<ExternalDriveMetricCard> createState() =>
      _ExternalDriveMetricCardState();
}

class _ExternalDriveMetricCardState extends State<ExternalDriveMetricCard> {
  int _selectedExternalDriveIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.state.disk == null ||
        widget.state.disk!.externalDrives.isEmpty) {
      return const BaseMetricCard(
        title: 'Ext Drive (MB/s)',
        value: 'N/A',
        subtitle: 'Not Connected',
      );
    }

    final drives = widget.state.disk!.externalDrives;
    final currentIndex = _selectedExternalDriveIndex % drives.length;
    final currentDrive = drives[currentIndex];

    return GestureDetector(
      onTap: () {
        if (drives.length > 1) {
          setState(() {
            _selectedExternalDriveIndex =
                (_selectedExternalDriveIndex + 1) % drives.length;
          });
        }
      },
      child: BaseMetricCard(
        title:
            'Ext Drive (${currentDrive.deviceName})${drives.length > 1 ? " 🔄" : ""} (MB/s)',
        value:
            '${(currentDrive.bytesReadPerSec / (1024 * 1024)).toStringAsFixed(1)} / ${(currentDrive.bytesWrittenPerSec / (1024 * 1024)).toStringAsFixed(1)}',
        subtitle: 'Read / Write',
      ),
    );
  }
}
