import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_payment_intent_usecase.dart';

abstract class PaymentEvent {}

class CreatePaymentIntentEvent extends PaymentEvent {
  final String courseId;
  final String token;
  CreatePaymentIntentEvent(this.courseId, this.token);
}

abstract class PaymentState {}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentSuccess extends PaymentState {
  final Map<String, dynamic> paymentIntent;
  PaymentSuccess(this.paymentIntent);
}

class PaymentFailure extends PaymentState {
  final String message;
  PaymentFailure(this.message);
}

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final CreatePaymentIntentUseCase createPaymentIntentUseCase;
  PaymentBloc({required this.createPaymentIntentUseCase})
    : super(PaymentInitial()) {
    on<CreatePaymentIntentEvent>((event, emit) async {
      emit(PaymentLoading());
      try {
        final intent = await createPaymentIntentUseCase(
          event.courseId,
          event.token,
        );
        emit(PaymentSuccess(intent));
      } catch (e) {
        emit(PaymentFailure(e.toString()));
      }
    });
  }
}
