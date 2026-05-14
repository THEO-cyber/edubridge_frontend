import 'dart:convert';
import 'package:edubridge/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import '../../core/error_handling.dart';

class LessonRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchLessonsForCourse(
    String courseId,
    String token,
  ) async {
    final response = await http.get(
      Uri.parse(
        ApiConstants.baseUrl + ApiConstants.lessons + '?courseId=$courseId',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw ApiException('Failed to fetch lessons', response.statusCode);
    }
  }

  Future<Map<String, dynamic>> addSection(
    String courseId,
    Map<String, dynamic> sectionData,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.courseSections(courseId)),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(sectionData),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException('Failed to add section', response.statusCode);
  }

  Future<Map<String, dynamic>> updateSection(
    String courseId,
    String sectionId,
    Map<String, dynamic> sectionData,
    String token,
  ) async {
    final response = await http.patch(
      Uri.parse(
        ApiConstants.baseUrl + ApiConstants.courseSection(courseId, sectionId),
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(sectionData),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException('Failed to update section', response.statusCode);
  }

  Future<void> deleteSection(
    String courseId,
    String sectionId,
    String token,
  ) async {
    final response = await http.delete(
      Uri.parse(
        ApiConstants.baseUrl + ApiConstants.courseSection(courseId, sectionId),
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException('Failed to delete section', response.statusCode);
    }
  }

  Future<Map<String, dynamic>> addLesson(
    String sectionId,
    Map<String, dynamic> lessonData,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.sectionLessons(sectionId)),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(lessonData),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException('Failed to add lesson', response.statusCode);
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
