import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../../../core/constants/app_constants.dart';
import 'question_model.dart';
import 'quiz_model.dart';
import 'quiz_attempt_model.dart';

class QuizService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- NGÂN HÀNG CÂU HỎI ---
  Future<void> addQuestion(QuestionModel question) async {
    await _db.collection('questions').add(question.toMap());
  }

  Stream<List<QuestionModel>> getQuestions(String courseId) {
    return _db.collection('questions')
        .where('courseId', isEqualTo: courseId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => QuestionModel.fromFirestore(d)).toList());
  }

  // --- QUẢN LÝ QUIZ ---
  Future<void> createQuiz(QuizModel quiz) async {
    await _db.collection('quizzes').add(quiz.toMap());
  }

  Stream<List<QuizModel>> getQuizzes(String courseId) {
    return _db.collection('quizzes')
        .where('courseId', isEqualTo: courseId)
        .orderBy('openAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => QuizModel.fromFirestore(d)).toList());
  }

  Stream<List<QuizAttemptModel>> getQuizAttempts(String quizId) {
    return _db.collection('quiz_attempts')
        .where('quizId', isEqualTo: quizId)
        .orderBy('score', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => QuizAttemptModel.fromFirestore(d)).toList());
  }

  // --- LOGIC LÀM BÀI ---

  Future<List<QuestionModel>> generateQuizQuestions(String courseId, Map<String, int> structure) async {
    List<QuestionModel> finalQuestions = [];
    final allQuestionsSnap = await _db.collection('questions').where('courseId', isEqualTo: courseId).get();
    final allQuestions = allQuestionsSnap.docs.map((d) => QuestionModel.fromFirestore(d)).toList();

    structure.forEach((difficulty, count) {
      var pool = allQuestions.where((q) => q.difficulty == difficulty).toList();
      pool.shuffle(Random());
      finalQuestions.addAll(pool.take(count));
    });

    return finalQuestions;
  }

  // CẬP NHẬT: Thêm tham số studentCode
  Future<QuizAttemptModel> startQuiz(QuizModel quiz, String studentId, String studentName, String studentCode) async {
    // Check số lần làm bài
    final existingAttempts = await _db.collection('quiz_attempts')
        .where('quizId', isEqualTo: quiz.id)
        .where('studentId', isEqualTo: studentId)
        .count()
        .get();

    int count = existingAttempts.count ?? 0;
    if (count >= quiz.maxAttempts) {
      throw Exception("Bạn đã hết lượt làm bài! (Tối đa ${quiz.maxAttempts} lần)");
    }

    // Sinh đề
    List<QuestionModel> questions = await generateQuizQuestions(quiz.courseId, quiz.structure);
    List<String> qIds = questions.map((q) => q.id).toList();

    final attempt = QuizAttemptModel(
      id: '',
      quizId: quiz.id,
      studentId: studentId,
      studentName: studentName,
      studentCode: studentCode, // <--- TRUYỀN VÀO ĐÂY
      startedAt: DateTime.now(),
      answers: {},
      questionIds: qIds,
    );

    final docRef = await _db.collection('quiz_attempts').add(attempt.toMap());

    return QuizAttemptModel(
        id: docRef.id,
        quizId: quiz.id,
        studentId: studentId,
        studentName: studentName,
        studentCode: studentCode, // <--- TRẢ VỀ
        startedAt: attempt.startedAt,
        answers: {},
        questionIds: qIds
    );
  }

  Future<void> submitQuiz(String attemptId, Map<String, int> answers) async {
    final attemptDoc = await _db.collection('quiz_attempts').doc(attemptId).get();
    final attempt = QuizAttemptModel.fromFirestore(attemptDoc);

    final questionsQuery = await _db.collection('questions')
        .where(FieldPath.documentId, whereIn: attempt.questionIds)
        .get();

    final questions = questionsQuery.docs.map((d) => QuestionModel.fromFirestore(d)).toList();

    int correctCount = 0;
    for (var q in questions) {
      if (answers.containsKey(q.id) && answers[q.id] == q.correctOptionIndex) {
        correctCount++;
      }
    }

    double finalScore = (correctCount / questions.length) * 10.0;

    await _db.collection('quiz_attempts').doc(attemptId).update({
      'finishedAt': Timestamp.now(),
      'answers': answers,
      'score': finalScore,
    });
  }
}