import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';
import '../models/timetable_model.dart';
import '../services/timetable_service.dart';
import '../config/schedule_config.dart';
import '../theme/app_theme.dart';

class ParentTimetableScreen extends StatefulWidget {
  final List<StudentModel> children;
  const ParentTimetableScreen({super.key, required this.children});

  @override
  State<ParentTimetableScreen> createState() => _ParentTimetableScreenState();
}

class _ParentTimetableScreenState extends State<ParentTimetableScreen> {
  final TimetableService _timetableService = TimetableService();
  StudentModel? _selectedChild;
  String _selectedDay = ScheduleConfig.weekdays.first;

  @override
  void initState() {
    super.initState();
    if (widget.children.isNotEmpty) {
      _selectedChild = widget.children.first;
    }
  }

  Stream<List<TimetableModel>> _streamTimetableForStudent(StudentModel student) async* {
    try {
      final classQuery = await FirebaseFirestore.instance.collection('classes')
          .where('schoolId', isEqualTo: student.schoolId)
          .where('className', isEqualTo: student.classId)
          .where('section', isEqualTo: student.section)
          .limit(1)
          .get();
          
      if (classQuery.docs.isEmpty) {
        yield [];
        return;
      }
      
      final classDocId = classQuery.docs.first.id;
      yield* _timetableService.streamTimetableByClass(student.schoolId, classDocId);
    } catch (e) {
      yield [];
    }
  }

  Future<Map<String, String>> _resolveNames(TimetableModel slot) async {
    String subjectName = slot.subjectId;
    String teacherName = slot.teacherId;
    
    try {
      final subjDoc = await FirebaseFirestore.instance.collection('subjects').doc(slot.subjectId).get();
      if (subjDoc.exists && subjDoc.data() != null) subjectName = subjDoc.data()!['subjectName'] ?? subjectName;
    } catch (_) {}

    try {
      var teacherDoc = await FirebaseFirestore.instance.collection('teachers').doc(slot.teacherId).get();
      if (teacherDoc.exists && teacherDoc.data() != null) teacherName = teacherDoc.data()!['name'] ?? teacherName;
    } catch (_) {}

    try {
      var teacherDoc = await FirebaseFirestore.instance.collection('users').doc(slot.teacherId).get();
      if (teacherDoc.exists && teacherDoc.data() != null) teacherName = teacherDoc.data()!['name'] ?? teacherName;
    } catch (_) {}
    
    return {'subjectName': subjectName, 'teacherName': teacherName};
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Class Timetable'.tr())),
        body: Center(child: Text('No children found.'.tr())),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Class Timetable'.tr())),
      body: Column(
        children: [
          if (widget.children.length > 1)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: DropdownButtonFormField<StudentModel>(
                decoration: InputDecoration(labelText: 'Select Child'.tr(), border: OutlineInputBorder()),
                initialValue: _selectedChild,
                items: widget.children.map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(c.name),
                )).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedChild = val;
                  });
                },
              ),
            ),
          Container(
            height: 60,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: ScheduleConfig.weekdays.length,
              itemBuilder: (context, index) {
                final day = ScheduleConfig.weekdays[index];
                final isSelected = day == _selectedDay;
                
                return InkWell(
                  onTap: () => setState(() => _selectedDay = day),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected ? AppTheme.primary : Colors.transparent,
                          width: 3,
                        )
                      )
                    ),
                    child: Text(
                      day,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppTheme.primary : Colors.grey.shade600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: _selectedChild == null 
                ? Center(child: Text('Please select a child.'.tr()))
                : StreamBuilder<List<TimetableModel>>(
                    stream: _streamTimetableForStudent(_selectedChild!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
                      
                      final allSlots = snapshot.data ?? [];
                      
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: ScheduleConfig.periods.length,
                        itemBuilder: (context, index) {
                          final pInfo = ScheduleConfig.periods[index];
                          final isBreak = pInfo['isBreak'] as bool;
                          final pNumber = pInfo['periodNumber'] as int;
                          
                          if (isBreak) {
                            return Card(
                              color: Colors.grey.shade100,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.coffee, color: Colors.grey),
                                    SizedBox(width: 8),
                                    Text('${pInfo['name']} (${pInfo['startTime']} - ${pInfo['endTime']})', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            );
                          }

                          final slot = allSlots.where((s) => s.dayOfWeek == _selectedDay && s.periodNumber == pNumber).firstOrNull;
                          
                          if (slot != null) {
                            return FutureBuilder<Map<String, String>>(
                              future: _resolveNames(slot),
                              builder: (context, nameSnapshot) {
                                final names = nameSnapshot.data ?? {'subjectName': 'Loading...', 'teacherName': 'Loading...'};
                                
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3)),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: CircleAvatar(
                                      backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                                      child: Text('$pNumber', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                                    ),
                                    title: Text(names['subjectName']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${pInfo['startTime']} - ${pInfo['endTime']}', style: TextStyle(color: Colors.blue.shade700, fontSize: 12)),
                                        Text('Teacher: ${names['teacherName']}', style: TextStyle(color: Colors.grey.shade700)),
                                      ],
                                    ),
                                  ),
                                );
                              }
                            );
                          } else {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.grey.shade100,
                                  child: Text('$pNumber', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                                ),
                                title: Text('Free Period'.tr(), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                                subtitle: Text('${pInfo['startTime']} - ${pInfo['endTime']}', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}
