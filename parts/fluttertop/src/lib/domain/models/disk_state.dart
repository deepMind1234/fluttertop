class DiskIoStat {
  final String deviceName;
  final int sectorsRead;
  final int sectorsWritten;
  final int bytesReadPerSec; // derived over time
  final int bytesWrittenPerSec; // derived over time
  final bool isExternal;

  DiskIoStat({
    required this.deviceName,
    required this.sectorsRead,
    required this.sectorsWritten,
    this.bytesReadPerSec = 0,
    this.bytesWrittenPerSec = 0,
    this.isExternal = false,
  });
}

class LogicalDriveCapacity {
  final String mountPoint;
  final String fileSystem;
  final int totalMb;
  final int usedMb;
  final int freeMb;

  LogicalDriveCapacity({
    required this.mountPoint,
    required this.fileSystem,
    required this.totalMb,
    required this.usedMb,
    required this.freeMb,
  });
}

class SystemDiskState {
  final List<DiskIoStat> disks;
  final List<LogicalDriveCapacity> logicalDrives;

  SystemDiskState({required this.disks, this.logicalDrives = const []});

  int get totalBytesReadPerSec => disks
      .where((d) => !d.isExternal)
      .fold(0, (sum, disk) => sum + disk.bytesReadPerSec);
  int get totalBytesWrittenPerSec => disks
      .where((d) => !d.isExternal)
      .fold(0, (sum, disk) => sum + disk.bytesWrittenPerSec);

  List<DiskIoStat> get externalDrives =>
      disks.where((d) => d.isExternal).toList();
}
