import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../models/class_model.dart';
import '../models/subject_model.dart';
import '../models/student_model.dart';
import '../models/marks_model.dart';
import '../models/teacher_model.dart';
import '../models/exam_model.dart';
import '../services/class_service.dart';
import '../services/subject_service.dart';
import '../services/student_service.dart';
import '../services/marks_service.dart';
import '../services/exam_service.dart';
import '../theme/app_theme.dart';

class TeacherMarksScreen extends StatefulWidget {
  final TeacherModel teacher;
  const TeacherMarksScreen({super.key, required this.teacher});

  @override
  State<TeacherMarksScreen> createState() => _TeacherMarksScreenState();
}

class _TeacherMarksScreenState extends State<TeacherMarksScreen> {
  final ClassService _classService = ClassService();
  final SubjectService _subjectService = SubjectService();
  final StudentService _studentService = StudentService();
  final MarksService _marksService = MarksService();
  final ExamService _examService = ExamService();
  
  List<ClassModel> _myClasses = [];
  List<SubjectModel> _mySubjects = [];
  List<ExamModel> _exams = [];
  
  ClassModel? _selectedClass;
  SubjectModel? _selectedSubject;
  ExamModel? _selectedExam;
  
  bool _isLoadingClasses = true;
  bool _isSaving = false;
  
  // Maps studentId to their input controller
  final Map<String, TextEditingController> _marksControllers = {};

  @override
  void initState() {
    super.initState();
    _loadMyClasses();
  }
  
