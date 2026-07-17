import 'dart:convert';
import 'package:flutter/material.dart';
import '../../constants/api_constants.dart';
import '../../core/cache/app_cache.dart';
import '../../core/http_utils.dart';
import '../../core/secure_storage.dart';

const _kPrimary = Color(0xFF1A237E);

class LecturerWithdrawalScreen extends StatefulWidget {
  const LecturerWithdrawalScreen({super.key});

  @override
  State<LecturerWithdrawalScreen> createState() =>
      _LecturerWithdrawalScreenState();
}

class _LecturerWithdrawalScreenState extends State<LecturerWithdrawalScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  bool _loading = true;
  String? _error;

  // Dashboard
  double _availableBalance = 0;
  double _pendingAmount = 0;
  double _totalPaid = 0;
  bool _stripeConnected = false; // true once a MoMo/Orange payout number is saved
  String _payoutPhone = '';

  // Request payout
  final _amountCtrl = TextEditingController();
  bool _submitting = false;

  // History
  List<Map<String, dynamic>> _history = [];
  bool _connectLoading = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<String?> _token() async {
    final t = await SecureStorage.getToken();
    if (t == null || t.isEmpty) throw Exception('Not authenticated');
    return t;
  }

  void _applyDashboardData(Map<String, dynamic> d) {
    _availableBalance =
        double.tryParse((d['availableBalance'] ?? d['balance'] ?? 0).toString()) ?? 0;
    _pendingAmount =
        double.tryParse((d['pendingAmount'] ?? d['pending'] ?? 0).toString()) ?? 0;
    _totalPaid =
        double.tryParse((d['totalPaid'] ?? d['totalWithdrawn'] ?? 0).toString()) ?? 0;
    _stripeConnected = d['payoutConnected'] == true ||
        (d['payoutPhone'] != null && d['payoutPhone'].toString().isNotEmpty);
    _payoutPhone = (d['payoutPhone'] ?? '').toString();
  }

  Future<void> _load() async {
    // Serve cache immediately — no spinner on revisit
    final cachedDash = AppCache.get<Map<String, dynamic>>('payout_dashboard');
    final cachedHist = AppCache.get<List<Map<String, dynamic>>>('payout_history');
    if (cachedDash != null) {
      _applyDashboardData(cachedDash);
      if (cachedHist != null) _history = cachedHist;
      setState(() => _loading = false);
    } else {
      setState(() { _loading = true; _error = null; });
    }

    try {
      final token = await _token();
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final dashRes = await apiGet(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.payoutsDashboard}'),
        headers: headers,
      );

      if (dashRes.statusCode == 200) {
        final data = jsonDecode(dashRes.body);
        final d = (data is Map ? (data['data'] ?? data) : {}) as Map<String, dynamic>;
        AppCache.set('payout_dashboard', d);
        _applyDashboardData(d);
      }

      final histRes = await apiGet(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.payoutsHistory}'),
        headers: headers,
      );
      if (histRes.statusCode == 200) {
        final data = jsonDecode(histRes.body);
        final list = data is List
            ? data
            : (data['data'] ?? data['payouts'] ?? data['history'] ?? []);
        _history = List<Map<String, dynamic>>.from(list is List ? list : []);
        AppCache.set('payout_history', _history);
      }

      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted && cachedDash == null) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _connectStripe() async {
    // Collect the instructor's MoMo/Orange Money number and save it as the
    // payout destination (Nkwa disbursements go to this number).
    final controller = TextEditingController(text: _payoutPhone);
    final phone = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Payout number'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.smartphone),
            hintText: '6XXXXXXXX (MoMo / Orange)',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (phone == null || phone.isEmpty) return;

    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (!(digits.length == 9 || (digits.startsWith('237') && digits.length == 12))) {
      _snack('Enter a valid MoMo/Orange number (9 digits)', Colors.orange);
      return;
    }

    setState(() => _connectLoading = true);
    try {
      final token = await _token();
      final res = await apiPost(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.payoutsConnect}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'phoneNumber': phone}),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        _snack('Payout number saved', Colors.green);
        await _load();
      } else {
        _snack('Failed to save payout number', Colors.red);
      }
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), Colors.red);
    } finally {
      if (mounted) setState(() => _connectLoading = false);
    }
  }

  Future<void> _requestPayout() async {
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amount <= 0) {
      _snack('Enter a valid amount', Colors.orange);
      return;
    }
    if (amount > _availableBalance) {
      _snack('Amount exceeds available balance', Colors.red);
      return;
    }
    if (!_stripeConnected) {
      _snack('Add your MoMo/Orange payout number first', Colors.orange);
      return;
    }

    setState(() => _submitting = true);
    try {
      final token = await _token();
      final res = await apiPost(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.payoutsRequest}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'amount': amount}),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        _amountCtrl.clear();
        AppCache.invalidate('payout_dashboard');
        AppCache.invalidate('payout_history');
        _snack('Payout requested! Processing in 1-3 business days.', Colors.green);
        await _load();
        _tabs.animateTo(1);
      } else {
        String msg = 'Payout request failed';
        try {
          final b = jsonDecode(res.body);
          if (b is Map) msg = (b['message'] ?? b['error'] ?? msg).toString();
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Earnings & Payouts'),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Request Payout'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : _error != null
              ? _ErrorView(error: _error!, onRetry: _load)
              : Column(
                  children: [
                    _DashboardHeader(
                      available: _availableBalance,
                      pending: _pendingAmount,
                      totalPaid: _totalPaid,
                    ),
                    if (!_stripeConnected)
                      _StripeConnectBanner(
                        loading: _connectLoading,
                        onConnect: _connectStripe,
                      ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabs,
                        children: [
                          _RequestTab(
                            amountCtrl: _amountCtrl,
                            maxAmount: _availableBalance,
                            submitting: _submitting,
                            stripeConnected: _stripeConnected,
                            onSubmit: _requestPayout,
                          ),
                          _HistoryTab(history: _history),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

// ── Dashboard header ──────────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  final double available;
  final double pending;
  final double totalPaid;
  const _DashboardHeader(
      {required this.available, required this.pending, required this.totalPaid});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kPrimary, Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _Stat(label: 'Available', value: available, color: Colors.greenAccent),
          _vDivider(),
          _Stat(label: 'Pending', value: pending, color: Colors.amberAccent),
          _vDivider(),
          _Stat(label: 'Total Paid', value: totalPaid, color: Colors.white70),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(
      width: 1, height: 40, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 4));
}

class _Stat extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('FCFA ${value.toStringAsFixed(0)}',
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}

// ── Stripe connect banner ─────────────────────────────────────────────────────

class _StripeConnectBanner extends StatelessWidget {
  final bool loading;
  final VoidCallback onConnect;
  const _StripeConnectBanner({required this.loading, required this.onConnect});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.amber.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade700),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Add your MoMo/Orange Money number to receive payouts',
              style: TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : ElevatedButton(
                  onPressed: onConnect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Connect', style: TextStyle(fontSize: 12)),
                ),
        ],
      ),
    );
  }
}

