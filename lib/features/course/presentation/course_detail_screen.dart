import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../data/group_model.dart'; // <--- Import GroupModel
import '../../content/presentation/stream_tab.dart';
import '../../content/presentation/classwork_tab.dart';
import '../../quiz/presentation/quiz_tab.dart';
import 'people_tab.dart';

class CourseDetailScreen extends StatefulWidget {
  final GroupModel group; // <--- Sử dụng GroupModel thay vì CourseModel
  final String userRole;

  const CourseDetailScreen(
      {super.key, required this.group, required this.userRole});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isReadOnly = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _checkSemesterStatus();
  }

  void _checkSemesterStatus() async {
    try {
      // Kiểm tra trạng thái học kỳ dựa trên semesterId trong Group
      final doc = await FirebaseFirestore.instance
          .collection(AppConstants.collSemesters)
          .doc(widget.group.semesterId)
          .get();

      if (doc.exists) {
        final isActive = doc.data()?['isActive'] ?? false;
        if (!isActive && widget.userRole == AppConstants.roleStudent) {
          setState(() => _isReadOnly = true);
        }
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hiển thị: Mã môn - Tên Nhóm (VD: IT001 - N01)
            Text("${widget.group.courseCode} - ${widget.group.name}"),
            if (_isReadOnly)
              const Text("(Close - Read Only)",
                  style: TextStyle(fontSize: 12, color: Colors.orangeAccent)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: "Stream"),
            Tab(text: "Classwork"),
            Tab(text: "Quiz"),
            Tab(text: "People"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // TRUYỀN GROUP ID (không phải courseId)
                // Vì assignments/materials được lưu theo courseId
                // Nhưng có targetGroupIds để filter theo nhóm
                // Và enrollments được query theo groupId
                StreamTab(
                    courseId: widget.group.id, // Truyền groupId
                    userRole: widget.userRole),

                ClassworkTab(
                  courseId: widget.group.id, // Truyền groupId
                  userRole: widget.userRole,
                  isReadOnly: _isReadOnly,
                ),

                QuizTab(
                  courseId: widget.group.id, // Truyền groupId
                  userRole: widget.userRole,
                  isReadOnly: _isReadOnly,
                ),

                PeopleTab(
                    courseId: widget.group.courseId, // ID môn học
                    groupId: widget.group.id, // <--- TRUYỀN ID NHÓM VÀO ĐÂY
                    userRole: widget.userRole),
              ],
            ),
    );
  }
}
