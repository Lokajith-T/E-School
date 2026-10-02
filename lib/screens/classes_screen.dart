import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../models/class_model.dart';
import '../services/class_service.dart';
import '../theme/app_theme.dart';
import 'add_class_screen.dart';
import 'class_details_screen.dart';

class ClassesScreen extends StatefulWidget {
  final String schoolId;
  const ClassesScreen({super.key, required this.schoolId});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  final ClassService _classService = ClassService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Classes'.tr()),
      ),
      body: StreamBuilder<List<ClassModel>>(
        stream: _classService.streamClasses(widget.schoolId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final classes = snapshot.data ?? [];
          // Sort by class name then section
          classes.sort((a, b) {
            int nameCompare = a.className.compareTo(b.className);
            if (nameCompare != 0) return nameCompare;
            return a.section.compareTo(b.section);
          });

          if (classes.isEmpty) {
            return Center(child: Text('No classes found. Add a class to begin.'.tr()));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              final classData = classes[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                    child: Text(
                      classData.section, 
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                    ),
                  ),
                  title: Text(classData.className, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Text('Tap to view details and subjects'.tr()),
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () async {
                      bool? confirm = await showDialog(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: Text('Delete Class'.tr()),
                          content: Text('Are you sure you want to delete this class? This action cannot be undone.'.tr()),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c, false), child: Text('Cancel'.tr())),
                            TextButton(onPressed: () => Navigator.pop(c, true), child: Text('Delete'.tr(), style: TextStyle(color: Colors.red))),
                          ],
                        )
                      );
                      if (confirm == true) {
                        await _classService.deleteClass(classData.classId);
                      }
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ClassDetailsScreen(classData: classData),
                      ),
                    );
                  },
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
              builder: (context) => AddClassScreen(schoolId: widget.schoolId),
            ),
          );
        },
        backgroundColor: AppTheme.primary,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
