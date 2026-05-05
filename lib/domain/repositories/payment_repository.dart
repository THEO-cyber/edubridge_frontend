abstract class PaymentRepository {
  Future<Map<String, dynamic>> createPaymentIntent(
    String courseId,
    String token,
  );
  Future<List<Map<String, dynamic>>> fetchPaymentHistory(String token);
}
