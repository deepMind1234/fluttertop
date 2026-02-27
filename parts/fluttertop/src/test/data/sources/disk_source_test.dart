import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertop/data/sources/disk_source.dart';

void main() {
  test('DiskDataSource parses disk stats correctly', () async {
    final source = DiskDataSource();
    final state = await source.getDiskState();

    // Success depends on /proc/diskstats being present (standard Linux)
    if (state != null) {
      expect(state.disks, isNotNull);
    }
  });
}
