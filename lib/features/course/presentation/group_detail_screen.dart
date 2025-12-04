import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/data/user_model.dart';
import '../data/enrollment_service.dart';
import '../../chat/presentation/chat_screen.dart'; // Import để chat nếu cần

class GroupDetailScreen extends StatefulWidget {
  final String courseId; // ID Môn học
  final String groupId;  // ID Nhóm
  final String groupName;

  const GroupDetailScreen({
    super.key,
    required this.courseId,
    required this.groupId,
    required this.groupName
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final EnrollmentService _service = EnrollmentService();

  void _confirmRemove(UserModel student) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Student"),
        content: Text("Are you sure you want to remove ${student.displayName} from this class?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          TextButton(
            onPressed: () async {
              await _service.removeStudent(widget.groupId, student.id);
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );
  }

  void _showAddStudentSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AddStudentSheet(courseId: widget.courseId, groupId: widget.groupId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStudentSheet,
        label: const Text("Add Student"),
        icon: const Icon(Icons.person_add),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.teal[50],
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.teal),
                const SizedBox(width: 10),
                const Expanded(child: Text("Official student list", style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Lấy danh sách Enrollment theo GroupID
              stream: FirebaseFirestore.instance
                  .collection(AppConstants.collEnrollments)
                  .where('groupId', isEqualTo: widget.groupId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text("This class has no students yet."));

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final enrollData = docs[index].data() as Map<String, dynamic>;
                    final userId = enrollData['userId'] as String;

                    // Dùng FutureBuilder để lấy thông tin chi tiết từng User
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection(AppConstants.collUsers).doc(userId).get(),
                      builder: (context, userSnap) {
                        if (userSnap.connectionState == ConnectionState.waiting) {
                          return const ListTile(title: Text("Loading...", style: TextStyle(color: Colors.grey)));
                        }

                        // --- CHECK DỮ LIỆU ĐỂ TRÁNH NULL ---
                        if (!userSnap.hasData || userSnap.data == null || !userSnap.data!.exists) {
                          // Trường hợp User đã bị xóa hoặc ID sai
                          return ListTile(
                            leading: const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.error)),
                            title: Text("User ID: $userId", style: const TextStyle(color: Colors.red)),
                            subtitle: const Text("The account does not exist."),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_forever, color: Colors.red),
                              onPressed: () => _service.removeStudent(widget.groupId, userId), // Cho phép xóa Enrollment rác
                            ),
                          );
                        }

                        final user = UserModel.fromFirestore(userSnap.data!);

                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(user.displayName != null && user.displayName!.isNotEmpty ? user.displayName![0] : "S"),
                          ),
                          title: Text(user.displayName ?? "No Name"),
                          subtitle: Text("${user.studentCode ?? '---'} | ${user.email}"),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                            onPressed: () => _confirmRemove(user),
                          ),
                        );
                      },
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

// --- SHEET TÌM KIẾM ---
class _AddStudentSheet extends StatefulWidget {
  final String courseId;
  final String groupId;
  const _AddStudentSheet({required this.courseId, required this.groupId});

  @override
  State<_AddStudentSheet> createState() => _AddStudentSheetState();
}

class _AddStudentSheetState extends State<_AddStudentSheet> {
  final _searchCtrl = TextEditingController();
  final _service = EnrollmentService();
  List<UserModel> _results = [];
  bool _isLoading = false;

  void _search() async {
    if (_searchCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      final res = await _service.searchStudentsToAdd(_searchCtrl.text.trim());
      if (mounted) setState(() => _results = res);
    } catch (e) {
      //
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _add(UserModel user) async {
    try {
      await _service.enrollStudent(widget.courseId, widget.groupId, user.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Added ${user.displayName} to class!")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
      child: SizedBox(
        height: 500,
        child: Column(
          children: [
            const Text("Find & Add Student", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: TextField(controller: _searchCtrl, decoration: const InputDecoration(hintText: "Nhập email sinh viên...", border: OutlineInputBorder()), onSubmitted: (_) => _search())),
                const SizedBox(width: 8),
                IconButton.filled(onPressed: _search, icon: const Icon(Icons.search)),
              ],
            ),
            const SizedBox(height: 10),
            if (_isLoading) const LinearProgressIndicator(),
            Expanded(
              child: _results.isEmpty
                  ? const Center(child: Text("Enter an email to search."))
                  : ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final u = _results[index];
                  return ListTile(
                    title: Text(u.displayName ?? "No Name"),
                    subtitle: Text(u.email),
                    trailing: ElevatedButton(onPressed: () => _add(u), child: const Text("Add")),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}