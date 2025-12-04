import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/data/user_model.dart'; // <--- QUAN TRỌNG: Import UserModel để sửa lỗi
import 'assignment_model.dart';
import 'submission_model.dart';

class AssignmentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Lấy danh sách bài tập
  Stream<List<AssignmentModel>> getAssignments(String courseId) {
    return _db.collection(AppConstants.collAssignments)
        .where('courseId', isEqualTo: courseId)
        .orderBy('dueAt', descending: false) // Sửa dueDate -> dueAt
        .snapshots()
        .map((snap) => snap.docs.map((d) => AssignmentModel.fromFirestore(d)).toList());
  }

  // 2. Tạo bài tập
  Future<void> createAssignment(AssignmentModel assignment) async {
    await _db.collection(AppConstants.collAssignments).add(assignment.toMap());
  }

  // 3. Nộp bài (Logic mới)
  Future<void> submitAssignment(SubmissionModel submission) async {
    final q = await _db.collection(AppConstants.collSubmissions)
        .where('assignmentId', isEqualTo: submission.assignmentId)
        .where('studentId', isEqualTo: submission.studentId)
        .get();

    if (q.docs.isNotEmpty) {
      // Update bài cũ
      await q.docs.first.reference.update({
        'fileUrls': submission.fileUrls, // <--- SỬA: fileUrls (List)
        'submittedAt': Timestamp.now(),
        'isLate': submission.isLate,     // <--- THÊM: update trạng thái trễ
      });
    } else {
      // Tạo bài mới
      await _db.collection(AppConstants.collSubmissions).add(submission.toMap());
    }
  }

  // 4. Lấy bài nộp của TÔI
  Stream<SubmissionModel?> getMySubmission(String assignmentId, String studentId) {
    return _db.collection(AppConstants.collSubmissions)
        .where('assignmentId', isEqualTo: assignmentId)
        .where('studentId', isEqualTo: studentId)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isNotEmpty ? SubmissionModel.fromFirestore(snap.docs.first) : null);
  }

  // 5. Lấy TẤT CẢ bài nộp
  Stream<List<SubmissionModel>> getAllSubmissions(String assignmentId) {
    return _db.collection(AppConstants.collSubmissions)
        .where('assignmentId', isEqualTo: assignmentId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => SubmissionModel.fromFirestore(d)).toList());
  }

  // 6. Chấm điểm
  Future<void> gradeSubmission(String submissionId, double grade, String feedback) async {
    await _db.collection(AppConstants.collSubmissions).doc(submissionId).update({
      'grade': grade,
      'feedback': feedback,
    });
  }

  // 7. Lấy danh sách chưa nộp (Đã fix lỗi import UserModel)
  Future<List<UserModel>> getMissingSubmissions(String courseId, String assignmentId) async {
    final enrollments = await _db.collection(AppConstants.collEnrollments)
        .where('courseId', isEqualTo: courseId)
        .get();

    List<String> allStudentIds = enrollments.docs.map((e) => e['userId'] as String).toList();

    final submissions = await _db.collection(AppConstants.collSubmissions)
        .where('assignmentId', isEqualTo: assignmentId)
        .get();

    List<String> submittedIds = submissions.docs.map((s) => s['studentId'] as String).toList();

    List<String> missingIds = allStudentIds.where((id) => !submittedIds.contains(id)).toList();

    if (missingIds.isEmpty) return [];

    final userQuery = await _db.collection(AppConstants.collUsers)
        .where(FieldPath.documentId, whereIn: missingIds.take(10).toList())
        .get();

    return userQuery.docs.map((d) => UserModel.fromFirestore(d)).toList();
  }
}