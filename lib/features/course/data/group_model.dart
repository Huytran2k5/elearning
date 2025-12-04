import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  final String semesterId;
  final String courseId;
  final String courseCode;
  final String courseName;
  final String name;        // <--- Tên nhóm (N01)
  final String teacherId;
  final String teacherName; // <--- Tên giảng viên
  final int studentCount;

  GroupModel({
    required this.id,
    required this.semesterId,
    required this.courseId,
    required this.courseCode,
    required this.courseName,
    required this.name,
    required this.teacherId,
    this.teacherName = 'Giảng viên', // Mặc định để tránh lỗi null
    this.studentCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'semesterId': semesterId,
      'courseId': courseId,
      'courseCode': courseCode,
      'courseName': courseName,
      'name': name,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'studentCount': studentCount,
    };
  }

  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return GroupModel(
      id: doc.id,
      semesterId: data['semesterId'] ?? '',
      courseId: data['courseId'] ?? '',
      courseCode: data['courseCode'] ?? '',
      courseName: data['courseName'] ?? '',
      name: data['name'] ?? '',
      teacherId: data['teacherId'] ?? '',
      teacherName: data['teacherName'] ?? 'Giảng viên',
      studentCount: data['studentCount'] ?? 0,
    );
  }
}