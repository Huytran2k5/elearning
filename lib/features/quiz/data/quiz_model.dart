import 'package:cloud_firestore/cloud_firestore.dart';

class QuizModel {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final DateTime openAt;
  final DateTime closeAt;
  final int durationMinutes;
  final int maxAttempts;
  // Cấu hình random: { 'EASY': 5, 'MEDIUM': 3, 'HARD': 2 }
  final Map<String, int> structure;

  QuizModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.openAt,
    required this.closeAt,
    required this.durationMinutes,
    required this.maxAttempts,
    required this.structure,
  });

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'title': title,
      'description': description,
      'openAt': Timestamp.fromDate(openAt),
      'closeAt': Timestamp.fromDate(closeAt),
      'durationMinutes': durationMinutes,
      'maxAttempts': maxAttempts,
      'structure': structure,
    };
  }

  factory QuizModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return QuizModel(
      id: doc.id,
      courseId: data['courseId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      openAt: (data['openAt'] as Timestamp).toDate(),
      closeAt: (data['closeAt'] as Timestamp).toDate(),
      durationMinutes: data['durationMinutes'] ?? 30,
      maxAttempts: data['maxAttempts'] ?? 1,
      structure: Map<String, int>.from(data['structure'] ?? {}),
    );
  }
}