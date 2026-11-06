import 'dart:convert';
import 'dart:typed_data';

import 'package:bc_launcher/models/organization.dart';
import 'package:bc_launcher/services/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures.dart';

/// Answers every request with [answer] (`n` counts from 1) and keeps them.
class FakeServer implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions request, int n) answer;
  final requests = <RequestOptions>[];

  FakeServer(this.answer);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return answer(options, requests.length);
  }

  @override
  void close({bool force = false}) {}
}

/// Fails every request the way Dio does when there is no network.
class NoNetwork implements HttpClientAdapter {
  int attempts = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    attempts++;
    throw DioException.connectionError(
      requestOptions: options,
      reason: 'no network',
    );
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody json(
  int status,
  Object body, {
  Map<String, List<String>> headers = const {},
}) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    'content-type': [
      status < 400 ? 'application/json' : 'application/problem+json',
    ],
    ...headers,
  },
);

ResponseBody problem(int status, [String? code]) => json(status, {
  'type': 'about:blank',
  'title': 'Error',
  'status': status,
  'code': ?code,
});

Dio dioWith(HttpClientAdapter adapter) => Dio()..httpClientAdapter = adapter;

Matcher apiError(ApiErrorType type, {String? code}) => throwsA(
  isA<ApiError>()
      .having((e) => e.type, 'type', type)
      .having((e) => e.code, 'code', code),
);

