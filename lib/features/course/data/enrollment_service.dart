import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/data/user_model.dart';
// import 'enrollment_model.dart'; // (Có thể bỏ nếu không dùng trực tiếp class này, nhưng cứ giữ nếu cần)

class EnrollmentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Lấy danh sách sinh viên trong 1 nhóm
  // (Lấy Enrollment trước -> Lấy User Info sau)
  Stream<List<UserModel>> getStudentsInGroup(String groupId) {
    return _db.collection(AppConstants.collEnrollments)
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .asyncMap((snapshot) async {
      List<UserModel> students = [];
      for (var doc in snapshot.docs) {
        String userId = doc['userId'];
        // Fetch user info
        var userDoc = await _db.collection(AppConstants.collUsers).doc(userId).get();
        if (userDoc.exists) {
          students.add(UserModel.fromFirestore(userDoc));
        }
      }
      return students;
    });
  }

  // 2. Thêm sinh viên vào nhóm (Dùng BATCH thay vì Transaction để fix lỗi Windows)
  Future<void> enrollStudent(String courseId, String groupId, String userId) async {
    // Bước A: Check xem sinh viên đã ở trong nhóm nào của môn này chưa
    // (Bước Read này làm độc lập bên ngoài Batch)
    final existingQuery = await _db.collection(AppConstants.collEnrollments)
        .where('courseId', isEqualTo: courseId)
        .where('userId', isEqualTo: userId)
        .get();

    if (existingQuery.docs.isNotEmpty) {
      throw Exception("Sinh viên này đã thuộc một nhóm khác trong môn học này rồi!");
    }

    // Bước B: Dùng WriteBatch để thực hiện ghi dữ liệu an toàn
    WriteBatch batch = _db.batch();

    // 1. Tạo Enrollment mới
    DocumentReference enrollRef = _db.collection(AppConstants.collEnrollments).doc();
    batch.set(enrollRef, {
      'userId': userId,
      'courseId': courseId,
      'groupId': groupId,
      'joinedAt': FieldValue.serverTimestamp(),
    });

    // 2. Tăng biến đếm trong Group
    DocumentReference groupRef = _db.collection(AppConstants.collGroups).doc(groupId);
    batch.update(groupRef, {
      'studentCount': FieldValue.increment(1)
    });

    // 3. Cam kết thực hiện cả 2 hành động cùng lúc
    await batch.commit();
  }

  // 3. Xóa sinh viên khỏi nhóm (Dùng BATCH)
  Future<void> removeStudent(String groupId, String userId) async {
    // Tìm doc enrollment để xóa
    final query = await _db.collection(AppConstants.collEnrollments)
        .where('groupId', isEqualTo: groupId)
        .where('userId', isEqualTo: userId)
        .get();

    if (query.docs.isEmpty) return;

    WriteBatch batch = _db.batch();

    // 1. Xóa enrollment
    batch.delete(query.docs.first.reference);

    // 2. Giảm biến đếm
    DocumentReference groupRef = _db.collection(AppConstants.collGroups).doc(groupId);
    batch.update(groupRef, {
      'studentCount': FieldValue.increment(-1)
    });

    // 3. Cam kết
    await batch.commit();
  }

  // 4. Tìm kiếm sinh viên để thêm (Loại trừ những người đã trong nhóm)
  Future<List<UserModel>> searchStudentsToAdd(String query) async {
    // Thực tế nên dùng Algolia/ElasticSearch, nhưng ở đây ta query simple
    // Lấy 20 sinh viên phù hợp
    final snapshot = await _db.collection(AppConstants.collUsers)
        .where('role', isEqualTo: AppConstants.roleStudent)
        .where('email', isGreaterThanOrEqualTo: query)
        .where('email', isLessThan: '${query}z')
        .limit(20)
        .get();

    return snapshot.docs.map((d) => UserModel.fromFirestore(d)).toList();
  }
}