import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:file_saver/file_saver.dart';

import 'assignment_model.dart';
import 'submission_model.dart';
import '../../quiz/data/quiz_model.dart';
import '../../quiz/data/quiz_attempt_model.dart';

class CsvExportService {

  Future<String> _saveCsvFile(String fileName, List<List<dynamic>> rows) async {
    String csvData = const ListToCsvConverter().convert(rows);
    final String csvContentWithBOM = '\uFEFF$csvData';
    Uint8List bytes = Uint8List.fromList(utf8.encode(csvContentWithBOM));

    String path = await FileSaver.instance.saveFile(
      name: fileName,
      bytes: bytes,
      ext: "csv",
      mimeType: MimeType.csv,
    );
    return path;
  }

  // Xuất Bài tập
  Future<String> exportAssignmentStats(AssignmentModel assignment, List<SubmissionModel> submissions) async {
    List<List<dynamic>> rows = [];
    rows.add(["Báo cáo bài tập: ${assignment.title}", "Ngày xuất: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}"]);
    rows.add(["Mã SV (ID)", "Họ Tên", "Email", "Nhóm", "Trạng thái", "Lần nộp", "Điểm số", "Thời gian nộp", "Link bài làm"]);

    for (var sub in submissions) {
      rows.add([
        sub.studentId, // Assignment chưa update studentCode, dùng ID tạm
        sub.studentName,
        sub.studentEmail,
        sub.groupId,
        sub.isLate ? "Trễ hạn" : "Đúng hạn",
        sub.attemptNumber,
        sub.grade ?? "Chưa chấm",
        DateFormat('dd/MM/yyyy HH:mm').format(sub.submittedAt),
        sub.fileUrls.join(", ")
      ]);
    }
    String safeName = "BaoCao_${assignment.title.replaceAll(RegExp(r'\s+'), '_')}";
    return await _saveCsvFile(safeName, rows);
  }

  // Xuất Quiz (ĐÃ SỬA: Dùng studentCode)
  Future<String> exportQuizStats(QuizModel quiz, List<QuizAttemptModel> attempts) async {
    List<List<dynamic>> rows = [];

    rows.add(["Báo cáo điểm thi: ${quiz.title}", "Ngày xuất: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}"]);
    rows.add(["Mã SV", "Họ Tên", "Điểm số", "Thời gian nộp", "Trạng thái"]);

    for (var att in attempts) {
      // Ưu tiên hiển thị Mã SV, nếu không có (dữ liệu cũ) thì fallback về UID
      String displayId = att.studentCode.isNotEmpty ? att.studentCode : att.studentId;

      rows.add([
        displayId, // <--- HIỂN THỊ MÃ SV
        att.studentName,
        att.score?.toStringAsFixed(2) ?? "0",
        att.finishedAt != null ? DateFormat('dd/MM HH:mm').format(att.finishedAt!) : "--",
        att.finishedAt != null ? "Hoàn thành" : "Đang làm"
      ]);
    }

    String safeName = "DiemThi_${quiz.title.replaceAll(RegExp(r'\s+'), '_')}";
    return await _saveCsvFile(safeName, rows);
  }
}