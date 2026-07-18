import '../../core/http_utils.dart';
import 'dart:convert';
import '../../constants/api_constants.dart';

class AnnouncementsRemoteDataSource {
  Future<List<dynamic>> getCourseAnnouncements(
      String courseId, String token) async {
    final res = await apiGet(
      Uri.parse(ApiConstants.baseUrl +
          ApiConstants.courseAnnouncements(courseId)),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  Future<Map<String, dynamic>> createAnnouncement(
      String courseId, String title, String content, String token) async {
    final res = await apiPost(
      Uri.parse(ApiConstants.baseUrl +
          ApiConstants.courseAnnouncements(courseId)),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'title': title, 'content': content}),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body);
    }
    throw Exception('Failed to create announcement');
  }

  Future<void> updateAnnouncement(
      String id, String title, String content, String token) async {
    await apiPatch(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.announcementById(id)),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'title': title, 'content': content}),
    );
  }

  Future<void> deleteAnnouncement(String id, String token) async {
    await apiDelete(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.announcementById(id)),
      headers: {'Authorization': 'Bearer $token'},
    );
  }
}
