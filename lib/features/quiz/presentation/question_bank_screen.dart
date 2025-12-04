import 'package:flutter/material.dart';
import '../data/question_model.dart';
import '../data/quiz_service.dart';

class QuestionBankScreen extends StatefulWidget {
  final String courseId;
  const QuestionBankScreen({super.key, required this.courseId});

  @override
  State<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends State<QuestionBankScreen> {
  final _quizService = QuizService();

  void _showAddQuestionDialog() {
    final textCtrl = TextEditingController();
    final optACtrl = TextEditingController();
    final optBCtrl = TextEditingController();
    final optCCtrl = TextEditingController();
    final optDCtrl = TextEditingController();
    int correctIndex = 0;
    String difficulty = 'EASY';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Thêm Câu Hỏi Mới"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: textCtrl, decoration: const InputDecoration(labelText: "Nội dung câu hỏi"), maxLines: 2),
                    const SizedBox(height: 10),
                    TextField(controller: optACtrl, decoration: const InputDecoration(labelText: "Đáp án A")),
                    TextField(controller: optBCtrl, decoration: const InputDecoration(labelText: "Đáp án B")),
                    TextField(controller: optCCtrl, decoration: const InputDecoration(labelText: "Đáp án C")),
                    TextField(controller: optDCtrl, decoration: const InputDecoration(labelText: "Đáp án D")),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text("Đáp án đúng: "),
                        DropdownButton<int>(
                          value: correctIndex,
                          items: const [
                            DropdownMenuItem(value: 0, child: Text("A")),
                            DropdownMenuItem(value: 1, child: Text("B")),
                            DropdownMenuItem(value: 2, child: Text("C")),
                            DropdownMenuItem(value: 3, child: Text("D")),
                          ],
                          onChanged: (val) => setState(() => correctIndex = val!),
                        )
                      ],
                    ),
                    Row(
                      children: [
                        const Text("Độ khó: "),
                        DropdownButton<String>(
                          value: difficulty,
                          items: const [
                            DropdownMenuItem(value: 'EASY', child: Text("Dễ")),
                            DropdownMenuItem(value: 'MEDIUM', child: Text("Trung bình")),
                            DropdownMenuItem(value: 'HARD', child: Text("Khó")),
                          ],
                          onChanged: (val) => setState(() => difficulty = val!),
                        )
                      ],
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
                ElevatedButton(
                  onPressed: () {
                    if (textCtrl.text.isEmpty) return;
                    final q = QuestionModel(
                      id: '',
                      courseId: widget.courseId,
                      questionText: textCtrl.text,
                      options: [optACtrl.text, optBCtrl.text, optCCtrl.text, optDCtrl.text],
                      correctOptionIndex: correctIndex,
                      difficulty: difficulty,
                    );
                    _quizService.addQuestion(q);
                    Navigator.pop(ctx);
                  },
                  child: const Text("Lưu"),
                )
              ],
            );
          }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ngân hàng câu hỏi")),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddQuestionDialog,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<QuestionModel>>(
        stream: _quizService.getQuestions(widget.courseId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final questions = snapshot.data!;

          if (questions.isEmpty) return const Center(child: Text("Ngân hàng trống. Hãy thêm câu hỏi."));

          return ListView.builder(
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final q = questions[index];
              Color diffColor = Colors.green;
              if (q.difficulty == 'MEDIUM') diffColor = Colors.orange;
              if (q.difficulty == 'HARD') diffColor = Colors.red;

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: diffColor,
                    child: Text(q.difficulty[0], style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(q.questionText),
                  subtitle: Text("Đúng: Option ${String.fromCharCode(65 + q.correctOptionIndex)}"), // 0->A, 1->B
                ),
              );
            },
          );
        },
      ),
    );
  }
}