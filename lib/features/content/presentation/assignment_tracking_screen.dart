import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/search_filter_bar.dart'; // Import Widget mới
import '../data/assignment_model.dart';
import '../data/submission_model.dart';
import '../data/assignment_service.dart';
import '../data/csv_export_service.dart';
import 'package:intl/intl.dart';


class AssignmentTrackingScreen extends StatefulWidget {
  final AssignmentModel assignment;
  const AssignmentTrackingScreen({super.key, required this.assignment});

  @override
  State<AssignmentTrackingScreen> createState() => _AssignmentTrackingScreenState();
}

class _AssignmentTrackingScreenState extends State<AssignmentTrackingScreen> {
  final _assignmentService = AssignmentService();
  final _csvService = CsvExportService();

  // Dữ liệu gốc và Dữ liệu hiển thị
  List<SubmissionModel> _allSubmissions = [];
  List<SubmissionModel> _displayList = [];

  // State quản lý Search/Filter/Sort
  String _searchQuery = "";

  String _filterValue = "Tất cả";
  final List<String> _filterOptions = ["Tất cả", "Đã chấm", "Chưa chấm", "Nộp trễ", "Đúng hạn"];

  String _sortValue = "Mới nhất";
  final List<String> _sortOptions = ["Mới nhất", "Cũ nhất", "Điểm cao -> Thấp", "Điểm thấp -> Cao", "Tên A-Z"];

  // Hàm xử lý logic chính (Core Logic)
  void _processData() {
    List<SubmissionModel> temp = List.from(_allSubmissions);

    // 1. LỌC (FILTER)
    if (_filterValue != "Tất cả") {
      temp = temp.where((sub) {
        if (_filterValue == "Đã chấm") return sub.grade != null;
        if (_filterValue == "Chưa chấm") return sub.grade == null;
        if (_filterValue == "Nộp trễ") return sub.isLate;
        if (_filterValue == "Đúng hạn") return !sub.isLate;
        return true;
      }).toList();
    }

    // 2. TÌM KIẾM (SEARCH)
    if (_searchQuery.isNotEmpty) {
      temp = temp.where((sub) {
        final name = sub.studentName.toLowerCase();
        final email = sub.studentEmail.toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || email.contains(query);
      }).toList();
    }

    // 3. SẮP XẾP (SORT)
    temp.sort((a, b) {
      switch (_sortValue) {
        case "Mới nhất": return b.submittedAt.compareTo(a.submittedAt);
        case "Cũ nhất": return a.submittedAt.compareTo(b.submittedAt);
        case "Điểm cao -> Thấp":
          return (b.grade ?? -1).compareTo(a.grade ?? -1); // Chưa chấm (-1) xếp cuối
        case "Điểm thấp -> Cao":
          return (a.grade ?? 999).compareTo(b.grade ?? 999);
        case "Tên A-Z": return a.studentName.compareTo(b.studentName);
        default: return 0;
      }
    });

    // Cập nhật UI
    setState(() => _displayList = temp);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Theo dõi: ${widget.assignment.title}"),
      ),
      body: StreamBuilder<List<SubmissionModel>>(
        stream: _assignmentService.getAllSubmissions(widget.assignment.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          // Chỉ cập nhật _allSubmissions khi có dữ liệu mới từ Stream
          // Và chỉ chạy _processData nếu đây là lần đầu hoặc stream đổi
          if (snapshot.hasData) {
            // Lưu ý: setState trong build là anti-pattern, nhưng với StreamBuilder cần xử lý khéo.
            // Cách tốt nhất: so sánh độ dài hoặc hash. Ở đây làm đơn giản:
            if (_allSubmissions.length != snapshot.data!.length) {
              _allSubmissions = snapshot.data!;
              // Defer processData to next frame to avoid build error
              WidgetsBinding.instance.addPostFrameCallback((_) => _processData());
            }
          }

          return Column(
            children: [
              // --- 1. THANH CÔNG CỤ (Dùng Widget mới) ---
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SearchFilterBar(
                  onSearchChanged: (val) {
                    _searchQuery = val;
                    _processData();
                  },
                  filterOptions: _filterOptions,
                  filterValue: _filterValue,
                  onFilterChanged: (val) {
                    _filterValue = val!;
                    _processData();
                  },
                  sortOptions: _sortOptions,
                  sortValue: _sortValue,
                  onSortChanged: (val) {
                    _sortValue = val!;
                    _processData();
                  },
                ),
              ),

              // --- 2. THỐNG KÊ NHANH ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text("Hiển thị: ${_displayList.length} / ${_allSubmissions.length} bài nộp",
                        style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // --- 3. BẢNG DỮ LIỆU ---
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(Colors.grey[200]),
                      columns: const [
                        DataColumn(label: Text("Sinh Viên")),
                        DataColumn(label: Text("Thời gian nộp")),
                        DataColumn(label: Text("Trạng thái")),
                        DataColumn(label: Text("Điểm")),
                      ],
                      rows: _displayList.map((sub) {
                        return DataRow(
                            cells: [
                              DataCell(
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(sub.studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text(sub.studentEmail, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                    ],
                                  )
                              ),
                              DataCell(Text(DateFormat('dd/MM HH:mm').format(sub.submittedAt))),
                              DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: sub.isLate ? Colors.red[50] : Colors.green[50],
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: sub.isLate ? Colors.red : Colors.green, width: 0.5)
                                    ),
                                    child: Text(
                                        sub.isLate ? "Trễ hạn" : "Đúng hạn",
                                        style: TextStyle(color: sub.isLate ? Colors.red : Colors.green, fontSize: 12)
                                    ),
                                  )
                              ),
                              DataCell(Text(
                                sub.grade?.toString() ?? "--",
                                style: TextStyle(fontWeight: FontWeight.bold, color: sub.grade != null ? Colors.blue : Colors.grey),
                              )),
                            ]
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}