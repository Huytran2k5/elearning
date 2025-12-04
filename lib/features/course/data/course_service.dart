import 'package:cloud_firestore/cloud_firestore.dart';
import 'course_model.dart';

class CourseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _coll = 'courses'; // Collection lưu danh mục môn học

  // 1. Lấy tất cả môn học (Sắp xếp theo mã)
  Stream<List<CourseModel>> getAllCourses() {
    return _db.collection(_coll)
        .orderBy('code')
        .snapshots()
        .map((snap) => snap.docs.map((d) => CourseModel.fromFirestore(d)).toList());
  }

  // Thêm Môn học (CÓ CHECK TRÙNG MÃ)
  Future<void> addCourse(CourseModel course) async {
    // 1. Kiểm tra mã tồn tại chưa (Chuẩn hóa chữ hoa)
    final check = await _db.collection(_coll)
        .where('code', isEqualTo: course.code.trim().toUpperCase())
        .get();

    if (check.docs.isNotEmpty) {
      // Ném ra lỗi để UI bắt lấy
      throw Exception("Mã môn học '${course.code}' đã tồn tại! Vui lòng kiểm tra lại.");
    }

    // 2. Nếu chưa có thì thêm
    await _db.collection(_coll).add(course.toMap());
  }

  // 3. Xóa môn học
  Future<void> deleteCourse(String id) async {
    // Cảnh báo: Nếu xóa môn học, các Group thuộc môn này sẽ bị lỗi tham chiếu.
    // Thực tế nên check xem có Group nào dùng courseId này không trước khi xóa.
    await _db.collection(_coll).doc(id).delete();
  }
}