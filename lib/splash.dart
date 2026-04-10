import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home.dart';
import 'login.dart';

import 'dart:async';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();

    // Sau 1.5 giây sẽ kiểm tra trạng thái đăng nhập
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _checkAuthAndNavigate();
      }
    });
  }

  // Hàm kiểm tra xem Thắng đã đăng nhập chưa
  void _checkAuthAndNavigate() {
    // Lấy thông tin user hiện tại từ Firebase
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Nếu đã đăng nhập (user khác null) -> Vào thẳng trang chủ
      // Thắng thay 'HomeScreen()' bằng tên Class trang chủ của bạn nhé
      print("Thắng đã đăng nhập: ${user.email}");
      Navigator.pushReplacement(
        context,

        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      // Nếu chưa đăng nhập -> Vào màn hình Login như cũ
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Login()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Màu nền của Splash
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Gengar giữ nguyên icon và vòng xoay chuyên nghiệp của Thắng
            Image.asset('assets/images/icon.png', width: 150),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              color: Color(0xFF0066FF), // Cho vòng xoay cùng màu xanh Mediapp
            ),
          ],
        ),
      ),
    );
  }
}