  @override
  void dispose() {
    for (var c in _marksControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadMyClasses() async {
    _classService.streamClasses(widget.teacher.schoolId).first.then((classes) {
      if (mounted) {
        setState(() {
          _myClasses = classes;
          _isLoadingClasses = false;
        });
      }
    });
  }

  Future<void> _loadExamsForClass(String classId) async {
    // Only load exams for the selected class that are published
    _examService.streamExams(widget.teacher.schoolId).listen((exams) {
      if (mounted) {
        setState(() {
          _exams = exams.where((e) => e.classId == classId && e.status == 'Published').toList();
          if (_selectedExam != null) {
            _selectedExam = _exams.where((e) => e.examId == _selectedExam!.examId).firstOrNull;
          }
        });
      }
    });
  }

  Future<void> _loadSubjectsForClass(String classId) async {
    _subjectService.streamSubjectsByClass(widget.teacher.schoolId, classId).first.then((subjects) {
      if (mounted) {
        setState(() {
          // Allow selecting any subject for the class to ensure it's not empty due to assignments
          _mySubjects = subjects.toList();
          _selectedSubject = _mySubjects.isNotEmpty ? _mySubjects.first : null;
        });
      }
    });
  }

  void _loadExistingMarks() async {
    if (_selectedClass == null || _selectedSubject == null || _selectedExam == null) return;

    // Validate that the selected subject is actually part of this exam
    final isSubjectInExam = _selectedExam!.subjects.any((s) => s.subjectId == _selectedSubject!.subjectId);
    if (!isSubjectInExam) {
      setState(() {
        for (var c in _marksControllers.values) {
          c.text = '';
        }
      });
      return;
    }
    
    _marksService.streamMarksByClassAndExam(
      widget.teacher.schoolId, 
      _selectedClass!.classId, 
      _selectedSubject!.subjectId,
      _selectedExam!.examName
    ).first.then((records) {
      if (mounted) {
        setState(() {
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
    });
  }

  Future<void> _saveMarks(List<StudentModel> students, String status) async {
    if (_selectedClass == null || _selectedSubject == null || _selectedExam == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select class, subject and Exam.'.tr())));
      return;
    }
    
    final examSubject = _selectedExam!.subjects.where((s) => s.subjectId == _selectedSubject!.subjectId).firstOrNull;
    if (examSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('This subject is not part of the selected exam.'.tr())));
      return;
    }

    setState(() => _isSaving = true);
    
    try {
      List<MarksModel> records = [];
      for (var s in students) {
        String marksText = _marksControllers[s.studentId]?.text.trim() ?? '';
        if (marksText.isNotEmpty) {
          int marksObtained = int.tryParse(marksText) ?? -1;
          if (marksObtained < 0 || marksObtained > examSubject.maxMarks) {
            throw Exception('Invalid marks for student ${s.name}. Must be between 0 and ${examSubject.maxMarks}.');
          }

          records.add(MarksModel(
            markId: '',
            schoolId: widget.teacher.schoolId,
            classId: _selectedClass!.classId,
            subjectId: _selectedSubject!.subjectId,
            studentId: s.studentId,
            examName: _selectedExam!.examName,
            marksObtained: marksObtained,
            maxMarks: examSubject.maxMarks,
            teacherId: widget.teacher.teacherId,
            status: status,
            createdAt: DateTime.now(),
          ));
        }
      }
      
      if (records.isNotEmpty) {
        await _marksService.saveMarksBatch(records);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Marks $status successfully!')));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No marks entered to save.'.tr())));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingClasses) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    final isSubjectInExam = _selectedExam != null && _selectedSubject != null && _selectedExam!.subjects.any((s) => s.subjectId == _selectedSubject!.subjectId);
    final examSubject = isSubjectInExam ? _selectedExam!.subjects.firstWhere((s) => s.subjectId == _selectedSubject!.subjectId) : null;

    return Scaffold(
      appBar: AppBar(title: Text('Mark Allocation'.tr())),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: InputDecoration(labelText: 'select_class'.tr(), border: OutlineInputBorder()),
                        initialValue: _selectedClass?.classId,
                        items: _myClasses.map((c) => DropdownMenuItem(
                          value: c.classId,
                          child: Text('${c.className} - ${c.section}', overflow: TextOverflow.ellipsis),
                        )).toList(),
                        onChanged: (val) {
                          if (val == null) return;
                          final selected = _myClasses.firstWhere((c) => c.classId == val);
                          setState(() {
                            _selectedClass = selected;
                            _selectedSubject = null;
                            _mySubjects = [];
                            _selectedExam = null;
                            _exams = [];
                          });
                          _loadSubjectsForClass(selected.classId);
                          _loadExamsForClass(selected.classId);
                        },
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: InputDecoration(labelText: 'select_subject'.tr(), border: OutlineInputBorder()),
                        initialValue: _selectedSubject?.subjectId,
                        items: _mySubjects.map((s) => DropdownMenuItem(
                          value: s.subjectId,
                          child: Text(s.subjectName, overflow: TextOverflow.ellipsis),
                        )).toList(),
                        onChanged: (val) {
                          if (val == null) return;
                          setState(() => _selectedSubject = _mySubjects.firstWhere((s) => s.subjectId == val));
                          _loadExistingMarks();
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: InputDecoration(labelText: 'Select Published Exam'.tr(), border: OutlineInputBorder()),
                        initialValue: _selectedExam?.examId,
                        items: _exams.map((e) => DropdownMenuItem(
                          value: e.examId,
                          child: Text(e.examName, overflow: TextOverflow.ellipsis),
                        )).toList(),
                        onChanged: (val) {
                          if (val == null) return;
                          setState(() => _selectedExam = _exams.firstWhere((e) => e.examId == val));
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
                )
              ],
            ),
          ),
          if (_selectedExam != null && _selectedSubject != null && !isSubjectInExam)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
                      SizedBox(height: 16),
                      Text('Subject Not in Exam'.tr(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                      SizedBox(height: 8),
                      Text('The subject "${_selectedSubject!.subjectName}" is not scheduled for "${_selectedExam!.examName}".', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: _selectedClass == null 
                  ? Center(child: Text('Please select class, subject, and exam'.tr()))
                  : StreamBuilder<List<StudentModel>>(
                      stream: _studentService.streamStudents(widget.teacher.schoolId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
                        
                        final students = (snapshot.data ?? []).where((s) => 
                            s.classId == _selectedClass!.className && 
                            s.section == _selectedClass!.section).toList();
                            
                        if (students.isEmpty) return Center(child: Text('No students in this class.'.tr()));
                        
                        return Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              color: Colors.grey.shade100,
                              width: double.infinity,
                              child: Text(
                                examSubject != null ? 'Max Marks: ${examSubject.maxMarks}' : 'Enter Marks',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                                textAlign: TextAlign.right,
                              ),
                            ),
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
                                            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
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
                                            width: 100,
                                            child: TextFormField(
                                              controller: _marksControllers[student.studentId],
                                              keyboardType: TextInputType.number,
                                              textAlign: TextAlign.center,
                                              decoration: InputDecoration(
                                                hintText: examSubject != null ? '/ ${examSubject.maxMarks}' : '/ 100',
                                                border: const OutlineInputBorder(),
                                                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
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
                              child: Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _isSaving ? null : () => _saveMarks(students, 'Draft'),
                                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                                      child: Text('Save as Draft'.tr()),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: _isSaving ? null : () => _saveMarks(students, 'Published'),
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        backgroundColor: AppTheme.primary,
                                      ),
                                      child: _isSaving
                                          ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                          : Text('Submit / Publish'.tr(), style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
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
