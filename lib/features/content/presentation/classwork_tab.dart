import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Để hiện tracking
import '../../../core/constants/app_constants.dart';
import '../../auth/data/auth_service.dart';
import '../data/assignment_model.dart';
import '../data/material_model.dart';
import '../data/assignment_service.dart';
import '../data/content_service.dart';
import 'assignment_detail_screen.dart';
import 'create_assignment_screen.dart';
import 'create_material_screen.dart';

class ClassworkTab extends StatelessWidget {
  final String courseId;
  final String userRole;
  final bool isReadOnly;

  ClassworkTab({super.key, required this.courseId, required this.userRole, this.isReadOnly = false});

  final _assignmentService = AssignmentService();
  final _contentService = ContentService();
  final _currentUser = AuthService().currentUser!;

  bool get isInstructor => userRole == AppConstants.roleInstructor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Nút Thêm đa năng (Chỉ cho GV)
      floatingActionButton: isInstructor ? _buildFab(context) : null,

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- PHẦN 1: TÀI LIỆU ---
            _buildSectionTitle("Tài Liệu Học Tập", Icons.book),
            StreamBuilder<List<MaterialModel>>(
              stream: _contentService.getMaterials(courseId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();
                final materials = snapshot.data!;
                if (materials.isEmpty) return const Padding(padding: EdgeInsets.all(8.0), child: Text("Chưa có tài liệu."));

                return Column(
                  children: materials.map((m) => _buildMaterialCard(context, m)).toList(),
                );
              },
            ),

            const SizedBox(height: 24),

            // --- PHẦN 2: BÀI TẬP ---
            _buildSectionTitle("Bài Tập & Kiểm Tra", Icons.assignment),
            StreamBuilder<List<AssignmentModel>>(
              stream: _assignmentService.getAssignments(courseId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();
                final assignments = snapshot.data!;
                if (assignments.isEmpty) return const Padding(padding: EdgeInsets.all(8.0), child: Text("Chưa có bài tập."));

                return Column(
                  children: assignments.map((a) => _buildAssignmentCard(context, a)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Widget Thẻ Tài Liệu
  Widget _buildMaterialCard(BuildContext context, MaterialModel material) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.description, color: Colors.white)),
        title: Text(material.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Đăng ngày: ${DateFormat('dd/MM').format(material.createdAt)}"),
        onExpansionChanged: (isOpen) {
          // Tracking VIEW khi mở ra (chỉ SV)
          if (isOpen && !isInstructor && !material.viewerIds.contains(_currentUser.uid)) {
            _contentService.markMaterialAsViewed(material.id, _currentUser.uid);
          }
        },
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (material.description.isNotEmpty) ...[
                  Text(material.description),
                  const SizedBox(height: 10),
                ],
                // Danh sách Link
                ...material.fileUrls.map((url) => InkWell(
                  onTap: () {
                    // Tracking DOWNLOAD
                    if (!isInstructor) _contentService.markMaterialAsDownloaded(material.id, _currentUser.uid);
                    launchUrl(Uri.parse(url));
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.link, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(child: Text(url, style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline))),
                    ],
                  ),
                )),

                // Tracking Info (Cho GV)
                if (isInstructor) ...[
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(Icons.visibility, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text("${material.viewerIds.length} xem"),
                      const SizedBox(width: 16),
                      const Icon(Icons.download, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text("${material.downloaderIds.length} tải"),
                    ],
                  )
                ]
              ],
            ),
          )
        ],
      ),
    );
  }

  // Widget Thẻ Bài Tập (Code cũ, viết gọn lại)
  Widget _buildAssignmentCard(BuildContext context, AssignmentModel asm) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.assignment, color: Colors.white)),
        title: Text(asm.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Hạn: ${DateFormat('dd/MM HH:mm').format(asm.dueAt)}"),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AssignmentDetailScreen(
                assignment: asm,
                userRole: userRole,
                isReadOnly: isReadOnly, // <--- 3. TRUYỀN SANG MÀN HÌNH CHI TIẾT
              ))
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue[900]),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[900])),
        ],
      ),
    );
  }

  // Nút FAB đa năng (PopupMenu)
  Widget _buildFab(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'assignment') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => CreateAssignmentScreen(courseId: courseId)));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => CreateMaterialScreen(courseId: courseId)));
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'material',
          child: ListTile(leading: Icon(Icons.book), title: Text('Tài liệu mới')),
        ),
        const PopupMenuItem<String>(
          value: 'assignment',
          child: ListTile(leading: Icon(Icons.assignment), title: Text('Bài tập mới')),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.blue),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}