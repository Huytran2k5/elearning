import 'package:cloud_firestore/cloud_firestore.dart';

class QuizAttemptModel {
  final String id;
  final String quizId;
  final String studentId;
  final String studentName;
  final String studentCode;// Cache tên để xuất CSV
  final DateTime startedAt;
  final DateTime? finishedAt;
  final double? score; // null = đang làm
  // Lưu lại danh sách câu hỏi cụ thể của lần thi này (để review)
  // Map<QuestionID, SelectedIndex>
  final Map<String, int> answers;
  final List<String> questionIds; // Thứ tự câu hỏi

  QuizAttemptModel({
    required this.id,
    required this.quizId,
    required this.studentId,
    required this.studentName,
    this.studentCode = '',
    required this.startedAt,
    this.finishedAt,
    this.score,
    required this.answers,
    required this.questionIds,
  });

  Map<String, dynamic> toMap() {
    return {
      'quizId': quizId,
      'studentId': studentId,
      'studentName': studentName,
      'studentCode': studentCode,
      'startedAt': Timestamp.fromDate(startedAt),
      'finishedAt': finishedAt != null ? Timestamp.fromDate(finishedAt!) : null,
      'score': score,
      'answers': answers,
      'questionIds': questionIds,
    };
  }

  factory QuizAttemptModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return QuizAttemptModel(
      id: doc.id,
      quizId: data['quizId'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? 'Student',
      studentCode: data['studentCode'] ?? '',
      startedAt: (data['startedAt'] as Timestamp).toDate(),
      finishedAt: data['finishedAt'] != null ? (data['finishedAt'] as Timestamp).toDate() : null,
      score: data['score'] != null ? (data['score'] as num).toDouble() : null,
      answers: Map<String, int>.from(data['answers'] ?? {}),
      questionIds: List<String>.from(data['questionIds'] ?? []),
    );
  }
}