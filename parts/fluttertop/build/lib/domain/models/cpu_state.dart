class CpuCoreStat {
  final String name;
  final double user; // percentage
  final double system; // percentage
  final double idle; // percentage
  final double usagePercentage; // overall utilization

  CpuCoreStat({
    required this.name,
    required this.user,
    required this.system,
    required this.idle,
    required this.usagePercentage,
  });
}

class SystemCpuState {
  final CpuCoreStat total;
  final List<CpuCoreStat> cores;
  final double globalClockSpeedMhz;
  final int contextSwitches;

  SystemCpuState({
    required this.total,
    required this.cores,
    required this.globalClockSpeedMhz,
    required this.contextSwitches,
  });
}
