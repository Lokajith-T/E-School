import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';
import '../models/class_model.dart';
import '../services/student_service.dart';
import '../services/sim_service.dart';
import '../services/auth_service.dart';
import '../services/class_service.dart';
import '../theme/app_theme.dart';

class AddStudentScreen extends StatefulWidget {
  final String schoolId;
  final String? initialClass;
  final String? initialSection;
  const AddStudentScreen({super.key, required this.schoolId, this.initialClass, this.initialSection});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _admissionController = TextEditingController();
  final _studentMobileController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _parentMobileController = TextEditingController();

  final ClassService _classService = ClassService();
  List<ClassModel> _classes = [];
  ClassModel? _selectedClass;
  bool _isLoadingClasses = true;

  bool _isLoading = false;
  final StudentService _studentService = StudentService();

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    try {
      final classes = await _classService.getClassesOnce(widget.schoolId);
      setState(() {
        _classes = classes;
        _isLoadingClasses = false;
        
        if (widget.initialClass != null && widget.initialClass!.isNotEmpty) {
          try {
            _selectedClass = _classes.firstWhere(
              (c) => c.classId == widget.initialClass || (c.className == widget.initialClass && c.section == widget.initialSection),
            );
          } catch (_) {}
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingClasses = false;
        });
      }
    }
  }

  Future<void> _addStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final studentMobile = SimService.normalizeNumber(_studentMobileController.text.trim());
      final parentMobile = SimService.normalizeNumber(_parentMobileController.text.trim());

      // 1. Provision Parent User (or find existing)
      String parentUid = '';
      final parentQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('mobileNumber', isEqualTo: parentMobile)
          .where('role', isEqualTo: 'parent')
          .where('schoolId', isEqualTo: widget.schoolId)
          .limit(1)
          .get();

      if (parentQuery.docs.isNotEmpty) {
        parentUid = parentQuery.docs.first.id;
      } else {
        // Create new parent user auth and firestore profile
        parentUid = await AuthService().provisionUserAuth(parentMobile, role: 'parent');
        final parentDoc = FirebaseFirestore.instance.collection('users').doc(parentUid);
        await parentDoc.set({
          'uid': parentUid,
          'role': 'parent',
          'name': _parentNameController.text.trim(),
          'schoolId': widget.schoolId,
          'mobileNumber': parentMobile,
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // 2. Create Student Model
      final studentModel = StudentModel(
        studentId: '', // Will be generated in service
        uid: '',
        schoolId: widget.schoolId,
        admissionNumber: _admissionController.text.trim(),
        name: _nameController.text.trim(),
        classId: _selectedClass!.classId,
        section: _selectedClass!.section,
        parentIds: [parentUid],
        email: '',
        phone: studentMobile,
      );

      await _studentService.addStudent(studentModel);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Student added successfully!'.tr())),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add student: ${e.toString().replaceAll('Exception: ', '')}'),
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
        title: Text('Add Student'.tr()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Student Details'.tr(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Student Name'.tr(), border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _admissionController,
                decoration: InputDecoration(labelText: 'admission_number'.tr(), border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 16),
              _isLoadingClasses
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<ClassModel>(
                      initialValue: _selectedClass,
                      decoration: InputDecoration(
                        labelText: 'Class & Section'.tr(),
                        border: const OutlineInputBorder(),
                      ),
                      items: _classes.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text('${c.className} - ${c.section}'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedClass = val;
                        });
                      },
                      validator: (v) => v == null ? 'Required' : null,
                    ),
              SizedBox(height: 16),
              TextFormField(
                controller: _studentMobileController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Student Mobile Number (For Login)'.tr(),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_android),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              
              SizedBox(height: 32),
              Text('Parent Details'.tr(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              TextFormField(
                controller: _parentNameController,
                decoration: InputDecoration(labelText: 'Parent Name'.tr(), border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _parentMobileController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Parent Mobile Number (For Login)'.tr(),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_android),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),

              SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _isLoading ? null : _addStudent,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Save Student'.tr(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
