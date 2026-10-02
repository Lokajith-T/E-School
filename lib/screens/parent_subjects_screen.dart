import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';
import '../models/subject_model.dart';
import '../theme/app_theme.dart';

class ParentSubjectsScreen extends StatefulWidget {
  final List<StudentModel> children;
  const ParentSubjectsScreen({super.key, required this.children});

  @override
  State<ParentSubjectsScreen> createState() => _ParentSubjectsScreenState();
}

class _ParentSubjectsScreenState extends State<ParentSubjectsScreen> {
  StudentModel? _selectedChild;

  @override
  void initState() {
    super.initState();
    if (widget.children.isNotEmpty) {
      _selectedChild = widget.children.first;
    }
  }

  Stream<List<SubjectModel>> _streamSubjects(StudentModel student) async* {
    try {
      // Resolve actual class doc ID
      String actualClassId = student.classId;
      final classQuery = await FirebaseFirestore.instance.collection('classes')
          .where('schoolId', isEqualTo: student.schoolId)
          .where('className', isEqualTo: student.classId)
          .where('section', isEqualTo: student.section)
          .limit(1)
          .get();
      
      if (classQuery.docs.isNotEmpty) {
        actualClassId = classQuery.docs.first.id;
      }

      yield* FirebaseFirestore.instance.collection('subjects')
          .where('schoolId', isEqualTo: student.schoolId)
          .where('classId', isEqualTo: actualClassId)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => SubjectModel.fromMap(doc.data(), doc.id)).toList());
    } catch (e) {
      yield [];
    }
  }

  Future<String> _getTeacherName(String? teacherId) async {
    if (teacherId == null || teacherId.isEmpty) return 'Not Assigned';
    
    // Check teachers collection first (students have permission to read this)
    try {
      var doc = await FirebaseFirestore.instance.collection('teachers').doc(teacherId).get();
      if (doc.exists && doc.data() != null) return doc.data()!['name'] ?? 'Unknown';
    } catch (_) {}

    // Fallback to users collection (might throw permission denied for non-admins)
    try {
      var doc = await FirebaseFirestore.instance.collection('users').doc(teacherId).get();
      if (doc.exists && doc.data() != null) return doc.data()!['name'] ?? 'Unknown';
    } catch (_) {}
    
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Subjects'.tr())),
        body: Center(child: Text('No children found.'.tr())),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Subjects'.tr())),
      body: Column(
        children: [
          if (widget.children.length > 1)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: DropdownButtonFormField<StudentModel>(
                decoration: InputDecoration(labelText: 'Select Child'.tr(), border: OutlineInputBorder()),
                initialValue: _selectedChild,
                items: widget.children.map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(c.name),
                )).toList(),
                onChanged: (val) => setState(() => _selectedChild = val),
              ),
            ),
          Expanded(
            child: _selectedChild == null
                ? Center(child: Text('Please select a child.'.tr()))
                : StreamBuilder<List<SubjectModel>>(
                    stream: _streamSubjects(_selectedChild!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
                      
                      final subjects = snapshot.data ?? [];
                      if (subjects.isEmpty) return Center(child: Text('No subjects registered for this class yet.'.tr()));
                      
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: subjects.length,
                        itemBuilder: (context, index) {
                          final subject = subjects[index];
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.menu_book, color: AppTheme.primary),
                              ),
                              title: Text(subject.subjectName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              subtitle: FutureBuilder<String>(
                                future: _getTeacherName(subject.teacherId),
                                builder: (context, ts) {
                                  return Text('Teacher: ${ts.data ?? 'Loading...'}', style: TextStyle(color: Colors.grey.shade700));
                                }
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}
