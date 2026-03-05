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

  // Track the currently displayed unit and when it was last changed.
  String _currentUnit = 'KB/s';
  DateTime _lastUnitChangeTime = DateTime.now();

  @override
  Widget build(BuildContext context) {
    if (widget.state.network == null ||
        widget.state.network!.interfaces.isEmpty) {
      return const BaseMetricCard(
        title: 'Network',
        value: '-- / --',
        subtitle: '0 Active Interfaces',
      );
    }

    final interfaces = widget.state.network!.interfaces;
    final currentIndex = _selectedNetworkIndex % interfaces.length;
    final currentInterface = interfaces[currentIndex];

    // Determine the ideal unit based on max traffic (rx or tx)
    final int maxTrafic =
        currentInterface.bytesReceivedPerSec > currentInterface.bytesSentPerSec
        ? currentInterface.bytesReceivedPerSec
        : currentInterface.bytesSentPerSec;

    String idealUnit = 'B/s';
    if (maxTrafic >= 1024 * 1024) {
      idealUnit = 'MB/s';
    } else if (maxTrafic >= 1024) {
      idealUnit = 'KB/s';
    }

    // Debounce unit changes: only allow change if 5 seconds have passed,
    // or if the traffic suddenly spikes to a higher unit (always allow scaling up immediately).
    final now = DateTime.now();
    bool shouldUpdateUnit = false;

    // Determine unit rank for immediate scale-up
    int rank(String u) => u == 'B/s' ? 0 : (u == 'KB/s' ? 1 : 2);

    if (rank(idealUnit) > rank(_currentUnit)) {
      shouldUpdateUnit = true; // Spike up immediately
    } else if (idealUnit != _currentUnit &&
        now.difference(_lastUnitChangeTime).inSeconds >= 5) {
      shouldUpdateUnit = true; // Fall down or change after 5s
    }

    if (shouldUpdateUnit) {
      _currentUnit = idealUnit;
      _lastUnitChangeTime = now;
    }

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
            'Net (${currentInterface.name})${interfaces.length > 1 ? " 🔄" : ""} ($_currentUnit)',
        value:
            '${_formatValue(currentInterface.bytesReceivedPerSec, _currentUnit)} / ${_formatValue(currentInterface.bytesSentPerSec, _currentUnit)}',
        subtitle: 'Rx / Tx',
      ),
    );
  }

  String _formatValue(int bytesPerSec, String unit) {
    if (unit == 'B/s') {
      return bytesPerSec.toString();
    } else if (unit == 'KB/s') {
      return (bytesPerSec / 1024).toStringAsFixed(1);
    } else {
      return (bytesPerSec / (1024 * 1024)).toStringAsFixed(1);
    }
  }
}
