import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

const kApiTimeout = Duration(seconds: 12);

/// Wraps an http.get with a 12-second timeout and friendly error conversion.
Future<http.Response> apiGet(Uri url, {Map<String, String>? headers}) =>
    http.get(url, headers: headers).timeout(kApiTimeout);

/// Wraps an http.post with a 12-second timeout.
Future<http.Response> apiPost(Uri url,
        {Map<String, String>? headers, Object? body}) =>
    http.post(url, headers: headers, body: body).timeout(kApiTimeout);

/// Wraps an http.patch with a 12-second timeout.
Future<http.Response> apiPatch(Uri url,
        {Map<String, String>? headers, Object? body}) =>
    http.patch(url, headers: headers, body: body).timeout(kApiTimeout);

/// Wraps an http.delete with a 12-second timeout.
Future<http.Response> apiDelete(Uri url, {Map<String, String>? headers}) =>
    http.delete(url, headers: headers).timeout(kApiTimeout);

/// Converts a low-level network exception to a readable message.
String networkErrorMessage(Object e) {
  if (e is TimeoutException) {
    return 'Connection timed out. Make sure your device is on the same network as the server.';
  }
  if (e is SocketException) {
    return 'Cannot reach server. Check your network connection.';
  }
  return e.toString().replaceFirst('Exception: ', '');
}
