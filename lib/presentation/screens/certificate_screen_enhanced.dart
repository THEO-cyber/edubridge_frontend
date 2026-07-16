import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../constants/api_constants.dart';
import '../../core/secure_storage.dart';
import '../../domain/entities/certificate_entity.dart';
import '../blocs/certificate_bloc.dart';
import '../blocs/certificate_bloc_provider.dart';

// ── Brand colours ──────────────────────────────────────────────────────────────
// Kept in sync with the canonical certificate PDF (backend buildPdf) and the web
// CertificateCard: navy #0F172A, gold #F59E0B.
const _navy   = Color(0xFF0F172A);
const _gold   = Color(0xFFF59E0B);
const _goldLt = Color(0xFFFBBF24);
const _cream  = Color(0xFFF8FAFC);

/// Can be used two ways:
///  1. Wrap in CertificateBlocProvider and pass token directly.
///  2. Use CertificateScreenEnhanced.route() which wraps itself.
class CertificateScreenEnhanced extends StatefulWidget {
  final String? token;
  const CertificateScreenEnhanced({super.key, this.token});

  /// Self-contained route — fetches its own token and provides its own bloc.
  static Route<void> route() => MaterialPageRoute(
        builder: (_) => CertificateBlocProvider(
          child: const CertificateScreenEnhanced(),
        ),
      );

  @override
  State<CertificateScreenEnhanced> createState() =>
      _CertificateScreenEnhancedState();
}

