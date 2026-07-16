import 'dart:convert';
import 'package:edubridge/constants/api_constants.dart';
import '../../core/error_handling.dart';
import '../../core/http_utils.dart';

class PaymentRemoteDataSource {
  /// Start a MoMo/Orange Money payment (Nkwa). The server derives the amount
  /// from the course price; we forward the payer's phone number + optional
  /// coupon. Returns { paymentId, nkwaPaymentId, status, operator, amount }.
  Future<Map<String, dynamic>> createPaymentIntent(
    String courseId,
    String token, {
    required String phoneNumber,
    String? couponCode,
  }) async {
    final response = await apiPost(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.createPaymentIntent),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'courseId': courseId,
        'phoneNumber': phoneNumber,
        if (couponCode != null && couponCode.isNotEmpty) 'couponCode': couponCode,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      String msg = 'Failed to start payment';
      try {
        final b = jsonDecode(response.body);
        msg = (b['message'] ?? b['error'] ?? msg).toString();
      } catch (_) {}
      throw ApiException(msg, response.statusCode);
    }
  }

  /// Poll a payment's status. Returns the status string:
  /// PENDING | COMPLETED | FAILED.
  Future<String> getPaymentStatus(String paymentId, String token) async {
    final response = await apiGet(
      Uri.parse('${ApiConstants.baseUrl}/payments/$paymentId/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = extractObject(jsonDecode(response.body));
      return (data['status'] ?? 'PENDING').toString().toUpperCase();
    }
    throw ApiException('Failed to check payment status', response.statusCode);
  }

  Future<List<Map<String, dynamic>>> fetchPaymentHistory(String token) async {
    final response = await apiGet(
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
    final response = await apiPost(
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

  /// GET /payouts/earnings — instructor earnings data
  Future<Map<String, dynamic>> fetchEarnings(String token) async {
    final response = await apiGet(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.payoutsEarnings),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return extractObject(jsonDecode(response.body));
    }
    throw ApiException('Failed to fetch earnings (${response.statusCode})',
        response.statusCode);
  }

  /// Returns coupon info: { discountAmount, discountPercentage, finalPrice, ... }
  Future<Map<String, dynamic>> applyCoupon(
    String couponCode,
    String courseId,
    String token,
  ) async {
    final response = await apiPost(
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
