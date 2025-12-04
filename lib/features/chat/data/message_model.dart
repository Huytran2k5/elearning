import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime sentAt;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.sentAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'sentAt': Timestamp.fromDate(sentAt),
    };
  }

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      content: data['content'] ?? '',
      sentAt: (data['sentAt'] as Timestamp).toDate(),
    );
  }
}