class _CertificateScreenEnhancedState
    extends State<CertificateScreenEnhanced> {
  String _loggedInName = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final t = widget.token?.isNotEmpty == true
        ? widget.token!
        : (await SecureStorage.getToken() ?? '');

    String name = await SecureStorage.getUserName() ?? '';
    if (name.isEmpty && t.isNotEmpty) {
      name = await _fetchUserName(t);
      if (name.isNotEmpty) await SecureStorage.saveUserName(name);
    }

    if (mounted) {
      setState(() => _loggedInName = name);
      context.read<CertificateBloc>().add(LoadCertificatesEvent(t));
    }
  }

  Future<String> _fetchUserName(String token) async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.me}'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final body = res.body.isNotEmpty
            ? (jsonDecode(res.body) as Map<String, dynamic>)
            : <String, dynamic>{};
        final data = body['data'] is Map
            ? body['data'] as Map<String, dynamic>
            : body;
        final first = (data['firstName'] ?? data['first_name'] ?? '').toString().trim();
        final last  = (data['lastName']  ?? data['last_name']  ?? '').toString().trim();
        if (first.isNotEmpty || last.isNotEmpty) {
          return '$first $last'.trim();
        }
        final fallback = (data['name'] ?? data['username'] ?? '').toString().trim();
        return fallback;
      }
    } catch (_) {}
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Certificates',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<CertificateBloc, CertificateState>(
        builder: (context, state) {
          if (state is CertificateLoading) {
            return const Center(
                child: CircularProgressIndicator(color: _navy));
          }
          if (state is CertificateError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 56, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  Text(state.message,
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          if (state is CertificateLoaded) {
            if (state.certificates.isEmpty) return _buildEmpty();
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              itemCount: state.certificates.length,
              itemBuilder: (_, i) => _CertificateCard(
                    cert: state.certificates[i],
                    loggedInName: _loggedInName,
                  ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _navy.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.workspace_premium_rounded,
                    size: 52, color: _gold),
              ),
              const SizedBox(height: 20),
              const Text(
                'No Certificates Yet',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _navy),
              ),
              const SizedBox(height: 10),
              const Text(
                'Complete a course to earn your first\nprofessional certificate.',
                style: TextStyle(fontSize: 14, color: Colors.blueGrey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}

// ── Certificate card ──────────────────────────────────────────────────────────

class _CertificateCard extends StatefulWidget {
  final CertificateEntity cert;
  final String loggedInName;
  const _CertificateCard({required this.cert, this.loggedInName = ''});

  @override
  State<_CertificateCard> createState() => _CertificateCardState();
}

class _CertificateCardState extends State<_CertificateCard> {
  bool _downloading = false;
  bool _sharing = false;

  CertificateEntity get cert => widget.cert;

  String get _formattedDate =>
      DateFormat('d MMMM yyyy').format(cert.issuedAt);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openPreview(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: _navy.withValues(alpha: 0.18),
                blurRadius: 20,
                offset: const Offset(0, 8))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              // ── Banner preview ─────────────────────────────────────────────
              Container(
                height: 120,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(children: [
                  // Corner ornaments
                  Positioned(
                      top: 10, left: 10,
                      child: _corner()),
                  Positioned(
                      top: 10, right: 10,
                      child: Transform.rotate(
                          angle: 1.5708, child: _corner())),
                  Positioned(
                      bottom: 10, left: 10,
                      child: Transform.rotate(
                          angle: -1.5708, child: _corner())),
                  Positioned(
                      bottom: 10, right: 10,
                      child: Transform.rotate(
                          angle: 3.1416, child: _corner())),

                  // Gold borders
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: _gold.withValues(alpha: 0.5), width: 1.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),

                  // Content
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.workspace_premium_rounded,
                            color: _gold, size: 32),
                        const SizedBox(height: 6),
                        const Text(
                          'CERTIFICATE OF COMPLETION',
                          style: TextStyle(
                              color: _gold,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.5),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            cert.courseName.isNotEmpty
                                ? cert.courseName
                                : 'EduBridge Course',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                height: 1.3),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),

              // ── Details strip ──────────────────────────────────────────────
              Container(
                color: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    Row(children: [
                      Expanded(
                        child: _infoCol(
                          'ISSUED TO',
                          cert.studentName.isNotEmpty
                              ? cert.studentName
                              : 'Student',
                        ),
                      ),
                      Container(
                          width: 1, height: 36, color: const Color(0xFFE8E8E8)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _infoCol('DATE ISSUED', _formattedDate),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: Color(0xFFF0F0F0)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: _infoChip(Icons.tag_rounded,
                              '#${cert.certificateNumber}'),
                        ),
                        const SizedBox(width: 8),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          // Download button
                          _actionBtn(
                            icon: _downloading ? null : Icons.download_rounded,
                            label: 'Download',
                            loading: _downloading,
                            color: _navy,
                            onTap: _handleDownload,
                          ),
                          const SizedBox(width: 8),
                          // Share button
                          _actionBtn(
                            icon: _sharing ? null : Icons.share_rounded,
                            label: 'Share',
                            loading: _sharing,
                            color: _gold,
                            onTap: _handleShare,
                          ),
                        ]),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _corner() => SizedBox(
        width: 18,
        height: 18,
        child: CustomPaint(painter: _CornerPainter()),
      );

  Widget _infoCol(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 9,
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _navy),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      );

  Widget _infoChip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F2FB),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: Colors.blueGrey),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
      );

  Widget _actionBtn({
    required IconData? icon,
    required String label,
    required bool loading,
    required Color color,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: loading ? null : onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (loading)
              const SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            else
              Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ]),
        ),
      );

  void _openPreview(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _CertificatePreviewScreen(
        cert: cert,
        loggedInName: widget.loggedInName,
      ),
    ));
  }

  Future<void> _handleDownload() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      final bytes = await _getPdfBytes(cert, fallbackName: widget.loggedInName);
      final file = await _savePdfToDevice(bytes,
          certNumber: cert.certificateNumber, permanent: true);
      final result = await OpenFilex.open(file.path);
      if (mounted) {
        final opened = result.type == ResultType.done;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            Icon(
              opened ? Icons.check_circle_rounded : Icons.folder_open_rounded,
              color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                opened ? 'Certificate opened!' : 'Saved! Tap Open to view.',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ]),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 5),
          action: opened ? null : SnackBarAction(
            label: 'Open',
            textColor: Colors.white,
            onPressed: () => OpenFilex.open(file.path),
          ),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Download failed: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ));
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _handleShare() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final bytes = await _getPdfBytes(cert, fallbackName: widget.loggedInName);
      final file = await _savePdfToDevice(bytes,
          certNumber: cert.certificateNumber, permanent: false);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'My EduBridge Certificate — ${cert.courseName}',
        text: 'I completed "${cert.courseName}" on EduBridge! 🎓\nCertificate #${cert.certificateNumber}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Share failed: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }
}

// ── Full-screen certificate preview ───────────────────────────────────────────

class _CertificatePreviewScreen extends StatefulWidget {
  final CertificateEntity cert;
  final String loggedInName;
  const _CertificatePreviewScreen({required this.cert, this.loggedInName = ''});

