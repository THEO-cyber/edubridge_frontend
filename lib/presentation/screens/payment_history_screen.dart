import 'package:flutter/material.dart';
import '../../core/secure_storage.dart';
import '../../core/money.dart';
import '../../data/datasources/payment_remote_data_source.dart';

const _kNavy = Color(0xFF1A237E);
const _kBlue = Color(0xFF1976D2);

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final _ds = PaymentRemoteDataSource();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _payments = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await SecureStorage.getToken();
      if (token == null || token.isEmpty) throw Exception('Not authenticated');
      final data = await _ds.fetchPaymentHistory(token);
      if (mounted) setState(() => _payments = data);
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            e.toString().replaceAll('Exception: ', '').replaceAll('ApiException: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Payment History'),
        backgroundColor: _kNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kNavy))
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _load)
              : _payments.isEmpty
                  ? _EmptyState()
                  : _PaymentList(payments: _payments),
    );
  }
}

class _PaymentList extends StatelessWidget {
  final List<Map<String, dynamic>> payments;
  const _PaymentList({required this.payments});

  @override
  Widget build(BuildContext context) {
    // Summary totals
    double total = 0;
    int successCount = 0;
    for (final p in payments) {
      final status = (p['status'] ?? '').toString().toLowerCase();
      final amount = (p['amount'] ?? p['finalAmount'] ?? 0);
      if (status == 'succeeded' || status == 'completed' || status == 'paid') {
        total += (amount is num ? amount : 0).toDouble();
        successCount++;
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary card
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kNavy, _kBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: 'Total Spent',
                  value: Money.xaf(total),
                  icon: Icons.payments_rounded,
                ),
              ),
              Container(
                  width: 1, height: 48, color: Colors.white24),
              Expanded(
                child: _SummaryItem(
                  label: 'Purchases',
                  value: '$successCount',
                  icon: Icons.shopping_bag_rounded,
                ),
              ),
              Container(
                  width: 1, height: 48, color: Colors.white24),
              Expanded(
                child: _SummaryItem(
                  label: 'All Transactions',
                  value: '${payments.length}',
                  icon: Icons.receipt_long_rounded,
                ),
              ),
            ],
          ),
        ),

        // Payment cards
        ...payments.map((p) => _PaymentCard(payment: p)),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _SummaryItem(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        const SizedBox(height: 2),
        Text(label,
            style:
                const TextStyle(color: Colors.white70, fontSize: 11),
            textAlign: TextAlign.center),
      ],
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final Map<String, dynamic> payment;
  const _PaymentCard({required this.payment});

  String get _statusLabel {
    final s = (payment['status'] ?? '').toString().toLowerCase();
    if (s == 'succeeded' || s == 'completed' || s == 'paid') return 'Paid';
    if (s == 'pending') return 'Pending';
    if (s == 'failed') return 'Failed';
    if (s == 'refunded') return 'Refunded';
    return s.isEmpty ? 'Unknown' : s[0].toUpperCase() + s.substring(1);
  }

  Color get _statusColor {
    final s = (payment['status'] ?? '').toString().toLowerCase();
    if (s == 'succeeded' || s == 'completed' || s == 'paid') return Colors.green;
    if (s == 'pending') return Colors.orange;
    if (s == 'refunded') return Colors.blue;
    return Colors.red;
  }

  String get _formattedDate {
    try {
      final raw = payment['createdAt'] ?? payment['created_at'] ?? '';
      if (raw.toString().isEmpty) return '—';
      final dt = DateTime.parse(raw.toString()).toLocal();
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return '—';
    }
  }

  String get _courseName {
    final course = payment['course'];
    if (course is Map) {
      return (course['title'] ?? course['name'] ?? 'Course').toString();
    }
    return (payment['courseName'] ?? payment['description'] ?? 'Course')
        .toString();
  }

  String get _amount {
    final raw = payment['amount'] ?? payment['finalAmount'] ?? 0;
    final num value = raw is num ? raw : num.tryParse('$raw') ?? 0;
    // XAF is zero-decimal — amounts are stored as whole francs, not cents.
    return Money.xaf(value);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _statusLabel == 'Paid'
                    ? Icons.check_circle_outline_rounded
                    : _statusLabel == 'Refunded'
                        ? Icons.undo_rounded
                        : _statusLabel == 'Pending'
                            ? Icons.hourglass_empty_rounded
                            : Icons.error_outline_rounded,
                color: _statusColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _courseName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formattedDate,
                    style: TextStyle(
                        fontSize: 12, color: Colors.blueGrey.shade400),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Amount + status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _amount,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _kNavy),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _statusColor),
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

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 72, color: Colors.blueGrey.shade200),
          const SizedBox(height: 16),
          const Text('No payments yet',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Your payment history will appear here.',
              style: TextStyle(color: Colors.blueGrey.shade400)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(backgroundColor: _kNavy),
              child: const Text('Retry',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
