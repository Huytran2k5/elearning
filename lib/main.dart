import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'features/auth/presentation/login_screen.dart';
import 'core/services/network_service.dart';
import 'core/services/sync_queue_service.dart';

// Global variable to manage Theme (Light/Dark)
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🔥 Enable Firestore Offline Persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // 🌐 Initialize Network Service
  final networkService = NetworkService();
  networkService.init();

  // 🔄 Auto-sync when back online
  networkService.isOnline.addListener(() {
    if (networkService.isOnline.value) {
      print('🌐 Back online! Syncing pending actions...');
      SyncQueueService().processQueue();
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
          title: 'IT E-Learning',
          debugShowCheckedModeBanner: false,

          // Light Theme
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue[900]!),
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: AppBarTheme(
                backgroundColor: Colors.blue[900],
                foregroundColor: Colors.white),
          ),

          // Dark Theme
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue[900]!, brightness: Brightness.dark),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF1F1F1F),
                foregroundColor: Colors.white),
          ),

          themeMode: mode,
          home: const LoginScreen(),
        );
      },
    );
  }
}
