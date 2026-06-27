import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/certificate_entity.dart';
import '../blocs/certificate_bloc.dart';

// ── Brand colours ──────────────────────────────────────────────────────────────
const _navy   = Color(0xFF0D1B4B);
const _gold   = Color(0xFFC9A84C);
const _goldLt = Color(0xFFF0D080);
const _cream  = Color(0xFFFAF8F0);

class CertificateScreenEnhanced extends StatefulWidget {
  final String token;
  const CertificateScreenEnhanced({super.key, required this.token});

  @override
  State<CertificateScreenEnhanced> createState() =>
      _CertificateScreenEnhancedState();
}

class _CertificateScreenEnhancedState
    extends State<CertificateScreenEnhanced> {
  @override
  void initState() {
    super.initState();
    context.read<CertificateBloc>().add(LoadCertificatesEvent(widget.token));
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
              itemBuilder: (_, i) =>
                  _CertificateCard(cert: state.certificates[i]),
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
  const _CertificateCard({required this.cert});

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
                height: 140,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D1B4B), Color(0xFF1A3272)],
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
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                    Row(children: [
                      _infoChip(Icons.tag_rounded,
                          '#${cert.certificateNumber}'),
                      const Spacer(),
                      // Download button
                      _actionBtn(
                        icon: _downloading
                            ? null
                            : Icons.download_rounded,
                        label: 'Download',
                        loading: _downloading,
                        color: _navy,
                        onTap: _handleDownload,
                      ),
                      const SizedBox(width: 10),
                      // Share button
                      _actionBtn(
                        icon: _sharing
                            ? null
                            : Icons.share_rounded,
                        label: 'Share',
                        loading: _sharing,
                        color: _gold,
                        onTap: _handleShare,
                      ),
                    ]),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F2FB),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: Colors.blueGrey),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
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
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
      builder: (_) => _CertificatePreviewScreen(cert: cert),
    ));
  }

  Future<void> _handleDownload() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      final bytes = await CertificatePdfBuilder.build(cert);
      final file = await _savePdf(bytes, permanent: true);
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
                opened
                    ? 'Certificate opened!'
                    : 'Saved to: Files > Android > data > ${file.path.split('/Android/').last}',
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
          content: Text('Download failed: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
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
      final bytes = await CertificatePdfBuilder.build(cert);
      final file = await _savePdf(bytes, permanent: false);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject:
            'My Certificate — ${cert.courseName}',
        text:
            'I completed "${cert.courseName}" on EduBridge! 🎓\nCertificate #${cert.certificateNumber}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Share failed: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<File> _savePdf(Uint8List bytes, {required bool permanent}) async {
    return _savePdfToDevice(bytes,
        certNumber: cert.certificateNumber, permanent: permanent);
  }
}

// ── Full-screen certificate preview ───────────────────────────────────────────

class _CertificatePreviewScreen extends StatefulWidget {
  final CertificateEntity cert;
  const _CertificatePreviewScreen({required this.cert});

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
      backgroundColor: const Color(0xFF0A0F24),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0F24),
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
        color: const Color(0xFF0A0F24),
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
    final name = cert.studentName.isNotEmpty ? cert.studentName : 'Graduate';
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
              padding: const EdgeInsets.fromLTRB(48, 24, 48, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header: logo + brand
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: _navy,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text('E',
                              style: TextStyle(
                                  color: _gold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'EDUBRIDGE',
                        style: TextStyle(
                            color: _navy,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Gold divider
                  _goldDivider(),
                  const SizedBox(height: 10),

                  // Title
                  const Text(
                    'Certificate of Completion',
                    style: TextStyle(
                        color: _navy,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'THIS IS TO CERTIFY THAT',
                    style: TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 8,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),

                  // Student name
                  Text(
                    name,
                    style: const TextStyle(
                        color: _navy,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'HAS SUCCESSFULLY COMPLETED THE COURSE',
                    style: TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 7.5,
                        letterSpacing: 2.5,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),

                  // Course name
                  Text(
                    '"$course"',
                    style: const TextStyle(
                        color: Color(0xFF1A3272),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        height: 1.3),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const Spacer(),

                  // Bottom section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Left: date + cert number
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                                width: 80, height: 1, color: _navy),
                            const SizedBox(height: 4),
                            Text(_formattedDate,
                                style: const TextStyle(
                                    fontSize: 9,
                                    color: _navy,
                                    fontWeight: FontWeight.w600)),
                            const Text('DATE OF ISSUE',
                                style: TextStyle(
                                    fontSize: 7,
                                    color: Colors.blueGrey,
                                    letterSpacing: 1.5)),
                          ],
                        ),
                      ),

                      // Center: seal
                      _buildSeal(),

                      // Right: cert number
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                                width: 80, height: 1, color: _navy),
                            const SizedBox(height: 4),
                            Text(
                              '#${cert.certificateNumber}',
                              style: const TextStyle(
                                  fontSize: 9,
                                  color: _navy,
                                  fontWeight: FontWeight.w600),
                            ),
                            const Text('CERTIFICATE NO.',
                                style: TextStyle(
                                    fontSize: 7,
                                    color: Colors.blueGrey,
                                    letterSpacing: 1.5)),
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

  Widget _buildSeal() => Container(
        width: 64,
        height: 64,
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
            const Icon(Icons.workspace_premium_rounded,
                color: _navy, size: 20),
            const SizedBox(height: 1),
            const Text('EDUBRIDGE',
                style: TextStyle(
                    color: _navy,
                    fontSize: 5.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
            const Text('CERTIFIED',
                style: TextStyle(
                    color: _navy,
                    fontSize: 4.5,
                    letterSpacing: 0.8)),
          ],
        ),
      );

  // ── Actions ─────────────────────────────────────────────────────────────────

  Future<void> _handleDownload() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      final bytes = await CertificatePdfBuilder.build(cert);
      final file = await _savePdf(bytes, permanent: true);
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
                opened
                    ? 'Certificate opened!'
                    : 'Saved! Go to Files > Android > data to find it.',
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
      final bytes = await CertificatePdfBuilder.build(cert);
      final file = await _savePdf(bytes, permanent: false);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'My EduBridge Certificate — ${cert.courseName}',
        text:
            'I just completed "${cert.courseName}" on EduBridge! 🎓\nCertificate No: #${cert.certificateNumber}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Share failed: $e'),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<File> _savePdf(Uint8List bytes, {required bool permanent}) async {
    return _savePdfToDevice(bytes,
        certNumber: cert.certificateNumber, permanent: permanent);
  }
}

