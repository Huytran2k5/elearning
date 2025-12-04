import 'package:cloud_firestore/cloud_firestore.dart';
import 'group_model.dart';

class GroupService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _coll = 'groups';

  // 1. Lấy danh sách
  Stream<List<GroupModel>> getGroupsBySemester(String semesterId) {
    return _db.collection(_coll)
        .where('semesterId', isEqualTo: semesterId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => GroupModel.fromFirestore(d)).toList());
  }

  // Tạo Nhóm Mới (CÓ CHECK TRÙNG)
  Future<void> createGroup(GroupModel group) async {
    // 1. Kiểm tra trùng lặp: Cùng Học kỳ + Cùng Môn + Cùng Tên nhóm
    final duplicateCheck = await _db.collection(_coll)
        .where('semesterId', isEqualTo: group.semesterId)
        .where('courseId', isEqualTo: group.courseId)
        .where('name', isEqualTo: group.name.trim()) // Tên nhóm (VD: N01)
        .get();

    if (duplicateCheck.docs.isNotEmpty) {
      throw Exception("Nhóm '${group.name}' đã tồn tại cho môn này trong học kỳ hiện tại!");
    }

    // 2. Thêm mới
    await _db.collection(_coll).add(group.toMap());
  }

  // 3. Xóa
  Future<void> deleteGroup(String groupId) async {
    await _db.collection(_coll).doc(groupId).delete();
  }
}