import 'dart:io';

import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:dart_minecraft/dart_minecraft.dart';
import 'package:oauth2/oauth2.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Minecraft {
  static Profile? profile;

  static late HttpServer _redirectServer;
  static late Credentials _credentials;

  static const String _authorizationEndpoint =
      "https://login.live.com/oauth20_authorize.srf";
  static const String _tokenEndpoint =
      "https://login.live.com/oauth20_token.srf";

  static authenticateOauth2() async {
    final preferences = await SharedPreferences.getInstance();
    final credentialsJson = preferences.getString("credentials") ?? "";

    Credentials credentials;
    if (credentialsJson.isNotEmpty) {
      try {
        credentials = Credentials.fromJson(credentialsJson);
        credentials = await credentials.refresh(identifier: Constants.clientID);
      } catch (e) {
        await preferences.remove("credentials");
        return await authenticateOauth2();
      }
    } else {
      credentials = await Minecraft._microsoftCredentials();
      await preferences.setString("credentials", credentials.toJson());
    }

    _credentials = credentials;
    profile = await getCurrentProfile(await getToken());
  }

  static Future<String> getToken() async {
    if (_credentials.isExpired) await authenticateOauth2();

    final xbl = await authenticateXBL(_credentials.accessToken);
    final xsts = await authenticateXSTS(xbl.first);
    return await authenticateWithXBOX(xsts.first, xsts.second);
  }

  static Future<Credentials> _microsoftCredentials() async {
    _redirectServer = await HttpServer.bind('127.0.0.1', 5020);

    AuthorizationCodeGrant grant = AuthorizationCodeGrant(
      Constants.clientID,
      Uri.parse(_authorizationEndpoint),
      Uri.parse(_tokenEndpoint),
      httpClient: _JsonAcceptingHttpClient(),
    );

    Uri authorizationUrl = grant.getAuthorizationUrl(
      Uri.parse(Constants.redirectUrl),
      scopes: ['XboxLive.signin', 'offline_access'],
    );

    Utility.showLoging(authorizationUrl);

    final responseQueryParameters = await _listenParameters();
    var client = await grant.handleAuthorizationResponse(
      responseQueryParameters,
    );

    return client.credentials;
  }

  static Future<Map<String, String>> _listenParameters() async {
    final request = await _redirectServer.first;
    final params = request.uri.queryParameters;
    request.response.statusCode = 200;
    request.response.headers.set('content-type', 'text/plain; charset=utf-8');
    request.response.writeln("Loging complete, you can now close this window");
    await request.response.close();
    await _redirectServer.close();

    return params;
  }

  static Future<void> launch() async {
    return;
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
