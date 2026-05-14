import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/secure_storage.dart';
import 'lecturer/lecturer_course_management_screen.dart';

class LecturerDashboardScreen extends StatefulWidget {
  const LecturerDashboardScreen({super.key});

  @override
  State<LecturerDashboardScreen> createState() =>
      _LecturerDashboardScreenState();
}

class _LecturerDashboardScreenState extends State<LecturerDashboardScreen> {
  int _selectedIndex = 0;
  final List<String> _sectionTitles = [
    'Dashboard',
    'Courses',
    'Live Classes',
    'Profile',
  ];

  static final List<Widget> _pages = <Widget>[
    _DashboardHome(),
    _CoursesPage(),
    _LiveClassesPage(),
    _ProfilePage(),
  ];

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      // Remove AppBar for a seamless header
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blueGrey[50]),
              margin: EdgeInsets.zero,
              padding: EdgeInsets.zero,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.blueGrey[100],
                    child: Icon(
                      Icons.person,
                      size: 36,
                      color: Colors.blueGrey[700],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Lecturer Name',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.blueGrey[900],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'lecturer@email.com',
                    style: TextStyle(color: Colors.blueGrey[400], fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.blueGrey),
              title: const Text('Settings'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.blueGrey),
              title: const Text('Calendar'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(
                Icons.account_balance_wallet,
                color: Colors.blueGrey,
              ),
              title: const Text('Payments'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.attach_money, color: Colors.blueGrey),
              title: const Text('Withdrawals'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.support_agent, color: Colors.blueGrey),
              title: const Text('Support'),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Logout'),
              onTap: () async {
                await SecureStorage.deleteAllTokens();
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/lecturer-login',
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blueGrey,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Courses',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.video_call), label: 'Live'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// --- Dashboard Section Stubs ---
class _DashboardHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Modern dashboard: cover, avatar, stats, courses, activity
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 400;
        final screenHeight = MediaQuery.of(context).size.height;
        final horizontalPadding = isSmall ? 12.0 : 24.0;
        final avatarRadius = isSmall ? 28.0 : 38.0;
        final coverHeight = (screenHeight * 0.28).clamp(
          150.0,
          260.0,
        ); // Increased for appbar controls
        final statFontSize = isSmall ? 16.0 : 22.0;
        final statLabelSize = isSmall ? 12.0 : 15.0;
        final cardMaxWidth = isSmall ? 220.0 : 320.0;

        return Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // Unified header (AppBar + Profile)
            Container(
              width: double.infinity,
              height: coverHeight,
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFe0e7ef), Color(0xFFf8fafc)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AppBar controls row
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Builder(
                          builder: (context) => IconButton(
                            icon: const Icon(
                              Icons.menu,
                              color: Colors.blueGrey,
                            ),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                            tooltip: 'Menu',
                          ),
                        ),
                        Expanded(
                          child: Text(
                            // Use the same section title as before
                            (context
                                    .findAncestorStateOfType<
                                      _LecturerDashboardScreenState
                                    >()
                                    ?._sectionTitles[context
                                        .findAncestorStateOfType<
                                          _LecturerDashboardScreenState
                                        >()
                                        ?._selectedIndex ??
                                    0]) ??
                                '',
                            style: const TextStyle(
                              color: Colors.blueGrey,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.notifications_none,
                            color: Colors.blueGrey,
                          ),
                          onPressed: () {},
                          tooltip: 'Notifications',
                        ),
                      ],
                    ),
                  ),
                  // Profile row
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(width: horizontalPadding),
                        CircleAvatar(
                          radius: avatarRadius,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: avatarRadius - 4,
                            backgroundColor: Colors.blueGrey[100],
                            child: Icon(
                              Icons.person,
                              size: avatarRadius,
                              color: Colors.blueGrey[700],
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lecturer Name',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isSmall ? 16 : 22,
                                  color: Colors.blueGrey[900],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'lecturer@email.com',
                                style: TextStyle(
                                  color: Colors.blueGrey[400],
                                  fontSize: isSmall ? 11 : 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: horizontalPadding),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Scrollable content below header
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: (screenHeight * 0.045).clamp(22.0, 40.0)),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: _statCard(
                              'Earnings',
                              '₦120,000',
                              Icons.payments,
                              statFontSize,
                              statLabelSize,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _statCard(
                              'Enrolled',
                              '320',
                              Icons.people,
                              statFontSize,
                              statLabelSize,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _statCard(
                              'Courses',
                              '8',
                              Icons.menu_book,
                              statFontSize,
                              statLabelSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isSmall ? 18 : 32),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'My Courses',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: isSmall ? 14 : 18,
                                color: Colors.blueGrey[800],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              final dashboardState = context
                                  .findAncestorStateOfType<
                                    _LecturerDashboardScreenState
                                  >();
                              dashboardState?._onNavTap(1);
                            },
                            icon: Icon(Icons.add, size: isSmall ? 14 : 18),
                            label: Text(
                              'Upload Course',
                              style: TextStyle(fontSize: isSmall ? 12 : 14),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blueGrey[700],
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmall ? 8 : 12,
                                vertical: isSmall ? 4 : 8,
                              ),
                              minimumSize: Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isSmall ? 4 : 8),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: SizedBox(
                        height: (MediaQuery.of(context).size.height * 0.22)
                            .clamp(110.0, 220.0),
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _courseCard(
                              'Flutter Basics',
                              '120 enrolled',
                              true,
                              cardMaxWidth,
                              isSmall,
                            ),
                            _courseCard(
                              'Dart Advanced',
                              '80 enrolled',
                              false,
                              cardMaxWidth,
                              isSmall,
                            ),
                            _courseCard(
                              'UI/UX Design',
                              '60 enrolled',
                              true,
                              cardMaxWidth,
                              isSmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: isSmall ? 18 : 32),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: Text(
                        'Recent Activity',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmall ? 14 : 18,
                          color: Colors.blueGrey[800],
                        ),
                      ),
                    ),
                    SizedBox(height: isSmall ? 6 : 12),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: Column(
                        children: [
                          _activityItem(
                            'New student enrolled in "Flutter Basics"',
                            DateTime.now().subtract(const Duration(hours: 2)),
                            Icons.person_add,
                            Colors.green,
                            isSmall,
                          ),
                          _activityItem(
                            'You received ₦10,000 for "Dart Advanced"',
                            DateTime.now().subtract(const Duration(days: 1)),
                            Icons.attach_money,
                            Colors.blue,
                            isSmall,
                          ),
                          _activityItem(
                            'Live class request for "UI/UX Design"',
                            DateTime.now().subtract(const Duration(days: 2)),
                            Icons.video_call,
                            Colors.orange,
                            isSmall,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isSmall ? 18 : 32),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _statCard(
    String label,
    String value,
    IconData icon,
    double valueFontSize,
    double labelFontSize,
  ) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.blueGrey[400], size: valueFontSize + 8),
            SizedBox(height: valueFontSize > 18 ? 10 : 6),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: valueFontSize,
                color: Colors.blueGrey[900],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: valueFontSize > 18 ? 4 : 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.blueGrey[400],
                fontSize: labelFontSize,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _courseCard(
    String title,
    String subtitle,
    bool isPaid,
    double maxWidth,
    bool isSmall,
  ) {
    return Container(
      width: maxWidth,
      margin: const EdgeInsets.only(right: 14),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: EdgeInsets.all(isSmall ? 10 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.menu_book,
                    color: Colors.blueGrey[300],
                    size: isSmall ? 18 : 22,
                  ),
                  SizedBox(width: isSmall ? 4 : 8),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmall ? 6 : 8,
                      vertical: isSmall ? 1 : 2,
                    ),
                    decoration: BoxDecoration(
                      color: isPaid ? Colors.green[50] : Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isPaid ? 'Paid' : 'Free',
                      style: TextStyle(
                        fontSize: isSmall ? 10 : 12,
                        color: isPaid ? Colors.green : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isSmall ? 8 : 16),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isSmall ? 13 : 16,
                  color: Colors.blueGrey[900],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isSmall ? 3 : 6),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.blueGrey[400],
                  fontSize: isSmall ? 10 : 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.more_vert, size: isSmall ? 16 : 20),
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _activityItem(
    String text,
    DateTime time,
    IconData icon,
    Color color,
    bool isSmall,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.15),
        child: Icon(icon, color: color, size: isSmall ? 14 : 20),
      ),
      title: Text(
        text,
        style: TextStyle(
          fontSize: isSmall ? 11 : 15,
          color: Colors.blueGrey[900],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        DateFormat('MMM d, h:mm a').format(time),
        style: TextStyle(
          fontSize: isSmall ? 9 : 12,
          color: Colors.blueGrey[400],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _CoursesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const LecturerCourseManagementScreen();
  }
}

class _LiveClassesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () => Navigator.of(context).pushNamed('/live-sessions'),
        icon: const Icon(Icons.video_call),
        label: const Text('Open Live Session Requests'),
      ),
    );
  }
}

