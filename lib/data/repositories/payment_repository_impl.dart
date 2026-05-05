import '../../domain/repositories/payment_repository.dart';
import '../datasources/payment_remote_data_source.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource remoteDataSource;
  PaymentRepositoryImpl(this.remoteDataSource);

  @override
  Future<Map<String, dynamic>> createPaymentIntent(
    String courseId,
    String token,
  ) async {
    return await remoteDataSource.createPaymentIntent(courseId, token);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPaymentHistory(String token) async {
    return await remoteDataSource.fetchPaymentHistory(token);
  }
}
