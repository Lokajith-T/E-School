import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../models/homework_model.dart';
import '../models/teacher_model.dart';
import '../models/class_model.dart';
import '../services/homework_service.dart';
import '../services/class_service.dart';
import '../theme/app_theme.dart';

class AddHomeworkScreen extends StatefulWidget {
  final TeacherModel teacher;
  const AddHomeworkScreen({super.key, required this.teacher});

  @override
  State<AddHomeworkScreen> createState() => _AddHomeworkScreenState();
}

class _AddHomeworkScreenState extends State<AddHomeworkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  
  final HomeworkService _homeworkService = HomeworkService();
  final ClassService _classService = ClassService();

  List<ClassModel> _myClasses = [];
  ClassModel? _selectedClass;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  
  bool _isLoadingClasses = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadMyClasses();
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

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _saveHomework() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select a class'.tr())));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final hw = HomeworkModel(
        homeworkId: '',
        schoolId: widget.teacher.schoolId,
        classId: _selectedClass!.classId,
        subjectId: 'general', // We haven't built subject selection for homework yet
        teacherId: widget.teacher.teacherId,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        assignedDate: DateTime.now(),
        dueDate: _dueDate,
      );

      await _homeworkService.addHomework(hw);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Homework assigned successfully!'.tr(), style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingClasses) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: Text('Assign Homework'.tr())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<ClassModel>(
                decoration: InputDecoration(labelText: 'Assign to Class'.tr(), border: OutlineInputBorder()),
                initialValue: _selectedClass,
                items: _myClasses.map((c) => DropdownMenuItem(
                  value: c,
                  child: Text('${c.className} - ${c.section}'),
                )).toList(),
                onChanged: (val) => setState(() => _selectedClass = val),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'.tr(), border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: InputDecoration(labelText: 'Description'.tr(), border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 16),
              InkWell(
                onTap: _selectDueDate,
                child: InputDecorator(
                  decoration: InputDecoration(labelText: 'due_date'.tr(), border: OutlineInputBorder()),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('MMM dd, yyyy').format(_dueDate)),
                      Icon(Icons.calendar_today, size: 20, color: AppTheme.primary),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveHomework,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Assign Homework'.tr(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
