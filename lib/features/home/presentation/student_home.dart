import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/data/auth_service.dart';
import '../../auth/data/user_model.dart';
import '../../auth/presentation/login_screen.dart';
import '../../course/data/course_model.dart';
import '../data/student_service.dart';
import '../../course/presentation/course_detail_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../course/data/group_model.dart';

class StudentHome extends StatelessWidget {
  final UserModel user;
  final bool isEmbedded; // <-- THAM SỐ MỚI

  // Mặc định false (nếu dùng lẻ)
  const StudentHome({super.key, required this.user, this.isEmbedded = false});

  void _handleLogout(BuildContext context) async {
    await AuthService().signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentService = StudentService();

    return Scaffold(
      // Nếu được nhúng vào Dashboard (Tab 2) thì ẨN AppBar đi cho đỡ trùng
      appBar: isEmbedded ? null : AppBar(
        title: const Text("My Courses"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user.id).snapshots(),
              builder: (context, snapshot) {
                UserModel displayUser = user;
                if (snapshot.hasData && snapshot.data!.exists) {
                  displayUser = UserModel.fromFirestore(snapshot.data!);
                }
                return InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(user: displayUser))),
                  child: UserAvatar(avatarUrl: displayUser.avatarUrl, userName: displayUser.displayName, radius: 18, backgroundColor: Colors.white24),
                );
              }
          ),
          IconButton(onPressed: () => _handleLogout(context), icon: const Icon(Icons.logout)),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: FutureBuilder<List<GroupModel>>(
        future: studentService.getEnrolledGroups(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final groups = snapshot.data ?? [];

          if (groups.isEmpty) {
            return const Center(child: Text("Bạn chưa đăng ký khóa học nào."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              return _buildGroupCard(context, groups[index]); // Gọi hàm vẽ thẻ Group
            },
          );
        },
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, GroupModel group) {
    final cardColor = Colors.primaries[group.courseCode.hashCode % Colors.primaries.length];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // QUAN TRỌNG: Truyền GroupModel vào CourseDetailScreen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CourseDetailScreen(group: group, userRole: user.role)),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 90,
              width: double.infinity,
              decoration: BoxDecoration(color: cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
              padding: const EdgeInsets.all(16),
              alignment: Alignment.bottomLeft,
              child: Text(
                  "${group.courseCode} - ${group.name}", // Hiện Mã môn + Tên nhóm
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.courseName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), // Tên môn học
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(group.teacherName, style: const TextStyle(fontWeight: FontWeight.w500)), // Tên GV
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}