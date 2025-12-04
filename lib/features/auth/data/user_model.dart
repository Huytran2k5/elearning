import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';

class UserModel {
  final String id;
  final String email;
  final String role; // 'INSTRUCTOR' hoặc 'STUDENT'
  final String? displayName;
  final String? studentCode;
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    this.displayName,
    this.studentCode,
    this.avatarUrl,
  });

  // Map từ Firestore document sang Object
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      role: data['role'] ?? AppConstants.roleStudent,
      displayName: data['displayName'],
      studentCode: data['studentCode'],
      avatarUrl: data['avatarUrl'],
    );
  }

  // Map từ Object sang JSON để lưu lên Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'displayName': displayName,
      'studentCode': studentCode,
      'updatedAt': FieldValue.serverTimestamp(),
      'avatarUrl': avatarUrl,
    };
  }

  // Kiểm tra xem có phải Admin/Giảng viên không
  bool get isInstructor => role == AppConstants.roleInstructor;

  UserModel copyWith({
    String? email,
    String? role,
    String? displayName,
    String? studentCode,
    String? avatarUrl,
  }) {
    return UserModel(
      id: this.id, // Giữ nguyên ID cũ
      email: email ?? this.email,
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
      studentCode: studentCode ?? this.studentCode,
      avatarUrl: avatarUrl ?? this.avatarUrl, // Cập nhật cái mới nếu có
    );
  }
}