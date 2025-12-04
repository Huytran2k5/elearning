import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';

class DashboardStats {
  final int activeCourses;
  final int totalStudents;
  final int totalAssignments;
  final int pendingGrades;

  DashboardStats({
    required this.activeCourses,
    required this.totalStudents,
    required this.totalAssignments,
    required this.pendingGrades,
  });
}

class DashboardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<DashboardStats> fetchStats() async {
    try {
      // 1. Đếm số khóa học (Courses)
      // (Thực tế nên lọc theo semesterId active, ở đây đếm tổng cho đơn giản)
      final coursesCount = await _db.collection(AppConstants.collCourses).count().get();

      // 2. Đếm số sinh viên (Users where role = STUDENT)
      final studentsCount = await _db
          .collection(AppConstants.collUsers)
          .where('role', isEqualTo: AppConstants.roleStudent)
          .count()
          .get();

      // 3. Đếm số bài tập (Assignments)
      final assignmentsCount = await _db.collection(AppConstants.collAssignments).count().get();

      // 4. Đếm số bài chưa chấm (Submissions where grade = null)
      // Lưu ý: count() với điều kiện null cần index, nếu lỗi index thì dùng get().length
      final pendingCountQuery = await _db
          .collection(AppConstants.collSubmissions)
          .where('grade', isNull: true)
          .get(); // Dùng get() cho an toàn vì tập dữ liệu submission chưa lớn

      return DashboardStats(
        activeCourses: coursesCount.count ?? 0,
        totalStudents: studentsCount.count ?? 0,
        totalAssignments: assignmentsCount.count ?? 0,
        pendingGrades: pendingCountQuery.docs.length,
      );
    } catch (e) {
      print("Lỗi lấy thống kê: $e");
      // Trả về 0 hết nếu lỗi (hoặc mất mạng)
      return DashboardStats(activeCourses: 0, totalStudents: 0, totalAssignments: 0, pendingGrades: 0);
    }
  }
}