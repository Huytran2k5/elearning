import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service để cache critical data locally
class CacheService {
  // Cache keys
  static const String _keyUserProfile = 'user_profile';
  static const String _keyEnrollments = 'enrollments';
  static const String _keyActiveSemester = 'active_semester';
  static const String _keyCourseGroups = 'course_groups';

  // ==================== USER PROFILE ====================

  /// Cache user profile data
  Future<void> cacheUserProfile(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserProfile, jsonEncode(userData));
      print('💾 User profile cached');
    } catch (e) {
      print('❌ Error caching user profile: $e');
    }
  }

  /// Get cached user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_keyUserProfile);
      if (data == null) return null;

      print('📦 User profile loaded from cache');
      return jsonDecode(data);
    } catch (e) {
      print('❌ Error reading cached profile: $e');
      return null;
    }
  }

  // ==================== ENROLLMENTS ====================

  /// Cache list of enrolled courses
  Future<void> cacheEnrollments(List<Map<String, dynamic>> courses) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyEnrollments, jsonEncode(courses));
      print('💾 Enrollments cached (${courses.length} courses)');
    } catch (e) {
      print('❌ Error caching enrollments: $e');
    }
  }

  /// Get cached enrollments
  Future<List<Map<String, dynamic>>> getEnrollments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_keyEnrollments);
      if (data == null) return [];

      final List<dynamic> list = jsonDecode(data);
      print('📦 Enrollments loaded from cache (${list.length} courses)');
      return list.cast<Map<String, dynamic>>();
    } catch (e) {
      print('❌ Error reading cached enrollments: $e');
      return [];
    }
  }

  // ==================== ACTIVE SEMESTER ====================

  /// Cache active semester info
  Future<void> cacheActiveSemester(Map<String, dynamic> semester) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyActiveSemester, jsonEncode(semester));
      print('💾 Active semester cached');
    } catch (e) {
      print('❌ Error caching semester: $e');
    }
  }

  /// Get cached active semester
  Future<Map<String, dynamic>?> getActiveSemester() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_keyActiveSemester);
      if (data == null) return null;

      print('📦 Active semester loaded from cache');
      return jsonDecode(data);
    } catch (e) {
      print('❌ Error reading cached semester: $e');
      return null;
    }
  }

  // ==================== ANNOUNCEMENTS ====================

  /// Cache recent announcements for a course
  Future<void> cacheAnnouncements(
      String courseId, List<Map<String, dynamic>> announcements) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'announcements_$courseId', jsonEncode(announcements));
      print('💾 Announcements cached for course $courseId');
    } catch (e) {
      print('❌ Error caching announcements: $e');
    }
  }

  /// Get cached announcements
  Future<List<Map<String, dynamic>>> getAnnouncements(String courseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('announcements_$courseId');
      if (data == null) return [];

      final List<dynamic> list = jsonDecode(data);
      print('📦 Announcements loaded from cache for course $courseId');
      return list.cast<Map<String, dynamic>>();
    } catch (e) {
      print('❌ Error reading cached announcements: $e');
      return [];
    }
  }

  // ==================== COURSE GROUPS ====================

  /// Cache groups for a course
  Future<void> cacheCourseGroups(
      String courseId, List<Map<String, dynamic>> groups) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_keyCourseGroups$courseId', jsonEncode(groups));
      print('💾 Groups cached for course $courseId');
    } catch (e) {
      print('❌ Error caching groups: $e');
    }
  }

  /// Get cached groups
  Future<List<Map<String, dynamic>>> getCourseGroups(String courseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('$_keyCourseGroups$courseId');
      if (data == null) return [];

      final List<dynamic> list = jsonDecode(data);
      print('📦 Groups loaded from cache for course $courseId');
      return list.cast<Map<String, dynamic>>();
    } catch (e) {
      print('❌ Error reading cached groups: $e');
      return [];
    }
  }

  // ==================== CLEAR CACHE ====================

  /// Clear all cached data
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('🗑️ All cache cleared');
    } catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }

  /// Clear specific cache
  Future<void> clearCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      print('🗑️ Cache cleared: $key');
    } catch (e) {
      print('❌ Error clearing cache $key: $e');
    }
  }
}
