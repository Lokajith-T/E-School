import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';
import '../models/homework_model.dart';
import '../services/homework_service.dart';

class ParentHomeworkScreen extends StatefulWidget {
  final List<StudentModel> children;
  const ParentHomeworkScreen({super.key, required this.children});

  @override
  State<ParentHomeworkScreen> createState() => _ParentHomeworkScreenState();
}

class _ParentHomeworkScreenState extends State<ParentHomeworkScreen> {
  final HomeworkService _homeworkService = HomeworkService();
  StudentModel? _selectedChild;

  @override
  void initState() {
    super.initState();
    if (widget.children.isNotEmpty) {
      _selectedChild = widget.children.first;
    }
  }

  Stream<List<HomeworkModel>> _streamHomeworkForStudent(StudentModel student) async* {
    try {
      final classQuery = await FirebaseFirestore.instance.collection('classes')
          .where('schoolId', isEqualTo: student.schoolId)
          .where('className', isEqualTo: student.classId)
          .where('section', isEqualTo: student.section)
          .limit(1)
          .get();
          
      if (classQuery.docs.isEmpty) {
        yield [];
        return;
      }
      
      final classDocId = classQuery.docs.first.id;
      yield* _homeworkService.streamHomeworkByClass(student.schoolId, classDocId);
    } catch (e) {
      yield [];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Child Homework'.tr())),
        body: Center(child: Text('No children found.'.tr())),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Child Homework'.tr())),
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
                onChanged: (val) {
                  setState(() {
                    _selectedChild = val;
                  });
                },
              ),
            ),
          Expanded(
            child: _selectedChild == null 
                ? Center(child: Text('Please select a child.'.tr()))
                : StreamBuilder<List<HomeworkModel>>(
                    stream: _streamHomeworkForStudent(_selectedChild!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
                      
                      final records = snapshot.data ?? [];
                      
                      if (records.isEmpty) {
                        return Center(child: Text('No homework assigned to this class.'.tr()));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: records.length,
                        itemBuilder: (context, index) {
                          final hw = records[index];
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    hw.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
          )
        ],
      ),
    );
  }
}
