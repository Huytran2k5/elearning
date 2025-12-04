import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/quiz_model.dart';
import '../data/quiz_service.dart';

class CreateQuizScreen extends StatefulWidget {
  final String courseId;
  const CreateQuizScreen({super.key, required this.courseId});

  @override
  State<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final _titleCtrl = TextEditingController();
  final _quizService = QuizService();

  DateTime _openAt = DateTime.now();
  DateTime _closeAt = DateTime.now().add(const Duration(days: 1));
  int _duration = 30;
  int _attempts = 1;

  // Cấu trúc đề
  int _easyCount = 5;
  int _mediumCount = 3;
  int _hardCount = 2;

  void _create() {
    if (_titleCtrl.text.isEmpty) return;

    final quiz = QuizModel(
      id: '',
      courseId: widget.courseId,
      title: _titleCtrl.text,
      description: '',
      openAt: _openAt,
      closeAt: _closeAt,
      durationMinutes: _duration,
      maxAttempts: _attempts,
      structure: {
        'EASY': _easyCount,
        'MEDIUM': _mediumCount,
        'HARD': _hardCount,
      },
    );

    _quizService.createQuiz(quiz);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tạo Đề Thi Mới")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: "Tiêu đề Quiz", border: OutlineInputBorder())),
            const SizedBox(height: 20),

            // Cấu hình ngẫu nhiên
            const Text("Cấu trúc đề (Ngẫu nhiên)", style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(child: _buildCountInput("Số câu Dễ", _easyCount, (v) => setState(() => _easyCount = v))),
                const SizedBox(width: 10),
                Expanded(child: _buildCountInput("Số câu TB", _mediumCount, (v) => setState(() => _mediumCount = v))),
                const SizedBox(width: 10),
                Expanded(child: _buildCountInput("Số câu Khó", _hardCount, (v) => setState(() => _hardCount = v))),
              ],
            ),

            const Divider(),
            _buildNumberInput("Thời gian làm bài (phút)", _duration, (v) => setState(() => _duration = v)),
            _buildNumberInput("Số lần làm tối đa", _attempts, (v) => setState(() => _attempts = v)),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(onPressed: _create, child: const Text("TẠO QUIZ")),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCountInput(String label, int val, Function(int) onChange) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        DropdownButton<int>(
          value: val,
          items: List.generate(11, (index) => DropdownMenuItem(value: index, child: Text("$index"))),
          onChanged: (v) => onChange(v!),
        )
      ],
    );
  }

  Widget _buildNumberInput(String label, int val, Function(int) onChange) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        DropdownButton<int>(
          value: val,
          items: [1, 5, 10, 15, 30, 45, 60, 90].map((e) => DropdownMenuItem(value: e, child: Text("$e"))).toList(),
          onChanged: (v) => onChange(v!),
        )
      ],
    );
  }
}