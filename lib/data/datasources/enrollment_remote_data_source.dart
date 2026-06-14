import 'dart:convert';
import '../../constants/api_constants.dart';
import '../../core/error_handling.dart';
import '../../core/http_utils.dart';

class EnrollmentRemoteDataSource {
  Future<void> enrollInCourse(String courseId, String token) async {
    try {
      final response = await apiPost(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.enrollFree(courseId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'courseId': courseId}),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ApiException('Failed to enroll in course', response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(networkErrorMessage(e), 0);
    }
  }

  Future<void> unenrollFromCourse(String enrollmentId, String token) async {
    try {
      final response = await apiDelete(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.unenroll + enrollmentId),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException('Failed to unenroll from course', response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(networkErrorMessage(e), 0);
    }
  }

  Future<List<Map<String, dynamic>>> fetchEnrollments(String token) async {
    try {
      final response = await apiGet(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.enroll),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final enrollments = data is List ? data : (data['enrollments'] ?? []);
        return List<Map<String, dynamic>>.from(enrollments);
      }
      throw ApiException('Failed to fetch enrollments', response.statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(networkErrorMessage(e), 0);
    }
  }

  Future<Map<String, dynamic>> fetchEnrollmentDetails(
    String enrollmentId,
    String token,
  ) async {
    try {
      final response = await apiGet(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.enrollmentDetails(enrollmentId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw ApiException('Failed to fetch enrollment details', response.statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(networkErrorMessage(e), 0);
    }
  }

  Future<void> updateLessonProgress(
    String lessonId,
    Map<String, dynamic> progressData,
    String token,
  ) async {
    try {
      final response = await apiPost(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.lessonProgress(lessonId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(progressData),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ApiException('Failed to update lesson progress', response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(networkErrorMessage(e), 0);
    }
  }
}
