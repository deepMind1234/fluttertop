class SystemMemoryState {
  final int totalMemBytes;
  final int usedMemBytes;
  final int freeMemBytes;
  final int buffersBytes;
  final int cachedBytes; // includes reclaimable
  final int activeMemBytes;
  final int inactiveMemBytes;
  final int totalSwapBytes;
  final int usedSwapBytes;
  final int freeSwapBytes;

  SystemMemoryState({
    required this.totalMemBytes,
    required this.usedMemBytes,
    required this.freeMemBytes,
    required this.buffersBytes,
    required this.cachedBytes,
    required this.activeMemBytes,
    required this.inactiveMemBytes,
    required this.totalSwapBytes,
    required this.usedSwapBytes,
    required this.freeSwapBytes,
  });

  double get memUsagePercentage => (usedMemBytes / totalMemBytes) * 100;
  double get swapUsagePercentage =>
      totalSwapBytes > 0 ? (usedSwapBytes / totalSwapBytes) * 100 : 0;
}
