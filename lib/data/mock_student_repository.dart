
// Mock models
class StudentProfile {
  final String id;
  final String name;
  final String grade;
  final String section;
  final String rollNumber;

  StudentProfile({
    required this.id,
    required this.name,
    required this.grade,
    required this.section,
    required this.rollNumber,
  });
}

class MockStudentRepository {
  // Simulating fetching student data
  Future<StudentProfile> getStudentProfile() async {
    await Future.delayed(const Duration(seconds: 1)); // simulate network delay
    return StudentProfile(
      id: 'STU2026-001',
      name: 'Alex Johnson',
      grade: '10',
      section: 'A',
      rollNumber: '12',
    );
  }

  // Enforce role-based data access: Only fetching data relevant to this specific student
  Future<Map<String, String>> getDashboardStats() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'attendance': '92%',
      'homework_pending': '2',
      'upcoming_exams': '3',
      'fees_due': '₹0',
    };
  }
}
