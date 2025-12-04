import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/search_filter_bar.dart';
import '../../content/data/csv_export_service.dart';
import '../data/quiz_model.dart';
import '../data/quiz_attempt_model.dart';
import '../data/quiz_service.dart';

class QuizTrackingScreen extends StatefulWidget {
  final QuizModel quiz;
  const QuizTrackingScreen({super.key, required this.quiz});

  @override
  State<QuizTrackingScreen> createState() => _QuizTrackingScreenState();
}

class _QuizTrackingScreenState extends State<QuizTrackingScreen> {
  final _quizService = QuizService();
  final _csvService = CsvExportService();

  // State Search & Sort
  String _searchQuery = "";
  String _sortValue = "Điểm Cao -> Thấp";
  final List<String> _sortOptions = ["Điểm Cao -> Thấp", "Điểm Thấp -> Cao", "Tên A-Z", "Mới nộp"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Kết quả: ${widget.quiz.title}"),
        actions: [
          // --- NÚT XUẤT CSV CỦA BẠN ---
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: "Xuất CSV",
            onPressed: () async {
              // 1. Thông báo người dùng đợi
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Đang tải xuống..."))
              );

              try {
                // 2. Lấy dữ liệu mới nhất từ Firestore (One-shot query)
                final data = await _quizService.getQuizAttempts(widget.quiz.id).first;

                if (data.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Chưa có dữ liệu để xuất!"))
                  );
                  return;
                }

                // --- GỌI SERVICE VÀ NHẬN KẾT QUẢ ---
                String path = await _csvService.exportQuizStats(widget.quiz, data);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Đã lưu file tại: $path"),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 3),
                      )
                  );
                }

              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Lỗi xuất file: $e"), backgroundColor: Colors.red)
                );
              }
            },
          )
          // -----------------------------
        ],
      ),
      body: StreamBuilder<List<QuizAttemptModel>>(
        stream: _quizService.getQuizAttempts(widget.quiz.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text("Lỗi: ${snapshot.error}"));

          var attempts = snapshot.data ?? [];

          // 1. Lọc theo tên
          if (_searchQuery.isNotEmpty) {
            attempts = attempts.where((a) => a.studentName.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
          }

          // 2. Sắp xếp
          attempts.sort((a, b) {
            final scoreA = a.score ?? -1;
            final scoreB = b.score ?? -1;

            switch (_sortValue) {
              case "Điểm Cao -> Thấp": return scoreB.compareTo(scoreA);
              case "Điểm Thấp -> Cao": return scoreA.compareTo(scoreB);
              case "Tên A-Z": return a.studentName.compareTo(b.studentName);
              case "Mới nộp":
                final timeA = a.finishedAt ?? DateTime(2000);
                final timeB = b.finishedAt ?? DateTime(2000);
                return timeB.compareTo(timeA);
              default: return 0;
            }
          });

          return Column(
            children: [
              // Thanh công cụ
              Padding(
                padding: const EdgeInsets.all(16),
                child: SearchFilterBar(
                  onSearchChanged: (val) => setState(() => _searchQuery = val),
                  filterOptions: const [],
                  filterValue: null,
                  onFilterChanged: (val) {},
                  filterLabel: "",
                  sortOptions: _sortOptions,
                  sortValue: _sortValue,
                  onSortChanged: (val) => setState(() => _sortValue = val!),
                ),
              ),

              // Thống kê
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text("Đã nộp: ${attempts.length} bài", style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    if (attempts.isNotEmpty)
                      Text("TB: ${(attempts.map((e) => e.score ?? 0).reduce((a, b) => a + b) / attempts.length).toStringAsFixed(1)} điểm"),
                  ],
                ),
              ),
              const Divider(),

              // Danh sách
              Expanded(
                child: ListView.separated(
                  itemCount: attempts.length,
                  separatorBuilder: (_,__) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final att = attempts[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: (att.score ?? 0) >= 5 ? Colors.green : Colors.red,
                        child: Text("${att.score?.toStringAsFixed(1) ?? '?'}", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(att.studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Nộp: ${att.finishedAt != null ? DateFormat('HH:mm dd/MM').format(att.finishedAt!) : 'Đang làm'}"),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}