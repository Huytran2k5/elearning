import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../data/assignment_model.dart';
import '../data/assignment_service.dart';
import '../../course/data/group_model.dart';
import '../data/content_service.dart';

class CreateAssignmentScreen extends StatefulWidget {
  final String courseId;
  const CreateAssignmentScreen({super.key, required this.courseId});

  @override
  State<CreateAssignmentScreen> createState() => _CreateAssignmentScreenState();
}

class _CreateAssignmentScreenState extends State<CreateAssignmentScreen> {
  final _assignmentService = AssignmentService();
  final _contentService = ContentService();

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  DateTime _openAt = DateTime.now();
  DateTime _dueAt = DateTime.now().add(const Duration(days: 7));
  bool _allowLate = false;
  DateTime? _lateDueAt;

  int _maxAttempts = 1;
  List<GroupModel> _availableGroups = [];
  List<String> _selectedGroupIds = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  void _loadGroups() async {
    final groups = await _contentService.getCourseGroups(widget.courseId);
    setState(() => _availableGroups = groups);
  }

  Future<void> _pickDateTime(bool isStart) async {
    final initialDate = isStart ? _openAt : _dueAt;
    final date = await showDatePicker(
        context: context,
        firstDate: DateTime.now().subtract(const Duration(days: 1)),
        lastDate: DateTime(2030),
        initialDate: initialDate);

    if (date != null && mounted) {
      final time = await showTimePicker(
          context: context, initialTime: TimeOfDay.fromDateTime(initialDate));
      if (time != null) {
        setState(() {
          final result =
              DateTime(date.year, date.month, date.day, time.hour, time.minute);
          if (isStart) {
            _openAt = result;
          } else {
            _dueAt = result;
            if (_lateDueAt != null && _lateDueAt!.isBefore(_dueAt)) {
              _lateDueAt = _dueAt.add(const Duration(days: 1));
            }
          }
        });
      }
    }
  }

