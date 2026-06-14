import 'dart:convert';
import 'package:edubridge/constants/api_constants.dart';
import '../../core/error_handling.dart';
import '../../core/http_utils.dart';

class ReviewRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchReviews(String courseId) async {
    try {
      final response = await apiGet(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.courseReviews(courseId)),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reviews = data is List
            ? data
            : (data['reviews'] ?? data['data'] ?? []);
        return List<Map<String, dynamic>>.from(reviews);
      }
      throw ApiException('Failed to fetch reviews', response.statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(networkErrorMessage(e), 0);
    }
  }

  Future<Map<String, dynamic>> postReview(
    String courseId,
    String review,
    int rating,
    String token,
  ) async {
    try {
      final response = await apiPost(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.reviews),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'courseId': courseId,
          'comment': review,
          'review': review,
          'content': review,
          'rating': rating,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      if (response.statusCode == 409) {
        throw ApiException('You have already reviewed this course.', 409);
      }
      String msg = 'Failed to post review';
      try {
        final b = jsonDecode(response.body);
        if (b is Map) msg = (b['message'] ?? b['error'] ?? msg).toString();
      } catch (_) {}
      throw ApiException(msg, response.statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(networkErrorMessage(e), 0);
    }
  }

  Future<void> deleteReview(String reviewId, String token) async {
    try {
      final response = await apiDelete(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.reviews}/$reviewId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException('Failed to delete review', response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(networkErrorMessage(e), 0);
    }
  }

  Future<List<Map<String, dynamic>>> fetchMyReviews(String token) async {
    try {
      final response = await apiGet(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.myReviews}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data is List ? data : (data['reviews'] ?? data['data'] ?? []);
        return List<Map<String, dynamic>>.from(list);
      }
      throw ApiException('Failed to fetch my reviews', response.statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(networkErrorMessage(e), 0);
    }
  }
}
