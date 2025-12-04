import 'package:cloud_firestore/cloud_firestore.dart';

class SubmissionModel {
  final String id;
  final String assignmentId;
  final String studentId;
  final String studentName;
  final String studentEmail; // Để xuất CSV
  final String groupId;      // Để lọc theo nhóm

  final List<String> fileUrls; // Hỗ trợ nộp nhiều file (link)
  final DateTime submittedAt;
  final int attemptNumber;     // Lần nộp thứ mấy (1, 2, 3...)
  final bool isLate;           // Trạng thái nộp trễ

  final double? grade;
  final String? feedback;

  SubmissionModel({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.groupId,
    required this.fileUrls,
    required this.submittedAt,
    this.attemptNumber = 1,
    this.isLate = false,
    this.grade,
    this.feedback,
  });

  String get statusText {
    if (grade != null) return "Đã chấm: $grade";
    if (isLate) return "Nộp trễ (Lần $attemptNumber)";
    return "Đã nộp (Lần $attemptNumber)";
  }

  Map<String, dynamic> toMap() {
    return {
      'assignmentId': assignmentId,
      'studentId': studentId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'groupId': groupId,
      'fileUrls': fileUrls,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'attemptNumber': attemptNumber,
      'isLate': isLate,
      'grade': grade,
      'feedback': feedback,
    };
  }

  factory SubmissionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return SubmissionModel(
      id: doc.id,
      assignmentId: data['assignmentId'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      studentEmail: data['studentEmail'] ?? '',
      groupId: data['groupId'] ?? '',
      fileUrls: List<String>.from(data['fileUrls'] ?? []),
      submittedAt: data['submittedAt'] != null
          ? (data['submittedAt'] as Timestamp).toDate()
          : DateTime.now(),
      attemptNumber: data['attemptNumber'] ?? 1,
      isLate: data['isLate'] ?? false,
      grade: data['grade'] != null ? (data['grade'] as num).toDouble() : null,
      feedback: data['feedback'],
    );
  }
}