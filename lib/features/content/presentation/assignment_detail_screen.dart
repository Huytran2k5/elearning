import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';

// --- IMPORTS ---
import '../../../core/constants/app_constants.dart';
import '../../../core/services/cloudinary_service.dart'; // Service Upload
import '../../auth/data/auth_service.dart';
import '../data/assignment_model.dart';
import '../data/submission_model.dart';
import '../data/assignment_service.dart';
import 'assignment_tracking_screen.dart'; // Màn hình Tracking/Xuất CSV

class AssignmentDetailScreen extends StatefulWidget {
  final AssignmentModel assignment;
  final String userRole;
  final bool isReadOnly;

  const AssignmentDetailScreen({
    super.key,
    required this.assignment,
    required this.userRole,
    this.isReadOnly = false,
  });

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  final _authService = AuthService();
  final _assignmentService = AssignmentService();
  final _cloudinaryService = CloudinaryService(); // Service Upload ảnh/file

  bool _isSubmitting = false;

  // State Upload File
  String? _pendingFileUrl;
  String _pendingFileName = "";
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final isInstructor = widget.userRole == AppConstants.roleInstructor;

    return Scaffold(
      appBar: AppBar(title: Text(widget.assignment.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const Divider(height: 32),

            if (isInstructor)
              _buildInstructorView(context)
            else
              _buildStudentView(context),
          ],
        ),
      ),
    );
  }

  // --- THÔNG TIN ĐỀ BÀI ---
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
                "Hạn nộp: ${DateFormat('dd/MM HH:mm').format(widget.assignment.dueAt)}",
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)
            ),
            Chip(
              label: Text(widget.assignment.allowLate ? "Cho phép nộp trễ" : "Không nộp trễ"),
              backgroundColor: widget.assignment.allowLate ? Colors.orange[50] : Colors.red[50],
              labelStyle: TextStyle(fontSize: 12, color: widget.assignment.allowLate ? Colors.orange[900] : Colors.red[900]),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text("Mô tả / Đề bài:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 6),
        Text(widget.assignment.description, style: const TextStyle(fontSize: 15, height: 1.4)),

        // Hiển thị file đính kèm của đề bài (nếu có)
        if (widget.assignment.attachmentUrls.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text("Tài liệu đính kèm:", style: TextStyle(fontWeight: FontWeight.bold)),
          ...widget.assignment.attachmentUrls.map((url) => InkWell(
            onTap: () => launchUrl(Uri.parse(url)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.attach_file, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(url, style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline), overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          )),
        ]
      ],
    );
  }

  // --- GIAO DIỆN SINH VIÊN ---
  Widget _buildStudentView(BuildContext context) {
    final studentId = _authService.currentUser?.uid;
    if (studentId == null) return const SizedBox.shrink();

    return StreamBuilder<SubmissionModel?>(
      stream: _assignmentService.getMySubmission(widget.assignment.id, studentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final submission = snapshot.data;
        final isSubmitted = submission != null;

        return Card(
          color: Colors.blue[50],
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.blue.withOpacity(0.3))),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Bài làm của bạn", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                const SizedBox(height: 10),

                // 1. TRẠNG THÁI BÀI NỘP
                if (isSubmitted) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(submission.statusText,
                        style: TextStyle(
                            color: submission.grade != null ? Colors.green[700] : Colors.blue[700],
                            fontWeight: FontWeight.bold
                        )
                    ),
                    subtitle: submission.feedback != null
                        ? Text("Nhận xét GV: ${submission.feedback}", style: const TextStyle(fontWeight: FontWeight.w500))
                        : const Text("Đang đợi chấm điểm"),
                    leading: Icon(
                      submission.grade != null ? Icons.verified : Icons.access_time_filled,
                      color: submission.grade != null ? Colors.green : Colors.blue,
                      size: 30,
                    ),
                  ),
                  // Hiển thị file đã nộp
                  if (submission.fileUrls.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                      child: InkWell(
                        onTap: () => launchUrl(Uri.parse(submission.fileUrls.first)),
                        child: Row(
                          children: [
                            const Icon(Icons.description, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(child: Text("Xem file đã nộp", style: const TextStyle(decoration: TextDecoration.underline, color: Colors.blue))),
                            const Icon(Icons.open_in_new, size: 16, color: Colors.grey)
                          ],
                        ),
                      ),
                    ),
                  const Divider(height: 24),
                ],

                // 2. FORM NỘP BÀI (HOẶC NỘP LẠI)
                if (widget.isReadOnly)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock, color: Colors.deepOrange),
                        SizedBox(width: 10),
                        Expanded(child: Text("Học kỳ đã kết thúc. Không thể nộp bài.", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange))),
                      ],
                    ),
                  )
                else if (submission?.grade == null) ...[
                  // --- UI UPLOAD FILE (CLOUDINARY) ---
                  const Text("Nộp bài mới:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(8)
                    ),
                    child: Row(
                      children: [
                        IconButton.filledTonal(
                          onPressed: (_isSubmitting || _isUploading) ? null : _pickAssignmentFile,
                          icon: _isUploading
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.cloud_upload),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  _pendingFileName.isNotEmpty ? _pendingFileName : "Chưa chọn file",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _pendingFileName.isNotEmpty ? Colors.black : Colors.grey
                                  )
                              ),
                              if (_pendingFileName.isEmpty)
                                const Text("Hỗ trợ: PDF, Word, Zip, Ảnh...", style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                        if (_pendingFileName.isNotEmpty && !_isUploading)
                          const Icon(Icons.check_circle, color: Colors.green)
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: (_isSubmitting || _isUploading || _pendingFileUrl == null) ? null : _submitFile,
                      icon: _isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send),
                      label: Text(isSubmitted ? "Cập nhật bài nộp" : "Nộp bài ngay"),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[400]
                      ),
                    ),
                  )
                ] else
                  const Center(child: Text("Bài tập đã được chấm điểm. Không thể nộp lại.", style: TextStyle(color: Colors.green, fontStyle: FontStyle.italic))),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- LOGIC CHỌN VÀ UPLOAD FILE ---
  void _pickAssignmentFile() async {
    final file = await _cloudinaryService.pickFile(type: FileType.any);

    if (file != null) {
      setState(() {
        _isUploading = true;
        _pendingFileName = file.name;
      });

      // Upload lên Cloudinary
      final url = await _cloudinaryService.uploadFile(file);

      if (mounted) {
        setState(() {
          _isUploading = false;
          if (url != null) {
            _pendingFileUrl = url;
          } else {
            _pendingFileName = "";
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi Upload! Vui lòng thử lại.")));
          }
        });
      }
    }
  }

  // --- LOGIC NỘP BÀI (QUAN TRỌNG: FIX ID) ---
  void _submitFile() async {
    if (_pendingFileUrl == null) return;
    setState(() => _isSubmitting = true);

    try {
      final currentUser = _authService.currentUser!;
      final now = DateTime.now();

      // 1. Check hạn nộp
      bool isLate = now.isAfter(widget.assignment.dueAt);
      if (!widget.assignment.allowLate && isLate) {
        throw Exception("Đã quá hạn nộp bài!");
      }

      // 2. Logic lấy thông tin thật (Map Email -> Firestore ID)
      // Để đảm bảo Dashboard thống kê đúng
      String realStudentName = currentUser.displayName ?? "Student";
      String realStudentId = currentUser.uid; // Fallback

      try {
        if (currentUser.email != null) {
          final query = await FirebaseFirestore.instance
              .collection(AppConstants.collUsers)
              .where('email', isEqualTo: currentUser.email)
              .limit(1)
              .get();

          if(query.docs.isNotEmpty) {
            final doc = query.docs.first;
            realStudentId = doc.id; // Lấy ID Firestore
            realStudentName = doc.data()['displayName'] ?? "Student";
          }
        }
      } catch (e) {
        print("Lỗi map ID: $e");
      }

      // 3. Tạo Submission
      final submission = SubmissionModel(
        id: '',
        assignmentId: widget.assignment.id,
        studentId: realStudentId, // Sử dụng ID thật
        studentName: realStudentName,
        studentEmail: currentUser.email ?? "",
        groupId: "", // Có thể update sau nếu cần lọc theo nhóm
        fileUrls: [_pendingFileUrl!], // Link từ Cloudinary
        submittedAt: now,
        isLate: isLate,
        attemptNumber: 1,
      );

      await _assignmentService.submitAssignment(submission);

      // 4. Reset Form
      setState(() {
        _pendingFileUrl = null;
        _pendingFileName = "";
      });

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nộp bài thành công!")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // --- GIAO DIỆN GIẢNG VIÊN ---
  Widget _buildInstructorView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Danh sách bài nộp", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AssignmentTrackingScreen(assignment: widget.assignment))
                );
              },
              icon: const Icon(Icons.analytics),
              label: const Text("Theo dõi & Xuất CSV"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            )
          ],
        ),
        const SizedBox(height: 10),
        StreamBuilder<List<SubmissionModel>>(
          stream: _assignmentService.getAllSubmissions(widget.assignment.id),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final subs = snapshot.data!;
            if (subs.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Text("Chưa có sinh viên nào nộp bài."));

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: subs.length,
              itemBuilder: (context, index) {
                final sub = subs[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 2,
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: sub.isLate ? Colors.orange : Colors.blue,
                      child: Text(sub.studentName.isNotEmpty ? sub.studentName[0] : "S", style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(sub.studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      "${DateFormat('dd/MM HH:mm').format(sub.submittedAt)} ${sub.isLate ? '(Trễ)' : ''}",
                      style: TextStyle(color: sub.isLate ? Colors.red : Colors.grey[700]),
                    ),
                    trailing: sub.grade != null
                        ? Text("${sub.grade}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16))
                        : const Text("Chưa chấm", style: TextStyle(color: Colors.red, fontSize: 12)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (sub.fileUrls.isNotEmpty)
                              InkWell(
                                onTap: () => launchUrl(Uri.parse(sub.fileUrls.first)),
                                child: Row(
                                  children: [
                                    const Icon(Icons.cloud_download, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text("Mở file bài làm", style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontWeight: FontWeight.bold))),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 16),
                            _GradeForm(submission: sub, onGrade: _assignmentService.gradeSubmission),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            );
          },
        )
      ],
    );
  }
}

