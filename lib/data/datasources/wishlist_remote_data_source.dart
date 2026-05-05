import 'dart:convert';
import 'package:edubridge/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import '../../core/error_handling.dart';

class WishlistRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchWishlist(String token) async {
    final response = await http.get(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.wishlist),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw ApiException('Failed to fetch wishlist', response.statusCode);
    }
  }

  Future<void> addToWishlist(String courseId, String token) async {
    final response = await http.post(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.wishlist),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'courseId': courseId}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException('Failed to add to wishlist', response.statusCode);
    }
  }
}
