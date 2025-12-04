import 'package:flutter/material.dart';
import '../../auth/data/auth_service.dart';
import '../data/chat_service.dart';
import '../data/message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  final String targetUserId;
  final String targetUserName;

  const ChatScreen({super.key, required this.targetUserId, required this.targetUserName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatService = ChatService();
  final _msgCtrl = TextEditingController();
  final _currentUserId = AuthService().currentUser!.uid; // MY ID
  String? _conversationId;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  void _initChat() async {
    // 1. Get info from Auth
    final currentUser = AuthService().currentUser;
    if (currentUser == null || currentUser.email == null) return;

    String myRealId = currentUser.uid; // Default is Auth UID

    // 2. "EMAIL BRIDGE": Find real ID in Firestore based on Email
    try {
      final userQuery = await FirebaseFirestore.instance
          .collection('users') // Or AppConstants.collUsers
          .where('email', isEqualTo: currentUser.email)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        // AHA! Found matching Firestore record with email!
        // Use this record's ID instead of Auth UID
        myRealId = userQuery.docs.first.id;
      } else {
      }
    } catch (e) {
    }

    // 3. Now create chat room ID using "myRealId"
    final id = await _chatService.getOrCreateConversationId(myRealId, widget.targetUserId);

    // --- DEBUG LOG ---
    if (mounted) setState(() => _conversationId = id);
  }

  void _send() {
    if (_msgCtrl.text.trim().isEmpty || _conversationId == null) return;

    final msg = MessageModel(
      id: '',
      senderId: _currentUserId,
      senderName: AuthService().currentUser!.displayName ?? "Me",
      content: _msgCtrl.text.trim(),
      sentAt: DateTime.now(),
    );

    _chatService.sendMessage(_conversationId!, msg);
    _msgCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chat with ${widget.targetUserName}")),
      body: Column(
        children: [
          Expanded(
            child: _conversationId == null
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<List<MessageModel>>(
              stream: _chatService.getMessages(_conversationId!),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final msgs = snapshot.data!;
                if (msgs.isEmpty) return const Center(child: Text("Start the conversation!"));

                return ListView.builder(
                  reverse: true, // New messages at bottom
                  itemCount: msgs.length,
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (context, index) {
                    final msg = msgs[index];
                    final isMe = msg.senderId == _currentUserId;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[600] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg.content,
                              style: TextStyle(color: isMe ? Colors.white : Colors.black, fontSize: 16),
                            ),
                            // Can add timestamp display if needed
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgCtrl,
              decoration: const InputDecoration(
                  hintText: "Type a message...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(30))),
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  filled: true,
                  fillColor: Colors.white
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.blue,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _send,
            ),
          )
        ],
      ),
    );
  }
}