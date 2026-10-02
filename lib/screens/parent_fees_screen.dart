import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../models/student_model.dart';
import '../models/fee_model.dart';
import '../services/fee_service.dart';
import '../theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ParentFeesScreen extends StatefulWidget {
  final List<StudentModel> children;
  const ParentFeesScreen({super.key, required this.children});

  @override
  State<ParentFeesScreen> createState() => _ParentFeesScreenState();
}

class _ParentFeesScreenState extends State<ParentFeesScreen> {
  final FeeService _feeService = FeeService();
  StudentModel? _selectedChild;

  @override
  void initState() {
    super.initState();
    if (widget.children.isNotEmpty) {
      _selectedChild = widget.children.first;
    }
  }
  
  Stream<List<FeeModel>> _streamFeesForStudent(StudentModel student) async* {
    try {
      final classQuery = await FirebaseFirestore.instance.collection('classes')
          .where('schoolId', isEqualTo: student.schoolId)
          .where('className', isEqualTo: student.classId)
          .where('section', isEqualTo: student.section)
          .limit(1)
          .get();
          
      String classDocId = 'All';
      if (classQuery.docs.isNotEmpty) {
        classDocId = classQuery.docs.first.id;
      }
      
      yield* _feeService.streamFeesForStudent(student.schoolId, classDocId, student.studentId);
    } catch (e) {
      yield [];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Fee Reports'.tr())),
        body: Center(child: Text('No children found.'.tr())),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Fee Reports'.tr())),
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
                : StreamBuilder<List<FeeModel>>(
                    stream: _streamFeesForStudent(_selectedChild!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
                      if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

                      final fees = snapshot.data ?? [];

                      if (fees.isEmpty) {
                        return Center(child: Text('No pending fees.'.tr()));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: fees.length,
                        itemBuilder: (context, index) {
                          final fee = fees[index];
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3))),
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
                                          fee.feeTitle,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '\$${fee.amount.toStringAsFixed(2)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded, size: 16, color: Colors.redAccent),
                                      SizedBox(width: 6),
                                      Text(
                                        'Due Date: ${DateFormat('MMM dd, yyyy').format(fee.dueDate)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment Gateway coming soon!'.tr())));
                                      },
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppTheme.primary,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: Text('Pay Now'.tr()),
                                    ),
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