class _ProfilePage extends StatefulWidget {
  @override
  State<_ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<_ProfilePage> {
  bool isEditing = false;
  final TextEditingController phoneController = TextEditingController(
    text: '+234 801 234 5678',
  );
  final TextEditingController bioController = TextEditingController(
    text: 'Experienced Flutter developer and educator.',
  );
  final TextEditingController qualificationController = TextEditingController(
    text: 'MSc Computer Science',
  );
  String? idFileName;

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 400;
    final horizontalPadding = isSmall ? 12.0 : 24.0;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFf8fafc), Color(0xFFe0e7ef)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.05),
              // Decorative header with curve
              Stack(
                children: [
                  ClipPath(
                    clipper: _ProfileHeaderClipper(),
                    child: Container(
                      height: isSmall ? 170 : 220,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFe0e7ef), Color(0xFFf8fafc)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment(0, isSmall ? -0.5 : -0.7),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: isSmall ? 44 : 60,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: isSmall ? 40 : 56,
                              backgroundColor: Colors.blueGrey[100],
                              child: Icon(
                                Icons.person,
                                size: isSmall ? 40 : 56,
                                color: Colors.blueGrey[700],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Lecturer Name',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isSmall ? 19 : 24,
                              color: Colors.blueGrey[900],
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'lecturer@email.com',
                            style: TextStyle(
                              color: Colors.blueGrey[400],
                              fontSize: isSmall ? 13 : 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Lecturer',
                              style: TextStyle(
                                color: Colors.blueGrey,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 18,
                ),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 4,
                  shadowColor: Colors.blueGrey[100],
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmall ? 12 : 24,
                      vertical: 26,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blueGrey[400],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Profile Details',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isSmall ? 16 : 19,
                                    color: Colors.blueGrey[800],
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: Icon(
                                isEditing ? Icons.close : Icons.edit,
                                color: Colors.blueGrey,
                              ),
                              onPressed: () =>
                                  setState(() => isEditing = !isEditing),
                              tooltip: isEditing ? 'Cancel' : 'Edit Profile',
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _profileField(
                          'Phone',
                          icon: Icons.phone,
                          child: isEditing
                              ? TextField(
                                  controller: phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                )
                              : Text(
                                  phoneController.text,
                                  style: TextStyle(
                                    fontSize: isSmall ? 13 : 15,
                                    color: Colors.blueGrey[900],
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),
                        Divider(color: Colors.blueGrey[50]),
                        _profileField(
                          'Bio',
                          icon: Icons.info,
                          child: isEditing
                              ? TextField(
                                  controller: bioController,
                                  maxLines: 2,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                )
                              : Text(
                                  bioController.text,
                                  style: TextStyle(
                                    fontSize: isSmall ? 13 : 15,
                                    color: Colors.blueGrey[900],
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),
                        Divider(color: Colors.blueGrey[50]),
                        _profileField(
                          'Qualification',
                          icon: Icons.school,
                          child: isEditing
                              ? TextField(
                                  controller: qualificationController,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                )
                              : Text(
                                  qualificationController.text,
                                  style: TextStyle(
                                    fontSize: isSmall ? 13 : 15,
                                    color: Colors.blueGrey[900],
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),
                        Divider(color: Colors.blueGrey[50]),
                        _profileField(
                          'ID Document',
                          icon: Icons.badge,
                          child: isEditing
                              ? Row(
                                  children: [
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.upload_file),
                                      label: const Text('Upload'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blueGrey[700],
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                      ),
                                      onPressed: () async {
                                        // File picker logic placeholder
                                        setState(() {
                                          idFileName = 'id_card.pdf';
                                        });
                                      },
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      idFileName ?? 'No file selected',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.blueGrey[700],
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  idFileName ?? 'id_card.pdf',
                                  style: TextStyle(
                                    fontSize: isSmall ? 13 : 15,
                                    color: Colors.blueGrey[900],
                                  ),
                                ),
                        ),
                        if (isEditing)
                          Padding(
                            padding: const EdgeInsets.only(top: 28.0),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() => isEditing = false);
                                  // Save logic placeholder
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueGrey[800],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: const Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileField(String label, {required Widget child, IconData? icon}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, right: 8),
            child: Icon(icon, color: Colors.blueGrey[300], size: 20),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 4),
              child,
            ],
          ),
        ),
      ],
    );
  }
}

// Decorative curved header clipper
class _ProfileHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 40,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
