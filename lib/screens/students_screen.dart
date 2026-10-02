import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../models/student_model.dart';
import '../services/student_service.dart';
import '../theme/app_theme.dart';
import 'add_student_screen.dart';
import 'student_details_screen.dart';

class StudentsScreen extends StatefulWidget {
  final String schoolId;
  const StudentsScreen({super.key, required this.schoolId});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final StudentService _studentService = StudentService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Students'.tr()),
      ),
      body: StreamBuilder<List<StudentModel>>(
        stream: _studentService.streamStudents(widget.schoolId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final students = snapshot.data ?? [];
          if (students.isEmpty) {
            return Center(child: Text('No students found. Add a student to begin.'.tr()));
          }

          return ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentDetailsScreen(student: student),
                    ),
                  );
                },
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                  child: Icon(Icons.person, color: AppTheme.primary),
                ),
                title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Admn: ${student.admissionNumber} • Class: ${student.classId} ${student.section}'),
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () async {
                    bool? confirm = await showDialog(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: Text('Remove Student'.tr()),
                        content: Text('Are you sure you want to remove this student?'.tr()),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c, false), child: Text('Cancel'.tr())),
                          TextButton(onPressed: () => Navigator.pop(c, true), child: Text('Remove'.tr(), style: TextStyle(color: Colors.red))),
                        ],
                      )
                    );
                    if (confirm == true) {
                      await _studentService.deleteStudentData(student);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddStudentScreen(schoolId: widget.schoolId),
            ),
          );
        },
        backgroundColor: AppTheme.primary,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
