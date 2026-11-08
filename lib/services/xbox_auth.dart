import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Why a Microsoft account can't play, as the player has to be told.
enum AccountProblem {
  noXbox,
  country,
  adultVerification,
  child,
  noMinecraft,
  expired,
}

class AccountError implements Exception {
  final AccountProblem problem;

  const AccountError(this.problem);

  @override
  String toString() => "AccountError(${problem.name})";
}

class XboxAuth {
  static const _timeout = Duration(seconds: 20);

  @visibleForTesting
  static http.Client client = http.Client();

  static Future<({String token, String userHash})> xsts(String xblToken) async {
    final response = await client
        .post(
          Uri.https('xsts.auth.xboxlive.com', '/xsts/authorize'),
          headers: {
            'content-type': 'application/json',
            'accept': 'application/json',
          },
          body: jsonEncode({
            'Properties': {
              'SandboxId': 'RETAIL',
              'UserTokens': [xblToken],
            },
            'RelyingParty': 'rp://api.minecraftservices.com/',
            'TokenType': 'JWT',
          }),
        )
        .timeout(_timeout);

    final Object? json;
    try {
      json = jsonDecode(response.body);
    } catch (_) {
      throw http.ClientException("XSTS answered ${response.statusCode}");
    }
    if (json is! Map<String, dynamic>) {
      throw http.ClientException("XSTS answered ${response.statusCode}");
    }

    final code = json['XErr'];
    if (code is int) throw AccountError(problemOf(code));
    if (response.statusCode == 401) {
      throw const AccountError(AccountProblem.expired);
    }

    final token = json['Token'];
    final claims = json['DisplayClaims']?['xui'];
    final userHash = claims is List && claims.isNotEmpty
        ? claims.first['uhs']
        : null;
    if (token is! String || userHash is! String) {
      throw http.ClientException("XSTS answered ${response.statusCode}");
    }
    return (token: token, userHash: userHash);
  }

  /// What an `XErr` code means for the player.
  static AccountProblem problemOf(int code) => switch (code) {
    2148916233 => AccountProblem.noXbox,
    2148916235 => AccountProblem.country,
    2148916236 || 2148916237 => AccountProblem.adultVerification,
    2148916238 => AccountProblem.child,
    _ => AccountProblem.expired,
  };
}
