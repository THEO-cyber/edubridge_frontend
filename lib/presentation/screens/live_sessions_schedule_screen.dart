import 'package:flutter/material.dart';
import '../../constants/api_constants.dart';
import '../../core/secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LiveSessionsScheduleScreen extends StatefulWidget {
  const LiveSessionsScheduleScreen({super.key});

  @override
  State<LiveSessionsScheduleScreen> createState() =>
      _LiveSessionsScheduleScreenState();
}

class _LiveSessionsScheduleScreenState
    extends State<LiveSessionsScheduleScreen> {
  late Future<List<Map<String, dynamic>>> _liveSessionsFuture;

  @override
  void initState() {
    super.initState();
    _liveSessionsFuture = _fetchLiveSessions();
  }

  Future<List<Map<String, dynamic>>> _fetchLiveSessions() async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) throw Exception('Not logged in');

      final response = await http.get(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.liveSessions),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sessions = _extractList(data, [
          'liveSessions',
          'sessions',
          'data',
          'results',
          'items',
        ]);
        return List<Map<String, dynamic>>.from(sessions);
      }
      if (response.statusCode == 404) {
        debugPrint('Live sessions endpoint not available: ${response.body}');
        return [];
      }
      throw Exception(
        'Failed to load live sessions: ${response.statusCode} ${response.body}',
      );
    } catch (e) {
      debugPrint('Live sessions fetch error: $e');
      rethrow;
    }
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
        'Unexpected live sessions response format: ${jsonEncode(data)}',
      );
    }
    throw Exception(
      'Unexpected live sessions response type: ${data.runtimeType}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 400;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Sessions'),
        backgroundColor: Colors.blueGrey[800],
      ),
      backgroundColor: Colors.grey[100],
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _liveSessionsFuture,
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
                        _liveSessionsFuture = _fetchLiveSessions();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final sessions = snapshot.data ?? [];
          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.videocam_off_outlined,
                    size: 60,
                    color: Colors.blueGrey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text('No live sessions scheduled'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _liveSessionsFuture = _fetchLiveSessions();
              });
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                final title = session['title'] ?? 'Live Session';
                final courseName = session['courseName'] ?? 'Course';
                final instructorName =
                    session['instructorName'] ?? 'Instructor';
                final scheduledTime =
                    session['scheduledTime'] ?? DateTime.now().toString();
                final status = session['status'] ?? 'scheduled';
                final capacity = session['capacity'] ?? 0;
                final enrolledCount = session['enrolledCount'] ?? 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: status == 'live'
                              ? Colors.red[50]
                              : status == 'upcoming'
                              ? Colors.amber[50]
                              : Colors.grey[50],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (status == 'live')
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: Colors.red[600],
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          title,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: isSmall ? 14 : 16,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    courseName,
                                    style: TextStyle(
                                      color: Colors.blueGrey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: status == 'live'
                                    ? Colors.red[600]
                                    : status == 'upcoming'
                                    ? Colors.amber[600]
                                    : Colors.grey[600],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: Colors.blueGrey[600],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _formatDateTime(scheduledTime),
                                    style: TextStyle(
                                      color: Colors.blueGrey[700],
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 16,
                                  color: Colors.blueGrey[600],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Instructor: $instructorName',
                                    style: TextStyle(
                                      color: Colors.blueGrey[700],
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.group,
                                  size: 16,
                                  color: Colors.blueGrey[600],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '$enrolledCount / $capacity participants',
                                    style: TextStyle(
                                      color: Colors.blueGrey[700],
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (status == 'live')
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.videocam),
                                  label: const Text('Join Live Session'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red[600],
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () {
                                    // Navigate to live session
                                  },
                                ),
                              )
                            else if (status == 'upcoming')
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.notifications_active),
                                  label: const Text('Set Reminder'),
                                  onPressed: () {
                                    // Set reminder
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }
}
