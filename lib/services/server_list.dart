import 'dart:io';
import 'dart:typed_data';

import 'package:dart_minecraft/dart_nbt.dart';

/// The game's multiplayer server list, `servers.dat` (uncompressed NBT: a
/// `servers` list of compounds with `name` and `ip`).
class ServerList {
  /// Writes a list with one server, replacing [file] if it exists.
  static Future<void> create(File file, String name, String address) {
    return _write(
      file,
      NbtCompound(
        name: '',
        children: [
          NbtList(
            name: 'servers',
            children: [
              NbtCompound(
                name: '',
                children: [
                  NbtString(name: 'name', value: name),
                  NbtString(name: 'ip', value: address),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Changes the address of the entries with [from] to [to] and leaves the
  /// rest alone. Returns whether any entry had [from].
  static Future<bool> replaceAddress(File file, String from, String to) async {
    if (!await file.exists()) return false;

    final root = NbtReader(await file.readAsBytes()).read();
    var replaced = false;
    for (final list in root.getChildrenByName('servers')) {
      if (list is! NbtList) continue;
      for (final server in list.children) {
        if (server is! NbtCompound) continue;
        for (var i = 0; i < server.children.length; i++) {
          final tag = server.children[i];
          if (tag is NbtString && tag.name == 'ip' && tag.value == from) {
            server.children[i] = NbtString(name: 'ip', value: to)
              ..parent = server;
            replaced = true;
          }
        }
      }
    }

    if (replaced) await _write(file, root);
    return replaced;
  }

  /// The addresses in [file], in order (empty if it doesn't exist).
  static Future<List<String>> addresses(File file) async {
    if (!await file.exists()) return const [];

    final root = NbtReader(await file.readAsBytes()).read();
    return [
      for (final list in root.getChildrenByName('servers'))
        if (list is NbtList)
          for (final server in list.children)
            if (server is NbtCompound)
              for (final tag in server.getChildrenByName('ip'))
                if (tag is NbtString) tag.value,
    ];
  }

  static Future<void> _write(File file, NbtCompound root) async {
    final bytes = NbtWriter().write(root);
    await file.parent.create(recursive: true);
    final part = File("${file.path}.part");
    await part.writeAsBytes(Uint8List.fromList(bytes));
    await part.rename(file.path);
  }
}
