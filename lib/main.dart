import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 1. Thêm import Provider
import 'theme_provider.dart'; // 2. Thêm import ThemeProvider
import 'splash.dart';
import 'login.dart';
import 'home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 3. Bọc app trong ChangeNotifierProvider để quản lý trạng thái Dark Mode
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 4. Lấy theme hiện tại từ ThemeProvider
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Mediapp',
      debugShowCheckedModeBanner: false,
      // 5. Sử dụng theme động (Sáng/Tối) thay vì ThemeData cố định
      theme: themeProvider.currentTheme,
      home: const Splash(),
    );
  }
}