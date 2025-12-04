import 'package:cloud_firestore/cloud_firestore.dart';

class AssignmentModel {
  final String id;
  final String courseId;
  final String title;
  final String description; // Thay cho instructions cũ
  final List<String> attachmentUrls; // Link đề bài/ảnh minh họa
  final List<String> targetGroupIds; // Phân quyền nhóm

  // --- Cấu hình Thời gian & Luật lệ ---
  final DateTime openAt;       // Ngày bắt đầu
  final DateTime dueAt;        // Hạn nộp chính thức
  final bool allowLate;
  final DateTime? lateDueAt;   // Hạn nộp trễ (nếu có)
  final int maxAttempts;       // Số lần nộp tối đa (vd: 3)
  final List<String> allowedFileTypes; // ['.pdf', '.zip']
  final int maxSizeMb;         // Giới hạn dung lượng

  AssignmentModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    this.attachmentUrls = const [],
    this.targetGroupIds = const [],
    required this.openAt,
    required this.dueAt,
    this.allowLate = false,
    this.lateDueAt,
    this.maxAttempts = 1,
    this.allowedFileTypes = const ['.pdf', '.zip'],
    this.maxSizeMb = 10,
  });

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'title': title,
      'description': description,
      'attachmentUrls': attachmentUrls,
      'targetGroupIds': targetGroupIds,
      'openAt': Timestamp.fromDate(openAt),
      'dueAt': Timestamp.fromDate(dueAt),
      'allowLate': allowLate,
      'lateDueAt': lateDueAt != null ? Timestamp.fromDate(lateDueAt!) : null,
      'maxAttempts': maxAttempts,
      'allowedFileTypes': allowedFileTypes,
      'maxSizeMb': maxSizeMb,
    };
  }

  factory AssignmentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Hàm phụ trợ để lấy ngày an toàn (nếu null thì lấy ngày hiện tại)
    DateTime safeDate(dynamic val, {int addDays = 0}) {
      if (val is Timestamp) return val.toDate();
      return DateTime.now().add(Duration(days: addDays));
    }

    return AssignmentModel(
      id: doc.id,
      courseId: data['courseId'] ?? '',
      title: data['title'] ?? '(Không tiêu đề)',
      description: data['description'] ?? '',
      attachmentUrls: List<String>.from(data['attachmentUrls'] ?? []),
      targetGroupIds: List<String>.from(data['targetGroupIds'] ?? []),

      // --- SỬA ĐOẠN NÀY ĐỂ TRÁNH LỖI NULL ---
      openAt: safeDate(data['openAt']),
      dueAt: safeDate(data['dueAt'], addDays: 7), // Mặc định hạn 7 ngày nếu thiếu
      lateDueAt: data['lateDueAt'] != null ? (data['lateDueAt'] as Timestamp).toDate() : null,
      // --------------------------------------

      allowLate: data['allowLate'] ?? false,
      maxAttempts: data['maxAttempts'] ?? 1,
      allowedFileTypes: List<String>.from(data['allowedFileTypes'] ?? ['.pdf']),
      maxSizeMb: data['maxSizeMb'] ?? 10,
    );
  }
}