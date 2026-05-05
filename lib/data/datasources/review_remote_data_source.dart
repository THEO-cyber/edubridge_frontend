import 'dart:convert';
import 'package:edubridge/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import '../../core/error_handling.dart';

class ReviewRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchReviews(String courseId) async {
    final response = await http.get(
      Uri.parse(
        ApiConstants.baseUrl + ApiConstants.reviews + '?courseId=$courseId',
      ),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw ApiException('Failed to fetch reviews', response.statusCode);
    }
  }

  Future<void> postReview(
    String courseId,
    String review,
    int rating,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.reviews),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'courseId': courseId,
        'review': review,
        'rating': rating,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException('Failed to post review', response.statusCode);
    }
  }
}
