import 'package:flutter/material.dart';
import '../../domain/models/cpu_state.dart';

class CpuCoreHeatmap extends StatelessWidget {
  final List<CpuCoreStat> cores;

  const CpuCoreHeatmap({super.key, required this.cores});

  Color _getColorForUsage(double usage) {
    // 0% = dark green or grey, 100% = bright red
    // For a dark theme heatmap, let's use HSL to transition from green (120) to red (0)
    final hue = (1.0 - (usage / 100.0).clamp(0.0, 1.0)) * 120.0;
    return HSLColor.fromAHSL(1.0, hue, 0.8, 0.4).toColor();
  }

  @override
  Widget build(BuildContext context) {
    if (cores.isEmpty) {
      return const Center(child: Text('No per-core data available'));
    }

    // Determine grid size. We want it dense.
    // E.g. for 16 cores, 4x4. For 24, 6x4 or 8x3. Wrap handles this nicely.
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate a nice square size based on the width and number of items
        int columns = (cores.length <= 4)
            ? 4
            : (cores.length <= 16)
            ? 8
            : (cores.length <= 64)
            ? 16
            : 32;

        double spacing = 2.0;
        double itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        // Constrain the block size so it doesn't become gigantic on wide displays
        if (itemWidth > 20.0) {
          itemWidth = 20.0;
        }

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cores.map((core) {
            return Tooltip(
              message:
                  '${core.name}: ${core.usagePercentage.toStringAsFixed(1)}%',
              waitDuration: const Duration(milliseconds: 200),
              child: Container(
                width: itemWidth,
                height: itemWidth, // Square
                decoration: BoxDecoration(
                  color: _getColorForUsage(core.usagePercentage),
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
