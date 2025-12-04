import 'package:flutter/material.dart';
import '../../../core/widgets/search_filter_bar.dart';
import '../data/course_model.dart';
import '../data/course_service.dart';

class CourseCatalogScreen extends StatefulWidget {
  const CourseCatalogScreen({super.key});

  @override
  State<CourseCatalogScreen> createState() => _CourseCatalogScreenState();
}

class _CourseCatalogScreenState extends State<CourseCatalogScreen> {
  final _service = CourseService();

  // State tìm kiếm & sắp xếp
  String _searchQuery = "";
  String _sortValue = "Code A-Z";
  final List<String> _sortOptions = ["Code A-Z", "Name A-Z", "Number of Credits"];

  // Hàm hiện dialog thêm môn
  void _showAddDialog() {
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final creditCtrl = TextEditingController(text: "3");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add New Course"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: codeCtrl,
                decoration: const InputDecoration(
                    labelText: "Course ID (e.g., IT001)",
                    hintText: "This ID is unique for each course",
                    border: OutlineInputBorder()
                )
            ),
            const SizedBox(height: 12),
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Course Name", border: OutlineInputBorder())
            ),
            const SizedBox(height: 12),
            TextField(
                controller: creditCtrl,
                decoration: const InputDecoration(labelText: "Number of credits", border: OutlineInputBorder()),
                keyboardType: TextInputType.number
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async { // <--- Phải có async
              if (codeCtrl.text.isEmpty || nameCtrl.text.isEmpty) return;

              try {
                // Gọi Service
                await _service.addCourse(CourseModel(
                  id: '',
                  code: codeCtrl.text.trim().toUpperCase(),
                  name: nameCtrl.text.trim(),
                  credits: int.tryParse(creditCtrl.text) ?? 3,
                  description: '',
                ));

                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("The course has been added successfully!")));
                }
              } catch (e) {
                // HIỆN THÔNG BÁO LỖI KHI TRÙNG
                // replaceAll để xóa chữ "Exception:" cho đẹp
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll("Exception: ", "")),
                      backgroundColor: Colors.red,
                    )
                );
              }
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Course Management"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text("Add Course"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<CourseModel>>(
        stream: _service.getAllCourses(), // Lấy toàn bộ môn học
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          var courses = snapshot.data!;

          // --- LOGIC LỌC & SẮP XẾP CLIENT-SIDE ---
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            courses = courses.where((c) => c.name.toLowerCase().contains(q) || c.code.toLowerCase().contains(q)).toList();
          }

          courses.sort((a, b) {
            switch (_sortValue) {
              case "Code A-Z": return a.code.compareTo(b.code);
              case "Name A-Z": return a.name.compareTo(b.name);
              case "Number of credits": return b.credits.compareTo(a.credits); // Nhiều tín chỉ lên đầu
              default: return 0;
            }
          });
          // ---------------------------------------

          if (courses.isEmpty) return const Center(child: Text("Blank, please add a new course!"));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SearchFilterBar(
                  onSearchChanged: (val) => setState(() => _searchQuery = val),
                  filterOptions: const [], filterValue: null, onFilterChanged: (v){}, // Không cần filter
                  filterLabel: "",
                  sortOptions: _sortOptions,
                  sortValue: _sortValue,
                  onSortChanged: (val) => setState(() => _sortValue = val!),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: courses.length,
                  padding: const EdgeInsets.all(8),
                  separatorBuilder: (_,__) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final c = courses[index];
                    return Card(
                      elevation: 1,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo[100],
                          child: Text("${c.credits}", style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                        ),
                        title: Text("${c.code} - ${c.name}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Credits: ${c.credits}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            // Cảnh báo trước khi xóa
                            showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text("Delete Course?"),
                                  content: const Text("Warning: Deleting the original course may affect the currently active classes."),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
                                    TextButton(onPressed: () {
                                      _service.deleteCourse(c.id);
                                      Navigator.pop(ctx);
                                    }, child: const Text("Delete", style: TextStyle(color: Colors.red))),
                                  ],
                                )
                            );
                          },
                        ),
                      ),
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