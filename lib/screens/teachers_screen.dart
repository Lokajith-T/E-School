import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../models/teacher_model.dart';
import '../services/teacher_service.dart';
import '../theme/app_theme.dart';
import 'add_teacher_screen.dart';

class TeachersScreen extends StatefulWidget {
  final String schoolId;
  const TeachersScreen({super.key, required this.schoolId});

  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
  final TeacherService _teacherService = TeacherService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Teachers'.tr()),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or mobile number...'.tr(),
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<TeacherModel>>(
        stream: _teacherService.streamTeachers(widget.schoolId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final teachers = snapshot.data ?? [];
          
          final filteredTeachers = teachers.where((t) {
            return t.name.toLowerCase().contains(_searchQuery) || 
                   t.mobileNumber.contains(_searchQuery);
          }).toList();

          if (filteredTeachers.isEmpty) {
            return Center(child: Text('No teachers found.'.tr()));
          }

          return ListView.builder(
            itemCount: filteredTeachers.length,
            itemBuilder: (context, index) {
              final teacher = filteredTeachers[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                  child: Icon(Icons.co_present, color: AppTheme.primary),
                ),
                title: Text(teacher.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${teacher.subjects.join(', ')} • ${teacher.mobileNumber}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'toggle_status') {
                      if (teacher.status == 'active') {
                        await _teacherService.deactivateTeacher(teacher.teacherId);
                      } else {
                        await _teacherService.activateTeacher(teacher.teacherId);
                      }
                    } else if (value == 'delete') {
                      bool? confirm = await showDialog(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: Text('Remove Teacher'.tr()),
                          content: Text('Are you sure you want to remove this teacher?'.tr()),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c, false), child: Text('Cancel'.tr())),
                            TextButton(onPressed: () => Navigator.pop(c, true), child: Text('Remove'.tr(), style: TextStyle(color: Colors.red))),
                          ],
                        )
                      );
                      if (confirm == true) {
                        await _teacherService.deleteTeacherData(teacher);
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'toggle_status',
                      child: Text(teacher.status == 'active' ? 'Deactivate' : 'Activate'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'.tr(), style: TextStyle(color: Colors.red)),
                    ),
                  ],
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
              builder: (context) => AddTeacherScreen(schoolId: widget.schoolId),
            ),
          );
        },
        backgroundColor: AppTheme.primary,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
