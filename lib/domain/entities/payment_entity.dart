enum PaymentStatus { pending, completed, failed, cancelled }

class PaymentEntity {
  final String id;
  final String studentId;
  final String courseId;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? transactionId;
  final String? paymentMethod;

  PaymentEntity({
    required this.id,
    required this.studentId,
    required this.courseId,
    required this.amount,
    this.currency = 'XAF',
    this.status = PaymentStatus.pending,
    required this.createdAt,
    this.completedAt,
    this.transactionId,
    this.paymentMethod,
  });
}
