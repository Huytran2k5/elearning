import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/data/auth_service.dart';
import '../data/quiz_model.dart';
import '../data/quiz_service.dart';
import 'create_quiz_screen.dart';
import 'question_bank_screen.dart';
import 'take_quiz_screen.dart';
import 'quiz_tracking_screen.dart';

class QuizTab extends StatelessWidget {
  final String courseId;
  final String userRole;
  final bool isReadOnly; // Biến kiểm tra Read-only

  QuizTab({
    super.key,
    required this.courseId,
    required this.userRole,
    this.isReadOnly = false, // Mặc định false
  });

  final _quizService = QuizService();

  @override
  Widget build(BuildContext context) {
    final isInstructor = userRole == AppConstants.roleInstructor;

    return Scaffold(
      body: Column(
        children: [
          // 1. Toolbar cho Giảng viên (Ẩn nút tạo nếu ReadOnly - hoặc để đó nhưng báo lỗi khi bấm)
          // Ở đây tôi vẫn để hiện, nhưng có thể thêm logic disable nếu muốn
          if (isInstructor)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuestionBankScreen(courseId: courseId))),
                      icon: const Icon(Icons.storage),
                      label: const Text("Ngân hàng CH"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[100], foregroundColor: Colors.brown),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (isReadOnly) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Học kỳ đã đóng!")));
                          return; // Chặn nếu cần
                        }
                        Navigator.push(context, MaterialPageRoute(builder: (_) => CreateQuizScreen(courseId: courseId)));
                      },
                      icon: const Icon(Icons.add_task),
                      label: const Text("Tạo Đề Thi"),
                    ),
                  ),
                ],
              ),
            ),

          // 2. Danh sách Quiz
          Expanded(
            child: StreamBuilder<List<QuizModel>>(
              stream: _quizService.getQuizzes(courseId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final quizzes = snapshot.data ?? [];

                if (quizzes.isEmpty) return const Center(child: Text("Chưa có bài kiểm tra nào."));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: quizzes.length,
                  itemBuilder: (context, index) {
                    final quiz = quizzes[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.purple,
                          child: Text("${quiz.durationMinutes}'", style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                        title: Text(quiz.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Mở: ${DateFormat('dd/MM HH:mm').format(quiz.openAt)}\nĐóng: ${DateFormat('dd/MM HH:mm').format(quiz.closeAt)}"),
                        isThreeLine: true,
                        trailing: isInstructor
                            ? IconButton(icon: const Icon(Icons.analytics), onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => QuizTrackingScreen(quiz: quiz))
                          );
                        }) // Nút xem thống kê cho GV
                            : ElevatedButton(
                          onPressed: () => _startQuiz(context, quiz),
                          style: ElevatedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            backgroundColor: isReadOnly ? Colors.grey : Colors.blue,
                          ),
                          child: Text(isReadOnly ? "Đã đóng" : "Làm bài", style: const TextStyle(color: Colors.white)),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _startQuiz(BuildContext context, QuizModel quiz) {
    // 1. Check ReadOnly
    if (isReadOnly) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Học kỳ đã kết thúc! Không thể làm bài."),
            backgroundColor: Colors.orange,
          )
      );
      return;
    }

    // 2. Check thời gian
    final now = DateTime.now();
    if (now.isBefore(quiz.openAt)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chưa đến giờ làm bài!")));
      return;
    }
    if (now.isAfter(quiz.closeAt)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã hết hạn làm bài!")));
      return;
    }

    // 3. Vào thi
    Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TakeQuizScreen(quiz: quiz))
    );
  }
}