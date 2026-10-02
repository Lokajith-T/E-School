import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../models/student_model.dart';
import '../models/marks_model.dart';
import '../services/marks_service.dart';
import '../theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ParentMarksScreen extends StatefulWidget {
  final List<StudentModel> children;
  const ParentMarksScreen({super.key, required this.children});

  @override
  State<ParentMarksScreen> createState() => _ParentMarksScreenState();
}

class _ParentMarksScreenState extends State<ParentMarksScreen> {
  final MarksService _marksService = MarksService();
  StudentModel? _selectedChild;

  @override
  void initState() {
    super.initState();
    if (widget.children.isNotEmpty) {
      _selectedChild = widget.children.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Exam Results'.tr())),
        body: Center(child: Text('No children found.'.tr())),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Exam Results'.tr())),
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
                : StreamBuilder<List<MarksModel>>(
                    stream: _marksService.streamStudentMarks(_selectedChild!.schoolId, _selectedChild!.studentId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
                      
                      final records = (snapshot.data ?? []).where((m) => m.status == 'Published').toList();
                      
                      if (records.isEmpty) {
                        return Center(child: Text('No marks recorded yet.'.tr()));
                      }
                      
                      // Group by Exam Name
                      Map<String, List<MarksModel>> examGroups = {};
                      for (var r in records) {
                        if (!examGroups.containsKey(r.examName)) {
                          examGroups[r.examName] = [];
                        }
                        examGroups[r.examName]!.add(r);
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: examGroups.keys.length,
                        itemBuilder: (context, index) {
                          String examName = examGroups.keys.elementAt(index);
                          List<MarksModel> marks = examGroups[examName]!;
                          
                          int totalObtained = marks.fold(0, (sum, item) => sum + item.marksObtained);
                          int totalMax = marks.fold(0, (sum, item) => sum + item.maxMarks);
                          double percentage = totalMax > 0 ? (totalObtained / totalMax) * 100 : 0.0;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: ExpansionTile(
                              title: Text(examName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              subtitle: Text('Score: $totalObtained / $totalMax  (${percentage.toStringAsFixed(1)}%)'),
                              children: marks.map((m) {
                                return FutureBuilder<String>(
                                  future: FirebaseFirestore.instance.collection('subjects').doc(m.subjectId).get().then((doc) => doc.exists ? (doc.data()?['subjectName'] ?? m.subjectId) : m.subjectId),
                                  builder: (context, subjectSnapshot) {
                                    String displayName = subjectSnapshot.data ?? 'Loading...';
                                    return ListTile(
                                      leading: Icon(Icons.menu_book, color: AppTheme.primary),
                                      title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      trailing: Text(
                                        '${m.marksObtained} / ${m.maxMarks}',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    );
                                  }
                                );
                              }).toList(),
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
