import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertop/data/sources/identity_source.dart';

void main() {
  test('IdentitySource parses cpuinfo properties robustly', () async {
    // For this test, normally we'd inject a FileSystem.
    // Since we read direct files, we rely on the host machine having /proc/cpuinfo.
    // We just want to ensure it doesn't crash on standard Linux.
    final source = SystemIdentitySource();
    final identity = await source.getIdentity();

    expect(identity.cpuLogicalCores > 0, true);
    expect(identity.cpuModelName, isNotEmpty);
  });
}
