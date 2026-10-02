import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../widgets/custom_bottom_nav.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/teacher_model.dart';
import '../widgets/app_drawer.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import 'help_support_screen.dart';
import '../services/firestore_service.dart';

import 'teacher_attendance_screen.dart';
import 'teacher_homework_screen.dart';
import 'teacher_marks_screen.dart';
import 'teacher_timetable_screen.dart';
import 'teacher_leave_screen.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _index = 0;
  final FirestoreService _firestoreService = FirestoreService();
  TeacherModel? _teacher;
  bool _isLoading = true;

  int _classesCount = 0;
  int _homeworkCount = 0;
  final int _pendingLeavesCount = 0;

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  Future<void> _loadTeacherData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    try {
      final snapshot = await _firestoreService.getCollectionQuery('teachers')
          .where('uid', isEqualTo: uid).limit(1).get();
          
      if (snapshot.docs.isNotEmpty) {
        if (mounted) {
          setState(() {
            _teacher = TeacherModel.fromMap(snapshot.docs.first.data() as Map<String, dynamic>, snapshot.docs.first.id);
            _isLoading = false;
          });
          _fetchStats();
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _fetchStats() async {
    if (_teacher == null) return;
    try {
      final hwSnap = await _firestoreService.getCollectionQuery('homework')
          .where('schoolId', isEqualTo: _teacher!.schoolId)
          .where('teacherId', isEqualTo: _teacher!.teacherId)
          .get();
      
      final subSnap = await _firestoreService.getCollectionQuery('subjects')
          .where('schoolId', isEqualTo: _teacher!.schoolId)
          .where('teacherId', isEqualTo: _teacher!.teacherId)
          .get();
          
      final uniqueClasses = subSnap.docs.map((doc) => doc['classId'].toString()).toSet();
      
      if (mounted) {
        setState(() {
          _homeworkCount = hwSnap.docs.length;
          _classesCount = uniqueClasses.length;
        });
      }
    } catch (e) {
      // Ignore stat fetch errors for now
    }
  }

  final _pages = const ['Home', 'Classes', 'Reports', 'Profile'];

  void _open(String feature) {
    if (feature == 'Notifications') {
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
          _list('My Classes', [
            'Class 10-A',
            'Class 10-B',
            'Class 9-A',
          ]),
          _list('Reports', [
            'Attendance Report',
            'Academic Performance',
            'Homework Report',
          ]),
          _list('Teacher Profile', [
            'My Details',
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
                colors: [Color(0xFF283593), Color(0xFF3F51B5)], // Dark blue/indigo gradient for teacher
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
                        child: Icon(Icons.person, size: 32, color: Color(0xFF283593)),
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
                        'Good Morning,\n${_teacher?.name ?? 'Teacher'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text('Teacher'.tr(),
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
                  Expanded(child: _statCard('Today\'s Classes', '$_classesCount', Icons.calendar_today, const Color(0xFFEDE7F6), const Color(0xFF673AB7))),
                  SizedBox(width: 8),
                  Expanded(child: _statCard('Homework', '$_homeworkCount', Icons.assignment_outlined, const Color(0xFFE3F2FD), const Color(0xFF2196F3))),
                  SizedBox(width: 8),
                  Expanded(child: _statCard('Pending Leaves', '$_pendingLeavesCount', Icons.pending_actions, const Color(0xFFFFF3E0), const Color(0xFFFF9800))),
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
                _gridItem('Timetable', Icons.calendar_month, const Color(0xFFEDE7F6), const Color(0xFF673AB7), () {
                  if (_teacher != null) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherTimetableScreen(teacher: _teacher!)));
                  }
                }),
                _gridItem('Attendance', Icons.fact_check_outlined, const Color(0xFFFCE4EC), const Color(0xFFE91E63), () {
                  if (_teacher != null) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherAttendanceScreen(teacher: _teacher!)));
                  }
                }),
                _gridItem('Marks', Icons.edit_note, const Color(0xFFFFEBEE), const Color(0xFFF44336), () {
                  if (_teacher != null) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherMarksScreen(teacher: _teacher!)));
                  }
                }),
                _gridItem('Syllabus', Icons.menu_book, const Color(0xFFEDE7F6), const Color(0xFF673AB7), () => _open('Syllabus')),
                _gridItem('Homework', Icons.assignment, const Color(0xFFE8F5E9), const Color(0xFF4CAF50), () {
                  if (_teacher != null) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherHomeworkScreen(teacher: _teacher!)));
                  }
                }),
                _gridItem('Leave Request', Icons.event_busy_outlined, const Color(0xFFFFF3E0), const Color(0xFFFF9800), () {
                  if (_teacher != null) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherLeaveScreen(teacher: _teacher!)));
                  }
                }),
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
                  colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)], // Soft blue gradient
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.format_quote, color: Color(0xFF1976D2), size: 30),
                        SizedBox(height: 4),
                        Text('Teach today\nfor a better tomorrow'.tr(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: 
                            FontWeight.w800,
                            color: Color(0xFF1E293B),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.laptop_chromebook, size: 64, color: Colors.blue.shade700), // Placeholder for illustration
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
                        color: const Color(0xFF198754).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.menu_book_rounded, color: Color(0xFF198754)),
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