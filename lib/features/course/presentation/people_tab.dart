import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/data/auth_service.dart';
import '../../auth/data/user_model.dart';
import '../../chat/presentation/chat_screen.dart';

class PeopleTab extends StatelessWidget {
  final String courseId; // Giữ lại courseId nếu cần dùng cho logic khác (vd: lấy info môn học)
  final String groupId;  // <--- THÊM BIẾN QUAN TRỌNG NÀY (Để lọc enrollment)
  final String userRole;

  PeopleTab({
    super.key,
    required this.courseId,
    required this.userRole,
    this.groupId = '', // Mặc định rỗng để tránh lỗi constructor cũ, nhưng phải truyền vào
  });

  final _currentUserId = AuthService().currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    // Nếu groupId rỗng, dùng tạm courseId (cho dữ liệu cũ), nhưng dữ liệu mới phải dùng groupId
    final targetId = groupId.isNotEmpty ? groupId : courseId;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Giảng Viên"),
          _buildInstructorTile(context),

          _buildSectionHeader("Sinh Viên"),
          _buildStudentList(context, targetId), // Truyền ID đúng
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(title, style: TextStyle(color: Colors.blue[900], fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildInstructorTile(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection(AppConstants.collUsers).where('role', isEqualTo: AppConstants.roleInstructor).limit(1).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const ListTile(title: Text("Đang tải..."));
        if (snapshot.data!.docs.isEmpty) return const ListTile(title: Text("Chưa có GV"));

        final instructor = UserModel.fromFirestore(snapshot.data!.docs.first);
        return ListTile(
          leading: CircleAvatar(backgroundColor: Colors.blue, child: Text(instructor.displayName?[0] ?? "G")),
          title: Text(instructor.displayName ?? "Giảng viên"),
          subtitle: Text(instructor.email),
          trailing: IconButton(
            icon: const Icon(Icons.message, color: Colors.blue),
            onPressed: () {
              if (userRole == AppConstants.roleInstructor) return;
              _openChat(context, instructor.id, instructor.displayName ?? "Giảng viên");
            },
          ),
        );
      },
    );
  }

  // SỬA QUERY Ở ĐÂY: Dùng groupId để lọc
  Widget _buildStudentList(BuildContext context, String filterId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.collEnrollments)
      // Ưu tiên lọc theo groupId (nếu enrollment mới lưu groupId), fallback sang courseId (nếu dữ liệu cũ)
      // Để đơn giản, ta giả định enrollment mới luôn có groupId.
      // Nhưng cẩn thận: trong `enrollment_service.dart`, ta đang lưu cả 2 field.
      // Nếu bạn muốn hiển thị sinh viên CỦA NHÓM NÀY, hãy lọc theo groupId.
          .where('groupId', isEqualTo: filterId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text("Lớp chưa có sinh viên."));

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_,__) => const Divider(),
          itemBuilder: (context, index) {
            final enrollData = docs[index].data() as Map<String, dynamic>;
            final studentId = enrollData['userId'];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection(AppConstants.collUsers).doc(studentId).get(),
              builder: (context, userSnap) {
                if (userSnap.connectionState == ConnectionState.waiting) return const SizedBox.shrink();

                if (!userSnap.hasData || userSnap.data == null || !userSnap.data!.exists) {
                  return const ListTile(title: Text("User không tồn tại", style: TextStyle(color: Colors.grey)));
                }

                final user = UserModel.fromFirestore(userSnap.data!);
                final bool isInstructor = userRole == AppConstants.roleInstructor;
                final bool isMe = user.id == _currentUserId;
                final bool canChat = isInstructor && !isMe;

                return ListTile(
                  leading: CircleAvatar(child: Text(user.displayName?[0] ?? "S")),
                  title: Text(user.displayName ?? "Student"),
                  subtitle: Text(user.email),
                  trailing: canChat
                      ? IconButton(
                    icon: const Icon(Icons.message, color: Colors.blue),
                    onPressed: () => _openChat(context, user.id, user.displayName ?? "Student"),
                  )
                      : null,
                );
              },
            );
          },
        );
      },
    );
  }

  void _openChat(BuildContext context, String targetId, String targetName) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(targetUserId: targetId, targetUserName: targetName)));
  }
}