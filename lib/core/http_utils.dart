import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'secure_storage.dart';

const kApiTimeout = Duration(seconds: 12);

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
      final data = jsonDecode(refreshRes.body) as Map<String, dynamic>;
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

Future<http.Response> apiGet(Uri url, {Map<String, String>? headers}) =>
    _withRefresh((h) => http.get(url, headers: h).timeout(kApiTimeout), headers);

Future<http.Response> apiPost(Uri url,
        {Map<String, String>? headers, Object? body}) =>
    _withRefresh(
        (h) => http.post(url, headers: h, body: body).timeout(kApiTimeout),
        headers);

Future<http.Response> apiPatch(Uri url,
        {Map<String, String>? headers, Object? body}) =>
    _withRefresh(
        (h) => http.patch(url, headers: h, body: body).timeout(kApiTimeout),
        headers);

Future<http.Response> apiPut(Uri url,
        {Map<String, String>? headers, Object? body}) =>
    _withRefresh(
        (h) => http.put(url, headers: h, body: body).timeout(kApiTimeout),
        headers);

Future<http.Response> apiDelete(Uri url, {Map<String, String>? headers}) =>
    _withRefresh(
        (h) => http.delete(url, headers: h).timeout(kApiTimeout), headers);

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
