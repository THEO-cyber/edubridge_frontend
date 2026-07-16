import '../repositories/payment_repository.dart';

class CreatePaymentIntentUseCase {
  final PaymentRepository repository;
  CreatePaymentIntentUseCase(this.repository);

  Future<Map<String, dynamic>> call(
    String courseId,
    String token, {
    required String phoneNumber,
    String? couponCode,
  }) {
    return repository.createPaymentIntent(
      courseId,
      token,
      phoneNumber: phoneNumber,
      couponCode: couponCode,
    );
  }
}
