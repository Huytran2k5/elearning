import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';

class ProfileService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Cập nhật Avatar URL
  Future<void> updateAvatar(String userId, String newAvatarUrl) async {
    await _db.collection(AppConstants.collUsers).doc(userId).update({
      'avatarUrl': newAvatarUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}