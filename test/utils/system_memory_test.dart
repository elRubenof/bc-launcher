import 'package:bc_launcher/utils/system_memory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads macOS\' sysctl', () {
    expect(SystemMemory.parseSysctl('17179869184\n'), 17179869184);
    expect(SystemMemory.parseSysctl(''), isNull);
  });

  test('reads Linux\' MemTotal', () {
    const meminfo = 'MemTotal:       16314224 kB\nMemFree:         1234 kB\n';
    expect(SystemMemory.parseMeminfo(meminfo), 16314224 * 1024);
    expect(SystemMemory.parseMeminfo('MemFree: 1 kB'), isNull);
  });

  test('rounds to GB, at least 1', () {
    expect(SystemMemory.toGb(17179869184), 16);
    expect(SystemMemory.toGb(16314224 * 1024), 16);
    expect(SystemMemory.toGb(100), 1);
  });
}
