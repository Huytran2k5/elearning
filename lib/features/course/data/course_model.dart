import 'package:cloud_firestore/cloud_firestore.dart';

class CourseModel {
  final String id;        // Firestore ID (Auto-gen)
  final String code;      // Mã môn (UNIQUE - VD: IT001). Sẽ check trùng.
  final String name;      // Tên môn (VD: Phát triển ứng dụng di động)
  final int credits;      // Số tín chỉ
  final String description;

  CourseModel({
    required this.id,
    required this.code,
    required this.name,
    required this.credits,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'code': code, // Logic Service sẽ đảm bảo code này không trùng trong collection courses
      'name': name,
      'credits': credits,
      'description': description,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory CourseModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CourseModel(
      id: doc.id,
      code: data['code'] ?? '',
      name: data['name'] ?? '',
      credits: data['credits'] ?? 0,
      description: data['description'] ?? '',
    );
  }
}