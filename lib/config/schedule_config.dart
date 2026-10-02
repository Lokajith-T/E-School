class ScheduleConfig {
  static const List<Map<String, dynamic>> periods = [
    {'periodNumber': 1, 'name': 'Period 1', 'startTime': '09:00 AM', 'endTime': '09:45 AM', 'isBreak': false},
    {'periodNumber': 2, 'name': 'Period 2', 'startTime': '09:45 AM', 'endTime': '10:30 AM', 'isBreak': false},
    {'periodNumber': 3, 'name': 'Break', 'startTime': '10:30 AM', 'endTime': '10:45 AM', 'isBreak': true},
    {'periodNumber': 4, 'name': 'Period 3', 'startTime': '10:45 AM', 'endTime': '11:30 AM', 'isBreak': false},
    {'periodNumber': 5, 'name': 'Period 4', 'startTime': '11:30 AM', 'endTime': '12:15 PM', 'isBreak': false},
    {'periodNumber': 6, 'name': 'Lunch', 'startTime': '12:15 PM', 'endTime': '01:00 PM', 'isBreak': true},
    {'periodNumber': 7, 'name': 'Period 5', 'startTime': '01:00 PM', 'endTime': '01:45 PM', 'isBreak': false},
    {'periodNumber': 8, 'name': 'Period 6', 'startTime': '01:45 PM', 'endTime': '02:30 PM', 'isBreak': false},
    {'periodNumber': 9, 'name': 'Period 7', 'startTime': '02:30 PM', 'endTime': '03:15 PM', 'isBreak': false},
  ];

  static const List<String> weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
}
