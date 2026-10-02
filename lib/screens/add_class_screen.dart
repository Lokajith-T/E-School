import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../models/class_model.dart';
import '../models/teacher_model.dart';
import '../services/class_service.dart';
import '../services/teacher_service.dart';
import '../theme/app_theme.dart';

class AddClassScreen extends StatefulWidget {
  final String schoolId;
  const AddClassScreen({super.key, required this.schoolId});

  @override
  State<AddClassScreen> createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _classNameController = TextEditingController();
  final _sectionController = TextEditingController();
  String? _selectedTeacherId;

  bool _isLoading = false;
  final ClassService _classService = ClassService();
  final TeacherService _teacherService = TeacherService();
  
  List<TeacherModel> _teachers = [];

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }
  
  Future<void> _loadTeachers() async {
    // Only fetch for dropdown once
    _teacherService.streamTeachers(widget.schoolId).first.then((teachers) {
      if (mounted) {
        setState(() {
          _teachers = teachers;
        });
      }
    });
  }

  Future<void> _addClass() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final classModel = ClassModel(
        classId: '',
        schoolId: widget.schoolId,
        className: _classNameController.text.trim(),
        section: _sectionController.text.trim(),
        classTeacherId: _selectedTeacherId,
      );

      await _classService.addClass(classModel);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Class added successfully!'.tr()), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add class: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Class'.tr()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Class Details'.tr(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              TextFormField(
                controller: _classNameController,
                decoration: InputDecoration(labelText: 'Class Name (e.g. Class 10, Grade 8)'.tr(), border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _sectionController,
                decoration: InputDecoration(labelText: 'Section (e.g. A, B, North)'.tr(), border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Class Teacher (Optional)'.tr(), border: OutlineInputBorder()),
                initialValue: _selectedTeacherId,
                items: [
                  DropdownMenuItem(value: null, child: Text('None'.tr())),
                  ..._teachers.map((t) => DropdownMenuItem(
                    value: t.teacherId,
                    child: Text('${t.name} (${t.employeeId})'),
                  )),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedTeacherId = val;
                  });
                },
              ),
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _isLoading ? null : _addClass,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Save Class'.tr(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
