import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/data/auth_service.dart';
import '../data/question_model.dart';
import '../data/quiz_model.dart';
import '../data/quiz_attempt_model.dart';
import '../data/quiz_service.dart';
import 'quiz_result_screen.dart';

class TakeQuizScreen extends StatefulWidget {
  final QuizModel quiz;
  const TakeQuizScreen({super.key, required this.quiz});

  @override
  State<TakeQuizScreen> createState() => _TakeQuizScreenState();
}

class _TakeQuizScreenState extends State<TakeQuizScreen> {
  final _quizService = QuizService();
  final _authService = AuthService();

  List<QuestionModel> _questions = [];
  QuizAttemptModel? _attempt;
  bool _isLoading = true;
  bool _isSubmitting = false;

  final Map<String, int> _answers = {};
  Timer? _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _initQuiz();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initQuiz() async {
    try {
      final currentUser = _authService.currentUser!;

      // --- LOGIC LẤY THÔNG TIN SINH VIÊN ---
      String realStudentId = currentUser.uid;
      String realStudentName = currentUser.displayName ?? "Student";
      String realStudentCode = ""; // <--- Biến chứa mã SV

      if (currentUser.email != null) {
        final userQuery = await FirebaseFirestore.instance
            .collection(AppConstants.collUsers)
            .where('email', isEqualTo: currentUser.email)
            .limit(1)
            .get();

        if (userQuery.docs.isNotEmpty) {
          final data = userQuery.docs.first.data();
          realStudentId = userQuery.docs.first.id;
          realStudentName = data['displayName'] ?? "Student";
          realStudentCode = data['studentCode'] ?? ""; // <--- Lấy mã SV từ DB
        }
      }
      // --------------------------------------

      // Gọi service với studentCode
      final attempt = await _quizService.startQuiz(
          widget.quiz,
          realStudentId,
          realStudentName,
          realStudentCode // <--- Truyền vào
      );

      final questions = await _quizService.generateQuizQuestions(widget.quiz.courseId, widget.quiz.structure);

      if (mounted) {
        setState(() {
          _attempt = attempt;
          _questions = questions;
          _remainingSeconds = widget.quiz.durationMinutes * 60;
          _isLoading = false;
        });
        _startTimer();
      }

    } catch (e) {
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text("Thông báo"),
            content: Text(e.toString().replaceAll("Exception: ", "")),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text("Quay lại"),
              )
            ],
          ),
        );
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _submit();
      }
    });
  }

  void _submit() async {
    if (_isSubmitting) return;
    _timer?.cancel();
    setState(() => _isSubmitting = true);

    try {
      await _quizService.submitQuiz(_attempt!.id, _answers);
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => QuizResultScreen(attemptId: _attempt!.id)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi nộp bài: $e")));
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _confirmSubmit() {
    int answeredCount = _answers.length;
    int totalCount = _questions.length;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Nộp bài?"),
        content: Text(answeredCount < totalCount ? "Bạn mới làm $answeredCount/$totalCount câu. Chắc chắn nộp?" : "Nộp bài ngay?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Làm tiếp")),
          ElevatedButton(onPressed: () { Navigator.pop(ctx); _submit(); }, child: const Text("Nộp bài")),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<bool> _onWillPop() async {
    if (_isLoading || _isSubmitting) return true;
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Thoát bài thi?"),
        content: const Text("Nếu thoát bây giờ, kết quả sẽ không được lưu."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Ở lại")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Thoát", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.quiz.title),
          automaticallyImplyLeading: false,
          actions: [
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(color: _remainingSeconds < 60 ? Colors.red : Colors.blue, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    const Icon(Icons.timer, size: 16, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(_formatTime(_remainingSeconds), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            )
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _questions.length,
                separatorBuilder: (_,__) => const Divider(height: 30, thickness: 1),
                itemBuilder: (context, index) {
                  return _buildQuestionItem(index, _questions[index]);
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, -2))]),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _confirmSubmit,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text("NỘP BÀI", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionItem(int index, QuestionModel q) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Câu ${index + 1}: ${q.questionText}", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ...List.generate(q.options.length, (optIndex) {
          final isSelected = _answers[q.id] == optIndex;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
                color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade300)
            ),
            child: RadioListTile<int>(
                title: Text(q.options[optIndex]),
                value: optIndex,
                groupValue: _answers[q.id],
                activeColor: Colors.blue,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                dense: true,
                onChanged: (val) {
                  setState(() {
                    _answers[q.id] = val!;
                  });
                }
            ),
          );
        })
      ],
    );
  }
}