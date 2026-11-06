enum ApiErrorType {
  /// No network, a timeout or a server that can't be reached.
  offline,

  /// The server answered with a 5xx.
  serverUnavailable,

  /// No token, or an invalid or expired one: sign in again.
  unauthenticated,

  /// The player isn't a member of the organization (or is banned; the API
  /// doesn't tell them apart).
  notMember,

  /// The instance doesn't exist or the player can't see it.
  notFound,

  /// The API version is no longer supported: negotiate it again.
  upgradeRequired,

  /// The server and the launcher share no API version.
  incompatible,

  /// The response doesn't match what the launcher expects.
  invalidResponse,

  /// Any other API error; see [ApiError.code].
  other,
}

/// An error talking to an organization's server. The UI turns [type] (or
/// [code] for [ApiErrorType.other]) into a message.
class ApiError implements Exception {
  final ApiErrorType type;

  /// The stable `code` of the API's problem document, when there is one
  /// (e.g. `invalid_challenge`, `not_joined`, `url_expired`).
  final String? code;
  final int? status;

  const ApiError(this.type, {this.code, this.status});

  @override
  String toString() => "ApiError(${type.name}, code: $code, status: $status)";
}
