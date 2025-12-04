import 'package:cloud_firestore/cloud_firestore.dart';

class QuestionModel {
  final String id;
  final String courseId;
  final String questionText;
  final List<String> options; // Danh sách đáp án [A, B, C, D]
  final int correctOptionIndex; // Index đáp án đúng (0, 1, 2...)
  final String difficulty; // 'EASY', 'MEDIUM', 'HARD'

  QuestionModel({
    required this.id,
    required this.courseId,
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
    required this.difficulty,
  });

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'questionText': questionText,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
      'difficulty': difficulty,
    };
  }

  factory QuestionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return QuestionModel(
      id: doc.id,
      courseId: data['courseId'] ?? '',
      questionText: data['questionText'] ?? '',
      options: List<String>.from(data['options'] ?? []),
      correctOptionIndex: data['correctOptionIndex'] ?? 0,
      difficulty: data['difficulty'] ?? 'EASY',
    );
  }
}