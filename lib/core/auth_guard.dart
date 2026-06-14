import 'dart:convert';
import 'package:flutter/material.dart';
import 'secure_storage.dart';
import 'app_router.dart';

class AuthGuard {
  /// Decodes the stored JWT locally and returns true only if it exists and is
  /// not yet expired. No network call is made.
  static Future<bool> isTokenValid() async {
    final token = await SecureStorage.getToken();
    if (token == null || token.isEmpty) return false;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      String payload = parts[1]
          .replaceAll('-', '+')
          .replaceAll('_', '/');
      final remainder = payload.length % 4;
      if (remainder != 0) payload += '=' * (4 - remainder);
      final decoded = jsonDecode(utf8.decode(base64Decode(payload)));
      final exp = decoded['exp'];
      if (exp == null) return true; // token has no expiry — treat as valid
      final expiry = DateTime.fromMillisecondsSinceEpoch((exp as int) * 1000);
      return DateTime.now().isBefore(expiry);
    } catch (_) {
      return false; // malformed token — treat as invalid
    }
  }

  /// Call when a 401 is received from any API call.
  /// Clears all stored credentials and sends the user back to the login screen.
  static Future<void> handleUnauthorized() async {
    await SecureStorage.deleteAllTokens();
    await SecureStorage.clearRole();
    final nav = AppRouter.navigatorKey.currentState;
    if (nav == null) return;
    nav.pushNamedAndRemoveUntil('/user-login', (_) => false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = AppRouter.navigatorKey.currentContext;
      if (ctx == null) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('Your session has expired. Please log in again.'),
          backgroundColor: Color(0xFF1A237E),
          duration: Duration(seconds: 4),
        ),
      );
    });
  }
}
