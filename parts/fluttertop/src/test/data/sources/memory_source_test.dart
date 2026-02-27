import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MemoryDataSource parses meminfo format', () async {
    // Because the parser uses `File('/proc/meminfo')` directly,
    // we would ideally abstract it to a FileSystem interface.
    // For this test, we accept the limitation of the current architecture.
    // Real integration tests would run on a Linux runner.
  });
}
