import 'dart:convert';
import 'package:edubridge/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import '../../core/error_handling.dart';

class LiveSessionRemoteDataSource {
  // Student endpoints
  Future<List<Map<String, dynamic>>> fetchLiveSessions(String token) async {
    // Backend has no bare GET /live-sessions — use /upcoming instead
    final url = '${ApiConstants.baseUrl}${ApiConstants.liveSessionUpcoming}';
    print('---------- [LiveSessions] GET $url');
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    print('---------- [LiveSessions] Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(
          data is List ? data : (data['sessions'] ?? data['data'] ?? []));
    } else {
      throw ApiException('Failed to fetch live sessions', response.statusCode);
    }
  }

  Future<Map<String, dynamic>> fetchLiveSessionDetail(String sessionId, String token) async {
    final response = await http.get(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.liveSessions + '/$sessionId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is Map ? data as Map<String, dynamic> : data['data'] as Map<String, dynamic>;
    } else {
      throw ApiException('Failed to fetch session detail', response.statusCode);
    }
  }

  Future<void> requestLiveSession(String token, String sessionId, String courseId) async {
    final response = await http.post(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.liveSessionRequest),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'sessionId': sessionId, 'courseId': courseId}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException('Failed to request live session', response.statusCode);
    }
  }

  Future<Map<String, dynamic>> joinLiveSession(String sessionId, String token) async {
    final url = '${ApiConstants.baseUrl}/live-sessions/$sessionId/join';
    print('---------- [JoinSession] POST $url');
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    print('---------- [JoinSession] Status: ${response.statusCode}');
    print('---------- [JoinSession] Response: ${response.body}');
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    String msg = 'Failed to join session';
    try {
      final b = jsonDecode(response.body);
      if (b is Map) msg = (b['message'] ?? msg).toString();
    } catch (_) {}
    throw ApiException(msg, response.statusCode);
  }

  Future<List<Map<String, dynamic>>> fetchMySessionRequests(String token) async {
    final response = await http.get(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.liveSessionRequests + '/my-requests'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    } else {
      throw ApiException('Failed to fetch session requests', response.statusCode);
    }
  }

  Future<void> leaveLiveSession(String sessionId, String token) async {
    final response = await http.post(
      Uri.parse(
        ApiConstants.baseUrl + ApiConstants.liveSessions + '/$sessionId/leave',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException('Failed to leave live session', response.statusCode);
    }
  }

  // Lecturer endpoints
  Future<List<Map<String, dynamic>>> fetchMyLiveSessions(String token) async {
    final url = ApiConstants.baseUrl + ApiConstants.liveSessionMySessions;
    print('---------- [MySessions] GET $url');
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    print('---------- [MySessions] Status: ${response.statusCode}');
    print('---------- [MySessions] Response: ${response.body}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = data is List
          ? List<Map<String, dynamic>>.from(data)
          : List<Map<String, dynamic>>.from(
              data['sessions'] ?? data['data'] ?? []);
      print('---------- [MySessions] Parsed count: ${list.length}');
      return list;
    } else {
      throw ApiException('Failed to fetch instructor sessions', response.statusCode);
    }
  }

  Future<void> createLiveSession(String token, Map<String, dynamic> body) async {
    final url = ApiConstants.baseUrl + ApiConstants.liveSessions;
    print('---------- [LiveSession] POST $url');
    print('---------- [LiveSession] Body: ${jsonEncode(body)}');
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    print('---------- [LiveSession] Status: ${response.statusCode}');
    print('---------- [LiveSession] Response: ${response.body}');
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException('Failed to create live session: ${response.body}', response.statusCode);
    }
  }

  Future<void> scheduleLiveSession(String token, String sessionId, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.liveSessions + '/$sessionId/schedule'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException('Failed to schedule live session', response.statusCode);
    }
  }

  Future<List<Map<String, dynamic>>> fetchSessionRequests(String sessionId, String token) async {
    final response = await http.get(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.liveSessions + '/$sessionId/requests'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    } else {
      throw ApiException('Failed to fetch session requests', response.statusCode);
    }
  }

  Future<void> acceptSessionRequest(String requestId, String token, {String? feedback}) async {
    final response = await http.post(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.liveSessionRequests + '/$requestId/accept'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'feedback': feedback}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException('Failed to accept request', response.statusCode);
    }
  }

  Future<void> rejectSessionRequest(String requestId, String token, String rejectionReason) async {
    final response = await http.post(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.liveSessionRequests + '/$requestId/reject'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'rejectionReason': rejectionReason}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException('Failed to reject request', response.statusCode);
    }
  }

  Future<void> endLiveSession(String sessionId, String token) async {
    final response = await http.patch(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.liveSessions + '/$sessionId/end'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException('Failed to end live session', response.statusCode);
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllInstructorRequests(String token) async {
    final url = ApiConstants.baseUrl + ApiConstants.liveSessionRequests;
    print('---------- [InstructorRequests] GET $url');
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    print('---------- [InstructorRequests] Status: ${response.statusCode}');
    print('---------- [InstructorRequests] Response: ${response.body}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = data is List
          ? List<Map<String, dynamic>>.from(data)
          : List<Map<String, dynamic>>.from(data['requests'] ?? data['data'] ?? []);
      print('---------- [InstructorRequests] Total count: ${list.length}');
      return list;
    }
    throw ApiException('Failed to fetch requests', response.statusCode);
  }

  Future<void> cancelSessionRequest(String requestId, String token) async {
    final response = await http.patch(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.liveSessionCancel(requestId)),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException('Failed to cancel request', response.statusCode);
    }
  }

  Future<void> setAvailability(String token, Map<String, dynamic> body) async {
    final url = '${ApiConstants.baseUrl}/live-sessions/availability';
    print('---------- [Availability] POST $url');
    print('---------- [Availability] Body: ${jsonEncode(body)}');
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    print('---------- [Availability] Status: ${response.statusCode}');
    print('---------- [Availability] Response: ${response.body}');
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException('Failed to set availability: ${response.body}', response.statusCode);
    }
  }

  Future<List<Map<String, dynamic>>> fetchMyAvailabilitySlots(String token) async {
    final url = ApiConstants.baseUrl + ApiConstants.liveSessionMyAvailability;
    print('---------- [MySlots] GET $url');
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    print('---------- [MySlots] Status: ${response.statusCode}');
    print('---------- [MySlots] Response: ${response.body}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = data is List
          ? List<Map<String, dynamic>>.from(data)
          : List<Map<String, dynamic>>.from(
              data['slots'] ?? data['availability'] ?? data['data'] ?? []);
      print('---------- [MySlots] Parsed count: ${list.length}');
      return list;
    }
    throw ApiException('Failed to fetch availability slots', response.statusCode);
  }

  Future<void> deleteAvailabilitySlot(String slotId, String token) async {
    final url = '${ApiConstants.baseUrl}/live-sessions/availability/$slotId';
    print('---------- [DeleteSlot] DELETE $url');
    final response = await http.delete(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    print('---------- [DeleteSlot] Status: ${response.statusCode}');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException('Failed to delete slot', response.statusCode);
    }
  }

  Future<void> recordAttendance(String sessionId, String token, List<String> attendeeIds) async {
    final response = await http.post(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.liveSessions + '/$sessionId/attendance'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'attendeeIds': attendeeIds}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException('Failed to record attendance', response.statusCode);
    }
  }

  // Analytics endpoints
  Future<Map<String, dynamic>> fetchSessionAnalytics(String sessionId, String token) async {
    final response = await http.get(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.liveSessions + '/$sessionId/analytics'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is Map ? data as Map<String, dynamic> : data['data'] as Map<String, dynamic>;
    } else {
      throw ApiException('Failed to fetch session analytics', response.statusCode);
    }
  }

  Future<List<Map<String, dynamic>>> fetchCourseSessionsAnalytics(String courseId, String token) async {
    final response = await http.get(
      Uri.parse(ApiConstants.baseUrl + '/courses/$courseId/sessions/analytics'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    } else {
      throw ApiException('Failed to fetch course analytics', response.statusCode);
    }
  }

  Future<Map<String, dynamic>> fetchOverallAnalytics(String token) async {
    final response = await http.get(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.liveSessions + '/analytics/overview'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is Map ? data as Map<String, dynamic> : data['data'] as Map<String, dynamic>;
    } else {
      throw ApiException('Failed to fetch overall analytics', response.statusCode);
    }
  }

  Future<List<Map<String, dynamic>>> fetchSessionAttendance(String sessionId, String token) async {
    final response = await http.get(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.liveSessions + '/$sessionId/attendance'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    } else {
      throw ApiException('Failed to fetch attendance records', response.statusCode);
    }
  }

  Future<void> markAttendance(String sessionId, String studentId, String token) async {
    final response = await http.post(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.liveSessions + '/$sessionId/attendance/$studentId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException('Failed to mark attendance', response.statusCode);
    }
  }

  // ── Group session flow (v2) ──────────────────────────────────────────────

  Future<void> createGroupLiveSession(String token, Map<String, dynamic> body) async {
    final url = '${ApiConstants.baseUrl}${ApiConstants.liveSessions}';
    print('---------- [CreateSession] POST $url');
    print('---------- [CreateSession] Body: ${jsonEncode(body)}');
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode(body),
    );
    print('---------- [CreateSession] Status: ${response.statusCode}');
    print('---------- [CreateSession] Response: ${response.body}');
    if (response.statusCode != 200 && response.statusCode != 201) {
      String msg = 'Failed to create session';
      try {
        final b = jsonDecode(response.body);
        if (b is Map) {
          final raw = b['message'] ?? b['error'];
          msg = raw is List ? raw.join(', ') : (raw?.toString() ?? msg);
        }
      } catch (_) {}
      throw ApiException(msg, response.statusCode);
    }
    // Print created session id + status for debugging
    try {
      final created = jsonDecode(response.body);
      final s = created is Map
          ? (created['session'] ?? created['data'] ?? created)
          : created;
      print(
          '---------- [CreateSession] Created id=${s['id']} status=${s['status']}');
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> fetchUpcomingSessions(String token) async {
    // Try /live-sessions/upcoming first; if it returns 0, try /live-sessions?type=group
    final url = '${ApiConstants.baseUrl}${ApiConstants.liveSessionUpcoming}';
    print('---------- [Upcoming] GET $url');
    final response = await http.get(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );
    print('---------- [Upcoming] Status: ${response.statusCode}');
    print('---------- [Upcoming] Response: ${response.body}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = List<Map<String, dynamic>>.from(
          data is List ? data : (data['sessions'] ?? data['data'] ?? []));
      if (list.isNotEmpty) return list;

      // Fallback: try bare /live-sessions?type=group&status=scheduled
      final fallbackUrl =
          '${ApiConstants.baseUrl}${ApiConstants.liveSessions}?type=group&status=scheduled';
      print('---------- [Upcoming] Fallback GET $fallbackUrl');
      final fb = await http.get(
        Uri.parse(fallbackUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );
      print('---------- [Upcoming] Fallback Status: ${fb.statusCode}');
      print('---------- [Upcoming] Fallback Response: ${fb.body}');
      if (fb.statusCode == 200) {
        final fd = jsonDecode(fb.body);
        return List<Map<String, dynamic>>.from(
            fd is List ? fd : (fd['sessions'] ?? fd['data'] ?? []));
      }
      return list; // return empty if fallback also fails
    }
    throw ApiException('Failed to fetch upcoming sessions', response.statusCode);
  }

  Future<void> applyToSession(String sessionId, String token,
      {String? message}) async {
    final url = '${ApiConstants.baseUrl}${ApiConstants.liveSessionApply(sessionId)}';
    print('---------- [Apply] POST $url');
    final hasBody = message != null && message.isNotEmpty;
    print('---------- [Apply] Body: ${hasBody ? jsonEncode({'message': message}) : '(none)'}');
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: hasBody ? jsonEncode({'message': message}) : null,
    );
    print('---------- [Apply] Status: ${response.statusCode}');
    print('---------- [Apply] Response: ${response.body}');
    if (response.statusCode != 200 && response.statusCode != 201) {
      String msg = 'Failed to apply';
      try {
        final b = jsonDecode(response.body);
        if (b is Map) {
          final raw = b['message'] ?? b['error'];
          msg = raw is List ? raw.join(', ') : (raw?.toString() ?? msg);
        }
      } catch (_) {}
      throw ApiException(msg, response.statusCode);
    }
  }

  Future<List<Map<String, dynamic>>> fetchApplicationsForSession(
      String sessionId, String token) async {
    final url =
        '${ApiConstants.baseUrl}${ApiConstants.liveSessionApplications(sessionId)}';
    print('---------- [Applications] GET $url');
    final response = await http.get(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );
    print('---------- [Applications] Status: ${response.statusCode}');
    print('---------- [Applications] Response: ${response.body}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = List<Map<String, dynamic>>.from(
          data is List ? data : (data['applications'] ?? data['data'] ?? []));
      for (final a in list) {
        print('---------- [Applications] app id=${a['id']} status=${a['status']} student=${a['student'] ?? a['studentId']}');
      }
      return list;
    }
    throw ApiException('Failed to fetch applications', response.statusCode);
  }

  Future<void> acceptApplication(String applicationId, String token) async {
    final url =
        '${ApiConstants.baseUrl}${ApiConstants.liveSessionApplicationAccept(applicationId)}';
    print('---------- [AcceptApp] PATCH $url');
    final response = await http.patch(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );
    print('---------- [AcceptApp] Status: ${response.statusCode}');
    print('---------- [AcceptApp] Response: ${response.body}');
    if (response.statusCode != 200 && response.statusCode != 201) {
      String msg = 'Failed to accept application';
      try {
        final b = jsonDecode(response.body);
        if (b is Map) msg = (b['message'] ?? msg).toString();
      } catch (_) {}
      throw ApiException(msg, response.statusCode);
    }
  }

  Future<void> rejectApplication(String applicationId, String token) async {
    final url =
        '${ApiConstants.baseUrl}${ApiConstants.liveSessionApplicationReject(applicationId)}';
    print('---------- [RejectApp] PATCH $url');
    final response = await http.patch(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );
    print('---------- [RejectApp] Status: ${response.statusCode}');
    print('---------- [RejectApp] Response: ${response.body}');
    if (response.statusCode != 200 && response.statusCode != 201) {
      String msg = 'Failed to reject application';
      try {
        final b = jsonDecode(response.body);
        if (b is Map) msg = (b['message'] ?? msg).toString();
      } catch (_) {}
      throw ApiException(msg, response.statusCode);
    }
  }

  Future<void> notifyAcceptedStudents(String sessionId, String token,
      {String? message}) async {
    final url =
        '${ApiConstants.baseUrl}${ApiConstants.liveSessionNotifyAccepted(sessionId)}';
    print('---------- [Notify] POST $url');
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode(
          {'message': message ?? 'Your live session is about to start!'}),
    );
    print('---------- [Notify] Status: ${response.statusCode}');
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException('Failed to send notifications', response.statusCode);
    }
  }

  Future<void> deleteSession(String sessionId, String token) async {
    final url = '${ApiConstants.baseUrl}${ApiConstants.liveSessions}/$sessionId';
    print('---------- [DeleteSession] DELETE $url');
    final response = await http.delete(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );
    print('---------- [DeleteSession] Status: ${response.statusCode}');
    print('---------- [DeleteSession] Response: ${response.body}');
    if (response.statusCode != 200 && response.statusCode != 204) {
      String msg = 'Failed to delete session';
      try {
        final b = jsonDecode(response.body);
        if (b is Map) msg = (b['message'] ?? msg).toString();
      } catch (_) {}
      throw ApiException(msg, response.statusCode);
    }
  }

  Future<void> rescheduleSession(
      String sessionId, String token, DateTime scheduledAt) async {
    final url = '${ApiConstants.baseUrl}${ApiConstants.liveSessions}/$sessionId';
    print('---------- [Reschedule] PATCH $url');
    final body = {'scheduledAt': scheduledAt.toUtc().toIso8601String()};
    print('---------- [Reschedule] Body: ${jsonEncode(body)}');
    final response = await http.patch(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode(body),
    );
    print('---------- [Reschedule] Status: ${response.statusCode}');
    print('---------- [Reschedule] Response: ${response.body}');
    if (response.statusCode != 200 && response.statusCode != 201) {
      String msg = 'Failed to reschedule session';
      try {
        final b = jsonDecode(response.body);
        if (b is Map) msg = (b['message'] ?? msg).toString();
      } catch (_) {}
      throw ApiException(msg, response.statusCode);
    }
  }

  Future<Map<String, dynamic>> confirmLiveSessionRequest(
    String requestId,
    String token,
  ) async {
    final url = ApiConstants.baseUrl + ApiConstants.liveSessionConfirm(requestId);
    print('---------- [ConfirmSession] POST $url');
    print('---------- [ConfirmSession] requestId: $requestId');
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    print('---------- [ConfirmSession] Status: ${response.statusCode}');
    print('---------- [ConfirmSession] Response: ${response.body}');
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException('Failed to confirm live session: ${response.body}', response.statusCode);
  }
}
