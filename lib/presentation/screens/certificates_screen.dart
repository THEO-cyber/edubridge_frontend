import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../constants/api_constants.dart';
import '../../core/secure_storage.dart';
import '../../data/datasources/certificate_remote_data_source.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CertificatesScreen extends StatefulWidget {
  const CertificatesScreen({super.key});

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
  late Future<List<Map<String, dynamic>>> _certificatesFuture;
  final _certDs = CertificateRemoteDataSource();

  @override
  void initState() {
    super.initState();
    _certificatesFuture = _fetchCertificates();
  }

  Future<List<Map<String, dynamic>>> _fetchCertificates() async {
    final token = await SecureStorage.getToken();
    if (token == null || token.isEmpty) throw Exception('Not logged in');

    final response = await http.get(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.certificates),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final certificates = _extractList(data, [
        'certificates',
        'data',
        'results',
        'items',
      ]);
      return List<Map<String, dynamic>>.from(certificates);
    }

    if (response.statusCode == 404) {
      return _fetchFromEnrollments(token);
    }

    throw Exception(
        'Failed to load certificates: ${response.statusCode}');
  }

  Future<List<Map<String, dynamic>>> _fetchFromEnrollments(
      String token) async {
    final response = await http.get(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.enroll),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final enrollments =
          data is List ? data : (data['enrollments'] ?? data['data'] ?? []);
      return List<Map<String, dynamic>>.from(enrollments)
          .where((e) {
            final progress = e['progress'] ?? 0;
            return progress is num ? progress >= 100 : false;
          })
          .map((e) => {
                'courseName': e['courseTitle'] ?? e['courseName'] ?? 'Course',
                'issuedDate':
                    e['updatedAt'] ?? e['completedAt'] ?? DateTime.now().toIso8601String(),
                'courseId': e['courseId'] ?? e['course']?['id'] ?? '',
              })
          .toList();
    }

    throw Exception('Failed to load certificates');
  }

  List<dynamic> _extractList(dynamic data, List<String> keys) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      for (final key in keys) {
        final value = data[key];
        if (value is List) return value;
      }
      if (data['data'] is List) return data['data'] as List;
      if (data['data'] is Map<String, dynamic>) {
        return _extractList(data['data'], keys);
      }
    }
    return [];
  }

  Future<void> _downloadCertificate(
      BuildContext ctx, Map<String, dynamic> cert) async {
    final certId = (cert['id'] ?? '').toString();
    final certUrl = (cert['certificateUrl'] ?? cert['downloadUrl'] ?? '').toString();

    // If backend provides a direct URL, use that
    if (certUrl.isNotEmpty) {
      await _downloadFromUrl(ctx, certUrl, cert);
      return;
    }

    if (certId.isEmpty) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(
              content: Text('Certificate ID not available for download'),
              backgroundColor: Colors.orange),
        );
      }
      return;
    }

    // Use the data source download endpoint
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Preparing download...')),
      );
    }

    try {
      final token = await SecureStorage.getToken();
      if (token == null || token.isEmpty) throw Exception('Not authenticated');

      final Uint8List bytes = await _certDs.downloadCertificate(certId, token);
      await _saveAndOpen(ctx, bytes, 'certificate_$certId.pdf');
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content:
                Text('Download failed: ${e.toString().replaceFirst("Exception: ", "")}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadFromUrl(
      BuildContext ctx, String url, Map<String, dynamic> cert) async {
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Downloading certificate...')),
      );
    }
    try {
      final token = await SecureStorage.getToken();
      final response = await http.get(
        Uri.parse(url),
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      );
      if (response.statusCode == 200) {
        final courseName =
            (cert['courseName'] ?? 'certificate').toString().replaceAll(' ', '_');
        await _saveAndOpen(ctx, response.bodyBytes, '$courseName.pdf');
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveAndOpen(
      BuildContext ctx, Uint8List bytes, String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);

    final result = await OpenFilex.open(file.path);

    if (ctx.mounted) {
      if (result.type == ResultType.done) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(
              content: Text('Certificate opened'),
              backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text('Saved to: ${file.path}'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 400;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Certificates'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F6FA),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _certificatesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF1A237E)));
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 60, color: Colors.red.shade400),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text('${snapshot.error}',
                        textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _certificatesFuture = _fetchCertificates();
                    }),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final certificates = snapshot.data ?? [];
          if (certificates.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events_outlined,
                      size: 72, color: Colors.amber.shade300),
                  const SizedBox(height: 16),
                  const Text('No certificates yet',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Complete courses to earn certificates',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _certificatesFuture = _fetchCertificates());
            },
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isSmall ? 1 : 2,
                childAspectRatio: 1.4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              itemCount: certificates.length,
              itemBuilder: (context, index) {
                final cert = certificates[index];
                return _CertificateCard(
                  cert: cert,
                  onTap: () => _showDetail(context, cert),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showDetail(BuildContext context, Map<String, dynamic> cert) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _CertificateDetailSheet(
        cert: cert,
        onDownload: () => _downloadCertificate(ctx, cert),
      ),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  final Map<String, dynamic> cert;
  final VoidCallback onTap;

  const _CertificateCard({required this.cert, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final courseName = (cert['courseName'] ?? cert['name'] ?? 'Course').toString();
    final issuedDate = _formatDate((cert['issuedDate'] ?? cert['createdAt'] ?? '').toString());

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.amber.shade400, Colors.amber.shade200],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.emoji_events,
                      color: Colors.amber.shade800, size: 28),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Certificate',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                courseName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.amber.shade900,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 11, color: Colors.amber.shade800),
                  const SizedBox(width: 4),
                  Text(
                    issuedDate,
                    style: TextStyle(
                        fontSize: 11, color: Colors.amber.shade800),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return dateStr;
    }
  }
}

class _CertificateDetailSheet extends StatelessWidget {
  final Map<String, dynamic> cert;
  final VoidCallback onDownload;

  const _CertificateDetailSheet(
      {required this.cert, required this.onDownload});

  @override
  Widget build(BuildContext context) {
    final courseName =
        (cert['courseName'] ?? cert['name'] ?? 'Course').toString();
    final issuedDate = _formatDate(
        (cert['issuedDate'] ?? cert['createdAt'] ?? '').toString());
    final certId = (cert['id'] ?? 'N/A').toString();
    final certNumber =
        (cert['certificateNumber'] ?? cert['number'] ?? '').toString();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade400, Colors.amber.shade200],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.emoji_events,
                    color: Colors.amber.shade900, size: 48),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Certificate of Completion',
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        courseName,
                        style: TextStyle(
                          color: Colors.amber.shade800,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _detailRow(Icons.calendar_today, 'Issued', issuedDate),
          if (certId != 'N/A') _detailRow(Icons.tag, 'ID', certId),
          if (certNumber.isNotEmpty)
            _detailRow(Icons.confirmation_number, 'Certificate #', certNumber),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onDownload();
              },
              icon: const Icon(Icons.download),
              label: const Text('Download Certificate'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Text('$label: ',
              style: const TextStyle(
                  color: Colors.blueGrey, fontWeight: FontWeight.w600)),
          Expanded(
              child: Text(value,
                  style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return dateStr;
    }
  }
}
