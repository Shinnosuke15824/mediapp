import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:provider/provider.dart'; // 1. Thêm import Provider
import 'package:shared_preferences/shared_preferences.dart'; // Thêm SharedPreferences để lưu trạng thái
import 'theme_provider.dart'; // 2. Thêm import ThemeProvider
import 'login.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool isVietnamese = true;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _chatController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final User? user = FirebaseAuth.instance.currentUser;
  Color _avatarColor = Colors.blue;
  bool _isTyping = false;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Map<String, dynamic> get lang => {
    'home': isVietnamese ? "Trang chủ" : "Home",
    'booking': isVietnamese ? "Lịch hẹn" : "Appointment",
    'chat': isVietnamese ? "Tin nhắn" : "Message",
    'profile': isVietnamese ? "Hồ sơ" : "Profile",
    'welcome': isVietnamese ? "Chào bạn! 👋" : "Hello! 👋",
    'find_doc': isVietnamese ? "Tìm bác sĩ của bạn" : "Find your doctor",
    'search_hint': isVietnamese ? "Tìm bác sĩ..." : "Search doctor...",
    'dept': isVietnamese ? "Chuyên khoa" : "Speciality",
    'all': isVietnamese ? "Xem tất cả" : "See all",
    'book_btn': isVietnamese ? "Bấm để đặt lịch" : "Book now",
    'my_booking': isVietnamese ? "Lịch hẹn của bạn" : "Your Appointments",
    'no_booking': isVietnamese
        ? "Chưa có lịch hẹn nào."
        : "No appointments yet.",
    'patient': isVietnamese ? "Người khám" : "Patient",
    'change_pw': isVietnamese ? "Đổi mật khẩu" : "Change Password",
    'logout': isVietnamese ? "Đăng xuất" : "Logout",
    'call_hotline': isVietnamese ? "Gọi Hotline" : "Call Hotline",
    'chat_hint': isVietnamese ? "Nhập tin nhắn..." : "Type a message...",
    'bot_typing': isVietnamese ? "Bác sĩ đang gõ..." : "Doctor is typing...",
    'reset_chat': isVietnamese ? "Làm mới chat" : "Reset chat",
    'select_hosp': isVietnamese ? "Chọn nơi khám bệnh" : "Select Hospital",
    'hosp_title': isVietnamese ? "Danh sách bệnh viện" : "Hospital List",
    'back_hosp': isVietnamese ? "Đổi bệnh viện" : "Change Hospital",
    'hosp_desc': isVietnamese
        ? "Vui lòng chọn bệnh viện để xem bác sĩ"
        : "Choose a hospital to see doctors",
  };

  final List<Map<String, String>> allDoctors = [
    {
      'image': 'assets/images/hinh1.png',
      'name': 'ThS.BS. Hoàng Long',
      'dept': 'Nhi khoa',
    },
    {
      'image': 'assets/images/hinh2.png',
      'name': 'BS. Thu Trang',
      'dept': 'Mắt',
    },
    {
      'image': 'assets/images/hinh3.png',
      'name': 'BS. Tuấn Kiệt',
      'dept': 'Tim mạch',
    },
    {
      'image': 'assets/images/hinh4.png',
      'name': 'PGS.TS. Minh Đức',
      'dept': 'Tâm thần',
    },
    {
      'image': 'assets/images/hinh5.png',
      'name': 'BS. Phương Thảo',
      'dept': 'Chỉnh hình',
    },
    {
      'image': 'assets/images/hinh6.png',
      'name': 'ThS.BS. Lan Anh',
      'dept': 'Nội khoa',
    },
  ];

  final List<String> hospitals = [
    "Bệnh viện Đại học Y Dược",
    "Bệnh viện Chợ Rẫy",
    "Bệnh viện Từ Dũ",
    "Bệnh viện Nhi Đồng 1",
    "Bệnh viện Thống Nhất",
  ];

  String? _selectedHospital; // Biến lưu bệnh viện đang chọn

  List<Map<String, String>> displayedDoctors = [];
  List<Map<String, dynamic>> bookedAppointments = [];
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    displayedDoctors = List.from(allDoctors);
    _resetChat();
    _initNotifications();
    _loadAppState();
    _fetchAppointments();
  }

  void _loadAppState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isVietnamese = prefs.getBool('isVietnamese') ?? true;
    });
  }

  void _fetchAppointments() async {
    if (user == null) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('userId', isEqualTo: user?.uid)
          .get();

      final List<Map<String, dynamic>> loadedData = snapshot.docs.map((doc) {
        final data = doc.data();
        String img = allDoctors.firstWhere(
          (d) => d['name'] == data['doctorName'],
          orElse: () => {'image': 'assets/images/logo.png'},
        )['image']!;
        return {
          'id': doc.id,
          'name': data['doctorName'] ?? 'Bác sĩ',
          'image': img,
          'patient': data['patientName'] ?? 'Bệnh nhân',
          'hospital': data['hospital'] ?? 'Bệnh viện chưa xác định',
          'date': data['date'] ?? '',
          'time': data['time'] ?? '',
          'dept': data['dept'] ?? '',
          'fullDateTime': data['fullDateTime'] != null
              ? DateTime.parse(data['fullDateTime'])
              : DateTime.now(),
        };
      }).toList();

      setState(() {
        bookedAppointments = loadedData;
      });
    } catch (e) {
      debugPrint("Lỗi tải lịch hẹn: $e");
    }
  }

  void _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    tz.initializeTimeZones();
  }

  Future<void> _showNotification(
    String patientName,
    String doctorName,
    String time,
  ) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'mediapp_channel',
          'Thông báo Mediapp',
          importance: Importance.max,
          priority: Priority.high,
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      isVietnamese ? 'Nhắc lịch khám!' : 'Appointment Reminder!',
      isVietnamese
          ? '$patientName có lịch khám với $doctorName vào lúc $time'
          : '$patientName has a schedule with $doctorName at $time',
      platformChannelSpecifics,
    );
  }

  void _resetChat() {
    setState(() {
      _messages = [
        {
          "text": isVietnamese
              ? "Chào bạn! Tôi là chatbot bác sĩ. Bạn cần hỗ trợ gì?"
              : "Hello ! I am your AI Doctor. How can I help you?",
          "isMe": false,
        },
      ];
    });
  }

  void _handleSendMessage() {
    String text = _chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"text": text, "isMe": true});
      _isTyping = true;
    });
    _chatController.clear();

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        String resp = _getBotResponse(text);
        setState(() {
          _messages.add({"text": resp, "isMe": false});
          _isTyping = false;
        });
      }
    });
  }

  String _getBotResponse(String input) {
    input = input.toLowerCase();
    if (isVietnamese) {
      if (input.contains("chào"))
        return "Chào bạn! Chúc bạn ngày mới tốt lành.";
      return "Bác sĩ đã nhận được thông tin từ bạn!";
    } else {
      return "Doctor has received your message!";
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _bookDoctor(Map<String, String> doc) async {
    final DateTime? d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2027),
    );
    if (d == null) return;
    final TimeOfDay? t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (t == null) return;

    _nameController.clear();

    final String? pName = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 25,
          right: 25,
          top: 25,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(
                  Icons.person_add_alt_1,
                  color: Colors.blue,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  lang['patient'],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              isVietnamese
                  ? "Vui lòng nhập tên người sẽ đến khám bệnh"
                  : "Please enter the name of the patient",
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: isVietnamese
                    ? "Ví dụ: Nguyễn Văn A..."
                    : "Ex: John Doe...",
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, _nameController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  isVietnamese ? "XÁC NHẬN ĐẶT LỊCH" : "CONFIRM BOOKING",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (pName == null || pName.isEmpty) return;
    DateTime sel = DateTime(d.year, d.month, d.day, t.hour, t.minute);

    bool conflict = bookedAppointments.any(
      (app) =>
          app['name'] == doc['name'] &&
          (sel.difference(app['fullDateTime'] as DateTime).inMinutes.abs() <
              30),
    );

    if (conflict) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isVietnamese ? "Lịch này đã có người đặt!" : "Slot taken!",
          ),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      String timeStr = t.format(context);
      try {
        await FirebaseFirestore.instance.collection('appointments').add({
          'userId': user?.uid,
          'doctorName': doc['name'],
          'patientName': pName,
          'hospital':
              _selectedHospital, // Lưu bệnh viện đang chọn vào Firestore
          'date': DateFormat('dd/MM/yyyy').format(d),
          'time': timeStr,
          'dept': doc['dept'],
          'fullDateTime': sel.toIso8601String(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        _fetchAppointments();
        _showNotification(pName, doc['name']!, timeStr);
      } catch (e) {
        debugPrint("Lỗi đặt lịch: $e");
      }
    }
  }

  void _showError(String m) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Mediapp"),
        content: Text(m),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _resetChat,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(lang['reset_chat']),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _messages.length,
            itemBuilder: (context, index) => _ChatBubble(
              text: _messages[index]["text"],
              isMe: _messages[index]["isMe"],
            ),
          ),
        ),
        if (_isTyping)
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                lang['bot_typing'],
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        _buildChatInputArea(),
      ],
    );
  }

  Widget _buildChatInputArea() {
    return Container(
      padding: const EdgeInsets.all(15),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              decoration: InputDecoration(
                hintText: lang['chat_hint'],
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            backgroundColor: Colors.blue,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _handleSendMessage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Text(lang['welcome'], style: const TextStyle(color: Colors.grey)),

          if (_selectedHospital == null) ...[
            Text(
              lang['select_hosp'],
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              lang['hosp_desc'],
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 25),
            _buildHospitalGrid(),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _selectedHospital!,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _selectedHospital = null),
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: Text(lang['back_hosp']),
                ),
              ],
            ),
            const SizedBox(height: 15),
            _buildSearchBar(),
            const SizedBox(height: 20),
            Text(
              lang['dept'],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildCategorySection(),
            const SizedBox(height: 20),
            _buildDoctorGrid(),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHospitalGrid() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: hospitals.length,
      itemBuilder: (context, i) => Container(
        margin: const EdgeInsets.only(bottom: 15),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedHospital = hospitals[i];
              // Hiển thị cả 6 bác sĩ cho bệnh viện được chọn
              displayedDoctors = List.from(allDoctors);
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hospitals[i],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isVietnamese
                            ? "Xem danh sách bác sĩ"
                            : "See doctors list",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() => TextField(
    onChanged: (v) => setState(
      () => displayedDoctors = allDoctors
          .where((d) => d['name']!.toLowerCase().contains(v.toLowerCase()))
          .toList(),
    ),
    decoration: InputDecoration(
      hintText: lang['search_hint'],
      prefixIcon: const Icon(Icons.search),
      filled: true,
      fillColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[800]
          : Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
    ),
  );

  Widget _buildCategorySection() {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _catItem(
            Icons.favorite,
            isVietnamese ? "Tim mạch" : "Heart",
            "Tim mạch",
          ),
          _catItem(Icons.visibility, isVietnamese ? "Mắt" : "Eye", "Mắt"),
          _catItem(
            Icons.child_care,
            isVietnamese ? "Nhi khoa" : "Pediatric",
            "Nhi khoa",
          ),
          _catItem(
            Icons.psychology,
            isVietnamese ? "Tâm thần" : "Psychology",
            "Tâm thần",
          ),
          _catItem(
            Icons.healing,
            isVietnamese ? "Chỉnh hình" : "Orthopedic",
            "Chỉnh hình",
          ),
          _catItem(
            Icons.medical_services,
            isVietnamese ? "Nội khoa" : "General",
            "Nội khoa",
          ),
        ],
      ),
    );
  }

  Widget _catItem(IconData icon, String label, String deptKey) =>
      GestureDetector(
        onTap: () => setState(
          () => displayedDoctors = allDoctors
              .where((d) => d['dept'] == deptKey)
              .toList(),
        ),
        child: Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Column(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.blue.withOpacity(0.1),
                child: Icon(icon, color: Colors.blue, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildDoctorGrid() => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      childAspectRatio: 0.8,
    ),
    itemCount: displayedDoctors.length,
    itemBuilder: (ctx, i) => GestureDetector(
      onTap: () => _bookDoctor(displayedDoctors[i]),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
                child: Image.asset(
                  displayedDoctors[i]['image']!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(
                    displayedDoctors[i]['name']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    "${displayedDoctors[i]['dept']}",
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lang['book_btn'],
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildHistoryTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang['my_booking'],
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 15),
          Expanded(
            child: bookedAppointments.isEmpty
                ? Center(child: Text(lang['no_booking']))
                : ListView.builder(
                    itemCount: bookedAppointments.length,
                    itemBuilder: (context, index) {
                      final app = bookedAppointments[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: AssetImage(app['image']),
                          ),
                          title: Text(
                            app['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "${lang['patient']}: ${app['patient']}\n🏢 ${app['hospital']}\n📅 ${app['date']} - ${app['time']}",
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('appointments')
                                  .doc(app['id'])
                                  .delete();
                              _fetchAppointments();
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: _avatarColor,
                child: const Icon(Icons.person, size: 60, color: Colors.white),
              ),
              CircleAvatar(
                backgroundColor: Colors.white,
                radius: 18,
                child: IconButton(
                  icon: const Icon(
                    Icons.camera_alt,
                    size: 18,
                    color: Colors.blue,
                  ),
                  onPressed: () => setState(
                    () => _avatarColor = (List.of(
                      Colors.primaries,
                    )..shuffle()).first,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            user?.email ?? "User",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          ListTile(
            leading: Icon(
              themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: Colors.amber,
            ),
            title: Text(isVietnamese ? "Chế độ tối" : "Dark Mode"),
            trailing: Switch(
              value: themeProvider.isDarkMode,
              onChanged: (v) => themeProvider.toggleTheme(),
            ),
          ),
          _profileMenu(Icons.lock_outline, lang['change_pw'], () {
            _currentPasswordController.clear();
            _newPasswordController.clear();
            _confirmPasswordController.clear();
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (ctx) => Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                  left: 25,
                  right: 25,
                  top: 25,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      lang['change_pw'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _currentPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: isVietnamese
                            ? "Mật khẩu hiện tại"
                            : "Current password",
                        prefixIcon: const Icon(Icons.lock_person_outlined),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: isVietnamese
                            ? "Mật khẩu mới"
                            : "New password",
                        prefixIcon: const Icon(Icons.lock_outline),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: isVietnamese
                            ? "Xác nhận mật khẩu mới"
                            : "Confirm new password",
                        prefixIcon: const Icon(Icons.check_circle_outline),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () async {
                          String cpw = _currentPasswordController.text.trim();
                          String npw = _newPasswordController.text.trim();
                          String cnpw = _confirmPasswordController.text.trim();
                          if (cpw.isEmpty || npw.isEmpty || cnpw != npw) {
                            _showError("Vui lòng kiểm tra lại thông tin!");
                            return;
                          }
                          try {
                            AuthCredential cred = EmailAuthProvider.credential(
                              email: user!.email!,
                              password: cpw,
                            );
                            await user?.reauthenticateWithCredential(cred);
                            await user?.updatePassword(npw);
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isVietnamese ? "Đổi thành công!" : "Success!",
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            _showError("Lỗi: $e");
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          isVietnamese ? "CẬP NHẬT" : "UPDATE",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          _profileMenu(Icons.logout, lang['logout'], () async {
            await FirebaseAuth.instance.signOut();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (c) => Login()),
            );
          }, isRed: true),
        ],
      ),
    );
  }

  Widget _getBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildHistoryTab();
      case 2:
        return _buildChatTab();
      case 3:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _profileMenu(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isRed = false,
  }) => ListTile(
    leading: Icon(icon, color: isRed ? Colors.red : Colors.blue),
    title: Text(
      title,
      style: TextStyle(
        color: isRed
            ? Colors.red
            : (Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black),
      ),
    ),
    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    onTap: onTap,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Mediapp",
          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.phone, color: Colors.red),
            onPressed: () => _makePhoneCall("19001234"),
          ),
          TextButton(
            onPressed: () async {
              setState(() => isVietnamese = !isVietnamese);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isVietnamese', isVietnamese);
              _resetChat();
            },
            child: Text(
              isVietnamese ? "EN" : "VN",
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _getBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (v) => setState(() => _currentIndex = v),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: lang['home'],
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_today),
            label: lang['booking'],
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.message),
            label: lang['chat'],
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: lang['profile'],
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  const _ChatBubble({required this.text, required this.isMe});
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe
              ? Colors.blue
              : (Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isMe
                ? Colors.white
                : (Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black),
          ),
        ),
      ),
    );
  }
}
