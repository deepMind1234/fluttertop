class GpuSysfsState {
  final String deviceName;
  final double gpuUsagePercentage;
  final double memUsagePercentage;

  GpuSysfsState({
    required this.deviceName,
    required this.gpuUsagePercentage,
    required this.memUsagePercentage,
  });
}
