import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/search_filter_bar.dart';
import '../../auth/data/auth_service.dart';
import '../../semester/data/semester_model.dart';
import '../../semester/data/semester_service.dart';
import '../data/course_model.dart';
import '../data/course_service.dart';
import '../data/group_model.dart';
import '../data/group_service.dart';
import 'group_detail_screen.dart'; // Màn hình thêm sinh viên
import 'course_detail_screen.dart'; // Màn hình vào lớp (Stream, Classwork)

class GroupManagementScreen extends StatefulWidget {
  const GroupManagementScreen({super.key});

  @override
  State<GroupManagementScreen> createState() => _GroupManagementScreenState();
}

class _GroupManagementScreenState extends State<GroupManagementScreen> {
  final _semesterService = SemesterService();
  final _courseService = CourseService();
  final _groupService = GroupService();
  final _currentUser = AuthService().currentUser!;

  SemesterModel? _selectedSemester;
  List<CourseModel> _allCourses = []; // Danh sách môn học để chọn

  String _searchQuery = "";
  String _sortValue = "Tên Môn A-Z";

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  void _loadSubjects() {
    // Lấy danh mục môn học (Catalog)
    _courseService.getAllCourses().listen((courses) {
      if (mounted) setState(() => _allCourses = courses);
    });
  }

  // --- DIALOG MỞ LỚP MỚI ---
  void _showCreateGroupDialog() {
    if (_selectedSemester == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng chọn Học kỳ trước!")));
      return;
    }

    CourseModel? selectedCourse;
    final groupNameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Mở Lớp Học Phần"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<CourseModel>(
                      decoration: const InputDecoration(labelText: "Chọn Môn Học", border: OutlineInputBorder()),
                      isExpanded: true,
                      hint: const Text("Tìm môn học..."),
                      items: _allCourses.map((c) => DropdownMenuItem(
                        value: c,
                        child: Text("${c.code} - ${c.name}", overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (val) => setState(() => selectedCourse = val),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: groupNameCtrl,
                      decoration: const InputDecoration(labelText: "Tên Nhóm (VD: N01)", border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 8),
                    if (selectedCourse != null)
                      Text(
                        "Lớp sẽ tạo: ${selectedCourse!.code} - ${groupNameCtrl.text}",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                      )
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
                ElevatedButton(
                  onPressed: () async { // <--- Thêm async
                    if (selectedCourse == null || groupNameCtrl.text.isEmpty) return;

                    final teacherName = _currentUser.displayName ?? "Giảng viên";

                    final newGroup = GroupModel(
                      id: '',
                      semesterId: _selectedSemester!.id,
                      courseId: selectedCourse!.id,
                      courseCode: selectedCourse!.code,
                      courseName: selectedCourse!.name,
                      name: groupNameCtrl.text.trim(), // Trim tên
                      teacherId: _currentUser.uid,
                      teacherName: teacherName,
                      studentCount: 0,
                    );

                    // --- BỌC TRONG TRY-CATCH ---
                    try {
                      await _groupService.createGroup(newGroup); // <--- Thêm await

                      if (mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã mở lớp thành công!")));
                      }
                    } catch (e) {
                      // Hiện lỗi trùng lặp
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(e.toString().replaceAll("Exception: ", "")),
                                backgroundColor: Colors.red
                            )
                        );
                      }
                    }
                    // ---------------------------
                  },
                  child: const Text("Tạo Nhóm"),
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
      appBar: AppBar(
        title: const Text("Quản Lý Lớp Học Phần"),
        backgroundColor: Colors.teal[800],
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateGroupDialog,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // 1. Dropdown Chọn Học Kỳ
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: StreamBuilder<List<SemesterModel>>(
              stream: _semesterService.getSemestersStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();
                final semesters = snapshot.data!;
                return DropdownButtonFormField<SemesterModel>(
                  decoration: const InputDecoration(
                      labelText: "Chọn Học Kỳ",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                  ),
                  value: _selectedSemester,
                  items: semesters.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                  onChanged: (val) => setState(() => _selectedSemester = val),
                );
              },
            ),
          ),

          // 2. Search & Sort
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: SearchFilterBar(
              onSearchChanged: (val) => setState(() => _searchQuery = val),
              filterOptions: const [], filterValue: null, onFilterChanged: (v){}, filterLabel: "",
              sortOptions: const ["Tên Môn A-Z", "Tên Nhóm A-Z"],
              sortValue: _sortValue,
              onSortChanged: (val) => setState(() => _sortValue = val!),
            ),
          ),

          // 3. Danh Sách Lớp
          Expanded(
            child: _selectedSemester == null
                ? const Center(child: Text("Vui lòng chọn học kỳ"))
                : StreamBuilder<List<GroupModel>>(
              stream: _groupService.getGroupsBySemester(_selectedSemester!.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: Text("Lỗi: ${snapshot.error}"));

                var groups = snapshot.data ?? [];

                // Client-side Filter & Sort
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  groups = groups.where((g) => g.courseName.toLowerCase().contains(q) || g.name.toLowerCase().contains(q)).toList();
                }

                groups.sort((a, b) {
                  if (_sortValue == "Tên Môn A-Z") return a.courseName.compareTo(b.courseName);
                  if (_sortValue == "Tên Nhóm A-Z") return a.name.compareTo(b.name);
                  return 0;
                });

                if (groups.isEmpty) return const Center(child: Text("Chưa có lớp nào trong học kỳ này."));

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final g = groups[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal,
                          child: Text(g.courseCode.isNotEmpty ? g.courseCode.substring(0, 1) : "C"),
                        ),
                        title: Text("${g.courseCode} - ${g.courseName}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Lớp: ${g.name} • ${g.studentCount} SV"),
                        children: [
                          // A. Nút Vào lớp học
                          Container(
                            width: double.infinity,
                            color: Colors.teal[50],
                            child: TextButton.icon(
                              onPressed: () {
                                // Truyền GroupModel vào CourseDetailScreen
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => CourseDetailScreen(
                                      group: g,
                                      userRole: AppConstants.roleInstructor,
                                    ))
                                );
                              },
                              icon: const Icon(Icons.login, color: Colors.teal),
                              label: const Text("Vào Lớp Học (Đăng bài/Tạo Quiz)", style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          // B. Nút Quản lý SV
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.people),
                            title: const Text("Quản lý danh sách sinh viên"),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => GroupDetailScreen(
                                    courseId: g.courseId,
                                    groupId: g.id,
                                    groupName: "${g.courseCode} - ${g.name}",
                                  ))
                              );
                            },
                          ),
                          // C. Nút xóa
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.delete, color: Colors.red),
                            title: const Text("Hủy lớp này", style: TextStyle(color: Colors.red)),
                            onTap: () => _groupService.deleteGroup(g.id),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}