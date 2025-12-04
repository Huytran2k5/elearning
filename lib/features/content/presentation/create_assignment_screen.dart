import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/admin_system_service.dart'; // <--- IMPORT MỚI
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
        initialDate: initialDate
    );

    if (date != null && mounted) {
      final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initialDate));
      if (time != null) {
        setState(() {
          final result = DateTime(date.year, date.month, date.day, time.hour, time.minute);
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chưa nhập tiêu đề")));
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
      lateDueAt: _allowLate ? (_lateDueAt ?? _dueAt.add(const Duration(days: 3))) : null,
      maxAttempts: _maxAttempts,
      targetGroupIds: _selectedGroupIds,
      attachmentUrls: [],
    );

    // 1. Lưu bài tập
    await _assignmentService.createAssignment(newAsm);

    // 2. --- LOGIC GỬI EMAIL THÔNG BÁO ---
    try {
      // A. Tìm xem gửi cho ai (Lọc Enrollment)
      Query enrollQuery = FirebaseFirestore.instance.collection(AppConstants.collEnrollments)
          .where('courseId', isEqualTo: widget.courseId);

      // Nếu có chọn nhóm cụ thể thì lọc thêm nhóm
      if (_selectedGroupIds.isNotEmpty) {
        enrollQuery = enrollQuery.where('groupId', whereIn: _selectedGroupIds);
      }

      final enrollments = await enrollQuery.get();

      if (enrollments.docs.isNotEmpty) {
        List<String> userIds = enrollments.docs.map((e) => e['userId'] as String).toList();

        // B. Lấy Email từ User ID (Lấy tối đa 50 người để demo, tránh quá tải query)
        // Trong thực tế, bạn nên dùng Cloud Function để xử lý việc này
        final usersSnap = await FirebaseFirestore.instance
            .collection(AppConstants.collUsers)
            .where(FieldPath.documentId, whereIn: userIds.take(10).toList()) // Demo limit 10
            .get();

        List<String> emails = usersSnap.docs.map((u) => u['email'] as String).toList();

        // C. Gửi mail
        if (emails.isNotEmpty) {
          final adminSys = AdminSystemService();
          await adminSys.sendAssignmentNotification(emails, "Khóa học CNTT", newAsm.title, newAsm.dueAt);
        }
      }
    } catch (e) {
    }
    // -------------------------------------

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã giao bài & Gửi email thông báo!")));
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
            TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: "Tiêu đề bài tập", border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _descCtrl, maxLines: 4, decoration: const InputDecoration(labelText: "Mô tả / Đề bài", border: OutlineInputBorder())),

            const SizedBox(height: 20),
            const Text("Cấu hình Thời gian", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),

            ListTile(
              title: const Text("Ngày mở đề"),
              subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(_openAt)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDateTime(true),
            ),
            ListTile(
              title: const Text("Hạn chót (Deadline)"),
              subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(_dueAt), style: const TextStyle(color: Colors.red)),
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
                subtitle: Text(_lateDueAt == null ? "Chọn ngày..." : DateFormat('dd/MM/yyyy HH:mm').format(_lateDueAt!)),
                leading: const Icon(Icons.warning_amber),
                onTap: () async {
                  setState(() => _lateDueAt = _dueAt.add(const Duration(days: 3)));
                },
              ),

            const Divider(),

            Row(
              children: [
                const Text("Số lần nộp tối đa: "),
                DropdownButton<int>(
                  value: _maxAttempts,
                  items: [1, 2, 3, 5, 10].map((e) => DropdownMenuItem(value: e, child: Text("$e lần"))).toList(),
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
                    setState(() => sel ? _selectedGroupIds.add(g.id) : _selectedGroupIds.remove(g.id));
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
                child: _isLoading ? const CircularProgressIndicator() : const Text("XÁC NHẬN GIAO BÀI"),
              ),
            )
          ],
        ),
      ),
    );
  }
}