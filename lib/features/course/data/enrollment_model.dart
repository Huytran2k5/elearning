import 'package:cloud_firestore/cloud_firestore.dart';

class EnrollmentModel {
  final String id;
  final String userId;    // ID sinh viên
  final String courseId;  // ID môn học (để check trùng)
  final String groupId;   // ID nhóm cụ thể
  final DateTime joinedAt;

  EnrollmentModel({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.groupId,
    required this.joinedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'courseId': courseId,
      'groupId': groupId,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }

  factory EnrollmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EnrollmentModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      courseId: data['courseId'] ?? '',
      groupId: data['groupId'] ?? '',
      joinedAt: (data['joinedAt'] as Timestamp).toDate(),
    );
  }
}