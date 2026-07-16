import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_payment_intent_usecase.dart';
import '../../data/repositories/payment_repository_impl.dart';

abstract class PaymentEvent {}

class CreatePaymentIntentEvent extends PaymentEvent {
  final String courseId;
  final String token;
  final String phoneNumber;
  final String? couponCode;
  CreatePaymentIntentEvent(
    this.courseId,
    this.token, {
    required this.phoneNumber,
    this.couponCode,
  });
}

class FetchPaymentHistoryEvent extends PaymentEvent {
  final String token;
  FetchPaymentHistoryEvent(this.token);
}

abstract class PaymentState {}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentSuccess extends PaymentState {
  final Map<String, dynamic> paymentIntent;
  PaymentSuccess(this.paymentIntent);
}

class PaymentHistoryLoaded extends PaymentState {
  final List<Map<String, dynamic>> payments;
  PaymentHistoryLoaded(this.payments);
}

class PaymentFailure extends PaymentState {
  final String message;
  PaymentFailure(this.message);
}

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final CreatePaymentIntentUseCase createPaymentIntentUseCase;
  final PaymentRepositoryImpl? paymentRepository;

  PaymentBloc({
    required this.createPaymentIntentUseCase,
    this.paymentRepository,
  }) : super(PaymentInitial()) {
    on<CreatePaymentIntentEvent>((event, emit) async {
      emit(PaymentLoading());
      try {
        final intent = await createPaymentIntentUseCase(
          event.courseId,
          event.token,
          phoneNumber: event.phoneNumber,
          couponCode: event.couponCode,
        );
        emit(PaymentSuccess(intent));
      } catch (e) {
        emit(PaymentFailure(e.toString()));
      }
    });

    on<FetchPaymentHistoryEvent>((event, emit) async {
      emit(PaymentLoading());
      try {
        if (paymentRepository != null) {
          final payments = await paymentRepository!.fetchPaymentHistory(
            event.token,
          );
          emit(PaymentHistoryLoaded(payments));
        } else {
          emit(PaymentFailure('Payment repository not initialized'));
        }
      } catch (e) {
        emit(PaymentFailure(e.toString()));
      }
    });
  }
}
