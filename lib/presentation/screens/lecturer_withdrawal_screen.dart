import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../constants/api_constants.dart';
import '../../core/secure_storage.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/datasources/profile_remote_data_source.dart';

const _kPrimary = Color(0xFF1A237E);

class LecturerWithdrawalScreen extends StatefulWidget {
  const LecturerWithdrawalScreen({super.key});

  @override
  State<LecturerWithdrawalScreen> createState() =>
      _LecturerWithdrawalScreenState();
}

class _LecturerWithdrawalScreenState
    extends State<LecturerWithdrawalScreen> {
  final _amountCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  bool _loading = true;
  bool _submitting = false;
  double _availableBalance = 0;
  List<Map<String, dynamic>> _history = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _accountCtrl.dispose();
    _bankCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await SecureStorage.getToken();
      if (token == null || token.isEmpty) throw Exception('Not authenticated');

      final ds = ProfileRemoteDataSource(AuthRemoteDataSource());
      final analytics = await ds.fetchInstructorAnalytics(token);
      _availableBalance =
          double.tryParse((analytics['totalRevenue'] ?? 0).toString()) ?? 0;

      // Fetch payment history as withdrawal record
      final response = await http.get(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.paymentHistory),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data is List ? data : (data['payments'] ?? []);
        _history = List<Map<String, dynamic>>.from(list);
      }

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _requestWithdrawal() async {
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amount <= 0) {
      _snack('Enter a valid withdrawal amount', Colors.orange);
      return;
    }
    if (amount > _availableBalance) {
      _snack('Amount exceeds available balance', Colors.red);
      return;
    }
    if (_accountCtrl.text.trim().isEmpty ||
        _bankCtrl.text.trim().isEmpty ||
        _nameCtrl.text.trim().isEmpty) {
      _snack('Fill in all bank account details', Colors.orange);
      return;
    }

    setState(() => _submitting = true);
    try {
      final token = await SecureStorage.getToken();
      if (token == null || token.isEmpty) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/payments/withdraw'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': amount,
          'accountNumber': _accountCtrl.text.trim(),
          'bankName': _bankCtrl.text.trim(),
          'accountName': _nameCtrl.text.trim(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _amountCtrl.clear();
        _snack('Withdrawal request submitted! Processing in 1-3 business days.',
            Colors.green);
        await _load();
      } else {
        String msg = 'Withdrawal failed';
        try {
          final body = jsonDecode(response.body);
          if (body['message'] is String) msg = body['message'] as String;
        } catch (_) {}
        _snack(msg, Colors.red);
      }
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), Colors.red);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Withdraw Earnings'),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _kPrimary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: Colors.red.shade300),
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: const TextStyle(color: Colors.black54)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                          onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BalanceCard(balance: _availableBalance),
                      const SizedBox(height: 20),
                      _WithdrawalForm(
                        amountCtrl: _amountCtrl,
                        accountCtrl: _accountCtrl,
                        bankCtrl: _bankCtrl,
                        nameCtrl: _nameCtrl,
                        maxAmount: _availableBalance,
                        submitting: _submitting,
                        onSubmit: _requestWithdrawal,
                      ),
                      if (_history.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text('Payment History',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 10),
                        ..._history.take(10).map((tx) => _TxTile(tx: tx)),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double balance;
  const _BalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kPrimary, Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Available Balance',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          Text(
            '₦${balance.toStringAsFixed(2)}',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 32),
          ),
          const SizedBox(height: 4),
          const Text('Total earnings from your courses',
              style: TextStyle(color: Colors.white60, fontSize: 12)),
        ],
      ),
    );
  }
}

class _WithdrawalForm extends StatelessWidget {
  final TextEditingController amountCtrl;
  final TextEditingController accountCtrl;
  final TextEditingController bankCtrl;
  final TextEditingController nameCtrl;
  final double maxAmount;
  final bool submitting;
  final VoidCallback onSubmit;

  const _WithdrawalForm({
    required this.amountCtrl,
    required this.accountCtrl,
    required this.bankCtrl,
    required this.nameCtrl,
    required this.maxAmount,
    required this.submitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Request Withdrawal',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 16),
            _input(amountCtrl, 'Amount (₦)',
                icon: Icons.payments_outlined,
                type: const TextInputType.numberWithOptions(decimal: true),
                suffix: TextButton(
                  onPressed: () => amountCtrl.text =
                      maxAmount.toStringAsFixed(2),
                  child: const Text('MAX',
                      style: TextStyle(
                          color: _kPrimary, fontWeight: FontWeight.bold)),
                )),
            const SizedBox(height: 12),
            _input(accountCtrl, 'Account Number',
                icon: Icons.account_balance,
                type: TextInputType.number),
            const SizedBox(height: 12),
            _input(bankCtrl, 'Bank Name',
                icon: Icons.business_outlined),
            const SizedBox(height: 12),
            _input(nameCtrl, 'Account Name',
                icon: Icons.person_outline),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: submitting ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Request Withdrawal',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(TextEditingController ctrl, String label,
      {IconData? icon,
      TextInputType type = TextInputType.text,
      Widget? suffix}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
        suffixIcon: suffix,
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF5F6FA),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.blueGrey.shade200)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.blueGrey.shade200)),
      ),
    );
  }
}

class _TxTile extends StatelessWidget {
  final Map<String, dynamic> tx;
  const _TxTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final amount =
        double.tryParse((tx['amount'] ?? 0).toString()) ?? 0;
    final course = (tx['courseName'] ??
            tx['course']?['title'] ??
            'Payment')
        .toString();
    final status = (tx['status'] ?? 'completed').toString();
    final isPositive = status == 'completed' || status == 'succeeded';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child:
            const Icon(Icons.payments, color: Colors.green, size: 20),
      ),
      title: Text(course,
          style: const TextStyle(fontSize: 13),
          overflow: TextOverflow.ellipsis),
      trailing: Text(
        '₦${amount.toStringAsFixed(2)}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isPositive ? Colors.green : Colors.red,
        ),
      ),
    );
  }
}
