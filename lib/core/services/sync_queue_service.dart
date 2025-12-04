import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/content/data/assignment_service.dart';
import '../../features/content/data/submission_model.dart';
import '../../features/content/data/content_service.dart';
import '../../features/content/data/comment_model.dart';

/// Model for pending actions
class PendingAction {
  final String id;
  final String type; // 'submit_assignment', 'post_comment', etc.
  final Map<String, dynamic> data;
  final DateTime timestamp;

  PendingAction({
    required this.id,
    required this.type,
    required this.data,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'data': data,
        'timestamp': timestamp.toIso8601String(),
      };

  factory PendingAction.fromJson(Map<String, dynamic> json) => PendingAction(
        id: json['id'],
        type: json['type'],
        data: Map<String, dynamic>.from(json['data']),
        timestamp: DateTime.parse(json['timestamp']),
      );
}

/// Service to queue offline actions and sync when online
class SyncQueueService {
  static const String _queueKey = 'pending_actions_queue';

  // ==================== QUEUE MANAGEMENT ====================

  /// Add action to queue when offline
  Future<void> enqueue(String type, Map<String, dynamic> data) async {
    final action = PendingAction(
      id: const Uuid().v4(),
      type: type,
      data: data,
      timestamp: DateTime.now(),
    );

    final prefs = await SharedPreferences.getInstance();
    final queue = await _getQueue();
    queue.add(action);

    await prefs.setString(
        _queueKey, jsonEncode(queue.map((e) => e.toJson()).toList()));
    print('📥 Queued [$type] - ID: ${action.id}');
  }

  /// Get current queue
  Future<List<PendingAction>> _getQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_queueKey);
      if (data == null) return [];

      List<dynamic> list = jsonDecode(data);
      return list.map((e) => PendingAction.fromJson(e)).toList();
    } catch (e) {
      print('❌ Error reading queue: $e');
      return [];
    }
  }

  /// Get queue count (for UI display)
  Future<int> getQueueCount() async {
    final queue = await _getQueue();
    return queue.length;
  }

  /// Process all pending actions
  Future<void> processQueue() async {
    final queue = await _getQueue();
    if (queue.isEmpty) {
      print('✅ Queue is empty');
      return;
    }

    print('🔄 Processing ${queue.length} pending action(s)...');

    int successCount = 0;
    int failCount = 0;

    for (var action in queue) {
      try {
        await _executeAction(action);
        await _removeFromQueue(action.id);
        successCount++;
        print('✅ Synced [${action.type}] - ID: ${action.id}');
      } catch (e) {
        failCount++;
        print('❌ Failed [${action.type}] - ID: ${action.id} - Error: $e');

        // Remove action if older than 7 days (avoid infinite retry)
        if (DateTime.now().difference(action.timestamp).inDays > 7) {
          await _removeFromQueue(action.id);
          print('🗑️ Removed stale action: ${action.id}');
        }
      }
    }

    print('🎉 Sync completed: $successCount success, $failCount failed');
  }

  /// Execute a single action based on type
  Future<void> _executeAction(PendingAction action) async {
    switch (action.type) {
      case 'submit_assignment':
        await _syncSubmitAssignment(action.data);
        break;

      case 'post_comment':
        await _syncPostComment(action.data);
        break;

      case 'mark_viewed':
        await _syncMarkViewed(action.data);
        break;

      default:
        print('⚠️ Unknown action type: ${action.type}');
    }
  }

  /// Remove action from queue
  Future<void> _removeFromQueue(String actionId) async {
    final queue = await _getQueue();
    queue.removeWhere((a) => a.id == actionId);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _queueKey, jsonEncode(queue.map((e) => e.toJson()).toList()));
  }

  /// Clear entire queue
  Future<void> clearQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_queueKey);
    print('🗑️ Queue cleared');
  }

  // ==================== SYNC ACTIONS ====================

  /// Sync: Submit Assignment
  Future<void> _syncSubmitAssignment(Map<String, dynamic> data) async {
    final submission = SubmissionModel(
      id: '',
      assignmentId: data['assignmentId'],
      studentId: data['studentId'],
      studentName: data['studentName'],
      studentEmail: data['studentEmail'],
      groupId: data['groupId'],
      fileUrls: List<String>.from(data['fileUrls']),
      submittedAt: DateTime.parse(data['submittedAt']),
      isLate: data['isLate'],
      attemptNumber: data['attemptNumber'],
    );

    await AssignmentService().submitAssignment(submission);
  }

  /// Sync: Post Comment
  Future<void> _syncPostComment(Map<String, dynamic> data) async {
    final comment = CommentModel(
      id: '',
      announcementId: data['announcementId'],
      userId: data['userId'],
      userName: data['userName'],
      content: data['content'],
      createdAt: DateTime.parse(data['createdAt']),
    );

    await ContentService().addComment(comment);
  }

  /// Sync: Mark as Viewed
  Future<void> _syncMarkViewed(Map<String, dynamic> data) async {
    await FirebaseFirestore.instance
        .collection(data['collection'])
        .doc(data['documentId'])
        .update({
      'viewerIds': FieldValue.arrayUnion([data['userId']])
    });
  }
}