  @override
  State<_CertificatePreviewScreen> createState() =>
      _CertificatePreviewScreenState();
}

class _CertificatePreviewScreenState
    extends State<_CertificatePreviewScreen> {
  bool _downloading = false;
  bool _sharing = false;

  CertificateEntity get cert => widget.cert;
  String get _formattedDate =>
      DateFormat('d MMMM yyyy').format(cert.issuedAt);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Certificate Preview',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        actions: [
          IconButton(
            icon: _downloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.download_rounded),
            tooltip: 'Download PDF',
            onPressed: _downloading ? null : _handleDownload,
          ),
          IconButton(
            icon: _sharing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.share_rounded),
            tooltip: 'Share',
            onPressed: _sharing ? null : _handleShare,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width,
            ),
            child: AspectRatio(
              aspectRatio: 1.414, // A4 landscape
              child: _buildCertificateWidget(),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFF0F172A),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Row(children: [
          Expanded(
            child: _bigBtn(
              icon: Icons.download_rounded,
              label: 'Download PDF',
              bg: _navy,
              loading: _downloading,
              onTap: _handleDownload,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _bigBtn(
              icon: Icons.share_rounded,
              label: 'Share',
              bg: _gold,
              loading: _sharing,
              onTap: _handleShare,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _bigBtn({
    required IconData icon,
    required String label,
    required Color bg,
    required bool loading,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: loading ? null : onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
              color: bg, borderRadius: BorderRadius.circular(14)),
          child: Center(
            child: loading
                ? const CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5)
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(label,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                    ],
                  ),
          ),
        ),
      );

  // ── On-screen certificate widget ────────────────────────────────────────────

  Widget _buildCertificateWidget() {
    final name = cert.studentName.isNotEmpty
        ? cert.studentName
        : widget.loggedInName.isNotEmpty
            ? widget.loggedInName
            : 'Graduate';
    final course =
        cert.courseName.isNotEmpty ? cert.courseName : 'EduBridge Course';

    return Container(
      decoration: BoxDecoration(
        color: _cream,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 30,
              offset: const Offset(0, 12)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Watermark background pattern ──────────────────────────────
            Positioned.fill(
              child: CustomPaint(painter: _WatermarkPainter()),
            ),

            // ── Outer gold border ─────────────────────────────────────────
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: _gold, width: 2.5),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  border:
                      Border.all(color: _gold.withValues(alpha: 0.4), width: 1),
                ),
              ),
            ),

            // ── Corner ornaments ──────────────────────────────────────────
            Positioned(top: 8, left: 8, child: _cornerWidget(0)),
            Positioned(top: 8, right: 8,
                child: _cornerWidget(1.5708)),
            Positioned(bottom: 8, right: 8,
                child: _cornerWidget(3.1416)),
            Positioned(bottom: 8, left: 8,
                child: _cornerWidget(-1.5708)),

            // ── Main content ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(48, 14, 48, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header: logo + brand
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: _navy,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text('E',
                              style: TextStyle(
                                  color: _gold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'EDUBRIDGE',
                        style: TextStyle(
                            color: _navy,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Gold divider
                  _goldDivider(),
                  const SizedBox(height: 6),

                  // Title
                  const Text(
                    'Certificate of Completion',
                    style: TextStyle(
                        color: _navy,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'THIS IS TO CERTIFY THAT',
                    style: TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 7,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 5),

                  // Student name
                  Text(
                    name,
                    style: const TextStyle(
                        color: _navy,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'HAS SUCCESSFULLY COMPLETED THE COURSE',
                    style: TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 7,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 5),

                  // Course name
                  Text(
                    '"$course"',
                    style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        height: 1.3),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const Spacer(),

                  // Cert info bar
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    children: [
                      Text(
                        'No: #${cert.certificateNumber}',
                        style: const TextStyle(
                            fontSize: 6.5, color: Colors.blueGrey,
                            letterSpacing: 0.8),
                      ),
                      Text(
                        'Issued: $_formattedDate',
                        style: const TextStyle(
                            fontSize: 6.5, color: Colors.blueGrey,
                            letterSpacing: 0.8),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Two signature lines
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Left — EduBridge Academy
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(width: 60, height: 1, color: _navy),
                            const SizedBox(height: 2),
                            Text(
                              cert.issuedBy.isNotEmpty
                                  ? cert.issuedBy
                                  : 'EduBridge Academy',
                              style: const TextStyle(
                                  fontSize: 7,
                                  color: _navy,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Text('AUTHORIZED SIGNATORY',
                                style: TextStyle(
                                    fontSize: 5.5,
                                    color: Colors.blueGrey,
                                    letterSpacing: 0.8)),
                          ],
                        ),
                      ),

                      // Center seal (smaller)
                      _buildSeal(size: 48),

                      // Right — instructor
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(width: 60, height: 1, color: _navy),
                            const SizedBox(height: 2),
                            Text(
                              cert.instructorName.isNotEmpty
                                  ? cert.instructorName
                                  : 'Course Instructor',
                              style: const TextStyle(
                                  fontSize: 7,
                                  color: _navy,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Text('COURSE INSTRUCTOR',
                                style: TextStyle(
                                    fontSize: 5.5,
                                    color: Colors.blueGrey,
                                    letterSpacing: 0.8)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _goldDivider() => Row(
        children: [
          Expanded(
              child: Container(
                  height: 1,
                  color: _gold.withValues(alpha: 0.5))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.star_rounded, color: _gold, size: 10),
          ),
          Expanded(
              child: Container(
                  height: 1,
                  color: _gold.withValues(alpha: 0.5))),
        ],
      );

  Widget _cornerWidget(double angle) => Transform.rotate(
        angle: angle,
        child: SizedBox(
            width: 22, height: 22, child: CustomPaint(painter: _CornerPainter())),
      );

  Widget _buildSeal({double size = 64}) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [_goldLt, _gold, Color(0xFF8B6914)],
            stops: [0.0, 0.6, 1.0],
          ),
          boxShadow: [
            BoxShadow(
                color: _gold.withValues(alpha: 0.4),
                blurRadius: 10,
                spreadRadius: 1),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.workspace_premium_rounded,
                color: _navy, size: size * 0.31),
            SizedBox(height: size * 0.015),
            Text('EDUBRIDGE',
                style: TextStyle(
                    color: _navy,
                    fontSize: size * 0.086,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8)),
            Text('CERTIFIED',
                style: TextStyle(
                    color: _navy,
                    fontSize: size * 0.07,
                    letterSpacing: 0.6)),
          ],
        ),
      );

  // ── Actions ─────────────────────────────────────────────────────────────────

  Future<void> _handleDownload() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      final bytes = await _getPdfBytes(cert, fallbackName: widget.loggedInName);
      final file = await _savePdfToDevice(bytes,
          certNumber: cert.certificateNumber, permanent: true);
      final result = await OpenFilex.open(file.path);
      if (mounted) {
        final opened = result.type == ResultType.done;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            Icon(
              opened ? Icons.check_circle_rounded : Icons.folder_open_rounded,
              color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                opened ? 'Certificate opened!' : 'Saved! Tap Open to view.',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ]),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 5),
          action: opened ? null : SnackBarAction(
            label: 'Open',
            textColor: Colors.white,
            onPressed: () => OpenFilex.open(file.path),
          ),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Download failed: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
        ));
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _handleShare() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final bytes = await _getPdfBytes(cert, fallbackName: widget.loggedInName);
      final file = await _savePdfToDevice(bytes,
          certNumber: cert.certificateNumber, permanent: false);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'My EduBridge Certificate — ${cert.courseName}',
        text: 'I just completed "${cert.courseName}" on EduBridge! 🎓\nCertificate No: #${cert.certificateNumber}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Share failed: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }
}

// ── Shared PDF helpers ────────────────────────────────────────────────────────

/// Tries GET /certificates/:id/download from the backend first.
/// Falls back to local PDF generation if the endpoint fails or returns non-PDF.
Future<Uint8List> _getPdfBytes(CertificateEntity cert, {String fallbackName = ''}) async {
  if (cert.id.isNotEmpty) {
    try {
      final token = await SecureStorage.getToken() ?? '';
      final url =
          '${ApiConstants.baseUrl}${ApiConstants.certificates}/${cert.id}/download';
      final res = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 20));

      if (res.statusCode == 200 &&
          res.headers['content-type']?.contains('pdf') == true &&
          res.bodyBytes.length > 512) {
        return res.bodyBytes;
      }
    } catch (_) {}
  }
  // Fall back to locally generated PDF
  return CertificatePdfBuilder.build(cert, fallbackName: fallbackName);
}

