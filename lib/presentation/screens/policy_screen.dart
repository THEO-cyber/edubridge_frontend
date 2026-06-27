import 'package:flutter/material.dart';

const _kNavy = Color(0xFF1A237E);

enum PolicyType { privacy, terms }

class PolicyScreen extends StatelessWidget {
  final PolicyType type;
  const PolicyScreen({super.key, required this.type});

  bool get _isPrivacy => type == PolicyType.privacy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(_isPrivacy ? 'Privacy Policy' : 'Terms of Service'),
        backgroundColor: _kNavy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _Header(
            icon: _isPrivacy
                ? Icons.privacy_tip_rounded
                : Icons.gavel_rounded,
            title: _isPrivacy ? 'Privacy Policy' : 'Terms of Service',
            updated: 'Last updated: June 1, 2025',
          ),
          const SizedBox(height: 20),
          if (_isPrivacy) ..._privacySections() else ..._termsSections(),
          const SizedBox(height: 32),
          _ContactBox(isPrivacy: _isPrivacy),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  List<Widget> _privacySections() => [
        _PolicySection(
          title: '1. Information We Collect',
          body:
              'We collect information you provide directly to us, such as when you create an account, enroll in a course, or contact us for support. This includes:\n\n'
              '• Name, email address, and password\n'
              '• Profile information such as photo, bio, and expertise\n'
              '• Payment information (processed securely by our payment provider)\n'
              '• Course progress, quiz results, and certificates earned\n'
              '• Messages and communications through the platform',
        ),
        _PolicySection(
          title: '2. How We Use Your Information',
          body:
              'We use the information we collect to:\n\n'
              '• Provide, maintain, and improve our platform\n'
              '• Process transactions and send related information\n'
              '• Send notifications about your courses, sessions, and activity\n'
              '• Respond to your comments and questions\n'
              '• Monitor and analyze usage patterns to improve user experience\n'
              '• Detect and prevent fraudulent transactions and abuse',
        ),
        _PolicySection(
          title: '3. Information Sharing',
          body:
              'We do not sell or rent your personal information to third parties. We may share your information only in the following circumstances:\n\n'
              '• With instructors of courses you enroll in (limited to your name and progress)\n'
              '• With payment processors to complete transactions\n'
              '• When required by law or to protect our legal rights\n'
              '• With your explicit consent',
        ),
        _PolicySection(
          title: '4. Data Security',
          body:
              'We take the security of your data seriously. We use industry-standard encryption (TLS) for all data in transit and follow best practices for data storage. Passwords are hashed and never stored in plain text.\n\n'
              'While we strive to protect your information, no security system is impenetrable. We encourage you to use a strong, unique password and enable Two-Factor Authentication in your settings.',
        ),
        _PolicySection(
          title: '5. Cookies & Tracking',
          body:
              'We use cookies and similar tracking technologies to maintain your session and remember your preferences. You can control cookie settings through your device or browser, though disabling cookies may affect platform functionality.',
        ),
        _PolicySection(
          title: '6. Your Rights',
          body:
              'You have the right to:\n\n'
              '• Access the personal data we hold about you\n'
              '• Request correction of inaccurate data\n'
              '• Request deletion of your account and associated data\n'
              '• Opt out of marketing communications at any time\n'
              '• Export your data in a portable format\n\n'
              'To exercise any of these rights, contact us at privacy@edubridge.app.',
        ),
        _PolicySection(
          title: '7. Children\'s Privacy',
          body:
              'EduBridge is not directed at children under 13. We do not knowingly collect personal information from children under 13. If you believe a child has provided us with their information, please contact us immediately.',
        ),
        _PolicySection(
          title: '8. Changes to This Policy',
          body:
              'We may update this Privacy Policy from time to time. We will notify you of significant changes by posting a notice on the platform or sending an email. Your continued use of EduBridge after changes constitutes acceptance of the updated policy.',
        ),
      ];

