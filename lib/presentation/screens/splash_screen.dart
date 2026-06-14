import 'package:flutter/material.dart';
import '../../core/secure_storage.dart';
import '../../core/auth_guard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2400), () async {
      if (!mounted) return;
      final valid = await AuthGuard.isTokenValid();
      if (!mounted) return;
      if (!valid) {
        // Token missing or expired — clear stale credentials and go to login
        await SecureStorage.deleteAllTokens();
        await SecureStorage.clearRole();
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/user-login');
        return;
      }
      final role = (await SecureStorage.getRole() ?? '').toUpperCase();
      final String destination;
      if (role == 'INSTRUCTOR' || role == 'LECTURER') {
        destination = '/lecturer-dashboard';
      } else if (role == 'SUPER_ADMIN' || role == 'SUPERADMIN' || role == 'ADMIN') {
        destination = '/admin-dashboard';
      } else {
        destination = '/student-dashboard';
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(destination);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A237E),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo mark — circle with stylised "e"
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF64B5F6),
                      width: 3,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'e',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 50,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Word-mark: "edu" white + "Bridge" blue
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'edu',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 2,
                        ),
                      ),
                      TextSpan(
                        text: 'Bridge',
                        style: TextStyle(
                          color: Color(0xFF64B5F6),
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Learn anything, anywhere.',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 13,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
