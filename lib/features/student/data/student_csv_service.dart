import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'; // cho kIsWeb
import '../../auth/data/user_model.dart';
import '../../auth/data/auth_service.dart';
import '../../../core/constants/app_constants.dart';

class CsvImportResult {
  final UserModel user;
  final bool isDuplicate;
  final String statusMessage;

  CsvImportResult({
    required this.user,
    required this.isDuplicate,
    required this.statusMessage
  });
}

class StudentCsvService {
  final AuthService _authService = AuthService();

  // 1. Chọn file
  Future<FilePickerResult?> pickCsvFile() async {
    return await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true, // Quan trọng cho Web
    );
  }

  // 2. Parse và Validate
  Future<List<CsvImportResult>> processCsvData(List<int> fileBytes) async {
    // Decode bytes -> String -> CSV List
    final content = utf8.decode(fileBytes);
    final List<List<dynamic>> rows = const CsvToListConverter().convert(content, eol: '\n');

    List<String> importEmails = [];
    List<UserModel> parsedUsers = [];

    // Bỏ qua dòng header (index 0)
    for (int i = 1; i < rows.length; i++) {
      var row = rows[i];
      if (row.length < 3) continue; // Skip dòng lỗi

      // Giả sử format CSV: StudentCode, FullName, Email
      String code = row[0].toString().trim();
      String name = row[1].toString().trim();
      String email = row[2].toString().trim();

      if (email.isEmpty) continue;

      importEmails.add(email);
      // Tạo model tạm (ID sẽ sinh sau)
      parsedUsers.add(UserModel(
        id: '',
        email: email,
        role: AppConstants.roleStudent,
        displayName: name,
        studentCode: code // Cần thêm field này vào UserModel nếu chưa có
      ));
    }

    // Check trùng lặp từ Database
    List<String> existingEmails = await _authService.checkExistingEmails(importEmails);

    // Tạo kết quả cho màn hình Preview
    return parsedUsers.map((user) {
      bool exists = existingEmails.contains(user.email);
      return CsvImportResult(
        user: user,
        isDuplicate: exists,
        statusMessage: exists ? "Đã tồn tại (Bỏ qua)" : "Hợp lệ (Sẽ thêm)",
      );
    }).toList();
  }
}