import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  final String id;
  final String courseId;
  final String authorName; // Tên giảng viên
  final String title;
  final String content;    // Nội dung thông báo
  final String? attachmentUrl;
  final List<String> targetGroupIds;
  final DateTime createdAt;
  final List<String> viewerIds; // Danh sách ID sinh viên đã xem
  final List<String> downloaderIds;
  final int commentCount;

  AnnouncementModel({
    required this.id,
    required this.courseId,
    required this.authorName,
    required this.title,
    required this.content,
    this.attachmentUrl,
    this.targetGroupIds = const [],
    required this.createdAt,
    this.viewerIds = const [],
    this.downloaderIds = const [],
    this.commentCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'authorName': authorName,
      'title': title,
      'content': content,
      'attachmentUrl': attachmentUrl,
      'targetGroupIds': targetGroupIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'viewerIds': viewerIds,
      'downloaderIds': downloaderIds,
      'commentCount': commentCount,
    };
  }

  factory AnnouncementModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AnnouncementModel(
      id: doc.id,
      courseId: data['courseId'] ?? '',
      authorName: data['authorName'] ?? 'Instructor',
      title: data['title'] ?? '(Không tiêu đề)',
      content: data['content'] ?? '',
      attachmentUrl: data['attachmentUrl'],
      targetGroupIds: List<String>.from(data['targetGroupIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      viewerIds: List<String>.from(data['viewerIds'] ?? []),
      downloaderIds: List<String>.from(data['downloaderIds'] ?? []),
      commentCount: data['commentCount'] ?? 0,
    );
  }
}