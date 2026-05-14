import '../../domain/entities/payment_entity.dart';
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

  Future<List<PaymentEntity>> fetchPayments(String token) async {
    final data = await remoteDataSource.fetchPaymentHistory(token);
    return data.map((e) {
      String statusString = (e['status'] ?? 'pending').toString().toLowerCase();
      PaymentStatus status = PaymentStatus.pending;

      if (statusString == 'completed')
        status = PaymentStatus.completed;
      else if (statusString == 'failed')
        status = PaymentStatus.failed;
      else if (statusString == 'cancelled')
        status = PaymentStatus.cancelled;

      return PaymentEntity(
        id: e['id'] ?? '',
        studentId: e['studentId'] ?? '',
        courseId: e['courseId'] ?? '',
        amount: (e['amount'] ?? 0).toDouble(),
        currency: e['currency'] ?? 'USD',
        status: status,
        createdAt: DateTime.parse(e['createdAt'] ?? DateTime.now().toString()),
        completedAt: e['completedAt'] != null
            ? DateTime.parse(e['completedAt'])
            : null,
        transactionId: e['transactionId'],
        paymentMethod: e['paymentMethod'],
      );
    }).toList();
  }

  Future<PaymentEntity?> verifyPayment(String courseId, String token) async {
    try {
      final data = await remoteDataSource.verifyPayment(courseId, token);
      String statusString = (data['status'] ?? 'pending')
          .toString()
          .toLowerCase();
      PaymentStatus status = PaymentStatus.pending;

      if (statusString == 'completed')
        status = PaymentStatus.completed;
      else if (statusString == 'failed')
        status = PaymentStatus.failed;
      else if (statusString == 'cancelled')
        status = PaymentStatus.cancelled;

      return PaymentEntity(
        id: data['id'] ?? '',
        studentId: data['studentId'] ?? '',
        courseId: data['courseId'] ?? '',
        amount: (data['amount'] ?? 0).toDouble(),
        currency: data['currency'] ?? 'USD',
        status: status,
        createdAt: DateTime.parse(
          data['createdAt'] ?? DateTime.now().toString(),
        ),
        completedAt: data['completedAt'] != null
            ? DateTime.parse(data['completedAt'])
            : null,
        transactionId: data['transactionId'],
        paymentMethod: data['paymentMethod'],
      );
    } catch (e) {
      return null;
    }
  }
}
