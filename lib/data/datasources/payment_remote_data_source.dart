import 'dart:convert';
import 'package:edubridge/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import '../../core/error_handling.dart';

class PaymentRemoteDataSource {
  Future<Map<String, dynamic>> createPaymentIntent(
    String courseId,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.createPaymentIntent),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'courseId': courseId}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException(
        'Failed to create payment intent',
        response.statusCode,
      );
    }
  }

  Future<List<Map<String, dynamic>>> fetchPaymentHistory(String token) async {
    final response = await http.get(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.paymentHistory),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(
        data is List ? data : (data['payments'] ?? []),
      );
    } else {
      throw ApiException(
        'Failed to fetch payment history',
        response.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> verifyPayment(
    String courseId,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/payments/verify'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'courseId': courseId}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException('Failed to verify payment', response.statusCode);
    }
  }

  /// Returns coupon info: { discountAmount, discountPercentage, finalPrice, ... }
  Future<Map<String, dynamic>> applyCoupon(
    String couponCode,
    String courseId,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.couponsApply),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'couponCode': couponCode, 'courseId': courseId}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        final inner = data['data'];
        return inner is Map<String, dynamic> ? inner : data;
      }
      return {};
    }
    String errorMsg = 'Invalid or expired coupon code';
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['message'] is String) {
        errorMsg = body['message'] as String;
      }
    } catch (_) {}
    throw ApiException(errorMsg, response.statusCode);
  }
}
