import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/quiz_attempt_model.dart';

class QuizResultScreen extends StatelessWidget {
  final String attemptId;
  const QuizResultScreen({super.key, required this.attemptId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kết Quả Bài Thi"), automaticallyImplyLeading: false),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('quiz_attempts').doc(attemptId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final attempt = QuizAttemptModel.fromFirestore(snapshot.data!);

          // Tính màu sắc điểm
          Color scoreColor = Colors.red;
          if (attempt.score! >= 5) scoreColor = Colors.orange;
          if (attempt.score! >= 8) scoreColor = Colors.green;

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.verified, size: 80, color: Colors.blue),
                const SizedBox(height: 20),
                const Text("Bạn đã hoàn thành bài thi!", style: TextStyle(fontSize: 20)),
                const SizedBox(height: 40),

                Text(
                    "${attempt.score?.toStringAsFixed(1)}",
                    style: TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: scoreColor)
                ),
                const Text("Điểm số", style: TextStyle(color: Colors.grey)),

                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context), // Quay về danh sách Quiz
                  child: const Text("Quay về khóa học"),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}