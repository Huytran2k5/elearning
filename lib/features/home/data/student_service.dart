import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../course/data/group_model.dart'; // <--- Dùng GroupModel

class StudentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Lấy danh sách LỚP HỌC (Group) mà sinh viên đã đăng ký
  Future<List<GroupModel>> getEnrolledGroups(String studentId) async {
    // 1. Lấy Enrollment
    final enrollQuery = await _db.collection(AppConstants.collEnrollments)
        .where('userId', isEqualTo: studentId)
        .get();

    if (enrollQuery.docs.isEmpty) return [];

    // 2. Lấy Group ID
    final groupIds = enrollQuery.docs.map((doc) => doc['groupId'] as String).toList();

    if (groupIds.isEmpty) return [];

    // 3. Lấy thông tin Group (Chia batch nếu > 10)
    final groupQuery = await _db.collection('groups') // Tên collection mới
        .where(FieldPath.documentId, whereIn: groupIds.take(10).toList())
        .get();

    return groupQuery.docs.map((doc) => GroupModel.fromFirestore(doc)).toList();
  }
}