import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../models/class_model.dart';
import '../models/subject_model.dart';
import '../models/student_model.dart';
import '../models/teacher_model.dart';
import '../services/subject_service.dart';
import '../services/student_service.dart';
import '../services/teacher_service.dart';
import '../theme/app_theme.dart';
import 'add_student_screen.dart';

class ClassDetailsScreen extends StatefulWidget {
  final ClassModel classData;
  const ClassDetailsScreen({super.key, required this.classData});

  @override
  State<ClassDetailsScreen> createState() => _ClassDetailsScreenState();
}

class _ClassDetailsScreenState extends State<ClassDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SubjectService _subjectService = SubjectService();
  final StudentService _studentService = StudentService();
  final TeacherService _teacherService = TeacherService();
  
  List<TeacherModel> _allTeachers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTeachers();
  }
  
  Future<void> _loadTeachers() async {
    _teacherService.streamTeachers(widget.classData.schoolId).first.then((teachers) {
      if (mounted) {
        setState(() {
          _allTeachers = teachers;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddSubjectDialog() {
    final formKey = GlobalKey<FormState>();
    final subjectNameController = TextEditingController();
    String? selectedTeacherId;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Add Subject'.tr()),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: subjectNameController,
                      decoration: InputDecoration(labelText: 'Subject Name'.tr()),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'Assign Teacher (Optional)'.tr()),
                      initialValue: selectedTeacherId,
                      items: [
                        DropdownMenuItem(value: null, child: Text('None'.tr())),
                        ..._allTeachers.map((t) => DropdownMenuItem(
                          value: t.teacherId,
                          child: Text('${t.name} (${t.employeeId})'),
                        )),
                      ],
                      onChanged: (val) {
                        setDialogState(() {
                          selectedTeacherId = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'.tr()),
                ),
                FilledButton(
                  onPressed: isSubmitting ? null : () async {
                    if (!formKey.currentState!.validate()) return;
                    setDialogState(() => isSubmitting = true);
                    try {
                      final sub = SubjectModel(
                        subjectId: '',
                        schoolId: widget.classData.schoolId,
                        classId: widget.classData.classId,
                        subjectName: subjectNameController.text.trim(),
                        teacherId: selectedTeacherId,
                      );
                      await _subjectService.addSubject(sub);
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Subject added!'.tr())),
                        );
                      }
                    } catch (e) {
                      setDialogState(() => isSubmitting = false);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  child: isSubmitting 
                      ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Save'.tr()),
                ),
              ],
            );
          }
        );
      }
    );
  }

  Widget _buildSubjectsTab() {
    return StreamBuilder<List<SubjectModel>>(
      stream: _subjectService.streamSubjectsByClass(widget.classData.schoolId, widget.classData.classId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
        final subjects = snapshot.data ?? [];
        
        if (subjects.isEmpty) {
          return Center(child: Text('No subjects assigned yet.'.tr()));
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: subjects.length,
          itemBuilder: (context, index) {
            final sub = subjects[index];
            final teacherName = _allTeachers.where((t) => t.teacherId == sub.teacherId).firstOrNull?.name ?? 'Not Assigned';
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(sub.subjectName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Teacher: $teacherName'),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await _subjectService.deleteSubject(sub.subjectId);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStudentsTab() {
    return StreamBuilder<List<StudentModel>>(
      stream: _studentService.streamStudents(widget.classData.schoolId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
        
        // Filter students for this class/section
        final students = (snapshot.data ?? []).where((s) => 
            s.classId == widget.classData.className && 
            s.section == widget.classData.section).toList();
            
        if (students.isEmpty) {
          return Center(child: Text('No students in this class.'.tr()));
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: students.length,
          itemBuilder: (context, index) {
            final s = students[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(child: Text(s.name[0])),
                title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Admn: ${s.admissionNumber}'),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.classData.className} - ${widget.classData.section}'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primary,
          tabs: [
            Tab(text: 'subjects'.tr()),
            Tab(text: 'students'.tr()),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSubjectsTab(),
          _buildStudentsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddSubjectDialog();
          } else {
            _showAddStudentOptions();
          }
        },
        backgroundColor: AppTheme.primary,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddStudentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.person_add),
                title: Text('Register New Student'.tr()),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => AddStudentScreen(
                      schoolId: widget.classData.schoolId,
                      initialClass: widget.classData.className,
                      initialSection: widget.classData.section,
                    ),
                  ));
                },
              ),
              ListTile(
                leading: Icon(Icons.assignment_ind),
                title: Text('Assign Existing Student'.tr()),
                onTap: () {
                  Navigator.pop(context);
                  _showAssignExistingStudentDialog();
                },
              ),
            ],
          ),
        );
      }
    );
  }

  void _showAssignExistingStudentDialog() {
    String? selectedStudentId;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Assign Existing Student'.tr()),
              content: StreamBuilder<List<StudentModel>>(
                stream: _studentService.streamStudents(widget.classData.schoolId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
                  }
                  
                  // Filter out students already in this class
                  final availableStudents = (snapshot.data ?? []).where((s) => 
                      s.classId != widget.classData.className || 
                      s.section != widget.classData.section).toList();
                      
                  if (availableStudents.isEmpty) {
                    return Text('All registered students are already in this class.'.tr());
                  }

                  return DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: 'Select Student'.tr()),
                    initialValue: selectedStudentId,
                    items: availableStudents.map((s) => DropdownMenuItem(
                      value: s.studentId,
                      child: Text('${s.name} (${s.admissionNumber})'),
                    )).toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        selectedStudentId = val;
                      });
                    },
                  );
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'.tr()),
                ),
                FilledButton(
                  onPressed: isSubmitting ? null : () async {
                    if (selectedStudentId == null) return;
                    setDialogState(() => isSubmitting = true);
                    try {
                      await _studentService.updateStudent(selectedStudentId!, {
                        'classId': widget.classData.className,
                        'section': widget.classData.section,
                      });
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Student assigned to class successfully!'.tr())),
                        );
                      }
                    } catch (e) {
                      setDialogState(() => isSubmitting = false);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  child: isSubmitting 
                      ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Assign'.tr()),
                ),
              ],
            );
          }
        );
      }
    );
  }
}
