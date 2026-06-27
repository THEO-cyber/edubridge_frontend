import 'package:flutter/material.dart';

const _kNavy = Color(0xFF1A237E);
const _kBlue = Color(0xFF1976D2);

class AboutScreen extends StatelessWidget {
  final bool isInstructor;
  const AboutScreen({super.key, this.isInstructor = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: CustomScrollView(
        slivers: [
          _buildHeader(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: isInstructor
                    ? _instructorSections(context)
                    : _studentSections(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 220,
      backgroundColor: _kNavy,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('About EduBridge',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_kNavy, _kBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3), width: 2),
                  ),
                  child: const Center(
                    child: Text('E',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('EduBridge',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(
                  'Your Gateway to Quality Education',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    isInstructor ? 'Instructor Guide v1.0' : 'Student Guide v1.0',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Student sections ──────────────────────────────────────────────────────

  List<Widget> _studentSections(BuildContext context) => [
        _HeroTip(
          icon: Icons.school_rounded,
          text:
              'Welcome to EduBridge — learn from top instructors, track your progress, earn certificates, and join live sessions.',
        ),
        const SizedBox(height: 24),
        _Section(
          icon: Icons.explore_rounded,
          iconColor: _kNavy,
          title: 'Navigating the App',
          children: [
            _NavTab(
              icon: Icons.home_rounded,
              label: 'Home',
              description:
                  'Browse featured courses, see what\'s trending, and access quick links to your learning.',
            ),
            _NavTab(
              icon: Icons.menu_book_rounded,
              label: 'Courses',
              description:
                  'Search and filter all available courses by category, price, or rating.',
            ),
            _NavTab(
              icon: Icons.favorite_rounded,
              label: 'Wishlist',
              description:
                  'Save courses you\'re interested in. Tap the heart icon on any course to add it.',
            ),
            _NavTab(
              icon: Icons.person_rounded,
              label: 'Profile',
              description:
                  'View your enrolled courses, progress, certificates, and account settings.',
            ),
          ],
        ),
        const SizedBox(height: 20),
        _Section(
          icon: Icons.play_lesson_rounded,
          iconColor: Colors.green[700]!,
          title: 'Enrolling & Watching Lessons',
          children: [
            _Step(
                number: 1,
                text: 'Open a course and tap **Enroll**. Free courses enroll instantly; paid courses go through checkout.'),
            _Step(
                number: 2,
                text: 'After enrolling, tap **Start Learning** or find the course under **My Courses** in your profile.'),
            _Step(
                number: 3,
                text: 'Tap any lesson to open the video player. Use the **360p / 480p / 720p** quality buttons below the player if your connection is slow.'),
            _Step(
                number: 4,
                text: 'Tap **Save Progress** at any time to record how far you\'ve watched. Tap **Mark Complete** when you\'re done with a lesson.'),
            _Tip(
                text: 'Video URLs are freshly fetched each time you open a lesson — this ensures they never expire mid-watch.'),
          ],
        ),
        const SizedBox(height: 20),
        _Section(
          icon: Icons.note_alt_rounded,
          iconColor: Colors.orange[700]!,
          title: 'Notes & Quizzes',
          children: [
            _NavTab(
              icon: Icons.note_alt_outlined,
              label: 'Notes',
              description:
                  'Tap the Notes button inside a lesson to jot down timestamped notes. Find all notes later under Settings → My Notes.',
            ),
            _NavTab(
              icon: Icons.quiz_outlined,
              label: 'Quiz',
              description:
                  'Test your knowledge with lesson quizzes. Results are saved and you can retake them anytime.',
            ),
          ],
        ),
        const SizedBox(height: 20),
        _Section(
          icon: Icons.videocam_rounded,
          iconColor: Colors.purple[600]!,
          title: 'Live Sessions',
          children: [
            _Step(
                number: 1,
                text: 'Go to **Home** and scroll to **Upcoming Live Sessions**, or use the shortcuts menu (⚡ button) → **Live Sessions**.'),
            _Step(
                number: 2,
                text: 'Find a session and tap **Apply**. Your instructor will review and accept or reject your application.'),
            _Step(
                number: 3,
                text: 'Once accepted, you\'ll receive a notification. Open the session and tap **Join Session** at the scheduled time.'),
            _Tip(
                text: 'You can see your application status (Pending / Accepted / Rejected) on the live sessions screen.'),
          ],
        ),
        const SizedBox(height: 20),
        _Section(
          icon: Icons.emoji_events_rounded,
          iconColor: Colors.amber[700]!,
          title: 'Certificates',
          children: [
            _Step(
                number: 1,
                text: 'Complete all lessons in a course by marking each one done.'),
            _Step(
                number: 2,
                text: 'A certificate is automatically issued once you reach 100% completion.'),
            _Step(
                number: 3,
                text: 'Download or share your certificate from **Profile → My Certificates** or **Settings → My Certificates**.'),
          ],
        ),
        const SizedBox(height: 32),
        _VersionFooter(),
      ];

  // ── Instructor sections ───────────────────────────────────────────────────

  List<Widget> _instructorSections(BuildContext context) => [
        _HeroTip(
          icon: Icons.auto_awesome_rounded,
          text:
              'Create and publish courses, host live sessions, upload lesson videos, and track your students\' progress — all from one place.',
        ),
        const SizedBox(height: 24),

        // ── Dashboard overview ──────────────────────────────────────
        _Section(
          icon: Icons.dashboard_rounded,
          iconColor: _kNavy,
          title: 'Navigating the Dashboard',
          children: [
            _NavTab(
              icon: Icons.home_rounded,
              label: 'Home',
              description:
                  'See your stats at a glance — total students, courses, revenue, and recent activity.',
            ),
            _NavTab(
              icon: Icons.menu_book_rounded,
              label: 'Courses',
              description:
                  'Create, edit, publish, and manage all your courses and their content.',
            ),
            _NavTab(
              icon: Icons.video_call_rounded,
              label: 'Live',
              description:
                  'Schedule live sessions, manage student applications, and start or end sessions.',
            ),
            _NavTab(
              icon: Icons.bar_chart_rounded,
              label: 'Analytics',
              description:
                  'View enrolment trends, attendance rates, student feedback, and revenue over time.',
            ),
            _NavTab(
              icon: Icons.person_rounded,
              label: 'Profile / Settings',
              description:
                  'Update your bio, title, expertise, hourly rate. Access Settings from the drawer (☰ icon, top-left) for password, 2FA, and more.',
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ── Full end-to-end course creation ─────────────────────────
        _Section(
          icon: Icons.rocket_launch_rounded,
          iconColor: Colors.green[700]!,
          title: 'Creating & Publishing a Course (Full Guide)',
          highlight: true,
          children: [
            _HighlightBox(
              text:
                  'Follow these steps in order. Do NOT publish until every lesson has a video that shows "Ready". Students cannot access lessons without a ready video.',
            ),

            _StepHeader('STEP 1 — Create the Course'),
            _Step(
                number: 1,
                text: 'Go to the **Courses** tab at the bottom of the screen.'),
            _Step(
                number: 2,
                text: 'Tap the **+ New Course** button (top-right corner).'),
            _Step(
                number: 3,
                text: 'Fill in:\n  • **Title** — clear and descriptive\n  • **Description** — what students will learn\n  • **Category** — choose the closest match\n  • **Price** — set 0 for a free course\n  • **Level** — Beginner / Intermediate / Advanced'),
            _Step(
                number: 4,
                text: 'Tap **Create**. Your course is now saved as a **Draft** — invisible to students until you publish.'),

            _StepHeader('STEP 2 — Add Sections'),
            _Step(
                number: 5,
                text: 'From the Courses list, tap your course card to open it, then tap ⋮ (three dots) → **Manage Content**.'),
            _Step(
                number: 6,
                text: 'Tap **Add Section**. Give it a name (e.g. "Introduction", "Module 1"). Sections organise your lessons into logical groups.'),
            _Step(
                number: 7,
                text: 'Repeat **Step 6** for every section you want in your course.'),

            _StepHeader('STEP 3 — Add Lessons'),
            _Step(
                number: 8,
                text: 'Inside a section, tap **Add Lesson**. Enter the lesson title and description.'),
            _Step(
                number: 9,
                text: 'Tap **Confirm**. A success message appears with a **Lesson ID** (e.g. `64abc123...`). **Copy this ID immediately** — you\'ll need it in the next step to upload the video.'),
            _Step(
                number: 10,
                text: 'Repeat **Steps 8–9** for every lesson in that section. Then repeat for other sections too.'),
            _Tip(
                text: 'The Lesson ID is only shown once in the success message. If you miss it, the ID is also visible in Manage Content next to each lesson name.'),

            _StepHeader('STEP 4 — Upload Videos for Each Lesson'),
            _Step(
                number: 11,
                text: 'Still in **Manage Content**, tap **Upload Lesson Video**.'),
            _Step(
                number: 12,
                text: 'Paste or type the **Lesson ID** you copied in Step 9. This links the video to the correct lesson.'),
            _Step(
                number: 13,
                text: 'Tap **Pick Video** and select the file from your device. Supported formats: **MP4, MOV, AVI**.'),
            _Step(
                number: 14,
                text: 'An **upload bar** appears. Keep the screen open until upload finishes. After uploading, a **processing progress bar** starts automatically — this is your video being converted to multiple quality levels.'),
            _Step(
                number: 15,
                text: 'When the dialog says **"Video is ready!"** — that lesson is fully set up. You can close the dialog; processing continues in the background if you close early.'),
            _Step(
                number: 16,
                text: 'Go back to Manage Content and repeat **Steps 11–15** for every other lesson that needs a video.'),
            _Tip(
                text: 'If a video shows "Processing Failed", go to Upload Lesson Video again, enter the same Lesson ID, and re-upload the file.'),
            const SizedBox(height: 8),
            _QualityInfo(),

            _StepHeader('STEP 5 — Review & Publish'),
            _Step(
                number: 17,
                text: 'In **Manage Content**, check that every lesson shows a green **Ready** status next to the video icon. If any lesson still shows "Processing" — wait for it to finish before publishing.'),
            _Step(
                number: 18,
                text: 'Once all lessons are Ready, go back to your course → tap ⋮ → **Publish Course**.'),
            _Step(
                number: 19,
                text: 'Your course is now **live**. Students can discover it in the Courses tab, enrol, and start watching immediately.'),
            _Tip(
                text: 'You can unpublish a course at any time from ⋮ → Unpublish. Enrolled students retain access to lessons they\'ve already started.'),
          ],
        ),
        const SizedBox(height: 20),

        // ── Live sessions ───────────────────────────────────────────
        _Section(
          icon: Icons.live_tv_rounded,
          iconColor: Colors.orange[700]!,
          title: 'Hosting Live Sessions',
          children: [
            _Step(
                number: 1,
                text: 'Go to the **Live** tab and tap **+ Create Session**. Set the title, date, time, duration, and max number of students.'),
            _Step(
                number: 2,
                text: 'Students will see your session and submit applications. A badge on the card shows pending requests.'),
            _Step(
                number: 3,
                text: 'Tap the session → ⋮ → **Manage Applications**. Tap **Accept** to confirm a student or **Reject** to decline. Accepted students are immediately notified.'),
            _Step(
                number: 4,
                text: 'At session time, tap ⋮ → **Start / Join Session** to open the live classroom link.'),
            _Step(
                number: 5,
                text: 'After the session ends, tap **End Session** to mark it as completed. Students can then leave reviews and ratings.'),
            _Tip(
                text: 'Tap **View Analytics** on any past session to see accepted, attended, pending, and rejected counts. Tap each analytics card to see the individual student list.'),
          ],
        ),
        const SizedBox(height: 20),

        // ── Analytics & Earnings ────────────────────────────────────
        _Section(
          icon: Icons.payments_rounded,
          iconColor: Colors.teal[600]!,
          title: 'Analytics & Earnings',
          children: [
            _NavTab(
              icon: Icons.bar_chart_rounded,
              label: 'Analytics Tab',
              description:
                  'See total students enrolled, average attendance, total teaching hours, and request trends across all your sessions.',
            ),
            _NavTab(
              icon: Icons.account_balance_wallet_rounded,
              label: 'Earnings',
              description:
                  'Access via the drawer (☰) → Earnings. Shows your total revenue, pending balance, and paid-out amounts.',
            ),
            _NavTab(
              icon: Icons.send_rounded,
              label: 'Withdrawals',
              description:
                  'Access via drawer (☰) → Withdraw Earnings. Request a payout and funds are sent to your connected account.',
            ),
          ],
        ),
        const SizedBox(height: 32),
        _VersionFooter(),
      ];
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _StepHeader extends StatelessWidget {
  final String text;
  const _StepHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: _kNavy,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _kNavy,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroTip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _HeroTip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kNavy, _kBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: Colors.white, fontSize: 13, height: 1.5)),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<Widget> children;
  final bool highlight;

  const _Section({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.children,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1A237E))),
            ),
            if (highlight)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                ),
                child: Text('Key Step',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[700])),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: Colors.grey[100]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  final int number;
  final String text;
  const _Step({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    final parts = text.split('**');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _kNavy,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('$number',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                    fontSize: 13, color: Colors.black87, height: 1.5),
                children: [
                  for (int i = 0; i < parts.length; i++)
                    TextSpan(
                      text: parts[i],
                      style: TextStyle(
                          fontWeight: i.isOdd
                              ? FontWeight.bold
                              : FontWeight.normal),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  const _NavTab(
      {required this.icon, required this.label, required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _kNavy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _kNavy, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: _kNavy)),
                const SizedBox(height: 3),
                Text(description,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  final String text;
  const _Tip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EAF6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kNavy.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline_rounded,
              color: _kNavy, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF303F9F), height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _HighlightBox extends StatelessWidget {
  final String text;
  const _HighlightBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withValues(alpha: 0.08),
            Colors.purple.withValues(alpha: 0.04)
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.purple[700], size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 12, color: Colors.purple[800], height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _QualityInfo extends StatelessWidget {
  const _QualityInfo();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.teal.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.hd_rounded, color: Colors.teal[700], size: 16),
            const SizedBox(width: 6),
            Text('Available Quality Options',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.teal[700])),
          ]),
          const SizedBox(height: 8),
          for (final q in [
            ('360p', 'Low bandwidth — best for slow connections'),
            ('480p', 'Standard quality — good balance'),
            ('720p', 'HD — recommended for fast connections (default)'),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(q.$1,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal[700])),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(q.$2,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.black54))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _VersionFooter extends StatelessWidget {
  const _VersionFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [_kNavy, _kBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('E',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('EduBridge',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: _kNavy)),
                Text('Version 1.0.0',
                    style: TextStyle(fontSize: 11, color: Colors.black38)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Built with ❤️ for learners and educators',
            style: TextStyle(fontSize: 11, color: Colors.grey[400])),
        const SizedBox(height: 8),
      ],
    );
  }
}
