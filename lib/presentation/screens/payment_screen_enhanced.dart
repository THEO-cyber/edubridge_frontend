import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import '../../core/secure_storage.dart';
import '../../data/datasources/payment_remote_data_source.dart';
import '../blocs/payment_bloc.dart';

const _kPrimary = Color(0xFF1A237E);

class PaymentScreenEnhanced extends StatefulWidget {
  final String courseId;
  final String courseName;
  final double price;

  const PaymentScreenEnhanced({
    super.key,
    required this.courseId,
    required this.courseName,
    required this.price,
  });

  @override
  State<PaymentScreenEnhanced> createState() => _PaymentScreenEnhancedState();
}

class _PaymentScreenEnhancedState extends State<PaymentScreenEnhanced> {
  final _couponController = TextEditingController();
  final _paymentDs = PaymentRemoteDataSource();

  double _discount = 0;
  double _discountPercent = 0;
  bool _couponLoading = false;
  bool _couponApplied = false;
  String? _couponError;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  double get _finalPrice => (widget.price - _discount).clamp(0, double.infinity);

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) {
      setState(() => _couponError = 'Enter a promo code first');
      return;
    }
    setState(() {
      _couponLoading = true;
      _couponError = null;
    });
    try {
      final token = await SecureStorage.getToken();
      if (token == null || token.isEmpty) throw Exception('Not authenticated');

      final result = await _paymentDs.applyCoupon(code, widget.courseId, token);

      // Backend may return discountAmount, discountPercentage, finalPrice, etc.
      double pd(dynamic v) => double.tryParse((v ?? '0').toString()) ?? 0.0;
      final discountAmount =
          pd(result['discountAmount'] ?? result['discount']);
      final discountPct =
          pd(result['discountPercentage'] ?? result['percentage']);
      final rawFinal = pd(result['finalPrice'] ?? result['total']);
      final finalPrice =
          rawFinal == 0.0 ? (widget.price - discountAmount) : rawFinal;

      setState(() {
        _discount = widget.price - finalPrice;
        _discountPercent = discountPct;
        _couponApplied = true;
        _couponLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              discountPct > 0
                  ? 'Coupon applied! ${discountPct.toStringAsFixed(0)}% off'
                  : 'Coupon applied!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _couponError =
            e.toString().replaceFirst('Exception: ', '');
        _couponLoading = false;
      });
    }
  }

  void _removeCoupon() {
    setState(() {
      _discount = 0;
      _discountPercent = 0;
      _couponApplied = false;
      _couponError = null;
      _couponController.clear();
    });
  }

  Future<void> _processPayment(Map<String, dynamic> paymentIntent) async {
    try {
      final clientSecret =
          (paymentIntent['clientSecret'] ??
              paymentIntent['client_secret'] ??
              '').toString();

      if (clientSecret.isEmpty) {
        throw Exception('Payment setup failed — missing client secret.');
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'EduBridge',
          style: ThemeMode.light,
          appearance: PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: _kPrimary,
            ),
          ),
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      if (mounted) {
        Navigator.of(context).pop(true); // return success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful! You are now enrolled.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) return; // user dismissed sheet
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Payment failed: ${e.error.localizedMessage ?? e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment error: ${e.toString().replaceFirst("Exception: ", "")}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocListener<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is PaymentSuccess) {
            _processPayment(state.paymentIntent);
          } else if (state is PaymentFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _OrderSummaryCard(
                courseName: widget.courseName,
                price: widget.price,
              ),
              const SizedBox(height: 16),
              _CouponSection(
                controller: _couponController,
                applied: _couponApplied,
                loading: _couponLoading,
                error: _couponError,
                onApply: _applyCoupon,
                onRemove: _removeCoupon,
              ),
              const SizedBox(height: 16),
              _PriceSummaryCard(
                subtotal: widget.price,
                discount: _discount,
                discountPercent: _discountPercent,
                finalPrice: _finalPrice,
              ),
              const SizedBox(height: 24),
              _PayButton(finalPrice: _finalPrice, courseId: widget.courseId),
              const SizedBox(height: 16),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline,
                        size: 14, color: Colors.blueGrey[400]),
                    const SizedBox(width: 4),
                    Text(
                      'Payments secured by Stripe',
                      style: TextStyle(
                          fontSize: 12, color: Colors.blueGrey[400]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  final String courseName;
  final double price;
  const _OrderSummaryCard({required this.courseName, required this.price});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Order Summary',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.menu_book,
                      color: _kPrimary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    courseName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
                Text(
                  '₦${price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _kPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CouponSection extends StatelessWidget {
  final TextEditingController controller;
  final bool applied;
  final bool loading;
  final String? error;
  final VoidCallback onApply;
  final VoidCallback onRemove;

  const _CouponSection({
    required this.controller,
    required this.applied,
    required this.loading,
    required this.error,
    required this.onApply,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Promo Code',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            if (applied)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '"${controller.text}" applied',
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                    TextButton(
                      onPressed: onRemove,
                      child: const Text('Remove',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'e.g. SAVE20',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: Colors.blueGrey.shade300),
                        ),
                        errorText: error,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: loading ? null : onApply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Apply'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PriceSummaryCard extends StatelessWidget {
  final double subtotal;
  final double discount;
  final double discountPercent;
  final double finalPrice;

  const _PriceSummaryCard({
    required this.subtotal,
    required this.discount,
    required this.discountPercent,
    required this.finalPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _row('Subtotal', '₦${subtotal.toStringAsFixed(2)}'),
            if (discount > 0) ...[
              const SizedBox(height: 8),
              _row(
                'Discount${discountPercent > 0 ? " (${discountPercent.toStringAsFixed(0)}%)" : ""}',
                '-₦${discount.toStringAsFixed(2)}',
                valueColor: Colors.green,
              ),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1),
            ),
            _row(
              'Total',
              '₦${finalPrice.toStringAsFixed(2)}',
              bold: true,
              valueColor: _kPrimary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value,
      {bool bold = false, Color? valueColor}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontSize: bold ? 17 : 14,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value,
            style: style.copyWith(color: valueColor ?? Colors.black87)),
      ],
    );
  }
}

class _PayButton extends StatelessWidget {
  final double finalPrice;
  final String courseId;

  const _PayButton({required this.finalPrice, required this.courseId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentBloc, PaymentState>(
      builder: (context, state) {
        final isLoading = state is PaymentLoading;
        return SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: isLoading
                ? null
                : () async {
                    final token = await SecureStorage.getToken();
                    if (token == null || token.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Authentication required')),
                      );
                      return;
                    }
                    context.read<PaymentBloc>().add(
                          CreatePaymentIntentEvent(courseId, token),
                        );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 3,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    'Pay ₦${finalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 17),
                  ),
          ),
        );
      },
    );
  }
}
