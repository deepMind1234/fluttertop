import 'package:flutter/material.dart';
import '../../../domain/models/system_state.dart';
import 'base_metric_card.dart';

class GpuMetricCard extends StatefulWidget {
  final SystemState state;

  const GpuMetricCard({super.key, required this.state});

  @override
  State<GpuMetricCard> createState() => _GpuMetricCardState();
}

class _GpuMetricCardState extends State<GpuMetricCard> {
  int _selectedGpuIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.state.gpus.isEmpty) {
      return const BaseMetricCard(title: 'GPU', value: 'N/A');
    }

    final gpus = widget.state.gpus;
    final currentIndex = _selectedGpuIndex % gpus.length;
    final currentGpu = gpus[currentIndex];

    return GestureDetector(
      onTap: () {
        if (gpus.length > 1) {
          setState(() {
            _selectedGpuIndex = (_selectedGpuIndex + 1) % gpus.length;
          });
        }
      },
      child: BaseMetricCard(
        title: 'GPU (${currentGpu.deviceName})${gpus.length > 1 ? " 🔄" : ""}',
        value: '${currentGpu.gpuUsagePercentage.toStringAsFixed(1)}%',
        subtitle: 'VRAM: ${currentGpu.memUsagePercentage.toStringAsFixed(1)}%',
      ),
    );
  }
}
