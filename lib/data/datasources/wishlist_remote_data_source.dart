import 'dart:convert';
import 'package:edubridge/constants/api_constants.dart';
import '../../core/error_handling.dart';
import '../../core/http_utils.dart';

class WishlistRemoteDataSource {
  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<List<Map<String, dynamic>>> fetchWishlist(String token) async {
    final response = await apiGet(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.wishlist),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      return extractListOf(jsonDecode(response.body), ['wishlist', 'items']);
    }
    throw ApiException('Failed to fetch wishlist', response.statusCode);
  }

  Future<void> addToWishlist(String courseId, String token) async {
    final response = await apiPost(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.wishlistCourse(courseId)),
      headers: _headers(token),
    );
    if (response.statusCode == 409) {
      throw ApiException('Course is already in your wishlist', 409);
    }
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException('Failed to add to wishlist', response.statusCode);
    }
  }

  Future<void> removeFromWishlist(String courseId, String token) async {
    final response = await apiDelete(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.wishlistCourse(courseId)),
      headers: _headers(token),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException('Failed to remove from wishlist', response.statusCode);
    }
  }

  Future<bool> isInWishlist(String courseId, String token) async {
    final response = await apiGet(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.wishlistCheck(courseId)),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      final data = extractObject(jsonDecode(response.body));
      return data['inWishlist'] ?? data['exists'] ?? false;
    }
    throw ApiException('Failed to check wishlist status', response.statusCode);
  }

  Future<void> clearWishlist(String token) async {
    final response = await apiDelete(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.wishlist),
      headers: _headers(token),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException('Failed to clear wishlist', response.statusCode);
    }
  }
}
