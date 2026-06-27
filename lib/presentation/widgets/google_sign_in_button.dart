import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/secure_storage.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../services/notification_service.dart';

// Shared Google Sign-In logic used by both student and instructor login screens.

final _googleSignIn = GoogleSignIn(
  serverClientId:
      '628312261906-e46lcmni7u0g5ed8l6befkao67oengkc.apps.googleusercontent.com',
  scopes: ['email', 'profile'],
);

/// Signs in with Google, sends the ID token to the backend, stores tokens,
/// and navigates to the appropriate dashboard.
Future<void> handleGoogleSignIn(BuildContext context) async {
  try {
    // Ensure a fresh sign-in dialog each time
    await _googleSignIn.signOut();
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return; // User cancelled

    final auth = await googleUser.authentication;
    final idToken = auth.idToken;
    if (idToken == null) throw Exception('Could not retrieve Google ID token');

    final result = await AuthRemoteDataSource().googleMobileLogin(idToken);

    // Extract tokens
    final accessToken = result['accessToken'] as String? ?? '';
    final refreshToken = result['refreshToken'] as String? ?? '';

    // Extract role — backend wraps in { user, accessToken, refreshToken }
    final userMap = result['user'];
    String role = '';
    if (userMap is Map) {
      role = (userMap['role'] ?? '').toString().toLowerCase();
    }
    if (role.isEmpty) role = 'student';

    await SecureStorage.saveToken(accessToken);
    await SecureStorage.saveRefreshToken(refreshToken);
    await SecureStorage.saveRole(role);

    if (accessToken.isNotEmpty) {
      NotificationService.registerToken(accessToken);
    }

    if (!context.mounted) return;
    final route =
        role == 'instructor' ? '/lecturer-dashboard' : '/student-dashboard';
    Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
  } on Exception catch (e) {
    final msg = e
        .toString()
        .replaceAll('Exception: ', '')
        .replaceAll('ApiException: ', '');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg.isNotEmpty ? msg : 'Google sign-in failed'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}

/// Reusable "Continue with Google" button widget.
class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({super.key});

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _loading
            ? null
            : () async {
                setState(() => _loading = true);
                await handleGoogleSignIn(context);
                if (mounted) setState(() => _loading = false);
              },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: Colors.grey.shade300, width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
        ),
        child: _loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.grey.shade600,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/icons/google.png',
                    width: 22,
                    height: 22,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.g_mobiledata_rounded,
                      size: 24,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Divider with centered "OR" label between sign-in options.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade300)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'OR',
              style: TextStyle(
                color: Colors.blueGrey.shade400,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade300)),
        ],
      ),
    );
  }
}
