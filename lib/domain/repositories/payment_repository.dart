abstract class PaymentRepository {
  Future<Map<String, dynamic>> createPaymentIntent(
    String courseId,
    String token, {
    required String phoneNumber,
    String? couponCode,
  });
  Future<List<Map<String, dynamic>>> fetchPaymentHistory(String token);
}
