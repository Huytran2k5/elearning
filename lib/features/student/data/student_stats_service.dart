import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../content/data/assignment_model.dart';
import '../../content/data/submission_model.dart';
import '../../quiz/data/quiz_attempt_model.dart';

class StudentStats {
  final int assignmentsPending;
  final int assignmentsLate;
  final int assignmentsDone;
  final double avgQuizScore;
  final List<TimelineItem> upcomingDeadlines;

  StudentStats({
    required this.assignmentsPending,
    required this.assignmentsLate,
    required this.assignmentsDone,
    required this.avgQuizScore,
    required this.upcomingDeadlines,
  });
}

class TimelineItem {
  final String title;
  final DateTime date;
  final String type;
  final String courseName;

  TimelineItem({required this.title, required this.date, required this.type, this.courseName = ''});
}

class StudentStatsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<StudentStats> getStats(String studentId) async {
    print("🔍 [STATS] Bắt đầu tính toán cho SV: $studentId");

    try {
      // 1. Lấy danh sách Enrollment
      final enrollments = await _db.collection(AppConstants.collEnrollments)
          .where('userId', isEqualTo: studentId)
          .get();

      if (enrollments.docs.isEmpty) return _emptyStats();

      // Lấy danh sách ID NHÓM mà sinh viên tham gia
      Set<String> myGroupIds = {};
      for (var doc in enrollments.docs) {
        myGroupIds.add(doc['groupId']);
      }

      print("🔍 [STATS] SV đang học trong ${myGroupIds.length} nhóm: $myGroupIds");

      if (myGroupIds.isEmpty) return _emptyStats();

      // 2. Lấy Bài tập (Assignments)
      // --- SỬA QUAN TRỌNG: Query theo Group ID (thay vì Course ID) ---
      // Vì trong ClassworkTab, chúng ta truyền groupId vào field 'courseId' của Assignment
      final assignmentsSnap = await _db.collection(AppConstants.collAssignments)
          .where('courseId', whereIn: myGroupIds.take(10).toList())
          .get();

      print("🔍 [STATS] Tìm thấy ${assignmentsSnap.docs.length} bài tập.");

      final allAssignments = assignmentsSnap.docs.map((d) => AssignmentModel.fromFirestore(d)).toList();

      // 3. Lấy Bài nộp (Submissions)
      final submissionsSnap = await _db.collection(AppConstants.collSubmissions)
          .where('studentId', isEqualTo: studentId)
          .get();

      final allSubmissions = submissionsSnap.docs.map((d) => SubmissionModel.fromFirestore(d)).toList();

      // 4. Tính toán Logic
      int pending = 0;
      int late = 0;
      int done = 0;
      List<TimelineItem> timelines = [];
      final now = DateTime.now();

      for (var asm in allAssignments) {
        // (Bỏ qua logic lọc targetGroupIds cũ vì giờ ta đã query chính xác theo Group rồi)

        // Check xem đã nộp chưa
        bool isSubmitted = false;
        try {
          final sub = allSubmissions.firstWhere((s) => s.assignmentId == asm.id);
          isSubmitted = true;
          done++;
          if (sub.isLate) late++;
        } catch (_) {}

        // Chưa nộp
        if (!isSubmitted) {
          if (now.isAfter(asm.dueAt)) {
            late++; // Quá hạn
          } else {
            pending++; // Chờ nộp
            timelines.add(TimelineItem(
              title: asm.title,
              date: asm.dueAt,
              type: 'Bài tập',
            ));
          }
        }
      }

      // 5. Tính toán Quiz
      final attemptsSnap = await _db.collection('quiz_attempts')
          .where('studentId', isEqualTo: studentId)
          .get();

      double totalScore = 0;
      int quizCount = 0;
      for (var doc in attemptsSnap.docs) {
        final attempt = QuizAttemptModel.fromFirestore(doc);
        if (attempt.score != null) {
          totalScore += attempt.score!;
          quizCount++;
        }
      }
      double avgScore = quizCount > 0 ? totalScore / quizCount : 0.0;

      // Sắp xếp Timeline
      timelines.sort((a, b) => a.date.compareTo(b.date));

      return StudentStats(
        assignmentsPending: pending,
        assignmentsLate: late,
        assignmentsDone: done,
        avgQuizScore: avgScore,
        upcomingDeadlines: timelines,
      );

    } catch (e) {
      print("❌ [STATS ERROR]: $e");
      return _emptyStats();
    }
  }

  StudentStats _emptyStats() {
    return StudentStats(assignmentsPending: 0, assignmentsLate: 0, assignmentsDone: 0, avgQuizScore: 0, upcomingDeadlines: []);
  }
}