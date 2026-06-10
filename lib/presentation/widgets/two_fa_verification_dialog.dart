import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../constants/api_constants.dart';
import '../../core/secure_storage.dart';

Future<void> showTwoFAVerificationDialog({
  required BuildContext context,
  required String tempToken,
  required Future<void> Function(BuildContext ctx) onVerified,
}) async {
  final controllers = List.generate(6, (_) => TextEditingController());
  final focusNodes = List.generate(6, (_) => FocusNode());

  try {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setStateDialog) {
          Future<void> verify() async {
            final code = controllers.map((c) => c.text).join();
            if (code.length < 6) {
              setStateDialog(() {});
              return;
            }
            setStateDialog(() {});

            try {
              final requestBody = jsonEncode({'tempToken': tempToken, 'totpCode': code});
              print('---------- [2FA Dialog] URL: ${ApiConstants.baseUrl}${ApiConstants.twoFaVerify}');
              print('---------- [2FA Dialog] Request body: $requestBody');
              final res = await http.post(
                Uri.parse(ApiConstants.baseUrl + ApiConstants.twoFaVerify),
                headers: {'Content-Type': 'application/json'},
                body: requestBody,
              );
              print('---------- [2FA Dialog] Status: ${res.statusCode}');
              print('---------- [2FA Dialog] Response: ${res.body}');

              if (res.statusCode == 200 || res.statusCode == 201) {
                final body = jsonDecode(res.body);
                String? accessToken;
                if (body['accessToken'] is String) {
                  accessToken = body['accessToken'] as String;
                } else if (body['token'] is String) {
                  accessToken = body['token'] as String;
                } else if (body['data'] is Map) {
                  accessToken = (body['data']['accessToken'] ??
                          body['data']['token'])
                      ?.toString();
                }
                print('---------- [2FA Dialog] Extracted accessToken: $accessToken');

                if (accessToken != null && accessToken.isNotEmpty) {
                  await SecureStorage.saveToken(accessToken);
                  print('---------- [2FA Dialog] Token saved');
                  if (dialogCtx.mounted) Navigator.of(dialogCtx).pop(true);
                  if (context.mounted) await onVerified(context);
                } else {
                  if (dialogCtx.mounted) {
                    ScaffoldMessenger.of(dialogCtx).showSnackBar(
                      const SnackBar(
                          content: Text('Verified but no token in response')),
                    );
                  }
                }
              } else {
                String msg = 'Invalid code (${res.statusCode})';
                try {
                  final b = jsonDecode(res.body);
                  if (b is Map) {
                    final raw = b['message'] ?? b['error'];
                    if (raw is List) {
                      msg = raw.join(', ');
                    } else if (raw != null) {
                      msg = raw.toString();
                    }
                  }
                } catch (_) {}
                print('---------- [2FA Dialog] Error message shown: $msg');
                if (dialogCtx.mounted) {
                  ScaffoldMessenger.of(dialogCtx).showSnackBar(
                    SnackBar(
                      content: Text(msg),
                      duration: const Duration(seconds: 6),
                    ),
                  );
                }
                setStateDialog(() {
                  for (final c in controllers) c.clear();
                  focusNodes[0].requestFocus();
                });
              }
            } catch (e) {
              print('---------- [2FA Dialog] Exception: $e');
              if (dialogCtx.mounted) {
                ScaffoldMessenger.of(dialogCtx).showSnackBar(
                  const SnackBar(
                      content: Text('Network error. Check your connection.')),
                );
              }
            }
          }

          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            contentPadding:
                const EdgeInsets.fromLTRB(24, 0, 24, 24),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            title: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A237E), Color(0xFF1976D2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.security_rounded,
                      color: Colors.white, size: 32),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Two-Factor Authentication',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Enter the 6-digit code from your authenticator app',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.blueGrey.shade500,
                      fontWeight: FontWeight.normal),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (i) {
                    final filled = controllers[i].text.isNotEmpty;
                    return Container(
                      width: 40,
                      height: 48,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: filled
                            ? const Color(0xFF1A237E).withValues(alpha: 0.06)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: filled
                              ? const Color(0xFF1A237E)
                              : const Color(0xFFDDE1EF),
                          width: filled ? 2 : 1.5,
                        ),
                      ),
                      child: TextField(
                        controller: controllers[i],
                        focusNode: focusNodes[i],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        maxLength: 1,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                        ),
                        decoration: const InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                        ),
                        onChanged: (v) {
                          if (v.length > 1) {
                            final digits =
                                v.replaceAll(RegExp(r'\D'), '');
                            for (int j = 0;
                                j < 6 && j < digits.length;
                                j++) {
                              controllers[j].text = digits[j];
                            }
                            final next =
                                (digits.length < 6 ? digits.length : 5);
                            focusNodes[next].requestFocus();
                          } else if (v.isNotEmpty && i < 5) {
                            focusNodes[i + 1].requestFocus();
                          }
                          setStateDialog(() {});
                          if (controllers.every(
                              (c) => c.text.isNotEmpty)) {
                            verify();
                          }
                        },
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => verify(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Verify',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  } finally {
    for (final c in controllers) c.dispose();
    for (final n in focusNodes) n.dispose();
  }
}
