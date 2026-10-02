import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../models/class_model.dart';
import '../models/subject_model.dart';
import '../models/student_model.dart';
import '../models/marks_model.dart';
import '../models/exam_model.dart';
import '../services/class_service.dart';
import '../services/subject_service.dart';
import '../services/student_service.dart';
import '../services/marks_service.dart';
import '../services/exam_service.dart';
import '../theme/app_theme.dart';

class AdminMarksScreen extends StatefulWidget {
  final String schoolId;
  const AdminMarksScreen({super.key, required this.schoolId});

  @override
  State<AdminMarksScreen> createState() => _AdminMarksScreenState();
}

class _AdminMarksScreenState extends State<AdminMarksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final ClassService _classService = ClassService();
  final SubjectService _subjectService = SubjectService();
  final StudentService _studentService = StudentService();
  final MarksService _marksService = MarksService();
  final ExamService _examService = ExamService();
  
  List<ClassModel> _classes = [];
  List<SubjectModel> _subjects = [];
  List<ExamModel> _exams = [];
  
  ClassModel? _selectedClass;
  SubjectModel? _selectedSubject;
  ExamModel? _selectedExam;
  
  String _status = 'Initializing...';
  bool _isLoadingClasses = true;
  bool _isSaving = false;
  
  final Map<String, TextEditingController> _marksControllers = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadClasses();
    _loadExams();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    for (var c in _marksControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadClasses() async {
    setState(() => _status = 'Loading classes...');
    try {
      final classes = await _classService.getClassesOnce(widget.schoolId);
      if (mounted) {
        setState(() {
          _classes = classes;
          _isLoadingClasses = false;
          _status = 'Loaded ${classes.length} classes';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingClasses = false;
          _status = 'ERROR: $e';
        });
      }
    }
  }

  Future<void> _loadExams() async {
    _examService.streamExams(widget.schoolId).listen((exams) {
      if (mounted) {
        setState(() {
          _exams = exams;
          // Ensure _selectedExam remains valid if it exists
          if (_selectedExam != null) {
            final match = _exams.where((e) => e.examId == _selectedExam!.examId).firstOrNull;
            _selectedExam = match;
          }
        });
      }
    });
  }

  Future<void> _loadSubjectsForClass(String classId) async {
    try {
      final subjects = await _subjectService.streamSubjectsByClass(widget.schoolId, classId).first;
      if (mounted) {
        setState(() {
          _subjects = subjects;
          _selectedSubject = _subjects.isNotEmpty ? _subjects.first : null;
        });
      }
    } catch (e) {
      debugPrint('Error loading subjects: $e');
    }
  }

  void _loadExistingMarks() async {
    if (_selectedClass == null || _selectedSubject == null || _selectedExam == null) {
      return;
    }
    
    try {
      final records = await _marksService.streamMarksByClassAndExam(
        widget.schoolId, 
        _selectedClass!.classId, 
        _selectedSubject!.subjectId,
        _selectedExam!.examName
      ).first;
      
      if (mounted) {
        setState(() {
          // Clear current marks
          for (var c in _marksControllers.values) {
            c.text = '';
          }
          for (var r in records) {
            if (_marksControllers.containsKey(r.studentId)) {
              _marksControllers[r.studentId]!.text = r.marksObtained.toString();
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading marks: $e');
    }
  }

  Future<void> _saveMarks(List<StudentModel> students) async {
    if (_selectedClass == null || _selectedSubject == null || _selectedExam == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select class, subject and Exam.'.tr())));
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      List<MarksModel> records = [];
      for (var s in students) {
        String marksText = _marksControllers[s.studentId]?.text.trim() ?? '';
        if (marksText.isNotEmpty) {
          int marksObtained = int.tryParse(marksText) ?? 0;
          records.add(MarksModel(
            markId: '',
            schoolId: widget.schoolId,
            classId: _selectedClass!.classId,
            subjectId: _selectedSubject!.subjectId,
            studentId: s.studentId,
            examName: _selectedExam!.examName,
            marksObtained: marksObtained,
            maxMarks: 100,
            teacherId: 'admin',
            createdAt: DateTime.now(),
          ));
        }
      }
      
      if (records.isNotEmpty) {
        await _marksService.saveMarksBatch(records);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Marks saved successfully!'.tr())));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No marks entered to save.'.tr())));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showAddExamDialog() {
    final formKey = GlobalKey<FormState>();
    final examNameController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Create Exam'.tr()),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: examNameController,
                      decoration: InputDecoration(labelText: 'Exam Name (e.g. Term 1)'.tr()),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
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
                      final newExam = ExamModel(
                        examId: '',
                        schoolId: widget.schoolId,
                        examName: examNameController.text.trim(),
                        academicYear: '',
                        classId: '',
                        subjects: [],
                      );
                      await _examService.addExam(newExam);
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exam Created Successfully'.tr())));
                      }
                    } catch (e) {
                      setDialogState(() => isSubmitting = false);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                      }
                    }
                  },
                  child: isSubmitting ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('Create'.tr()),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Exams & Marks Allocation'.tr()),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'manage_exams'.tr()),
            Tab(text: 'Allocate Marks'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildManageExamsTab(),
          _buildAllocateMarksTab(),
        ],
      ),
    );
  }

  Widget _buildManageExamsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Exams'.tr(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              FilledButton.icon(
                onPressed: _showAddExamDialog,
                icon: Icon(Icons.add),
                label: Text('Create Exam'.tr()),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  minimumSize: const Size(0, 48),
                ),
              )
            ],
          ),
        ),
        Expanded(
          child: _exams.isEmpty 
            ? Center(child: Text('No exams found. Create an exam first.'.tr()))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _exams.length,
                itemBuilder: (context, index) {
                  final exam = _exams[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                        child: Icon(Icons.assignment, color: AppTheme.primary),
                      ),
                      title: Text(exam.examName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: Text('Delete Exam'.tr()),
                              content: Text('Are you sure you want to delete this exam?'.tr()),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(c, false), child: Text('Cancel'.tr())),
                                TextButton(onPressed: () => Navigator.pop(c, true), child: Text('Delete'.tr(), style: TextStyle(color: Colors.red))),
                              ],
                            )
                          );
                          if (confirm == true) {
                            await _examService.deleteExam(exam.examId);
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }

  Widget _buildAllocateMarksTab() {
    if (_isLoadingClasses) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(_status, style: const TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    if (_classes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.class_outlined, size: 64, color: Colors.grey.shade400),
              SizedBox(height: 16),
              Text('No classes found'.tr(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
              SizedBox(height: 8),
              Text(_status, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500)),
              SizedBox(height: 8),
              Text('Create classes first from Classes menu.'.tr(), textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<ClassModel>(
                      isExpanded: true,
                      decoration: InputDecoration(labelText: 'select_class'.tr(), border: OutlineInputBorder()),
                      initialValue: _selectedClass,
                      items: _classes.map((c) => DropdownMenuItem(
                        value: c,
                        child: Text('${c.className} - ${c.section}'),
                      )).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedClass = val;
                          _selectedSubject = null;
                          _subjects = [];
                        });
                        if (val != null) _loadSubjectsForClass(val.classId);
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<SubjectModel>(
                      isExpanded: true,
                      decoration: InputDecoration(labelText: 'select_subject'.tr(), border: OutlineInputBorder()),
                      initialValue: _selectedSubject,
                      items: _subjects.map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.subjectName),
                      )).toList(),
                      onChanged: (val) {
                        setState(() => _selectedSubject = val);
                        _loadExistingMarks();
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<ExamModel>(
                      isExpanded: true,
                      decoration: InputDecoration(labelText: 'Select Exam'.tr(), border: OutlineInputBorder()),
                      initialValue: _selectedExam,
                      items: _exams.map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.examName),
                      )).toList(),
                      onChanged: (val) {
                        setState(() => _selectedExam = val);
                        _loadExistingMarks();
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  FilledButton(
                    onPressed: _loadExistingMarks,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      minimumSize: const Size(0, 56),
                    ),
                    child: Text('Load'.tr()),
                  )
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _selectedClass == null 
              ? Center(child: Text('Please select a class above'.tr(), style: TextStyle(fontSize: 16, color: Colors.grey.shade600)))
              : StreamBuilder<List<StudentModel>>(
                  stream: _studentService.streamStudents(widget.schoolId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
                    if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                    
                    final students = (snapshot.data ?? []).where((s) => 
                        s.classId == _selectedClass!.className && 
                        s.section == _selectedClass!.section).toList();
                        
                    if (students.isEmpty) return Center(child: Text('No students in this class.'.tr()));
                    
                    return Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: students.length,
                            itemBuilder: (context, index) {
                              final student = students[index];
                              if (!_marksControllers.containsKey(student.studentId)) {
                                _marksControllers[student.studentId] = TextEditingController();
                              }
                              
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                                        child: Text(student.name[0], style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                                      ),
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
                                      SizedBox(
                                        width: 80,
                                        child: TextFormField(
                                          controller: _marksControllers[student.studentId],
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          decoration: InputDecoration(
                                            hintText: '/ 100'.tr(),
                                            border: OutlineInputBorder(),
                                            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                          ),
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
                            onPressed: _isSaving ? null : () => _saveMarks(students),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: AppTheme.primary,
                            ),
                            child: _isSaving
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text('Save Marks'.tr(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        )
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
}
