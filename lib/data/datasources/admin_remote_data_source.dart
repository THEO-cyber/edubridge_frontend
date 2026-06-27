import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants/api_constants.dart';
import '../../core/error_handling.dart';
import '../../core/http_utils.dart';

class AdminRemoteDataSource {
  Map<String, String> _auth(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // ── Helpers ────────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _list(dynamic data, List<String> keys) {
    if (data is List) return List<Map<String, dynamic>>.from(data);
    for (final k in keys) {
      if (data is Map && data[k] is List) {
        return List<Map<String, dynamic>>.from(data[k] as List);
      }
    }
    return [];
  }

  void _throw(http.Response res, String fallback) {
    String msg = fallback;
    try {
      final b = jsonDecode(res.body);
      if (b is Map) msg = (b['message'] ?? b['error'] ?? msg).toString();
    } catch (_) {}
    throw ApiException(msg, res.statusCode);
  }

  // ── Stats ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> fetchStats(String token) async {
    final res = await apiGet(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.adminStats}'),
      headers: _auth(token),
    );
    if (res.statusCode == 200) {
      final d = jsonDecode(res.body);
      return d is Map<String, dynamic>
          ? (d['data'] as Map<String, dynamic>? ?? d)
          : {};
    }
    _throw(res, 'Failed to fetch stats');
    return {};
  }

  Future<List<Map<String, dynamic>>> fetchActivity(String token,
      {int limit = 10}) async {
    final res = await apiGet(
      Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.adminActivity}?limit=$limit'),
      headers: _auth(token),
    );
    if (res.statusCode == 200) {
      final d = jsonDecode(res.body);
      return _list(d, ['data', 'activity', 'activities']);
    }
    return [];
  }

  // ── Users ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> fetchUsers(String token,
      {int page = 1, int limit = 20, String? role, String? search}) async {
    final params = {
      'page': '$page',
      'limit': '$limit',
      if (role != null) 'role': role,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.adminUsers}')
        .replace(queryParameters: params);
    final res = await apiGet(uri, headers: _auth(token));
    if (res.statusCode == 200) {
      final d = jsonDecode(res.body);
      if (d is Map<String, dynamic>) return d;
    }
    _throw(res, 'Failed to fetch users');
    return {};
  }

  Future<void> deactivateUser(String id, String token) async {
    final res = await apiPut(
      Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.adminDeactivateUser(id)}'),
      headers: _auth(token),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      _throw(res, 'Failed to deactivate user');
    }
  }

  Future<void> activateUser(String id, String token) async {
    final res = await apiPut(
      Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.adminActivateUser(id)}'),
      headers: _auth(token),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      _throw(res, 'Failed to activate user');
    }
  }

  Future<void> deleteUser(String id, String token) async {
    final res = await apiDelete(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.adminUserById(id)}'),
      headers: _auth(token),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      _throw(res, 'Failed to delete user');
    }
  }

  // ── Courses ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> fetchCourses(String token,
      {int page = 1, int limit = 20, String? status, String? search}) async {
    final params = {
      'page': '$page',
      'limit': '$limit',
      if (status != null) 'status': status,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final uri =
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.adminCourses}')
            .replace(queryParameters: params);
    final res = await apiGet(uri, headers: _auth(token));
    if (res.statusCode == 200) {
      final d = jsonDecode(res.body);
      if (d is Map<String, dynamic>) return d;
    }
    _throw(res, 'Failed to fetch courses');
    return {};
  }

  Future<void> approveCourse(String id, String token) async {
    final res = await apiPut(
      Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.adminApproveCourse(id)}'),
      headers: _auth(token),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      _throw(res, 'Failed to approve course');
    }
  }

  Future<void> rejectCourse(String id, String reason, String token) async {
    final res = await apiPut(
      Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.adminRejectCourse(id)}'),
      headers: _auth(token),
      body: jsonEncode({'reason': reason}),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      _throw(res, 'Failed to reject course');
    }
  }

  Future<void> suspendCourse(String id, String reason, String token) async {
    final res = await apiPut(
      Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.adminSuspendCourse(id)}'),
      headers: _auth(token),
      body: jsonEncode({'reason': reason}),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      _throw(res, 'Failed to suspend course');
    }
  }

  // ── Categories ─────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchCategories(String token) async {
    final res = await apiGet(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.adminCategories}'),
      headers: _auth(token),
    );
    if (res.statusCode == 200) {
      return _list(jsonDecode(res.body), ['data', 'categories']);
    }
    return [];
  }

  Future<void> createCategory(
      String name, String description, String token) async {
    final res = await apiPost(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.adminCategories}'),
      headers: _auth(token),
      body: jsonEncode({'name': name, 'description': description}),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      _throw(res, 'Failed to create category');
    }
  }

  Future<void> updateCategory(
      String id, String name, String description, String token) async {
    final res = await apiPut(
      Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.adminCategoryById(id)}'),
      headers: _auth(token),
      body: jsonEncode({'name': name, 'description': description}),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      _throw(res, 'Failed to update category');
    }
  }

  Future<void> deleteCategory(String id, String token) async {
    final res = await apiDelete(
      Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.adminCategoryById(id)}'),
      headers: _auth(token),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      _throw(res, 'Failed to delete category');
    }
  }

  // ── Instructor moderation ──────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchInstructors(String token) async {
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.adminInstructors}'),
      headers: _auth(token),
    );
    if (res.statusCode == 200) {
      return _list(jsonDecode(res.body), ['data', 'instructors']);
    }
    throw ApiException('Failed to fetch instructors', res.statusCode);
  }

  Future<void> suspendInstructor(
      String id, String reason, String token) async {
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.adminSuspend(id)}'),
      headers: _auth(token),
      body: jsonEncode({'reason': reason}),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      _throw(res, 'Failed to suspend instructor');
    }
  }

  Future<void> warnInstructor(
      String id, String message, String token) async {
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.adminWarn(id)}'),
      headers: _auth(token),
      body: jsonEncode({'message': message}),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      _throw(res, 'Failed to send warning');
    }
  }

  Future<void> deleteInstructor(String id, String token) async {
    final res = await http.delete(
      Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.adminDeleteInstructor(id)}'),
      headers: _auth(token),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      _throw(res, 'Failed to remove instructor');
    }
  }

  // ── Reviews ────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchAllReviews(String token,
      {String? courseId, String? instructorId, int? rating}) async {
    final params = <String, String>{};
    if (courseId != null) params['courseId'] = courseId;
    if (instructorId != null) params['instructorId'] = instructorId;
    if (rating != null) params['rating'] = rating.toString();
    final uri =
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.adminReviews}')
            .replace(queryParameters: params.isEmpty ? null : params);
    final res = await http.get(uri, headers: _auth(token));
    if (res.statusCode == 200) {
      return _list(jsonDecode(res.body), ['data', 'reviews']);
    }
    throw ApiException('Failed to fetch reviews', res.statusCode);
  }

  // ── Applications ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> fetchApplications(String token,
      {int page = 1, int limit = 20, String? status}) async {
    final params = {
      'page': '$page',
      'limit': '$limit',
      if (status != null) 'status': status,
    };
    final uri =
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.adminApplications}')
            .replace(queryParameters: params);
    final res = await apiGet(uri, headers: _auth(token));
    if (res.statusCode == 200) {
      final d = jsonDecode(res.body);
      if (d is Map<String, dynamic>) return d;
    }
    _throw(res, 'Failed to fetch applications');
    return {};
  }

  Future<void> reviewApplication(
      String id, String status, String token, {String? reason}) async {
    final res = await apiPatch(
      Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.adminReviewApplication(id)}'),
      headers: _auth(token),
      body: jsonEncode({
        'status': status,
        if (reason != null) 'reason': reason,
      }),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      _throw(res, 'Failed to review application');
    }
  }

  // ── Reports ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> fetchReports(String token,
      {int page = 1, int limit = 20, String? status, String? targetType}) async {
    final params = {
      'page': '$page',
      'limit': '$limit',
      if (status != null) 'status': status,
      if (targetType != null) 'targetType': targetType,
    };
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.reports}')
        .replace(queryParameters: params);
    final res = await apiGet(uri, headers: _auth(token));
    if (res.statusCode == 200) {
      final d = jsonDecode(res.body);
      if (d is Map<String, dynamic>) return d;
    }
    _throw(res, 'Failed to fetch reports');
    return {};
  }

  Future<void> resolveReport(
      String id, String status, String token, {String? note}) async {
    final res = await apiPatch(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.reviewReport(id)}'),
      headers: _auth(token),
      body: jsonEncode({
        'status': status,
        if (note != null) 'note': note,
      }),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      _throw(res, 'Failed to resolve report');
    }
  }

  // ── Coupons ────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchCoupons(String token) async {
    final res = await apiGet(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.adminCoupons}'),
      headers: _auth(token),
    );
    if (res.statusCode == 200) {
      return _list(jsonDecode(res.body), ['data', 'coupons']);
    }
    _throw(res, 'Failed to fetch coupons');
    return [];
  }

  Future<void> createCoupon(Map<String, dynamic> data, String token) async {
    final res = await apiPost(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.adminCoupons}'),
      headers: _auth(token),
      body: jsonEncode(data),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      _throw(res, 'Failed to create coupon');
    }
  }

  Future<void> deleteCoupon(String id, String token) async {
    final res = await apiDelete(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.adminCouponById(id)}'),
      headers: _auth(token),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      _throw(res, 'Failed to delete coupon');
    }
  }

  // ── Video moderation ───────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchPendingVideos(String token) async {
    final res = await apiGet(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.adminVideosPending}'),
      headers: _auth(token),
    );
    if (res.statusCode == 200) {
      return _list(jsonDecode(res.body), ['data', 'videos']);
    }
    return [];
  }

  Future<void> approveVideo(String id, String token) async {
    final res = await apiPost(
      Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.adminApproveVideo(id)}'),
      headers: _auth(token),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      _throw(res, 'Failed to approve video');
    }
  }

  Future<void> rejectVideo(String id, String reason, String token) async {
    final res = await apiPost(
      Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.adminRejectVideo(id)}'),
      headers: _auth(token),
      body: jsonEncode({'reason': reason}),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      _throw(res, 'Failed to reject video');
    }
  }

  // ── Notifications ──────────────────────────────────────────────────────────

  Future<void> broadcastNotification(
      String role, String title, String message, String token,
      {String? actionUrl}) async {
    final res = await apiPost(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.adminBroadcast}'),
      headers: _auth(token),
      body: jsonEncode({
        'role': role,
        'title': title,
        'message': message,
        if (actionUrl != null) 'actionUrl': actionUrl,
      }),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      _throw(res, 'Failed to send notification');
    }
  }

  // ── Payouts (admin) ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> fetchAllPayouts(String token,
      {int page = 1, int limit = 20}) async {
    final uri =
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.adminPayouts}')
            .replace(queryParameters: {'page': '$page', 'limit': '$limit'});
    final res = await apiGet(uri, headers: _auth(token));
    if (res.statusCode == 200) {
      final d = jsonDecode(res.body);
      if (d is Map<String, dynamic>) return d;
    }
    _throw(res, 'Failed to fetch payouts');
    return {};
  }

  // ── Session reviews ────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchSessionReviews(
      String sessionId, String token) async {
    final res = await http.get(
      Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.sessionReviews(sessionId)}'),
      headers: _auth(token),
    );
    if (res.statusCode == 200) {
      return _list(jsonDecode(res.body), ['data', 'reviews']);
    }
    throw ApiException('Failed to fetch session reviews', res.statusCode);
  }
}

