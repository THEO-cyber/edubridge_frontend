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
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw ApiException(
        'Failed to fetch payment history',
        response.statusCode,
      );
    }
  }
}
