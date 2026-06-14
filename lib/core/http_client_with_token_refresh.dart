import 'package:http/http.dart' as http;
import '../../core/secure_storage.dart';
import '../../core/auth_guard.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../core/error_handling.dart';

class HttpClientWithTokenRefresh {
  final AuthRepository authRepository;

  HttpClientWithTokenRefresh(this.authRepository);

  Future<http.Response> get(String url, {Map<String, String>? headers}) async {
    return await _makeRequest(() => http.get(Uri.parse(url), headers: headers));
  }

  Future<http.Response> post(
    String url, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    return await _makeRequest(
      () => http.post(Uri.parse(url), headers: headers, body: body),
    );
  }

  Future<http.Response> patch(
    String url, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    return await _makeRequest(
      () => http.patch(Uri.parse(url), headers: headers, body: body),
    );
  }

  Future<http.Response> delete(
    String url, {
    Map<String, String>? headers,
  }) async {
    return await _makeRequest(
      () => http.delete(Uri.parse(url), headers: headers),
    );
  }

  Future<http.Response> _makeRequest(
    Future<http.Response> Function() request,
  ) async {
    final response = await request();

    // 401 — token is outright invalid/expired; redirect to login immediately
    if (response.statusCode == 401) {
      await AuthGuard.handleUnauthorized();
      throw UnauthorizedException('Session expired, please login again');
    }

    // 403 — try a token refresh once, then give up
    if (response.statusCode == 403) {
      try {
        await authRepository.refreshToken();
        final newToken = await SecureStorage.getToken();
        if (newToken != null) {
          throw TokenRefreshedException('Token refreshed, please retry the request');
        }
      } catch (e) {
        if (e is TokenRefreshedException) rethrow;
        // Refresh failed — session is dead, redirect to login
        await AuthGuard.handleUnauthorized();
        throw UnauthorizedException('Session expired, please login again');
      }
    }

    return response;
  }
}

class TokenRefreshedException implements Exception {
  final String message;
  TokenRefreshedException(this.message);

  @override
  String toString() => message;
}
