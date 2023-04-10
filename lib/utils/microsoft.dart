import 'dart:convert';
import 'dart:io';

import 'package:launcher/models/minecraft_account.dart';
import 'package:launcher/utils/utility.dart';
import 'package:oauth2/oauth2.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:http/http.dart' as http;

const _authorizationEndpoint = "https://login.live.com/oauth20_authorize.srf";
const _tokenEndpoint = "https://login.live.com/oauth20_token.srf";

const String clientID = "f028f08c-f101-4c96-a985-5762481026d8";
const String redirectUrl = "http://127.0.0.1:5020/spartaland-auth";

late HttpServer _redirectServer;

class Microsoft {
  static Future<void> loginFromBrowser() async {
    Credentials credentials = await _microsoftCredentials();

    Map xboxLiveData = await _authorizationXBL(credentials.accessToken);
    String xblToken = xboxLiveData['Token'];
    String userHash = xboxLiveData['DisplayClaims']['xui'][0]['uhs'];

    String xstsToken = await _tokenXSTS(xblToken);
    String bearer = await _bearerToken(userHash, xstsToken);

    MinecraftAccount mcAccount = MinecraftAccount(xblToken, bearer);
    await mcAccount.loadProfile();

    Utility.selectedAccount = mcAccount;

    Utility.accounts.removeWhere((e) => e.uuid == mcAccount.uuid);
    Utility.accounts.insert(0, mcAccount);

    Utility.saveUsers();
  }

  static Future<void> loginUser(String username) async {
    try {
      MinecraftAccount mcAccount =
          Utility.accounts.firstWhere((e) => e.username == username);

      String xblToken = mcAccount.xblToken;

      Map xstsData = await _authorizationXSTS(xblToken);
      String xstsToken = xstsData['Token'];
      String userHash = xstsData['DisplayClaims']['xui'][0]['uhs'];

      String bearer = await _bearerToken(userHash, xstsToken);

      mcAccount.bearer = bearer;
      await mcAccount.loadProfile();

      Utility.selectedAccount = mcAccount;

      Utility.accounts.removeWhere((e) => e.uuid == mcAccount.uuid);
      Utility.accounts.insert(0, mcAccount);

      Utility.saveUsers();
    } catch (e) {
      await loginFromBrowser();
    }
  }

  static Future<String> minecraftBearer() async {
    Credentials credentials = await _microsoftCredentials();

    Map xboxLiveData = await _authorizationXBL(credentials.accessToken);
    String xblToken = xboxLiveData['Token'];
    String userHash = xboxLiveData['DisplayClaims']['xui'][0]['uhs'];

    String xstsToken = await _tokenXSTS(xblToken);

    return await _bearerToken(userHash, xstsToken);
  }

  static Future<Credentials> _microsoftCredentials() async {
    _redirectServer = await HttpServer.bind('127.0.0.1', 5020);

    AuthorizationCodeGrant grant = AuthorizationCodeGrant(
      clientID, //Client ID
      Uri.parse(_authorizationEndpoint),
      Uri.parse(_tokenEndpoint),
      httpClient: _JsonAcceptingHttpClient(),
    );
    Uri authorizationUrl = grant.getAuthorizationUrl(Uri.parse(redirectUrl),
        scopes: ['XboxLive.signin', 'offline_access']);
    await launchUrlString(
        "$authorizationUrl&cobrandid=8058f65d-ce06-4c30-9559-473c9275a65d&prompt=select_account");

    final responseQueryParameters = await _listenParameters();

    var client =
        await grant.handleAuthorizationResponse(responseQueryParameters);
    return client.credentials;
  }

  static Future<Map<String, String>> _listenParameters() async {
    final request = await _redirectServer.first;
    final params = request.uri.queryParameters;
    request.response.statusCode = 200;
    request.response.headers.set('content-type', 'text/plain; charset=utf-8');
    request.response
        .writeln("Inicio de sesión completado, puedes cerrar esta pestaña.");
    await request.response.close();
    await _redirectServer.close();

    return params;
  }

  static Future<Map> _authorizationXBL(String accessToken) async {
    final response = await http.post(
      Uri.parse("https://user.auth.xboxlive.com/user/authenticate"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: json.encode({
        'Properties': {
          'AuthMethod': 'RPS',
          'SiteName': 'user.auth.xboxlive.com',
          'RpsTicket': 'd=$accessToken'
        },
        'RelyingParty': 'http://auth.xboxlive.com',
        'TokenType': 'JWT'
      }),
    );

    return json.decode(response.body);
  }

  static Future<String> _tokenXSTS(String xblToken) async {
    final response = await http.post(
      Uri.parse("https://xsts.auth.xboxlive.com/xsts/authorize"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: json.encode({
        "Properties": {
          "SandboxId": "RETAIL",
          "UserTokens": [xblToken]
        },
        "RelyingParty": "rp://api.minecraftservices.com/",
        "TokenType": "JWT"
      }),
    );

    return json.decode(response.body)['Token'];
  }

  static Future<Map> _authorizationXSTS(String xblToken) async {
    final response = await http.post(
      Uri.parse("https://xsts.auth.xboxlive.com/xsts/authorize"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: json.encode({
        "Properties": {
          "SandboxId": "RETAIL",
          "UserTokens": [xblToken]
        },
        "RelyingParty": "rp://api.minecraftservices.com/",
        "TokenType": "JWT"
      }),
    );

    return json.decode(response.body);
  }

  static Future<String> _bearerToken(String userHash, String xstsToken) async {
    final response = await http.post(
      Uri.parse(
          "https://api.minecraftservices.com/authentication/login_with_xbox"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "identityToken": "XBL3.0 x=$userHash;$xstsToken",
        "ensureLegacyEnabled": true
      }),
    );

    return json.decode(response.body)['access_token'];
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
