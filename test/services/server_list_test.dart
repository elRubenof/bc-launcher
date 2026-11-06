import 'dart:io';

import 'package:bc_launcher/services/server_list.dart';
import 'package:dart_minecraft/dart_nbt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';

void main() {
  late Directory folder;
  late File file;

  setUp(() async {
    folder = await Directory.systemTemp.createTemp('server_list_test');
    file = File(join(folder.path, 'servers.dat'));
  });
  tearDown(() => folder.delete(recursive: true));

  /// A list written by the game: several servers with more fields.
  Future<void> writeGameList() async {
    NbtCompound server(String name, String ip) => NbtCompound(
      name: '',
      children: [
        NbtString(name: 'name', value: name),
        NbtString(name: 'ip', value: ip),
        NbtByte(name: 'acceptTextures', value: 1),
      ],
    );
    await file.writeAsBytes(
      NbtWriter().write(
        NbtCompound(
          name: '',
          children: [
            NbtList(
              name: 'servers',
              children: [
                server('Mine', 'my.server'),
                server('Series', 'old.example.com'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  test('creates a list with one server the game can read', () async {
    await ServerList.create(file, 'Spartaland 3', 'play.example.com');

    final root = NbtReader(await file.readAsBytes()).read();
    final servers = root.getChildrenByName('servers').single as NbtList;
    final server = servers.single as NbtCompound;
    expect(server.getChildrenByName('name').single.value, 'Spartaland 3');
    expect(server.getChildrenByName('ip').single.value, 'play.example.com');
    expect(await File('${file.path}.part').exists(), isFalse);
  });

  test('changes only the entry with the old address', () async {
    await writeGameList();

    final replaced = await ServerList.replaceAddress(
      file,
      'old.example.com',
      'new.example.com',
    );

    expect(replaced, isTrue);
    expect(await ServerList.addresses(file), ['my.server', 'new.example.com']);
    final root = NbtReader(await file.readAsBytes()).read();
    final series = (root.getChildrenByName('servers').single as NbtList)[1];
    expect(
      (series as NbtCompound).getChildrenByName('name').single.value,
      'Series',
    );
    expect(series.getChildrenByName('acceptTextures').single.value, 1);
  });

  test('leaves the list alone when the old address is not there', () async {
    await writeGameList();
    final before = await file.readAsBytes();

    final replaced = await ServerList.replaceAddress(
      file,
      'gone.example.com',
      'new.example.com',
    );

    expect(replaced, isFalse);
    expect(await file.readAsBytes(), before);
  });

  test('a missing file has no addresses and nothing to replace', () async {
    expect(await ServerList.addresses(file), isEmpty);
    expect(await ServerList.replaceAddress(file, 'a', 'b'), isFalse);
    expect(await file.exists(), isFalse);
  });
}
