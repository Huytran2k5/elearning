import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:flutter/foundation.dart';

/// Service để detect connectivity và notify listeners
class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final ValueNotifier<bool> isOnline = ValueNotifier(true);

  /// Initialize network monitoring
  void init() {
    // Check initial status
    InternetConnection().hasInternetAccess.then((hasAccess) {
      isOnline.value = hasAccess;
      debugPrint(
          '🌐 Initial network status: ${isOnline.value ? "ONLINE" : "OFFLINE"}');
    });

    // Listen for changes
    InternetConnection().onStatusChange.listen((status) {
      final wasOnline = isOnline.value;
      isOnline.value = status == InternetStatus.connected;

      if (wasOnline != isOnline.value) {
        debugPrint(
            '🌐 Network changed: ${isOnline.value ? "ONLINE ✅" : "OFFLINE ⚠️"}');
      }
    });
  }

  /// Check network manually
  Future<bool> checkConnection() async {
    final hasAccess = await InternetConnection().hasInternetAccess;
    isOnline.value = hasAccess;
    return hasAccess;
  }
}