// ── Request payout tab ────────────────────────────────────────────────────────

class _RequestTab extends StatelessWidget {
  final TextEditingController amountCtrl;
  final double maxAmount;
  final bool submitting;
  final bool stripeConnected;
  final VoidCallback onSubmit;

  const _RequestTab({
    required this.amountCtrl,
    required this.maxAmount,
    required this.submitting,
    required this.stripeConnected,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Request a Payout',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              Text(
                'Available: FCFA ${maxAmount.toStringAsFixed(0)}',
                style: TextStyle(color: Colors.green.shade700, fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount (FCFA)',
                  prefixIcon: const Icon(Icons.payments_outlined),
                  suffixIcon: TextButton(
                    onPressed: () =>
                        amountCtrl.text = maxAmount.toStringAsFixed(0),
                    child: const Text('MAX',
                        style: TextStyle(
                            color: _kPrimary, fontWeight: FontWeight.bold)),
                  ),
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
              ),
              const SizedBox(height: 16),
              if (!stripeConnected)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Add your MoMo/Orange Money payout number before requesting a payout.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: submitting || !stripeConnected ? null : onSubmit,
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
                      : const Text('Request Payout',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Payouts are sent to your MoMo / Orange Money number.',
                  style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── History tab ───────────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  final List<Map<String, dynamic>> history;
  const _HistoryTab({required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 56, color: Colors.blueGrey.shade200),
            const SizedBox(height: 12),
            Text('No payouts yet',
                style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 15)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) => _PayoutTile(tx: history[i]),
    );
  }
}

class _PayoutTile extends StatelessWidget {
  final Map<String, dynamic> tx;
  const _PayoutTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse((tx['amount'] ?? 0).toString()) ?? 0;
    final status = (tx['status'] ?? 'pending').toString().toLowerCase();
    final date = tx['createdAt'] ?? tx['requestedAt'] ?? '';

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'completed':
      case 'paid':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'failed':
        statusColor = Colors.red;
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = Colors.blueGrey;
        statusIcon = Icons.info_outline;
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: CircleAvatar(
        backgroundColor: statusColor.withValues(alpha: 0.12),
        child: Icon(statusIcon, color: statusColor, size: 20),
      ),
      title: Text(
        'FCFA ${amount.toStringAsFixed(0)}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: date.isNotEmpty
          ? Text(date.toString().split('T').first,
              style: const TextStyle(fontSize: 12))
          : null,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(status.toUpperCase(),
            style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 11)),
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