// ── Shared save helper ────────────────────────────────────────────────────────

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
  static Future<Uint8List> build(CertificateEntity cert) async {
    final doc = pw.Document();

    final name = cert.studentName.isNotEmpty ? cert.studentName : 'Graduate';
    final course =
        cert.courseName.isNotEmpty ? cert.courseName : 'EduBridge Course';
    final dateStr = DateFormat('d MMMM yyyy').format(cert.issuedAt);
    final certNo = cert.certificateNumber;

    // Colours
    const navyPdf   = PdfColor.fromInt(0xFF0D1B4B);
    const goldPdf   = PdfColor.fromInt(0xFFC9A84C);
    const goldLtPdf = PdfColor.fromInt(0xFFF0D080);
    const creamPdf  = PdfColor.fromInt(0xFFFAF8F0);
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
                          color: const PdfColor.fromInt(0xFF1A3272),
                          fontSize: 18,
                          letterSpacing: 0.5),
                      textAlign: pw.TextAlign.center,
                    ),

                    pw.Spacer(),

                    // Bottom row
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        // Date column
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              pw.Container(
                                  width: 100,
                                  height: 0.75,
                                  color: navyPdf),
                              pw.SizedBox(height: 4),
                              pw.Text(dateStr,
                                  style: pw.TextStyle(
                                      font: pw.Font.timesBold(),
                                      color: navyPdf,
                                      fontSize: 9)),
                              pw.Text('DATE OF ISSUE',
                                  style: pw.TextStyle(
                                      font: pw.Font.times(),
                                      color: greyPdf,
                                      fontSize: 7,
                                      letterSpacing: 1.5)),
                            ],
                          ),
                        ),

                        // Seal
                        pw.Container(
                          width: 70,
                          height: 70,
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
                                      color: navyPdf, fontSize: 22)),
                              pw.Text('EDUBRIDGE',
                                  style: pw.TextStyle(
                                      font: pw.Font.timesBold(),
                                      color: navyPdf,
                                      fontSize: 5.5,
                                      letterSpacing: 1)),
                              pw.Text('CERTIFIED',
                                  style: pw.TextStyle(
                                      font: pw.Font.times(),
                                      color: navyPdf,
                                      fontSize: 4.5,
                                      letterSpacing: 0.8)),
                            ],
                          ),
                        ),

                        // Cert number column
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              pw.Container(
                                  width: 100,
                                  height: 0.75,
                                  color: navyPdf),
                              pw.SizedBox(height: 4),
                              pw.Text('#$certNo',
                                  style: pw.TextStyle(
                                      font: pw.Font.timesBold(),
                                      color: navyPdf,
                                      fontSize: 9)),
                              pw.Text('CERTIFICATE NO.',
                                  style: pw.TextStyle(
                                      font: pw.Font.times(),
                                      color: greyPdf,
                                      fontSize: 7,
                                      letterSpacing: 1.5)),
                            ],
                          ),
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
