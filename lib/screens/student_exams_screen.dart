import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../models/student_model.dart';
import '../models/exam_model.dart';
import '../services/exam_service.dart';
import '../theme/app_theme.dart';

class StudentExamsScreen extends StatefulWidget {
  final StudentModel student;
  const StudentExamsScreen({super.key, required this.student});

  @override
  State<StudentExamsScreen> createState() => _StudentExamsScreenState();
}

class _StudentExamsScreenState extends State<StudentExamsScreen> {
  final ExamService _examService = ExamService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Exams'.tr()),
      ),
      body: StreamBuilder<List<ExamModel>>(
        stream: _examService.streamExams(widget.student.schoolId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final exams = (snapshot.data ?? [])
              .where((e) => e.status == 'Published')
              .toList();

          if (exams.isEmpty) {
            return Center(
              child: Text('No upcoming exams published yet.'.tr(),
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: exams.length,
            itemBuilder: (context, index) {
              final exam = exams[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                    child: Icon(Icons.assignment, color: AppTheme.primary),
                  ),
                  title: Text(
                    exam.examName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Text('Academic Year: ${exam.academicYear}'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (exam.instructions.isNotEmpty) ...[
                            Text('Instructions:'.tr(), style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text(exam.instructions),
                            const Divider(height: 24),
                          ],
                          Text('Exam Schedule:'.tr(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(height: 8),
                          ...exam.subjects.map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.book, color: Colors.blue),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(s.subjectName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      Text(
                                        '${DateFormat('MMM dd, yyyy').format(s.examDate)} • ${s.startTime} - ${s.endTime}',
                                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('Max'.tr(), style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    Text('${s.maxMarks}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ],
                                )
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
