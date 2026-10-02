import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class AdminReportsScreen extends StatefulWidget {
  final String schoolId;

  const AdminReportsScreen({super.key, required this.schoolId});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _classReports = [];

  @override
  void initState() {
    super.initState();
    _fetchClassReports();
  }

  Future<void> _fetchClassReports() async {
    try {
      final classesSnap = await _firestoreService.getCollectionQuery('classes')
          .where('schoolId', isEqualTo: widget.schoolId)
          .get();

      final List<Map<String, dynamic>> reports = [];

      for (var doc in classesSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Placeholder values for now, real calculation would query 'attendance' and 'marks' collections
        // for students matching this classId.
        reports.add({
          'id': doc.id,
          'name': data['name'] ?? 'Class',
          'section': data['section'] ?? '',
          'avgAttendance': '85%', // TODO: Calculate actual class average attendance
          'avgMarks': '72%', // TODO: Calculate actual class average marks
        });
      }

      // Sort by class name
      reports.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

      if (mounted) {
        setState(() {
          _classReports = reports;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading reports: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      appBar: AppBar(
        title: Text('Class Reports'.tr()),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _classReports.isEmpty
              ? Center(child: Text('No classes found for reports.'.tr()))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _classReports.length,
                  itemBuilder: (context, index) {
                    final report = _classReports[index];
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.class_, color: AppTheme.primary),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '${report['name']} - ${report['section']}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _reportStat(
                                    'Avg Attendance',
                                    report['avgAttendance'],
                                    Icons.fact_check_outlined,
                                    const Color(0xFFFFF3E0),
                                    const Color(0xFFFF9800),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: _reportStat(
                                    'Avg Marks',
                                    report['avgMarks'],
                                    Icons.analytics_outlined,
                                    const Color(0xFFEDE7F6),
                                    const Color(0xFF673AB7),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _reportStat(String title, String value, IconData icon, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
