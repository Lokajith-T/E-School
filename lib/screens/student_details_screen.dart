import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/student_model.dart';
import '../models/fee_model.dart';
import '../services/fee_service.dart';
import '../theme/app_theme.dart';

class StudentDetailsScreen extends StatefulWidget {
  final StudentModel student;
  const StudentDetailsScreen({super.key, required this.student});

  @override
  State<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen> {
  final FeeService _feeService = FeeService();

  Future<void> _showAddFeeDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    DateTime dueDate = DateTime.now().add(const Duration(days: 30));
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Allocate Fee to ${widget.student.name}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleController,
                      decoration: InputDecoration(labelText: 'Fee Title (e.g., Library Fine)'.tr()),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Amount (\$)'),
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
                              schoolId: widget.student.schoolId,
                              classId: 'All', // Specific to student, class doesn't matter for this query
                              studentId: widget.student.studentId,
                              feeTitle: titleController.text.trim(),
                              amount: amount,
                              dueDate: dueDate,
                            );
                            await _feeService.addFee(fee);
                            if (mounted) Navigator.pop(context);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                            setDialogState(() => isSaving = false);
                          }
                        },
                  child: isSaving ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('Allocate'.tr()),
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
      appBar: AppBar(
        title: Text('${widget.student.name} Details'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            color: AppTheme.primary.withValues(alpha: 0.05),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                  child: Icon(Icons.person, size: 40, color: AppTheme.primary),
                ),
                SizedBox(height: 16),
                Text(widget.student.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Class: ${widget.student.classId} ${widget.student.section}', style: const TextStyle(fontSize: 16)),
                Text('Admn No: ${widget.student.admissionNumber}', style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Specific Fees Assigned'.tr(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                FilledButton.icon(
                  onPressed: () => _showAddFeeDialog(context),
                  icon: Icon(Icons.add, size: 18),
                  label: Text('Add Fee'.tr()),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<FeeModel>>(
              // Note: For simplicity, this stream fetches all fees and we filter for this specific student.
              // A more robust implementation would use a specialized query.
              stream: _feeService.streamFeesForStudent(widget.student.schoolId, 'All', widget.student.studentId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                
                // Filter to only show fees specifically assigned to this student ID
                final allFees = snapshot.data ?? [];
                final studentSpecificFees = allFees.where((f) => f.studentId == widget.student.studentId).toList();
                
                if (studentSpecificFees.isEmpty) {
                  return Center(child: Text('No specific fees assigned to this student.'.tr()));
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: studentSpecificFees.length,
                  itemBuilder: (context, index) {
                    final fee = studentSpecificFees[index];
                    return Card(
                      child: ListTile(
                        title: Text(fee.feeTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Due: ${DateFormat('MMM dd, yyyy').format(fee.dueDate)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('\$${fee.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary)),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _feeService.deleteFee(fee.feeId),
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
