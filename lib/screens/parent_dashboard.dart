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
import 'parent_leave_screen.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  int _index = 0;
  final FirestoreService _firestoreService = FirestoreService();
  List<StudentModel> _myChildren = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyChildren();
  }

  Future<void> _loadMyChildren() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    // Parent document doesn't strictly have a ParentModel, but Students have parentIds.
    // So we just find students whose parentIds contains this parent's UID.
    final snapshot = await _firestoreService.getCollectionQuery('students')
        .where('parentIds', arrayContains: uid).get();
        
    if (mounted) {
      setState(() {
        _myChildren = snapshot.docs.map((doc) => StudentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
        _isLoading = false;
      });
    }
  }

  final _pages = const ['Home', 'Activities', 'Reports', 'Profile'];

  void _open(String feature) {
    if (feature == 'Attendance') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ParentAttendanceScreen(children: _myChildren)));
      return;
    } else if (feature == 'Homework') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ParentHomeworkScreen(children: _myChildren)));
      return;
    } else if (feature == 'Results' || feature == 'Exam Results') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ParentMarksScreen(children: _myChildren)));
      return;
    } else if (feature == 'Timetable') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ParentTimetableScreen(children: _myChildren)));
      return;
    } else if (feature == 'Fee Details' || feature == 'Fee Report' || feature == 'Fees' || feature == 'Pay Fees') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ParentFeesScreen(children: _myChildren)));
      return;
    } else if (feature == 'Leave Requests' || feature == 'Leave Request' || feature == 'Leave') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ParentLeaveScreen(children: _myChildren)));
      return;
    } else if (feature == 'Notifications') {
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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
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
            onPressed: () => _open('Notifications'),
            icon: Icon(Icons.notifications_none_rounded),
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
      body: IndexedStack(
        index: _index,
        children: [
          _home(),
          _list('Child Activities', [
            'Attendance',
            'Homework',
            'Timetable',
            'Leave Requests',
          ]),
          _list('Academic & Fee Reports', [
            'Exam Results',
            'Academic Progress',
            'Fee Details',
            'Payment History',
          ]),
          _list('Parent Profile', [
            'My Details',
            'Child Profile',
            'Settings',
            'Help & Support',
          ]),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
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
                colors: [Color(0xFF00695C), Color(0xFF00897B)], // Teal/Green gradient for parent
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
                        child: Icon(Icons.person, size: 32, color: Color(0xFF00695C)),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hello, Parent'.tr(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text('Parent'.tr(),
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
                  Expanded(child: _statCard('Child\'s Attendance', '92%', Icons.check_circle_outline, const Color(0xFFFFF3E0), const Color(0xFFFF9800))),
                  SizedBox(width: 8),
                  Expanded(child: _statCard('Latest Marks', '78%', Icons.analytics_outlined, const Color(0xFFEDE7F6), const Color(0xFF673AB7))),
                  SizedBox(width: 8),
                  Expanded(child: _statCard('Fee Status', 'Paid', Icons.check_circle, const Color(0xFFE8F5E9), const Color(0xFF4CAF50))),
                ],
              ),
            ),

            // Child Selector (if multiple children)
          if (_myChildren.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.face, color: Color(0xFF00695C)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Viewing: ${_myChildren.first.name}', // Just showing the first child for now
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                  ],
                ),
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
                _gridItem('Marks Report', Icons.edit_note, const Color(0xFFFCE4EC), const Color(0xFFE91E63), () => _open('Results')),
                _gridItem('Attendance', Icons.fact_check_outlined, const Color(0xFFFFF3E0), const Color(0xFFFF9800), () => _open('Attendance')),
                _gridItem('Bus Tracking', Icons.directions_bus_outlined, const Color(0xFFE3F2FD), const Color(0xFF2196F3), () => _open('Transport')),
                _gridItem('Gallery', Icons.photo_library_outlined, const Color(0xFFE8F5E9), const Color(0xFF4CAF50), () => _open('Gallery')),
                _gridItem('Leave Request', Icons.event_busy_outlined, const Color(0xFFFCE4EC), const Color(0xFFE91E63), () => _open('Leave')),
                _gridItem('Circulars', Icons.article_outlined, const Color(0xFFEDE7F6), const Color(0xFF673AB7), () => _open('Circulars')),
                _gridItem('Fees', Icons.receipt_long, const Color(0xFFE8F5E9), const Color(0xFF4CAF50), () => _open('Fees')),
                _gridItem('Homework', Icons.assignment, const Color(0xFFFFF3E0), const Color(0xFFFF9800), () => _open('Homework')),
                _gridItem('Timetable', Icons.calendar_month, const Color(0xFFE0F7FA), const Color(0xFF00BCD4), () => _open('Timetable')),
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
                  colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD)], // Soft blue gradient
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Stay Connected\nwith Your Child\'.tr()s Progress',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        height: 1.3,
                      ),
                    ),
                  ),
                  Icon(Icons.family_restroom, size: 64, color: Colors.blue.shade800), // Placeholder for illustration
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
              Flexible(
                child: Text(
                  title.tr(),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
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

  Widget _list(String title, List<String> items) {
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
                onTap: () => _open(item),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6F42C1).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.school_rounded, color: Color(0xFF6F42C1)),
                    ),
                    title: Text(
                      item.tr(),
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