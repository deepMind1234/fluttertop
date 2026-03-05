class ProcessInfo {
  final int pid;
  final String user;
  final String name;
  final double cpuUsagePercentage;
  final int memoryUsageBytes;
  final String state;
  final int coreId;
  final Duration uptime;
  final int minflt;
  final int majflt;
  final int voluntaryCtxtSwitches;
  final int nonvoluntaryCtxtSwitches;
  final int threadsCount;
  final int vmPeakKb;
  final int vmSizeKb;
  final int vmHwmKb;
  final int readBytes;
  final int writeBytes;
  final String commandLine;
  final String executablePath;

  ProcessInfo({
    required this.pid,
    required this.user,
    required this.name,
    required this.cpuUsagePercentage,
    required this.memoryUsageBytes,
    required this.state,
    required this.coreId,
    required this.uptime,
    required this.minflt,
    required this.majflt,
    required this.voluntaryCtxtSwitches,
    required this.nonvoluntaryCtxtSwitches,
    required this.threadsCount,
    required this.vmPeakKb,
    required this.vmSizeKb,
    required this.vmHwmKb,
    required this.readBytes,
    required this.writeBytes,
    required this.commandLine,
    required this.executablePath,
  });
}
