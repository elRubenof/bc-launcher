import 'dart:convert';
import 'dart:developer';

import 'package:bc_launcher/models/instance.dart';
import 'package:bc_launcher/models/manifest.dart';
import 'package:bc_launcher/models/news.dart';
import 'package:bc_launcher/models/organization.dart';
import 'package:bc_launcher/services/api_error.dart';
import 'package:dio/dio.dart';

/// Talks to one organization's server. Returns models or throws [ApiError];
/// it never touches the UI.
class ApiClient {
  /// API versions this launcher speaks; the highest one shared is used.
  static const supportedApiVersions = [1];

  final Organization organization;

  /// The organization token, or `null` when there is none yet.
  final Future<String?> Function() getToken;

  /// Called on `401`: signs in again and returns the new token, or `null`.
  final Future<String?> Function()? renewToken;

  final Dio _dio;

  ApiClient(
    this.organization, {
    required this.getToken,
    this.renewToken,
    Dio? dio,
  }) : _dio = dio ?? _newDio() {
    _dio.options
      ..baseUrl = "${organization.url}/api/v${organization.apiVersion}"
      ..validateStatus = (_) => true;
  }

  /// Reads the discovery document at [url] (`https://` is added when
  /// missing) and negotiates the API version.
  static Future<Organization> discovery(String url, {Dio? dio}) async {
    final origin = normalizeUrl(url);
    final client = (dio ?? _newDio())..options.validateStatus = (_) => true;
    final response = await _retry(
      () => _fetch(client, "GET", "$origin/.well-known/bc-launcher"),
    );

    return _read(response, (json) {
      final shared = List<int>.from(json['apiVersions'])
          .where(supportedApiVersions.contains)
          .toList();
      if (json['discoveryVersion'] != 1 || shared.isEmpty) {
        throw const ApiError(ApiErrorType.incompatible);
      }

      return Organization.fromDiscovery(
        json,
        url: origin,
        apiVersion: shared.reduce((a, b) => a > b ? a : b),
      );
    });
  }

  static String normalizeUrl(String url) {
    var value = url.trim();
    if (!value.contains("://")) value = "https://$value";
    while (value.endsWith("/")) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }

  /// The `serverId` for Mojang's `join`.
  Future<String> challenge() => _call(
    "POST",
    "/auth/challenge",
    auth: false,
    (json) => json['serverId'] as String,
  );

  /// The organization token, after Mojang's `join` with [serverId].
  Future<({String token, DateTime expiresAt})> verify({
    required String username,
    required String serverId,
  }) => _call(
    "POST",
    "/auth/verify",
    auth: false,
    data: {'username': username, 'serverId': serverId},
    (json) => (
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expiresAt']),
    ),
  );

  Future<List<Instance>> instances() => _call(
    "GET",
    "/instances",
    (json) => _list(json['instances'], Instance.fromJson),
  );

  /// With the [etag] of the last manifest, `null` when nothing changed.
  Future<({Manifest manifest, String? etag})?> manifest(
    String instanceId, {
    String? etag,
  }) async {
    final response = await _send(
      "GET",
      "/instances/${Uri.encodeComponent(instanceId)}/manifest",
      headers: {'If-None-Match': ?etag},
    );
    if (response.statusCode == 304) return null;

    return _read(
      response,
      (json) => (
        manifest: Manifest.fromJson(json),
        etag: response.headers.value('etag'),
      ),
    );
  }

  /// One page of news; pass [cursor] for the next one.
  Future<({List<News> items, String? nextCursor})> news(
    String instanceId, {
    String? cursor,
  }) => _call(
    "GET",
    "/instances/${Uri.encodeComponent(instanceId)}/news",
    query: {'cursor': ?cursor},
    (json) => (
      items: _list(json['items'], News.fromJson),
      nextCursor: json['nextCursor'] as String?,
    ),
  );

  Future<T> _call<T>(
    String method,
    String path,
    T Function(Map<String, dynamic> json) parse, {
    bool auth = true,
    Object? data,
    Map<String, dynamic>? query,
  }) async {
    final response = await _send(
      method,
      path,
      auth: auth,
      data: data,
      query: query,
    );
    return _read(response, parse);
  }

  /// Sends with the token, retrying network and server failures (GET only)
  /// and signing in again once on `401`.
  Future<Response> _send(
    String method,
    String path, {
    bool auth = true,
    Object? data,
    Map<String, dynamic>? query,
    Map<String, String> headers = const {},
  }) async {
    Future<Response> attempt(String? token) {
      Future<Response> fetch() => _fetch(
        _dio,
        method,
        path,
        data: data,
        query: query,
        headers: {
          ...headers,
          if (token != null) 'Authorization': "Bearer $token",
        },
      );
      return method == "GET" ? _retry(fetch) : fetch();
    }

    final token = auth ? await getToken() : null;
    try {
      return await attempt(token);
    } on ApiError catch (e) {
      if (!auth || e.type != ApiErrorType.unauthenticated) rethrow;

      final renewed = await renewToken?.call();
      if (renewed == null) rethrow;
      return attempt(renewed);
    }
  }

  /// One request. Anything but 2xx or `304` becomes an [ApiError].
  static Future<Response> _fetch(
    Dio dio,
    String method,
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    Map<String, String> headers = const {},
  }) async {
    final Response response;
    try {
      response = await dio.request(
        path,
        data: data,
        queryParameters: query,
        options: Options(method: method, headers: headers),
      );
    } on DioException catch (e) {
      log("API request failed: ${e.type.name}");
      throw const ApiError(ApiErrorType.offline);
    }

    final status = response.statusCode ?? 0;
    if (status < 300 || status == 304) return response;

    final body = _json(response.data);
    final code = body?['code'] is String ? body!['code'] as String : null;
    throw ApiError(
      switch (status) {
        401 => ApiErrorType.unauthenticated,
        403 when code == 'not_member' => ApiErrorType.notMember,
        404 => ApiErrorType.notFound,
        426 => ApiErrorType.upgradeRequired,
        >= 500 => ApiErrorType.serverUnavailable,
        _ => ApiErrorType.other,
      },
      code: code,
      status: status,
    );
  }

  /// Retries [send] up to twice on network and server failures.
  static Future<Response> _retry(Future<Response> Function() send) async {
    for (var attempt = 0; ; attempt++) {
      try {
        return await send();
      } on ApiError catch (e) {
        final transient =
            e.type == ApiErrorType.offline ||
            e.type == ApiErrorType.serverUnavailable;
        if (!transient || attempt >= 2) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      }
    }
  }

  /// Parses the body; anything that doesn't fit is an invalid response.
  static T _read<T>(
    Response response,
    T Function(Map<String, dynamic> json) parse,
  ) {
    try {
      return parse(_json(response.data)!);
    } on ApiError {
      rethrow;
    } catch (e) {
      log("Invalid response from ${response.requestOptions.path}: $e");
      throw const ApiError(ApiErrorType.invalidResponse);
    }
  }

  /// Reads each item on its own, so one unreadable item doesn't hide the rest.
  static List<T> _list<T>(
    Object? items,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final result = <T>[];
    for (final item in items as List) {
      try {
        result.add(fromJson(item as Map<String, dynamic>));
      } catch (e) {
        log("Skipping an invalid item: $e");
      }
    }
    return result;
  }

  static Map<String, dynamic>? _json(Object? data) {
    try {
      return (data is String ? jsonDecode(data) : data)
          as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  static Dio _newDio() => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
}
