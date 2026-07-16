import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'secure_storage.dart';

// 45s so the first request can survive a free-tier backend cold start
// (Render sleeps when idle and takes ~30-50s to wake). Warm requests are ~2-4s.
const kApiTimeout = Duration(seconds: 45);

/// The backend wraps every response in `{ success, data, timestamp }`.
/// This returns the inner `data` payload (or the value unchanged if there is
/// no envelope), so datasources can parse the real body regardless.
dynamic unwrapEnvelope(dynamic decoded) {
  if (decoded is Map &&
      decoded.containsKey('data') &&
      (decoded.containsKey('success') || decoded.containsKey('timestamp'))) {
    return decoded['data'];
  }
  return decoded;
}

/// Extracts a `List<Map>` from a decoded response body, transparently handling
/// the response envelope and common wrapper keys (courses, results, items…).
List<Map<String, dynamic>> extractListOf(dynamic decoded, List<String> keys) {
  final payload = unwrapEnvelope(decoded);
  if (payload is List) return List<Map<String, dynamic>>.from(payload);
  if (payload is Map) {
    for (final k in keys) {
      if (payload[k] is List) return List<Map<String, dynamic>>.from(payload[k]);
    }
  }
  return [];
}

/// Extracts a single `Map` object from a decoded body, unwrapping the envelope.
Map<String, dynamic> extractObject(dynamic decoded) {
  final payload = unwrapEnvelope(decoded);
  return payload is Map ? Map<String, dynamic>.from(payload) : <String, dynamic>{};
}

// ── Token-refresh interceptor ──────────────────────────────────────────────
//
// If any authenticated request returns 401, we attempt one token refresh and
// retry. If the refresh itself fails, tokens are cleared (forcing re-login).

Future<http.Response> _withRefresh(
  Future<http.Response> Function(Map<String, String>?) doRequest,
  Map<String, String>? headers,
) async {
  final response = await doRequest(headers);

  // Only intercept 401 on requests that carried a Bearer token.
  if (response.statusCode != 401 ||
      !(headers ?? {}).containsKey('Authorization')) {
    return response;
  }

  final storedRefresh = await SecureStorage.getRefreshToken();
  if (storedRefresh == null || storedRefresh.isEmpty) return response;

  try {
    final refreshRes = await http
        .post(
          Uri.parse(ApiConstants.baseUrl + ApiConstants.refresh),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refreshToken': storedRefresh}),
        )
        .timeout(kApiTimeout);

    if (refreshRes.statusCode == 200 || refreshRes.statusCode == 201) {
      final data = extractObject(jsonDecode(refreshRes.body));
      final newAccess = data['accessToken'] as String?;
      final newRefresh = data['refreshToken'] as String?;

      if (newAccess != null && newAccess.isNotEmpty) {
        await SecureStorage.saveToken(newAccess);
        if (newRefresh != null && newRefresh.isNotEmpty) {
          await SecureStorage.saveRefreshToken(newRefresh);
        }
        // Retry original request with fresh token.
        final retryHeaders = Map<String, String>.from(headers ?? {})
          ..['Authorization'] = 'Bearer $newAccess';
        return await doRequest(retryHeaders);
      }
    }
  } catch (_) {}

  // Refresh failed — wipe tokens so the app redirects to login next time.
  await SecureStorage.deleteAllTokens();
  return response;
}

// ── Public helpers ─────────────────────────────────────────────────────────

/// Rewrites a successful response so its body is the inner payload of the
/// backend's `{ success, data, timestamp }` envelope. This lets every
/// datasource parse `response.body` directly (e.g. `decoded['courses']`)
/// without worrying about the wrapper. No-op if there's no envelope.
http.Response _unwrapResponse(http.Response resp) {
  if (resp.statusCode >= 200 &&
      resp.statusCode < 300 &&
      resp.body.isNotEmpty) {
    try {
      final decoded = jsonDecode(resp.body);
      if (decoded is Map &&
          decoded['data'] != null &&
          (decoded.containsKey('success') || decoded.containsKey('timestamp'))) {
        return http.Response(
          jsonEncode(decoded['data']),
          resp.statusCode,
          headers: resp.headers,
          request: resp.request,
          reasonPhrase: resp.reasonPhrase,
        );
      }
    } catch (_) {/* not JSON — leave as-is */}
  }
  return resp;
}

Future<http.Response> apiGet(Uri url, {Map<String, String>? headers}) =>
    _withRefresh((h) => http.get(url, headers: h).timeout(kApiTimeout), headers)
        .then(_unwrapResponse);

Future<http.Response> apiPost(Uri url,
        {Map<String, String>? headers, Object? body}) =>
    _withRefresh(
            (h) => http.post(url, headers: h, body: body).timeout(kApiTimeout),
            headers)
        .then(_unwrapResponse);

Future<http.Response> apiPatch(Uri url,
        {Map<String, String>? headers, Object? body}) =>
    _withRefresh(
            (h) => http.patch(url, headers: h, body: body).timeout(kApiTimeout),
            headers)
        .then(_unwrapResponse);

Future<http.Response> apiPut(Uri url,
        {Map<String, String>? headers, Object? body}) =>
    _withRefresh(
            (h) => http.put(url, headers: h, body: body).timeout(kApiTimeout),
            headers)
        .then(_unwrapResponse);

Future<http.Response> apiDelete(Uri url, {Map<String, String>? headers}) =>
    _withRefresh(
            (h) => http.delete(url, headers: h).timeout(kApiTimeout), headers)
        .then(_unwrapResponse);

// ── Error helpers ──────────────────────────────────────────────────────────

String networkErrorMessage(Object e) {
  if (e is TimeoutException) {
    return 'Connection timed out. Make sure your device is on the same network as the server.';
  }
  if (e is SocketException) {
    return 'Cannot reach server. Check your network connection.';
  }
  return e.toString().replaceFirst('Exception: ', '');
}
