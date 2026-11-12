import 'dart:convert';

import 'package:bc_launcher/services/xbox_auth.dart';
import 'package:bc_launcher/utils/minecraft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  void answer(int status, Object body) {
    XboxAuth.client = MockClient(
      (_) async =>
          http.Response(body is String ? body : jsonEncode(body), status),
    );
  }

  test('gives the token and user hash', () async {
    answer(200, {
      'Token': 'xsts',
      'DisplayClaims': {
        'xui': [
          {'uhs': 'hash'},
        ],
      },
    });

    final xsts = await XboxAuth.xsts('xbl');
    expect(xsts.token, 'xsts');
    expect(xsts.userHash, 'hash');
  });

  test('sends the Xbox Live token for Minecraft', () async {
    late http.Request sent;
    XboxAuth.client = MockClient((request) async {
      sent = request;
      return http.Response(
        jsonEncode({
          'Token': 't',
          'DisplayClaims': {
            'xui': [
              {'uhs': 'h'},
            ],
          },
        }),
        200,
      );
    });

    await XboxAuth.xsts('xbl');
    final body = jsonDecode(sent.body);
    expect(sent.url.host, 'xsts.auth.xboxlive.com');
    expect(body['Properties']['UserTokens'], ['xbl']);
    expect(body['RelyingParty'], 'rp://api.minecraftservices.com/');
  });

  test('each XErr is the problem the player is told', () async {
    final expected = {
      2148916233: AccountProblem.noXbox,
      2148916235: AccountProblem.country,
      2148916236: AccountProblem.adultVerification,
      2148916237: AccountProblem.adultVerification,
      2148916238: AccountProblem.child,
    };
    for (final MapEntry(key: code, value: problem) in expected.entries) {
      answer(401, {'XErr': code, 'Message': ''});
      await expectLater(
        XboxAuth.xsts('xbl'),
        throwsA(
          isA<AccountError>().having((e) => e.problem, 'problem', problem),
        ),
      );
    }
  });

  test('a rejection without XErr asks to sign in again', () async {
    answer(401, {});
    await expectLater(
      XboxAuth.xsts('xbl'),
      throwsA(
        isA<AccountError>().having(
          (e) => e.problem,
          'problem',
          AccountProblem.expired,
        ),
      ),
    );
  });

  test('an answer that is not Xbox counts as no connection', () async {
    answer(503, '<html>down</html>');
    await expectLater(
      XboxAuth.xsts('xbl'),
      throwsA(predicate(Minecraft.isNetworkError)),
    );
  });
}
