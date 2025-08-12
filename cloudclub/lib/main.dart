import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'sign_in_page.dart';
import 'home_page.dart';
import 'upload_page.dart';
import 'profile_page.dart';
import 'files_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
