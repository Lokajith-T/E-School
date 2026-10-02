import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../models/class_model.dart';
import '../models/subject_model.dart';
import '../models/exam_model.dart';
import '../services/class_service.dart';
import '../services/subject_service.dart';
import '../services/exam_service.dart';
import '../theme/app_theme.dart';

class AdminExamsScreen extends StatefulWidget {
  final String schoolId;
  const AdminExamsScreen({super.key, required this.schoolId});

  @override
  State<AdminExamsScreen> createState() => _AdminExamsScreenState();
}

class _AdminExamsScreenState extends State<AdminExamsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final ClassService _classService = ClassService();
  final SubjectService _subjectService = SubjectService();
  final ExamService _examService = ExamService();
  
  List<ClassModel> _classes = [];
  List<ExamModel> _exams = [];
  
  bool _isLoadingClasses = true;

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
    super.dispose();
  }

  Future<void> _loadClasses() async {
    try {
      final classes = await _classService.getClassesOnce(widget.schoolId);
      if (mounted) {
        setState(() {
          _classes = classes;
          _isLoadingClasses = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingClasses = false);
    }
  }

  Future<void> _loadExams() async {
    _examService.streamExams(widget.schoolId).listen((exams) {
      if (mounted) {
        setState(() {
          _exams = exams;
        });
      }
    });
  }

  void _showAddExamDialog() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => CreateExamScreen(schoolId: widget.schoolId, classes: _classes)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Exam Management'.tr()),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'manage_exams'.tr()),
            Tab(text: 'drafts_published'.tr()),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildManageExamsTab(),
          _buildStatusTab(),
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
              Text('All Exams'.tr(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  final cls = _classes.where((c) => c.classId == exam.classId).firstOrNull;
                  final className = cls != null ? '${cls.className} - ${cls.section}' : 'Unknown Class';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: exam.status == 'Published' ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                        child: Icon(Icons.assignment, color: exam.status == 'Published' ? Colors.green : Colors.orange),
                      ),
                      title: Text(exam.examName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('$className | Status: ${exam.status}'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Academic Year: ${exam.academicYear}'),
                              SizedBox(height: 8),
                              Text('Schedule:'.tr(), style: TextStyle(fontWeight: FontWeight.bold)),
                              ...exam.subjects.map((s) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Text('- ${s.subjectName}: ${DateFormat('MMM dd, yyyy').format(s.examDate)} (${s.startTime} - ${s.endTime}) [Max Marks: ${s.maxMarks}]'),
                              )),
                              SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (exam.status == 'Draft')
                                    TextButton(
                                      onPressed: () async {
                                        await _examService.updateExam(ExamModel(
                                          examId: exam.examId,
                                          schoolId: exam.schoolId,
                                          examName: exam.examName,
                                          academicYear: exam.academicYear,
                                          classId: exam.classId,
                                          subjects: exam.subjects,
                                          instructions: exam.instructions,
                                          status: 'Published',
                                          createdAt: exam.createdAt,
                                        ));
                                      },
                                      child: Text('Publish'.tr(), style: TextStyle(color: Colors.green)),
                                    ),
                                  if (exam.status == 'Published')
                                    TextButton(
                                      onPressed: () async {
                                        await _examService.updateExam(ExamModel(
                                          examId: exam.examId,
                                          schoolId: exam.schoolId,
                                          examName: exam.examName,
                                          academicYear: exam.academicYear,
                                          classId: exam.classId,
                                          subjects: exam.subjects,
                                          instructions: exam.instructions,
                                          status: 'Draft',
                                          createdAt: exam.createdAt,
                                        ));
                                      },
                                      child: Text('Unpublish'.tr(), style: TextStyle(color: Colors.orange)),
                                    ),
                                  TextButton(
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
                                    child: Text('Delete'.tr(), style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }

  Widget _buildStatusTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey.shade400),
          SizedBox(height: 16),
          Text('Total Exams: ${_exams.length}', style: TextStyle(fontSize: 18, color: Colors.grey.shade700)),
          Text('Published: ${_exams.where((e) => e.status == 'Published').length}', style: TextStyle(fontSize: 18, color: Colors.green)),
          Text('Drafts: ${_exams.where((e) => e.status == 'Draft').length}', style: TextStyle(fontSize: 18, color: Colors.orange)),
        ],
      ),
    );
  }
}

class CreateExamScreen extends StatefulWidget {
  final String schoolId;
  final List<ClassModel> classes;
  
  const CreateExamScreen({super.key, required this.schoolId, required this.classes});

  @override
  State<CreateExamScreen> createState() => _CreateExamScreenState();
}

