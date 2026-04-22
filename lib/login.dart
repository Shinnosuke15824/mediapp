import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'home.dart';

class Login extends StatefulWidget {
  Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> with SingleTickerProviderStateMixin {
  // Khởi tạo các đối tượng xác thực từ Firebase và Google
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Các bộ điều khiển dữ liệu cho các ô nhập văn bản (TextField)
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Các biến trạng thái quản lý giao diện và logic
  bool _isPasswordVisible = false; // Ẩn/hiện mật khẩu
  bool _isConfirmPasswordVisible = false; // Ẩn/hiện mật khẩu xác nhận
  bool isLogin = true; // Cờ chuyển đổi giữa chế độ Đăng nhập và Đăng ký
  bool isLoading = false; // Trạng thái chờ khi xử lý dữ liệu
  bool _rememberMe = false; // Trạng thái lưu thông tin đăng nhập

  // Quản lý màn hình chờ (Splash Screen) và hiệu ứng mờ dần (Opacity)
  bool _showSplash = true;
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    // Tải thông tin email/mật khẩu đã lưu từ bộ nhớ máy (nếu có)
    _loadSavedCredentials();

    // Hiệu ứng mờ dần (Fade In) nội dung đăng nhập sau 100ms
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _opacity = 1.0);
    });

    // Tự động tắt màn hình Splash sau 2.5 giây
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  // Hàm truy xuất Email và Mật khẩu đã lưu từ SharedPreferences
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

  // Hàm lưu hoặc xóa thông tin đăng nhập vào bộ nhớ máy
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

  // --- HÀM XỬ LÝ ĐĂNG NHẬP / ĐĂNG KÝ CHÍNH ---
  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    // Kiểm tra dữ liệu đầu vào không được để trống
    if (email.isEmpty || password.isEmpty) {
      _showSnackBar("Vui lòng nhập email và mật khẩu!", Colors.orange);
      return;
    }

    // Kiểm tra định dạng Email hợp lệ bằng biểu thức chính quy (Regular Expression)
    bool emailValid = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(email);

    if (!emailValid) {
      _showSnackBar("Email không đúng định dạng!", Colors.redAccent);
      return;
    }

    // Kiểm tra mật khẩu xác nhận khi ở chế độ Đăng ký
    if (!isLogin && password != confirmPass) {
      _showSnackBar("Mật khẩu xác nhận không khớp!", Colors.redAccent);
      return;
    }

    setState(() => isLoading = true); // Bắt đầu trạng thái chờ

    try {
      if (isLogin) {
        // Thực hiện lệnh Đăng nhập với Email và Mật khẩu qua Firebase Auth
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (userCredential.user != null) {
          await _saveCredentials(); // Lưu thông tin nếu người dùng tick "Nhớ mật khẩu"
          _showSnackBar("Chào mừng bạn đã quay trở lại!", Colors.green);

          if (mounted) {
            // Chuyển hướng sang màn hình chính và xóa lịch sử các trang trước đó
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
          }
        }
      } else {
        // Thực hiện lệnh Đăng ký tài khoản mới trên hệ thống Firebase
        await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (mounted) {
          _showSnackBar("Đăng ký thành công! Mời bạn đăng nhập", Colors.green);
          _emailController.clear();
          _passwordController.clear();
          _confirmPasswordController.clear();
          setState(
            () => isLogin = true,
          ); // Chuyển về màn hình đăng nhập sau khi đăng ký thành công
        }
      }
    } on FirebaseAuthException catch (e) {
      // Xử lý các mã lỗi phản hồi từ Firebase Authentication
      String message = "Đã có lỗi xảy ra";
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        message = "Email hoặc mật khẩu không chính xác!";
      } else if (e.code == 'email-already-in-use') {
        message = "Email này đã được đăng ký bởi tài khoản khác!";
      } else if (e.code == 'weak-password') {
        message = "Mật khẩu quá yếu (yêu cầu tối thiểu 6 ký tự)!";
      }
      _showSnackBar(message, Colors.red);
    } catch (e) {
      _showSnackBar("Lỗi hệ thống: ${e.toString()}", Colors.red);
    } finally {
      if (mounted) setState(() => isLoading = false); // Tắt trạng thái chờ
    }
  }

  // --- HÀM XỬ LÝ KHÔI PHỤC MẬT KHẨU ---
  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar(
        "Vui lòng nhập Email để hệ thống gửi link khôi phục!",
        Colors.orange,
      );
      return;
    }

    try {
      // Gửi yêu cầu đặt lại mật khẩu đến địa chỉ Email của người dùng
      await _auth.sendPasswordResetEmail(email: email);

      if (mounted) {
        // Hiển thị thông báo hướng dẫn người dùng kiểm tra hộp thư
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.mark_email_read, color: Colors.green),
                SizedBox(width: 10),
                Text("Đã gửi Email!"),
              ],
            ),
            content: Text(
              "Hệ thống đã gửi link đặt lại mật khẩu đến:\n$email\nVui lòng kiểm tra hộp thư đến hoặc thư rác.",
              style: const TextStyle(height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Đã hiểu"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _showSnackBar(
        "Lỗi: Không tìm thấy tài khoản tương ứng với Email này!",
        Colors.red,
      );
    }
  }

  // --- HÀM ĐĂNG NHẬP BẰNG TÀI KHOẢN GOOGLE ---
  Future<void> _signInWithGoogle() async {
    setState(() => isLoading = true);
    try {
      // Xóa phiên làm việc Google cũ để luôn hiện bảng chọn tài khoản
      await _googleSignIn.signOut();

      // Mở giao diện chọn tài khoản Google trên thiết bị
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => isLoading = false);
        return;
      }

      // Lấy thông tin xác thực từ Google
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Đăng nhập vào Firebase bằng thông tin xác thực Google
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

  // Hàm tiện ích hiển thị thông báo SnackBar nhanh trên màn hình
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
    // Kiểm tra trạng thái Dark Mode của hệ thống
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // LỚP 1: GIAO DIỆN ĐĂNG NHẬP CHÍNH (Sử dụng AnimatedOpacity cho hiệu ứng mượt)
          AnimatedOpacity(
            opacity: _opacity,
            duration: const Duration(seconds: 1),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
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
                    // Tiêu đề thay đổi động theo trạng thái isLogin
                    Padding(
                      padding: const EdgeInsets.only(left: 25.0, top: 25.0),
                      child: Text(
                        isLogin ? 'Đăng Nhập' : 'Đăng Ký',
                        style: TextStyle(
                          fontFamily: 'Ubuntu',
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
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
                    // KHỐI EMAIL
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
                          color: isDark ? Colors.white70 : Colors.black,
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
                    // KHỐI MẬT KHẨU
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
                    // KHỐI XÁC NHẬN MẬT KHẨU (Chỉ hiện khi Đăng ký)
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
                    // Quên mật khẩu & Nhớ mật khẩu
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
                    // NÚT ĐĂNG NHẬP / ĐĂNG KÝ
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
                    // NÚT ĐĂNG NHẬP GOOGLE
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
                    // Dòng nhắc chuyển đổi giữa Đăng nhập và Đăng ký
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

          // LỚP 2: MÀN HÌNH SPLASH (Sẽ mất đi sau 2.5s)
          if (_showSplash)
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: _showSplash ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 800),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
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

  // Widget xây dựng nút Quay lại
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

  // Widget dùng chung để tạo các ô nhập liệu (Email, Mật khẩu)
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
