class AppConstants {
  static const String appName = "IT Faculty E-Learning";

  // --- Role ---
  static const String roleInstructor = 'INSTRUCTOR';
  static const String roleStudent = 'STUDENT';

  // Admin Account
  static const String defaultAdminEmail = 'admin';
  static const String defaultAdminPassword = 'admin';

  // Database Collections (Firestore)
  static const String collUsers = 'users';
  static const String collSemesters = 'semesters';
  static const String collCourses = 'courses';
  static const String collGroups = 'groups';
  static const String collEnrollments = 'enrollments';
  static const String collAssignments = 'assignments';
  static const String collSubmissions = 'submissions';
  static const String collAnnouncements = 'announcements';
  static const String collMaterials = 'materials';

  // Asset Paths
  static const String imagePath = 'assets/images';
  static const String iconPath = 'assets/icons';

}

class AllowedSubjects {
  static const List<String> list = [
    'Programming',
    'Database',
    'Artificial Intelligence',
    'Computer Networks',
    'Software Engineering',
    'Data Science',
    'Cyber Security'
  ];
}