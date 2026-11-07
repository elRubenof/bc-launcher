import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:bc_launcher/models/instance.dart';
import 'package:bc_launcher/models/instance_settings.dart';
import 'package:bc_launcher/services/credentials_store.dart';
import 'package:bc_launcher/services/minecraft_session_store.dart';
import 'package:bc_launcher/services/game_process.dart';
import 'package:bc_launcher/services/java_manager.dart';
import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/launch_utils/minecraft_launcher_core.dart';
import 'package:bc_launcher/utils/system_memory.dart';
import 'package:dart_minecraft/dart_minecraft.dart';
import 'package:flutter/material.dart';
import 'package:oauth2/oauth2.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// How starting the launcher went with the saved Microsoft account.
enum SignIn {
  signedIn,

  /// No internet: the saved profile and token are used.
  offline,

  /// No saved account, or Microsoft rejected it: the login is shown.
  signedOut,
}

class Minecraft {
  static ValueNotifier<Profile?> profile = ValueNotifier(null);

  /// There is no internet (Microsoft can't be reached): the saved session
  /// is used and the game is played without servers. It is retried every
  /// [_reconnectInterval] until it answers.
  static final offline = ValueNotifier<bool>(false);

  static HttpServer? _redirectServer;
  static late Credentials _credentials;
  static MinecraftSession? _session;
  static Timer? _reconnect;

  static const _timeout = Duration(seconds: 20);
  static const _reconnectInterval = Duration(seconds: 30);

  static const String _authorizationEndpoint =
      "https://login.live.com/oauth20_authorize.srf";
  static const String _tokenEndpoint =
      "https://login.live.com/oauth20_token.srf";

  /// Signs in with the saved account; without internet, with its saved
  /// profile and token.
  static Future<SignIn> authenticateOauth2() async {
    final credentialsJson = await CredentialsStore.read();
    if (credentialsJson == null) return SignIn.signedOut;
    _session = await MinecraftSessionStore.read();

    try {
      _credentials = Credentials.fromJson(credentialsJson);
      await _renew();
      _setOnline();
      return SignIn.signedIn;
    } catch (e) {
      final session = _session;
      if (isNetworkError(e) && session != null) {
        profile.value = Profile.fromJson({
          'id': session.uuid,
          'name': session.name,
        });
        _setOffline();
        return SignIn.offline;
      }

      final supportDirectory = await getApplicationSupportDirectory();
      File file = File(join(supportDirectory.path, "error.txt"));
      await file.writeAsString(e.toString());

      return SignIn.signedOut;
    }
  }

  /// Renews the Microsoft credentials and the Minecraft token, and saves
  /// them with the profile.
  static Future<void> _renew() async {
    _credentials = await _credentials
        .refresh(identifier: Constants.clientID)
        .timeout(_timeout);
    // Microsoft rotates the refresh token, so keep the new one.
    await CredentialsStore.write(_credentials.toJson());

    final token = await _minecraftToken();
    profile.value = await getCurrentProfile(token).timeout(_timeout);
    await _saveSession(token);
  }

  static Future<void> _saveSession(String token) async {
    final current = profile.value;
    if (current == null) return;
    final session = MinecraftSession.fresh(
      uuid: current.uuid,
      name: current.name,
      token: token,
    );
    _session = session;
    await MinecraftSessionStore.write(session);
  }

  static logout() async {
    _stopReconnecting();
    offline.value = false;
    _session = null;
    await CredentialsStore.clear();
    await MinecraftSessionStore.clear();
  }

  /// The Minecraft token: the saved one while it is valid, a new one
  /// otherwise. Without internet, the saved one even if it expired (enough
  /// for a single player game).
  static Future<String> getToken() async {
    final session = _session;
    if (session != null && !session.isExpired) return session.token;

    try {
      if (_credentials.isExpired) {
        _credentials = await _credentials
            .refresh(identifier: Constants.clientID)
            .timeout(_timeout);
        await CredentialsStore.write(_credentials.toJson());
      }
      final token = await _minecraftToken();
      profile.value ??= await getCurrentProfile(token).timeout(_timeout);
      await _saveSession(token);
      _setOnline();
      return token;
    } catch (e) {
      if (!isNetworkError(e) || session == null) rethrow;
      _setOffline();
      return session.token;
    }
  }

  static Future<String> _minecraftToken() async {
    final xbl = await authenticateXBL(_credentials.accessToken)
        .timeout(_timeout);
    final xsts = await authenticateXSTS(xbl.first).timeout(_timeout);
    return await authenticateWithXBOX(
      xsts.first,
      xsts.second,
    ).timeout(_timeout);
  }

  /// No connection at all, as opposed to Microsoft or Xbox rejecting the
  /// account.
  static bool isNetworkError(Object error) =>
      error is SocketException ||
      error is http.ClientException ||
      error is TimeoutException ||
      error is HandshakeException ||
      error is HttpException;

  static void _setOffline() {
    offline.value = true;
    _reconnect ??= Timer.periodic(_reconnectInterval, (_) => _tryReconnect());
  }

  static void _setOnline() {
    _stopReconnecting();
    offline.value = false;
  }

  static void _stopReconnecting() {
    _reconnect?.cancel();
    _reconnect = null;
  }

  static bool _reconnecting = false;

  static Future<void> _tryReconnect() async {
    if (_reconnecting) return;
    _reconnecting = true;
    try {
      await _renew();
      _setOnline();
    } catch (e) {
      // Still without internet: try again later. A rejected account is
      // signed in again on the next start.
      if (!isNetworkError(e)) _stopReconnecting();
    } finally {
      _reconnecting = false;
    }
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

  /// Plays [versionId] of an installed instance in [folder], with the
  /// libraries and assets shared in [sharedFolder], until the game closes.
  /// [onStarted] is called once the game is running.
  static Future<GameExit> launch(
    Instance instance,
    Directory folder,
    String versionId,
    Directory sharedFolder,
    InstanceSettings settings, {
    VoidCallback? onStarted,
  }) async {
    final path = folder.path;
    final versionData = await MinecraftLauncherCore.loadVersionData(
      versionId,
      path,
    );
    final java = await JavaManager.ensureRuntime(
      versionData,
      Directory(join(sharedFolder.path, "runtime")),
    );

    final token = await Minecraft.getToken();
    profile.value ??= await getCurrentProfile(token);

    Map options = {
      'username': profile.value!.name,
      'uuid': profile.value!.uuid,
      'token': token,
      'executablePath': java,
      'jvmArguments': [
        "-Xmx${settings.ram(instance, await SystemMemory.totalGb())}G",
      ],
      'sharedRoot': sharedFolder.path,
      // Without internet there are no servers to join.
      if (settings.connects && !offline.value && instance.serverAddress != null)
        ...MinecraftLauncherCore.serverOptions(
          versionData,
          instance.serverAddress!,
        ),
      if (settings.isFullscreen)
        'fullscreen': true
      else ...{
        'customResolution': true,
        'resolutionWidth': "${settings.width}",
        'resolutionHeight': "${settings.height}",
      },
    };

    List<String> cmd = await MinecraftLauncherCore.getMinecraftCommand(
      versionData,
      path,
      options,
    );

    return GameProcess.run(cmd, folder, secrets: [token], onStarted: onStarted);
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