Future<File> _savePdfToDevice(
  Uint8List bytes, {
  required String certNumber,
  required bool permanent,
}) async {
  final safeNum = certNumber.replaceAll(RegExp(r'[^A-Za-z0-9]'), '_');
  final fileName = 'EduBridge_Certificate_$safeNum.pdf';

  if (!permanent) {
    // For sharing: temp dir is fine
    final tmp = await getTemporaryDirectory();
    final file = File('${tmp.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  // For permanent download on Android: use app-specific external storage
  // (/storage/emulated/0/Android/data/<pkg>/files/Certificates/)
  // Visible in Files app and accessible via FileProvider without permissions.
  if (Platform.isAndroid) {
    final extDir = await getExternalStorageDirectory();
    if (extDir != null) {
      final certDir = Directory('${extDir.path}/Certificates');
      if (!certDir.existsSync()) certDir.createSync(recursive: true);
      final file = File('${certDir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      return file;
    }
  }

  // iOS / fallback: documents directory
  final docsDir = await getApplicationDocumentsDirectory();
  final certDir = Directory('${docsDir.path}/Certificates');
  if (!certDir.existsSync()) certDir.createSync(recursive: true);
  final file = File('${certDir.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return file;
}

// ── PDF builder ───────────────────────────────────────────────────────────────

class CertificatePdfBuilder {
  static Future<Uint8List> build(CertificateEntity cert, {String fallbackName = ''}) async {
    final doc = pw.Document();

    final name = cert.studentName.isNotEmpty
        ? cert.studentName
        : fallbackName.isNotEmpty
            ? fallbackName
            : 'Graduate';
    final course = cert.courseName.isNotEmpty ? cert.courseName : 'EduBridge Course';
    final instructor = cert.instructorName.isNotEmpty ? cert.instructorName : '';
    final issuedBy = cert.issuedBy.isNotEmpty ? cert.issuedBy : 'EduBridge Academy';
    final dateStr = DateFormat('d MMMM yyyy').format(cert.issuedAt);
    final certNo = cert.certificateNumber;

    // Colours
    const navyPdf   = PdfColor.fromInt(0xFF0F172A);
    const goldPdf   = PdfColor.fromInt(0xFFF59E0B);
    const goldLtPdf = PdfColor.fromInt(0xFFFBBF24);
    const creamPdf  = PdfColor.fromInt(0xFFF8FAFC);
    const greyPdf   = PdfColor.fromInt(0xFF607D8B);

    doc.addPage(pw.Page(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.zero,
        theme: pw.ThemeData.withFont(
          base: pw.Font.times(),
          bold: pw.Font.timesBold(),
          italic: pw.Font.timesItalic(),
          boldItalic: pw.Font.timesBoldItalic(),
        ),
      ),
      build: (pw.Context ctx) {
        return pw.Stack(
          children: [
            // ── Cream background ────────────────────────────────────────────
            pw.Positioned.fill(
              child: pw.Container(color: creamPdf),
            ),

            // ── Watermark diagonal text ─────────────────────────────────────
            pw.Positioned.fill(
              child: pw.Center(
                child: pw.Transform.rotate(
                  angle: -0.5,
                  child: pw.Opacity(
                    opacity: 0.04,
                    child: pw.Text(
                      'EDUBRIDGE',
                      style: pw.TextStyle(
                          font: pw.Font.timesBold(),
                          fontSize: 100,
                          color: navyPdf),
                    ),
                  ),
                ),
              ),
            ),

            // ── Outer gold border ───────────────────────────────────────────
            pw.Positioned.fill(
              child: pw.Container(
                margin: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: goldPdf, width: 2.5),
                ),
              ),
            ),
            pw.Positioned.fill(
              child: pw.Container(
                margin: const pw.EdgeInsets.all(18),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                      color: PdfColor(
                          goldPdf.red, goldPdf.green, goldPdf.blue, 0.4),
                      width: 1),
                ),
              ),
            ),

            // ── Main content ────────────────────────────────────────────────
            pw.Positioned.fill(
              child: pw.Padding(
                padding: const pw.EdgeInsets.fromLTRB(60, 30, 60, 28),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // Logo row
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Container(
                          width: 28,
                          height: 28,
                          decoration: const pw.BoxDecoration(
                            color: navyPdf,
                            shape: pw.BoxShape.circle,
                          ),
                          child: pw.Center(
                            child: pw.Text('E',
                                style: pw.TextStyle(
                                    font: pw.Font.timesBold(),
                                    color: goldPdf,
                                    fontSize: 16)),
                          ),
                        ),
                        pw.SizedBox(width: 10),
                        pw.Text(
                          'EDUBRIDGE',
                          style: pw.TextStyle(
                              font: pw.Font.timesBold(),
                              color: navyPdf,
                              fontSize: 14,
                              letterSpacing: 4),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),

                    // Gold divider
                    _pdfDivider(goldPdf),
                    pw.SizedBox(height: 14),

                    // Title
                    pw.Text(
                      'Certificate of Completion',
                      style: pw.TextStyle(
                          font: pw.Font.timesBold(),
                          color: navyPdf,
                          fontSize: 28,
                          letterSpacing: 1),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'THIS IS TO CERTIFY THAT',
                      style: pw.TextStyle(
                          font: pw.Font.times(),
                          color: greyPdf,
                          fontSize: 9,
                          letterSpacing: 3),
                    ),
                    pw.SizedBox(height: 14),

                    // Student name
                    pw.Text(
                      name,
                      style: pw.TextStyle(
                          font: pw.Font.timesBoldItalic(),
                          color: navyPdf,
                          fontSize: 34,
                          letterSpacing: 0.5),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 8),

                    // Thin rule under name
                    pw.Container(
                        width: 220,
                        height: 0.75,
                        color: PdfColor(
                            goldPdf.red, goldPdf.green, goldPdf.blue, 0.6)),
                    pw.SizedBox(height: 8),

                    pw.Text(
                      'HAS SUCCESSFULLY COMPLETED THE COURSE',
                      style: pw.TextStyle(
                          font: pw.Font.times(),
                          color: greyPdf,
                          fontSize: 9,
                          letterSpacing: 2.5),
                    ),
                    pw.SizedBox(height: 10),

                    // Course name
                    pw.Text(
                      '"$course"',
                      style: pw.TextStyle(
                          font: pw.Font.timesBold(),
                          color: const PdfColor.fromInt(0xFF1E293B),
                          fontSize: 18,
                          letterSpacing: 0.5),
                      textAlign: pw.TextAlign.center,
                    ),

                    pw.Spacer(),

                    // Bottom: cert info + two signature lines
                    pw.Column(
                      children: [
                        // Cert number + date info bar
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Text('Certificate No: #$certNo',
                                style: pw.TextStyle(
                                    font: pw.Font.times(),
                                    color: greyPdf,
                                    fontSize: 8,
                                    letterSpacing: 1)),
                            pw.SizedBox(width: 24),
                            pw.Text('Issued: $dateStr',
                                style: pw.TextStyle(
                                    font: pw.Font.times(),
                                    color: greyPdf,
                                    fontSize: 8,
                                    letterSpacing: 1)),
                          ],
                        ),
                        pw.SizedBox(height: 12),
                        // Signature row
                        pw.Row(
                          children: [
                            // Left signature — issuing org
                            pw.Expanded(
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.center,
                                children: [
                                  pw.Container(
                                      width: 120, height: 0.75, color: navyPdf),
                                  pw.SizedBox(height: 4),
                                  pw.Text(issuedBy,
                                      style: pw.TextStyle(
                                          font: pw.Font.timesBold(),
                                          color: navyPdf,
                                          fontSize: 9)),
                                  pw.Text('AUTHORIZED SIGNATORY',
                                      style: pw.TextStyle(
                                          font: pw.Font.times(),
                                          color: greyPdf,
                                          fontSize: 6.5,
                                          letterSpacing: 1.2)),
                                ],
                              ),
                            ),

                            // Center seal
                            pw.Container(
                              width: 60,
                              height: 60,
                              decoration: pw.BoxDecoration(
                                shape: pw.BoxShape.circle,
                                gradient: const pw.RadialGradient(
                                  colors: [goldLtPdf, goldPdf,
                                    PdfColor.fromInt(0xFF8B6914)],
                                  stops: [0.0, 0.6, 1.0],
                                ),
                              ),
                              child: pw.Column(
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                children: [
                                  pw.Text('★',
                                      style: pw.TextStyle(
                                          color: navyPdf, fontSize: 18)),
                                  pw.Text('EDUBRIDGE',
                                      style: pw.TextStyle(
                                          font: pw.Font.timesBold(),
                                          color: navyPdf,
                                          fontSize: 5,
                                          letterSpacing: 0.8)),
                                  pw.Text('CERTIFIED',
                                      style: pw.TextStyle(
                                          font: pw.Font.times(),
                                          color: navyPdf,
                                          fontSize: 4,
                                          letterSpacing: 0.6)),
                                ],
                              ),
                            ),

                            // Right signature — instructor
                            pw.Expanded(
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.center,
                                children: [
                                  pw.Container(
                                      width: 120, height: 0.75, color: navyPdf),
                                  pw.SizedBox(height: 4),
                                  pw.Text(
                                    instructor.isNotEmpty
                                        ? instructor
                                        : 'Course Instructor',
                                    style: pw.TextStyle(
                                        font: pw.Font.timesBold(),
                                        color: navyPdf,
                                        fontSize: 9)),
                                  pw.Text('COURSE INSTRUCTOR',
                                      style: pw.TextStyle(
                                          font: pw.Font.times(),
                                          color: greyPdf,
                                          fontSize: 6.5,
                                          letterSpacing: 1.2)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Corner ornaments (PDF) ──────────────────────────────────────
            pw.Positioned(
                top: 10, left: 10,
                child: _pdfCorner(goldPdf, 0)),
            pw.Positioned(
                top: 10, right: 10,
                child: _pdfCorner(goldPdf, 1.5708)),
            pw.Positioned(
                bottom: 10, right: 10,
                child: _pdfCorner(goldPdf, 3.1416)),
            pw.Positioned(
                bottom: 10, left: 10,
                child: _pdfCorner(goldPdf, -1.5708)),
          ],
        );
      },
    ));

    return doc.save();
  }

  static pw.Widget _pdfDivider(PdfColor gold) => pw.Row(
        children: [
          pw.Expanded(
              child: pw.Container(
                  height: 0.8,
                  color: PdfColor(gold.red, gold.green, gold.blue, 0.5))),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8),
            child: pw.Text('✦',
                style: pw.TextStyle(color: gold, fontSize: 10)),
          ),
          pw.Expanded(
              child: pw.Container(
                  height: 0.8,
                  color: PdfColor(gold.red, gold.green, gold.blue, 0.5))),
        ],
      );

  static pw.Widget _pdfCorner(PdfColor color, double angle) =>
      pw.Transform.rotate(
        angle: angle,
        child: pw.SizedBox(
          width: 24,
          height: 24,
          child: pw.CustomPaint(
            painter: (canvas, size) {
              canvas.setStrokeColor(color);
              canvas.setLineWidth(1.5);
              // Outer L
              canvas.moveTo(0, size.y);
              canvas.lineTo(0, size.y - 14);
              canvas.strokePath();
              canvas.moveTo(0, size.y);
              canvas.lineTo(14, size.y);
              canvas.strokePath();
              // Inner L
              canvas.setLineWidth(0.75);
              canvas.moveTo(3, size.y - 3);
              canvas.lineTo(3, size.y - 8);
              canvas.strokePath();
              canvas.moveTo(3, size.y - 3);
              canvas.lineTo(8, size.y - 3);
              canvas.strokePath();
              // Dot
              canvas.setFillColor(color);
              canvas.drawEllipse(0, size.y, 2, 2);
              canvas.fillPath();
            },
          ),
        ),
      );
}

// ── Custom painters ───────────────────────────────────────────────────────────

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _gold
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.65, 0)
      ..moveTo(0, 0)
      ..lineTo(0, size.height * 0.65)
      ..moveTo(3, 3)
      ..lineTo(size.width * 0.38, 3)
      ..moveTo(3, 3)
      ..lineTo(3, size.height * 0.38);

    canvas.drawPath(path, paint);

    paint
      ..style = PaintingStyle.fill
      ..color = _gold;
    canvas.drawCircle(Offset.zero, 2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WatermarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _navy.withValues(alpha: 0.025)
      ..style = PaintingStyle.fill;

    // Subtle diagonal stripe pattern
    const gap = 28.0;
    for (double d = -size.height; d < size.width + size.height; d += gap) {
      canvas.drawRect(Rect.fromLTWH(d, 0, 6, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
