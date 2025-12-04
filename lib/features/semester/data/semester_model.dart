import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class SemesterModel extends Equatable {
  final String id;
  final String name; // Ví dụ: Fall 2025
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive; // Học kỳ hiện tại hay không

  SemesterModel({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.isActive = false,
  });

  // Map từ Firestore -> Object
  factory SemesterModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return SemesterModel(
      id: doc.id,
      name: data['name'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? false,
    );
  }

  // Map từ Object -> JSON để lưu
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isActive': isActive,
    };
  }

  // CopyWith để hỗ trợ chỉnh sửa object dễ dàng
  SemesterModel copyWith({String? name, DateTime? startDate, DateTime? endDate, bool? isActive}) {
    return SemesterModel(
      id: id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
    );
  }

  // 3. Ghi đè props để so sánh theo ID
  @override
  List<Object?> get props => [id];
}