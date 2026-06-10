import 'dart:convert';
import 'package:edubridge/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import '../../core/error_handling.dart';

class ReviewRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchReviews(String courseId) async {
    final response = await http.get(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.courseReviews(courseId)),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final reviews = data is List ? data : (data['reviews'] ?? data['data'] ?? []);
      return List<Map<String, dynamic>>.from(reviews);
    } else {
      throw ApiException('Failed to fetch reviews', response.statusCode);
    }
  }

  Future<Map<String, dynamic>> postReview(
    String courseId,
    String review,
    int rating,
    String token,
  ) async {
    final url = '${ApiConstants.baseUrl}${ApiConstants.reviews}';
    final response = await http.post(
      Uri.parse(url),
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
    } else {
      String msg = 'Failed to post review';
      try {
        final b = jsonDecode(response.body);
        if (b is Map) msg = (b['message'] ?? b['error'] ?? msg).toString();
      } catch (_) {}
      throw ApiException(msg, response.statusCode);
    }
  }

  Future<void> deleteReview(String reviewId, String token) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.reviews}/$reviewId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException('Failed to delete review', response.statusCode);
    }
  }

  Future<List<Map<String, dynamic>>> fetchMyReviews(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.reviews}/my-reviews'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw ApiException('Failed to fetch my reviews', response.statusCode);
    }
  }
}
