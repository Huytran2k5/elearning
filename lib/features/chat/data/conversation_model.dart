import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  final String id;
  final List<String> participantIds; // [AdminID, StudentID]
  final String lastMessage;
  final DateTime updatedAt;

  ConversationModel({
    required this.id,
    required this.participantIds,
    required this.lastMessage,
    required this.updatedAt,
  });

  factory ConversationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ConversationModel(
      id: doc.id,
      participantIds: List<String>.from(data['participantIds'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
}