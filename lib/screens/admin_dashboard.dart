import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../widgets/custom_bottom_nav.dart';
import '../theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/app_drawer.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import 'help_support_screen.dart';
import '../services/firestore_service.dart';
import 'students_screen.dart';
import 'teachers_screen.dart';
import 'classes_screen.dart';
import 'admin_fees_screen.dart';
import 'admin_exams_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_timetable_screen.dart';
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _index = 0;
  final FirestoreService _firestoreService = FirestoreService();
  String _schoolId = '';

  @override
  void initState() {
    super.initState();
    _fetchAdminSchoolId();
  }

  Future<void> _fetchAdminSchoolId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        setState(() {
          _schoolId = doc.data()!['schoolId'] ?? '';
        });
      }
    }
  }

  final _sections = const [
    'Dashboard',
    'Users',
    'Reports',
    'Profile',
  ];

  void _message(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature module coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      drawer: const AppDrawer(),
      appBar: _index != 0 ? AppBar(
        title: Text(_sections[_index].tr()),
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
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
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
          _listPage('School Management', [
            ('Students', Icons.school_outlined),
            ('Teachers', Icons.cast_for_education),
            ('Classes', Icons.meeting_room_outlined),
            ('Parents', Icons.family_restroom),
          ]),
          _listPage('School Reports', [
            ('Attendance Report', Icons.fact_check_outlined),
            ('Academic Report', Icons.bar_chart),
            ('Fee Report', Icons.account_balance_wallet_outlined),
            ('Student Report', Icons.people_outline),
          ]),
          _listPage('Admin Profile', [
            ('School Information', Icons.school_outlined),
            ('Account Settings', Icons.settings_outlined),
            ('Help & Support', Icons.help_outline),
            ('Logout', Icons.logout),
          ]),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() => _index = value);
        },
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
                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)], // Dark blue gradient for admin
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
                        child: Icon(Icons.person, size: 32, color: Color(0xFF1E3A8A)),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Good Morning,\nAdmin'.tr(), // Replace with real name if stored
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text('Head Master'.tr(),
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
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
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
            offset: const Offset(0, -10),
            child: Column(
              children: [
                // 3 Stat Cards Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
              child: StreamBuilder<QuerySnapshot>(
                stream: _schoolId.isEmpty ? const Stream.empty() : _firestoreService.getCollectionQuery('students').where('schoolId', isEqualTo: _schoolId).snapshots(),
                builder: (context, studentSnapshot) {
                  int studentCount = studentSnapshot.hasData ? studentSnapshot.data!.docs.length : 0;
                  return StreamBuilder<QuerySnapshot>(
                    stream: _schoolId.isEmpty ? const Stream.empty() : _firestoreService.getCollectionQuery('users').where('role', isEqualTo: 'teacher').where('schoolId', isEqualTo: _schoolId).snapshots(),
                    builder: (context, teacherSnapshot) {
                      int teacherCount = teacherSnapshot.hasData ? teacherSnapshot.data!.docs.length : 0;
                      return StreamBuilder<QuerySnapshot>(
                        stream: _schoolId.isEmpty ? const Stream.empty() : _firestoreService.getCollectionQuery('classes').where('schoolId', isEqualTo: _schoolId).snapshots(),
                        builder: (context, classesSnapshot) {
                          int classesCount = classesSnapshot.hasData ? classesSnapshot.data!.docs.length : 0;
                          return Row(
                            children: [
                              Expanded(child: _statCard('Total Students', '$studentCount', Icons.group, const Color(0xFFE8F5E9), const Color(0xFF4CAF50))),
                              SizedBox(width: 8),
                              Expanded(child: _statCard('Total Teachers', '$teacherCount', Icons.person_outline, const Color(0xFFEDE7F6), const Color(0xFF673AB7))),
                              SizedBox(width: 8),
                              Expanded(child: _statCard('Total Classes', '$classesCount', Icons.meeting_room_outlined, const Color(0xFFFFEBEE), const Color(0xFFF44336))),
                            ],
                          );
                        }
                      );
                    }
                  );
                }
              ), // closes StreamBuilder
              ), // closes Padding

          SizedBox(height: 16), // Reduced gap below stats

          // Feature Grid (3 columns x 3 rows)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 6,
              childAspectRatio: 1.1,
              children: [
                _gridItem('Student Management', Icons.groups, const Color(0xFFE0F7FA), const Color(0xFF00BCD4), () {
                  if (_schoolId.isNotEmpty) Navigator.push(context, MaterialPageRoute(builder: (_) => StudentsScreen(schoolId: _schoolId)));
                }),
                _gridItem('Teacher Management', Icons.group_add, const Color(0xFFEDE7F6), const Color(0xFF673AB7), () {
                  if (_schoolId.isNotEmpty) Navigator.push(context, MaterialPageRoute(builder: (_) => TeachersScreen(schoolId: _schoolId)));
                }),
                _gridItem('Class Allocation', Icons.class_outlined, const Color(0xFFE8F5E9), const Color(0xFF4CAF50), () {
                  if (_schoolId.isNotEmpty) Navigator.push(context, MaterialPageRoute(builder: (_) => ClassesScreen(schoolId: _schoolId)));
                }),
                _gridItem('Timetable', Icons.calendar_month, const Color(0xFFE3F2FD), const Color(0xFF2196F3), () {
                  if (_schoolId.isNotEmpty) Navigator.push(context, MaterialPageRoute(builder: (_) => AdminTimetableScreen(schoolId: _schoolId)));
                }),
                _gridItem('Finance', Icons.attach_money, const Color(0xFFE8F5E9), const Color(0xFF4CAF50), () {
                  if (_schoolId.isNotEmpty) Navigator.push(context, MaterialPageRoute(builder: (_) => AdminFeesScreen(schoolId: _schoolId)));
                }),
                _gridItem('Circulars', Icons.article_outlined, const Color(0xFFFFEBEE), const Color(0xFFF44336), () => _message('Circulars')),
                _gridItem('Class', Icons.class_outlined, const Color(0xFFEDE7F6), const Color(0xFF673AB7), () {
                  if (_schoolId.isNotEmpty) Navigator.push(context, MaterialPageRoute(builder: (_) => ClassesScreen(schoolId: _schoolId)));
                }),
                _gridItem('Reports', Icons.bar_chart, const Color(0xFFEDE7F6), const Color(0xFF673AB7), () {
                  if (_schoolId.isNotEmpty) Navigator.push(context, MaterialPageRoute(builder: (_) => AdminReportsScreen(schoolId: _schoolId)));
                }),
                _gridItem('Exams', Icons.assignment, const Color(0xFFEDE7F6), const Color(0xFF673AB7), () {
                  if (_schoolId.isNotEmpty) Navigator.push(context, MaterialPageRoute(builder: (_) => AdminExamsScreen(schoolId: _schoolId)));
                }),
              ],
            ),
          ),
          
          SizedBox(height: 18),
          
          // Motivational Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)], // Soft cyan gradient
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('School Progress'.tr(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF006064),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text('Together for a better future'.tr(),
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF00838F),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.auto_graph, size: 64, color: Colors.cyan.shade700), // Placeholder for illustration
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
        border: Border.all(color: iconColor.withValues(alpha: 0.4), width: 1.5),
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border.all(color: iconColor, width: 1.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 24, color: iconColor),
          ),
          SizedBox(height: 2),
          Text(
            title.tr(),
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _listPage(
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
                onTap: () {
                  if (item.$1 == 'Teachers') {
                    if (_schoolId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Loading admin details...'.tr())));
                      return;
                    }
                    Navigator.push(context, MaterialPageRoute(builder: (_) => TeachersScreen(schoolId: _schoolId)));
                  } else if (item.$1 == 'Students') {
                    if (_schoolId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Loading admin details...'.tr())));
                      return;
                    }
                    Navigator.push(context, MaterialPageRoute(builder: (_) => StudentsScreen(schoolId: _schoolId)));
                  } else if (item.$1 == 'Classes') {
                    if (_schoolId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Loading admin details...'.tr())));
                      return;
                    }
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ClassesScreen(schoolId: _schoolId)));
                  } else if (item.$1 == 'Fee Report' || item.$1 == 'Fees Allocation') {
                    if (_schoolId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Loading admin details...'.tr())));
                      return;
                    }
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AdminFeesScreen(schoolId: _schoolId)));
                  } else if (item.$1 == 'Account Settings' || item.$1 == 'Settings') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                  } else if (item.$1 == 'Help & Support') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
                  } else {
                    _message(item.$1);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item.$2, color: AppTheme.primary),
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