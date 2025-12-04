import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/semester_model.dart';
import '../data/semester_service.dart';

class SemesterListScreen extends StatelessWidget {
  SemesterListScreen({super.key});

  final SemesterService _service = SemesterService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Semester Management"),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSemesterDialog(context, null),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<SemesterModel>>(
        stream: _service.getSemestersStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final semesters = snapshot.data ?? [];

          if (semesters.isEmpty) {
            return const Center(child: Text("There are no semesters yet. Please create a new one!"));
          }

          return ListView.builder(
            itemCount: semesters.length,
            itemBuilder: (context, index) {
              final sem = semesters[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: sem.isActive ? Colors.green : Colors.grey,
                    child: Icon(sem.isActive ? Icons.check : Icons.history, color: Colors.white),
                  ),
                  title: Text(sem.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      "${DateFormat('dd/MM/yyyy').format(sem.startDate)} - ${DateFormat('dd/MM/yyyy').format(sem.endDate)}"
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text("Edit")),
                      if (!sem.isActive)
                        const PopupMenuItem(value: 'active', child: Text("Set as the main semester")),
                      const PopupMenuItem(value: 'delete', child: Text("Delete", style: TextStyle(color: Colors.red))),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') _showSemesterDialog(context, sem);
                      if (value == 'delete') _confirmDelete(context, sem.id);
                      if (value == 'active') _service.setActiveSemester(sem.id);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- Các hàm phụ trợ (Dialogs) ---

  void _showSemesterDialog(BuildContext context, SemesterModel? semester) {
    final nameCtrl = TextEditingController(text: semester?.name);
    DateTime start = semester?.startDate ?? DateTime.now();
    DateTime end = semester?.endDate ?? DateTime.now().add(const Duration(days: 120));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(semester == null ? "Add Semester" : "Edit Semester"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: "Semester Name (VD: HK1 2025)"),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            final date = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2030), initialDate: start);
                            if (date != null) setState(() => start = date);
                          },
                          child: Text("Start:\n${DateFormat('dd/MM/yyyy').format(start)}"),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            final date = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2030), initialDate: end);
                            if (date != null) setState(() => end = date);
                          },
                          child: Text("End:\n${DateFormat('dd/MM/yyyy').format(end)}"),
                        ),
                      ),
                    ],
                  )
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () async { // <--- THÊM ASYNC
                    if (nameCtrl.text.isEmpty) return;

                    final newSem = SemesterModel(
                      id: semester?.id ?? '',
                      name: nameCtrl.text.trim(),
                      startDate: start,
                      endDate: end,
                      isActive: semester?.isActive ?? false,
                    );

                    try {
                      if (semester == null) {
                        await _service.addSemester(newSem); // <--- AWAIT
                      } else {
                        await _service.updateSemester(newSem); // <--- AWAIT
                      }

                      // --- SỬA LỖI MOUNTED ---
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Save Successfully!")));

                    } catch (e) {
                      if (!context.mounted) return;
                      // Xóa chữ "Exception:" cho đẹp
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red)
                      );
                    }
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          }
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: const Text("Are you sure you want to delete this semester?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("No")),
          TextButton(
              onPressed: () {
                _service.deleteSemester(id);
                Navigator.pop(ctx);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }
}