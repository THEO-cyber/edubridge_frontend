import 'package:edubridge/presentation/screens/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/secure_storage.dart';
import '../blocs/payment_bloc.dart';

class PaymentScreen extends StatelessWidget {
  final String courseId;
  const PaymentScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: FutureBuilder<String?>(
        future: SecureStorage.getToken(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final token = snapshot.data;
          if (token == null) {
            // Not logged in, redirect to AuthScreen
            Future.microtask(() {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const AuthScreen()),
              );
            });
            return const Center(child: CircularProgressIndicator());
          }
          return BlocConsumer<PaymentBloc, PaymentState>(
            listener: (context, state) {
              if (state is PaymentSuccess) {
                // TODO: Integrate with Stripe payment sheet using state.paymentIntent
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Payment intent created. Proceed with Stripe.',
                    ),
                  ),
                );
              } else if (state is PaymentFailure) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.message)));
              }
            },
            builder: (context, state) {
              if (state is PaymentLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return Center(
                child: ElevatedButton(
                  onPressed: () {
                    context.read<PaymentBloc>().add(
                      CreatePaymentIntentEvent(courseId, token),
                    );
                  },
                  child: const Text('Pay with Stripe'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
