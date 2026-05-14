import 'package:http/http.dart' as http;
import '../../core/secure_storage.dart';
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

    // If we get a 403 (Forbidden), try to refresh the token and retry once
    if (response.statusCode == 403) {
      try {
        await authRepository.refreshToken();
        // Retry the request with the new token
        final newToken = await SecureStorage.getToken();
        if (newToken != null) {
          // We need to modify the request to use the new token
          // This is tricky because we need to reconstruct the request
          // For now, let's throw an exception that indicates token refresh succeeded
          // but we need the caller to retry with the new token
          throw TokenRefreshedException(
            'Token refreshed, please retry the request',
          );
        }
      } catch (e) {
        if (e is TokenRefreshedException) {
          rethrow;
        }
        // If refresh failed, throw UnauthorizedException
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
