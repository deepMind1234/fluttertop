class SystemPaths {
  // Processor
  static const String procStat = '/proc/stat';
  static const String procCpuInfo = '/proc/cpuinfo';

  // Memory
  static const String procMemInfo = '/proc/meminfo';

  // Disk & Storage
  static const String procDiskStats = '/proc/diskstats';
  static const String sysBlock = '/sys/block';

  // Network
  static const String procNetDev = '/proc/net/dev';
  static const String sysClassNet = '/sys/class/net';

  // Power & Battery
  static const String sysClassPowerSupply = '/sys/class/power_supply';

  // GPU & Thermals
  static const String sysClassDrm = '/sys/class/drm';
  static const String sysClassThermal = '/sys/class/thermal';
  static const String sysClassHwmon = '/sys/class/hwmon';

  // Process Details
  static const String procDir = '/proc';
}
