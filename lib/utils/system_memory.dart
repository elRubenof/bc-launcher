import 'dart:developer';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

/// The computer's total RAM, the most an instance can be given.
class SystemMemory {
  /// When it can't be read.
  static const fallbackGb = 16;

  static Future<int>? _totalGb;

  /// In GB, rounded; read once.
  static Future<int> totalGb() => _totalGb ??= _read();

  static Future<int> _read() async {
    try {
      final bytes = switch (Platform.operatingSystem) {
        'macos' => parseSysctl(
          (await Process.run('sysctl', ['-n', 'hw.memsize'])).stdout as String,
        ),
        'linux' => parseMeminfo(await File('/proc/meminfo').readAsString()),
        'windows' => _windowsBytes(),
        _ => null,
      };
      if (bytes != null && bytes > 0) return toGb(bytes);
    } catch (e) {
      log("Could not read the total RAM: $e");
    }
    return fallbackGb;
  }

  static int toGb(int bytes) {
    final gb = (bytes / (1024 * 1024 * 1024)).round();
    return gb < 1 ? 1 : gb;
  }

  /// `sysctl -n hw.memsize` → bytes.
  static int? parseSysctl(String output) => int.tryParse(output.trim());

  /// `/proc/meminfo`'s `MemTotal: <n> kB` → bytes.
  static int? parseMeminfo(String meminfo) {
    final match = RegExp(
      r'^MemTotal:\s+(\d+)\s*kB',
      multiLine: true,
    ).firstMatch(meminfo);
    final kb = match == null ? null : int.tryParse(match.group(1)!);
    return kb == null ? null : kb * 1024;
  }

  /// `GlobalMemoryStatusEx`'s `ullTotalPhys`.
  static int? _windowsBytes() {
    final kernel32 = DynamicLibrary.open('kernel32.dll');
    final globalMemoryStatusEx = kernel32
        .lookupFunction<
          Int32 Function(Pointer<_MemoryStatusEx>),
          int Function(Pointer<_MemoryStatusEx>)
        >('GlobalMemoryStatusEx');

    final status = calloc<_MemoryStatusEx>();
    try {
      status.ref.dwLength = sizeOf<_MemoryStatusEx>();
      if (globalMemoryStatusEx(status) == 0) return null;
      return status.ref.ullTotalPhys;
    } finally {
      calloc.free(status);
    }
  }
}

/// Windows' `MEMORYSTATUSEX`.
final class _MemoryStatusEx extends Struct {
  @Uint32()
  external int dwLength;
  @Uint32()
  external int dwMemoryLoad;
  @Uint64()
  external int ullTotalPhys;
  @Uint64()
  external int ullAvailPhys;
  @Uint64()
  external int ullTotalPageFile;
  @Uint64()
  external int ullAvailPageFile;
  @Uint64()
  external int ullTotalVirtual;
  @Uint64()
  external int ullAvailVirtual;
  @Uint64()
  external int ullAvailExtendedVirtual;
}
