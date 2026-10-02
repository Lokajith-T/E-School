import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../models/class_model.dart';
import '../models/teacher_model.dart';
import '../models/subject_model.dart';
import '../models/timetable_model.dart';
import '../services/class_service.dart';
import '../services/teacher_service.dart';
import '../services/subject_service.dart';
import '../services/timetable_service.dart';
import '../config/schedule_config.dart';
import '../theme/app_theme.dart';

class AdminTimetableScreen extends StatefulWidget {
  final String schoolId;
  const AdminTimetableScreen({super.key, required this.schoolId});

  @override
  State<AdminTimetableScreen> createState() => _AdminTimetableScreenState();
}

class _AdminTimetableScreenState extends State<AdminTimetableScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final ClassService _classService = ClassService();
  final TeacherService _teacherService = TeacherService();
  final SubjectService _subjectService = SubjectService();
  final TimetableService _timetableService = TimetableService();

  List<ClassModel> _classes = [];
  List<TeacherModel> _teachers = [];
  List<SubjectModel> _subjects = [];

  ClassModel? _selectedClass;
  TeacherModel? _selectedTeacher;
  String _selectedWeekday = ScheduleConfig.weekdays.first;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final classes = await _classService.getClassesOnce(widget.schoolId);
      final teachers = await _teacherService.streamTeachers(widget.schoolId).first;
      
      if (mounted) {
        setState(() {
          _classes = classes;
          _teachers = teachers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSubjectsForClass(String classId) async {
    final subjects = await _subjectService.streamSubjectsByClass(widget.schoolId, classId).first;
    if (mounted) {
      setState(() {
        _subjects = subjects;
      });
    }
  }

  Future<void> _loadSubjectsForTeacher(String teacherId) async {
    // For teacher timetable, we need all subjects they teach across all classes
    final subjects = await _subjectService.streamSubjectsByTeacher(widget.schoolId, teacherId).first;
    if (mounted) {
      setState(() {
        _subjects = subjects;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: Text('Timetable Management'.tr()),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'student_timetable'.tr()),
            Tab(text: 'teacher_timetable'.tr()),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStudentTimetableTab(),
          _buildTeacherTimetableTab(),
        ],
      ),
    );
  }

  Widget _buildStudentTimetableTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: DropdownButtonFormField<ClassModel>(
            decoration: InputDecoration(labelText: 'select_class'.tr(), border: OutlineInputBorder()),
            initialValue: _selectedClass,
            items: _classes.map((c) => DropdownMenuItem(
              value: c,
              child: Text('${c.className} - ${c.section}'),
            )).toList(),
            onChanged: (val) {
              setState(() {
                _selectedClass = val;
                _selectedWeekday = ScheduleConfig.weekdays.first;
              });
              if (val != null) _loadSubjectsForClass(val.classId);
            },
          ),
        ),
        if (_selectedClass != null) ...[
          _buildWeekdaySelector(),
          Expanded(
            child: StreamBuilder<List<TimetableModel>>(
              stream: _timetableService.streamTimetableByClass(widget.schoolId, _selectedClass!.classId),
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
                      return _buildBreakCard(pInfo['name'], pInfo['startTime'], pInfo['endTime']);
                    }

                    // Find if there's a slot assigned here
                    final slot = allSlots.where((s) => s.dayOfWeek == _selectedWeekday && s.periodNumber == pNumber).firstOrNull;
                    
                    return _buildEditableSlotCard(
                      pInfo: pInfo,
                      currentSlot: slot,
                      onAssign: () => _showAssignDialog(
                        isStudentView: true,
                        periodNumber: pNumber,
                        dayOfWeek: _selectedWeekday,
                        existingSlot: slot,
                        contextClassId: _selectedClass!.classId,
                      ),
                      onClear: slot != null ? () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: Text('Clear Assignment'.tr()),
                            content: Text('Are you sure you want to clear this period?'.tr()),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c, false), child: Text('Cancel'.tr())),
                              TextButton(onPressed: () => Navigator.pop(c, true), child: Text('Clear'.tr(), style: TextStyle(color: Colors.red))),
                            ],
                          )
                        );
                        if (confirm == true) {
                          await _timetableService.deleteTimetableSlot(slot.timetableId);
                        }
                      } : null,
                    );
                  },
                );
              },
            ),
          )
        ] else
          Expanded(child: Center(child: Text('Select a class to view and edit its timetable.'.tr()))),
      ],
    );
  }

  Widget _buildTeacherTimetableTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: DropdownButtonFormField<TeacherModel>(
            decoration: InputDecoration(labelText: 'select_teacher'.tr(), border: OutlineInputBorder()),
            initialValue: _selectedTeacher,
            items: _teachers.map((t) => DropdownMenuItem(
              value: t,
              child: Text(t.name),
            )).toList(),
            onChanged: (val) {
              setState(() {
                _selectedTeacher = val;
                _selectedWeekday = ScheduleConfig.weekdays.first;
              });
              if (val != null) _loadSubjectsForTeacher(val.teacherId);
            },
          ),
        ),
        if (_selectedTeacher != null) ...[
          _buildWeekdaySelector(),
          Expanded(
            child: StreamBuilder<List<TimetableModel>>(
              stream: _timetableService.streamTimetableByTeacher(widget.schoolId, _selectedTeacher!.teacherId),
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
                      return _buildBreakCard(pInfo['name'], pInfo['startTime'], pInfo['endTime']);
                    }

                    // Find if there's a slot assigned here
                    final slot = allSlots.where((s) => s.dayOfWeek == _selectedWeekday && s.periodNumber == pNumber).firstOrNull;
                    
                    return _buildEditableSlotCard(
                      pInfo: pInfo,
                      currentSlot: slot,
                      onAssign: () => _showAssignDialog(
                        isStudentView: false,
                        periodNumber: pNumber,
                        dayOfWeek: _selectedWeekday,
                        existingSlot: slot,
                        contextTeacherId: _selectedTeacher!.teacherId,
                      ),
                      onClear: slot != null ? () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: Text('Clear Assignment'.tr()),
                            content: Text('Are you sure you want to clear this period?'.tr()),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c, false), child: Text('Cancel'.tr())),
                              TextButton(onPressed: () => Navigator.pop(c, true), child: Text('Clear'.tr(), style: TextStyle(color: Colors.red))),
                            ],
                          )
                        );
                        if (confirm == true) {
                          await _timetableService.deleteTimetableSlot(slot.timetableId);
                        }
                      } : null,
                    );
                  },
                );
              },
            ),
          )
        ] else
          Expanded(child: Center(child: Text('Select a teacher to view and edit their timetable.'.tr()))),
      ],
    );
  }

  Widget _buildWeekdaySelector() {
    return Container(
      color: Colors.white,
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: ScheduleConfig.weekdays.length,
        itemBuilder: (context, index) {
          final day = ScheduleConfig.weekdays[index];
          final isSelected = _selectedWeekday == day;
          return InkWell(
            onTap: () => setState(() => _selectedWeekday = day),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
                  color: isSelected ? AppTheme.primary : Colors.grey.shade700,
                )
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBreakCard(String name, String start, String end) {
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
            Text('$name ($start - $end)', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableSlotCard({
    required Map<String, dynamic> pInfo,
    required TimetableModel? currentSlot,
    required VoidCallback onAssign,
    VoidCallback? onClear,
  }) {
    final hasSlot = currentSlot != null;
    
    // Attempt to resolve names
    String title = 'Unassigned';
    String subtitle = 'Tap to assign subject and teacher';
    
    if (hasSlot) {
      final subj = _subjects.where((s) => s.subjectId == currentSlot.subjectId).firstOrNull;
      final teacher = _teachers.where((t) => t.teacherId == currentSlot.teacherId).firstOrNull;
      final cls = _classes.where((c) => c.classId == currentSlot.classId).firstOrNull;
      
      title = subj?.subjectName ?? 'Unknown Subject';
      if (_tabController.index == 0) { // Student view -> show teacher
        subtitle = teacher != null ? 'Teacher: ${teacher.name}' : 'Unknown Teacher';
      } else { // Teacher view -> show class
        subtitle = cls != null ? 'Class: ${cls.className} - ${cls.section}' : 'Unknown Class';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: hasSlot ? AppTheme.primary.withValues(alpha: 0.3) : Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: hasSlot ? AppTheme.primary.withValues(alpha: 0.1) : Colors.grey.shade100,
          child: Text('${pInfo['periodNumber']}', style: TextStyle(color: hasSlot ? AppTheme.primary : Colors.grey, fontWeight: FontWeight.bold)),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: hasSlot ? Colors.black : Colors.grey)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${pInfo['startTime']} - ${pInfo['endTime']}', style: TextStyle(color: Colors.blue.shade700, fontSize: 12)),
            Text(subtitle, style: TextStyle(color: Colors.grey.shade700)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasSlot)
              IconButton(
                icon: Icon(Icons.clear, color: Colors.red),
                onPressed: onClear,
              ),
            IconButton(
              icon: Icon(hasSlot ? Icons.edit : Icons.add_circle, color: AppTheme.primary),
              onPressed: onAssign,
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignDialog({
    required bool isStudentView,
    required int periodNumber,
    required String dayOfWeek,
    required TimetableModel? existingSlot,
    String? contextClassId,
    String? contextTeacherId,
  }) {
    SubjectModel? dialogSubject;
    TeacherModel? dialogTeacher;
    ClassModel? dialogClass;
    bool isSubmitting = false;

    // Filter available subjects based on context
    List<SubjectModel> availableSubjects = [];
    if (isStudentView && contextClassId != null) {
      availableSubjects = _subjects; // Already filtered for class
      
      // Attempt pre-select if editing
      if (existingSlot != null) {
        dialogSubject = availableSubjects.where((s) => s.subjectId == existingSlot.subjectId).firstOrNull;
        dialogTeacher = _teachers.where((t) => t.teacherId == existingSlot.teacherId).firstOrNull;
      }
    } else if (!isStudentView && contextTeacherId != null) {
      availableSubjects = _subjects; // Already filtered for teacher
      
      if (existingSlot != null) {
        dialogSubject = availableSubjects.where((s) => s.subjectId == existingSlot.subjectId).firstOrNull;
        dialogClass = _classes.where((c) => c.classId == existingSlot.classId).firstOrNull;
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existingSlot != null ? 'Edit Period $periodNumber ($dayOfWeek)' : 'Assign Period $periodNumber ($dayOfWeek)'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isStudentView) ...[
                      DropdownButtonFormField<ClassModel>(
                        decoration: InputDecoration(labelText: 'select_class'.tr(), border: OutlineInputBorder()),
                        initialValue: dialogClass,
                        items: _classes.map((c) => DropdownMenuItem(value: c, child: Text('${c.className} - ${c.section}'))).toList(),
                        onChanged: (v) {
                          setDialogState(() {
                            dialogClass = v;
                            dialogSubject = null;
                          });
                        },
                      ),
                      SizedBox(height: 12),
                    ],
                    
                    DropdownButtonFormField<SubjectModel>(
                      decoration: InputDecoration(labelText: 'select_subject'.tr(), border: OutlineInputBorder()),
                      initialValue: dialogSubject,
                      items: availableSubjects.where((s) {
                        if (!isStudentView && dialogClass != null) {
                          return s.classId == dialogClass!.classId;
                        }
                        return true;
                      }).map((s) => DropdownMenuItem(value: s, child: Text(s.subjectName))).toList(),
                      onChanged: (v) {
                        setDialogState(() {
                          dialogSubject = v;
                          // If in student view, auto-select the teacher for this subject
                          if (isStudentView && v != null) {
                            dialogTeacher = _teachers.where((t) => t.teacherId == v.teacherId).firstOrNull;
                          }
                        });
                      },
                    ),
                    SizedBox(height: 12),

                    if (isStudentView) ...[
                      DropdownButtonFormField<TeacherModel>(
                        decoration: InputDecoration(labelText: 'select_teacher'.tr(), border: OutlineInputBorder()),
                        initialValue: dialogTeacher,
                        items: _teachers.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                        onChanged: (v) => setDialogState(() => dialogTeacher = v),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel'.tr())),
                FilledButton(
                  onPressed: isSubmitting ? null : () async {
                    if (dialogSubject == null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Subject is required'.tr())));
                      return;
                    }
                    if (isStudentView && dialogTeacher == null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Teacher is required'.tr())));
                      return;
                    }
                    if (!isStudentView && dialogClass == null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Class is required'.tr())));
                      return;
                    }

                    setDialogState(() => isSubmitting = true);
                    try {
                      // Check for conflicts (simplified for now, full conflict detection would check stream bounds)
                      // The robust way is a transaction, but we'll try to just overwrite/save for now
                      if (existingSlot != null) {
                        await _timetableService.deleteTimetableSlot(existingSlot.timetableId);
                      }
                      
                      await _timetableService.addTimetableSlot(TimetableModel(
                        timetableId: '',
                        schoolId: widget.schoolId,
                        classId: isStudentView ? contextClassId! : dialogClass!.classId,
                        dayOfWeek: dayOfWeek,
                        subjectId: dialogSubject!.subjectId,
                        teacherId: isStudentView ? dialogTeacher!.teacherId : contextTeacherId!,
                        periodNumber: periodNumber,
                      ));
                      
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Assignment Saved'.tr())));
                      }
                    } catch (e) {
                      setDialogState(() => isSubmitting = false);
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  child: isSubmitting ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('Save'.tr()),
                ),
              ],
            );
          }
        );
      }
    );
  }
}
