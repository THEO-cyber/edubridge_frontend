import '../../core/http_utils.dart';
import 'dart:convert';
import '../../constants/api_constants.dart';

class DiscussionsRemoteDataSource {
  Future<List<dynamic>> getCourseDiscussions(
      String courseId, String token) async {
    final res = await apiGet(
      Uri.parse(
          ApiConstants.baseUrl + ApiConstants.courseDiscussions(courseId)),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  Future<Map<String, dynamic>> getThread(
      String threadId, String token) async {
    final res = await apiGet(
      Uri.parse(
          ApiConstants.baseUrl + ApiConstants.discussionThread(threadId)),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load thread');
  }

  Future<Map<String, dynamic>> createThread(
      String courseId, String title, String content, String token) async {
    final res = await apiPost(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.discussionThreads),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(
          {'courseId': courseId, 'title': title, 'content': content}),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body);
    }
    throw Exception('Failed to create thread');
  }

  Future<Map<String, dynamic>> replyToThread(
      String threadId, String content, String token,
      {String? replyToId}) async {
    final res = await apiPost(
      Uri.parse(
          ApiConstants.baseUrl + ApiConstants.replyToThread(threadId)),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'content': content,
        if (replyToId != null) 'replyToId': replyToId,
      }),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body);
    }
    throw Exception('Failed to post reply');
  }

  Future<void> markAsAnswered(
      String threadId, String replyId, String token) async {
    await apiPost(
      Uri.parse(ApiConstants.baseUrl +
          ApiConstants.markAnswered(threadId, replyId)),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<void> submitReport(
      String targetType, String targetId, String reason, String token) async {
    await apiPost(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.reports),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'targetType': targetType,
        'targetId': targetId,
        'reason': reason,
      }),
    );
  }
}
