import 'dart:async';
import 'dart:io';

import 'package:bc_launcher/services/minecraft_session_store.dart';
import 'package:bc_launcher/utils/minecraft.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('a fresh session lasts a little less than a day', () {
    final session = MinecraftSession.fresh(
      uuid: 'abc',
      name: 'Nyxar',
      token: 'token',
    );
    final left = session.expiresAt.difference(DateTime.now());
    expect(left, lessThanOrEqualTo(const Duration(hours: 23)));
    expect(left, greaterThan(const Duration(hours: 22)));
    expect(session.isExpired, isFalse);
  });

  test('a session past its time is expired', () {
    final session = MinecraftSession(
      uuid: 'abc',
      name: 'Nyxar',
      token: 'token',
      expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
    );
    expect(session.isExpired, isTrue);
  });

  test('is saved, read back and cleared', () async {
    expect(await MinecraftSessionStore.read(), isNull);

    await MinecraftSessionStore.write(
      MinecraftSession(
        uuid: 'abc',
        name: 'Nyxar',
        token: 'token',
        expiresAt: DateTime.utc(2026, 11, 8, 12),
      ),
    );
    final read = await MinecraftSessionStore.read();
    expect(read!.uuid, 'abc');
    expect(read.name, 'Nyxar');
    expect(read.token, 'token');
    expect(read.expiresAt, DateTime.utc(2026, 11, 8, 12));

    await MinecraftSessionStore.clear();
    expect(await MinecraftSessionStore.read(), isNull);
  });

  test('a broken saved session is none', () async {
    FlutterSecureStorage.setMockInitialValues({'minecraft_session': '{bad'});
    expect(await MinecraftSessionStore.read(), isNull);
  });

  test('only connection failures count as no internet', () {
    expect(Minecraft.isNetworkError(const SocketException('no')), isTrue);
    expect(Minecraft.isNetworkError(http.ClientException('no')), isTrue);
    expect(Minecraft.isNetworkError(TimeoutException('slow')), isTrue);
    expect(Minecraft.isNetworkError(Exception('rejected')), isFalse);
  });
}