  List<Widget> _termsSections() => [
        _PolicySection(
          title: '1. Acceptance of Terms',
          body:
              'By accessing or using EduBridge, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the platform. These terms apply to all users, including students and instructors.',
        ),
        _PolicySection(
          title: '2. Account Responsibilities',
          body:
              'You are responsible for:\n\n'
              '• Maintaining the confidentiality of your account credentials\n'
              '• All activity that occurs under your account\n'
              '• Providing accurate and up-to-date information\n'
              '• Notifying us immediately of any unauthorized use of your account\n\n'
              'You may not share your account with others or use another user\'s account without permission.',
        ),
        _PolicySection(
          title: '3. Course Enrollment & Payments',
          body:
              'Free courses are available to all registered users at no cost. Paid courses require payment before access is granted. All payments are processed securely.\n\n'
              'Refunds may be requested within 7 days of purchase if less than 30% of the course has been completed. Refund requests are reviewed on a case-by-case basis.',
        ),
        _PolicySection(
          title: '4. Instructor Obligations',
          body:
              'Instructors using EduBridge agree to:\n\n'
              '• Provide accurate, high-quality, and original course content\n'
              '• Not infringe on the intellectual property rights of others\n'
              '• Respond to student questions and requests in a timely manner\n'
              '• Not engage in deceptive, misleading, or fraudulent practices\n'
              '• Comply with all applicable laws and regulations',
        ),
        _PolicySection(
          title: '5. Intellectual Property',
          body:
              'Course content created by instructors remains their intellectual property. By publishing on EduBridge, instructors grant us a non-exclusive license to host and display the content on the platform.\n\n'
              'The EduBridge platform, including its design, trademarks, and technology, is the exclusive property of EduBridge and may not be copied, modified, or distributed without written permission.',
        ),
        _PolicySection(
          title: '6. Prohibited Conduct',
          body:
              'Users may not:\n\n'
              '• Share course materials outside the platform without instructor permission\n'
              '• Harass, threaten, or abuse other users or instructors\n'
              '• Post spam, malware, or harmful content\n'
              '• Attempt to hack, reverse-engineer, or disrupt the platform\n'
              '• Use the platform for any unlawful purpose',
        ),
        _PolicySection(
          title: '7. Limitation of Liability',
          body:
              'EduBridge is provided "as is" without warranties of any kind. To the fullest extent permitted by law, EduBridge shall not be liable for any indirect, incidental, or consequential damages arising from your use of the platform.',
        ),
        _PolicySection(
          title: '8. Termination',
          body:
              'We reserve the right to suspend or terminate accounts that violate these terms, engage in fraudulent activity, or cause harm to other users. You may delete your account at any time through the Settings screen.',
        ),
        _PolicySection(
          title: '9. Changes to Terms',
          body:
              'We may modify these Terms of Service at any time. Continued use of EduBridge after changes are posted constitutes your acceptance. We will notify you of material changes via email or a prominent notice on the platform.',
        ),
      ];
}

class _Header extends StatelessWidget {
  final IconData icon;
  final String title;
  final String updated;

  const _Header(
      {required this.icon, required this.title, required this.updated});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kNavy, Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17)),
                const SizedBox(height: 4),
                Text(updated,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String body;

  const _PolicySection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding:
              const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
                color: _kNavy, shape: BoxShape.circle),
          ),
          title: Text(
            title,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: _kNavy),
          ),
          iconColor: _kNavy,
          collapsedIconColor: Colors.blueGrey,
          children: [
            Text(
              body,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.blueGrey.shade700,
                  height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactBox extends StatelessWidget {
  final bool isPrivacy;
  const _ContactBox({required this.isPrivacy});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EAF6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kNavy.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.mail_outline_rounded, color: _kNavy, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Questions or concerns?',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: _kNavy)),
                const SizedBox(height: 4),
                Text(
                  isPrivacy
                      ? 'Contact our privacy team at privacy@edubridge.app'
                      : 'Contact our support team at support@edubridge.app',
                  style: TextStyle(
                      fontSize: 12, color: Colors.blueGrey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
