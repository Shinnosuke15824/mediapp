import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 1. Thêm import này

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  // 2. Hàm khởi tạo (Constructor) để tự động tải lại theme khi app vừa mở
  ThemeProvider() {
    _loadTheme();
  }

  // Hàm tải dữ liệu từ bộ nhớ máy
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners(); // Cập nhật giao diện ngay khi lấy được dữ liệu
  }

  // 3. Cập nhật hàm toggleTheme để lưu trạng thái vào máy
  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode); // Lưu lại lựa chọn
    notifyListeners(); // Thông báo cho toàn app cập nhật giao diện
  }

  ThemeData get currentTheme {
    return _isDarkMode ? darkTheme : lightTheme;
  }

  // Cấu hình Màu Sáng
  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: Colors.blue),
  );

  // Cấu hình Màu Tối
  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1E1E1E), foregroundColor: Colors.white),
    cardTheme: const CardThemeData(color: Color(0xFF1E1E1E)),
  );
}