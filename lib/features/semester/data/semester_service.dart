import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import 'semester_model.dart';

class SemesterService {
  final CollectionReference _semRef = FirebaseFirestore.instance.collection(AppConstants.collSemesters);

  // 1. Lấy danh sách Real-time (Stream)
  // Sắp xếp ngày bắt đầu giảm dần (Mới nhất lên đầu)
  Stream<List<SemesterModel>> getSemestersStream() {
    return _semRef
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => SemesterModel.fromFirestore(doc)).toList()
    );
  }

  // Thêm học kỳ mới (CÓ CHECK TRÙNG TÊN)
  Future<void> addSemester(SemesterModel semester) async {
    final check = await _semRef
        .where('name', isEqualTo: semester.name.trim())
        .get();

    if (check.docs.isNotEmpty) {
      throw Exception("Học kỳ '${semester.name}' đã tồn tại!");
    }

    await _semRef.add(semester.toMap());
  }

  // 3. Cập nhật học kỳ
  Future<void> updateSemester(SemesterModel semester) async {
    await _semRef.doc(semester.id).update(semester.toMap());
  }

  // 4. Xóa học kỳ
  Future<void> deleteSemester(String id) async {
    await _semRef.doc(id).delete();
  }

  // 5. Đặt làm Học kỳ chính (Active)
  Future<void> setActiveSemester(String id) async {
    // Lấy tất cả học kỳ đang active
    var activeSnapshots = await _semRef.where('isActive', isEqualTo: true).get();

    WriteBatch batch = FirebaseFirestore.instance.batch();

    // Tắt active của các học kỳ cũ
    for (var doc in activeSnapshots.docs) {
      batch.update(doc.reference, {'isActive': false});
    }

    // Bật active cho học kỳ được chọn
    batch.update(_semRef.doc(id), {'isActive': true});

    await batch.commit();
  }
}