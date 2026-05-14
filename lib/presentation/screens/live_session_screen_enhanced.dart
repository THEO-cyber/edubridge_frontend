import 'package:flutter/material.dart';

class LiveSessionScreenEnhanced extends StatefulWidget {
  const LiveSessionScreenEnhanced({Key? key}) : super(key: key);

  @override
  State<LiveSessionScreenEnhanced> createState() =>
      _LiveSessionScreenEnhancedState();
}

class _LiveSessionScreenEnhancedState extends State<LiveSessionScreenEnhanced> {
  final List<Map<String, dynamic>> mockSessions = [
    {
      'id': '1',
      'title': 'Flutter State Management Explained',
      'instructor': 'John Doe',
      'scheduledAt': DateTime.now().add(const Duration(hours: 2)),
      'duration': 60,
      'capacity': 50,
      'booked': 32,
      'status': 'upcoming',
    },
    {
      'id': '2',
      'title': 'Web Development Best Practices',
      'instructor': 'Jane Smith',
      'scheduledAt': DateTime.now().add(const Duration(hours: 5)),
      'duration': 90,
      'capacity': 100,
      'booked': 45,
      'status': 'upcoming',
    },
    {
      'id': '3',
      'title': 'Q&A Session',
      'instructor': 'Admin',
      'scheduledAt': DateTime.now().subtract(const Duration(hours: 1)),
      'duration': 45,
      'capacity': 200,
      'booked': 120,
      'status': 'live',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Sessions')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLiveSessionTab(),
            const SizedBox(height: 24),
            Text(
              'Upcoming Sessions',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._buildUpcomingSessions(),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveSessionTab() {
    final liveSession = mockSessions
        .where((s) => s['status'] == 'live')
        .firstOrNull;
    if (liveSession == null) return const SizedBox.shrink();

    return Card(
      color: Colors.red[50],
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Colors.red, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'LIVE NOW',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              liveSession['title'],
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(liveSession['instructor']),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.people, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${liveSession['booked']} watching'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Joining live session...')),
                  );
                },
                child: const Text('Join Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildUpcomingSessions() {
    final upcomingSessions = mockSessions
        .where((s) => s['status'] == 'upcoming')
        .toList();
    return upcomingSessions.map((session) {
      return _buildSessionCard(session);
    }).toList();
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    final scheduledAt = session['scheduledAt'] as DateTime;
    final timeString =
        '${scheduledAt.hour}:${scheduledAt.minute.toString().padLeft(2, '0')}';
    final dateString =
        '${scheduledAt.month}/${scheduledAt.day}/${scheduledAt.year}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session['title'],
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(child: Text(session['instructor'])),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(child: Text('$dateString at $timeString')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(child: Text('${session['duration']} minutes')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${session['booked']}/${session['capacity']} seats taken',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                ElevatedButton(
                  onPressed: _bookSession,
                  child: const Text('Book Now'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _bookSession() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session booked successfully!')),
    );
  }
}
