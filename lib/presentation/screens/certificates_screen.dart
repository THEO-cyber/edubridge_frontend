import 'package:flutter/material.dart';
import '../../constants/api_constants.dart';
import '../../core/secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CertificatesScreen extends StatefulWidget {
  const CertificatesScreen({super.key});

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
  late Future<List<Map<String, dynamic>>> _certificatesFuture;

  @override
  void initState() {
    super.initState();
    _certificatesFuture = _fetchCertificates();
  }

  Future<List<Map<String, dynamic>>> _fetchCertificates() async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Not logged in');

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
      return _fetchCertificatesFromEnrollments(token);
    }

    throw Exception(
      'Failed to load certificates: ${response.statusCode} ${response.body}',
    );
  }

  Future<List<Map<String, dynamic>>> _fetchCertificatesFromEnrollments(
    String token,
  ) async {
    final response = await http.get(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.enroll),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final enrollments = data is List
          ? data
          : (data['enrollments'] ?? data['data'] ?? []);
      final completed = List<Map<String, dynamic>>.from(enrollments)
          .where((enrollment) {
            final progress = enrollment['progress'] ?? 0;
            return progress is num ? progress >= 100 : false;
          })
          .map((enrollment) {
            return {
              'courseName':
                  enrollment['courseTitle'] ??
                  enrollment['courseName'] ??
                  'Course',
              'issuedDate':
                  enrollment['updatedAt'] ??
                  enrollment['completedAt'] ??
                  DateTime.now().toIso8601String(),
              'courseId':
                  enrollment['courseId'] ?? enrollment['course']?['id'] ?? '',
            };
          })
          .toList();
      return completed;
    }

    throw Exception(
      'Failed to fetch completed enrollments for certificates: '
      '${response.statusCode} ${response.body}',
    );
  }

  List<dynamic> _extractList(dynamic data, List<String> keys) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      for (final key in keys) {
        final value = data[key];
        if (value is List) return value;
      }
      if (data['data'] is Map<String, dynamic> || data['data'] is List) {
        return _extractList(data['data'], keys);
      }
      throw Exception(
        'Unexpected certificates response format: ${jsonEncode(data)}',
      );
    }
    throw Exception(
      'Unexpected certificates response type: ${data.runtimeType}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 400;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Certificates'),
        backgroundColor: Colors.blueGrey[800],
      ),
      backgroundColor: Colors.grey[100],
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _certificatesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _certificatesFuture = _fetchCertificates();
                      });
                    },
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
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 60,
                    color: Colors.blueGrey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text('No certificates yet'),
                  const SizedBox(height: 8),
                  const Text(
                    'Complete courses to earn certificates',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _certificatesFuture = _fetchCertificates();
              });
            },
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isSmall ? 1 : 2,
                childAspectRatio: 1.5,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              itemCount: certificates.length,
              itemBuilder: (context, index) {
                final cert = certificates[index];
                final courseName = cert['courseName'] ?? 'Course';
                final issuedDate =
                    cert['issuedDate'] ?? DateTime.now().toString();

                return GestureDetector(
                  onTap: () {
                    _showCertificateDetail(context, cert);
                  },
                  child: Card(
                    elevation: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.amber[300]!, Colors.amber[100]!],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.emoji_events,
                            size: 48,
                            color: Colors.amber[700],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Certificate of Completion',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.amber[900],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            courseName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber[800],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatDate(issuedDate),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.amber[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showCertificateDetail(BuildContext context, Map<String, dynamic> cert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Certificate Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Course: ${cert['courseName'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Issued: ${_formatDate(cert['issuedDate'] ?? '')}'),
            const SizedBox(height: 8),
            Text('ID: ${cert['id'] ?? 'N/A'}'),
            const SizedBox(height: 16),
            if (cert['certificateUrl'] != null)
              ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Download Certificate'),
                onPressed: () {
                  // Implement download functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Download started')),
                  );
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