class _CreateExamScreenState extends State<CreateExamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _examNameController = TextEditingController();
  final _academicYearController = TextEditingController(text: '2026-2027');
  final _instructionsController = TextEditingController();
  
  ClassModel? _selectedClass;
  List<SubjectModel> _classSubjects = [];
  final SubjectService _subjectService = SubjectService();
  final ExamService _examService = ExamService();
  
  // Schedule builder state
  final List<ExamSubject> _schedule = [];
  SubjectModel? _scheduleSubject;
  DateTime? _scheduleDate;
  TimeOfDay? _scheduleStartTime;
  TimeOfDay? _scheduleEndTime;
  final _maxMarksController = TextEditingController(text: '100');

  bool _isSubmitting = false;

  Future<void> _loadSubjectsForClass(String classId) async {
    try {
      final subjects = await _subjectService.streamSubjectsByClass(widget.schoolId, classId).first;
      if (mounted) {
        setState(() {
          _classSubjects = subjects;
          _scheduleSubject = null;
        });
      }
    } catch (e) {
      debugPrint('Error loading subjects: $e');
    }
  }

  void _addScheduleItem() {
    if (_scheduleSubject == null || _scheduleDate == null || _scheduleStartTime == null || _scheduleEndTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill all schedule fields.'.tr())));
      return;
    }
    
    // Check conflicts
    if (_schedule.any((s) => s.subjectId == _scheduleSubject!.subjectId)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('This subject is already in the schedule.'.tr())));
      return;
    }

    setState(() {
      _schedule.add(ExamSubject(
        subjectId: _scheduleSubject!.subjectId,
        subjectName: _scheduleSubject!.subjectName,
        examDate: _scheduleDate!,
        startTime: _scheduleStartTime!.format(context),
        endTime: _scheduleEndTime!.format(context),
        maxMarks: int.tryParse(_maxMarksController.text) ?? 100,
      ));
      
      // Reset some fields
      _scheduleSubject = null;
    });
  }

  Future<void> _saveExam(String status) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select a class.'.tr())));
      return;
    }
    if (_schedule.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please add at least one subject to the schedule.'.tr())));
      return;
    }

    setState(() => _isSubmitting = true);
    
    try {
      final newExam = ExamModel(
        examId: '',
        schoolId: widget.schoolId,
        examName: _examNameController.text.trim(),
        academicYear: _academicYearController.text.trim(),
        classId: _selectedClass!.classId,
        subjects: _schedule,
        instructions: _instructionsController.text.trim(),
        status: status,
      );
      
      await _examService.addExam(newExam);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exam $status Successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Exam'.tr())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _examNameController,
                decoration: InputDecoration(labelText: 'Exam Name (e.g., Mid-Term)'.tr()),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _academicYearController,
                decoration: InputDecoration(labelText: 'Academic Year (e.g., 2026-2027)'.tr()),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<ClassModel>(
                isExpanded: true,
                decoration: InputDecoration(labelText: 'Select Class & Section'.tr(), border: OutlineInputBorder()),
                initialValue: _selectedClass,
                items: widget.classes.map((c) => DropdownMenuItem(
                  value: c,
                  child: Text('${c.className} - ${c.section}'),
                )).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedClass = val;
                    _schedule.clear();
                  });
                  if (val != null) _loadSubjectsForClass(val.classId);
                },
              ),
              SizedBox(height: 24),
              Text('Exam Schedule & Subjects'.tr(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              if (_selectedClass == null) 
                Text('Please select a class first.'.tr())
              else ...[
                Card(
                  color: Colors.grey.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        DropdownButtonFormField<SubjectModel>(
                          isExpanded: true,
                          decoration: InputDecoration(labelText: 'select_subject'.tr(), border: OutlineInputBorder()),
                          initialValue: _scheduleSubject,
                          items: _classSubjects.map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.subjectName),
                          )).toList(),
                          onChanged: (val) => setState(() => _scheduleSubject = val),
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final d = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (d != null) setState(() => _scheduleDate = d);
                                },
                                icon: Icon(Icons.calendar_today, size: 16),
                                label: Text(_scheduleDate == null ? 'Date' : DateFormat('MMM dd').format(_scheduleDate!)),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 10, minute: 0));
                                  if (t != null) setState(() => _scheduleStartTime = t);
                                },
                                icon: Icon(Icons.access_time, size: 16),
                                label: Text(_scheduleStartTime == null ? 'Start' : _scheduleStartTime!.format(context)),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 12, minute: 0));
                                  if (t != null) setState(() => _scheduleEndTime = t);
                                },
                                icon: Icon(Icons.access_time, size: 16),
                                label: Text(_scheduleEndTime == null ? 'End' : _scheduleEndTime!.format(context)),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _maxMarksController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(labelText: 'Max Marks'.tr()),
                              ),
                            ),
                            SizedBox(width: 12),
                            FilledButton(
                              onPressed: _addScheduleItem,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 56),
                              ),
                              child: Text('Add Subject'.tr()),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                if (_schedule.isNotEmpty) ...[
                  Text('Scheduled Subjects:'.tr(), style: TextStyle(fontWeight: FontWeight.bold)),
                  ..._schedule.map((s) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${s.subjectName} (${s.maxMarks} marks)'),
                    subtitle: Text('${DateFormat('MMM dd, yyyy').format(s.examDate)} | ${s.startTime} - ${s.endTime}'),
                    trailing: IconButton(
                      icon: Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () => setState(() => _schedule.remove(s)),
                    ),
                  )),
                ],
              ],
              SizedBox(height: 24),
              TextFormField(
                controller: _instructionsController,
                maxLines: 3,
                decoration: InputDecoration(labelText: 'Instructions (Optional)'.tr()),
              ),
              SizedBox(height: 24),
              if (_isSubmitting)
                Center(child: CircularProgressIndicator())
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _saveExam('Draft'),
                        child: Text('Save as Draft'.tr()),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => _saveExam('Published'),
                        child: Text('Publish Exam'.tr()),
                      ),
                    ),
                  ],
                ),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
