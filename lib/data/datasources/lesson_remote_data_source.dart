import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:edubridge/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import '../../core/error_handling.dart';

class LessonRemoteDataSource {
  static Map<String, String> _auth(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  static String _err(String body, String fallback) {
    try {
      final d = jsonDecode(body);
      if (d is Map) {
        final e = d['errors'];
        if (e is List && e.isNotEmpty) return e.join('\n');
        final m = d['message'];
        if (m is String && m.isNotEmpty) return m;
      }
    } catch (_) {}
    return body.isNotEmpty ? body : fallback;
  }

  Future<List<Map<String, dynamic>>> fetchLessonsForCourse(
    String courseId,
    String token,
  ) async {
    final response = await http.get(
      Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.lessons}?courseId=$courseId',
      ),
      headers: _auth(token),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = data is List ? data : (data['data'] ?? data['lessons'] ?? []);
      return List<Map<String, dynamic>>.from(list as List);
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw ApiException('Failed to fetch lessons', response.statusCode);
    }
  }

  Future<Map<String, dynamic>> addSection(
    String courseId,
    Map<String, dynamic> sectionData,
    String token,
  ) async {
    // POST /lessons/sections/{courseId}  — courseId is a path segment
    // Body: { title, sortOrder }
    final url = '${ApiConstants.baseUrl}${ApiConstants.lessons}/sections/$courseId';
    final body = <String, dynamic>{
      'title': sectionData['title'],
      'sortOrder': sectionData['order'] ?? 1,
    };
    debugPrint('-- addSection POST $url body=${jsonEncode(body)}');
    final response = await http.post(
      Uri.parse(url),
      headers: _auth(token),
      body: jsonEncode(body),
    );
    debugPrint('-- addSection STATUS ${response.statusCode} ${response.body}');
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException(
        _err(response.body, 'Failed to add section'), response.statusCode);
  }

  Future<Map<String, dynamic>> updateSection(
    String courseId,
    String sectionId,
    Map<String, dynamic> sectionData,
    String token,
  ) async {
    // PATCH /lessons/sections/:sectionId
    final url = '${ApiConstants.baseUrl}${ApiConstants.lessons}/sections/$sectionId';
    debugPrint('-- updateSection PATCH $url body=${jsonEncode(sectionData)}');
    final response = await http.patch(
      Uri.parse(url),
      headers: _auth(token),
      body: jsonEncode(sectionData),
    );
    debugPrint('-- updateSection STATUS ${response.statusCode} ${response.body}');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException(
        _err(response.body, 'Failed to update section'), response.statusCode);
  }

  Future<void> deleteSection(
    String courseId,
    String sectionId,
    String token,
  ) async {
    // DELETE /lessons/sections/:sectionId
    final url = '${ApiConstants.baseUrl}${ApiConstants.lessons}/sections/$sectionId';
    debugPrint('-- deleteSection DELETE $url');
    final response = await http.delete(Uri.parse(url), headers: _auth(token));
    debugPrint('-- deleteSection STATUS ${response.statusCode} ${response.body}');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException(
          _err(response.body, 'Failed to delete section'), response.statusCode);
    }
  }

  Future<Map<String, dynamic>> addLesson(
    String sectionId,
    Map<String, dynamic> lessonData,
    String token,
  ) async {
    // POST /lessons  — sectionId goes in the body along with title/sortOrder
    final url = '${ApiConstants.baseUrl}${ApiConstants.lessons}';
    final body = <String, dynamic>{
      'sectionId': sectionId,
      'title': lessonData['title'],
      if (lessonData['sortOrder'] != null) 'sortOrder': lessonData['sortOrder'],
      if (lessonData['content'] != null) 'content': lessonData['content'],
    };
    debugPrint('-- addLesson POST $url body=${jsonEncode(body)}');
    final response = await http.post(
      Uri.parse(url),
      headers: _auth(token),
      body: jsonEncode(body),
    );
    debugPrint('-- addLesson STATUS ${response.statusCode} ${response.body}');
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException(
        _err(response.body, 'Failed to add lesson'), response.statusCode);
  }

  Future<Map<String, dynamic>> updateLesson(
    String lessonId,
    Map<String, dynamic> lessonData,
    String token,
  ) async {
    final response = await http.patch(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.lessonDetails(lessonId)),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(lessonData),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException('Failed to update lesson', response.statusCode);
  }

  Future<void> deleteLesson(String lessonId, String token) async {
    final response = await http.delete(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.lessonDetails(lessonId)),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException('Failed to delete lesson', response.statusCode);
    }
  }
}
