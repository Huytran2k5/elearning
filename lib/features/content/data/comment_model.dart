import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String announcementId;
  final String userId;
  final String userName;
  final String content;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.announcementId,
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'announcementId': announcementId,
      'userId': userId,
      'userName': userName,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      announcementId: data['announcementId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'User',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}