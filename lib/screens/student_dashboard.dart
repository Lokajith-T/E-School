import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../widgets/custom_bottom_nav.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/student_model.dart';
import '../widgets/app_drawer.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import 'help_support_screen.dart';
import '../services/firestore_service.dart';

import 'parent_attendance_screen.dart';
import 'parent_homework_screen.dart';
import 'parent_marks_screen.dart';
import 'parent_timetable_screen.dart';
import 'parent_fees_screen.dart';
import 'student_exams_screen.dart';

import 'parent_leave_screen.dart';
import 'parent_subjects_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _index = 0;
  final FirestoreService _firestoreService = FirestoreService();
  StudentModel? _student;
  bool _isLoading = true;

  final _pages = const [
    'Home',
    'Learning',
    'Attendance',
    'Notifications',
    'Profile',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('No user');

      final snapshot = await _firestoreService.getCollectionQuery('students')
          .where('uid', isEqualTo: uid).limit(1).get();

      if (snapshot.docs.isNotEmpty) {
        if (mounted) {
          setState(() {
            _student = StudentModel.fromMap(snapshot.docs.first.data() as Map<String, dynamic>, snapshot.docs.first.id);
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Student not found');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e')),
        );
      }
    }
  }

  void _open(String feature) {
    if (_student == null) return;
    
    if (feature == 'Attendance') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ParentAttendanceScreen(children: [_student!])));
      return;
    } else if (feature == 'Homework') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ParentHomeworkScreen(children: [_student!])));
      return;
    } else if (feature == 'Results' || feature == 'Exam Results') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ParentMarksScreen(children: [_student!])));
      return;
    } else if (feature == 'Timetable') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ParentTimetableScreen(children: [_student!])));
      return;
    } else if (feature == 'Exams') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => StudentExamsScreen(student: _student!)));
      return;
    } else if (feature == 'Fee Details' || feature == 'Fees') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ParentFeesScreen(children: [_student!])));
      return;
    } else if (feature == 'Leave') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ParentLeaveScreen(children: [_student!])));
      return;
    } else if (feature == 'Subjects') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ParentSubjectsScreen(children: [_student!])));
      return;
    } else if (feature == 'Notifications' || feature == 'Announcements') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
      return;
    } else if (feature == 'Settings' || feature == 'Account Settings') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
      return;
    } else if (feature == 'Help & Support') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
      return;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature module coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF), // Light bluish background
      drawer: const AppDrawer(),
      appBar: _index != 0 ? AppBar(
        title: Text(_pages[_index].tr()),
        actions: [
          IconButton(
            onPressed: () {
              if (context.locale.languageCode == 'en') {
                context.setLocale(const Locale('ta'));
              } else {
                context.setLocale(const Locale('en'));
              }
            },
            icon: Icon(Icons.translate),
            tooltip: 'Switch Language'.tr(),
          ),
          IconButton(
            onPressed: () => _open('Announcements'),
            icon: Icon(Icons.campaign_rounded),
          ),
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
            icon: Icon(Icons.logout),
          ),
          SizedBox(width: 8),
        ],
      ) : null,
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _index,
              children: [
                _home(),
                _list('Study Materials', [
                  ('Mathematics', Icons.calculate_outlined),
                  ('Science', Icons.science_outlined),
                  ('History', Icons.history_edu_outlined),
                  ('Literature', Icons.book_outlined),
                ]),
                if (_student != null) ParentAttendanceScreen(children: [_student!], showAppBar: false) else Center(child: CircularProgressIndicator()),
                _list('Notifications', [
                  ('New Assignment Posted', Icons.assignment),
                  ('Fee Receipt Generated', Icons.receipt),
                  ('Teacher Communication', Icons.message),
                ]),
                _list('My Profile', [
                  ('Personal Details', Icons.person_outline),
                  ('Timetable', Icons.schedule),
                  ('Exam Results', Icons.grade),
                  ('Settings', Icons.settings),
                  ('Logout', Icons.logout),
                ]),
              ],
            ),
      bottomNavigationBar: CustomBottomNav(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Learning',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check),
            label: 'Attendance',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _home() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Gradient
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16, 
              left: 20, 
              right: 12, 
              bottom: 30
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F4C75), Color(0xFF3282B8)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Row(
              children: [
                Builder(
                  builder: (context) => GestureDetector(
                    onTap: () => Scaffold.of(context).openDrawer(),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const CircleAvatar(
                        radius: 26,
                        backgroundColor: Color(0xFFE0F2FE),
                        child: Icon(Icons.person, size: 32, color: Color(0xFF0F4C75)),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ${_student?.name.split(' ').first ?? 'Student'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text('Student'.tr(),
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    if (context.locale.languageCode == 'en') {
                      context.setLocale(const Locale('ta'));
                    } else {
                      context.setLocale(const Locale('en'));
                    }
                  },
                  icon: Icon(Icons.translate, color: Colors.white),
                ),
                IconButton(
                  onPressed: () => _open('Notifications'),
                  icon: Icon(Icons.notifications_active, color: Colors.white),
                ),
                IconButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (!mounted) return;
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                  },
                  icon: Icon(Icons.logout, color: Colors.white),
                ),
              ],
            ),
          ),
          
          // Body wrapped to pull everything up
          Transform.translate(
            offset: const Offset(0, -20),
            child: Column(
              children: [
                // 3 Stat Cards Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                children: [
                  Expanded(child: _statCard('Attendance', '92%', Icons.check_circle_outline, const Color(0xFFE8F5E9), const Color(0xFF4CAF50))),
                  SizedBox(width: 8),
                  Expanded(child: _statCard('Marks', '85%', Icons.track_changes, const Color(0xFFFCE4EC), const Color(0xFFE91E63))),
                  SizedBox(width: 8),
                  Expanded(child: _statCard('Assignments', '3', Icons.assignment_outlined, const Color(0xFFE3F2FD), const Color(0xFF2196F3))),
                ],
              ),
            ),

            SizedBox(height: 12),

            // Feature Grid (3 columns)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 8,
                childAspectRatio: 1.1,
              children: [
                _gridItem('Subjects', Icons.menu_book, const Color(0xFFF3E5F5), const Color(0xFF673AB7), () => _open('Subjects')),
                _gridItem('Homework', Icons.assignment, const Color(0xFFFFF3E0), const Color(0xFFFF9800), () => _open('Homework')),
                _gridItem('Timetable', Icons.calendar_month, const Color(0xFFE0F7FA), const Color(0xFF00BCD4), () => _open('Timetable')),
                _gridItem('Exams', Icons.assignment, const Color(0xFFFCE4EC), const Color(0xFFE91E63), () => _open('Exams')),
                _gridItem('Performance', Icons.analytics_outlined, const Color(0xFFEDE7F6), const Color(0xFF673AB7), () => _open('Results')),
                _gridItem('Fees', Icons.receipt_long, const Color(0xFFE8F5E9), const Color(0xFF4CAF50), () => _open('Fees')),
                _gridItem('Leave', Icons.edit_document, const Color(0xFFFFF3E0), const Color(0xFFFF9800), () => _open('Leave')),
                _gridItem('PTM', Icons.people_outline, const Color(0xFFE3F2FD), const Color(0xFF2196F3), () => _open('PTM')),
                _gridItem('More', Icons.grid_view_rounded, const Color(0xFFF3E5F5), const Color(0xFF9C27B0), () => _open('More')),
              ],
            ),
          ),
          
          SizedBox(height: 24),
          
          // Motivational Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF0F5), Color(0xFFFFE4E1)], // Soft pink gradient
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Small steps\nevery day lead to\nbig results!'.tr(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        height: 1.3,
                      ),
                    ),
                  ),
                  Icon(Icons.school, size: 64, color: Colors.blue.shade300), // Placeholder for illustration
                ],
              ),
            ),
          ),
                SizedBox(height: 10),
              ],
            ),
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: iconColor),
              SizedBox(width: 4),
              Flexible(
                child: Text(
                  title.tr(),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _gridItem(String title, IconData icon, Color bgColor, Color iconColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border.all(color: iconColor, width: 1.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 24, color: iconColor),
          ),
          SizedBox(height: 4),
          Text(
            title.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(
    String title,
    List<(String, IconData)> items,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        Text(
          title.tr(),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 24),
        ...items.map(
          (item) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _open(item.$1),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC3545).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item.$2, color: const Color(0xFFDC3545)),
                    ),
                    title: Text(
                      item.$1.tr(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios_rounded,
                        size: 16, color: Colors.grey.shade400),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
