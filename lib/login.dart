import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 1. Thêm import này
import 'package:google_sign_in/google_sign_in.dart'; // Thêm import Google
import 'home.dart';

class Login extends StatefulWidget {
  Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> with SingleTickerProviderStateMixin {
  // Thêm Ticker cho hiệu ứng
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(); // Khởi tạo GoogleSignIn

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool isLogin = true;
  bool isLoading = false;
  bool _rememberMe = false;

  // --- PHẦN THÊM MỚI: QUẢN LÝ MÀN HÌNH CHÀO (SPLASH) ---
  bool _showSplash = true; // Biến kiểm soát hiển thị splash
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials(); // Lấy dữ liệu đã lưu khi mở trang

    // Hiệu ứng Fade In cho nội dung Login
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _opacity = 1.0);
    });

    // Sau 2.5 giây sẽ tắt màn hình Splash có màu sắc đi
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  // HÀM LẤY DỮ LIỆU ĐÃ LƯU
  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('remember_me') ?? false;
      if (_rememberMe) {
        _emailController.text = prefs.getString('saved_email') ?? '';
        _passwordController.text = prefs.getString('saved_password') ?? '';
      }
    });
  }

  // HÀM LƯU HOẶC XÓA DỮ LIỆU
  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setBool('remember_me', true);
      await prefs.setString('saved_email', _emailController.text.trim());
      await prefs.setString('saved_password', _passwordController.text.trim());
    } else {
      await prefs.remove('remember_me');
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
    }
  }

  // HÀM XỬ LÝ AUTH - ĐÃ TỐI ƯU CHUYỂN TRANG
  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar("Vui lòng nhập email và mật khẩu!", Colors.orange);
      return;
    }

    // Kiểm tra định dạng Email
    bool emailValid = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(email);

    if (!emailValid) {
      _showSnackBar("Email không đúng định dạng!", Colors.redAccent);
      return;
    }

    if (!isLogin && password != confirmPass) {
      _showSnackBar("Mật khẩu xác nhận không khớp!", Colors.redAccent);
      return;
    }

    setState(() => isLoading = true);

    try {
      if (isLogin) {
        // --- LOGIC ĐĂNG NHẬP ---
        print("Đang kết nối Firebase...");
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (userCredential.user != null) {
          await _saveCredentials(); // Lưu thông tin nếu đăng nhập thành công

          print("Đăng nhập thành công! Đang chuyển trang...");
          _showSnackBar("Chào mừng bạn đã quay trở lại!", Colors.green);

          if (mounted) {
            // Dùng pushAndRemoveUntil để dọn dẹp các trang cũ cho nhẹ app
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
          }
        }
      } else {
        // --- LOGIC ĐĂNG KÝ ---
        await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (mounted) {
          _showSnackBar("Đăng ký thành công! Mời bạn đăng nhập", Colors.green);
          _emailController.clear();
          _passwordController.clear();
          _confirmPasswordController.clear();
          setState(() => isLogin = true);
        }
      }
    } on FirebaseAuthException catch (e) {
      print("Lỗi Firebase: ${e.code}");
      String message = "Đã có lỗi xảy ra";
      if (e.code == 'user-not-found' || e.code == 'invalid-credential')
        message = "Email hoặc mật khẩu không đúng Thắng ơi!";
      else if (e.code == 'wrong-password')
        message = "Sai mật khẩu rồi kìa!";
      else if (e.code == 'email-already-in-use')
        message = "Email này có người dùng rồi!";
      else if (e.code == 'weak-password')
        message = "Mật khẩu quá yếu (cần > 6 ký tự)!";

      _showSnackBar(message, Colors.red);
    } catch (e) {
      _showSnackBar("Lỗi hệ thống: ${e.toString()}", Colors.red);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // CÁC HÀM KHÁC GIỮ NGUYÊN
  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar("Vui lòng nhập email của bạn!", Colors.orange);
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _showSnackBar("Đã gửi link reset vào email!", Colors.green);
    } catch (e) {
      _showSnackBar("Không gửi được link reset!", Colors.red);
    }
  }

  // LOGIC ĐĂNG NHẬP GOOGLE
  Future<void> _signInWithGoogle() async {
    setState(() => isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => isLoading = false);
        return;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      if (userCredential.user != null && mounted) {
        _showSnackBar("Đăng nhập Google thành công!", Colors.green);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      _showSnackBar("Lỗi đăng nhập Google: ${e.toString()}", Colors.red);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lấy trạng thái Dark Mode từ Theme
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        // Dùng Stack để chồng màn hình Splash lên Login
        children: [
          // 1. GIAO DIỆN LOGIN CHÍNH
          AnimatedOpacity(
            opacity: _opacity,
            duration: const Duration(seconds: 1),
            child: SafeArea(
              child: SingleChildScrollView(
                physics:
                    const BouncingScrollPhysics(), // Hiệu ứng cuộn mượt hơn
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 25.0, top: 20.0),
                      child: _buildBackButton(),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Image.asset(
                            'assets/images/logo.png',
                            height: 60,
                            width: 60,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 25.0, top: 25.0),
                      child: Text(
                        isLogin ? 'Đăng Nhập' : 'Đăng Ký',
                        style: TextStyle(
                          fontFamily: 'Ubuntu',
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : Colors.black, // Đổi màu tiêu đề
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 25.0, top: 8.0),
                      child: Text(
                        isLogin
                            ? 'Đăng nhập để tiếp tục sử dụng ứng dụng'
                            : 'Tạo tài khoản mới để bắt đầu',
                        style: const TextStyle(
                          fontFamily: 'Redex',
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 29.0,
                        top: 30.0,
                        bottom: 8.0,
                      ),
                      child: Text(
                        'Email',
                        style: TextStyle(
                          fontFamily: 'Ubuntu',
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isDark
                              ? Colors.white70
                              : Colors.black, // Đổi màu label
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 25.0, right: 25.0),
                      child: _buildTextField(
                        hint: 'Nhập email của bạn',
                        controller: _emailController,
                        isDark: isDark,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 29.0,
                        top: 15.0,
                        bottom: 8.0,
                      ),
                      child: Text(
                        'Mật khẩu',
                        style: TextStyle(
                          fontFamily: 'Ubuntu',
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isDark ? Colors.white70 : Colors.black,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 25.0, right: 25.0),
                      child: _buildTextField(
                        hint: 'Nhập mật khẩu',
                        isPassword: true,
                        controller: _passwordController,
                        obscure: !_isPasswordVisible,
                        isDark: isDark,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible,
                          ),
                        ),
                      ),
                    ),
                    if (!isLogin)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 29.0,
                              top: 15.0,
                              bottom: 8.0,
                            ),
                            child: Text(
                              'Xác nhận mật khẩu',
                              style: TextStyle(
                                fontFamily: 'Ubuntu',
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isDark ? Colors.white70 : Colors.black,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 25.0,
                              right: 25.0,
                            ),
                            child: _buildTextField(
                              hint: 'Nhập lại mật khẩu',
                              isPassword: true,
                              obscure: !_isConfirmPasswordVisible,
                              controller: _confirmPasswordController,
                              isDark: isDark,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isConfirmPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.grey,
                                ),
                                onPressed: () => setState(
                                  () => _isConfirmPasswordVisible =
                                      !_isConfirmPasswordVisible,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (isLogin)
                      Padding(
                        padding: const EdgeInsets.only(right: 25.0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _forgotPassword,
                            child: Text(
                              'Quên mật khẩu?',
                              style: TextStyle(
                                fontFamily: 'Redex',
                                color: isDark ? Colors.white60 : Colors.black54,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (isLogin)
                      Padding(
                        padding: const EdgeInsets.only(left: 15.0, right: 25.0),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              activeColor: const Color(0xFF0066FF),
                              onChanged: (value) =>
                                  setState(() => _rememberMe = value!),
                            ),
                            Text(
                              "Nhớ mật khẩu",
                              style: TextStyle(
                                fontFamily: 'Redex',
                                fontSize: 13,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: 25.0,
                        right: 25.0,
                        top: isLogin ? 10.0 : 25.0,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _handleAuth,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0066FF),
                            disabledBackgroundColor: const Color(
                              0xFF0066FF,
                            ).withOpacity(0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  isLogin ? 'Đăng Nhập' : 'Đăng Ký',
                                  style: const TextStyle(
                                    fontFamily: 'Redex',
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 25.0),
                      child: Center(
                        child: Text(
                          'Hoặc đăng nhập bằng',
                          style: TextStyle(
                            fontFamily: 'Redex',
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 15.0),
                      child: Center(
                        child: GestureDetector(
                          onTap: isLoading ? null : _signInWithGoogle,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40.0,
                              vertical: 12.0,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade200,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              color: isDark
                                  ? Colors.grey.shade900
                                  : Colors.white,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.g_mobiledata,
                                  color: Colors.red,
                                  size: 35,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  "Google",
                                  style: TextStyle(
                                    fontFamily: 'Redex',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 40.0, bottom: 40.0),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isLogin
                                  ? "Chưa có tài khoản? "
                                  : "Đã có tài khoản? ",
                              style: TextStyle(
                                fontFamily: 'Redex',
                                color: isDark ? Colors.white60 : Colors.black54,
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _emailController.clear();
                                  _passwordController.clear();
                                  _confirmPasswordController.clear();
                                  isLogin = !isLogin;
                                });
                              },
                              child: Text(
                                isLogin ? 'Đăng ký ngay' : 'Đăng nhập',
                                style: const TextStyle(
                                  fontFamily: 'Ubuntu',
                                  color: Color(0xFF0066FF),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. MÀN HÌNH CHÀO (SPLASH LAYER) - CHỈ HIỂN THỊ KHI MỚI VÀO
          if (_showSplash)
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: _showSplash ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 800),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      // Hiệu ứng Gradient cho "xịn"
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF0066FF), Color(0xFF003399)],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 80,
                          width: 80,
                        ),
                      ),
                      const SizedBox(height: 30),
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Mediapp",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade800
              : Colors.grey.shade200,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: const Icon(Icons.chevron_left, size: 20),
        onPressed: () =>
            !isLogin ? setState(() => isLogin = true) : Navigator.pop(context),
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    bool isPassword = false,
    bool obscure = false,
    Widget? suffixIcon,
    TextEditingController? controller,
    required bool isDark,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? obscure : false,
      style: TextStyle(
        fontFamily: 'Redex',
        fontSize: 14,
        color: isDark ? Colors.white : Colors.black,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        filled: true,
        fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