// Widget chấm điểm nhỏ (Inline)
class _GradeForm extends StatefulWidget {
  final SubmissionModel submission;
  final Function(String, double, String) onGrade;
  const _GradeForm({required this.submission, required this.onGrade});

  @override
  State<_GradeForm> createState() => _GradeFormState();
}

class _GradeFormState extends State<_GradeForm> {
  final _gradeCtrl = TextEditingController();
  final _feedbackCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.submission.grade != null) _gradeCtrl.text = widget.submission.grade.toString();
    if (widget.submission.feedback != null) _feedbackCtrl.text = widget.submission.feedback!;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
            width: 80,
            child: TextField(
                controller: _gradeCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Điểm", border: OutlineInputBorder(), contentPadding: EdgeInsets.all(10))
            )
        ),
        const SizedBox(width: 10),
        Expanded(
            child: TextField(
                controller: _feedbackCtrl,
                decoration: const InputDecoration(labelText: "Nhận xét", border: OutlineInputBorder(), contentPadding: EdgeInsets.all(10))
            )
        ),
        IconButton.filled(
          icon: const Icon(Icons.save, color: Colors.white),
          onPressed: () {
            final grade = double.tryParse(_gradeCtrl.text);
            if (grade != null) {
              widget.onGrade(widget.submission.id, grade, _feedbackCtrl.text);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã lưu điểm!")));
            }
          },
        )
      ],
    );
  }
}