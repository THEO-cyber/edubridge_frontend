import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/payment_remote_data_source.dart';
import '../../data/repositories/payment_repository_impl.dart';
import '../../domain/usecases/create_payment_intent_usecase.dart';
import 'payment_bloc.dart';

class PaymentBlocProvider extends StatelessWidget {
  final Widget child;
  const PaymentBlocProvider({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PaymentBloc(
        createPaymentIntentUseCase: CreatePaymentIntentUseCase(
          PaymentRepositoryImpl(PaymentRemoteDataSource()),
        ),
      ),
      child: child,
    );
  }
}
