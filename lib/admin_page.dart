import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPage extends StatefulWidget {
  final bool isVietnamese;
  const AdminPage({super.key, required this.isVietnamese});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Map ngôn ngữ nội bộ cho trang Admin
  Map<String, String> get adminLang => {
    'title': widget.isVietnamese ? "Hệ Thống Quản Trị" : "Admin System",
    'tab_doc': widget.isVietnamese ? "BÁC SĨ" : "DOCTORS", // Tab mới gộp chung
    'tab_add': widget.isVietnamese ? "THÊM BÁC SĨ" : "ADD DOCTOR",
    'tab_list': widget.isVietnamese ? "DANH SÁCH BS" : "DOCTORS LIST",
    'tab_dept': widget.isVietnamese ? "CHUYÊN KHOA" : "SPECIALITY",
    'tab_hosp': widget.isVietnamese ? "BỆNH VIỆN" : "HOSPITAL",
    'name_label': widget.isVietnamese ? "Tên bác sĩ" : "Doctor Name",
    'dept_label': widget.isVietnamese
        ? "Chọn Chuyên khoa"
        : "Select Speciality",
    'hosp_label': widget.isVietnamese ? "Chọn Bệnh viện" : "Select Hospital",
    'img_label': widget.isVietnamese ? "Link ảnh" : "Image Link",
    'save_btn': widget.isVietnamese ? "LƯU BÁC SĨ" : "SAVE DOCTOR",
    'choose': widget.isVietnamese ? "Bấm để chọn" : "Click to select",
    'hint_dept': widget.isVietnamese
        ? "Tên chuyên khoa mới"
        : "New Speciality Name",
    'hint_hosp': widget.isVietnamese
        ? "Tên bệnh viện mới"
        : "New Hospital Name",
    'msg_fill': widget.isVietnamese
        ? "Vui lòng nhập đủ thông tin!"
        : "Please fill all fields!",
    'msg_save_doc': widget.isVietnamese
        ? "Thêm bác sĩ thành công! 🔥"
        : "Doctor added successfully! 🔥",
    'msg_save_spec': widget.isVietnamese
        ? "Thêm chuyên khoa thành công!"
        : "Speciality added!",
    'msg_save_hosp': widget.isVietnamese
        ? "Thêm bệnh viện thành công!"
        : "Hospital added!",
    'confirm_del': widget.isVietnamese ? "Xác nhận xoá?" : "Confirm delete?",
    'del_desc': widget.isVietnamese
        ? "Dữ liệu sẽ mất vĩnh viễn."
        : "Data will be lost forever.",
    'cancel': widget.isVietnamese ? "HỦY" : "CANCEL",
    'del_now': widget.isVietnamese ? "XOÁ NGAY" : "DELETE NOW",
    'del_success': widget.isVietnamese
        ? "Đã xoá thành công!"
        : "Deleted successfully!",
  };

  final _nameController = TextEditingController();
  final _imageLinkController = TextEditingController();
  final _specialityNameController = TextEditingController();
  final _hospitalNameController = TextEditingController();

  String? _selectedHospital;
  String? _selectedDept;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Đổi thành 3 Tab (vì đã gộp Tab Thêm BS và Danh sách BS làm 1)
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _imageLinkController.dispose();
    _specialityNameController.dispose();
    _hospitalNameController.dispose();
    super.dispose();
  }

  // --- HÀM DỊCH TỰ ĐỘNG: ĐÃ FIX TRIỆT ĐỂ LỖI RANGEERROR ---
  String _getDisplayName(String name) {
    if (widget.isVietnamese) return name;

    String key = name.toLowerCase().trim();

    // 1. Loại bỏ dấu tiếng Việt bằng Regex an toàn
    final vietnamese = {
      'a': '[àáạảãâầấậẩẫăằắặẳẵ]',
      'e': '[èéẹẻẽêềếệểễ]',
      'i': '[ìíịỉĩ]',
      'o': '[òóọỏõôồốộổỗơờớợởỡ]',
      'u': '[ùúụủũưừứựửữ]',
      'y': '[ỳýỵỷỹ]',
      'd': '[đ]',
    };

    for (var entry in vietnamese.entries) {
      key = key.replaceAll(RegExp(entry.value), entry.key);
    }

    // 2. Tra cứu trong từ điển
    Map<String, String> translation = {
      "tim mach": "Cardiology",
      "mat": "Ophthalmology",
      "nhi khoa": "Pediatrics",
      "tam than": "Psychiatry",
      "chinh hinh": "Orthopedics",
      "noi khoa": "Internal Medicine",
      "ngoai khoa": "Surgery",
      "da lieu": "Dermatology",
      "tai mui hong": "ENT",
      "rang ham mat": "Dentistry",
      "ung buou": "Oncology",
      "phu khoa": "Gynecology",
      "da khoa": "General Clinic",
      "than": "Nephrology",
      "tieu hoa": "Gastroenterology",
    };

    return translation[key] ?? name;
  }

  IconData _getIconForSpeciality(String name) {
    name = name.toLowerCase();
    if (name.contains("tim") || name.contains("mạch"))
      return Icons.favorite_rounded;
    if (name.contains("nhi") || name.contains("trẻ"))
      return Icons.child_care_rounded;
    if (name.contains("mắt")) return Icons.visibility_rounded;
    if (name.contains("tâm thần") || name.contains("não"))
      return Icons.psychology_rounded;
    if (name.contains("chỉnh hình") || name.contains("xương"))
      return Icons.healing_rounded;
    if (name.contains("nội")) return Icons.medical_services_rounded;
    if (name.contains("ngoại")) return Icons.biotech_rounded;
    if (name.contains("da liễu")) return Icons.face_retouching_natural_rounded;
    if (name.contains("tai") || name.contains("mũi") || name.contains("họng"))
      return Icons.hearing_rounded;
    if (name.contains("răng") || name.contains("hàm"))
      return Icons.sentiment_satisfied_alt;
    return Icons.label_important_outline;
  }

  Future<void> _deleteItem(String collection, String id, String name) async {
    try {
      await FirebaseFirestore.instance.collection(collection).doc(id).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "'${_getDisplayName(name)}' ${adminLang['del_success']}",
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Lỗi khi xoá: $e");
    }
  }

  Future<void> _saveSpeciality() async {
    if (_specialityNameController.text.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('specialities').add({
        'name': _specialityNameController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      _specialityNameController.clear();
      _showSuccess(adminLang['msg_save_spec']!);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveHospital() async {
    if (_hospitalNameController.text.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('hospitals').add({
        'name': _hospitalNameController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      _hospitalNameController.clear();
      _showSuccess(adminLang['msg_save_hosp']!);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveDoctor() async {
    if (_nameController.text.isEmpty ||
        _imageLinkController.text.isEmpty ||
        _selectedDept == null ||
        _selectedHospital == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(adminLang['msg_fill']!),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('doctors').add({
        'name': _nameController.text.trim(),
        'dept': _selectedDept,
        'hospital': _selectedHospital,
        'image': _imageLinkController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Xóa form sau khi lưu thành công
      _nameController.clear();
      _imageLinkController.clear();
      setState(() {
        _selectedDept = null;
        _selectedHospital = null;
      });

      _showSuccess(adminLang['msg_save_doc']!);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSuccess(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.grey[900]
        : Colors.grey[100];
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          adminLang['title']!,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: [
            Tab(
              icon: const Icon(Icons.medical_services),
              text: adminLang['tab_doc'],
            ),
            Tab(icon: const Icon(Icons.category), text: adminLang['tab_dept']),
            Tab(
              icon: const Icon(Icons.local_hospital),
              text: adminLang['tab_hosp'],
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDoctorTab(), // Tab gộp: Form Thêm + Danh sách Bác sĩ
          _buildSpecialityTab(), // Tab Chuyên khoa
          _buildHospitalTab(), // Tab Bệnh viện
        ],
      ),
    );
  }

  // --- TAB GỘP: QUẢN LÝ BÁC SĨ (THÊM + DANH SÁCH) ---
  Widget _buildDoctorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. KHU VỰC FORM THÊM BÁC SĨ
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.person_add_alt_1,
                        color: Colors.blue[700],
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        adminLang['tab_add']!,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildProInput(
                    adminLang['name_label']!,
                    _nameController,
                    Icons.person_outline,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    adminLang['dept_label']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDynamicDropdown(
                    "specialities",
                    _selectedDept,
                    (val) => setState(() => _selectedDept = val),
                  ),
                  const SizedBox(height: 15),
                  _buildProInput(
                    adminLang['img_label']!,
                    _imageLinkController,
                    Icons.link,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    adminLang['hosp_label']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDynamicDropdown(
                    "hospitals",
                    _selectedHospital,
                    (val) => setState(() => _selectedHospital = val),
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveDoctor,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              adminLang['save_btn']!,
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
          ),

          const SizedBox(height: 30),

          // 2. KHU VỰC DANH SÁCH BÁC SĨ
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Text(
              adminLang['tab_list']!,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('doctors')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());

              if (snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      "Chưa có bác sĩ nào trong hệ thống.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap:
                    true, // Quan trọng: Cho phép ListView cuộn chung với SingleChildScrollView tổng
                physics:
                    const NeverScrollableScrollPhysics(), // Tắt cuộn riêng của ListView
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, i) {
                  var doc = snapshot.data!.docs[i];
                  String imgPath = doc['image'].toString();
                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 5,
                      ),
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundImage: imgPath.startsWith('http')
                            ? NetworkImage(imgPath)
                            : AssetImage(imgPath) as ImageProvider,
                      ),
                      title: Text(
                        doc['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "${_getDisplayName(doc['dept'])} - ${doc['hospital']}",
                        style: const TextStyle(fontSize: 13),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        onPressed: () => _confirmDeleteDialog(
                          "doctors",
                          doc.id,
                          doc['name'],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialityTab() {
    return _buildCommonTab(
      controller: _specialityNameController,
      hint: adminLang['hint_dept']!,
      collection: "specialities",
      onSave: _saveSpeciality,
      isSpeciality: true,
    );
  }

  Widget _buildHospitalTab() {
    return _buildCommonTab(
      controller: _hospitalNameController,
      hint: adminLang['hint_hosp']!,
      collection: "hospitals",
      onSave: _saveHospital,
      isSpeciality: false,
    );
  }

  Widget _buildCommonTab({
    required TextEditingController controller,
    required String hint,
    required String collection,
    required VoidCallback onSave,
    required bool isSpeciality,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: _buildProInput(
                  hint,
                  controller,
                  isSpeciality
                      ? Icons.category_outlined
                      : Icons.local_hospital_outlined,
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: _isSaving ? null : onSave,
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  minimumSize: const Size(55, 55),
                ),
              ),
            ],
          ),
        ),
        const Divider(thickness: 2),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(collection)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, i) {
                  var item = snapshot.data!.docs[i];
                  String name = item['name'];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue[50],
                        child: Icon(
                          isSpeciality
                              ? _getIconForSpeciality(name)
                              : Icons.business_outlined,
                          color: Colors.blue[700],
                        ),
                      ),
                      title: Text(
                        _getDisplayName(name),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        onPressed: () =>
                            _confirmDeleteDialog(collection, item.id, name),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicDropdown(
    String collection,
    String? value,
    Function(String?) onChanged,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        var items = snapshot.data!.docs
            .map((doc) => doc['name'].toString())
            .toList();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]
                : Colors.grey[50],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(adminLang['choose']!),
              isExpanded: true,
              items: items
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(_getDisplayName(e)),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        );
      },
    );
  }

  Widget _buildProInput(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue[600]),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
      ),
    );
  }

  void _confirmDeleteDialog(String collection, String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(adminLang['confirm_del']!),
        content: Text("${adminLang['del_desc']} (${_getDisplayName(name)})"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(adminLang['cancel']!),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteItem(collection, id, name);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text(
              adminLang['del_now']!,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
