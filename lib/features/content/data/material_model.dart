import 'package:cloud_firestore/cloud_firestore.dart';

class MaterialModel {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final List<String> fileUrls; // Hỗ trợ nhiều link
  final DateTime createdAt;

  // Tracking
  final List<String> viewerIds;     // Ai đã xem (bấm vào chi tiết)
  final List<String> downloaderIds; // Ai đã bấm vào link

  MaterialModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    this.fileUrls = const [],
    required this.createdAt,
    this.viewerIds = const [],
    this.downloaderIds = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'title': title,
      'description': description,
      'fileUrls': fileUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'viewerIds': viewerIds,
      'downloaderIds': downloaderIds,
    };
  }

  factory MaterialModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MaterialModel(
      id: doc.id,
      courseId: data['courseId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      fileUrls: List<String>.from(data['fileUrls'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      viewerIds: List<String>.from(data['viewerIds'] ?? []),
      downloaderIds: List<String>.from(data['downloaderIds'] ?? []),
    );
  }
}