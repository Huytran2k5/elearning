import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/search_filter_bar.dart';
import '../../../core/services/admin_system_service.dart'; // <--- IMPORT MỚI
import '../../auth/data/user_model.dart';
import '../../auth/data/auth_service.dart';
import '../data/student_csv_service.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StudentCsvService _csvService = StudentCsvService();
  final AuthService _authService = AuthService(); // Vẫn dùng để check trùng email (nếu cần)

  // Data State
  List<UserModel> _allStudents = [];
  List<UserModel> _displayStudents = [];

  // Filter State
  String _searchQuery = "";
  String _sortValue = "Tên A-Z";
  final List<String> _sortOptions = ["Tên A-Z", "Tên Z-A", "Email A-Z", "Mới nhất"];

  // Import State
  List<CsvImportResult> _previewData = [];
  bool _isAnalyzing = false;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _processData() {
    List<UserModel> temp = List.from(_allStudents);
    // Search
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      temp = temp.where((u) {
        return (u.displayName ?? "").toLowerCase().contains(query) ||
            u.email.toLowerCase().contains(query) ||
            (u.studentCode ?? "").toLowerCase().contains(query);
      }).toList();
    }
    // Sort
    temp.sort((a, b) {
      switch (_sortValue) {
        case "Tên A-Z": return (a.displayName ?? "").compareTo(b.displayName ?? "");
        case "Tên Z-A": return (b.displayName ?? "").compareTo(a.displayName ?? "");
        case "Email A-Z": return a.email.compareTo(b.email);
        default: return 0;
      }
    });
    setState(() => _displayStudents = temp);
  }

  void _pickAndAnalyzeCsv() async {
    setState(() => _isAnalyzing = true);
    try {
      final result = await _csvService.pickCsvFile();
      if (result != null) {
        final bytes = result.files.first.bytes;
        if (bytes != null) {
          final results = await _csvService.processCsvData(bytes);
          setState(() => _previewData = results);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi đọc file: $e")));
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  // --- HÀM NHẬP LIỆU MỚI (TẠO AUTH + EMAIL) ---
  void _executeImport() async {
    final validRows = _previewData.where((item) => !item.isDuplicate).toList();

    if (validRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Không có dữ liệu mới để nhập!")));
      return;
    }

    setState(() => _isImporting = true);
    final adminSys = AdminSystemService(); // Service mới
    int successCount = 0;
    int failCount = 0;

    // Duyệt từng dòng để tạo tài khoản
    for (var item in validRows) {
      try {
        await adminSys.createStudentAccount(
          email: item.user.email,
          name: item.user.displayName ?? "Sinh viên",
          studentCode: item.user.studentCode ?? "",
        );
        successCount++;
      } catch (e) {
        failCount++;
        print("Lỗi import ${item.user.email}: $e");
      }
    }

    setState(() {
      _isImporting = false;
      _previewData = [];
    });

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Hoàn tất! Thành công: $successCount, Lỗi: $failCount"),
          backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
        )
    );
    _tabController.animateTo(0); // Về tab danh sách
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý Sinh viên"),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [Tab(text: "Danh sách"), Tab(text: "Nhập CSV")],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStudentListTab(),
          _buildCsvImportView(),
        ],
      ),
    );
  }

  Widget _buildStudentListTab() {
    return Column(
      children: [
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
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection(AppConstants.collUsers).where('role', isEqualTo: AppConstants.roleStudent).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData) return const SizedBox.shrink();

              var students = snapshot.data!.docs.map((d) => UserModel.fromFirestore(d)).toList();

              // Logic lọc/sắp xếp trực tiếp để tránh chớp
              if (_searchQuery.isNotEmpty) {
                final q = _searchQuery.toLowerCase();
                students = students.where((u) => (u.displayName??"").toLowerCase().contains(q) || u.email.toLowerCase().contains(q) || (u.studentCode??"").toLowerCase().contains(q)).toList();
              }
              students.sort((a, b) {
                switch (_sortValue) {
                  case "Tên A-Z": return (a.displayName??"").compareTo(b.displayName??"");
                  case "Tên Z-A": return (b.displayName??"").compareTo(a.displayName??"");
                  case "Email A-Z": return a.email.compareTo(b.email);
                  default: return 0;
                }
              });

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(alignment: Alignment.centerLeft, child: Text("Tìm thấy: ${students.length} sinh viên", style: const TextStyle(color: Colors.grey))),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.separated(
                      itemCount: students.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final u = students[index];
                        return ListTile(
                          leading: CircleAvatar(child: Text(u.displayName?[0] ?? "S")),
                          title: Text(u.displayName ?? "No Name"),
                          subtitle: Text("${u.studentCode ?? '---'} | ${u.email}"),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCsvImportView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Yêu cầu file CSV:", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("Cột 1: Mã SV | Cột 2: Họ tên | Cột 3: Email", style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isAnalyzing ? null : _pickAndAnalyzeCsv,
                icon: _isAnalyzing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.folder_open),
                label: const Text("Chọn File"),
              ),
            ],
          ),
        ),
        Expanded(
          child: _previewData.isEmpty
              ? const Center(child: Text("Vui lòng chọn file CSV để xem trước."))
              : SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Trạng thái')),
                  DataColumn(label: Text('Mã SV')),
                  DataColumn(label: Text('Họ Tên')),
                  DataColumn(label: Text('Email')),
                ],
                rows: _previewData.map((item) {
                  return DataRow(
                    color: MaterialStateProperty.resolveWith<Color?>((states) => item.isDuplicate ? Colors.grey[200] : Colors.green[50]),
                    cells: [
                      DataCell(Row(children: [
                        Icon(item.isDuplicate ? Icons.warning : Icons.check_circle, color: item.isDuplicate ? Colors.orange : Colors.green, size: 18),
                        const SizedBox(width: 8),
                        Text(item.statusMessage, style: TextStyle(color: item.isDuplicate ? Colors.orange[800] : Colors.green[800], fontWeight: FontWeight.bold)),
                      ])),
                      DataCell(Text(item.user.studentCode ?? "---")),
                      DataCell(Text(item.user.displayName ?? "")),
                      DataCell(Text(item.user.email)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        if (_previewData.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, -2))]),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Sẽ nhập: ${_previewData.where((e) => !e.isDuplicate).length} sinh viên"),
                ElevatedButton(
                  onPressed: _isImporting ? null : _executeImport,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12)),
                  child: _isImporting ? const CircularProgressIndicator(color: Colors.white) : const Text("XÁC NHẬN NHẬP"),
                ),
              ],
            ),
          )
      ],
    );
  }
}