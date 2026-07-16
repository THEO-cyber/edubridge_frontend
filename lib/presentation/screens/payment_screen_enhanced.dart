import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/secure_storage.dart';
import '../../core/money.dart';
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
  final _phoneController = TextEditingController();
  final _paymentDs = PaymentRemoteDataSource();

  double _discount = 0;
  double _discountPercent = 0;
  bool _couponLoading = false;
  bool _couponApplied = false;
  String? _couponError;

  @override
  void dispose() {
    _couponController.dispose();
    _phoneController.dispose();
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

  /// After the collection is created, the customer approves the charge on their
  /// phone (MoMo/Orange PIN prompt). We poll the backend until the payment is
  /// confirmed (COMPLETED) or fails.
  Future<void> _awaitMomoConfirmation(Map<String, dynamic> intent) async {
    final paymentId = (intent['paymentId'] ?? '').toString();
    if (paymentId.isEmpty) {
      _showError('Could not start the payment. Please try again.');
      return;
    }

    final operator = (intent['operator'] ?? '').toString().toUpperCase();
    _showConfirmSheet(operator);

    final token = await SecureStorage.getToken();
    if (token == null || token.isEmpty) {
      _finishConfirmation();
      _showError('Authentication required.');
      return;
    }

    // Poll for up to ~2 minutes (24 tries * 5s).
    String status = 'PENDING';
    for (var i = 0; i < 24; i++) {
      await Future.delayed(const Duration(seconds: 5));
      if (!mounted) return;
      try {
        status = await _paymentDs.getPaymentStatus(paymentId, token);
      } catch (_) {
        continue; // transient error — keep polling
      }
      if (status == 'COMPLETED' || status == 'FAILED') break;
    }

    if (!mounted) return;
    _finishConfirmation();

    if (status == 'COMPLETED') {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment successful! You are now enrolled.'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (status == 'FAILED') {
      _showError('Payment failed or was declined. Please try again.');
    } else {
      _showError('Still waiting for confirmation. Check "My Courses" shortly.');
    }
  }

  void _finishConfirmation() {
    // Close the confirm sheet if it is open.
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();
  }

  void _showConfirmSheet(String operator) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Confirm on your phone'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: _kPrimary),
            const SizedBox(height: 20),
            Text(
              operator.isNotEmpty
                  ? 'A $operator Mobile Money prompt has been sent to your phone. Enter your PIN to approve the payment.'
                  : 'A Mobile Money prompt has been sent to your phone. Enter your PIN to approve the payment.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
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
            _awaitMomoConfirmation(state.paymentIntent);
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
              const SizedBox(height: 16),
              _PhoneField(controller: _phoneController),
              const SizedBox(height: 24),
              _PayButton(
                finalPrice: _finalPrice,
                courseId: widget.courseId,
                phoneController: _phoneController,
                couponCode:
                    _couponApplied ? _couponController.text.trim() : null,
              ),
              const SizedBox(height: 16),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline,
                        size: 14, color: Colors.blueGrey[400]),
                    const SizedBox(width: 4),
                    Text(
                      'Secured by Nkwa — MoMo & Orange Money',
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
                  Money.xaf(price),
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
            _row('Subtotal', Money.xaf(subtotal)),
            if (discount > 0) ...[
              const SizedBox(height: 8),
              _row(
                'Discount${discountPercent > 0 ? " (${discountPercent.toStringAsFixed(0)}%)" : ""}',
                '-${Money.xaf(discount)}',
                valueColor: Colors.green,
              ),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1),
            ),
            _row(
              'Total',
              Money.xaf(finalPrice),
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

class _PhoneField extends StatelessWidget {
  final TextEditingController controller;
  const _PhoneField({required this.controller});

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
            const Text('Mobile Money number',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            const Text(
              'Enter your MTN MoMo or Orange Money number. You will approve the payment on your phone.',
              style: TextStyle(fontSize: 12, color: Colors.blueGrey),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                LengthLimitingTextInputFormatter(13),
              ],
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.smartphone, color: _kPrimary),
                hintText: '6XXXXXXXX',
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.blueGrey.shade300),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PayButton extends StatelessWidget {
  final double finalPrice;
  final String courseId;
  final TextEditingController phoneController;
  final String? couponCode;

  const _PayButton({
    required this.finalPrice,
    required this.courseId,
    required this.phoneController,
    this.couponCode,
  });

  bool _validPhone(String v) {
    final digits = v.replaceAll(RegExp(r'[^\d]'), '');
    // Accept a 9-digit local Cameroon number or a 237-prefixed one.
    return digits.length == 9 || (digits.startsWith('237') && digits.length == 12);
  }

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
                    final phone = phoneController.text.trim();
                    if (!_validPhone(phone)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Enter a valid MoMo/Orange number (9 digits)'),
                        ),
                      );
                      return;
                    }
                    final token = await SecureStorage.getToken();
                    if (!context.mounted) return;
                    if (token == null || token.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Authentication required')),
                      );
                      return;
                    }
                    context.read<PaymentBloc>().add(
                          CreatePaymentIntentEvent(
                            courseId,
                            token,
                            phoneNumber: phone,
                            couponCode: couponCode,
                          ),
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
                    'Pay ${Money.xaf(finalPrice)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 17),
                  ),
          ),
        );
      },
    );
  }
}
