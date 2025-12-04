import 'package:cloud_firestore/cloud_firestore.dart';
import 'message_model.dart'; // Make sure you have this model

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. CREATE CHAT ROOM ID (MOST IMPORTANT)
  // Logic: Always sort IDs in A-Z order.
  // Example: UserA and UserB always create room "UserA_UserB", regardless of who calls first.
  Future<String> getOrCreateConversationId(String currentUserId, String targetUserId) async {
    List<String> ids = [currentUserId, targetUserId];
    ids.sort(); // <--- KEY TO THE SOLUTION
    String conversationId = "${ids[0]}_${ids[1]}";

    // Create doc if it doesn't exist (to save general info)
    final docRef = _db.collection('conversations').doc(conversationId);
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        'participantIds': ids,
        'lastMessage': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    return conversationId;
  }

  // 2. Send message
  Future<void> sendMessage(String conversationId, MessageModel message) async {
    // Save message to sub-collection
    await _db.collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add(message.toMap());

    // Update last message outside
    await _db.collection('conversations').doc(conversationId).update({
      'lastMessage': message.content,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // 3. Get messages (Real-time)
  Stream<List<MessageModel>> getMessages(String conversationId) {
    return _db.collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('sentAt', descending: true) // Newest messages at bottom (for reverse ListView)
        .snapshots()
        .map((snap) => snap.docs.map((d) => MessageModel.fromFirestore(d)).toList());
  }
}