import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../course/data/group_model.dart'; // Import để lấy danh sách nhóm
import 'announcement_model.dart';
import 'comment_model.dart';
import 'material_model.dart';

class ContentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Lấy thông báo (Đã nâng cấp logic lọc)
  Stream<List<AnnouncementModel>> getAnnouncements(String courseId, String? studentGroupId, bool isInstructor) {
    return _db.collection(AppConstants.collAnnouncements)
        .where('courseId', isEqualTo: courseId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      final allPosts = snap.docs.map((d) => AnnouncementModel.fromFirestore(d)).toList();

      if (isInstructor) return allPosts; // Giảng viên thấy hết

      // Sinh viên: Chỉ thấy bài cho "Tất cả" HOẶC bài dành riêng cho nhóm mình
      return allPosts.where((post) {
        if (post.targetGroupIds.isEmpty) return true; // Dành cho tất cả
        if (studentGroupId != null && post.targetGroupIds.contains(studentGroupId)) return true;
        return false;
      }).toList();
    });
  }

  // 2. Lấy danh sách nhóm của khóa học (Để GV chọn khi đăng bài)
  Future<List<GroupModel>> getCourseGroups(String courseId) async {
    final snap = await _db.collection(AppConstants.collGroups).where('courseId', isEqualTo: courseId).get();
    return snap.docs.map((d) => GroupModel.fromFirestore(d)).toList();
  }

  // 3. Đăng thông báo
  Future<void> createAnnouncement(AnnouncementModel announcement) async {
    await _db.collection(AppConstants.collAnnouncements).add(announcement.toMap());
  }

  // 4. Tracking xem (Giữ nguyên)
  Future<void> markAsViewed(String announcementId, String studentId) async {
    await _db.collection(AppConstants.collAnnouncements).doc(announcementId).update({
      'viewerIds': FieldValue.arrayUnion([studentId])
    });
  }

  // --- LOGIC BÌNH LUẬN (MỚI) ---

  // 5. Gửi bình luận
  Future<void> addComment(CommentModel comment) async {
    // Thêm comment vào sub-collection (để gọn database)
    await _db.collection(AppConstants.collAnnouncements)
        .doc(comment.announcementId)
        .collection('comments')
        .add(comment.toMap());

    // Tăng biến đếm comment ở bài gốc (để hiển thị UI)
    await _db.collection(AppConstants.collAnnouncements)
        .doc(comment.announcementId)
        .update({'commentCount': FieldValue.increment(1)});
  }

  // 6. Lấy danh sách bình luận
  Stream<List<CommentModel>> getComments(String announcementId) {
    return _db.collection(AppConstants.collAnnouncements)
        .doc(announcementId)
        .collection('comments')
        .orderBy('createdAt', descending: false) // Cũ nhất lên đầu
        .snapshots()
        .map((snap) => snap.docs.map((d) => CommentModel.fromFirestore(d)).toList());
  }

  // --- MATERIAL (TÀI LIỆU) ---

  // 1. Lấy danh sách tài liệu
  Stream<List<MaterialModel>> getMaterials(String courseId) {
    return _db.collection(AppConstants.collMaterials)
        .where('courseId', isEqualTo: courseId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => MaterialModel.fromFirestore(d)).toList());
  }

  // 2. Tạo tài liệu mới
  Future<void> createMaterial(MaterialModel material) async {
    await _db.collection(AppConstants.collMaterials).add(material.toMap());
  }

  // 3. Tracking Xem Tài liệu
  Future<void> markMaterialAsViewed(String materialId, String studentId) async {
    await _db.collection(AppConstants.collMaterials).doc(materialId).update({
      'viewerIds': FieldValue.arrayUnion([studentId])
    });
  }

  // 4. Tracking Tải Tài liệu
  Future<void> markMaterialAsDownloaded(String materialId, String studentId) async {
    await _db.collection(AppConstants.collMaterials).doc(materialId).update({
      'downloaderIds': FieldValue.arrayUnion([studentId])
    });
  }

  Future<void> markAsDownloaded(String announcementId, String studentId) async {
    await _db.collection(AppConstants.collAnnouncements).doc(announcementId).update({
      'downloaderIds': FieldValue.arrayUnion([studentId])
    });
  }
}