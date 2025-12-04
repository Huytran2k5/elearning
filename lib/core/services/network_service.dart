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
    });

    // Listen for changes
    InternetConnection().onStatusChange.listen((status) {
      isOnline.value = status == InternetStatus.connected;
    });
  }

  /// Check network manually
  Future<bool> checkConnection() async {
    final hasAccess = await InternetConnection().hasInternetAccess;
    isOnline.value = hasAccess;
    return hasAccess;
  }
}
