import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/secure_storage.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/datasources/payment_remote_data_source.dart';
import '../../data/datasources/profile_remote_data_source.dart';

const _kPrimary = Color(0xFF1A237E);
const _kBg = Color(0xFFF5F6FA);

class LecturerEarningsScreen extends StatefulWidget {
  const LecturerEarningsScreen({super.key});

  @override
  State<LecturerEarningsScreen> createState() => _LecturerEarningsScreenState();
}

class _LecturerEarningsScreenState extends State<LecturerEarningsScreen> {
  final _paymentDs = PaymentRemoteDataSource();
  late final _profileDs = ProfileRemoteDataSource(AuthRemoteDataSource());

  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _transactions = [];
  Map<String, dynamic> _analytics = {};

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

      final results = await Future.wait([
        _paymentDs.fetchEarnings(token).catchError((_) async =>
            {'transactions': <Map<String, dynamic>>[]}),
        _profileDs.fetchInstructorAnalytics(token).catchError((_) async =>
            <String, dynamic>{}),
      ]);

      final earningsData = results[0];
      final analyticsData = results[1];

      // Merge: earnings endpoint overrides analytics totals if present
      final mergedAnalytics = {
        ...analyticsData,
        if (earningsData['totalEarnings'] != null)
          'totalRevenue': earningsData['totalEarnings'],
        if (earningsData['availableBalance'] != null)
          'availableBalance': earningsData['availableBalance'],
        if (earningsData['pendingBalance'] != null)
          'pendingBalance': earningsData['pendingBalance'],
      };

      // Transactions: prefer earnings endpoint, fall back to payment history
      final rawTx = earningsData['transactions'] ??
          earningsData['earnings'] ??
          earningsData['payouts'];
      final List<Map<String, dynamic>> txList;
      if (rawTx is List && rawTx.isNotEmpty) {
        txList = List<Map<String, dynamic>>.from(rawTx);
      } else {
        txList = await _paymentDs
            .fetchPaymentHistory(token)
            .catchError((_) async => <Map<String, dynamic>>[]);
      }

      setState(() {
        _transactions = txList;
        _analytics = mergedAnalytics;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 160,
            backgroundColor: _kPrimary,
            foregroundColor: Colors.white,
            title: const Text('Earnings & Revenue'),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_kPrimary, Color(0xFF1976D2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
                    child: _loading
                        ? const SizedBox.shrink()
                        : Row(
                            children: [
                              Expanded(
                                child: _HeaderStat(
                                  label: 'Total Revenue',
                                  value: _formatMoney(
                                      _analytics['totalRevenue'] ?? 0),
                                  icon: Icons.account_balance_wallet,
                                ),
                              ),
                              Expanded(
                                child: _HeaderStat(
                                  label: 'Total Students',
                                  value: (_analytics['totalEnrollments'] ??
                                          _analytics['totalStudents'] ??
                                          0)
                                      .toString(),
                                  icon: Icons.people,
                                ),
                              ),
                              Expanded(
                                child: _HeaderStat(
                                  label: 'Courses',
                                  value: (_analytics['totalCourses'] ?? 0)
                                      .toString(),
                                  icon: Icons.menu_book,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _load,
              ),
            ],
          ),

          if (_loading)
            const SliverFillRemaining(
              child: Center(
                  child: CircularProgressIndicator(color: _kPrimary)),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 56, color: Colors.red.shade300),
                    const SizedBox(height: 12),
                    Text(_error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                        onPressed: _load,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: _kPrimary,
                            foregroundColor: Colors.white),
                        child: const Text('Retry')),
                  ],
                ),
              ),
            )
          else ...[
            // Per-course revenue breakdown if available
            if (_analytics['topCourses'] is List &&
                (_analytics['topCourses'] as List).isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Text('Top Performing Courses',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF263238))),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 130,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount:
                        (_analytics['topCourses'] as List).length,
                    itemBuilder: (_, i) {
                      final c = (_analytics['topCourses'] as List)[i]
                          as Map<String, dynamic>;
                      return _CourseRevenueCard(course: c);
                    },
                  ),
                ),
              ),
            ],

            // Transactions header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Recent Transactions',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF263238))),
                    Text(
                      '${_transactions.length} total',
                      style: TextStyle(
                          color: Colors.blueGrey.shade500, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

            if (_transactions.isEmpty)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.symmetric(
                      vertical: 32, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.blueGrey.shade100),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 48, color: Colors.blueGrey.shade300),
                      const SizedBox(height: 12),
                      Text('No transactions yet',
                          style: TextStyle(
                              color: Colors.blueGrey.shade500)),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final tx = _transactions[i];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: _TransactionCard(transaction: tx),
                    );
                  },
                  childCount: _transactions.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ],
      ),
    );
  }

  String _formatMoney(dynamic value) {
    final amount = double.tryParse(value.toString()) ?? 0;
    if (amount >= 1000000) {
      return 'FCFA ${(amount / 1000000).toStringAsFixed(2)}M';
    }
    if (amount >= 1000) {
      return 'FCFA ${(amount / 1000).toStringAsFixed(1)}K';
    }
    return 'FCFA ${amount.toStringAsFixed(2)}';
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _HeaderStat(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white60, size: 16),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }
}

class _CourseRevenueCard extends StatelessWidget {
  final Map<String, dynamic> course;

  const _CourseRevenueCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final title = (course['title'] ?? 'Course').toString();
    final revenue = course['revenue'] ?? course['totalRevenue'] ?? 0;
    final enrollments =
        course['enrollments'] ?? course['totalEnrollments'] ?? 0;

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.menu_book,
                    color: _kPrimary, size: 16),
              ),
              const SizedBox(height: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const Spacer(),
              Text(
                'FCFA ${double.tryParse(revenue.toString())?.toStringAsFixed(0) ?? "0"}',
                style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
              Text('$enrollments enrolled',
                  style: TextStyle(
                      fontSize: 10, color: Colors.blueGrey.shade400)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const _TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(
            (transaction['amount'] ?? transaction['price'] ?? 0)
                .toString()) ??
        0;
    final courseName = (transaction['courseName'] ??
            transaction['course']?['title'] ??
            'Course')
        .toString();
    final studentName = (transaction['studentName'] ??
            transaction['user']?['name'] ??
            transaction['paidBy'] ??
            'Student')
        .toString();
    final status =
        (transaction['status'] ?? 'completed').toString().toLowerCase();
    final createdAt = DateTime.tryParse(
            (transaction['createdAt'] ?? transaction['date'] ?? '')
                .toString()) ??
        DateTime.now();

    final isSuccess = status == 'completed' || status == 'succeeded';
    final statusColor = isSuccess ? Colors.green : Colors.orange;

    return Card(
      elevation: 1,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.payments,
                  color: Colors.green, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(courseName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(
                    'From $studentName',
                    style: TextStyle(
                        fontSize: 12, color: Colors.blueGrey.shade500),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    DateFormat('MMM d, yyyy • HH:mm').format(createdAt),
                    style: TextStyle(
                        fontSize: 11, color: Colors.blueGrey.shade400),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'FCFA ${amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.green),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isSuccess ? 'Paid' : status,
                    style: TextStyle(
                        fontSize: 10,
                        color: statusColor,
                        fontWeight: FontWeight.w600),
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
