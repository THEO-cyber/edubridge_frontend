import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/payment_bloc.dart';
import '../../core/secure_storage.dart';

class PaymentScreenEnhanced extends StatefulWidget {
  final String courseId;
  final String courseName;
  final double price;

  const PaymentScreenEnhanced({
    Key? key,
    required this.courseId,
    required this.courseName,
    required this.price,
  }) : super(key: key);

  @override
  State<PaymentScreenEnhanced> createState() => _PaymentScreenEnhancedState();
}

class _PaymentScreenEnhancedState extends State<PaymentScreenEnhanced> {
  String? couponCode;
  double discount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderSummary(),
            const SizedBox(height: 24),
            _buildCouponSection(),
            const SizedBox(height: 24),
            _buildPriceSummary(),
            const SizedBox(height: 24),
            _buildPaymentButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.courseName,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  '\$${widget.price.toStringAsFixed(2)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Promo Code',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (value) => couponCode = value,
                decoration: InputDecoration(
                  hintText: 'Enter promo code',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: _applyCoupon, child: const Text('Apply')),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceSummary() {
    final discountedPrice = widget.price - discount;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtotal', style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  '\$${widget.price.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            if (discount > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Discount',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.green),
                  ),
                  Text(
                    '-\$${discount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '\$${discountedPrice.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentButton() {
    return BlocBuilder<PaymentBloc, PaymentState>(
      builder: (context, state) {
        final isLoading = state is PaymentLoading;
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : _processPayment,
            child: isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Proceed to Payment'),
          ),
        );
      },
    );
  }

  void _applyCoupon() {
    if (couponCode?.isEmpty ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a coupon code')),
      );
      return;
    }
    // Simulate discount
    setState(() {
      discount = widget.price * 0.1; // 10% discount
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Coupon applied! Discount: \$${discount.toStringAsFixed(2)}',
        ),
      ),
    );
  }

  void _processPayment() async {
    final token = await SecureStorage.getToken();
    if (token == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Authentication required')));
      return;
    }

    if (mounted) {
      context.read<PaymentBloc>().add(
        CreatePaymentIntentEvent(widget.courseId, token),
      );
    }
  }
}
