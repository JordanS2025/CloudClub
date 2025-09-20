import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'sign_in_page.dart';
import 'home_page.dart';
import 'upload_page.dart';
import 'profile_page.dart';
import 'files_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization error: $e');
    print('Error details: ${e.toString()}');
    // Don't continue without Firebase - this will cause auth errors
    rethrow;
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CloudClub',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AuthPage(),
      routes: {
        '/home': (context) => const HomePage(),
        '/upload': (context) => const UploadPage(),
        '/profile': (context) => const ProfilePage(),
        '/files': (context) => const FilesPage(),
      },
    );
  }
}
