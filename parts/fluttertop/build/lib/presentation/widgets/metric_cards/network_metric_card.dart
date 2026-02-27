import 'package:flutter/material.dart';
import '../../../domain/models/system_state.dart';
import 'base_metric_card.dart';

class NetworkMetricCard extends StatefulWidget {
  final SystemState state;

  const NetworkMetricCard({super.key, required this.state});

  @override
  State<NetworkMetricCard> createState() => _NetworkMetricCardState();
}

class _NetworkMetricCardState extends State<NetworkMetricCard> {
  int _selectedNetworkIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.state.network == null ||
        widget.state.network!.interfaces.isEmpty) {
      return const BaseMetricCard(
        title: 'Network (MB/s)',
        value: '-- / --',
        subtitle: '0 Active Interfaces',
      );
    }

    final interfaces = widget.state.network!.interfaces;
    final currentIndex = _selectedNetworkIndex % interfaces.length;
    final currentInterface = interfaces[currentIndex];

    return GestureDetector(
      onTap: () {
        if (interfaces.length > 1) {
          setState(() {
            _selectedNetworkIndex =
                (_selectedNetworkIndex + 1) % interfaces.length;
          });
        }
      },
      child: BaseMetricCard(
        title:
            'Net (${currentInterface.name})${interfaces.length > 1 ? " 🔄" : ""} (MB/s)',
        value:
            '${(currentInterface.bytesReceivedPerSec / (1024 * 1024)).toStringAsFixed(1)} / ${(currentInterface.bytesSentPerSec / (1024 * 1024)).toStringAsFixed(1)}',
        subtitle: 'Rx / Tx',
      ),
    );
  }
}
