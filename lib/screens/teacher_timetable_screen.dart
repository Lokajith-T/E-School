import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../models/timetable_model.dart';
import '../models/teacher_model.dart';
import '../models/class_model.dart';
import '../models/subject_model.dart';
import '../services/timetable_service.dart';
import '../services/class_service.dart';
import '../services/subject_service.dart';
import '../config/schedule_config.dart';
import '../theme/app_theme.dart';

class TeacherTimetableScreen extends StatefulWidget {
  final TeacherModel teacher;
  const TeacherTimetableScreen({super.key, required this.teacher});

  @override
  State<TeacherTimetableScreen> createState() => _TeacherTimetableScreenState();
}

class _TeacherTimetableScreenState extends State<TeacherTimetableScreen> {
  final TimetableService _timetableService = TimetableService();
  final ClassService _classService = ClassService();
  final SubjectService _subjectService = SubjectService();
  
  String _selectedDay = ScheduleConfig.weekdays.first;
  
  List<ClassModel> _classes = [];
  List<SubjectModel> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    try {
      final classes = await _classService.getClassesOnce(widget.teacher.schoolId);
      final subjects = await _subjectService.streamSubjectsByTeacher(widget.teacher.schoolId, widget.teacher.teacherId).first;
      if (mounted) {
        setState(() {
          _classes = classes;
          _subjects = subjects;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    return Scaffold(
      appBar: AppBar(title: Text('My Timetable'.tr())),
      body: Column(
        children: [
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
            child: StreamBuilder<List<TimetableModel>>(
              stream: _timetableService.streamTimetableByTeacher(widget.teacher.schoolId, widget.teacher.teacherId),
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
                      final cls = _classes.where((c) => c.classId == slot.classId).firstOrNull;
                      final subj = _subjects.where((s) => s.subjectId == slot.subjectId).firstOrNull;
                      
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
                            child: Text('${pInfo['periodNumber']}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(subj?.subjectName ?? 'Subject', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${pInfo['startTime']} - ${pInfo['endTime']}', style: TextStyle(color: Colors.blue.shade700, fontSize: 12)),
                              Text(cls != null ? 'Class: ${cls.className} - ${cls.section}' : 'Class', style: TextStyle(color: Colors.grey.shade700)),
                            ],
                          ),
                        ),
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
                            child: Text('${pInfo['periodNumber']}', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
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
          ),
        ],
      ),
    );
  }
}
