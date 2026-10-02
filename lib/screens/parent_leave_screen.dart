import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';
import '../models/leave_model.dart';
import '../services/leave_service.dart';

class ParentLeaveScreen extends StatefulWidget {
  final List<StudentModel> children;
  const ParentLeaveScreen({super.key, required this.children});

  @override
  State<ParentLeaveScreen> createState() => _ParentLeaveScreenState();
}

class _ParentLeaveScreenState extends State<ParentLeaveScreen> {
  final LeaveService _leaveService = LeaveService();
  StudentModel? _selectedChild;
  
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.children.isNotEmpty) {
      _selectedChild = widget.children.first;
    }
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
          if (_toDate != null && _toDate!.isBefore(_fromDate!)) {
            _toDate = null;
          }
        } else {
          _toDate = picked;
        }
      });
    }
  }

  Future<void> _submitLeave() async {
    if (_selectedChild == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select a child'.tr())));
      return;
    }
    if (_fromDate == null || _toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select From and To dates'.tr())));
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Resolve actual class doc ID
      String actualClassId = _selectedChild!.classId;
      try {
        final classQuery = await FirebaseFirestore.instance.collection('classes')
            .where('schoolId', isEqualTo: _selectedChild!.schoolId)
            .where('className', isEqualTo: _selectedChild!.classId)
            .where('section', isEqualTo: _selectedChild!.section)
            .limit(1)
            .get();
        if (classQuery.docs.isNotEmpty) {
          actualClassId = classQuery.docs.first.id;
        }
      } catch (_) {}

      final leave = LeaveModel(
        leaveId: '',
        schoolId: _selectedChild!.schoolId,
        classId: actualClassId,
        studentId: _selectedChild!.studentId,
        studentName: _selectedChild!.name,
        fromDate: _fromDate!,
        toDate: _toDate!,
        reason: _reasonController.text.trim(),
      );

      await _leaveService.submitLeaveRequest(leave);

      setState(() {
        _fromDate = null;
        _toDate = null;
        _reasonController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Leave request submitted successfully'.tr())));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Leave Requests'.tr())),
        body: Center(child: Text('No children found.'.tr())),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Leave Requests'.tr())),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Apply for Leave'.tr(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _selectDate(context, true),
                                icon: Icon(Icons.calendar_today, size: 18),
                                label: Text(_fromDate == null ? 'From' : DateFormat('MMM dd').format(_fromDate!)),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _fromDate == null ? null : () => _selectDate(context, false),
                                icon: Icon(Icons.calendar_today, size: 18),
                                label: Text(_toDate == null ? 'To' : DateFormat('MMM dd').format(_toDate!)),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _reasonController,
                          maxLines: 2,
                          decoration: InputDecoration(labelText: 'reason_for_leave'.tr()),
                          validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter a reason' : null,
                        ),
                        SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isSubmitting ? null : _submitLeave,
                            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                            child: _isSubmitting 
                                ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text('Submit Request'.tr()),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                Container(height: 1, color: Colors.grey.shade200),
                Expanded(
                  child: _selectedChild == null 
                      ? Center(child: Text('Select a child to view requests'.tr()))
                      : StreamBuilder<List<LeaveModel>>(
                          stream: _leaveService.streamStudentLeaves(_selectedChild!.schoolId, _selectedChild!.studentId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
                            
                            final leaves = snapshot.data ?? [];
                            if (leaves.isEmpty) return Center(child: Text('No leave requests found.'.tr()));
                            
                            return ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: leaves.length,
                              itemBuilder: (context, index) {
                                final leave = leaves[index];
                                Color statusColor = Colors.orange;
                                if (leave.status == 'Approved') statusColor = Colors.green;
                                if (leave.status == 'Rejected') statusColor = Colors.red;
                                
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
                                            Text('${DateFormat('MMM dd').format(leave.fromDate)} - ${DateFormat('MMM dd, yyyy').format(leave.toDate)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                              child: Text(leave.status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                                            )
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        Text(leave.reason, style: TextStyle(color: Colors.grey.shade700)),
                                        if (leave.handledBy != null && leave.status != 'Pending') ...[
                                          SizedBox(height: 8),
                                          Text('Handled by: ${leave.handledBy}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                                        ]
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
          )
        ],
      ),
    );
  }
}