void main() {
  final organization = Organization.fromDiscovery(
    fixture('discovery'),
    url: 'https://example.com',
    apiVersion: 1,
  );

  ApiClient client(
    HttpClientAdapter adapter, {
    String? token = 'token',
    Future<String?> Function()? renewToken,
  }) => ApiClient(
    organization,
    getToken: () async => token,
    renewToken: renewToken,
    dio: dioWith(adapter),
  );

  group('discovery', () {
    test('adds https://, drops the trailing slash and negotiates v1', () async {
      final server = FakeServer((_, _) => json(200, fixture('discovery')));
      final found = await ApiClient.discovery(
        'example.com/',
        dio: dioWith(server),
      );

      expect(
        server.requests.single.uri.toString(),
        'https://example.com/.well-known/bc-launcher',
      );
      expect(found.url, 'https://example.com');
      expect(found.apiVersion, 1);
      expect(found.name, 'Boludo´s Company');
    });

    test('keeps http:// when given', () {
      expect(
        ApiClient.normalizeUrl(' http://127.0.0.1:8787/ '),
        'http://127.0.0.1:8787',
      );
    });

    test('uses the highest shared version', () async {
      final discovery = fixture('discovery')..['apiVersions'] = [1, 2, 7];
      final found = await ApiClient.discovery(
        'example.com',
        dio: dioWith(FakeServer((_, _) => json(200, discovery))),
      );
      expect(found.apiVersion, 1);
    });

    test('no shared version is incompatible', () async {
      final discovery = fixture('discovery')..['apiVersions'] = [2];
      await expectLater(
        ApiClient.discovery(
          'example.com',
          dio: dioWith(FakeServer((_, _) => json(200, discovery))),
        ),
        apiError(ApiErrorType.incompatible),
      );
    });

    test('an unknown discovery format is incompatible', () async {
      final discovery = fixture('discovery')..['discoveryVersion'] = 2;
      await expectLater(
        ApiClient.discovery(
          'example.com',
          dio: dioWith(FakeServer((_, _) => json(200, discovery))),
        ),
        apiError(ApiErrorType.incompatible),
      );
    });

    test('something that is not a discovery document is invalid', () async {
      await expectLater(
        ApiClient.discovery(
          'example.com',
          dio: dioWith(
            FakeServer((_, _) => ResponseBody.fromString('<html>', 200)),
          ),
        ),
        apiError(ApiErrorType.invalidResponse),
      );
    });
  });

  group('requests', () {
    test('go to /api/v1 with the token', () async {
      final server = FakeServer((_, _) => json(200, fixture('instances')));
      final instances = await client(server).instances();

      expect(instances.map((i) => i.id), ['spartaland-3', 'cockwork']);
      final request = server.requests.single;
      expect(request.uri.toString(), 'https://example.com/api/v1/instances');
      expect(request.headers['Authorization'], 'Bearer token');
    });

    test('without a token, no Authorization header', () async {
      final server = FakeServer((_, _) => json(200, {'instances': []}));
      await client(server, token: null).instances();

      expect(server.requests.single.headers, isNot(contains('Authorization')));
    });

    test('sign-in requests never send the token', () async {
      final server = FakeServer((request, _) {
        return request.path.endsWith('challenge')
            ? json(200, {
                'serverId': 'abc',
                'expiresAt': '2026-11-06T10:05:00Z',
              })
            : json(200, {
                'token': 'new',
                'expiresAt': '2026-11-07T10:00:00Z',
                'player': {'uuid': 'u', 'name': 'n'},
              });
      });
      final api = client(server);

      expect(await api.challenge(), 'abc');
      final session = await api.verify(username: 'Nyxar', serverId: 'abc');

      expect(session.token, 'new');
      expect(session.expiresAt, DateTime.utc(2026, 11, 7, 10));
      expect(server.requests.last.data, {
        'username': 'Nyxar',
        'serverId': 'abc',
      });
      for (final request in server.requests) {
        expect(request.method, 'POST');
        expect(request.headers, isNot(contains('Authorization')));
      }
    });

    test('an instance that can not be read is left out', () async {
      final body = fixture('instances');
      (body['instances'] as List).add({'id': 'broken'});
      final instances = await client(FakeServer((_, _) => json(200, body)))
          .instances();

      expect(instances.map((i) => i.id), ['spartaland-3', 'cockwork']);
    });

    test('news pages through the cursor', () async {
      final server = FakeServer((_, _) => json(200, fixture('news')));
      final api = client(server);

      final first = await api.news('spartaland-3');
      await api.news('spartaland-3', cursor: 'cursor 2');

      expect(first.items.map((n) => n.id), ['n1', 'n2']);
      expect(first.nextCursor, 'cursor-2');
      expect(server.requests.first.uri.hasQuery, isFalse);
      expect(server.requests.last.uri.queryParameters, {'cursor': 'cursor 2'});
      expect(
        server.requests.last.uri.path,
        '/api/v1/instances/spartaland-3/news',
      );
    });
  });

  group('manifest', () {
    test('returns it with its ETag, and null on 304', () async {
      final server = FakeServer(
        (_, n) => n == 1
            ? json(
                200,
                fixture('manifest'),
                headers: {
                  'etag': ['"3.1"'],
                },
              )
            : ResponseBody.fromString('', 304),
      );
      final api = client(server);

      final first = await api.manifest('spartaland-3');
      expect(first!.manifest.files, hasLength(2));
      expect(first.etag, '"3.1"');
      expect(server.requests.first.headers, isNot(contains('If-None-Match')));

      expect(await api.manifest('spartaland-3', etag: first.etag), isNull);
      expect(server.requests.last.headers['If-None-Match'], '"3.1"');
    });
  });

  group('errors', () {
    final cases = {
      (401, 'unauthenticated'): ApiErrorType.unauthenticated,
      (403, 'not_member'): ApiErrorType.notMember,
      (404, 'not_found'): ApiErrorType.notFound,
      (426, null): ApiErrorType.upgradeRequired,
      (400, 'invalid_cursor'): ApiErrorType.other,
      (403, 'url_expired'): ApiErrorType.other,
    };
    for (final MapEntry(key: (status, code), value: type) in cases.entries) {
      test('$status ${code ?? ''} is ${type.name}', () async {
        await expectLater(
          client(FakeServer((_, _) => problem(status, code))).news('x'),
          apiError(type, code: code),
        );
      });
    }

    test('a body that does not fit the model is an invalid response', () async {
      await expectLater(
        client(FakeServer((_, _) => json(200, {'instances': 5}))).instances(),
        apiError(ApiErrorType.invalidResponse),
      );
    });
  });

  group('retries', () {
    test('GET retries a 5xx twice, then gives up', () async {
      final server = FakeServer((_, _) => problem(503));
      await expectLater(
        client(server).instances(),
        apiError(ApiErrorType.serverUnavailable),
      );
      expect(server.requests, hasLength(3));
    });

    test('GET succeeds when a retry works', () async {
      final server = FakeServer(
        (_, n) => n == 1 ? problem(502) : json(200, {'instances': []}),
      );
      expect(await client(server).instances(), isEmpty);
      expect(server.requests, hasLength(2));
    });

    test('no network is offline, after retrying', () async {
      final adapter = NoNetwork();
      await expectLater(
        client(adapter).instances(),
        apiError(ApiErrorType.offline),
      );
      expect(adapter.attempts, 3);
    });

    test('POST is never retried', () async {
      final server = FakeServer((_, _) => problem(503));
      await expectLater(
        client(server).challenge(),
        apiError(ApiErrorType.serverUnavailable),
      );
      expect(server.requests, hasLength(1));
    });

    test('4xx is never retried', () async {
      final server = FakeServer((_, _) => problem(404, 'not_found'));
      await expectLater(client(server).instances(), throwsA(isA<ApiError>()));
      expect(server.requests, hasLength(1));
    });
  });

  group('401', () {
    test('signs in again once and repeats the request', () async {
      final server = FakeServer(
        (_, n) => n == 1
            ? problem(401, 'unauthenticated')
            : json(200, {'instances': []}),
      );
      var renewals = 0;
      final api = client(
        server,
        token: 'old',
        renewToken: () async {
          renewals++;
          return 'new';
        },
      );

      expect(await api.instances(), isEmpty);
      expect(renewals, 1);
      expect(server.requests.map((r) => r.headers['Authorization']), [
        'Bearer old',
        'Bearer new',
      ]);
    });

    test('a second 401 is not renewed again', () async {
      final server = FakeServer((_, _) => problem(401, 'unauthenticated'));
      var renewals = 0;
      await expectLater(
        client(
          server,
          renewToken: () async {
            renewals++;
            return 'new';
          },
        ).instances(),
        apiError(ApiErrorType.unauthenticated, code: 'unauthenticated'),
      );
      expect(renewals, 1);
      expect(server.requests, hasLength(2));
    });

    test('without a way to renew, the 401 is the error', () async {
      final server = FakeServer((_, _) => problem(401, 'unauthenticated'));
      await expectLater(
        client(server).instances(),
        apiError(ApiErrorType.unauthenticated, code: 'unauthenticated'),
      );
      expect(server.requests, hasLength(1));
    });
  });

  group('426', () {
    test(
      'negotiates again and repeats the request with the new version',
      () async {
        final server = FakeServer(
          (request, _) => request.uri.path.startsWith('/api/v1/')
              ? problem(426)
              : json(200, {'instances': []}),
        );
        var renegotiations = 0;
        final api = ApiClient(
          organization,
          getToken: () async => 'token',
          renegotiate: () async {
            renegotiations++;
            return Organization.fromDiscovery(
              fixture('discovery')..['apiVersions'] = [2],
              url: 'https://example.com',
              apiVersion: 2,
            );
          },
          dio: dioWith(server),
        );

        expect(await api.instances(), isEmpty);
        expect(renegotiations, 1);
        expect(server.requests.map((r) => r.uri.path), [
          '/api/v1/instances',
          '/api/v2/instances',
        ]);
        expect(api.organization.apiVersion, 2);
      },
    );

    test('no shared version left is incompatible', () async {
      final api = ApiClient(
        organization,
        getToken: () async => 'token',
        renegotiate: () async =>
            throw const ApiError(ApiErrorType.incompatible),
        dio: dioWith(FakeServer((_, _) => problem(426))),
      );

      await expectLater(api.instances(), apiError(ApiErrorType.incompatible));
    });

    test('without a way to negotiate, the 426 is the error', () async {
      await expectLater(
        client(FakeServer((_, _) => problem(426))).instances(),
        apiError(ApiErrorType.upgradeRequired),
      );
    });
  });
}
