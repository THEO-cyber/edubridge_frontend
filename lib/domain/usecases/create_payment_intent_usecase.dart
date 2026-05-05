import '../repositories/payment_repository.dart';

class CreatePaymentIntentUseCase {
  final PaymentRepository repository;
  CreatePaymentIntentUseCase(this.repository);

  Future<Map<String, dynamic>> call(String courseId, String token) {
    return repository.createPaymentIntent(courseId, token);
  }
}
