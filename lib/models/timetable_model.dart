
class TimetableModel {
  final String timetableId;
  final String schoolId;
  final String classId;
  final String dayOfWeek;
  final String subjectId;
  final String teacherId;
  final int periodNumber;

  TimetableModel({
    required this.timetableId,
    required this.schoolId,
    required this.classId,
    required this.dayOfWeek,
    required this.subjectId,
    required this.teacherId,
    required this.periodNumber,
  });

  factory TimetableModel.fromMap(Map<String, dynamic> map, String documentId) {
    return TimetableModel(
      timetableId: documentId,
      schoolId: map['schoolId'] ?? '',
      classId: map['classId'] ?? '',
      dayOfWeek: map['dayOfWeek'] ?? '',
      subjectId: map['subjectId'] ?? '',
      teacherId: map['teacherId'] ?? '',
      periodNumber: map['periodNumber'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'classId': classId,
      'dayOfWeek': dayOfWeek,
      'subjectId': subjectId,
      'teacherId': teacherId,
      'periodNumber': periodNumber,
    };
  }
}
