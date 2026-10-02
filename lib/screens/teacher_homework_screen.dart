import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../models/homework_model.dart';
import '../models/teacher_model.dart';
import '../services/homework_service.dart';
import '../theme/app_theme.dart';
import 'add_homework_screen.dart';

class TeacherHomeworkScreen extends StatefulWidget {
  final TeacherModel teacher;
  const TeacherHomeworkScreen({super.key, required this.teacher});

  @override
  State<TeacherHomeworkScreen> createState() => _TeacherHomeworkScreenState();
}

class _TeacherHomeworkScreenState extends State<TeacherHomeworkScreen> {
  final HomeworkService _homeworkService = HomeworkService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Homework Assignments'.tr()),
      ),
      body: StreamBuilder<List<HomeworkModel>>(
        stream: _homeworkService.streamHomeworkByTeacher(widget.teacher.schoolId, widget.teacher.teacherId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final homeworkList = snapshot.data ?? [];

          if (homeworkList.isEmpty) {
            return Center(child: Text('You haven\'t assigned any homework yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: homeworkList.length,
            itemBuilder: (context, index) {
              final hw = homeworkList[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              hw.title, 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () async {
                              await _homeworkService.deleteHomework(hw.homeworkId);
                            },
                          )
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(hw.description, style: TextStyle(color: Colors.grey.shade800)),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                          SizedBox(width: 4),
                          Text(
                            'Due: ${DateFormat('MMM dd, yyyy').format(hw.dueDate)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                          ),
                        ],
                      )
                    ],
                  ),
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
              builder: (context) => AddHomeworkScreen(teacher: widget.teacher),
            ),
          );
        },
        backgroundColor: AppTheme.primary,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
