import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/fee_model.dart';
import '../models/class_model.dart';
import '../models/student_model.dart';
import '../services/fee_service.dart';
import '../services/class_service.dart';
import '../theme/app_theme.dart';

class AdminFeesScreen extends StatefulWidget {
  final String schoolId;
  const AdminFeesScreen({super.key, required this.schoolId});

  @override
  State<AdminFeesScreen> createState() => _AdminFeesScreenState();
}

class _AdminFeesScreenState extends State<AdminFeesScreen> {
  final FeeService _feeService = FeeService();
  final ClassService _classService = ClassService();

  Future<void> _showAddFeeDialog(BuildContext context, List<ClassModel> classes) async {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    DateTime dueDate = DateTime.now().add(const Duration(days: 30));
    String? selectedClassId; // If null, it means 'All Classes'
    String? selectedStudentId; // If null, it means 'All Students' in that scope
    bool isSaving = false;

    // Fetch students to populate the dropdown
    List<StudentModel> students = [];
    try {
      final snapshot = await FirebaseFirestore.instance.collection('students').where('schoolId', isEqualTo: widget.schoolId).get();
      students = snapshot.docs.map((doc) => StudentModel.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      // Ignore
    }

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            
            // Filter students based on selected class
            List<StudentModel> filteredStudents = students;
            if (selectedClassId != null) {
               final c = classes.firstWhere((cl) => cl.classId == selectedClassId);
               filteredStudents = students.where((s) => s.classId == c.className && s.section == c.section).toList();
            }

            return AlertDialog(
              title: Text('Allocate New Fee'.tr()),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleController,
                      decoration: InputDecoration(labelText: 'Fee Title (e.g., Term 1 Fee)'.tr()),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Amount (\$)'),
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String?>(
                      isExpanded: true,
                      decoration: InputDecoration(labelText: 'Assign To Class'.tr()),
                      initialValue: selectedClassId,
                      items: [
                        DropdownMenuItem(value: null, child: Text('All Classes (Whole School)'.tr())),
                        ...classes.map((c) => DropdownMenuItem(
                              value: c.classId,
                              child: Text('${c.className} - ${c.section}'),
                            )),
                      ],
                      onChanged: (val) {
                        setDialogState(() {
                           selectedClassId = val;
                           selectedStudentId = null; // Reset student selection when class changes
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String?>(
                      isExpanded: true,
                      decoration: InputDecoration(labelText: 'Assign To Specific Student (Optional)'.tr()),
                      initialValue: selectedStudentId,
                      items: [
                        DropdownMenuItem(value: null, child: Text('All Students'.tr())),
                        ...filteredStudents.map((s) => DropdownMenuItem(
                              value: s.studentId,
                              child: Text('${s.name} (${s.admissionNumber})'),
                            )),
                      ],
                      onChanged: (val) {
                        setDialogState(() => selectedStudentId = val);
                      },
                    ),
                    SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Due Date'.tr()),
                      subtitle: Text(DateFormat('MMM dd, yyyy').format(dueDate)),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: dueDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setDialogState(() => dueDate = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'.tr()),
                ),
                FilledButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (titleController.text.trim().isEmpty || amountController.text.trim().isEmpty) return;
                          
                          setDialogState(() => isSaving = true);
                          try {
                            final amount = double.tryParse(amountController.text.trim()) ?? 0;
                            final fee = FeeModel(
                              feeId: '',
                              schoolId: widget.schoolId,
                              classId: selectedClassId ?? 'All',
                              studentId: selectedStudentId ?? 'All',
                              feeTitle: titleController.text.trim(),
                              amount: amount,
                              dueDate: dueDate,
                            );
                            await _feeService.addFee(fee);
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                            setDialogState(() => isSaving = false);
                          }
                        },
                  child: isSaving ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('Allocate Fee'.tr()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Fees Allocation'.tr())),
      body: FutureBuilder<List<ClassModel>>(
        future: _classService.getClassesOnce(widget.schoolId),
        builder: (context, classSnapshot) {
          if (classSnapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
          
          final classes = classSnapshot.data ?? [];
          
          return StreamBuilder<List<FeeModel>>(
            stream: _feeService.streamAllFees(widget.schoolId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
              if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

              final fees = snapshot.data ?? [];

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: () => _showAddFeeDialog(context, classes),
                        icon: Icon(Icons.add),
                        label: Text('Allocate New Fee'.tr()),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: fees.isEmpty
                        ? Center(child: Text('No fees allocated yet.'.tr()))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: fees.length,
                            itemBuilder: (context, index) {
                              final fee = fees[index];
                              
                              String assignText = 'Assigned to: Whole School';
                              if (fee.classId != 'All') {
                                final c = classes.where((cl) => cl.classId == fee.classId).firstOrNull;
                                assignText = c != null ? 'Assigned to: Class ${c.className} - ${c.section}' : 'Assigned to: Class (ID: ${fee.classId})';
                              }

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                          Text(
                                            '\$${fee.amount.toStringAsFixed(2)}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primary),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Text(assignText, style: TextStyle(color: Colors.grey.shade700)),
                                      SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Due: ${DateFormat('MMM dd, yyyy').format(fee.dueDate)}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                                          ),
                                          InkWell(
                                            onTap: () => _feeService.deleteFee(fee.feeId),
                                            child: Icon(Icons.delete, color: Colors.red, size: 20),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
