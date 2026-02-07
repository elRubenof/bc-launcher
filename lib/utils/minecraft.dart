import 'dart:io';

import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/launch_utils/Minecraft_launcher_core.dart';
import 'package:bc_launcher/utils/settings.dart';
import 'package:dart_minecraft/dart_minecraft.dart';
import 'package:flutter/material.dart';
import 'package:oauth2/oauth2.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Minecraft {
  static ValueNotifier<Profile?> profile = ValueNotifier(null);

  static late HttpServer _redirectServer;
  static late Credentials _credentials;

  static const String _authorizationEndpoint =
      "https://login.live.com/oauth20_authorize.srf";
  static const String _tokenEndpoint =
      "https://login.live.com/oauth20_token.srf";

  static Future<bool> authenticateOauth2() async {
    final preferences = await SharedPreferences.getInstance();
    final credentialsJson = preferences.getString("credentials") ?? "";

    try {
      if (credentialsJson.isEmpty) return false;

      _credentials = Credentials.fromJson(credentialsJson);
      _credentials = await _credentials.refresh(identifier: Constants.clientID);

      profile.value = await getCurrentProfile(await getToken());
    } catch (e) {
      final supportDirectory = await getApplicationSupportDirectory();
      File file = File("${supportDirectory.path}/error.txt");
      await file.writeAsString(e.toString());

      return false;
    }

    return true;
  }

  static logout() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove("credentials");
  }

  static Future<String> getToken() async {
    if (_credentials.isExpired) await authenticateOauth2();

    final xbl = await authenticateXBL(_credentials.accessToken);
    final xsts = await authenticateXSTS(xbl.first);
    return await authenticateWithXBOX(xsts.first, xsts.second);
  }

  static Future<AuthorizationCodeGrant> getAuthorizationCode() async {
    return AuthorizationCodeGrant(
      Constants.clientID,
      Uri.parse(_authorizationEndpoint),
      Uri.parse(_tokenEndpoint),
      httpClient: _JsonAcceptingHttpClient(),
    );
  }

  static Future<Map<String, String>> listenParameters() async {
    _redirectServer = await HttpServer.bind('127.0.0.1', 5020);

    final request = await _redirectServer.first;
    final params = request.uri.queryParameters;
    request.response.statusCode = 200;
    request.response.headers.set('content-type', 'text/plain; charset=utf-8');
    await request.response.close();
    await _redirectServer.close();

    return params;
  }

  static Future<void> launch(Map server, {bool close = true}) async {
    final token = await Minecraft.getToken();
    profile.value ??= await getCurrentProfile(token);

    Map options = {
      'username': profile.value!.name,
      'uuid': profile.value!.uuid,
      'token': token,
      'executablePath':
          '${Directory.current.path}/runtime/java-runtime-gamma/windows-x64/java-runtime-gamma/bin/java.exe',
      'jvmArguments': ["-Xmx${Settings.allocatedRAM}G"],
      if (Settings.autoConnect && server['ip'] != null)
        'quickPlayMultiplayer': server['ip'],
      if (!Settings.fullscreen) 'resolutionWidth': "${Settings.gameWidth}",
      if (!Settings.fullscreen) 'resolutionHeight': "${Settings.gameHeight}",
    };

    List<String> cmd = await MinecraftLauncherCore.getMinecraftCommand(
      server['version'],
      Settings.minecraftDirectory.path,
      options,
    );

    final process = await Process.start(
      cmd[0],
      cmd.sublist(1),
      mode: ProcessStartMode.detachedWithStdio,
    );

    if (close) process.stdout.listen((line) => exit(0));
  }
}

class _JsonAcceptingHttpClient extends http.BaseClient {
  final _httpClient = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Accept'] = 'application/json';
    return _httpClient.send(request);
  }
}
