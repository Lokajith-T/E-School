import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../models/class_model.dart';
import '../models/student_model.dart';
import '../models/attendance_model.dart';
import '../models/teacher_model.dart';
import '../services/class_service.dart';
import '../services/student_service.dart';
import '../services/attendance_service.dart';
import '../theme/app_theme.dart';

class TeacherAttendanceScreen extends StatefulWidget {
  final TeacherModel teacher;
  const TeacherAttendanceScreen({super.key, required this.teacher});

  @override
  State<TeacherAttendanceScreen> createState() => _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  final ClassService _classService = ClassService();
  final StudentService _studentService = StudentService();
  final AttendanceService _attendanceService = AttendanceService();
  
  List<ClassModel> _myClasses = [];
  ClassModel? _selectedClass;
  DateTime _selectedDate = DateTime.now();
  
  bool _isLoadingClasses = true;
  bool _isSaving = false;
  
  // Maps studentId to 'present', 'absent', 'late'
  final Map<String, String> _attendanceMap = {};

  @override
  void initState() {
    super.initState();
    _loadMyClasses();
  }

  Future<void> _loadMyClasses() async {
    // Ideally query classes where teacherId is in subjects or classTeacherId
    // For simplicity, we fetch all classes and filter those they teach
    // or just fetch all for now
    _classService.streamClasses(widget.teacher.schoolId).first.then((classes) {
      if (mounted) {
        setState(() {
          _myClasses = classes;
          _isLoadingClasses = false;
          if (_myClasses.isNotEmpty) {
            _selectedClass = _myClasses.first;
            _loadExistingAttendance();
          }
        });
      }
    });
  }

  void _loadExistingAttendance() async {
    if (_selectedClass == null) return;
    
    String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    
    _attendanceService.streamAttendanceByClassAndDate(
      widget.teacher.schoolId, 
      _selectedClass!.classId, 
      formattedDate
    ).first.then((records) {
      if (mounted) {
        setState(() {
          _attendanceMap.clear();
          for (var r in records) {
            _attendanceMap[r.studentId] = r.status;
          }
        });
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadExistingAttendance();
    }
  }

  Future<void> _saveAttendance(List<StudentModel> students) async {
    setState(() => _isSaving = true);
    
    try {
      String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      List<AttendanceModel> records = students.map((s) {
        return AttendanceModel(
          attendanceId: '',
          schoolId: widget.teacher.schoolId,
          classId: _selectedClass!.classId,
          studentId: s.studentId,
          date: formattedDate,
          status: _attendanceMap[s.studentId] ?? 'present', // Default to present if unmarked
          markedByTeacherId: widget.teacher.teacherId,
        );
      }).toList();
      
      await _attendanceService.saveAttendanceBatch(records);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Attendance saved successfully!'.tr())));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingClasses) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Mark Attendance'.tr()),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<ClassModel>(
                    decoration: InputDecoration(
                      labelText: 'select_class'.tr(),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                    ),
                    initialValue: _selectedClass,
                    items: _myClasses.map((c) => DropdownMenuItem(
                      value: c,
                      child: Text('${c.className} - ${c.section}'),
                    )).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedClass = val;
                      });
                      _loadExistingAttendance();
                    },
                  ),
                ),
                SizedBox(width: 12),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 20, color: AppTheme.primary),
                        SizedBox(width: 8),
                        Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: _selectedClass == null 
                ? Center(child: Text('Please select a class'.tr()))
                : StreamBuilder<List<StudentModel>>(
                    stream: _studentService.streamStudents(widget.teacher.schoolId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
                      
                      final students = (snapshot.data ?? []).where((s) => 
                          s.classId == _selectedClass!.className && 
                          s.section == _selectedClass!.section).toList();
                          
                      if (students.isEmpty) {
                        return Center(child: Text('No students in this class.'.tr()));
                      }
                      
                      return Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              itemCount: students.length,
                              itemBuilder: (context, index) {
                                final student = students[index];
                                final status = _attendanceMap[student.studentId] ?? 'present'; // default
                                
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        CircleAvatar(child: Text(student.name[0])),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                              Text('Admn: ${student.admissionNumber}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                            ],
                                          )
                                        ),
                                        SegmentedButton<String>(
                                          segments: [
                                            ButtonSegment(value: 'present', label: Text('P'.tr())),
                                            ButtonSegment(value: 'absent', label: Text('A'.tr())),
                                            ButtonSegment(value: 'late', label: Text('L'.tr())),
                                          ],
                                          selected: {status},
                                          onSelectionChanged: (Set<String> newSelection) {
                                            setState(() {
                                              _attendanceMap[student.studentId] = newSelection.first;
                                            });
                                          },
                                          style: ButtonStyle(
                                            backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                                              if (states.contains(WidgetState.selected)) {
                                                if (status == 'present') return Colors.green.shade100;
                                                if (status == 'absent') return Colors.red.shade100;
                                                if (status == 'late') return Colors.orange.shade100;
                                              }
                                              return null;
                                            }),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(16),
                            width: double.infinity,
                            color: Colors.white,
                            child: FilledButton(
                              onPressed: _isSaving ? null : () => _saveAttendance(students),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: AppTheme.primary,
                              ),
                              child: _isSaving
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Text('Save Attendance'.tr(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          )
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
