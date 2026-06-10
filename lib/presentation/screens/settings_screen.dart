import 'package:flutter/material.dart';

const _kNavy = Color(0xFF1A237E);
const _kBlue = Color(0xFF1976D2);

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: _kNavy,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionLabel('ACCOUNT'),
          const SizedBox(height: 8),
          _SettingsCard(
            items: [
              _SettingsTile(
                icon: Icons.lock_outline,
                label: 'Change Password',
                iconColor: _kNavy,
                onTap: () => Navigator.pushNamed(context, '/forgot-password'),
              ),
              _SettingsTile(
                icon: Icons.security_outlined,
                label: 'Two-Factor Auth',
                iconColor: _kBlue,
                onTap: () => Navigator.pushNamed(context, '/2fa-setup'),
              ),
              _SettingsTile(
                icon: Icons.email_outlined,
                label: 'Email Preferences',
                iconColor: _kNavy,
                isLast: true,
                onTap: () =>
                    Navigator.pushNamed(context, '/email-preferences'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionLabel('CONTENT'),
          const SizedBox(height: 8),
          _SettingsCard(
            items: [
              _SettingsTile(
                icon: Icons.note_alt_outlined,
                label: 'My Notes',
                iconColor: _kNavy,
                onTap: () => Navigator.pushNamed(context, '/my-notes'),
              ),
              _SettingsTile(
                icon: Icons.emoji_events_outlined,
                label: 'My Certificates',
                iconColor: _kBlue,
                isLast: true,
                onTap: () => Navigator.pushNamed(context, '/certificates'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionLabel('APP'),
          const SizedBox(height: 8),
          _SettingsCard(
            items: [
              _SettingsTile(
                icon: Icons.info_outline,
                label: 'About EduBridge',
                iconColor: _kNavy,
                onTap: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('About EduBridge'),
                      content: const Text(
                        'EduBridge v1.0.0 — Your gateway to quality education',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                label: 'Privacy Policy',
                iconColor: _kBlue,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening Privacy Policy...')),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.gavel_outlined,
                label: 'Terms of Service',
                iconColor: _kNavy,
                isLast: true,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Opening Terms of Service...')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 12,
        color: Colors.grey,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<_SettingsTile> items;
  const _SettingsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(children: items),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;
  final bool isLast;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: isLast
              ? const BorderRadius.vertical(bottom: Radius.circular(16))
              : BorderRadius.zero,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: Colors.grey, size: 20),
              ],
            ),
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 52),
      ],
    );
  }
}