  void _submit() async {
    if (_titleCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Chưa nhập tiêu đề")));
      return;
    }

    setState(() => _isLoading = true);

    final newAsm = AssignmentModel(
      id: '',
      courseId: widget.courseId,
      title: _titleCtrl.text,
      description: _descCtrl.text,
      openAt: _openAt,
      dueAt: _dueAt,
      allowLate: _allowLate,
      lateDueAt: _allowLate
          ? (_lateDueAt ?? _dueAt.add(const Duration(days: 3)))
          : null,
      maxAttempts: _maxAttempts,
      targetGroupIds: _selectedGroupIds,
      attachmentUrls: [],
    );

    // 1. Lưu bài tập
    await _assignmentService.createAssignment(newAsm);

    // 2. Gửi email thông báo cho học viên
    try {
      print('📧 Starting assignment notification process...');
      print('🔍 GroupId (widget.courseId): ${widget.courseId}');
      print('🔍 Selected GroupIds: $_selectedGroupIds');

      // A. Query enrollments để lấy danh sách học viên
      // Lưu ý: widget.courseId thực chất là groupId
      Query enrollQuery =
          FirebaseFirestore.instance.collection(AppConstants.collEnrollments);

      // Nếu có chọn nhóm cụ thể (targetGroupIds)
      if (_selectedGroupIds.isNotEmpty) {
        enrollQuery = enrollQuery.where('groupId', whereIn: _selectedGroupIds);
        print('🔍 Filtering by specific groups: $_selectedGroupIds');
      } else {
        // Nếu không chọn, gửi cho nhóm hiện tại
        enrollQuery = enrollQuery.where('groupId', isEqualTo: widget.courseId);
        print('🔍 Filtering by current group: ${widget.courseId}');
      }

      final enrollments = await enrollQuery.get();
      print('📝 Found ${enrollments.docs.length} enrollments');

      // Debug: In ra tất cả enrollments để kiểm tra
      if (enrollments.docs.isEmpty) {
        print('⚠️ Checking all enrollments in database...');
        final allEnrollments = await FirebaseFirestore.instance
            .collection(AppConstants.collEnrollments)
            .limit(5)
            .get();
        print('📊 Total enrollments in DB: ${allEnrollments.docs.length}');
        for (var doc in allEnrollments.docs) {
          print(
              '   - Enrollment: courseId=${doc['courseId']}, userId=${doc['userId']}, groupId=${doc.data().containsKey('groupId') ? doc['groupId'] : 'N/A'}');
        }
      }

      if (enrollments.docs.isNotEmpty) {
        // B. Lấy userId từ enrollments
        List<String> userIds =
            enrollments.docs.map((e) => e['userId'] as String).toList();

        // C. Lấy email từ users (batch processing để tránh giới hạn whereIn = 10)
        List<String> allEmails = [];
        const batchSize = 10;

        for (int i = 0; i < userIds.length; i += batchSize) {
          final batch = userIds.skip(i).take(batchSize).toList();
          final usersSnap = await FirebaseFirestore.instance
              .collection(AppConstants.collUsers)
              .where(FieldPath.documentId, whereIn: batch)
              .get();

          final emails =
              usersSnap.docs.map((u) => u['email'] as String).toList();
          allEmails.addAll(emails);
        }

        print('📬 Found ${allEmails.length} email addresses');

        // D. Gửi email qua Firebase Extension
        if (allEmails.isNotEmpty) {
          final formattedDate =
              DateFormat('dd/MM/yyyy HH:mm').format(newAsm.dueAt);

          await FirebaseFirestore.instance.collection('mail').add({
            'to': allEmails,
            'message': {
              'subject': '📚 Bài tập mới: ${newAsm.title}',
              'text': '''
Kính gửi các bạn học viên,

Giảng viên vừa giao bài tập mới trong khóa học.

---------------------------------------
📝 Tên bài tập: ${newAsm.title}
⏰ Hạn nộp: $formattedDate
---------------------------------------

Vui lòng truy cập ứng dụng để xem chi tiết và nộp bài đúng hạn.

Chúc các bạn học tốt!
''',
              'html': '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; background-color: #f5f5f5; }
    .container { max-width: 600px; margin: 20px auto; background-color: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
    .header { background: linear-gradient(135deg, #1565C0 0%, #0D47A1 100%); color: white; padding: 30px 20px; text-align: center; }
    .header h1 { margin: 0; font-size: 24px; }
    .content { padding: 30px 20px; }
    .assignment-box { background-color: #E3F2FD; padding: 20px; border-radius: 8px; border-left: 4px solid #FF6F00; margin: 20px 0; }
    .assignment-box strong { color: #1565C0; display: inline-block; min-width: 100px; }
    .due-date { color: #D32F2F; font-weight: bold; font-size: 16px; }
    .footer { background-color: #f9f9f9; padding: 20px; text-align: center; color: #777; font-size: 12px; border-top: 1px solid #eee; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>📚 Bài tập mới</h1>
    </div>
    <div class="content">
      <p>Kính gửi các bạn học viên,</p>
      <p>Giảng viên vừa giao bài tập mới.</p>
      
      <div class="assignment-box">
        <div style="margin-bottom: 10px;">
          <strong>📝 Tên bài tập:</strong> ${newAsm.title}
        </div>
        <div>
          <strong>⏰ Hạn nộp:</strong> <span class="due-date">$formattedDate</span>
        </div>
      </div>
      
      <p>Vui lòng truy cập ứng dụng để xem chi tiết và nộp bài đúng hạn.</p>
      
      <p>Chúc các bạn học tốt! 🎓</p>
    </div>
    <div class="footer">
      <p>Đây là email tự động từ Hệ thống E-Learning. Vui lòng không trả lời email này.</p>
      <p>© 2025 IT E-Learning System</p>
    </div>
  </div>
</body>
</html>
'''
            }
          });

          print(
              '✅ Assignment notification email sent to ${allEmails.length} students');
        }
      } else {
        print('⚠️ No students enrolled in this course');
      }
    } catch (e) {
      print('❌ Error sending assignment notification: $e');
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Đã giao bài tập!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Giao Bài Tập Mới")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                    labelText: "Tiêu đề bài tập",
                    border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                    labelText: "Mô tả / Đề bài", border: OutlineInputBorder())),
            const SizedBox(height: 20),
            const Text("Cấu hình Thời gian",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            ListTile(
              title: const Text("Ngày mở đề"),
              subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(_openAt)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDateTime(true),
            ),
            ListTile(
              title: const Text("Hạn chót (Deadline)"),
              subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(_dueAt),
                  style: const TextStyle(color: Colors.red)),
              trailing: const Icon(Icons.event_busy, color: Colors.red),
              onTap: () => _pickDateTime(false),
            ),
            SwitchListTile(
              title: const Text("Cho phép nộp trễ?"),
              value: _allowLate,
              onChanged: (val) => setState(() => _allowLate = val),
            ),
            if (_allowLate)
              ListTile(
                title: const Text("Hạn chót nộp trễ"),
                subtitle: Text(_lateDueAt == null
                    ? "Chọn ngày..."
                    : DateFormat('dd/MM/yyyy HH:mm').format(_lateDueAt!)),
                leading: const Icon(Icons.warning_amber),
                onTap: () async {
                  setState(
                      () => _lateDueAt = _dueAt.add(const Duration(days: 3)));
                },
              ),
            const Divider(),
            Row(
              children: [
                const Text("Số lần nộp tối đa: "),
                DropdownButton<int>(
                  value: _maxAttempts,
                  items: [1, 2, 3, 5, 10]
                      .map((e) =>
                          DropdownMenuItem(value: e, child: Text("$e lần")))
                      .toList(),
                  onChanged: (val) => setState(() => _maxAttempts = val!),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text("Giao cho nhóm:"),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text("Tất cả"),
                  selected: _selectedGroupIds.isEmpty,
                  onSelected: (val) => setState(() => _selectedGroupIds = []),
                ),
                ..._availableGroups.map((g) => FilterChip(
                      label: Text(g.name),
                      selected: _selectedGroupIds.contains(g.id),
                      onSelected: (sel) {
                        setState(() => sel
                            ? _selectedGroupIds.add(g.id)
                            : _selectedGroupIds.remove(g.id));
                      },
                    )),
              ],
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text("XÁC NHẬN GIAO BÀI"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
