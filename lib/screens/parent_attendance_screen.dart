import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../models/student_model.dart';
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';

class ParentAttendanceScreen extends StatefulWidget {
  final List<StudentModel> children;
  final bool showAppBar;
  
  const ParentAttendanceScreen({
    super.key, 
    required this.children,
    this.showAppBar = true,
  });

  @override
  State<ParentAttendanceScreen> createState() => _ParentAttendanceScreenState();
}

class _ParentAttendanceScreenState extends State<ParentAttendanceScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  StudentModel? _selectedChild;
  
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

  @override
  void initState() {
    super.initState();
    if (widget.children.isNotEmpty) {
      _selectedChild = widget.children.first;
    }
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FBFF),
        appBar: widget.showAppBar ? AppBar(title: Text('Attendance'.tr())) : null,
        body: Center(child: Text('No children found.'.tr())),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      appBar: widget.showAppBar ? AppBar(
        title: Text('Attendance'.tr(), style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      ) : null,
      body: Column(
        children: [
          if (widget.children.length > 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<StudentModel>(
                    isExpanded: true,
                    value: _selectedChild,
                    items: widget.children.map((c) => DropdownMenuItem(
                      value: c,
                      child: Text('Viewing: ${c.name}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    )).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedChild = val;
                      });
                    },
                  ),
                ),
              ),
            ),
          
          Expanded(
            child: _selectedChild == null 
                ? Center(child: Text('Please select a child.'.tr()))
                : StreamBuilder<List<AttendanceModel>>(
                    stream: _attendanceService.streamStudentAttendance(_selectedChild!.schoolId, _selectedChild!.studentId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
                      
                      final records = snapshot.data ?? [];
                      
                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildCalendar(records),
                            SizedBox(height: 20),
                            _buildLegend(),
                            SizedBox(height: 20),
                          ],
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _legendItem('Present', Colors.green),
          _legendItem('Absent', Colors.red),
          _legendItem('Not Marked', Colors.yellow),
          _legendItem('Holiday', Colors.white, hasBorder: true),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color, {bool hasBorder = false}) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: hasBorder ? Border.all(color: Colors.grey.shade300) : null,
          ),
        ),
        SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildCalendar(List<AttendanceModel> records) {
    // Days in current month
    int daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    // Weekday of the 1st of the month (1 = Mon, 7 = Sun)
    int firstWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday;
    
    // Shift so Sunday is 0, Monday is 1, etc.
    int emptyPrefixDays = firstWeekday == 7 ? 0 : firstWeekday;

    List<Widget> dayWidgets = [];
    
    // Day headers (Sun, Mon, Tue...)
    final headers = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
    for (var h in headers) {
      dayWidgets.add(Center(
        child: Text(h, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
      ));
    }

    // Empty spaces before the 1st
    for (int i = 0; i < emptyPrefixDays; i++) {
      dayWidgets.add(SizedBox());
    }

    // Days
    for (int i = 1; i <= daysInMonth; i++) {
      DateTime currentDay = DateTime(_currentMonth.year, _currentMonth.month, i);
      String dateString = DateFormat('yyyy-MM-dd').format(currentDay);
      
      // Find record for this day
      AttendanceModel? record;
      try {
        record = records.firstWhere((r) => r.date == dateString);
      } catch (_) {}

      Color bgColor;
      Color textColor = Colors.white;
      
      if (currentDay.weekday == DateTime.sunday) {
        bgColor = Colors.white;
        textColor = Colors.black87;
      } else if (record != null) {
        if (record.status == 'present') {
          bgColor = Colors.green;
        } else if (record.status == 'absent') {
          bgColor = Colors.red;
        } else {
          bgColor = Colors.yellow; // Fallback
          textColor = Colors.black87;
        }
      } else {
        bgColor = Colors.yellow;
        textColor = Colors.black87;
      }

      dayWidgets.add(
        Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: currentDay.weekday == DateTime.sunday ? Border.all(color: Colors.grey.shade300) : null,
          ),
          alignment: Alignment.center,
          child: Text(
            '$i',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: Icon(Icons.chevron_left), onPressed: _previousMonth),
              Text(
                DateFormat('MMMM yyyy').format(_currentMonth),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              IconButton(icon: Icon(Icons.chevron_right), onPressed: _nextMonth),
            ],
          ),
          SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 7,
            childAspectRatio: 1,
            children: dayWidgets,
          ),
        ],
      ),
    );
  }
}
