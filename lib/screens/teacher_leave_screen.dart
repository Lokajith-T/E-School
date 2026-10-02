import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../models/teacher_model.dart';
import '../models/class_model.dart';
import '../models/leave_model.dart';
import '../services/class_service.dart';
import '../services/leave_service.dart';

class TeacherLeaveScreen extends StatefulWidget {
  final TeacherModel teacher;
  const TeacherLeaveScreen({super.key, required this.teacher});

  @override
  State<TeacherLeaveScreen> createState() => _TeacherLeaveScreenState();
}

class _TeacherLeaveScreenState extends State<TeacherLeaveScreen> {
  final ClassService _classService = ClassService();
  final LeaveService _leaveService = LeaveService();
  
  List<ClassModel> _myClasses = [];
  ClassModel? _selectedClass;
  bool _isLoadingClasses = true;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    _classService.streamClasses(widget.teacher.schoolId).first.then((classes) {
      if (mounted) {
        setState(() {
          _myClasses = classes;
          _isLoadingClasses = false;
        });
      }
    }).catchError((_) {
      if (mounted) setState(() => _isLoadingClasses = false);
    });
  }

  Future<void> _updateStatus(LeaveModel leave, String status) async {
    try {
      await _leaveService.updateLeaveStatus(leave.leaveId, status, widget.teacher.name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Leave marked as $status')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingClasses) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: Text('Leave Approvals'.tr())),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: DropdownButtonFormField<ClassModel>(
              decoration: InputDecoration(labelText: 'select_class'.tr(), border: OutlineInputBorder()),
              initialValue: _selectedClass,
              items: _myClasses.map((c) => DropdownMenuItem(
                value: c,
                child: Text('${c.className} - ${c.section}'),
              )).toList(),
              onChanged: (val) => setState(() => _selectedClass = val),
            ),
          ),
          Expanded(
            child: _selectedClass == null
                ? Center(child: Text('Select a class to view leave requests'.tr()))
                : StreamBuilder<List<LeaveModel>>(
                    stream: _leaveService.streamClassLeaves(widget.teacher.schoolId, _selectedClass!.classId),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                      if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
                      
                      final leaves = snapshot.data ?? [];
                      if (leaves.isEmpty) return Center(child: Text('No leave requests for this class.'.tr()));
                      
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: leaves.length,
                        itemBuilder: (context, index) {
                          final leave = leaves[index];
                          final isPending = leave.status == 'Pending';
                          
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
                                      Text(leave.studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                        child: Text(leave.status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                                      )
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Text('${DateFormat('MMM dd').format(leave.fromDate)} to ${DateFormat('MMM dd, yyyy').format(leave.toDate)}', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                                  SizedBox(height: 8),
                                  Text(leave.reason),
                                  SizedBox(height: 12),
                                  if (isPending)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () => _updateStatus(leave, 'Rejected'),
                                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                                          child: Text('Reject'.tr()),
                                        ),
                                        SizedBox(width: 8),
                                        FilledButton(
                                          onPressed: () => _updateStatus(leave, 'Approved'),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            minimumSize: const Size(0, 40),
                                            padding: const EdgeInsets.symmetric(horizontal: 16),
                                          ),
                                          child: Text('Approve'.tr()),
                                        ),
                                      ],
                                    )
                                  else if (leave.handledBy != null)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text('Handled by: ${leave.handledBy}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey)),
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
