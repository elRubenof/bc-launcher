import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:bc_launcher/services/credentials_store.dart';
import 'package:bc_launcher/services/java_manager.dart';
import 'package:bc_launcher/services/library_manager.dart';
import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/launch_utils/minecraft_launcher_core.dart';
import 'package:bc_launcher/utils/settings.dart';
import 'package:dart_minecraft/dart_minecraft.dart';
import 'package:flutter/material.dart';
import 'package:oauth2/oauth2.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// What [Minecraft.prepare] is downloading.
enum PrepareStep { libraries, java }

class Minecraft {
  static ValueNotifier<Profile?> profile = ValueNotifier(null);

  static HttpServer? _redirectServer;
  static late Credentials _credentials;

  static const String _authorizationEndpoint =
      "https://login.live.com/oauth20_authorize.srf";
  static const String _tokenEndpoint =
      "https://login.live.com/oauth20_token.srf";

  static Future<bool> authenticateOauth2() async {
    final credentialsJson = await CredentialsStore.read();

    try {
      if (credentialsJson == null) return false;

      _credentials = Credentials.fromJson(credentialsJson);
      _credentials = await _credentials.refresh(identifier: Constants.clientID);
      // Microsoft rotates the refresh token, so keep the new one.
      await CredentialsStore.write(_credentials.toJson());

      profile.value = await getCurrentProfile(await getToken());
    } catch (e) {
      final supportDirectory = await getApplicationSupportDirectory();
      File file = File(join(supportDirectory.path, "error.txt"));
      await file.writeAsString(e.toString());

      return false;
    }

    return true;
  }

  static logout() async {
    await CredentialsStore.clear();
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

  static Uri getAuthorizationUrl(AuthorizationCodeGrant grant, Uri redirect) {
    final random = Random.secure();
    final state = base64UrlEncode(
      List.generate(16, (_) => random.nextInt(256)),
    );
    final url = grant.getAuthorizationUrl(
      redirect,
      scopes: ['XboxLive.signin', 'offline_access'],
      state: state,
    );

    return url.replace(
      queryParameters: {
        ...url.queryParameters,
        'cobrandid': '8058f65d-ce06-4c30-9559-473c9275a65d',
        'prompt': 'select_account',
      },
    );
  }

  /// Starts the loopback server that receives the Microsoft redirect and
  /// returns the redirect URI to use. A port in [Constants.redirectUrl] is
  /// kept; without one, a free port is picked.
  static Future<Uri> startRedirectServer() async {
    await closeRedirectServer();

    final redirect = Uri.parse(Constants.redirectUrl);
    final server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      redirect.hasPort ? redirect.port : 0,
    );
    _redirectServer = server;

    return redirect.replace(port: server.port);
  }

  /// Waits for the Microsoft redirect, answers the browser with [page] and
  /// returns the redirect's query parameters.
  static Future<Map<String, String>> waitForRedirect(String page) async {
    final server = _redirectServer;
    if (server == null) throw StateError("Redirect server not started");

    await for (final request in server) {
      final params = request.uri.queryParameters;
      if (!params.containsKey('code') && !params.containsKey('error')) {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        continue;
      }

      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType = ContentType.html;
      request.response.write(page);
      await request.response.close();
      await closeRedirectServer();

      return params;
    }

    throw StateError("Redirect server closed");
  }

  static Future<void> closeRedirectServer() async {
    final server = _redirectServer;
    _redirectServer = null;
    await server?.close(force: true);
  }

  /// Downloads what the instance of [server] is missing to run on this
  /// system (libraries, natives and Java) and returns the Java executable.
  /// [onProgress] is only called while downloading.
  static Future<String> prepare(
    Map server, {
    void Function(PrepareStep step, double progress)? onProgress,
  }) async {
    final path = Settings.minecraftDirectory.path;
    final versionData = await MinecraftLauncherCore.loadVersionData(
      server['version'],
      path,
    );
    return _prepare(versionData, path, onProgress);
  }

  static Future<String> _prepare(
    Map versionData,
    String path,
    void Function(PrepareStep step, double progress)? onProgress,
  ) async {
    await LibraryManager.ensureLibraries(
      versionData,
      Directory(path),
      onProgress: (p) => onProgress?.call(PrepareStep.libraries, p),
    );

    final supportDirectory = await getApplicationSupportDirectory();
    return JavaManager.ensureRuntime(
      versionData,
      Directory(join(supportDirectory.path, "runtime")),
      onProgress: (p) => onProgress?.call(PrepareStep.java, p),
    );
  }

  /// [onPrepareProgress] reports the downloads of [prepare], when needed.
  /// [onStartFailed] is called if the game exits before writing anything,
  /// which means it never started.
  static Future<void> launch(
    Map server, {
    bool close = true,
    VoidCallback? onStartFailed,
    void Function(PrepareStep step, double progress)? onPrepareProgress,
  }) async {
    final path = Settings.minecraftDirectory.path;
    final versionData = await MinecraftLauncherCore.loadVersionData(
      server['version'],
      path,
    );
    final java = await _prepare(versionData, path, onPrepareProgress);

    final token = await Minecraft.getToken();
    profile.value ??= await getCurrentProfile(token);

    Map options = {
      'username': profile.value!.name,
      'uuid': profile.value!.uuid,
      'token': token,
      'executablePath': java,
      'jvmArguments': ["-Xmx${Settings.allocatedRAM}G"],
      if (Settings.autoConnect && server['ip'] != null)
        'quickPlayMultiplayer': server['ip'],
      if (!Settings.fullscreen) 'resolutionWidth': "${Settings.gameWidth}",
      if (!Settings.fullscreen) 'resolutionHeight': "${Settings.gameHeight}",
    };

    List<String> cmd = await MinecraftLauncherCore.getMinecraftCommand(
      versionData,
      path,
      options,
    );

    final process = await Process.start(
      cmd[0],
      cmd.sublist(1),
      workingDirectory: path,
      mode: ProcessStartMode.detachedWithStdio,
    );

    var started = false;
    process.stderr.drain<void>();
    process.stdout.listen(
      (_) {
        started = true;
        if (close) exit(0);
      },
      onDone: () {
        if (!started) onStartFailed?.call();
      },
    );
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
